# JSOLUCIONES ERP — PROCESOS DEL BACKEND (Paso a paso)

> Este archivo define QUÉ debe construirse en el backend, EN ORDEN.
> Cada proceso describe: qué hacer, qué archivos crear, qué endpoints exponer.
> El agente de backend debe seguir este orden estrictamente.
>
> ⚠️ ARQUITECTURA: Instancia por cliente (NO multi-tenant).
> Una DB PostgreSQL estándar por empresa. Sin django-tenants.

---

## PROCESO 1: Setup del proyecto Django + PostgreSQL

### Qué hacer:
1. Crear proyecto Django con estructura de settings separados (base, dev, prod)
2. Configurar PostgreSQL como base de datos (estándar, sin django-tenants)
3. Crear app `empresa` con modelo Empresa (configuración de la empresa)
4. Crear modelo Usuario custom (AbstractUser con email como login)
5. Crear migraciones iniciales y migrar
6. Configurar DRF, JWT, Swagger, CORS
7. Verificar que se puede acceder al admin y a Swagger

### Archivos a crear:
```
config/settings/base.py       → Settings compartidos (DB, apps, middleware, DRF, JWT, Swagger)
config/settings/development.py → DEBUG=True, DB local
config/settings/production.py  → Seguridad, DB producción
config/urls.py                 → URLs raíz con API versioning + Swagger
config/asgi.py
config/wsgi.py
apps/__init__.py
apps/empresa/models.py         → Empresa (config de la empresa: RUC, razón social, Nubefact, WA)
apps/empresa/serializers.py
apps/empresa/views.py
apps/empresa/urls.py
apps/empresa/admin.py
apps/usuarios/models.py        → Usuario (AbstractUser custom, email login)
apps/usuarios/admin.py
core/__init__.py
core/mixins.py                 → TimestampMixin, SoftDeleteMixin, AuditMixin
core/choices.py                → TODAS las constantes (copiar de 06_CONSTANTES)
core/pagination.py             → StandardPagination, LargeDatasetPagination
core/exceptions.py             → Excepciones custom
core/exception_handler.py      → custom_exception_handler
core/permissions.py            → TienePermisoModular, EsAdmin, etc.
core/utils/__init__.py
core/utils/validators.py       → validar_ruc, validar_dni
requirements/base.txt
requirements/dev.txt
requirements/prod.txt
docker-compose.yml             → PostgreSQL + Redis
Dockerfile
manage.py
.env.example
```

### Endpoints resultantes:
```
GET    /api/v1/empresa/           → Datos de la empresa (config)
PATCH  /api/v1/empresa/           → Editar config empresa (solo admin)
GET    /api/docs/                 → Swagger UI
GET    /api/redoc/                → ReDoc
```

### Verificación:
- [ ] `python manage.py migrate` ejecuta sin error
- [ ] Se puede acceder al admin de Django
- [ ] Swagger UI disponible en `/api/docs/`
- [ ] La tabla `empresa` existe en la DB

---

## PROCESO 2: Autenticación y sistema de usuarios

### Qué hacer:
1. Completar app `usuarios` con modelos: PerfilUsuario, Rol, Permiso
2. Configurar JWT con simplejwt (access + refresh)
3. Implementar login: email + password → JWT + info del usuario
4. Crear modelos Rol y Permiso con relación M2M
5. Seed de roles y permisos base (management command)
6. Management command `setup_empresa` (crea empresa + admin inicial)

### Archivos a crear:
```
apps/usuarios/models.py        → Usuario, PerfilUsuario, Rol, Permiso
apps/usuarios/serializers.py   → LoginSerializer, UsuarioSerializer, RolSerializer
apps/usuarios/views.py         → LoginView, RefreshView, PerfilViewSet, RolViewSet
apps/usuarios/services.py      → AuthService, UsuarioService
apps/usuarios/urls.py
apps/usuarios/admin.py
core/management/commands/seed_permissions.py  → Crear roles y permisos iniciales
core/management/commands/setup_empresa.py     → Setup inicial: empresa + usuario admin
```

