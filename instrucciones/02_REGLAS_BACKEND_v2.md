# JSOLUCIONES ERP — REGLAS DE BACKEND v2 (Django + DRF)

> Versión mejorada. Incluye: documentación Swagger, manejo de transacciones,
> optimización de queries, definición completa de roles y permisos, caché,
> manejo avanzado de errores y buenas prácticas de ERP/ecommerce.

---

## 1. REGLAS ESTRICTAS DEL BACKEND (Ampliadas)

```
BACK-01: Toda lógica de negocio va en services.py, NUNCA en views ni serializers.
BACK-02: Los views solo orquestan: reciben request → llaman service → devuelven response.
BACK-03: Serializers solo validan y transforman datos. NO lógica de negocio.
BACK-04: Toda vista de API debe tener permisos (IsAuthenticated + permiso por rol mínimo).
BACK-05: NUNCA exponer endpoints sin autenticación salvo los explícitamente públicos.
BACK-06: Usar ViewSets + Routers de DRF para CRUD estándar.
BACK-07: Respuestas API siempre con formato estándar (ver sección 4).
BACK-08: NUNCA hardcodear valores. Usar constantes en choices.py.
BACK-09: Validaciones de SUNAT/RUC/DNI en core/utils/validators.py.
BACK-10: Logs con logging de Python, NUNCA print().
BACK-11: Cada app Django = un módulo del ERP.
BACK-12: Tests unitarios obligatorios para services.py de cada módulo.
BACK-13: NUNCA instalar paquetes sin verificar compatibilidad con el stack.
BACK-14: Signals solo para side-effects (logs, notificaciones), NUNCA lógica principal.
BACK-15: Paginación obligatoria en todo listado. Default: 20 items.
BACK-16: Filtros con django-filter en cada listado.
BACK-17: NUNCA retornar querysets sin filtrar (siempre aplicar permisos del usuario).
BACK-18: Tareas pesadas o llamadas a APIs externas siempre en Celery.
BACK-19: NUNCA hacer migraciones con RunPython destructivo sin autorización.
BACK-20: Todo endpoint documentado con docstring + @extend_schema de drf-spectacular.
BACK-21: Toda operación que modifique >1 tabla DEBE usar @transaction.atomic.
BACK-22: Usar select_related/prefetch_related en TODA query con relaciones.
BACK-23: NUNCA evaluar querysets completos en memoria. Usar iterator() para >1000 registros.
BACK-24: Queries de reportes/agregación usan .values(), .annotate(), .aggregate().
BACK-25: NUNCA hacer cálculos en Python que la DB puede hacer (totales, conteos, promedios).
BACK-26: Bulk operations: usar bulk_create/bulk_update para >10 registros.
BACK-27: Toda respuesta de error debe incluir código y mensaje útil para el frontend.
BACK-28: Rate limiting en endpoints públicos y endpoints de alta frecuencia (POS).
BACK-29: Caché con Redis para: catálogo de productos, configuración de la empresa, roles.
BACK-30: Versionado de API preparado (v1/) desde el inicio.
```

---

## 2. DOCUMENTACIÓN SWAGGER / OPENAPI (drf-spectacular)

### 2.1 Paquete y configuración

```python
# requirements/base.txt (agregar)
drf-spectacular==0.29.0
drf-spectacular-sidecar==2024.7.1  # Para servir assets localmente

# settings/base.py
INSTALLED_APPS = [
    # ...
    'drf_spectacular',
    'drf_spectacular_sidecar',
]

REST_FRAMEWORK = {
    # ... (auth, pagination, renderers, filters ya definidos)
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'JSoluciones ERP API',
    'DESCRIPTION': 'API REST para el ERP JSoluciones.',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,

    # Organizar endpoints por app/módulo
    'SCHEMA_PATH_PREFIX': r'/api/v1/',

    # JWT auth en Swagger UI
    'SWAGGER_UI_SETTINGS': {
        'deepLinking': True,
        'persistAuthorization': True,
        'displayOperationId': False,
    },

    # Servir assets localmente (sin CDN)
    'SWAGGER_UI_DIST': 'SIDECAR',
    'SWAGGER_UI_FAVICON_HREF': 'SIDECAR',
    'REDOC_DIST': 'SIDECAR',

    # Seguridad: definir JWT como esquema de auth
    'SECURITY': [{'jwtAuth': []}],
    'APPEND_COMPONENTS': {
        'securitySchemes': {
            'jwtAuth': {
                'type': 'http',
                'scheme': 'bearer',
                'bearerFormat': 'JWT',
            }
        }
    },

    # Tags para organizar endpoints
    'TAGS': [
        {'name': 'Auth', 'description': 'Autenticación y tokens JWT'},
        {'name': 'Empresa', 'description': 'Configuración de la empresa'},
        {'name': 'Usuarios', 'description': 'Gestión de usuarios, roles y permisos'},
        {'name': 'Clientes', 'description': 'CRUD de clientes'},
        {'name': 'Proveedores', 'description': 'CRUD de proveedores'},
        {'name': 'Inventario', 'description': 'Productos, almacenes, stock'},
        {'name': 'Ventas', 'description': 'Ventas, cotizaciones, órdenes, POS'},
        {'name': 'Facturación', 'description': 'Comprobantes electrónicos vía Nubefact'},
        {'name': 'Compras', 'description': 'Órdenes de compra y recepciones'},
        {'name': 'Finanzas', 'description': 'Cuentas por cobrar/pagar, asientos'},
        {'name': 'Distribución', 'description': 'Pedidos, rutas, seguimiento'},
        {'name': 'WhatsApp', 'description': 'Mensajería vía Meta Cloud API'},
        {'name': 'Reportes', 'description': 'Reportes y exportaciones'},
    ],

    # Solo admins Django pueden ver la documentación en producción
    'SERVE_PERMISSIONS': ['rest_framework.permissions.IsAuthenticated'],
}
```

