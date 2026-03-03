# JSOLUCIONES ERP — VISION GENERAL

> ERP de gestion empresarial para el mercado peruano (PYMES).
> Single-tenant. Una empresa por instalacion. Sin multi-tenancy. Sin eCommerce.

---

## Que es JSoluciones

JSoluciones es un template de ERP completo y funcional construido para servir como base reutilizable. Cada instalacion es para una sola empresa. El sistema cubre el ciclo completo del negocio: ventas, inventario, facturacion electronica SUNAT, compras, finanzas, distribucion y comunicacion con clientes via WhatsApp.

### Para que sirve este repo

Este repo (`Jsoluciones-docs`) es la capsula de contexto del proyecto. Cuando el agente o un desarrollador tiene dudas sobre como funciona algo, como se llama algo, o como se hace algo, entra aqui y encuentra la respuesta por nombre de archivo.

---

## Stack Tecnologico

### Backend

| Capa | Tecnologia | Version |
|------|-----------|---------|
| Framework | Django | 4.2 |
| API REST | Django REST Framework | 3.14+ |
| Auth | simplejwt | 5.3+ (access 60min, refresh 7d, rotacion + blacklist) |
| DB | PostgreSQL | 16 (UUIDs, JSONB, indices compuestos) |
| Schema/Docs | drf-spectacular | 0.29+ (genera OpenAPI para Orval) |
| Tareas async | Celery + Redis | 5.3+ |
| WebSockets | Django Channels + Daphne | 4.0+ |
| Storage | Cloudflare R2 (boto3) | 3 buckets privados, presigned URLs |
| Cache | Redis (LocMem en dev) | - |
| Facturacion SUNAT | Nubefact OSE via HTTP | - |

### Frontend

| Tecnologia | Version | Proposito |
|-----------|---------|-----------|
| React | 19 | Framework UI |
| TypeScript | 5.8 | Tipado estatico |
| Vite | 7 | Build tool + dev server con proxy |
| Tailwind CSS | 4 | Estilos (via @tailwindcss/vite) |
| Preline | 3.2 | Interacciones JS (dropdowns, modales, tabs) |
| TanStack React Query | 5 | Data fetching, cache, mutations |
| Orval | 8 | Genera hooks y tipos desde OpenAPI |
| react-hot-toast | - | Notificaciones toast |
| react-apexcharts | - | Graficos en dashboard |
| react-hook-form | - | Formularios complejos |
| pnpm | - | Package manager |

### Infraestructura

- Redis: 3 usos (broker Celery DB0, channel layer WS DB1, cache general DB2)
- Celery: 4 colas (critical, default, notifications, reports)
- Docker Compose para desarrollo local
- Uvicorn ASGI en produccion (no Gunicorn — requiere ASGI para WebSockets)

---

## Repositorios

| Repo | Descripcion | Path local |
|------|-------------|------------|
| `Jsoluciones-be` | Django Backend (API REST + WebSockets + Celery) | `../Jsoluciones-be/` |
| `Jsoluciones-fe` | React Frontend (Vite + TanStack Query + Orval) | `../Jsoluciones-fe/` |
| `Jsoluciones-docs` | Documentacion (este repo) | `../Jsoluciones-docs/` |

> Amatista-be/ y Amatista-fe/ son un proyecto DISTINTO derivado de este template. NO modificar.

---

## Arquitectura del Backend

```
config/
  settings/base.py, development.py, production.py, testing.py
  urls.py, celery.py, asgi.py

core/
  mixins.py          -> TimestampMixin, SoftDeleteMixin, AuditMixin
  choices.py         -> TODAS las constantes (choices, roles, estados)
  pagination.py      -> StandardPagination (20/page), LargeDatasetPagination (cursor)
  permissions.py     -> TienePermiso, EsAdmin, EsSupervisorOAdmin, SoloSusDatos
  exceptions.py      -> Excepciones custom con error_code
  exception_handler.py -> Handler global formato estandar
  consumers.py       -> WebSocket consumers
  routing.py         -> Rutas WebSocket
  utils/
    validators.py    -> validar_ruc, validar_dni
    r2_storage.py    -> R2StorageService
    nubefact.py      -> Cliente HTTP Nubefact
    ple.py           -> Generacion archivos PLE SUNAT
  tasks/
    r2_tasks.py      -> Upload async, cache presigned URLs

apps/
  empresa/       -> Configuracion empresa (singleton, 1 fila)
  usuarios/      -> Usuario, Rol, Permiso, PerfilUsuario, LogActividad
  clientes/      -> Cliente (RUC/DNI, segmento, limite credito)
  proveedores/   -> Proveedor (RUC, condiciones pago)
  inventario/    -> Producto, Categoria, Almacen, Stock, MovimientoStock, Lote, Serie
  ventas/        -> Cotizacion, OrdenVenta, Venta, DetalleVenta, Caja, FormaPago
  facturacion/   -> Comprobante, NotaCreditoDebito, SerieComprobante, LogEnvio
  media/         -> MediaArchivo (polimorfico, R2 buckets)
  compras/       -> OrdenCompra, FacturaProveedor, Recepcion
  finanzas/      -> CuentaCobrar/Pagar, Cobro, Pago, AsientoContable
  distribucion/  -> Transportista, Pedido, SeguimientoPedido, EvidenciaEntrega
  whatsapp/      -> ConfiguracionWA, Plantilla, Mensaje, LogWA
  reportes/      -> Sin modelos propios (queries cross-app)
```

