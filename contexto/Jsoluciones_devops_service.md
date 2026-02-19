# JSOLUCIONES ERP – Arquitectura de Servicios (DevOps / Infraestructura)
> Documento de referencia para configuración de servicios de background, colas, caché, tiempo real y tareas programadas.
> ⚠️ **Proyecto NO multitenant** — instancia única por cliente, sin aislamiento de tenant en DB ni en workers.

---

## Stack de Servicios Involucrados

```
┌─────────────────────────────────────────────────────────┐
│                    JSOLUCIONES ERP                      │
│                                                         │
│  Django (WSGI/ASGI)  ←→  PostgreSQL                    │
│         ↕                                               │
│  Django Channels (ASGI) ←→  Redis (Channel Layer)      │
│         ↕                                               │
│  Celery Workers      ←→  Redis (Broker)                 │
│  Celery Beat                                            │
│         ↕                                               │
│  Redis (Cache L1)                                       │
│         ↕                                               │
│  Flower (monitor)                                       │
└─────────────────────────────────────────────────────────┘
```

---

## 1. Redis

### Roles que cumple Redis en este proyecto (3 usos distintos)

| Uso | DB Redis | Descripción |
|---|---|---|
| **Broker de Celery** | DB 0 | Cola de tareas async (Celery tasks) |
| **Channel Layer (WebSockets)** | DB 1 | Mensajes en tiempo real vía Django Channels |
| **Caché general** | DB 2 | Caché de queries, sesiones, tokens JWT blacklist |

### Configuración base (`settings.py`)
```python
REDIS_HOST = env("REDIS_HOST", default="redis")
REDIS_PORT = 6379

# Celery Broker
CELERY_BROKER_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"
CELERY_RESULT_BACKEND = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"

# Django Channels
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [(REDIS_HOST, REDIS_PORT)],
            "capacity": 1500,
            "expiry": 10,
        },
    }
}

# Django Cache
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": f"redis://{REDIS_HOST}:{REDIS_PORT}/2",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
        "TIMEOUT": 300,  # 5 minutos default
    }
}
```

### TTLs de caché recomendados por contexto

| Dato cacheado | TTL | Justificación |
|---|---|---|
| Stock en tiempo real | 30 seg | Cambia por ventas/movimientos |
| Lista de productos POS | 60 seg | Alta frecuencia de lectura |
| Tipos de cambio | 3600 seg (1h) | Se actualiza 1 vez al día |
| Sesiones JWT | Duración del token | Auth |
| JWT Blacklist (tokens revocados) | Hasta expiración del token | Logout seguro |
| Datos de cliente (ficha) | 300 seg | Cambios poco frecuentes |
| Reportes pesados (dashboard) | 600 seg | Cálculos costosos |
| Validaciones SUNAT (RUC/DNI) | 86400 seg (1 día) | Datos no cambian |

---

## 2. Celery

### Configuración global

```python
# celery.py
from celery import Celery
from celery.schedules import crontab

app = Celery("jsoluciones")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()

# Serialización
app.conf.task_serializer = "json"
app.conf.result_serializer = "json"
app.conf.accept_content = ["json"]

# Zona horaria (Perú)
app.conf.timezone = "America/Lima"
app.conf.enable_utc = True

# Reintentos por defecto
app.conf.task_acks_late = True
app.conf.task_reject_on_worker_lost = True
app.conf.task_max_retries = 3
```

---

### Colas definidas (por prioridad y módulo)

| Cola | Prioridad | Workers asignados | Qué procesa |
|---|---|---|---|
| `critical` | Alta | 2 | Emisión SUNAT, pagos, apertura/cierre caja |
| `default` | Normal | 2 | Tareas generales |
| `notifications` | Normal | 1 | WhatsApp, correos, push notifications |
| `reports` | Baja | 1 | Generación de reportes, exportaciones Excel/PDF |
| `sync` | Baja | 1 | Sincronización offline POS, eCommerce (WooCommerce/Shopify) |