### 2.2 URLs de documentación

```python
# config/urls.py
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
    SpectacularRedocView,
)

urlpatterns = [
    # ... otras URLs
    # Documentación API (solo en desarrollo o para admins)
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]
```

### 2.3 Decorador @extend_schema (OBLIGATORIO en cada endpoint custom)

```python
from drf_spectacular.utils import extend_schema, extend_schema_view, OpenApiParameter, OpenApiExample
from drf_spectacular.types import OpenApiTypes

# Para un ViewSet completo:
@extend_schema_view(
    list=extend_schema(
        summary='Listar ventas',
        description='Retorna ventas paginadas con filtros opcionales.',
        tags=['Ventas'],
    ),
    create=extend_schema(
        summary='Crear venta',
        description='Registra una nueva venta con detalle e impacta stock.',
        tags=['Ventas'],
        responses={201: VentaSerializer},
    ),
    retrieve=extend_schema(
        summary='Detalle de venta',
        tags=['Ventas'],
    ),
)
class VentaViewSet(viewsets.ModelViewSet):
    """CRUD de ventas."""
    pass

# Para actions custom:
class VentaViewSet(viewsets.ModelViewSet):
    @extend_schema(
        summary='Anular venta',
        description='Anula una venta y genera nota de crédito automáticamente.',
        tags=['Ventas'],
        request={'application/json': {'type': 'object', 'properties': {
            'motivo': {'type': 'string', 'example': 'Error en datos del cliente'}
        }}},
        responses={200: VentaSerializer},
    )
    @action(detail=True, methods=['post'])
    def anular(self, request, pk=None):
        pass
```

### 2.4 Reglas de documentación Swagger

```
SWAGGER-01: Todo ViewSet debe tener @extend_schema_view con summary y tags.
SWAGGER-02: Todo @action custom debe tener @extend_schema individual.
SWAGGER-03: Los tags corresponden a módulos: 'Ventas', 'Inventario', 'Facturación', etc.
SWAGGER-04: Incluir ejemplos de request/response cuando el formato no es obvio.
SWAGGER-05: Documentar parámetros de query (filtros, búsqueda, ordenamiento).
SWAGGER-06: Documentar códigos de error esperados (400, 403, 404, 502).
SWAGGER-07: En producción, la documentación solo es accesible para usuarios autenticados.
```

---

## 3. TRANSACCIONES Y ROLLBACK (Crítico para ERP)

### 3.1 Regla general

En un ERP, una operación de negocio generalmente toca MÚLTIPLES tablas. Si una parte falla, TODO debe revertirse. Ejemplo: una venta modifica Venta, DetalleVenta, MovimientoStock, Comprobante. Si falla en la creación del comprobante, la venta y el movimiento de stock deben revertirse.

### 3.2 Patrón obligatorio para operaciones multi-tabla

```python
# apps/ventas/services.py
from django.db import transaction
import logging

logger = logging.getLogger(__name__)

class VentaService:

    @staticmethod
    @transaction.atomic  # ★ OBLIGATORIO cuando se tocan >1 tabla ★
    def crear_venta(data, usuario):
        """
        Crea venta completa. Si algo falla, se revierte TODO.
        """
        # Savepoint automático por @transaction.atomic
        # Si lanza excepción → rollback de TODO

        # 1. Crear cabecera
        venta = Venta.objects.create(...)

        # 2. Crear detalles (bulk si son muchos)
        detalles = []
        for item in data['items']:
            detalles.append(DetalleVenta(venta=venta, **item))
        DetalleVenta.objects.bulk_create(detalles)

        # 3. Descontar stock (también usa atomic internamente)
        InventarioService.descontar_stock_venta(venta)

        # 4. Generar comprobante (puede fallar con Nubefact)
        try:
            FacturacionService.generar_comprobante(venta)
        except NubefactError:
            # Nubefact falló, pero la venta SÍ se guarda.
            # El comprobante queda pendiente_reenvio.
            # NO hacemos rollback de la venta por esto.
            logger.warning(f"Nubefact falló para venta {venta.id}, se reintentará")
            venta.comprobante_pendiente = True
            venta.save(update_fields=['comprobante_pendiente'])

        return venta
```

