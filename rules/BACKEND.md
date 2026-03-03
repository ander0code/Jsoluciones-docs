# JSOLUCIONES ERP — REGLAS DE BACKEND

> Eres un desarrollador senior de Django/Python.
> Este documento define los patrones, convenciones y reglas no negociables del backend.
> Aplica unicamente a Jsoluciones-be/. NO a Amatista-be/.

---

## 1. STACK (NO CAMBIAR)

| Capa | Tecnologia | Version |
|------|-----------|---------|
| Framework | Django | 4.2 |
| API | Django REST Framework | 3.14+ |
| Auth | simplejwt | 5.3+ (access 60min, refresh 7d, rotacion + blacklist) |
| DB | PostgreSQL | 16 |
| Schema | drf-spectacular | 0.29+ (OpenAPI para Orval) |
| Async | Celery + Redis | 5.3+ |
| WebSockets | Channels + Daphne | 4.0+ |
| Storage | Cloudflare R2 (boto3) | 3 buckets privados |
| Cache | Redis (LocMem en dev) | |
| Facturacion | Nubefact API via HTTP | |

---

## 2. PATRON POR APP (OBLIGATORIO)

Cada app tiene exactamente esta estructura:

```
apps/{modulo}/
  models.py        -> Modelos con mixins, db_table, indices, constraints
  serializers.py   -> SOLO validacion y transformacion (NUNCA logica de negocio)
  services.py      -> TODA la logica de negocio (@transaction.atomic)
  views.py         -> Solo orquesta: request -> service -> response
  urls.py          -> Router DRF + paths custom
  admin.py         -> Registro en Django admin
  tasks.py         -> Tareas Celery (si aplica)
```

---

## 3. REGLAS ESTRICTAS

### Logica de negocio

```
BACK-01: Toda logica de negocio va en services.py. NUNCA en views ni serializers.
BACK-02: Views solo orquestan: recibir request -> llamar service -> retornar response.
BACK-03: Serializers solo validan y transforman. NO logica, NO queries complejas.
BACK-04: Services son funciones puras (no clases). Usan keyword-only arguments.
         Retornan instancias de modelos. Errores via excepciones custom.
BACK-05: Signals solo para side-effects (logs, notificaciones). NUNCA logica principal.
```

### Transacciones y concurrencia

```
BACK-06: Toda operacion que modifique >1 tabla DEBE usar @transaction.atomic.
BACK-07: Descontar stock, correlativos de comprobante y cualquier recurso compartido
         -> select_for_update() (bloqueo pesimista para evitar race conditions).
BACK-08: Acciones post-transaccion (emails, WhatsApp, Celery tasks)
         -> transaction.on_commit() para ejecutar SOLO si la TX fue exitosa.
BACK-09: Recepciones parciales de OC -> Savepoints para que un item fallido
         no revierta los demas.
```

### Queries y performance

```
BACK-10: NUNCA queries N+1. Siempre select_related (FK directas) y
         prefetch_related (relaciones inversas/M2M) en todo queryset con relaciones.
BACK-11: Calculos de agregacion (totales, conteos) SIEMPRE en la DB
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

### Documentacion y OpenAPI

```
BACK-20: Todo ViewSet debe tener @extend_schema(tags=["..."]) a nivel de clase.
         Los tags son ASCII sin acentos (para compatibilidad con Orval).
BACK-21: Todo @action custom debe tener @extend_schema con summary y request/response.
BACK-22: Al terminar cambios en endpoints -> regenerar OpenAPI schema:
         python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml
```

### Generales

```
BACK-23: Logs con logging de Python. NUNCA print().
         logger = logging.getLogger('apps')
BACK-24: Campos monetarios -> DecimalField(max_digits=12, decimal_places=2).
         Precio unitario -> DecimalField(max_digits=12, decimal_places=4).
         Porcentajes -> DecimalField(max_digits=5, decimal_places=2).
         NUNCA FloatField para dinero.
