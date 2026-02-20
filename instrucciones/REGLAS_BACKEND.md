# JSOLUCIONES ERP — REGLAS DE BACKEND + BASE DE DATOS

> Documento unico de reglas para backend y base de datos.
> Alineado con el estado real del codigo (Feb 2026).
> Reemplaza: 02_REGLAS_BACKEND_v2.md, 03_REGLAS_BASE_DATOS.md

---

## 1. STACK REAL (NO CAMBIAR)

| Capa | Tecnologia | Version | Proposito |
|------|-----------|---------|-----------|
| Framework | Django | 4.2 | Backend web |
| API | Django REST Framework | 3.14+ | API REST |
| Auth | simplejwt | 5.3+ | JWT (access 60min, refresh 7d, rotacion + blacklist) |
| DB | PostgreSQL | 16 | Base de datos (UUIDs, JSONB, indices) |
| Schema | drf-spectacular | 0.29+ | OpenAPI/Swagger (genera schema para Orval) |
| Async | Celery + Redis | 5.3+ | Tareas en background |
| WebSockets | Channels + Daphne | 4.0+ | Notificaciones en tiempo real |
| Storage | Cloudflare R2 (boto3) | - | Archivos (3 buckets privados, presigned URLs) |
| Cache | Redis (LocMem en dev) | - | Presigned URLs, datos frecuentes |
| Facturacion | Nubefact API | - | Comprobantes electronicos SUNAT |

---

## 2. ARQUITECTURA

```
config/
  settings/base.py, development.py, production.py
  urls.py, celery.py, asgi.py

core/
  mixins.py          → TimestampMixin, SoftDeleteMixin, AuditMixin
  choices.py         → TODAS las constantes (choices, roles, estados)
  pagination.py      → StandardPagination (20/page), LargeDatasetPagination (cursor)
  permissions.py     → TienePermiso, EsAdmin, EsSupervisorOAdmin, SoloSusDatos
  exceptions.py      → Excepciones custom con error_code
  exception_handler.py → Handler global formato {success, data, message, errors, error_code}
  utils/
    validators.py    → validar_ruc, validar_dni
    r2_storage.py    → R2StorageService (upload, presigned URLs, delete, cache Redis)
    nubefact.py      → Cliente HTTP para Nubefact
  tasks/
    r2_tasks.py      → Upload async, limpiar huerfanos, precalentar cache
  management/commands/
    seed_permissions.py → Crea 8 roles + 40+ permisos
    setup_empresa.py    → Crea empresa + admin (interactivo)
    reset_password.py
    fix_perfil.py

apps/
  empresa/       → Configuracion (singleton, 1 fila)
  usuarios/      → Usuario (AbstractUser email), Rol, Permiso, PerfilUsuario, LogActividad
  clientes/      → Cliente (RUC/DNI, segmento, limite credito)
  proveedores/   → Proveedor (RUC, condiciones pago)
  inventario/    → Producto, Categoria, Almacen, Stock, MovimientoStock, Lote
  ventas/        → Cotizacion, OrdenVenta, Venta, DetalleVenta, Caja, FormaPago
  facturacion/   → Comprobante, NotaCreditoDebito, SerieComprobante, LogEnvio, ResumenDiario
  media/         → MediaArchivo (polimorfico, R2 buckets)
  compras/       → OrdenCompra, FacturaProveedor, Recepcion
  finanzas/      → CuentaPorCobrar, CuentaPorPagar, Cobro, Pago, CuentaContable, AsientoContable
  distribucion/  → Transportista, Pedido, SeguimientoPedido, EvidenciaEntrega
  whatsapp/      → ConfiguracionWA, Plantilla, Mensaje, LogWA
  reportes/      → Sin modelos propios (usa queries cross-app)
```

### Patron por app

Cada app tiene la misma estructura:

```
apps/{modulo}/
  models.py        → Modelos con mixins, db_table, indices, constraints
  serializers.py   → Validacion y transformacion (NUNCA logica de negocio)
  services.py      → TODA la logica de negocio (@transaction.atomic)
  views.py         → Solo orquesta: recibe request → llama service → retorna response
  urls.py          → Router DRF + paths custom
  admin.py         → Registro en Django admin
  tasks.py         → Tareas Celery (si aplica)
```

---

## 3. REGLAS ESTRICTAS

### Logica de negocio

```
BACK-01: Toda logica de negocio va en services.py. NUNCA en views ni serializers.
BACK-02: Views solo orquestan: recibir request → llamar service → retornar response.
BACK-03: Serializers solo validan y transforman. NO logica, NO queries complejas.
BACK-04: Services son funciones puras (no clases en el codigo actual). Usan keyword-only
         arguments. Retornan instancias de modelos. Errores via excepciones custom.
BACK-05: Signals solo para side-effects (logs, notificaciones). NUNCA logica principal.
```

### Transacciones y concurrencia

```
BACK-06: Toda operacion que modifique >1 tabla DEBE usar @transaction.atomic.
BACK-07: Descontar stock, correlativos de comprobante y cualquier recurso compartido
         → select_for_update() (bloqueo pesimista para evitar race conditions).
BACK-08: Acciones post-transaccion (emails, WhatsApp, Celery tasks)
         → transaction.on_commit() para ejecutar SOLO si la transaccion fue exitosa.
BACK-09: Recepciones parciales de OC → Savepoints (transaction.savepoint/rollback)
         para que un item fallido no revierta los demas.
```

### Queries y performance

```
BACK-10: NUNCA queries N+1. Siempre select_related (FK directas) y
         prefetch_related (relaciones inversas/M2M) en todo queryset con relaciones.
BACK-11: Calculos de agregacion (totales, conteos, promedios) SIEMPRE en la DB
         con aggregate() / annotate(). NUNCA traer todo a Python y sumar.
BACK-12: Bulk operations (bulk_create, bulk_update) para >10 registros.
BACK-13: Para tablas >100k registros (movimientos, logs) usar LargeDatasetPagination (cursor).
BACK-14: Paginacion obligatoria en TODOS los listados. Default: 20/pagina.
BACK-15: Filtros con django-filter en cada listado. SearchFilter para busqueda de texto.
```

### Seguridad y permisos

```
BACK-16: Toda vista DEBE tener permisos (IsAuthenticated minimo).
         Endpoints custom: required_permission = 'modulo.accion' + TienePermiso.
BACK-17: NUNCA retornar querysets sin filtrar. Aplicar permisos del usuario.
         Vendedores/cajeros solo ven sus datos (SoloSusDatos).
BACK-18: Rate limiting: anon=20/min, user=200/min, pos=600/min.
BACK-19: NUNCA exponer endpoints sin autenticacion salvo login, refresh y webhook WA.
```

### Documentacion

```
BACK-20: Todo ViewSet debe tener @extend_schema(tags=["..."]) a nivel de clase.
         Los tags son ASCII sin acentos (para compatibilidad con Orval).
BACK-21: Todo @action custom debe tener @extend_schema con summary y request/response.
BACK-22: Al terminar cambios en endpoints → regenerar OpenAPI schema:
         python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml
```

### Generales

```
BACK-23: Logs con logging de Python (logger = logging.getLogger('apps')). NUNCA print().
BACK-24: Campos monetarios → DecimalField(max_digits=12, decimal_places=2).
         Precio unitario → DecimalField(max_digits=12, decimal_places=4).
         Porcentajes → DecimalField(max_digits=5, decimal_places=2).
         NUNCA FloatField para dinero.
BACK-25: Constantes en core/choices.py. NUNCA hardcodear valores de negocio en codigo.
BACK-26: Nomenclatura: espanol para modelos/campos de negocio, ingles para metodos tecnicos.
BACK-27: Cada app Django = un modulo del ERP. No mezclar logica entre apps.
BACK-28: Tareas pesadas o llamadas a APIs externas (Nubefact, R2, WhatsApp) → Celery.
```

