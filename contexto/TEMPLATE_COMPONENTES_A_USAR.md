# JSoluciones ERP - Componentes del Template Tailwick a Usar

> Documento validado contra: SQL_JSOLUCIONES.sql (47 tablas), Backend Django (7 apps funcionales, ~70 endpoints), Frontend actual (Tailwick template + login custom).

---

## Estado Actual del Frontend

### Lo que YA existe custom (JSoluciones):
- Login page (`/login`) - Completamente reescrita con branding JSoluciones
- Perfil page (`/perfil`) - Datos del usuario autenticado
- AuthContext con JWT (login, logout, refresh, hasPermission, hasRole)
- ProtectedRoute con RBAC
- Axios con interceptors JWT + refresh automático
- API generada con Orval (22K lineas, tipos + react-query hooks)
- Componentes comunes: `DataTable` (básico), `Badge`, `ConfirmModal`, `EmptyState`, `ErrorBoundary`
- Sidebar con menú ERP + menú template original

### Lo que es TEMPLATE SIN MODIFICAR (datos mock/demo):
- 4 dashboards (ecommerce, analytics, email, HR)
- Ecommerce: product-list, product-grid, cart, checkout, orders, sellers
- HR: employee, holidays, attendance, leave, payroll, department
- Invoice: overview, list, add-new
- Users: list, grid
- Apps: calendar, chat, mailbox, notes
- 9 demos de layout sidebar
- Auth: register, verify-email, reset-password, two-steps, logout, create-password
- Landing pages, 404, coming-soon, maintenance, offline

---

## Stack de UI del Template

| Capa | Librería | Para qué |
|------|----------|----------|
| Estilos | Tailwind CSS 4 | Clases utilitarias |
| Interacciones JS | Preline (`hs-dropdown`, `hs-overlay`, `hs-tab`, `hs-accordion`) | Dropdowns, modales, tabs, acordeones |
| Gráficos | ApexCharts (`react-apexcharts`) | Bar, line, pie, donut, area |
| Calendario | FullCalendar (`@fullcalendar/*`) | Vista calendario completa |
| Date picker | Flatpickr (`react-flatpickr`) | Selector de fechas |
| Toasts | react-hot-toast | Notificaciones |
| Scrollbar | simplebar-react | Scrollbar custom (sidebar) |
| Iconos | react-icons (`Lu*` = Lucide) + @iconify/react | Iconografía |
| Carousel | Swiper | Sliders/carouseles |
| HTTP | Axios + @tanstack/react-query | Llamadas API + cache |
| Codegen | Orval | Genera hooks de API desde OpenAPI |

---

## COMPONENTES FIJOS (se usan en TODOS los módulos)

Estos NO tienen alternativa - son obligatorios:

### 1. DataTable
**Archivo template:** Los listados en `product-list`, `orders`, `employee`, `invoice/list` todos usan tablas con estructura similar.
**Lo que existe custom:** `src/components/common/DataTable.tsx` (básico, sin paginación ni sorting)
**Necesita:** Mejorar con paginación servidor, sorting, selección múltiple.
**Referencia template:** `src/app/(admin)/(app)/(ecommerce)/product-list/components/ProductList.tsx` - tabla más completa con checkboxes, badges, acciones.
**Usan:** Todas las vistas de listado (~20+ vistas)
**Backend soporta:** Paginación (PageNumber 20/page, Cursor 50/page), filtros via django-filters, búsqueda

### 2. Badge / BadgeStatus
**Archivo template:** Usado en prácticamente todas las tablas del template.
**Lo que existe custom:** `src/components/common/Badge.tsx` (5 variantes: default, success, warning, danger, info)
**Necesita:** Mapear estados del backend a colores.
**Mapeo de estados reales del SQL:**

