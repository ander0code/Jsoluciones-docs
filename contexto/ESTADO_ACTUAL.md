# JSOLUCIONES ERP — ESTADO ACTUAL

> Ultima actualizacion: 2026-02-20
> Version: Integracion Cloudflare R2 v2 completada — presigned URLs + cache Redis

---

## ESTADO DEL BACKEND

| Modulo | Modelos | Serializers | Services | Views | URLs | Tasks | Estado |
|--------|---------|-------------|----------|-------|------|-------|--------|
| empresa | ✅ | ✅ | ✅ | ✅ | ✅ | - | **100%** |
| usuarios | ✅ | ✅ | ✅ | ✅ | ✅ | - | **100%** |
| clientes | ✅ | ✅ | ✅ | ✅ | ✅ | - | **100%** |
| proveedores | ✅ | ✅ | ✅ | ✅ | ✅ | - | **100%** |
| inventario | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **100%** |
| ventas | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **100%** (incl. Cajas y FormasPago) |
| facturacion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **100%** (incl. ResumenDiario) |
| media | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **R2 v2 integrado** |
| compras | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **100%** |
| finanzas | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **100%** |
| distribucion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **100%** |
| whatsapp | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **Stubs** (Meta API pendiente) |
| reportes | - | ✅ | ✅ | ✅ | ✅ | ✅ | **Stubs** (export pendiente) |

**Total:** 13 modulos registrados en config/urls.py

---

## ENDPOINTS POR MÓDULO

### Inventario (`/api/v1/inventario/`)
```
GET/POST     /categorias/           — CRUD categorías
GET/POST     /productos/            — CRUD productos
GET/POST     /almacenes/            — CRUD almacenes
GET          /stock/                — Stock por almacén
GET/POST     /movimientos/          — Movimientos de stock
GET          /lotes/                — Lotes (fecha vencimiento)
GET          /alertas/stock-minimo/ — Alertas de stock bajo
```

### Ventas (`/api/v1/ventas/`)
```
GET/POST     /cotizaciones/                    — CRUD cotizaciones
POST         /cotizaciones/{id}/duplicar/      — Duplicar
POST         /cotizaciones/{id}/convertir-orden/ — Convertir a orden
GET/POST     /ordenes/                         — CRUD ordenes de venta
POST         /ordenes/{id}/convertir-venta/    — Convertir a venta
GET          /                                 — Listar ventas (read-only)
GET          /{id}/                            — Detalle venta
POST         /{id}/anular/                     — Anular (devuelve stock)
GET          /resumen-dia/                     — Resumen del dia
POST         /pos/                             — POS rapido
GET          /cajas/                           — Listar cajas
GET          /cajas/{id}/                      — Detalle caja
POST         /cajas/abrir/                     — Abrir caja (valida 1 por usuario)
POST         /cajas/{id}/cerrar/               — Cerrar caja (calcula diferencia)
GET          /formas-pago/                     — Listar formas de pago
GET          /formas-pago/{id}/                — Detalle forma de pago
POST         /formas-pago/venta/{venta_id}/    — Registrar pagos parciales
```

### Facturacion (`/api/v1/facturacion/`)
```
GET/POST     /series/                    — Series de comprobantes
GET          /comprobantes/              — Listar comprobantes (read-only)
GET          /comprobantes/{id}/         — Detalle con PDF/XML links
POST         /comprobantes/{id}/reenviar/ — Reenviar a Nubefact
GET          /comprobantes/{id}/notas/   — Notas del comprobante
GET          /comprobantes/{id}/logs/    — Logs de envio
POST         /emitir/                    — Emitir desde venta
GET          /notas/                     — Listar notas credito/debito
POST         /notas/crear/               — Crear nota credito/debito
GET          /logs/                      — Logs de envio Nubefact
GET          /resumenes/                 — Listar resumenes diarios
GET          /resumenes/{id}/            — Detalle resumen diario
```