---

## 4. BASE DE DATOS

### Mixins obligatorios (core/mixins.py — ya implementados)

Todo modelo hereda de estos:

```python
class TimestampMixin(models.Model):    # created_at, updated_at
class SoftDeleteMixin(models.Model):   # is_active, soft_delete(), restore()
class AuditMixin(models.Model):        # creado_por, actualizado_por (FK PerfilUsuario)
```

Modelos inmutables (logs, movimientos) solo usan TimestampMixin, sin SoftDelete ni Audit.

### Reglas de base de datos

```
DB-01: NUNCA modificar tablas/columnas existentes sin autorizacion del usuario.
DB-02: NUNCA eliminar migraciones. Solo crear nuevas.
DB-03: Toda tabla tiene: id (UUID PK), created_at, updated_at. Excepciones: M2M intermedias.
DB-04: Soft delete (is_active=False). NUNCA DELETE en registros contables/fiscales.
DB-05: Toda FK tiene on_delete explicito:
       - PROTECT para entidades referenciadas (cliente, producto, proveedor)
       - CASCADE solo para detalles que NO tienen sentido sin cabecera
       - SET_NULL para campos opcionales (creado_por, actualizado_por)
DB-06: Indices compuestos en tablas de alto volumen (movimientos, detalles, comprobantes).
DB-07: unique_together o UniqueConstraint donde la logica lo requiere.
DB-08: NUNCA raw SQL sin justificacion documentada.
DB-09: Campos de texto largo → TextField. Cortos → CharField con max_length.
DB-10: Las migraciones se versionan en Git (NUNCA en .gitignore).
```

### Tablas que NUNCA se borran (solo soft delete / cambio de estado)

```
- comprobantes, detalle_comprobantes (datos fiscales SUNAT)
- notas_credito_debito
- log_envio_nubefact
- ventas, detalle_ventas (una vez con comprobante)
- asientos_contables, detalle_asientos
- movimientos_stock (son logs inmutables)
- log_actividad
```

Para "anular": cambiar estado a 'anulado' y crear documento inverso (nota de credito, asiento reverso).

### Protocolo para cambios en DB

```
1. Describir el cambio al usuario (campo, tipo, motivo, impacto)
2. Esperar aprobacion EXPLICITA
3. Crear migracion (makemigrations)
4. Mostrar resultado al usuario
5. NUNCA aplicar migrate automaticamente en produccion sin backup
```

---

## 5. EXCEPCIONES (core/exceptions.py — ya implementadas)

Todas extienden APIException con status_code, default_detail, default_code:

| Excepcion | Codigo HTTP | error_code | Cuando se usa |
|-----------|-------------|-----------|---------------|
| ReglaDeNegocioError | 400 | regla_negocio | Validacion de logica generica |
| StockInsuficienteError | 400 | stock_insuficiente | Venta/transferencia sin stock |
| NubefactError | 502 | nubefact_error | Fallo comunicacion Nubefact |
| ComprobanteRechazadoError | 400 | comprobante_rechazado | SUNAT rechazo |
| CorrelativoAgotadoError | 409 | correlativo_agotado | Serie llego al limite |
| CotizacionVencidaError | 400 | cotizacion_vencida | Intentar convertir cotizacion vencida |
| LimiteCreditoExcedidoError | 400 | limite_credito_excedido | Cliente excedio credito |
| VentaNoAnulableError | 400 | venta_no_anulable | Comprobante ya aceptado SUNAT |
| OrdenNoAprobadaError | 400 | orden_no_aprobada | OC sin aprobar |
| PermisoInsuficienteError | 403 | permiso_insuficiente | Sin permiso RBAC |
| ArchivoInvalidoError | 400 | archivo_invalido | Upload invalido a R2 |

El custom_exception_handler envuelve TODO en formato estandar:

```json
{
  "success": false,
  "data": null,
  "message": "Stock insuficiente para Laptop HP.",
  "errors": [],
  "error_code": "stock_insuficiente"
}
```

---

## 6. PERMISOS RBAC (core/permissions.py — ya implementados)

### 8 roles base

| Rol | Codigo | Modulos |
|-----|--------|---------|
| Administrador | admin | TODOS |
| Gerente | gerente | Dashboard, Ventas, Inventario, Compras, Finanzas, Reportes |
| Supervisor | supervisor | Ventas, Inventario, Clientes, Compras, Reportes |
| Vendedor | vendedor | Ventas, Clientes, Inventario (consulta stock) |
| Cajero | cajero | POS, Ventas (solo crear) |
| Almacenero | almacenero | Inventario, Compras (solo recepcion) |
| Contador | contador | Finanzas, Facturacion (consulta), Reportes |
| Repartidor | repartidor | Distribucion (solo sus pedidos) |

### Clases de permiso

```python
TienePermiso    → Verifica required_permission del ViewSet contra permisos del rol
EsAdmin         → Solo codigo='admin'
EsSupervisorOAdmin → admin, gerente, supervisor
SoloSusDatos    → Vendedores/cajeros solo ven sus registros (object-level)
```

### Formato de permisos: modulo.accion

```
ventas.ver, ventas.crear, ventas.anular, ventas.pos
inventario.ver, inventario.stock_ajustar, inventario.transferir
facturacion.ver, facturacion.emitir, facturacion.anular
clientes.ver, clientes.crear, clientes.editar
compras.ver, compras.crear_oc, compras.aprobar_oc, compras.recepcionar
finanzas.ver, finanzas.registrar_pago, finanzas.asientos
distribucion.ver, distribucion.asignar, distribucion.actualizar_estado
reportes.ver, reportes.exportar
```

### Uso en ViewSets

```python
class VentaViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, TienePermiso]
    required_permission = 'ventas.ver'

    @action(detail=True, methods=['post'])
    def anular(self, request, pk=None):
        # Override para accion especifica
        self.required_permission = 'ventas.anular'
        self.check_permissions(request)
        # ...
```

---

## 7. CACHE (Redis)

### Que cachear y que NO

| Dato | Cachear | TTL | Razon |
|------|---------|-----|-------|
| Presigned URLs de R2 | SI | TTL_URL - 5min | Evitar llamadas repetidas a R2 |
| Config de la empresa | SI | 30 min | Casi nunca cambia |
| Dashboard KPIs | SI | 1-2 min | Reduce carga de queries pesados |
| Stock en tiempo real | NO | - | Cambia constantemente |
| Correlativos de comprobantes | NO | - | Requiere consistencia exacta |
| Datos transaccionales (ventas en proceso) | NO | - | Volatiles |

### Invalidacion

Al modificar datos cacheados, invalidar el cache correspondiente:

```python
from django.core.cache import cache
cache.delete(f'catalogo_{almacen_id}')
```

---

## 8. CLOUDFLARE R2 (ya implementado)

### Arquitectura

- 3 buckets privados: j-soluciones-media, j-soluciones-documentos, j-soluciones-evidencias
- Presigned URLs temporales (1-2h segun bucket)
- Cache Redis para presigned URLs (expira 5min antes del TTL)
- R2StorageService (core/utils/r2_storage.py): upload, presigned URL, delete, validacion

### Mapeo entidad → bucket

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

## 9. FLUJO DE VENTAS (el core del negocio)