```python
app.conf.task_routes = {
    # Facturación SUNAT — crítico
    "facturacion.tasks.emitir_comprobante": {"queue": "critical"},
    "facturacion.tasks.reenviar_contingencia": {"queue": "critical"},
    "facturacion.tasks.enviar_resumen_diario": {"queue": "critical"},

    # Ventas y pagos
    "ventas.tasks.procesar_pago": {"queue": "critical"},
    "ventas.tasks.cerrar_caja": {"queue": "critical"},

    # WhatsApp y notificaciones
    "whatsapp.tasks.enviar_mensaje": {"queue": "notifications"},
    "whatsapp.tasks.procesar_campana": {"queue": "notifications"},
    "notificaciones.tasks.enviar_email": {"queue": "notifications"},
    "notificaciones.tasks.enviar_push": {"queue": "notifications"},

    # Reportes y exportaciones
    "reportes.tasks.generar_excel": {"queue": "reports"},
    "reportes.tasks.generar_pdf": {"queue": "reports"},
    "reportes.tasks.exportar_programado": {"queue": "reports"},

    # Sincronización
    "ventas.tasks.sincronizar_offline": {"queue": "sync"},
    "ecommerce.tasks.importar_pedidos_woocommerce": {"queue": "sync"},
    "ecommerce.tasks.importar_pedidos_shopify": {"queue": "sync"},
    "distribucion.tasks.sincronizar_transportista_externo": {"queue": "sync"},
}
```

---

### Catálogo completo de tareas Celery por módulo

#### MÓDULO 1 – Ventas

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `ventas.sincronizar_venta_offline` | sync | Sube ventas POS guardadas en IndexedDB al reconectar | On reconnect |
| `ventas.calcular_comision_vendedor` | default | Calcula comisión al cerrar una venta | Post-venta |
| `ventas.alertar_cotizacion_por_vencer` | notifications | Notifica al vendedor si cotización vence en < 3 días | Periódica |
| `ventas.convertir_orden_a_despacho` | default | Genera orden de despacho automáticamente al aprobar OV | On approve |
| `ecommerce.importar_pedidos_woocommerce` | sync | Jala pedidos nuevos desde WooCommerce API | Periódica (5 min) |
| `ecommerce.importar_pedidos_shopify` | sync | Jala pedidos nuevos desde Shopify API | Periódica (5 min) |

---

#### MÓDULO 2 – Inventario

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `inventario.verificar_stock_minimo` | default | Evalúa si algún producto cayó bajo el stock mínimo | Post-movimiento |
| `inventario.alertar_stock_critico` | notifications | Envía notificación (push/email) al supervisor de almacén | Triggered por anterior |
| `inventario.alertar_lote_por_vencer` | notifications | Detecta lotes próximos a vencer (< 30 días) | Periódica (diaria) |
| `inventario.actualizar_valoracion_inventario` | default | Recalcula valoración de stock (método PEPS) | Periódica (noche) |

---

#### MÓDULO 3 – Facturación Electrónica (CRÍTICO)

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `facturacion.emitir_comprobante_sunat` | critical | Firma XML, envía a OSE/SUNAT, procesa CDR | On emit |
| `facturacion.manejar_rechazo_sunat` | critical | Procesa respuesta de error SUNAT, actualiza estado | On reject |
| `facturacion.reenviar_comprobante_contingencia` | critical | Reintenta envío de comprobantes en cola de contingencia | Periódica (5 min) |
| `facturacion.enviar_resumen_diario_sunat` | critical | Agrupa boletas del día y envía resumen a SUNAT | Diaria (23:50 Lima) |
| `facturacion.generar_ple_mensual` | reports | Genera archivos PLE (TXT) para SUNAT | Manual / Mensual |
| `facturacion.enviar_comprobante_cliente_email` | notifications | Envía PDF/XML del comprobante por correo | Post-emisión |
| `facturacion.enviar_comprobante_cliente_whatsapp` | notifications | Envía ticket por WhatsApp | Post-emisión (POS) |

---