### Media (`/api/v1/media/`)
```
GET/POST     /                           — CRUD archivos (listar, obtener)
POST         /subir/                     — Subir archivo a R2
PATCH        /{id}/                      — Actualizar metadata
DELETE       /{id}/                      — Eliminar archivo (soft delete)
GET          /entidad/{tipo}/{id}/       — Archivos por entidad
GET          /principal/{tipo}/{id}/     — Imagen principal
```

### Clientes (`/api/v1/clientes/`)
```
GET/POST     /                           — CRUD clientes
GET          /{id}/                      — Detalle
GET          /buscar/?q=                 — Busqueda rapida (nombre, doc, comercial)
GET          /{id}/historial/            — Historial de ventas (stub CAPA-5)
```

### Compras (`/api/v1/compras/`)
```
GET/POST     /ordenes/                    — CRUD órdenes de compra
POST         /ordenes/{id}/aprobar/       — Aprobar OC
POST         /ordenes/{id}/enviar/        — Marcar enviada
POST         /ordenes/{id}/cancelar/      — Cancelar OC
GET/POST     /facturas-proveedor/         — Facturas de proveedor
GET/POST     /recepciones/                — Recepciones (ingreso stock)
```

### Finanzas (`/api/v1/finanzas/`)
```
GET/POST     /cuentas-por-cobrar/         — CxC (desde ventas)
GET/POST     /cuentas-por-pagar/          — CxP (desde compras)
POST         /cobros/                     — Registrar cobro
POST         /pagos/                      — Registrar pago
GET/POST     /cuentas-contables/          — Plan contable
GET/POST     /asientos-contables/         — Asientos (debe=haber)
```

### Distribución (`/api/v1/distribucion/`)
```
GET/POST     /transportistas/             — CRUD transportistas
GET/POST     /pedidos/                    — CRUD pedidos
POST         /pedidos/{id}/asignar/       — Asignar transportista
POST         /pedidos/{id}/despachar/     — Marcar despachado
POST         /pedidos/{id}/en-ruta/       — Marcar en ruta
POST         /pedidos/{id}/entregar/      — Confirmar entrega
POST         /pedidos/{id}/cancelar/      — Cancelar pedido
```

### WhatsApp (`/api/v1/whatsapp/`)
```
GET/PATCH    /configuracion/              — Configurar WhatsApp
GET/POST     /plantillas/                 — CRUD plantillas
GET/POST     /mensajes/                   — CRUD mensajes
POST         /enviar/                     — Enviar mensaje
GET          /logs/                       — Logs de mensajes
POST         /webhook/                    — Webhook de Meta (sin auth)
```

### Reportes (`/api/v1/reportes/`)
```
GET          /dashboard/kpis/             — KPIs del dashboard
GET          /ventas/                     — Reporte de ventas
GET          /top-productos/              — Productos más vendidos
GET          /top-clientes/               — Mejores clientes
GET          /inventario/                 — Resumen de inventario
POST         /exportar/                   — Exportar (stub)
```

---

## FLUJO ECOMMERCE/VENTAS

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUJO DE VENTAS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. CATÁLOGO (Inventario)                                       │
│     GET /inventario/productos/                                  │
│     ↓                                                           │
│  2. COTIZACIÓN (Opcional)                                       │
│     POST /ventas/cotizaciones/                                  │
│     POST /cotizaciones/{id}/convertir-orden/                    │
│     ↓                                                           │
│  3. ORDEN DE VENTA                                              │
│     POST /ventas/ordenes/                                       │
│     POST /ordenes/{id}/convertir-venta/                         │
│     ↓                                                           │
│  4. VENTA (POS)                                                 │
│     POST /ventas/pos/ → Stock descontado automáticamente        │
│     ↓                                                           │
│  5. FACTURACIÓN                                                 │
│     POST /facturacion/emitir/ → Envía a Nubefact                │
│     ↓                                                           │
│  6. COBRO                                                       │
│     POST /finanzas/cobros/ → Actualiza CxC                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## AUDITORIA BACKEND (2026-02-19)

### Bugs corregidos