| Entidad | Estados (DB enum) | Color sugerido |
|---------|-------------------|----------------|
| Cotización | borrador, vigente, aceptada, vencida, rechazada | gray, blue, green, yellow, red |
| Orden Venta | pendiente, confirmada, parcial, completada, cancelada | yellow, blue, info, green, red |
| Venta | completada, anulada | green, red |
| Comprobante SUNAT | pendiente, aceptado, rechazado, observado, anulado, error, pendiente_reenvio | yellow, green, red, warning, gray, red, yellow |
| Orden Compra | borrador, pendiente_aprobacion, aprobada, enviada, recibida_parcial, recibida, cerrada, cancelada | gray, yellow, blue, info, warning, green, default, red |
| CxC/CxP | pendiente, vencido, pagado, refinanciado | yellow, red, green, info |
| Pedido | pendiente, confirmado, despachado, en_ruta, entregado, cancelado, devuelto | yellow, blue, info, info, green, red, warning |
| WA Mensaje | enviado, entregado, leido, fallido, en_espera | blue, green, green, red, yellow |

### 3. PageHeader
**Template:** Todas las páginas tienen un header con breadcrumb + título.
**Lo que existe:** `src/components/PageBreadcrumb.tsx`
**Necesita:** Agregar botones CTA (ej: "Nuevo Cliente", "Nueva Cotización")
**Usan:** Todas las páginas

### 4. FilterBar
**Template:** Las tablas de product-list, orders, employee tienen filtros inline.
**Lo que existe:** Nada dedicado aún.
**Necesita:** Componente reutilizable con dropdowns (Preline `hs-dropdown`), date range (Flatpickr), búsqueda texto.
**Usan:** Todas las vistas de listado
**Backend soporta:** django-filters en todas las apps (filtro por estado, fecha, cliente, etc.)

### 5. ModalForm
**Template:** Modales en sellers, holidays, department, leave.
**Lo que existe:** `src/components/common/ConfirmModal.tsx` (solo confirmación, no formulario)
**Referencia template:** `src/app/(admin)/(app)/(ecommerce)/sellers/components/Modal.tsx`
**Necesita:** Componente modal con formulario interno, validación, botones guardar/cancelar.
**Usan:** Clientes, Proveedores, Usuarios, Productos, Almacenes, Roles

### 6. Layout Admin (Sidebar + Topbar + Footer)
**Ya funciona:** `src/app/(admin)/layout.tsx` con sidebar collapsible, topbar, customizer.
**Acción:** Solo limpiar menú (quitar secciones "Template -").

---

## COMPONENTES CON OPCIONES A ELEGIR

### 7. Dashboard Principal

El template tiene **4 dashboards**. Para JSoluciones recomiendo:

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Ecommerce** | `src/app/(admin)/(dashboards)/index/` | KPI cards, ventas por mes (bar), revenue (line), top productos, pedidos recientes | **USAR ESTE** - Es el más cercano a un ERP de ventas |
| Analytics | `src/app/(admin)/(dashboards)/analytics/` | Tráfico web, sesiones, pageviews | NO - Es para web analytics, no aplica |
| Email | `src/app/(admin)/(dashboards)/email/` | Campañas email, open rates | NO - Quizás útil para WA en el futuro, no ahora |
| HR | `src/app/(admin)/(dashboards)/hr/` | Empleados, nómina, entrevistas | NO - No hay módulo HR |

**Decisión: Ecommerce Dashboard.** Adaptar KPI cards para:
- Ventas del día (backend: `GET /api/v1/ventas/resumen-dia/`)
- Ingresos del mes
- Pedidos activos
- Stock crítico (backend: `GET /api/v1/inventario/alertas-stock/`)
- Top 5 productos/clientes (chart bar/pie)

### 8. Vista de Productos

El template tiene **3 vistas** para productos:

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Product List** | `product-list/` | Tabla con imagen, nombre, precio, stock, categoría, rating, acciones | **USAR PARA INVENTARIO** - Vista administrativa principal |
| **Product Grid** | `product-grid/` | Cards en grid con imagen, filtros laterales | **USAR PARA POS** - Grid de productos para seleccionar rápido |
| Product Overview | `product-overview/` | Detalle producto con galería, tabs, ratings | OPCIONAL - Podría servir para ficha de producto |