```
Cotizacion (opcional)
  → POST /ventas/cotizaciones/
  → POST /cotizaciones/{id}/convertir-orden/
        ↓
Orden de Venta (opcional)
  → POST /ventas/ordenes/
  → POST /ordenes/{id}/convertir-venta/
        ↓
Venta (POS o desde orden)
  → POST /ventas/pos/
  → @transaction.atomic:
    1. Validar stock (select_for_update)
    2. Crear venta + detalle
    3. Descontar stock (crear MovimientoStock tipo 'salida')
    4. Generar comprobante via Nubefact (o marcar pendiente si falla)
    5. transaction.on_commit → notificacion
        ↓
Facturacion
  → POST /facturacion/emitir/
  → Nubefact API → PDF/XML guardados como R2 keys
  → Si falla: estado='error', tarea Celery reintenta
        ↓
Cobro (si es credito)
  → POST /finanzas/cobros/
  → Actualiza CuentaPorCobrar.monto_pendiente
```

### Anulacion de venta

```
POST /ventas/{id}/anular/
  @transaction.atomic:
  1. Validar que se puede anular (no ya anulada)
  2. Cambiar estado a 'anulada'
  3. DEVOLVER stock (crear MovimientoStock tipo 'devolucion')
  4. Si tiene comprobante aceptado → crear nota de credito
```

---

## 10. TODOS LOS ENDPOINTS (13 modulos, ~90+ endpoints)

### Auth (/api/v1/auth/)
```
POST /login/          → JWT tokens
POST /refresh/        → Renovar access token
POST /logout/         → Blacklist refresh token
GET  /me/             → Usuario actual + rol + permisos + empresa
```

### Empresa (/api/v1/empresa/)
```
GET   /               → Config empresa (singleton)
PATCH /               → Editar config (solo admin)
```

### Usuarios (/api/v1/usuarios/)
```
CRUD ViewSet          → Usuarios, Roles, Permisos
GET  /roles/{id}/permisos/ → Permisos del rol
```

### Clientes (/api/v1/clientes/)
```
CRUD ViewSet          → Clientes con validacion RUC/DNI
GET  /buscar/?q=      → Busqueda rapida
GET  /{id}/historial/ → Historial ventas (stub)
```

### Proveedores (/api/v1/proveedores/)
```
CRUD ViewSet          → Proveedores con validacion RUC
GET  /buscar/?q=      → Busqueda rapida
```

### Inventario (/api/v1/inventario/)
```
CRUD /productos/              → Con filtros, busqueda, stock
CRUD /categorias/
CRUD /almacenes/
GET  /stock/                  → Stock por almacen (read-only)
GET  /movimientos/            → Historial (read-only)
POST /movimientos/ajuste/     → Ajuste manual
POST /movimientos/transferencia/ → Transferencia entre almacenes
GET  /lotes/
GET  /alertas-stock/          → Stock bajo minimo
```

### Ventas (/api/v1/ventas/)
```
GET  /                        → Lista ventas (read-only)
GET  /{id}/                   → Detalle
POST /{id}/anular/            → Anular (devuelve stock)
GET  /resumen-dia/            → Resumen del dia
POST /pos/                    → Venta rapida POS
CRUD /cotizaciones/           → + duplicar, convertir-orden
CRUD /ordenes/                → + convertir-venta
GET  /cajas/                  → Lista cajas
POST /cajas/abrir/            → Abrir caja
POST /cajas/{id}/cerrar/      → Cerrar caja
GET  /formas-pago/            → Formas de pago
POST /formas-pago/venta/{id}/ → Registrar pagos parciales
```

### Facturacion (/api/v1/facturacion/)
```
GET  /comprobantes/           → Lista (read-only)
GET  /comprobantes/{id}/      → Detalle con PDF/XML
POST /comprobantes/{id}/reenviar/ → Reenviar a Nubefact
POST /emitir/                 → Emitir desde venta
GET  /notas/                  → Notas credito/debito
POST /notas/crear/            → Crear nota
CRUD /series/                 → Series de comprobantes
GET  /logs/                   → Logs de envio Nubefact
GET  /resumenes/              → Resumenes diarios
```

### Media (/api/v1/media/)
```
GET  /                        → Lista archivos
POST /subir/                  → Upload a R2
PATCH /{id}/                  → Actualizar metadata
DELETE /{id}/                 → Soft delete
GET  /entidad/{tipo}/{id}/    → Archivos por entidad
GET  /principal/{tipo}/{id}/  → Imagen principal
```