| # | Archivo | Problema | Solucion |
|---|---------|----------|----------|
| 1 | `usuarios/serializers/auth.py:110` | `return None` duplicado | Eliminado |
| 2 | `usuarios/serializers/auth.py:107` | `except:` sin tipo | `except Exception:` |
| 3 | `usuarios/views/auth.py:51` | `except:` sin tipo | `except Exception:` |
| 4 | `clientes/views.py:53-56` | `get_permissions()` redundante (ambas ramas iguales) | Metodo eliminado |
| 5 | `ventas/services.py` | Imports inline innecesarios en `crear_venta_directa` y `anular_venta` | Movidos a top-level (excepto Comprobante: circular) |
| 6 | `clientes/views.py:105-113` | Busqueda con `\|` entre querysets separados (3 queries) | Refactorizado a `Q()` (1 query) |
| 7 | `inventario/views.py:152-158` | Mismo patron ineficiente de busqueda | Refactorizado a `Q()` (1 query) |

### Endpoints creados (faltaban para modelos existentes)

| Endpoint | Modelo | Descripcion |
|----------|--------|-------------|
| `/api/v1/ventas/cajas/` | `Caja` | CRUD + apertura/cierre con validacion y calculo de diferencia |
| `/api/v1/ventas/formas-pago/` | `FormaPago` | Read + registro multi-pago por venta |
| `/api/v1/facturacion/resumenes/` | `ResumenDiario` | Read-only resumen diario boletas SUNAT |

### OpenAPI schema

- Regenerado con `python manage.py spectacular` (0 errores, 6 warnings)
- Copiado a `Jsoluciones-fe/openapi-schema.yaml`
- Todos los endpoints incluidos (cajas, formas-pago, resumenes, media)

---

## INTEGRACION CLOUDFLARE R2 v2 (2026-02-20)

> Spec completo: `Jsoluciones-docs/contexto/JSOLUCIONES_R2_INTEGRACION_v2.md`

### Arquitectura

- **3 buckets privados**: `j-soluciones-media`, `j-soluciones-documentos`, `j-soluciones-evidencias`
- **Presigned URLs** temporales para todo acceso a archivos (nunca URLs publicas)
- **Cache Redis** para presigned URLs (evita llamadas repetidas a R2)
- **TTL**: URLs duran 1-2h segun bucket, cache Redis expira 5min antes

### Cambios DB (migraciones aplicadas)

| ID | Tabla | Cambio |
|----|-------|--------|
| R2-01 | `media_archivos` | `tamano_bytes` Integer → BigInteger |
| R2-02 | `media_archivos` | Nuevo campo `bucket_name` (identifica bucket) |
| R2-03 | `media_archivos` | `url_publica` → `url_legacy` (no hay URLs publicas) |
| R2-06 | `evidencias_entrega` | Nuevo FK `media_id` → `media_archivos` |
| R2-07 | `comprobantes` + `notas_credito_debito` | `pdf_url/xml_url/cdr_url` → `pdf_r2_key/xml_r2_key/cdr_r2_key` |
| R2-08 | `media_archivos` | Nuevo campo `r2_metadata` JSONB |
| R2-09 | `configuracion` | Nuevo FK `logo_media_id` → `media_archivos` |
| R2-10 | `media_archivos` | Nuevos indices: `idx_media_bucket`, `idx_media_bucket_entidad` |

### Migraciones creadas

| App | Archivo | Contenido |
|-----|---------|-----------|
| media | `0002_r2_v2_integracion.py` | R2-01, R2-02, R2-03, R2-08, R2-10 |
| facturacion | `0003_r2_v2_integracion.py` | R2-07 (RenameField para preservar datos) |
| facturacion | `0004_alter_comprobante_cdr_r2_key_and_more.py` | Alineacion help_text |
| distribucion | `0002_r2_v2_integracion.py` | R2-06 |
| empresa | `0002_r2_v2_integracion.py` | R2-09 |

### Backend — Archivos modificados/creados