### 3.3 Savepoints para operaciones parciales

```python
from django.db import transaction

@transaction.atomic
def procesar_orden_compra(orden_id, items_recibidos):
    """
    Recepciona parcial/total de una OC.
    Cada item se procesa independientemente con savepoint.
    """
    orden = OrdenCompra.objects.select_for_update().get(id=orden_id)
    errores = []

    for item in items_recibidos:
        # Savepoint: si un item falla, no afecta a los demás
        sid = transaction.savepoint()
        try:
            InventarioService.registrar_entrada(
                producto_id=item['producto_id'],
                cantidad=item['cantidad'],
                almacen_id=orden.almacen_destino_id,
                referencia_tipo='compra',
                referencia_id=orden.id,
            )
            # Actualizar cantidad_recibida en detalle OC
            detalle = orden.detalles.get(producto_id=item['producto_id'])
            detalle.cantidad_recibida += item['cantidad']
            detalle.save(update_fields=['cantidad_recibida'])

            transaction.savepoint_commit(sid)
        except Exception as e:
            transaction.savepoint_rollback(sid)
            errores.append({'producto': item['producto_id'], 'error': str(e)})
            logger.error(f"Error recibiendo item {item['producto_id']}: {e}")

    # Actualizar estado de la OC
    orden.actualizar_estado_recepcion()
    return {'procesados': len(items_recibidos) - len(errores), 'errores': errores}
```

### 3.4 select_for_update (Bloqueo pesimista)

Usar cuando dos usuarios pueden modificar el mismo registro simultáneamente:

```python
# Crítico para: stock, correlativos de comprobantes, cuentas por cobrar

@transaction.atomic
def descontar_stock(producto_id, almacen_id, cantidad):
    """Descuenta stock con bloqueo para evitar race conditions."""
    # select_for_update BLOQUEA la fila hasta que termine la transacción
    producto_stock = (
        Stock.objects
        .select_for_update()
        .get(producto_id=producto_id, almacen_id=almacen_id)
    )

    if producto_stock.cantidad_actual < cantidad:
        raise StockInsuficienteError(
            f"Stock insuficiente para {producto_stock.producto.nombre}. "
            f"Disponible: {producto_stock.cantidad_actual}, Solicitado: {cantidad}"
        )

    producto_stock.cantidad_actual -= cantidad
    producto_stock.save(update_fields=['cantidad_actual', 'updated_at'])
    return producto_stock
```

### 3.5 on_commit (Acciones POST-transacción)

Para acciones que deben ocurrir SOLO si la transacción fue exitosa:

```python
from django.db import transaction

@transaction.atomic
def crear_venta(data, usuario):
    venta = Venta.objects.create(...)
    # ...

    # Enviar email/WhatsApp SOLO si la transacción completa fue exitosa
    transaction.on_commit(
        lambda: enviar_notificacion_venta.delay(venta.id)
    )

    # Si ocurre un error después de este on_commit pero antes del
    # final de la transacción, el callback NO se ejecuta.
    return venta
```

### 3.6 Tabla resumen: Cuándo usar cada patrón

| Situación | Patrón | Ejemplo |
|-----------|--------|---------|
| Crear venta + detalle + stock | `@transaction.atomic` | Venta completa |
| Modificar registro que otros leen | `select_for_update()` | Descontar stock, correlativos |
| Procesar N items independientes | Savepoints `savepoint()`/`rollback()` | Recepción parcial OC |
| Enviar email/WA después de éxito | `transaction.on_commit()` | Notificaciones |
| Operación de solo lectura | Sin transacción explícita | Listados, reportes |
| Bulk insert masivo | `bulk_create(batch_size=500)` | Importar catálogo productos |

---

## 4. OPTIMIZACIÓN DE QUERIES

### 4.1 Reglas de oro

```python
# ❌ PROHIBIDO: N+1 queries
ventas = Venta.objects.all()
for v in ventas:
    print(v.cliente.razon_social)     # 1 query extra por venta
    for d in v.detalles.all():        # 1 query extra por venta
        print(d.producto.nombre)      # 1 query extra por detalle

# ✅ CORRECTO: 3 queries total (sin importar cuántas ventas haya)
ventas = (
    Venta.objects
    .select_related('cliente', 'vendedor', 'comprobante')   # FK directas
    .prefetch_related('detalles', 'detalles__producto')     # Relaciones inversas
    .filter(is_active=True)
    .order_by('-created_at')
)
```