### Patron obligatorio por app

```
apps/{modulo}/
  models.py        -> Modelos con mixins, db_table, indices, constraints
  serializers.py   -> Solo validacion y transformacion (NUNCA logica de negocio)
  services.py      -> TODA la logica de negocio (@transaction.atomic)
  views.py         -> Solo orquesta: request -> service -> response
  urls.py          -> Router DRF + paths custom
  admin.py         -> Registro en Django admin
  tasks.py         -> Tareas Celery (si aplica)
```

---

## Arquitectura del Frontend

```
src/
  api/
    fetcher.ts              -> Custom fetch con JWT (inyecta token, maneja refresh 401)
    generated/              -> AUTO-GENERADO por Orval (NO editar)
    models/                 -> AUTO-GENERADO por Orval (NO editar)

  app/
    (admin)/                -> Paginas autenticadas
      layout.tsx            -> Layout con sidebar + topbar + footer
      (dashboards)/index/   -> Dashboard principal
      (app)/
        (ventas)/           -> POS, lista ventas, detalle venta, cotizaciones
        (inventario)/       -> Productos, stock, dashboard inventario
        (hr)/               -> Cotizaciones, cobros
        (invoice)/          -> Facturacion
        (users)/            -> Clientes, proveedores, usuarios
        (whatsapp)/         -> Configuracion, plantillas, mensajes, campanas
        (finanzas)/         -> CxC, CxP, conciliacion, asientos, reportes
        (distribucion)/     -> Pedidos, transportistas, seguimiento
        (compras)/          -> Ordenes de compra, proveedores, recepciones
        (configuracion)/    -> Roles, permisos, empresa, audit log
        perfil/             -> Perfil de usuario
    (auth)/                 -> Login, Logout

  components/
    common/                 -> Badge, ConfirmModal, DataTable, EmptyState,
                               ErrorBoundary, ErrorMessage, ProtectedRoute
    layouts/                -> Sidebar, topbar, footer, customizer

  config/
    constants.ts            -> Constantes del negocio (estados, tipos, ESTADO_COLOR_MAP)
    env.ts                  -> Variables de entorno

  context/
    AuthContext.tsx          -> Estado de autenticacion + RBAC

  helpers/
    constants.ts            -> Constantes de la app
    debounce.ts             -> Utilidad debounce
    formatters.ts           -> formatMoney, formatDate, formatDateTime, formatDocNumber

  types/
    erp/index.ts            -> Tipos manuales complementarios (solo si Orval no cubre)
```

---

## Roles del Sistema (8 roles base)

| Rol | Codigo | Acceso |
|-----|--------|--------|
| Administrador | admin | TODOS los modulos |
| Gerente | gerente | Dashboard, Ventas, Inventario, Compras, Finanzas, Reportes |
| Supervisor | supervisor | Ventas, Inventario, Clientes, Compras, Reportes |
| Vendedor | vendedor | Ventas, Clientes, Inventario (solo consulta) |
| Cajero | cajero | POS, Ventas (solo crear) |
| Almacenero | almacenero | Inventario, Compras (solo recepcion) |
| Contador | contador | Finanzas, Facturacion (consulta), Reportes |
| Repartidor | repartidor | Distribucion (solo sus pedidos) |

---

## Formato de Respuesta API

```json
// Exito — listado paginado
{
  "count": 150,
  "next": "/api/v1/ventas/?page=2",
  "previous": null,
  "results": [...]
}

// Exito — detalle / accion
{
  "id": "uuid",
  "numero": "V001-0001",
  ...
}

// Error (400/403/404/500)
{
  "success": false,
  "data": null,
  "message": "Stock insuficiente para Laptop HP.",
  "errors": [],
  "error_code": "stock_insuficiente"
}
```

---

## Colores del Design System (JSoluciones)

| Token CSS | Color | Hex | Uso |
|-----------|-------|-----|-----|
| `--color-primary` | Terracota | `#D65A42` | CTAs, links activos, badges primarios |
| `--color-brand-dark` | Negro Carbon | `#1A1A1A` | Titulos H1/H2 |
| `--color-brand-body` | Gris Pizarra | `#555555` | Texto cuerpo, labels |
| `--color-brand-surface` | Blanco Crema | `#F9F7F2` | Fondo general de pagina |
| `--color-brand-border` | Gris Nube | `#E8E8E8` | Bordes de inputs, cards |
| `--color-brand-accent` | Gris Topo | `#9E9188` | Iconos secundarios |

Tipografia: Playfair Display (titulos) + Inter (cuerpo y UI).