| Archivo | Cambio |
|---------|--------|
| `config/settings/base.py` | R2 section reescrita: `R2_BUCKETS` dict (3 buckets), TTLs, cache TTLs |
| `core/choices.py` | +6 `ENTIDAD_MEDIA_CHOICES`, +2 `TIPO_ARCHIVO_CHOICES` (video, audio) |
| `core/utils/r2_storage.py` | Reescrito como `R2StorageService` clase con: lazy boto3, upload, presigned URLs + Redis cache, delete, validaciones |
| `core/tasks/r2_tasks.py` | **NUEVO** — 4 tareas Celery: `upload_archivo_r2_async`, `eliminar_archivo_r2`, `limpiar_archivos_huerfanos`, `precalentar_cache_presigned_urls` |
| `config/celery.py` | +4 task routes R2, +1 beat schedule (`limpiar_archivos_huerfanos` a las 4:30 AM) |
| `apps/media/models.py` | Campos R2 v2 (bucket_name, url_legacy, r2_metadata, BigInt) |
| `apps/media/services.py` | Reescrito: `ENTIDAD_BUCKET_MAP`, `get_url_archivo()`, usa `r2_service` singleton |
| `apps/media/serializers.py` | `url` campo via `SerializerMethodField` (presigned URL desde Redis) |
| `apps/facturacion/models.py` | `pdf_url→pdf_r2_key`, `xml_url→xml_r2_key`, `cdr_url→cdr_r2_key` |
| `apps/facturacion/serializers.py` | R2 keys + presigned URL fields calculados (`pdf_url`, `xml_url`, `cdr_url`) |
| `apps/facturacion/services.py` | 3 funciones actualizadas + `guardar_documentos_sunat()` + `get_pdf_url_comprobante()` |
| `apps/distribucion/models.py` | FK `media` en `EvidenciaEntrega` |
| `apps/empresa/models.py` | FK `logo_media` en `Configuracion` |

### Swagger/OpenAPI tags fix

Todos los views ahora tienen `@extend_schema(tags=["..."])` a nivel de clase para que Swagger agrupe correctamente los endpoints bajo sus tags declarados. Tags usan nombres ASCII (sin acentos) para compatibilidad con Orval.

| Vista | Tag | Estado |
|-------|-----|--------|
| `inventario/views.py` | Inventario | ✅ |
| `compras/views.py` | Compras | ✅ |
| `distribucion/views.py` | Distribucion | ✅ |
| `finanzas/views.py` | Finanzas | ✅ |
| `reportes/views.py` | Reportes | ✅ |
| `ventas/views.py` | Ventas | ✅ |
| `whatsapp/views.py` | WhatsApp | ✅ |
| `empresa/views.py` | Empresa | ✅ |
| `facturacion/views.py` (6 clases) | Facturacion | ✅ |
| `media/views.py` | Media | ✅ |
| `usuarios/views/usuarios.py` (PermisoViewSet) | Usuarios | ✅ |

### Frontend — Cambios

| Cambio | Detalle |
|--------|---------|
| OpenAPI schema regenerado | `openapi-schema.yaml` refleja todos los campos R2 v2 + tags corregidos |
| Orval regenerado (limpio) | `src/api/generated/` y `src/api/models/` regenerados desde cero |
| Modulos Orval consolidados | Tags padre (no subtags) → un modulo por dominio: `inventario/`, `reportes/`, `facturacion/`, `ventas/`, `finanzas/`, etc. |
| Imports actualizados | Todos los imports frontend apuntan a los nuevos paths de modulos Orval |
| Tipos generados | `ComprobanteList` tiene `pdf_r2_key` + `pdf_url` (presigned), `MediaArchivo` tiene `url` (presigned), `r2_key`, `bucket_name` |
| `InvoiceList.tsx` | Sin cambios necesarios — `pdf_url` sigue disponible como campo calculado |
| Tipos manuales | `src/types/erp/index.ts` actualizado con campos R2 |
| Dashboard hooks | Corregidos para pasar params obligatorios (fecha_inicio, fecha_fin) |
| Build | `tsc -b && vite build` pasa sin errores |

### Infraestructura