BACK-25: Constantes en core/choices.py. NUNCA hardcodear valores de negocio en codigo.
BACK-26: Nomenclatura: espanol para modelos/campos de negocio, ingles para metodos tecnicos.
BACK-27: Cada app Django = un modulo del ERP. No mezclar logica entre apps.
BACK-28: Tareas pesadas o llamadas a APIs externas (Nubefact, R2, WhatsApp) -> Celery.
```

---

## 4. BASE DE DATOS

### Mixins Obligatorios (ya implementados en core/mixins.py)

Todo modelo hereda de uno o mas de estos:

```python
class TimestampMixin(models.Model):    # created_at, updated_at
class SoftDeleteMixin(models.Model):   # is_active, soft_delete(), restore()
class AuditMixin(models.Model):        # creado_por, actualizado_por (FK PerfilUsuario)
```

Modelos inmutables (logs, movimientos) solo usan TimestampMixin — sin SoftDelete ni Audit.

### Reglas de DB

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
DB-09: Campos de texto largo -> TextField. Cortos -> CharField con max_length.
DB-10: Las migraciones se versionan en Git (NUNCA en .gitignore).
```

### Tablas que NUNCA se borran (solo soft delete o cambio de estado)

- comprobantes, detalle_comprobantes (datos fiscales SUNAT)
- notas_credito_debito
- log_envio_nubefact
- ventas, detalle_ventas (una vez con comprobante)
- asientos_contables, detalle_asientos
- movimientos_stock (logs inmutables)
- log_actividad

Para "anular": cambiar estado a 'anulado' y crear documento inverso (nota de credito, asiento reverso).

---

## 5. EXCEPCIONES CUSTOM (ya implementadas en core/exceptions.py)

| Excepcion | HTTP | error_code | Cuando |
|-----------|------|------------|--------|
| ReglaDeNegocioError | 400 | regla_negocio | Validacion de logica generica |
| StockInsuficienteError | 400 | stock_insuficiente | Venta/transferencia sin stock |
| NubefactError | 502 | nubefact_error | Fallo comunicacion Nubefact |
| ComprobanteRechazadoError | 400 | comprobante_rechazado | SUNAT rechazo |
| CorrelativoAgotadoError | 409 | correlativo_agotado | Serie llego al limite |
| CotizacionVencidaError | 400 | cotizacion_vencida | Intentar convertir cotizacion vencida |
| LimiteCreditoExcedidoError | 400 | limite_credito_excedido | Cliente excedio credito |
| VentaNoAnulableError | 400 | venta_no_anulable | Comprobante ya aceptado SUNAT |
| PermisoInsuficienteError | 403 | permiso_insuficiente | Sin permiso RBAC |
| ArchivoInvalidoError | 400 | archivo_invalido | Upload invalido a R2 |

Formato estandar de respuesta de error (ya implementado en core/exception_handler.py):

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

## 6. PERMISOS RBAC (ya implementado en core/permissions.py)

### Clases de Permiso

```python
TienePermiso    -> Verifica required_permission del ViewSet contra permisos del rol
EsAdmin         -> Solo codigo='admin'
EsSupervisorOAdmin -> admin, gerente, supervisor
SoloSusDatos    -> Vendedores/cajeros solo ven sus registros (object-level)
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
        self.required_permission = 'ventas.anular'
        self.check_permissions(request)
        # ...
```

---

## 7. FLUJO DE VENTAS (core del negocio)

```
POST /ventas/pos/
  @transaction.atomic:
  1. Validar stock (select_for_update en Stock)
  2. Crear venta + detalle
  3. Descontar stock (crear MovimientoStock tipo 'salida')
  4. transaction.on_commit -> task emitir_comprobante_por_venta (Celery critical)

POST /ventas/{id}/anular/
  @transaction.atomic:
  1. Validar que se puede anular
  2. Cambiar estado a 'anulada'
  3. DEVOLVER stock (crear MovimientoStock tipo 'devolucion')
  4. Si tiene comprobante aceptado -> crear nota de credito
```

---

## 8. TODOS LOS ENDPOINTS (~90+ endpoints, 13 modulos)

### Auth (/api/v1/auth/)
```
POST /login/           -> JWT tokens
POST /refresh/         -> Renovar access token
POST /logout/          -> Blacklist refresh token
GET  /me/              -> Usuario actual + rol + permisos + empresa
```

### Empresa (/api/v1/empresa/)
```
GET   /                -> Config empresa (singleton)
PATCH /                -> Editar config (solo admin)
```

### Usuarios (/api/v1/usuarios/)
```
CRUD ViewSet           -> Usuarios, Roles, Permisos
GET  /roles/{id}/permisos/
```

