# JSOLUCIONES ERP — ESTADO ACTUAL Y PLAN DE VISTAS

> Documento de referencia rápida. Estado al día de la fecha.
> Generado a partir del análisis del plan de ejecución y el progreso real.

---

## 📊 ESTADO ACTUAL DEL 50%

| Capa | Módulo | Backend | Frontend | Estado |
|------|--------|---------|----------|--------|
| 0 | Infraestructura | ✅ Django, PostgreSQL, Docker | ✅ React, Tailwind, Vite | **100%** |
| 1 | Auth + Login | ✅ JWT, /auth/me/, permisos | ✅ Login, ProtectedRoute, AuthContext | **100%** |
| **2** | **Inventario** | ⬜ Modelos, serializers, endpoints | ⬜ Vistas de productos | **0%** |
| **3** | **Clientes + Ventas** ⭐ | ⬜ Modelos, POS, cotizaciones | ⬜ POS, cotizaciones, dashboard | **0%** |
| **4** | **Facturación** | ⬜ Nubefact, comprobantes | ⬜ Lista comprobantes | **0%** |
| **5** | Media + Proveedores | ⬜ R2, CRUD básico | ⬜ Fotos en productos | **0%** |

**Progreso real:** ~**20% del 50%** (solo CAPA 0 y 1 listas)

---

## 🎯 MAPA DE VISTAS DEL TEMPLATE TAILWICK

Qué vistas del template usar para cada módulo del ERP.

### CAPA 2: Inventario (Productos)

| Vista Tailwick | Ruta Actual | Para qué usarla | Endpoint API |
|----------------|-------------|-----------------|--------------|
| **Product Grid** | `/product-grid` | Catálogo visual tipo e-commerce (grid de productos con fotos) | `GET /inventario/productos/` |
| **Product List** | `/product-list` | Gestión admin con filtros, búsqueda y acciones masivas | `GET /inventario/productos/` |
| **Product Create** | `/product-create` | Formulario crear nuevo producto | `POST /inventario/productos/` |
| **Product Overview** | `/product-overview` | Ficha detalle del producto (stock por almacén, precios) | `GET /inventario/productos/{id}/` |

**Endpoints necesarios backend:**
```
GET/POST     /api/v1/inventario/productos/
GET/PATCH    /api/v1/inventario/productos/{id}/
GET          /api/v1/inventario/productos/{id}/stock/
GET          /api/v1/inventario/productos/buscar/?q=
GET/POST     /api/v1/inventario/categorias/
GET/POST     /api/v1/inventario/almacenes/
GET          /api/v1/inventario/movimientos/
POST         /api/v1/inventario/movimientos/ajuste/
POST         /api/v1/inventario/movimientos/transferencia/
```

---

### CAPA 3: Clientes + Ventas ⭐ PRIORIDAD DEL JEFE

#### Clientes

| Vista Tailwick | Ruta Actual | Para qué usarla | Endpoint API |
|----------------|-------------|-----------------|--------------|
| **Users List** | `/users-list` | Listado de clientes con búsqueda RUC/DNI/nombre | `GET /clientes/` |
| **User Grid** | `/users-grid` | Vista grid de clientes (alternativa) | `GET /clientes/` |

**Endpoints necesarios backend:**
```
GET/POST     /api/v1/clientes/
GET/PATCH    /api/v1/clientes/{id}/
GET          /api/v1/clientes/buscar/?q=
GET          /api/v1/clientes/{id}/historial-ventas/
```

#### Ventas (POS + Cotizaciones)

| Vista Tailwick | Ruta Actual | Para qué usarla | Endpoint API |
|----------------|-------------|-----------------|--------------|
| **Cart** | `/cart` | **BASE DEL POS** - Carrito de venta, buscador de productos | `POST /ventas/pos/` |
| **Checkout** | `/checkout` | **BASE DEL POS** - Finalización de venta, método de pago | `POST /ventas/pos/` |
| **Orders** | `/orders` | Listado de ventas realizadas (para histórico) | `GET /ventas/` |
| **Order Overview** | `/order-overview` | Detalle de una venta específica | `GET /ventas/{id}/` |
| **Sales Estimates** | `/sales-estimates` | **Cotizaciones** - Crear y gestionar cotizaciones | `GET/POST /ventas/cotizaciones/` |

