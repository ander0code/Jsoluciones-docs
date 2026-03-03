# JSOLUCIONES ERP — ARQUITECTURA DE SERVICIOS (DEVOPS)

> Referencia para configuracion de servicios de background, colas, cache, WebSockets y tareas programadas.
> Proyecto NO multitenant — instancia unica por cliente, sin aislamiento de tenant en DB ni en workers.

---

## Diagrama de Servicios

```
┌─────────────────────────────────────────────────────────┐
│                    JSOLUCIONES ERP                      │
│                                                         │
│  Django (WSGI/ASGI)  <->  PostgreSQL                    │
│         |                                               │
│  Django Channels (ASGI) <->  Redis (Channel Layer DB1)  │
│         |                                               │
│  Celery Workers      <->  Redis (Broker DB0)            │
│  Celery Beat                                            │
│         |                                               │
│  Redis (Cache DB2)                                      │
│         |                                               │
│  Flower (monitor Celery)                                │
└─────────────────────────────────────────────────────────┘
```

---

## 1. Redis — 3 Usos Distintos

| Uso | DB Redis | Descripcion |
|-----|----------|-------------|
| Broker de Celery | DB 0 | Cola de tareas async |
| Channel Layer (WebSockets) | DB 1 | Mensajes en tiempo real via Django Channels |
| Cache general | DB 2 | Queries, JWT blacklist, presigned URLs |

### Configuracion (settings/base.py)

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
        "CONFIG": {"hosts": [(REDIS_HOST, REDIS_PORT)], "capacity": 1500, "expiry": 10},
    }
}

# Cache
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": f"redis://{REDIS_HOST}:{REDIS_PORT}/2",
        "OPTIONS": {"CLIENT_CLASS": "django_redis.client.DefaultClient"},
        "TIMEOUT": 300,  # 5 min default
    }
}
```

### TTLs de Cache Recomendados

| Dato | TTL | Justificacion |
|------|-----|---------------|
| Stock en tiempo real | 30 seg | Cambia por ventas |
| Lista productos POS | 60 seg | Alta frecuencia de lectura |
| Config empresa | 1800 seg (30 min) | Casi nunca cambia |
| Dashboard KPIs | 600 seg (10 min) | Calculos costosos |
| Tipos de cambio | 3600 seg (1h) | Se actualiza 1 vez al dia |
| Sesiones JWT | Duracion del token | Auth |
| JWT Blacklist | Hasta expiracion | Logout seguro |
| Validaciones SUNAT (RUC/DNI) | 86400 seg (1 dia) | Datos no cambian |
| Presigned URLs R2 | TTL_URL - 5min | Evitar llamadas repetidas |

### Dato que NO se cachea

- Stock en operaciones criticas (select_for_update para ventas)
- Correlativos de comprobantes (requieren consistencia exacta)
- Datos transaccionales en proceso

---

## 2. Celery — Colas y Tareas

### Configuracion global (config/celery.py)

```python
app = Celery("jsoluciones")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
app.conf.task_serializer = "json"
app.conf.timezone = "America/Lima"
app.conf.enable_utc = True
app.conf.task_acks_late = True
app.conf.task_reject_on_worker_lost = True
app.conf.task_max_retries = 3
```

### Colas por Prioridad

| Cola | Prioridad | Workers | Que procesa |
|------|-----------|---------|-------------|
| `critical` | Alta | 2 | Emision SUNAT, pagos, apertura/cierre caja |
| `default` | Normal | 2 | Tareas generales, inventario, asientos |
| `notifications` | Normal | 1 | WhatsApp, emails, push |
| `reports` | Baja | 1 | Generacion reportes, Excel/PDF |

### Rutas de Tareas por Modulo

```python
# Facturacion SUNAT — critico
"facturacion.tasks.emitir_comprobante": {"queue": "critical"},
"facturacion.tasks.reenviar_contingencia": {"queue": "critical"},
"facturacion.tasks.enviar_resumen_diario": {"queue": "critical"},