### 4.2 Queries de reportes (hacer cálculos en la DB)

```python
from django.db.models import Sum, Count, Avg, F, Q, DecimalField
from django.db.models.functions import TruncMonth, TruncDate

# ❌ MAL: Traer todo a Python y calcular
ventas = Venta.objects.all()
total = sum(v.total_venta for v in ventas)  # Lento, usa mucha RAM

# ✅ BIEN: La DB hace el cálculo
total = Venta.objects.filter(
    estado='completada',
    fecha__range=[fecha_inicio, fecha_fin]
).aggregate(
    total_ventas=Sum('total_venta'),
    cantidad_ventas=Count('id'),
    ticket_promedio=Avg('total_venta'),
)

# Ventas agrupadas por mes
ventas_mensuales = (
    Venta.objects
    .filter(estado='completada', fecha__year=2025)
    .annotate(mes=TruncMonth('fecha'))
    .values('mes')
    .annotate(
        total=Sum('total_venta'),
        cantidad=Count('id'),
    )
    .order_by('mes')
)

# Top 10 productos más vendidos
top_productos = (
    DetalleVenta.objects
    .filter(venta__estado='completada')
    .values('producto__nombre', 'producto__sku')
    .annotate(
        cantidad_total=Sum('cantidad'),
        monto_total=Sum('total'),
    )
    .order_by('-cantidad_total')[:10]
)

# Clientes con deuda vencida
clientes_morosos = (
    CuentaPorCobrar.objects
    .filter(estado='vencido', monto_pendiente__gt=0)
    .select_related('cliente')
    .values('cliente__razon_social', 'cliente__numero_documento')
    .annotate(deuda_total=Sum('monto_pendiente'))
    .order_by('-deuda_total')
)
```

### 4.3 Paginación obligatoria con cursor para datasets grandes

```python
# core/pagination.py
from rest_framework.pagination import PageNumberPagination, CursorPagination

class StandardPagination(PageNumberPagination):
    """Paginación estándar para listados normales."""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class LargeDatasetPagination(CursorPagination):
    """Para tablas con >100k registros (movimientos stock, logs)."""
    page_size = 50
    ordering = '-created_at'
    cursor_query_param = 'cursor'
```

### 4.4 Queryset eficiente en ViewSets

```python
class ProductoViewSet(viewsets.ModelViewSet):
    """
    CRUD de productos.
    Usa only() para listados y select_related para detalle.
    """
    serializer_class = ProductoSerializer
    filterset_class = ProductoFilter

    def get_queryset(self):
        qs = Producto.objects.filter(is_active=True)

        if self.action == 'list':
            # Listado: solo campos necesarios para la tabla
            return qs.select_related('categoria').only(
                'id', 'sku', 'nombre', 'precio_venta',
                'stock_actual', 'categoria__nombre', 'is_active'
            )
        else:
            # Detalle: todo + relaciones
            return qs.select_related(
                'categoria', 'created_by'
            ).prefetch_related(
                'movimientos__almacen',
                'lotes',
            )
```

### 4.5 Bulk operations (para >10 registros)

```python
# ❌ MAL: N inserts individuales
for item in items:
    DetalleVenta.objects.create(venta=venta, **item)

# ✅ BIEN: 1 solo INSERT (o pocos batches)
detalles = [DetalleVenta(venta=venta, **item) for item in items]
DetalleVenta.objects.bulk_create(detalles, batch_size=500)

# Para actualización masiva:
productos = Producto.objects.filter(categoria_id=5)
for p in productos:
    p.precio_venta *= Decimal('1.10')  # +10%
Producto.objects.bulk_update(productos, ['precio_venta'], batch_size=500)
```

### 4.6 Caché con Redis

```python
# settings/base.py
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://localhost:6379/1',
        'TIMEOUT': 300,  # 5 minutos por defecto
    }
}

# En services.py
from django.core.cache import cache

class ProductoService:
    @staticmethod
    def obtener_catalogo(almacen_id):
        """Catálogo cacheado por 5 min (se invalida al crear/editar producto)."""
        cache_key = f'catalogo_{almacen_id}'
        catalogo = cache.get(cache_key)
        if catalogo is None:
            catalogo = list(
                Producto.objects
                .filter(is_active=True)
                .select_related('categoria')
                .values('id', 'sku', 'nombre', 'precio_venta', 'categoria__nombre')
            )
            cache.set(cache_key, catalogo, timeout=300)
        return catalogo

    @staticmethod
    def invalidar_cache_catalogo():
        """Llamar al crear/editar/eliminar productos."""
        pattern = f'catalogo_*'
        # Invalidar todas las variantes
        cache.delete_pattern(pattern)
```