#### MÓDULO 4 – Distribución y Seguimiento

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `distribucion.optimizar_ruta` | default | Calcula ruta óptima para transportista (algoritmo greedy/OSRM) | On planificar ruta |
| `distribucion.actualizar_ubicacion_gps` | default | Persiste coordenada GPS del repartidor en DB | WebSocket → cada 30 seg |
| `distribucion.notificar_cliente_despacho` | notifications | WhatsApp "Tu pedido está en camino" | On cambio estado EN RUTA |
| `distribucion.notificar_cliente_entrega` | notifications | WhatsApp "Tu pedido fue entregado" | On cambio estado ENTREGADO |
| `distribucion.sincronizar_estado_transportista_externo` | sync | Consulta API de Olva/Urbano para actualizar estado | Periódica (15 min) |
| `distribucion.encuesta_posventa` | notifications | Envía encuesta WhatsApp 3 días post-entrega | Periódica (diaria) |
| `distribucion.alertar_pedido_atrasado` | notifications | Notifica si pedido supera ETA sin entregarse | Periódica (horaria) |

---

#### MÓDULO 5 – Compras y Proveedores

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `compras.notificar_aprobacion_oc` | notifications | Alerta al supervisor si OC supera monto configurado | On crear OC |
| `compras.alertar_oc_vencida_sin_recibir` | notifications | Notifica si OC superó fecha estimada sin recibirse | Periódica (diaria) |
| `compras.validar_factura_proveedor_sunat` | critical | Valida RUC y factura contra SUNAT | On registrar factura |
| `compras.alertar_vencimiento_factura_proveedor` | notifications | Recordatorio de facturas próximas a vencer | Periódica (diaria) |
| `compras.evaluar_kpi_proveedor` | default | Calcula KPI de entrega a tiempo vs fallida | Mensual |

---

#### MÓDULO 6 – Financiero y Tributario

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `finanzas.calcular_intereses_mora` | default | Calcula interés diario sobre documentos vencidos | Periódica (diaria) |
| `finanzas.alertar_cxc_vencidas` | notifications | Notifica al contador sobre CxC vencidas | Periódica (diaria) |
| `finanzas.alertar_cxp_por_vencer` | notifications | Recordatorio de CxP próximas a vencer (< 5 días) | Periódica (diaria) |
| `finanzas.procesar_conciliacion_bancaria` | default | Procesa archivo cargado y genera sugerencias de match | On upload extracto |
| `finanzas.generar_flujo_caja_proyectado` | reports | Calcula flujo de caja para los próximos 30 días | Periódica (diaria) |
| `finanzas.generar_estado_resultados` | reports | Genera P&L del mes actual | Periódica (diaria, noche) |
| `finanzas.recordar_vencimiento_tributario` | notifications | Alerta sobre vencimientos SUNAT del mes | Periódica (diaria) |

---

#### MÓDULO 7 – WhatsApp API

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `whatsapp.enviar_mensaje_plantilla` | notifications | Envía mensaje via Meta Cloud API | Event-driven |
| `whatsapp.procesar_respuesta_webhook` | notifications | Procesa webhook entrante de Meta (estado del mensaje) | Webhook POST |
| `whatsapp.actualizar_estado_mensaje` | notifications | Actualiza estado (entregado/leído/fallido) en DB | Post-webhook |
| `whatsapp.ejecutar_campana_fidelizacion` | notifications | Envía mensajes masivos al segmento configurado | Scheduled / Manual |
| `whatsapp.calcular_metricas_campana` | reports | Agrega métricas de apertura/respuesta | Periódica (horaria) |
| `whatsapp.limpiar_logs_antiguos` | default | Purga logs de mensajes > 90 días | Semanal |

---

#### MÓDULO 8 – Dashboard & Reportes

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `reportes.calcular_kpis_dashboard` | reports | Precalcula KPIs y los guarda en caché Redis | Periódica (10 min) |
| `reportes.generar_excel_exportacion` | reports | Genera .xlsx con filtros del usuario | On demand |
| `reportes.generar_pdf_exportacion` | reports | Genera .pdf con branding | On demand |
| `reportes.enviar_reporte_programado` | reports | Envía por email el reporte exportado automáticamente | Scheduled (config del usuario) |
| `reportes.limpiar_archivos_temporales` | default | Elimina exports generados > 24h | Diaria (madrugada) |