# Notificaciones
"whatsapp.tasks.enviar_mensaje": {"queue": "notifications"},
"notificaciones.tasks.enviar_email": {"queue": "notifications"},

# Reportes
"reportes.tasks.generar_excel": {"queue": "reports"},
"reportes.tasks.generar_pdf": {"queue": "reports"},
```

### Catalogo de Tareas por Modulo

#### Ventas
| Tarea | Cola | Trigger |
|-------|------|---------|
| `emitir_comprobante_por_venta` | critical | Post-venta (transaction.on_commit) |
| `calcular_comision_vendedor` | default | Post-venta |
| `alertar_cotizacion_por_vencer` | notifications | Periodica |
| `sincronizar_venta_offline` | default | On reconnect POS |

#### Inventario
| Tarea | Cola | Trigger |
|-------|------|---------|
| `verificar_stock_minimo` | default | Post-movimiento |
| `alertar_lote_por_vencer` | notifications | Periodica (diaria, 7AM) |
| `actualizar_valoracion_inventario` | default | Periodica (nocturna) |

#### Facturacion (CRITICO)
| Tarea | Cola | Trigger |
|-------|------|---------|
| `emitir_comprobante_sunat` | critical | On emit |
| `reenviar_comprobante_contingencia` | critical | Periodica (5 min) |
| `enviar_resumen_diario_sunat` | critical | Diaria (23:50 Lima) |
| `enviar_comprobante_cliente_email` | notifications | Post-emision |

#### Finanzas
| Tarea | Cola | Trigger |
|-------|------|---------|
| `calcular_intereses_mora` | default | Periodica (6AM) |
| `alertar_cxc_vencidas` | notifications | Periodica (8AM) |
| `generar_estado_resultados` | reports | Periodica (3AM) |

#### Dashboard
| Tarea | Cola | Trigger |
|-------|------|---------|
| `calcular_kpis_dashboard` | reports | Periodica (10 min) |

---

## 3. Celery Beat — Schedule de Tareas

Todas las horas son en America/Lima (no UTC):

```python
"enviar-resumen-diario-sunat": crontab(hour=23, minute=50),
"reintentar-comprobantes": cada 300 seg (5 min),
"alertar-lotes-por-vencer": crontab(hour=7, minute=0),
"actualizar-valoracion-inventario": crontab(hour=1, minute=0),
"calcular-intereses-mora": crontab(hour=6, minute=0),
"alertar-cxc-vencidas": crontab(hour=8, minute=0),
"generar-estado-resultados": crontab(hour=3, minute=0),
"precalcular-kpis-dashboard": cada 600 seg (10 min),
"invalidar-sesiones-expiradas": cada 3600 seg (1h),
"limpiar-archivos-temporales": crontab(hour=4, minute=30),
```

---

## 4. Django Channels — WebSockets

### Consumers Activos

| Consumer | Grupo WS | Quien se suscribe | Que emite |
|----------|----------|-------------------|-----------|
| `DashboardConsumer` | `dashboard_{user_id}` | Usuarios con dashboard | KPIs actualizados |
| `NotificacionesConsumer` | `notif_{user_id}` | Todos los usuarios | Notificaciones globales (badge header) |
| `FacturacionConsumer` | `factura_{user_id}` | Emisores de comprobantes | Respuesta SUNAT en tiempo real |
| `GPSConsumer` | `gps_{pedido_id}` | Seguimiento de pedidos | Coordenadas GPS del repartidor |
| `PedidosConsumer` | `pedidos_{sucursal_id}` | Operadores distribucion | Nuevos pedidos, cambios estado |

### Flujo WebSocket <-> Celery

```
Evento (venta, movimiento, GPS)
       |
  Celery Task procesa
       |
  channel_layer.group_send(grupo, mensaje)
       |
  Consumer.receive -> WebSocket -> Frontend actualiza UI