**Decisión:**
- `/inventario/productos` -> Product List (tabla administrativa)
- `/ventas/pos` columna izquierda -> Product Grid (selección rápida)
- `/inventario/productos/:id` -> Product Overview (detalle)

**Backend valida:** Producto tiene sku, nombre, precio_venta, precio_compra, categoria, stock_minimo, stock_maximo, unidad_medida, codigo_barras. Todo mapea bien.

### 9. Vista de Órdenes/Ventas

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Orders** | `orders/` | Tabla con número, cliente, fecha, monto, estado badge, acciones | **USAR PARA LISTA DE VENTAS** |
| Order Overview | `order-overview/` | Detalle orden: timeline de estados, productos, dirección, resumen | **USAR PARA DETALLE DE VENTA** |

**Backend valida:** Venta tiene numero, fecha, cliente, vendedor, tipo_venta, metodo_pago, totales, estado. Matches perfecto.

### 10. POS (Punto de Venta)

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Cart** | `cart/` | Lista de items con cantidad editable, subtotal, resumen, botón checkout | **USAR para columna derecha del POS** (carrito) |
| **Product Grid** | `product-grid/` | Grid de cards con filtro | **USAR para columna izquierda** (catálogo) |
| Checkout | `checkout/` | Formulario de envío + resumen | NO DIRECTAMENTE - Muy orientado a ecommerce |

**Decisión:** Combinar Product Grid (izq) + Cart (der) en layout 60/40 full-screen.
**Backend:** `POST /api/v1/ventas/pos/` - Recibe cliente_id, items[{producto_id, cantidad, precio_unitario}], metodo_pago. Valida stock, deduce inventario, crea venta.

### 11. Vista de Clientes

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Users List** | `users-list/` | Tabla con avatar, nombre, email, rol, estado, acciones | **USAR** - Adaptar columnas para RUC/DNI, razón social, segmento |
| Users Grid | `users-grid/` | Cards con avatar y acciones | NO para listado principal, OPCIONAL para vista rápida |

**Backend valida:** Cliente tiene tipo_documento, numero_documento, razon_social, email, telefono, segmento, limite_credito, is_active.

### 12. Vista de Facturación

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Invoice List** | `invoice/list/` | Tabla con #, cliente, email, fecha, monto, estado badge | **USAR** - Adaptar para comprobantes SUNAT |
| **Invoice Overview** | `invoice/overview/` | Dashboard con KPIs + vista previa factura PDF | **USAR** - KPIs de facturación |
| Invoice Add New | `invoice/add-new/` | Formulario crear factura con tabla de items editable | **USAR** - Para emisión manual de comprobantes |

**Backend valida:** Comprobante tiene tipo_comprobante (01/03/07/08), serie, numero, fecha_emision, cliente, moneda, totales, estado_sunat, pdf_url, xml_url.
**Nota importante:** El template de `add-new` es ideal para la emisión manual. El backend tiene `emitir_comprobante_desde_venta()` como servicio pero NO como endpoint API aún.

### 13. Vista de Cotizaciones

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Sales Estimates** | `(hr)/sales-estimates/` | Tabla de estimados con #, cliente, fecha, monto, estado, acciones editar/eliminar | **USAR** - Es exactamente una tabla de cotizaciones |

**Backend valida:** Cotización tiene numero, fecha_emision, fecha_validez, cliente, vendedor, estado (borrador/vigente/aceptada/vencida/rechazada), totales. Endpoints: CRUD + duplicar + convertir-orden.

### 14. Vista de Cobros/Pagos

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Sales Payments** | `(hr)/sales-payments/` | Tabla de pagos con #, cliente, método, monto, fecha, estado | **USAR** - Adaptar para CxC |