### Clientes (/api/v1/clientes/)
```
CRUD ViewSet           -> Con validacion RUC/DNI
GET  /buscar/?q=       -> Busqueda rapida
GET  /{id}/historial/  -> Historial ventas
```

### Proveedores (/api/v1/proveedores/)
```
CRUD ViewSet           -> Con validacion RUC
GET  /buscar/?q=
```

### Inventario (/api/v1/inventario/)
```
CRUD /productos/
CRUD /categorias/
CRUD /almacenes/
GET  /stock/
GET  /movimientos/
POST /movimientos/ajuste/
POST /movimientos/transferencia/
GET  /lotes/
GET  /alertas-stock/
```

### Ventas (/api/v1/ventas/)
```
GET  /                 -> Lista (read-only)
GET  /{id}/
POST /{id}/anular/
GET  /resumen-dia/
POST /pos/             -> Venta rapida POS
CRUD /cotizaciones/    -> + duplicar, convertir-orden
CRUD /ordenes/         -> + convertir-venta
GET  /cajas/
POST /cajas/abrir/
POST /cajas/{id}/cerrar/
GET  /formas-pago/
POST /formas-pago/venta/{id}/
```

### Facturacion (/api/v1/facturacion/)
```
GET  /comprobantes/
GET  /comprobantes/{id}/
POST /comprobantes/{id}/reenviar/
POST /emitir/
GET  /notas/
POST /notas/crear/
CRUD /series/
GET  /logs/
GET  /resumenes/
```

### Media (/api/v1/media/)
```
GET  /
POST /subir/
PATCH /{id}/
DELETE /{id}/
GET  /entidad/{tipo}/{id}/
GET  /principal/{tipo}/{id}/
```

### Compras (/api/v1/compras/)
```
CRUD /ordenes/         -> + aprobar, enviar, cancelar
CRUD /facturas-proveedor/
CRUD /recepciones/
```

### Finanzas (/api/v1/finanzas/)
```
CRUD /cuentas-cobrar/
CRUD /cuentas-pagar/
POST /cobros/
POST /pagos/
CRUD /cuentas-contables/
CRUD /asientos/        -> + confirmar, anular
```

### Distribucion (/api/v1/distribucion/)
```
CRUD /transportistas/
CRUD /pedidos/         -> + asignar, despachar, en-ruta, confirmar-entrega, cancelar
GET  /pedidos/{id}/seguimiento/
POST /pedidos/{id}/evidencia/
```

### WhatsApp (/api/v1/whatsapp/)
```
GET/PATCH /configuracion/
CRUD /plantillas/
GET  /mensajes/        -> Read-only
POST /enviar/          -> Enviar (STUB — requiere credenciales Meta)
GET  /logs/
POST /webhook/         -> Meta webhook (sin auth)
```

### Reportes (/api/v1/reportes/)
```
GET  /dashboard/
GET  /ventas/
GET  /top-productos/
GET  /top-clientes/
GET  /inventario/
POST /exportar/        -> STUB
```

---

## 9. STUBS PENDIENTES

| Funcionalidad | Archivo | Dependencia |
|---------------|---------|-------------|
| WhatsApp envio real | whatsapp/services.py | Credenciales Meta |
| Validacion SUNAT proveedores | compras/tasks.py | Nubefact |
| GPS/Rastreo distribucion | distribucion/tasks.py | App movil |
| Exportar Excel/PDF | reportes/tasks.py | openpyxl/reportlab |
| Intereses de mora (logica) | finanzas/tasks.py | Reglas de negocio |
| Estado de resultados | finanzas/tasks.py | Logica contable |
| WebSocket consumers extras | core/routing.py | Comentados (Stock, POS) |

---

## 10. CHECKLIST ANTES DE CADA CAMBIO

- [ ] La logica de negocio esta en services.py?
- [ ] Los views solo orquestan?
- [ ] Se usa @transaction.atomic en operaciones multi-tabla?
- [ ] Se usa select_for_update donde hay concurrencia?
- [ ] Se usa select_related/prefetch_related en queries con relaciones?
- [ ] Hay @extend_schema(tags=[...]) en el ViewSet?
- [ ] Hay permisos en todos los endpoints?
- [ ] Se usa logging en vez de print?
- [ ] Campos monetarios son DecimalField?
- [ ] Hay paginacion en listados?
- [ ] Errores usan excepciones custom con error_code?
- [ ] Se regenero el OpenAPI schema si cambio algun endpoint?