---

#### MÓDULO 9 – Usuarios y Seguridad

| Tarea | Cola | Descripción | Trigger |
|---|---|---|---|
| `seguridad.invalidar_sesiones_expiradas` | default | Limpia tokens JWT expirados de Redis blacklist | Periódica (horaria) |
| `seguridad.alertar_intentos_fallidos_login` | notifications | Notifica admin si usuario supera intentos máximos | Event |
| `seguridad.cerrar_sesion_remota` | critical | Invalida token específico en blacklist Redis | Manual (admin) |
| `auditoria.registrar_accion_critica` | default | Persiste log de acciones sensibles (async) | Event-driven |

---

## 3. Celery Beat – Tareas Programadas

```python
app.conf.beat_schedule = {

    # ─── FACTURACIÓN ───────────────────────────────────────
    "enviar-resumen-diario-sunat": {
        "task": "facturacion.tasks.enviar_resumen_diario_sunat",
        "schedule": crontab(hour=23, minute=50),  # 11:50 PM Lima
    },
    "reintentar-comprobantes-contingencia": {
        "task": "facturacion.tasks.reenviar_comprobante_contingencia",
        "schedule": 300.0,  # cada 5 minutos
    },

    # ─── ECOMMERCE SYNC ────────────────────────────────────
    "importar-pedidos-woocommerce": {
        "task": "ecommerce.tasks.importar_pedidos_woocommerce",
        "schedule": 300.0,  # cada 5 minutos
    },
    "importar-pedidos-shopify": {
        "task": "ecommerce.tasks.importar_pedidos_shopify",
        "schedule": 300.0,
    },

    # ─── INVENTARIO ────────────────────────────────────────
    "alertar-lotes-por-vencer": {
        "task": "inventario.tasks.alertar_lote_por_vencer",
        "schedule": crontab(hour=7, minute=0),  # 7 AM Lima
    },
    "actualizar-valoracion-inventario": {
        "task": "inventario.tasks.actualizar_valoracion_inventario",
        "schedule": crontab(hour=1, minute=0),  # 1 AM
    },

    # ─── DISTRIBUCIÓN ──────────────────────────────────────
    "sincronizar-transportistas-externos": {
        "task": "distribucion.tasks.sincronizar_estado_transportista_externo",
        "schedule": 900.0,  # cada 15 minutos
    },
    "enviar-encuesta-posventa": {
        "task": "distribucion.tasks.encuesta_posventa",
        "schedule": crontab(hour=10, minute=0),  # 10 AM Lima
    },
    "alertar-pedidos-atrasados": {
        "task": "distribucion.tasks.alertar_pedido_atrasado",
        "schedule": 3600.0,  # cada hora
    },

    # ─── FINANZAS ──────────────────────────────────────────
    "calcular-intereses-mora": {
        "task": "finanzas.tasks.calcular_intereses_mora",
        "schedule": crontab(hour=6, minute=0),  # 6 AM Lima
    },
    "alertar-cxc-vencidas": {
        "task": "finanzas.tasks.alertar_cxc_vencidas",
        "schedule": crontab(hour=8, minute=0),  # 8 AM Lima
    },
    "alertar-cxp-por-vencer": {
        "task": "finanzas.tasks.alertar_cxp_por_vencer",
        "schedule": crontab(hour=8, minute=30),
    },
    "generar-flujo-caja-proyectado": {
        "task": "finanzas.tasks.generar_flujo_caja_proyectado",
        "schedule": crontab(hour=2, minute=0),  # 2 AM
    },
    "generar-estado-resultados": {
        "task": "finanzas.tasks.generar_estado_resultados",
        "schedule": crontab(hour=3, minute=0),  # 3 AM
    },
    "recordar-vencimientos-tributarios": {
        "task": "finanzas.tasks.recordar_vencimiento_tributario",
        "schedule": crontab(hour=9, minute=0),  # 9 AM Lima
    },

    # ─── COMPRAS ───────────────────────────────────────────
    "alertar-oc-vencidas": {
        "task": "compras.tasks.alertar_oc_vencida_sin_recibir",
        "schedule": crontab(hour=7, minute=30),
    },
    "alertar-facturas-proveedor-por-vencer": {
        "task": "compras.tasks.alertar_vencimiento_factura_proveedor",
        "schedule": crontab(hour=8, minute=0),
    },

    # ─── DASHBOARD ─────────────────────────────────────────
    "precalcular-kpis-dashboard": {
        "task": "reportes.tasks.calcular_kpis_dashboard",
        "schedule": 600.0,  # cada 10 minutos
    },

    # ─── WHATSAPP ──────────────────────────────────────────
    "calcular-metricas-whatsapp": {
        "task": "whatsapp.tasks.calcular_metricas_campana",
        "schedule": 3600.0,  # cada hora
    },
    "limpiar-logs-whatsapp": {
        "task": "whatsapp.tasks.limpiar_logs_antiguos",
        "schedule": crontab(day_of_week=0, hour=4, minute=0),  # Domingos 4 AM
    },

    # ─── SEGURIDAD ─────────────────────────────────────────
    "invalidar-sesiones-expiradas": {
        "task": "seguridad.tasks.invalidar_sesiones_expiradas",
        "schedule": 3600.0,  # cada hora
    },

    # ─── MANTENIMIENTO ─────────────────────────────────────
    "limpiar-archivos-temporales": {
        "task": "reportes.tasks.limpiar_archivos_temporales",
        "schedule": crontab(hour=4, minute=30),  # 4:30 AM
    },
    "cotizaciones-proximas-a-vencer": {
        "task": "ventas.tasks.alertar_cotizacion_por_vencer",
        "schedule": crontab(hour=8, minute=0),  # 8 AM Lima
    },
}
```