### Endpoints resultantes:
```
POST   /api/v1/auth/login/              → Login (email + password → tokens)
POST   /api/v1/auth/refresh/            → Refresh token
POST   /api/v1/auth/logout/             → Blacklist del refresh token
GET    /api/v1/auth/me/                 → Perfil del usuario actual + permisos
GET    /api/v1/usuarios/                → Listar usuarios
POST   /api/v1/usuarios/               → Crear usuario
GET    /api/v1/usuarios/{id}/           → Detalle usuario
PATCH  /api/v1/usuarios/{id}/           → Editar usuario
DELETE /api/v1/usuarios/{id}/           → Soft delete usuario
GET    /api/v1/roles/                   → Listar roles
POST   /api/v1/roles/                   → Crear rol custom
GET    /api/v1/roles/{id}/permisos/     → Permisos de un rol
```

### Verificación:
- [ ] Login retorna access_token y refresh_token
- [ ] /auth/me/ retorna datos del usuario + permisos + datos de empresa
- [ ] Un vendedor NO puede acceder a endpoints de admin
- [ ] Un admin SÍ puede acceder a todo
- [ ] Refresh token funciona y rota correctamente
- [ ] `python manage.py setup_empresa` crea empresa + admin sin error

---

## PROCESO 3: Inventario y productos

### Qué hacer:
1. Crear app `inventario` con modelos: Producto, Categoria, Almacen, Stock, MovimientoStock, Lote
2. CRUD completo de productos con filtros (categoría, estado, precio)
3. CRUD de categorías (jerárquicas: categoría padre)
4. CRUD de almacenes
5. Service de stock: calcular stock actual por producto/almacen
6. Service de movimientos: entrada, salida, transferencia, ajuste
7. Alertas de stock mínimo (tarea Celery)

### Archivos a crear:
```
apps/inventario/models.py        → Producto, Categoria, Almacen, Stock, MovimientoStock, Lote
apps/inventario/serializers.py   → ProductoSerializer, ProductoCreateSerializer, etc.
apps/inventario/views.py         → ProductoViewSet, CategoriaViewSet, AlmacenViewSet, MovimientoViewSet
apps/inventario/services.py      → InventarioService (stock, movimientos, alertas)
apps/inventario/filters.py       → ProductoFilter, MovimientoFilter
apps/inventario/urls.py
apps/inventario/tasks.py         → verificar_stock_minimo (Celery)
apps/inventario/tests/
```

### Endpoints resultantes:
```
# Productos
GET    /api/v1/inventario/productos/              → Listar (paginado, filtros)
POST   /api/v1/inventario/productos/              → Crear producto
GET    /api/v1/inventario/productos/{id}/          → Detalle
PATCH  /api/v1/inventario/productos/{id}/          → Editar
DELETE /api/v1/inventario/productos/{id}/          → Soft delete
GET    /api/v1/inventario/productos/{id}/stock/    → Stock por almacén
GET    /api/v1/inventario/productos/buscar/        → Búsqueda rápida (POS)

# Categorías
GET    /api/v1/inventario/categorias/
POST   /api/v1/inventario/categorias/
GET    /api/v1/inventario/categorias/{id}/
PATCH  /api/v1/inventario/categorias/{id}/

# Almacenes
GET    /api/v1/inventario/almacenes/
POST   /api/v1/inventario/almacenes/
GET    /api/v1/inventario/almacenes/{id}/
GET    /api/v1/inventario/almacenes/{id}/stock/    → Todo el stock del almacén

# Movimientos
GET    /api/v1/inventario/movimientos/             → Historial (cursor pagination)
POST   /api/v1/inventario/movimientos/ajuste/      → Ajuste manual de stock
POST   /api/v1/inventario/movimientos/transferencia/ → Transferencia entre almacenes

# Alertas
GET    /api/v1/inventario/alertas-stock/           → Productos bajo stock mínimo
```

---

## PROCESO 4: Clientes y proveedores

### Endpoints:
```
# Clientes
GET    /api/v1/clientes/                  → Listar
POST   /api/v1/clientes/                  → Crear (valida RUC/DNI)
GET    /api/v1/clientes/{id}/             → Detalle
PATCH  /api/v1/clientes/{id}/             → Editar
GET    /api/v1/clientes/{id}/historial/   → Ventas del cliente
GET    /api/v1/clientes/buscar/           → Búsqueda rápida

# Proveedores
GET    /api/v1/proveedores/               → Listar
POST   /api/v1/proveedores/               → Crear (valida RUC)
GET    /api/v1/proveedores/{id}/          → Detalle
PATCH  /api/v1/proveedores/{id}/          → Editar
GET    /api/v1/proveedores/{id}/compras/  → Historial de compras
```