```

---

## 5. Servidor ASGI (Produccion)

```bash
# Uvicorn con workers (produccion)
uvicorn jsoluciones.asgi:application \
  --host 0.0.0.0 \
  --port 8000 \
  --workers 4 \
  --lifespan off
```

> NO usar Gunicorn para WebSockets — requiere Uvicorn o Daphne por ser ASGI.

---

## 6. Docker Compose (Desarrollo Local)

```yaml
services:
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  celery-worker-critical:
    command: celery -A config worker -Q critical -c 2 -l info

  celery-worker-default:
    command: celery -A config worker -Q default,notifications -c 2 -l info

  celery-worker-reports:
    command: celery -A config worker -Q reports -c 1 -l info

  celery-beat:
    command: celery -A config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler

  flower:
    command: celery -A config flower --port=5555
    ports: ["5555:5555"]
```

---

## 7. Recursos en Produccion

| Proceso | Instancias | RAM min | Notas |
|---------|-----------|---------|-------|
| uvicorn (ASGI) | 2-4 | 2 GB c/u | Detras de Nginx |
| celery worker critical | 2 | 1 GB | Nunca < 2 instancias |
| celery worker default,notifications | 2 | 1 GB | |
| celery worker reports | 1 | 2 GB | Reportes pesados |
| celery beat | 1 | 256 MB | NUNCA duplicar |
| redis | 1 (+replica) | 512 MB min | Habilitar persistencia RDB |
| flower | 1 | 256 MB | Solo acceso interno |

---

## 8. Cloudflare R2 (Storage)

### 3 Buckets Privados

| Bucket | Contenido | TTL Presigned URL |
|--------|-----------|-------------------|
| `j-soluciones-media` | Fotos de productos, logos | 2h |
| `j-soluciones-documentos` | XMLs, CDRs, PDFs de comprobantes | 1h |
| `j-soluciones-evidencias` | Fotos de entrega, firmas | 2h |

### Mapeo Entidad -> Bucket

```python
ENTIDAD_BUCKET_MAP = {
    'producto': 'j-soluciones-media',
    'configuracion': 'j-soluciones-media',
    'comprobante': 'j-soluciones-documentos',
    'nota': 'j-soluciones-documentos',
    'evidencia': 'j-soluciones-evidencias',
}
```

---

## 9. Monitoreo

| Herramienta | Que monitorea | Acceso |
|-------------|---------------|--------|
| Flower | Cola Celery: tareas activas, fallidas, tiempo | Puerto 5555 (interno) |
| Django Admin | `django-celery-beat`: schedule de tareas | /admin/ |
| Django Admin | `django-celery-results`: historial resultados | /admin/ |
| Sentry | Excepciones en tareas Celery | Dashboard Sentry |

### Alertas Criticas

- Cola `critical` con > 50 tareas pendientes -> alerta inmediata
- Tarea `emitir_comprobante_sunat` con > 3 reintentos -> revision manual
- Redis memoria > 80% -> escalar o limpiar cache
- Celery Beat sin heartbeat > 5 min -> reiniciar servicio

---

## 10. Notas Clave

1. **Sin multitenant** — no hay routing por tenant en las colas. Las tareas son globales por instancia.
2. **Zona horaria Peru** — todos los Beat schedules en hora Lima, no UTC.
3. **SUNAT es critico** — la cola `critical` NUNCA debe compartirse con tareas de baja prioridad.
4. **WhatsApp webhooks** — llegan por POST HTTP (no WebSocket); se procesan con Celery despues de responder 200 OK a Meta.
5. **GPS en tiempo real** — no usar DB para coordenadas frecuentes; guardar en Redis con TTL corto y persistir solo eventos de estado (despachado/entregado).
6. **Flower en produccion** — proteger con autenticacion basica o VPN, nunca exponer publicamente.
7. **Settings de testing** — `config/settings/testing.py` usa LocMemCache (sin Redis) para que los tests pasen sin Redis corriendo.