---

## 4. Django Channels (WebSockets)

### Consumers (grupos de WebSocket)

| Consumer | Grupo WS | Quién se suscribe | Qué emite |
|---|---|---|---|
| `DashboardConsumer` | `dashboard_{user_id}` | Usuarios con acceso a dashboard | KPIs actualizados, alertas en tiempo real |
| `StockConsumer` | `stock_{almacen_id}` | Supervisores de almacén | Cambios de stock en tiempo real |
| `POSConsumer` | `pos_{caja_id}` | Cajeros activos | Confirmación de ventas, estado offline/online |
| `PedidosConsumer` | `pedidos_{sucursal_id}` | Operadores de distribución | Nuevos pedidos, cambios de estado |
| `GPSConsumer` | `gps_{ruta_id}` | Mapa de seguimiento | Coordenadas GPS del repartidor |
| `NotificacionesConsumer` | `notif_{user_id}` | Todos los usuarios | Notificaciones globales (badge header) |
| `FacturacionConsumer` | `factura_{user_id}` | Emisores de comprobantes | Respuesta SUNAT en tiempo real |

### Flujo WebSocket ↔ Celery
```
Evento (venta, movimiento, GPS)
       ↓
  Celery Task procesa
       ↓
  channel_layer.group_send(grupo, mensaje)
       ↓
  Consumer.receive → WebSocket → Frontend actualiza UI
```

---

## 5. Django ASGI + Uvicorn

```python
# asgi.py
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
```

### Servidor en producción
```bash
# Uvicorn con workers (producción)
uvicorn jsoluciones.asgi:application \
  --host 0.0.0.0 \
  --port 8000 \
  --workers 4 \
  --lifespan off
```

> ⚠️ **No usar Gunicorn** para WebSockets — requiere Uvicorn o Daphne por ser ASGI.

---

## 6. Configuración de Workers por Entorno