### 4.7 Cuándo cachear y cuándo NO

| Dato | Cachear | TTL | Razón |
|------|---------|-----|-------|
| Catálogo de productos | ✅ Sí | 5 min | Cambia poco, se consulta mucho |
| Config de la empresa | ✅ Sí | 30 min | Casi nunca cambia |
| Roles y permisos del usuario | ✅ Sí | 10 min | Cambia rara vez |
| Stock en tiempo real | ❌ No | — | Cambia constantemente |
| Venta en proceso | ❌ No | — | Datos transaccionales |
| Correlativos de comprobantes | ❌ No | — | Requiere consistencia exacta |
| Dashboard KPIs | ✅ Sí | 1-2 min | Reduce carga en reportes pesados |

---

## 5. DEFINICIÓN COMPLETA DE ROLES Y PERMISOS

### 5.1 Roles del sistema (8 roles base)

| Rol | Código | Descripción | Módulos que ve |
|-----|--------|-------------|---------------|
| **Administrador** | `admin` | Control total del sistema. Crea usuarios, configura módulos. | TODOS |
| **Gerente** | `gerente` | Ve dashboards ejecutivos, aprueba OC, acceso a reportes financieros. | Dashboard, Ventas, Inventario, Compras, Finanzas, Reportes |
| **Supervisor** | `supervisor` | Gestiona equipo de vendedores/almaceneros. Aprueba descuentos, ajustes. | Ventas, Inventario, Clientes, Reportes |
| **Vendedor** | `vendedor` | Registra ventas, cotizaciones, órdenes. Ve su propio rendimiento. | Ventas, Clientes, Inventario (solo consulta stock) |
| **Cajero** | `cajero` | Usa el POS. Registra ventas directas y cobros. | POS, Ventas (solo crear) |
| **Almacenero** | `almacenero` | Gestiona inventario, recepciona mercadería, registra movimientos. | Inventario, Compras (solo recepción) |
| **Contador** | `contador` | Gestiona finanzas, asientos contables, reportes tributarios. | Finanzas, Facturación (consulta), Reportes |
| **Repartidor** | `repartidor` | Ve pedidos asignados, actualiza estado de entrega, sube evidencia. | Distribución (solo sus pedidos) |

### 5.2 Matriz de permisos por módulo

```
FORMATO: módulo.acción
Valores: ✅ = permitido, ❌ = no tiene acceso, 👁 = solo lectura
```

| Permiso | admin | gerente | supervisor | vendedor | cajero | almacenero | contador | repartidor |
|---------|-------|---------|-----------|----------|--------|-----------|----------|-----------|
| **USUARIOS** | | | | | | | | |
| usuarios.ver | ✅ | 👁 | 👁 | ❌ | ❌ | ❌ | ❌ | ❌ |
| usuarios.crear | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| usuarios.editar | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| usuarios.eliminar | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **CLIENTES** | | | | | | | | |
| clientes.ver | ✅ | ✅ | ✅ | ✅ | 👁 | ❌ | 👁 | ❌ |
| clientes.crear | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| clientes.editar | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| clientes.eliminar | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **PROVEEDORES** | | | | | | | | |
| proveedores.ver | ✅ | ✅ | ✅ | ❌ | ❌ | 👁 | ✅ | ❌ |
| proveedores.crear | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| proveedores.editar | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **INVENTARIO** | | | | | | | | |
| inventario.ver | ✅ | ✅ | ✅ | 👁 | ❌ | ✅ | ❌ | ❌ |
| inventario.productos_crear | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| inventario.productos_editar | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| inventario.stock_ajustar | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| inventario.transferir | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| inventario.consultar_stock | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| **VENTAS** | | | | | | | | |
| ventas.ver | ✅ | ✅ | ✅ | ✅* | ✅* | ❌ | 👁 | ❌ |
| ventas.crear | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ventas.editar | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| ventas.anular | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| ventas.descuento_mayor_20 | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| ventas.pos | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| ventas.cotizaciones | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **FACTURACIÓN** | | | | | | | | |
| facturacion.ver | ✅ | ✅ | ✅ | 👁 | 👁 | ❌ | ✅ | ❌ |
| facturacion.emitir | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| facturacion.anular | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| facturacion.nota_credito | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **COMPRAS** | | | | | | | | |
| compras.ver | ✅ | ✅ | ✅ | ❌ | ❌ | 👁 | ✅ | ❌ |
| compras.crear_oc | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| compras.aprobar_oc | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| compras.recepcionar | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **FINANZAS** | | | | | | | | |
| finanzas.ver | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| finanzas.registrar_pago | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| finanzas.asientos | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| finanzas.reportes_tributarios | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **DISTRIBUCIÓN** | | | | | | | | |
| distribucion.ver | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅* |
| distribucion.asignar | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| distribucion.actualizar_estado | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| distribucion.evidencia | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **WHATSAPP** | | | | | | | | |
| whatsapp.ver | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| whatsapp.configurar | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| whatsapp.enviar | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **REPORTES** | | | | | | | | |
| reportes.ver | ✅ | ✅ | ✅ | 👁* | ❌ | ❌ | ✅ | ❌ |
| reportes.exportar | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **DASHBOARD** | | | | | | | | |
| dashboard.ejecutivo | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| dashboard.operativo | ✅ | ✅ | ✅ | ✅* | ✅* | ✅* | ❌ | ❌ |