**Backend:** Las tablas `cuentas_por_cobrar`, `cobros`, `cuentas_por_pagar`, `pagos` existen en SQL pero la app `finanzas` está vacía. Hay que implementar el backend primero.

### 15. Calendario

| Opción | Disponibilidad | Recomendación |
|--------|---------------|---------------|
| **FullCalendar** | Ya instalado, demo en `calendar/` | **USAR** - Para vencimientos CxC/CxP, cotizaciones por vencer, vencimientos tributarios |

**Backend:** Útil cuando se implemente finanzas. Las fechas de vencimiento ya están en cotizaciones (fecha_validez), CxC/CxP (fecha_vencimiento).

### 16. Chat/Mensajería

| Opción | Archivo | Recomendación |
|--------|---------|---------------|
| Chat | `chat/` | **FUTURO** - Podría servir de base para módulo WhatsApp (CAPA 9) |

**Backend:** App `whatsapp` es stub vacío. No usar ahora.

### 17. Empleados / Users

| Opción | Archivo | Lo que tiene | Recomendación |
|--------|---------|--------------|---------------|
| **Employee List** | `(hr)/employee/` | Tabla con datos de empleado, edición inline, modal delete | **USAR** - Para gestión de usuarios del ERP |

**Backend valida:** Usuario tiene email, first_name, last_name, is_active. PerfilUsuario tiene rol, telefono, avatar.

---

## COMPONENTES AVANZADOS (implementar cuando se necesiten)

### 18. KPICard
**Template:** Usadas en los 4 dashboards.
**Referencia:** `src/app/(admin)/(dashboards)/index/components/SalesThisMonth.tsx`, `WelcomeUser.tsx`, etc.
**Para:** Dashboard principal, Reportes, WhatsApp métricas (futuro)
**Backend:** `GET /api/v1/ventas/resumen-dia/` retorna totales. Falta endpoint de resumen mensual.

### 19. Charts (ApexCharts)
**Template:** Bar, Line, Pie, Donut, Area en todos los dashboards.
**Referencia:** `SalesRevenueOverview.tsx` (bar), `Audience.tsx` (line), `TrafficResources.tsx` (donut)
**Para:** Dashboard, Reportes de ventas, Stock por categoría
**Backend:** Necesita endpoints de agregación (no existen aún). Los datos base sí están.

### 20. Timeline
**Template:** `src/app/(admin)/(pages)/timeline/index.tsx` tiene un componente Timeline completo.
**Para:** Órdenes de Venta (flujo: Cotización -> Orden -> Venta -> Despacho), Trazabilidad de lotes, Seguimiento de pedidos.
**Backend valida:** `seguimiento_pedidos` tiene pedido_id, estado, fecha_evento, descripción. Logs de actividad también.

### 21. WizardForm (Stepper multi-paso)
**Template:** No hay un componente wizard dedicado en el template.
**Necesita:** Construir custom con tabs de Preline (`hs-tab`) + estado por paso.
**Para:** Crear cotización (4 pasos), Crear orden compra (4 pasos).
**Backend valida:** `crear_cotizacion()` recibe cliente_id + items[]. El wizard sería solo UX frontend.

---

## COMPONENTES QUE NO EXISTEN EN EL TEMPLATE (construir desde cero)

| Componente | Para qué | Prioridad | Cómo construir |
|------------|----------|-----------|----------------|
| **KanbanBoard** | Órdenes de venta por estado | Media | Librería `@hello-pangea/dnd` o similar + cards Tailwind |
| **MapView** | Distribución, seguimiento pedidos | Baja (CAPA 8 no implementada) | Leaflet + react-leaflet |
| **TreeView** | Almacén -> Zona -> Estantería | Baja | Acordeón anidado con Preline `hs-accordion` |
| **PermissionMatrix** | Roles y permisos (checkboxes) | Media | Tabla HTML con checkboxes, no necesita librería |
| **SidePanel/Drawer** | Detalle rápido sin cambiar página | Media | Preline `hs-overlay` modo offcanvas |