---

## PROCESO 5: Ventas (core del negocio)

### Qué hacer:
1. Modelos: Venta, DetalleVenta, Cotizacion, DetalleCotizacion, OrdenVenta, DetalleOrdenVenta
2. Service de venta: validar stock → crear venta + detalle → descontar stock → generar comprobante
3. Service de cotización: crear, duplicar, convertir a orden, vencer automáticamente
4. Service de orden de venta: crear, confirmar, completar
5. Flujo: Cotización → OrdenVenta → Venta (o venta directa)
6. POS: endpoint optimizado para venta rápida

### Endpoints:
```
# Ventas
GET    /api/v1/ventas/                    → Listar
POST   /api/v1/ventas/                    → Crear venta completa
GET    /api/v1/ventas/{id}/               → Detalle con items
POST   /api/v1/ventas/{id}/anular/        → Anular (genera nota crédito)
POST   /api/v1/ventas/pos/                → Venta rápida POS

# Cotizaciones
GET    /api/v1/ventas/cotizaciones/
POST   /api/v1/ventas/cotizaciones/
GET    /api/v1/ventas/cotizaciones/{id}/
POST   /api/v1/ventas/cotizaciones/{id}/duplicar/
POST   /api/v1/ventas/cotizaciones/{id}/convertir-a-orden/

# Órdenes de venta
GET    /api/v1/ventas/ordenes/
POST   /api/v1/ventas/ordenes/
POST   /api/v1/ventas/ordenes/{id}/confirmar/
POST   /api/v1/ventas/ordenes/{id}/generar-venta/
```

---

## PROCESO 6: Facturación electrónica (Nubefact)

### Qué hacer:
1. Modelos: SerieComprobante, Comprobante, DetalleComprobante, NotaCreditoDebito, LogEnvioNubefact
2. Cliente HTTP para Nubefact (core/utils/nubefact.py)
3. Service: generar JSON → enviar a Nubefact → guardar respuesta
4. Tarea Celery para reintentos de comprobantes fallidos
5. Endpoint para consultar estado de un comprobante
6. Endpoint para generar nota de crédito

### Endpoints:
```
GET    /api/v1/facturacion/comprobantes/               → Listar
GET    /api/v1/facturacion/comprobantes/{id}/           → Detalle + PDF/XML
POST   /api/v1/facturacion/comprobantes/{id}/reenviar/  → Reenviar a Nubefact
POST   /api/v1/facturacion/notas-credito/               → Crear nota crédito
GET    /api/v1/facturacion/series/                      → Series configuradas
POST   /api/v1/facturacion/series/                      → Crear nueva serie
GET    /api/v1/facturacion/logs/                        → Logs de envío
```

---

## PROCESO 7-10: Compras, Finanzas, Distribución, WhatsApp, Reportes

(Seguir la misma estructura de: modelos → services → views → endpoints → tests)

Se detallarán cuando se alcancen esas prioridades.

---

## RESUMEN DE PAQUETES A INSTALAR

```
# requirements/base.txt
Django>=4.2,<5.0
djangorestframework>=3.14
djangorestframework-simplejwt>=5.3
django-filter>=23.5
django-cors-headers>=4.3
drf-spectacular>=0.29
drf-spectacular-sidecar>=2024.7
celery>=5.3
redis>=5.0
django-redis>=5.4
psycopg2-binary>=2.9
python-decouple>=3.8
gunicorn>=21.2
whitenoise>=6.6
Pillow>=10.2
python-json-logger>=2.0

# requirements/dev.txt
-r base.txt
django-debug-toolbar>=4.4
django-silk>=5.1
pytest-django>=4.8
factory-boy>=3.3
faker>=22.0

# requirements/prod.txt
-r base.txt
django-storages>=1.14
boto3>=1.34
sentry-sdk>=1.40
```

**Nota: NO se incluye django-tenants. No se necesita.**