```
* = Solo ve sus propios datos/registros (filtrado por usuario)
👁 = Solo lectura (no puede crear, editar ni eliminar)
```

### 5.3 Implementación de permisos en código

```python
# core/permissions.py
from rest_framework.permissions import BasePermission

class TienePermisoModular(BasePermission):
    """
    Verifica permiso por código.
    En el ViewSet: required_permission = 'ventas.crear'
    """
    def has_permission(self, request, view):
        required = getattr(view, 'required_permission', None)
        if not required:
            return True  # Sin restricción
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.perfil.tiene_permiso(required)


class SoloSusDatos(BasePermission):
    """
    Vendedores y cajeros solo ven sus propios registros.
    Supervisores y superiores ven todo.
    """
    def has_object_permission(self, request, view, obj):
        user = request.user
        rol = user.perfil.rol.codigo
        if rol in ['admin', 'gerente', 'supervisor']:
            return True
        # Vendedores/cajeros solo ven lo suyo
        if hasattr(obj, 'vendedor_id'):
            return obj.vendedor_id == user.perfil.id
        if hasattr(obj, 'created_by_id'):
            return obj.created_by_id == user.perfil.id
        return False

# apps/usuarios/models.py
class PerfilUsuario(TimestampMixin):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='perfil')
    rol = models.ForeignKey('Rol', on_delete=models.PROTECT)
    # ...

    def tiene_permiso(self, codigo_permiso):
        """Verifica si el rol del usuario tiene el permiso indicado."""
        # Admin siempre tiene todos los permisos
        if self.rol.codigo == 'admin':
            return True
        return self.rol.permisos.filter(codigo=codigo_permiso, is_active=True).exists()

class Rol(TimestampMixin):
    codigo = models.CharField(max_length=30, unique=True)
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True)
    permisos = models.ManyToManyField('Permiso', blank=True)
    is_active = models.BooleanField(default=True)

class Permiso(models.Model):
    codigo = models.CharField(max_length=50, unique=True)  # 'ventas.crear'
    nombre = models.CharField(max_length=100)  # 'Crear Ventas'
    modulo = models.CharField(max_length=30)  # 'ventas'
    descripcion = models.TextField(blank=True)
```

### 5.4 Seed de permisos base