---

## MAPEO FINAL: Módulo ERP -> Componente Template -> Backend

### CAPA ACTUAL (implementado en backend)

| Módulo ERP | Ruta Frontend | Componente Template Base | Backend Endpoint |
|------------|---------------|--------------------------|------------------|
| **Dashboard** | `/dashboard` | Ecommerce Dashboard | `GET /ventas/resumen-dia/`, `GET /inventario/alertas-stock/` |
| **Ventas - POS** | `/ventas/pos` | Product Grid + Cart | `POST /ventas/pos/`, `GET /inventario/productos/buscar/` |
| **Ventas - Lista** | `/ventas` | Orders | `GET /ventas/`, `GET /ventas/{id}/` |
| **Ventas - Detalle** | `/ventas/:id` | Order Overview | `GET /ventas/{id}/` |
| **Cotizaciones** | `/ventas/cotizaciones` | Sales Estimates | `GET/POST /ventas/cotizaciones/`, duplicar, convertir-orden |
| **Productos** | `/inventario/productos` | Product List | `GET /inventario/productos/` |
| **Producto Crear** | `/inventario/productos/crear` | Product Create | `POST /inventario/productos/` |
| **Producto Detalle** | `/inventario/productos/:id` | Product Overview | `GET /inventario/productos/{id}/` (incluye stock) |
| **Clientes** | `/clientes` | Users List | `GET/POST /clientes/`, buscar, soft-delete |
| **Proveedores** | `/proveedores` | Users List (adaptado) | `GET/POST /proveedores/`, buscar |
| **Comprobantes** | `/facturacion/comprobantes` | Invoice List | `GET /facturacion/comprobantes/`, reenviar, notas, logs |
| **Facturación Dashboard** | `/facturacion` | Invoice Overview | `GET /facturacion/comprobantes/` (agregado) |
| **Emitir Comprobante** | `/facturacion/nuevo` | Invoice Add New | Servicio existe pero falta endpoint API |
| **Usuarios** | `/configuracion/usuarios` | Users List / Employee | `GET/POST /usuarios/` |
| **Roles y Permisos** | `/configuracion/roles` | Custom (PermissionMatrix) | `GET /usuarios/roles/`, `GET /usuarios/roles/{id}/permisos/` |
| **Empresa** | `/configuracion/empresa` | Custom form | `GET/PATCH /empresa/` |
| **Perfil** | `/perfil` | Custom (ya existe) | `GET /auth/me/` |

### CAPA FUTURA (backend vacío/stub)

| Módulo ERP | Componente Template Sugerido | Estado Backend |
|------------|------------------------------|----------------|
| Almacenes | DataTable + TreeView | Endpoints EXISTEN (`/inventario/almacenes/`) |
| Stock Tiempo Real | DataTable + Charts | Endpoints EXISTEN (`/inventario/stock/`, `/alertas-stock/`) |
| Movimientos Stock | DataTable con tabs | Endpoints EXISTEN (`/inventario/movimientos/`, ajuste, transferencia) |
| Lotes/Trazabilidad | DataTable + Timeline | Endpoints EXISTEN (`/inventario/lotes/`) |
| Órdenes de Compra | DataTable + WizardForm | Backend VACÍO (app compras) |
| CxC / CxP | Sales Payments + Calendar | Backend VACÍO (app finanzas) |
| Contabilidad | DataTable con tabs | Backend VACÍO (app finanzas) |
| Distribución | MapView + Timeline | Backend VACÍO (app distribucion) |
| WhatsApp | Chat + DataTable | Backend VACÍO (app whatsapp) |
| Reportes | Charts + DataTable + Export | Backend VACÍO (app reportes) |

---

## ARCHIVOS TEMPLATE QUE SE PUEDEN ELIMINAR

Estos no se usan para JSoluciones y solo añaden peso:

### Eliminar seguro (no mapean a ningún módulo ERP):
- `src/app/(admin)/(dashboards)/analytics/` - Web analytics
- `src/app/(admin)/(dashboards)/email/` - Email marketing
- `src/app/(admin)/(dashboards)/hr/` - HR dashboard
- `src/app/(admin)/(app)/(hr)/holidays/` - Vacaciones
- `src/app/(admin)/(app)/(hr)/attendance/` - Asistencia
- `src/app/(admin)/(app)/(hr)/attendance-main/` - Asistencia principal
- `src/app/(admin)/(app)/(hr)/leave/` - Permisos laborales
- `src/app/(admin)/(app)/(hr)/leave-employee/` - Permisos empleado
- `src/app/(admin)/(app)/(hr)/create-leave/` - Crear permiso
- `src/app/(admin)/(app)/(hr)/create-leave-employee/` - Crear permiso empleado
- `src/app/(admin)/(app)/(hr)/department/` - Departamentos
- `src/app/(admin)/(app)/(hr)/payroll-employee-salary/` - Nómina
- `src/app/(admin)/(app)/(hr)/payroll-payslip/` - Recibos de pago
- `src/app/(admin)/(app)/(hr)/create-payslip/` - Crear recibo
- `src/app/(admin)/(app)/(hr)/sales-expenses/` - Gastos HR
- `src/app/(admin)/(app)/(ecommerce)/sellers/` - Vendedores ecommerce
- `src/app/(admin)/(app)/(ecommerce)/checkout/` - Checkout ecommerce
- `src/app/(admin)/(layouts)/` - Todas las 9 demos de layout
- `src/app/(admin)/(pages)/pricing/` - Pricing page
- `src/app/(admin)/(pages)/faqs/` - FAQ page
- `src/app/(admin)/(pages)/starter/` - Starter page
- `src/app/(landing)/` - Ambas landing pages
- `src/app/(others)/coming-soon/` - Coming soon
- `src/app/(others)/maintenance/` - Maintenance
- `src/app/(others)/offline/` - Offline

### Conservar para referencia/reutilización:
- `src/app/(admin)/(dashboards)/index/` - Dashboard ecommerce (base del dashboard ERP)
- `src/app/(admin)/(app)/(ecommerce)/product-list/` - Base para inventario
- `src/app/(admin)/(app)/(ecommerce)/product-grid/` - Base para POS
- `src/app/(admin)/(app)/(ecommerce)/product-create/` - Base para crear producto
- `src/app/(admin)/(app)/(ecommerce)/product-overview/` - Base para detalle producto
- `src/app/(admin)/(app)/(ecommerce)/cart/` - Base para carrito POS
- `src/app/(admin)/(app)/(ecommerce)/orders/` - Base para lista ventas
- `src/app/(admin)/(app)/(ecommerce)/order-overview/` - Base para detalle venta
- `src/app/(admin)/(app)/(hr)/employee/` - Base para gestión usuarios
- `src/app/(admin)/(app)/(hr)/sales-estimates/` - Base para cotizaciones
- `src/app/(admin)/(app)/(hr)/sales-payments/` - Base para CxC/CxP
- `src/app/(admin)/(app)/(invoice)/` - Todas (facturación)
- `src/app/(admin)/(app)/(users)/` - Ambas (usuarios/clientes)
- `src/app/(admin)/(app)/calendar/` - Para vencimientos
- `src/app/(admin)/(app)/chat/` - Base para WhatsApp (futuro)
- `src/app/(admin)/(app)/notes/` - Podría servir para notas internas
- `src/app/(admin)/(pages)/timeline/` - Componente timeline
- `src/app/(auth)/modern-*/` - Auth pages (login ya custom, las demás sirven)
- `src/app/(others)/404/` - Página 404