**Endpoints necesarios backend:**
```
# Ventas
GET/POST     /api/v1/ventas/
GET          /api/v1/ventas/{id}/
POST         /api/v1/ventas/{id}/anular/
GET          /api/v1/ventas/resumen-dia/
POST         /api/v1/ventas/pos/              ← ★ POS optimizado

# Cotizaciones
GET/POST     /api/v1/ventas/cotizaciones/
GET/PATCH    /api/v1/ventas/cotizaciones/{id}/
POST         /api/v1/ventas/cotizaciones/{id}/duplicar/
POST         /api/v1/ventas/cotizaciones/{id}/convertir-orden/

# Órdenes de Venta
GET/POST     /api/v1/ventas/ordenes/
GET/PATCH    /api/v1/ventas/ordenes/{id}/
POST         /api/v1/ventas/ordenes/{id}/convertir-venta/
```

**Dashboard KPIs:**
- Ventas del día (monto + cantidad)
- Productos más vendidos (top 5)
- Stock bajo (alertas)

---

### CAPA 4: Facturación Nubefact

| Vista Tailwick | Ruta Actual | Para qué usarla | Endpoint API |
|----------------|-------------|-----------------|--------------|
| **Invoice Overview** | `/overview` | Dashboard comprobantes del día, resumen | `GET /facturacion/comprobantes/` |
| **Invoice List** | `/list` | Listado de comprobantes con filtros tipo/estado/fecha | `GET /facturacion/comprobantes/` |
| **Invoice Add New** | `/add-new` | **Adaptar** para ver detalle de comprobante | `GET /facturacion/comprobantes/{id}/` |

**Endpoints necesarios backend:**
```
GET          /api/v1/facturacion/comprobantes/
GET          /api/v1/facturacion/comprobantes/{id}/
POST         /api/v1/facturacion/comprobantes/{id}/reenviar/
POST         /api/v1/facturacion/notas-credito/
POST         /api/v1/facturacion/notas-debito/
GET          /api/v1/facturacion/series/
```

**Indicadores visuales:**
- Pendiente = amarillo
- Aceptado = verde
- Error = rojo
- Links a PDF/XML descargables

---

## 📋 CRONOGRAMA PARA EL 50%

### Semana 1 (Prioridad Jefe - E-commerce + Ventas)
- [ ] **Día 1-2:** CAPA 2 Backend - Modelos inventario + endpoints
- [ ] **Día 2-3:** CAPA 2 Frontend - Vistas productos (grid + listado)
- [ ] **Día 3-5:** CAPA 3 Backend - POS, cotizaciones, clientes
- [ ] **Día 5:** CAPA 3 Frontend - POS funcional (adaptar cart/checkout)

### Semana 2 (Facturación + Media)
- [ ] **Día 1-2:** CAPA 4 Backend - Nubefact, generación comprobantes
- [ ] **Día 2-3:** CAPA 4 Frontend - Lista comprobantes
- [ ] **Día 3-4:** CAPA 5 Backend - Media R2, proveedores básico
- [ ] **Día 4-5:** CAPA 5 Frontend - Fotos en productos, upload

---

## 🎨 DECISIONES DE UI TOMADAS

### Login (YA IMPLEMENTADO)
- ✅ Usar diseño stitch inspirado
- ✅ Logo geométrico JSoluciones inline
- ✅ Paleta de colores: Terracota #D65A42, Negro Carbón #1A1A1A
- ✅ Tipografía: Playfair Display (títulos), Inter (cuerpo)
- ✅ Panel derecho con cards flotantes (analytics mock)
- ✅ Fondo crema #F9F7F2

### Navegación Principal
- Sidebar filtrado por permisos del usuario
- Dashboard con KPIs reales
- Menú: Inventario, Ventas (POS), Clientes, Facturación

---

## 📁 ARCHIVOS DE REFERENCIA

- `00_PLAN_EJECUCION.md` — Plan maestro completo
- `10_mapa_template_tailwick.md` — Todas las vistas del template
- `14_DB_TABLAS_DESCRIPCION.MD` — Descripción de las 47 tablas
- `08_PROCESOS_FRONTEND.md` — Procesos para construir vistas

---

*Documento generado para seguimiento del progreso real vs planificado.*