```python
# core/management/commands/seed_permissions.py
"""
Ejecutar: python manage.py seed_permissions
Crea roles y permisos base definidos en la matriz.
Se ejecuta al configurar una nueva instancia.
"""
PERMISOS_BASE = [
    # (código, nombre, módulo)
    ('usuarios.ver', 'Ver usuarios', 'usuarios'),
    ('usuarios.crear', 'Crear usuarios', 'usuarios'),
    ('usuarios.editar', 'Editar usuarios', 'usuarios'),
    ('usuarios.eliminar', 'Eliminar usuarios', 'usuarios'),
    ('clientes.ver', 'Ver clientes', 'clientes'),
    ('clientes.crear', 'Crear clientes', 'clientes'),
    ('clientes.editar', 'Editar clientes', 'clientes'),
    ('clientes.eliminar', 'Eliminar clientes', 'clientes'),
    ('inventario.ver', 'Ver inventario', 'inventario'),
    ('inventario.productos_crear', 'Crear productos', 'inventario'),
    ('inventario.productos_editar', 'Editar productos', 'inventario'),
    ('inventario.stock_ajustar', 'Ajustar stock', 'inventario'),
    ('inventario.transferir', 'Transferir entre almacenes', 'inventario'),
    ('inventario.consultar_stock', 'Consultar stock', 'inventario'),
    ('ventas.ver', 'Ver ventas', 'ventas'),
    ('ventas.crear', 'Crear ventas', 'ventas'),
    ('ventas.editar', 'Editar ventas', 'ventas'),
    ('ventas.anular', 'Anular ventas', 'ventas'),
    ('ventas.descuento_mayor_20', 'Aplicar descuento >20%', 'ventas'),
    ('ventas.pos', 'Acceso al POS', 'ventas'),
    ('ventas.cotizaciones', 'Gestionar cotizaciones', 'ventas'),
    ('facturacion.ver', 'Ver comprobantes', 'facturacion'),
    ('facturacion.emitir', 'Emitir comprobantes', 'facturacion'),
    ('facturacion.anular', 'Anular comprobantes', 'facturacion'),
    ('facturacion.nota_credito', 'Emitir nota de crédito', 'facturacion'),
    ('compras.ver', 'Ver compras', 'compras'),
    ('compras.crear_oc', 'Crear orden de compra', 'compras'),
    ('compras.aprobar_oc', 'Aprobar orden de compra', 'compras'),
    ('compras.recepcionar', 'Recepcionar mercadería', 'compras'),
    ('finanzas.ver', 'Ver finanzas', 'finanzas'),
    ('finanzas.registrar_pago', 'Registrar pago/cobro', 'finanzas'),
    ('finanzas.asientos', 'Gestionar asientos contables', 'finanzas'),
    ('finanzas.reportes_tributarios', 'Ver reportes tributarios', 'finanzas'),
    ('distribucion.ver', 'Ver pedidos', 'distribucion'),
    ('distribucion.asignar', 'Asignar a transportista', 'distribucion'),
    ('distribucion.actualizar_estado', 'Actualizar estado pedido', 'distribucion'),
    ('distribucion.evidencia', 'Subir evidencia entrega', 'distribucion'),
    ('whatsapp.ver', 'Ver mensajes WhatsApp', 'whatsapp'),
    ('whatsapp.configurar', 'Configurar WhatsApp', 'whatsapp'),
    ('whatsapp.enviar', 'Enviar mensajes', 'whatsapp'),
    ('reportes.ver', 'Ver reportes', 'reportes'),
    ('reportes.exportar', 'Exportar reportes', 'reportes'),
    ('dashboard.ejecutivo', 'Dashboard ejecutivo', 'dashboard'),
    ('dashboard.operativo', 'Dashboard operativo', 'dashboard'),
]
```

---

## 6. MANEJO AVANZADO DE ERRORES

### 6.1 Handler global de excepciones

```python
# core/exception_handler.py
from rest_framework.views import exception_handler
from rest_framework.exceptions import ValidationError, AuthenticationFailed
import logging

logger = logging.getLogger('apps')

def custom_exception_handler(exc, context):
    """
    Handler global que asegura formato de respuesta consistente.
    Se configura en settings.py: REST_FRAMEWORK.EXCEPTION_HANDLER
    """
    response = exception_handler(exc, context)

    if response is not None:
        custom_data = {
            'success': False,
            'data': None,
            'message': '',
            'errors': [],
            'error_code': getattr(exc, 'default_code', 'error'),
        }

        if isinstance(exc, ValidationError):
            custom_data['message'] = 'Error de validación'
            custom_data['errors'] = response.data
        elif isinstance(exc, AuthenticationFailed):
            custom_data['message'] = 'Credenciales inválidas o sesión expirada'
            custom_data['error_code'] = 'auth_failed'
        else:
            custom_data['message'] = str(exc.detail) if hasattr(exc, 'detail') else str(exc)

        response.data = custom_data

    # Log de errores 500
    if response is None or response.status_code >= 500:
        view = context.get('view')
        logger.error(
            f"Error no manejado en {view.__class__.__name__ if view else 'unknown'}: {exc}",
            exc_info=True,
        )

    return response
```

```python
# settings/base.py (agregar)
REST_FRAMEWORK = {
    # ... existing config ...
    'EXCEPTION_HANDLER': 'core.exception_handler.custom_exception_handler',
}
```

### 6.2 Errores específicos del negocio ERP