### Del sidebar menu, quitar estas secciones:
- "Template - Ecommerce" (las rutas ERP ya apuntan a los mismos componentes)
- "Template - HR Management" (excepto sales-estimates y sales-payments)
- "Template - Invoice" (las rutas ERP ya apuntan)
- "Template - Users" (las rutas ERP ya apuntan)
- "Template - Apps" (excepto calendar)
- "Template - Auth" (solo modern, quitar basic/boxed/cover que dan 404)
- "Template - Landing" (eliminar)
- "Template - Pages" (eliminar excepto timeline)
- "Template - Layouts" (eliminar, usar el customizer en su lugar)

---

## DISCREPANCIAS ENCONTRADAS entre Template Mapping Doc y realidad

### En el TEMPLATE_MAPPING.MD pero NO existe en backend:
1. `PedidoOnline` (vista 1.2) - No hay tabla. Las ventas tienen `tipo_venta = 'online'` pero no canal WooCommerce/Shopify.
2. `ExtractoBancario`, `ConciliacionBancaria` (vista 6.3) - No hay tablas en SQL.
3. `DeclaracionTributaria`, `ResumenMensual` (vista 6.5) - No hay tablas en SQL.
4. `Disparador`, `Campaña` (vista 7.3) - No hay tablas en SQL. Solo existen `whatsapp_plantillas` y `whatsapp_mensajes`.
5. `Ruta`, `PedidoRuta` (vista 4.2) - No hay tablas. Solo `pedidos` con `transportista_id`.
6. `Zona`, `Estanteria` (vista 2.1) - No hay tablas. `almacenes` es tabla plana sin jerarquía.
7. `MetodoPago` como tabla (vista 1.1) - Es un enum, no tabla. Correcto en SQL.
8. `Caja`, `Sucursal` como tablas (vista 1.1) - Son campos VARCHAR en `ventas`, no tablas independientes.

### En el SQL pero NO mencionado en TEMPLATE_MAPPING.MD:
1. `series_comprobante` - Gestión de series de facturación (F001, B001, etc.)
2. `log_envio_nubefact` - Logs de intentos de envío a SUNAT
3. `media_archivos` - Tabla polimórfica de archivos en R2

### Backend implementado pero SIN ruta frontend:
1. **Almacenes** - Backend completo (`/inventario/almacenes/`) pero no hay ruta en router
2. **Stock** - Backend completo (`/inventario/stock/`, `/alertas-stock/`) pero no hay ruta
3. **Movimientos** - Backend completo (`/inventario/movimientos/`, ajuste, transferencia) pero no hay ruta
4. **Lotes** - Backend completo (`/inventario/lotes/`) pero no hay ruta
5. **Proveedores** - Backend completo (`/proveedores/`) pero no hay ruta ni menú
6. **Órdenes de Venta** - Backend completo (`/ventas/ordenes/`) pero no hay ruta
7. **Notas Crédito/Débito** - Backend completo (`/facturacion/notas/`) pero no hay ruta
8. **Series de Comprobante** - Backend completo (`/facturacion/series/`) pero no hay ruta

---

## BUGS CONOCIDOS EN EL FRONTEND ACTUAL

1. **QueryClient duplicado:** Tanto `main.tsx` como `App.tsx` crean un `QueryClient` y wrappean en `QueryClientProvider`. Quitar uno.
2. **AuthProvider duplicado:** Wrapeado en `main.tsx` Y en `App.tsx`.
3. **Perfil doble layout:** `/perfil` renderiza `PageWrapper` internamente pero ya está wrapeado por el router.
4. **helpers/constants.ts sin actualizar:** Dice `appName = 'Tailwick'`, `appAuthor = 'Themesdesign'`.
5. **Menú con rutas muertas:** Basic Auth, Boxed Auth, Cover Auth en sidebar pero no tienen rutas -> 404.
6. **Dependencias en devDependencies:** `axios`, `@tanstack/react-query`, `@tanstack/react-query-devtools` deberían estar en `dependencies`.

---

*Generado: Feb 2026. Validado contra SQL (47 tablas, 33 enums), Backend (7 apps funcionales, ~70 endpoints), Frontend (Tailwick template + auth custom).*