| Componente | Estado |
|------------|--------|
| PostgreSQL | Corriendo (servicio del sistema) |
| Redis | Corriendo (localhost:6379, usado para cache presigned URLs + Celery) |
| R2 credentials | Vacias en `.env` (buckets no creados aun en Cloudflare) |

---

## STUBS PENDIENTES

| Funcionalidad | Archivo | Depende de |
|---------------|---------|------------|
| WhatsApp Meta API | `whatsapp/services.py` | Credenciales Meta |
| Validación SUNAT | `compras/tasks.py` | Nubefact |
| GPS/Rastreo | `distribucion/tasks.py` | App móvil |
| Exportar Excel/PDF | `reportes/tasks.py` | Librerías Python |
| Intereses de mora | `finanzas/tasks.py` | Lógica interna |
| Estado de resultados | `finanzas/tasks.py` | Lógica contable |

Ver `PLAN_INTEGRACION.md` para detalles de implementación.

---

## ESTADO DEL FRONTEND

| Componente | Estado |
|------------|--------|
| React 19 + Vite 7 + TypeScript 5.8 | ✅ Configurado |
| Tailwind CSS 4 + Tailwick Template | ✅ Instalado |
| React Router v7 | ✅ Configurado |
| TanStack React Query v5 | ✅ Configurado |
| Orval v8 (generacion de tipos/hooks) | ✅ Regenerado con R2 v2 |
| Auth Context + Protected Routes | ✅ Funcional |
| Login Page | ✅ Implementado |
| Dashboard (KPIs, top clientes/productos) | ✅ Conectado a API real |
| Lista de comprobantes (facturacion) | ✅ Conectado a API real + descarga PDF |
| Lista de ventas/ordenes | ✅ Conectado a API real |
| Detalle de producto | ✅ Conectado a API real |
| Tipos Orval R2 v2 | ✅ `pdf_r2_key`, `pdf_url` (presigned), `bucket_name`, `url` (media) |
| Build produccion (`tsc -b && vite build`) | ✅ 0 errores |
| Vistas restantes del ERP | ⬜ Pendiente |

---

## ARCHIVOS DE CONTEXTO ACTIVOS

| Archivo | Uso |
|---------|-----|
| `ESTADO_ACTUAL.md` | Este archivo — Estado actual del proyecto |
| `JSOLUCIONES_R2_INTEGRACION_v2.md` | Spec completo de integracion R2 v2 (referencia, ya implementado) |
| `PLAN_INTEGRACION.md` | Plan para implementar stubs pendientes |
| `Jsoluciones_Logistica_Backend.md` | Spec de logica de negocio de los 9 modulos backend |
| `Jsoluciones_devops_service.md` | Infraestructura: Redis, Celery, Channels, ASGI |
| `Jsoluciones_roles_flujos.MD` | 10 roles + todos los flujos UX por rol |
| `10 _mapa_template_tailwick.md` | Mapeo de rutas del template Tailwick (22 usadas / 21 diferidas / 41 ignoradas) |
| `TEMPLATE_COMPONENTES_A_USAR.md` | Componentes validados contra SQL/backend real |

### Archivos movidos a `historial/`

| Archivo | Razon |
|---------|-------|
| `17_INTEGRACION_CLOUDFARE.MD` | Supersedido por R2 v2 (usaba 1 bucket con URLs publicas) |
| `JSOLUCIONES_TEMPLATE_MAPING.MD` | Reemplazado por `TEMPLATE_COMPONENTES_A_USAR.md` (referenciaba entidades inexistentes) |

---

## PROXIMOS PASOS

1. **Cloudflare R2** — Crear los 3 buckets en el dashboard de Cloudflare, llenar credenciales en `.env`
2. **Frontend** — Crear vistas React restantes conectadas a endpoints (POS, inventario, clientes, detalle facturacion)
3. **Integraciones** — Implementar stubs segun PLAN_INTEGRACION.md
4. **Flujos faltantes** — ~30% flujos core y ~60% flujos secundarios (ver Jsoluciones_roles_flujos.MD)
5. **Sucursales** — Actualmente es un campo string; evaluar si necesita tabla dedicada