```python
# core/exceptions.py (ampliado)
from rest_framework.exceptions import APIException

# --- Stock ---
class StockInsuficienteError(APIException):
    status_code = 400
    default_detail = 'Stock insuficiente para completar la operación.'
    default_code = 'stock_insuficiente'

# --- Facturación ---
class NubefactError(APIException):
    status_code = 502
    default_detail = 'Error de comunicación con Nubefact.'
    default_code = 'nubefact_error'

class ComprobanteRechazadoError(APIException):
    status_code = 400
    default_detail = 'Comprobante rechazado por SUNAT.'
    default_code = 'comprobante_rechazado'

class CorrelativoAgotadoError(APIException):
    status_code = 409
    default_detail = 'El correlativo de la serie ha llegado al límite.'
    default_code = 'correlativo_agotado'

# --- Ventas ---
class CotizacionVencidaError(APIException):
    status_code = 400
    default_detail = 'Cotización vencida. Debe duplicarla para continuar.'
    default_code = 'cotizacion_vencida'

class LimiteCreditoExcedidoError(APIException):
    status_code = 400
    default_detail = 'El cliente excedió su límite de crédito.'
    default_code = 'limite_credito_excedido'

class VentaNoAnulableError(APIException):
    status_code = 400
    default_detail = 'La venta no puede anularse (ya tiene comprobante aceptado por SUNAT).'
    default_code = 'venta_no_anulable'

# --- Compras ---
class OrdenNoAprobadaError(APIException):
    status_code = 400
    default_detail = 'La orden de compra debe estar aprobada para esta acción.'
    default_code = 'orden_no_aprobada'

class ConciliacionPendienteError(APIException):
    status_code = 400
    default_detail = 'No se puede procesar el pago sin conciliación con almacén.'
    default_code = 'conciliacion_pendiente'

# --- Permisos ---
class PermisoInsuficienteError(APIException):
    status_code = 403
    default_detail = 'No tiene permisos para esta operación.'
    default_code = 'permiso_insuficiente'

# --- Empresa ---
class EmpresaInactivaError(APIException):
    status_code = 403
    default_detail = 'La empresa está inactiva o suspendida.'
    default_code = 'empresa_inactiva'

class LimiteUsuariosError(APIException):
    status_code = 403
    default_detail = 'Se alcanzó el límite de usuarios del plan.'
    default_code = 'limite_usuarios'
```

---

## 7. LOGGING ESTRUCTURADO

```python
# settings/base.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '[{asctime}] {levelname} [{name}:{funcName}:{lineno}] {message}',
            'style': '{',
        },
        'json': {
            'class': 'pythonjsonlogger.jsonlogger.JsonFormatter',
            'format': '%(asctime)s %(levelname)s %(name)s %(message)s',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file_app': {
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/app.log',
            'maxBytes': 10 * 1024 * 1024,  # 10MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
        'file_errors': {
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/errors.log',
            'maxBytes': 10 * 1024 * 1024,
            'backupCount': 10,
            'formatter': 'verbose',
            'level': 'ERROR',
        },
    },
    'loggers': {
        'apps': {
            'handlers': ['console', 'file_app', 'file_errors'],
            'level': 'INFO',
        },
        'core': {
            'handlers': ['console', 'file_app', 'file_errors'],
            'level': 'INFO',
        },
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'WARNING',  # Cambiar a DEBUG para ver queries SQL
        },
    },
}
```

---

## 8. DEBUG Y PROFILING (Solo desarrollo)

```python
# requirements/dev.txt (agregar)
django-debug-toolbar==4.4
django-silk==5.1.0

# settings/development.py
INSTALLED_APPS += ['debug_toolbar', 'silk']
MIDDLEWARE.insert(0, 'debug_toolbar.middleware.DebugToolbarMiddleware')
MIDDLEWARE.append('silk.middleware.SilkyMiddleware')

INTERNAL_IPS = ['127.0.0.1']

# Silk: Registra queries y tiempos por request
SILKY_PYTHON_PROFILER = True
SILKY_MAX_RECORDED_REQUESTS = 500
```

---

## 9. THROTTLING / RATE LIMITING

```python
# settings/base.py
REST_FRAMEWORK = {
    # ... existing config ...
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '20/minute',       # Endpoints públicos (login, tracking)
        'user': '200/minute',      # Usuarios autenticados
        'pos': '600/minute',       # POS necesita alta frecuencia
        'nubefact': '30/minute',   # Límite de Nubefact
    },
}

# En views que necesitan rate custom:
from rest_framework.throttling import UserRateThrottle

class POSThrottle(UserRateThrottle):
    rate = '600/minute'

class VentaPOSViewSet(viewsets.ViewSet):
    throttle_classes = [POSThrottle]
```

---

## 10. CHECKLIST ANTES DE CADA COMMIT (Ampliado)

- [ ] ¿La lógica de negocio está en services.py?
- [ ] ¿Los views solo orquestan?
- [ ] ¿Se usa @transaction.atomic en operaciones multi-tabla?
- [ ] ¿Se usa select_for_update donde hay concurrencia (stock, correlativos)?
- [ ] ¿Se usa select_related/prefetch_related en queries con relaciones?
- [ ] ¿Los cálculos de agregación están en la DB (aggregate/annotate)?
- [ ] ¿Hay @extend_schema en endpoints custom?
- [ ] ¿Hay permisos en todos los endpoints?
- [ ] ¿Se pasan los IDs necesarios a las tareas Celery?
- [ ] ¿Se usa logging en vez de print?
- [ ] ¿Los campos monetarios son DecimalField?
- [ ] ¿Hay paginación en los listados?
- [ ] ¿Se crearon tests para el service?
- [ ] ¿Los errores usan excepciones custom con error_code?
- [ ] ¿Se invalida caché cuando se modifican datos cacheados?