### Compras (/api/v1/compras/)
```
CRUD /ordenes/                → + aprobar, enviar, cancelar
CRUD /facturas-proveedor/     → + anular
CRUD /recepciones/            → Ingreso stock
```

### Finanzas (/api/v1/finanzas/)
```
CRUD /cuentas-cobrar/
CRUD /cuentas-pagar/
POST /cobros/                 → Registrar cobro
POST /pagos/                  → Registrar pago
CRUD /cuentas-contables/      → Plan contable
CRUD /asientos/               → + confirmar, anular
```

### Distribucion (/api/v1/distribucion/)
```
CRUD /transportistas/
CRUD /pedidos/                → + asignar, despachar, en-ruta, confirmar-entrega, cancelar
GET  /pedidos/{id}/seguimiento/
POST /pedidos/{id}/evidencia/
```

### WhatsApp (/api/v1/whatsapp/)
```
GET/PATCH /configuracion/
CRUD /plantillas/
GET  /mensajes/               → Read-only
POST /enviar/                 → Enviar (stub)
GET  /logs/
POST /webhook/                → Meta webhook (sin auth)
```

### Reportes (/api/v1/reportes/)
```
GET  /dashboard/              → KPIs
GET  /ventas/                 → Reporte ventas por periodo
GET  /top-productos/          → Mas vendidos
GET  /top-clientes/           → Mejores clientes
GET  /inventario/             → Resumen inventario
POST /exportar/               → Exportar (stub)
```

---

## 11. STUBS PENDIENTES

| Funcionalidad | Archivo | Dependencia |
|---------------|---------|-------------|
| WhatsApp envio real | whatsapp/services.py | Credenciales Meta |
| Validacion SUNAT proveedores | compras/tasks.py | Nubefact |
| GPS/Rastreo distribucion | distribucion/tasks.py | App movil |
| Exportar Excel/PDF | reportes/tasks.py | openpyxl/reportlab |
| Intereses de mora | finanzas/tasks.py | Reglas de negocio |
| Estado de resultados | finanzas/tasks.py | Logica contable |
| Historial ventas de cliente | clientes/views.py:121 | Logica interna |
| WebSocket consumers extras | core/routing.py | Comentados (Stock, POS, GPS) |

---

## 12. REGENERAR OPENAPI SCHEMA

Cuando se modifiquen endpoints:

```bash
# En el directorio del backend
python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml

# Luego en el frontend
cd ../Jsoluciones-fe
pnpm orval
pnpm tsc --noEmit
```

---

## 13. MANAGEMENT COMMANDS

```bash
python manage.py seed_permissions    # Crear 8 roles + 40+ permisos
python manage.py setup_empresa       # Crear empresa + admin (interactivo)
python manage.py reset_password      # Resetear password de usuario
python manage.py fix_perfil          # Reparar perfil de usuario
python manage.py spectacular --file schema.yaml  # Generar OpenAPI schema
```

---

## 14. CHECKLIST ANTES DE CADA CAMBIO

- [ ] La logica de negocio esta en services.py?
- [ ] Los views solo orquestan?
- [ ] Se usa @transaction.atomic en operaciones multi-tabla?
- [ ] Se usa select_for_update donde hay concurrencia?
- [ ] Se usa select_related/prefetch_related en queries con relaciones?
- [ ] Hay @extend_schema(tags=[...]) en el ViewSet?
- [ ] Hay permisos en todos los endpoints?
- [ ] Se usa logging en vez de print?
- [ ] Campos monetarios son DecimalField (no Float)?
- [ ] Hay paginacion en listados?
- [ ] Errores usan excepciones custom con error_code?
- [ ] Se regenero el OpenAPI schema si cambio algun endpoint?

---

*Documento unico backend + DB. Feb 2026. Alineado con codigo real.*