### Desarrollo local (`docker-compose.yml`)
```yaml
services:
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  celery-worker-critical:
    command: celery -A jsoluciones worker -Q critical -c 2 -l info
    depends_on: [redis]

  celery-worker-default:
    command: celery -A jsoluciones worker -Q default,notifications -c 2 -l info
    depends_on: [redis]

  celery-worker-reports:
    command: celery -A jsoluciones worker -Q reports,sync -c 1 -l info
    depends_on: [redis]

  celery-beat:
    command: celery -A jsoluciones beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
    depends_on: [redis, db]

  flower:
    command: celery -A jsoluciones flower --port=5555
    ports: ["5555:5555"]
    depends_on: [redis]
```

### Producción (recomendado)

| Proceso | Instancias | Recursos | Notas |
|---|---|---|---|
| `uvicorn` (ASGI) | 2-4 | 2 CPU / 2 GB RAM c/u | Detrás de Nginx |
| `celery worker -Q critical` | 2 | 1 CPU / 1 GB RAM | Nunca < 2 instancias |
| `celery worker -Q default,notifications` | 2 | 1 CPU / 1 GB RAM | |
| `celery worker -Q reports,sync` | 1 | 1 CPU / 2 GB RAM | Reportes pesados |
| `celery beat` | **1 solo** | 256 MB RAM | Nunca duplicar |
| `redis` | 1 (+ replica) | 512 MB RAM min | Habilitar persistencia RDB |
| `flower` | 1 | 256 MB RAM | Solo acceso interno/admin |

---

## 7. Dependencias Python necesarias

```txt
# Celery + Redis
celery==5.3.x
redis==5.0.x
django-celery-beat==2.6.x        # Tareas periódicas desde DB (admin Django)
django-celery-results==2.5.x     # Resultados de tareas en DB

# Django Channels
channels==4.x
channels-redis==4.x
daphne==4.x                      # Alternativa a uvicorn para ASGI

# Cache
django-redis==5.4.x

# Servidor ASGI
uvicorn[standard]==0.27.x

# Utilidades tareas
celery-singleton==0.3.x          # Evitar tareas duplicadas (Beat)
```

---

## 8. Monitoreo y Alertas de Servicios

| Herramienta | Qué monitorea | Acceso |
|---|---|---|
| **Flower** | Cola de Celery: tareas activas, fallidas, tiempo ejecución | Puerto 5555 (interno) |
| **Django Admin** | `django-celery-beat`: schedule de tareas | `/admin/` |
| **Django Admin** | `django-celery-results`: historial de resultados | `/admin/` |
| **Redis INFO** | Memoria usada, clientes conectados, hit rate caché | CLI / Grafana |
| **Sentry** | Excepciones en tareas Celery (integración nativa) | Dashboard Sentry |

### Señales críticas a monitorear
- Cola `critical` con > 50 tareas pendientes → alerta inmediata
- Tarea `emitir_comprobante_sunat` con > 3 reintentos → revisión manual
- Redis memoria > 80% → escalar o limpiar caché
- Celery Beat sin heartbeat > 5 min → reiniciar servicio

---

## 9. Notas Clave del Proyecto

1. **Sin multitenant** → no hay routing por tenant en las colas, las tareas son globales por instancia.
2. **Zona horaria Perú (America/Lima)** → todos los Beat schedules en hora Lima, no UTC.
3. **SUNAT es crítico** → la cola `critical` NUNCA debe compartirse con tareas de baja prioridad.
4. **POS offline** → la sincronización offline usa IndexedDB en el cliente + tarea `sincronizar_venta_offline` al reconectar; no depende de Redis.
5. **WhatsApp webhooks** → llegan por POST HTTP (no WebSocket); se procesan con Celery inmediatamente después de responder 200 OK a Meta.
6. **GPS en tiempo real** → no usar DB para coordenadas frecuentes; guardar en Redis con TTL corto y persistir solo eventos de estado (despachado/entregado).
7. **Flower en producción** → proteger con autenticación básica o VPN, nunca exponer públicamente.

---

*Documento de arquitectura de servicios — JSOLUCIONES ERP (instancia única, no multitenant)*