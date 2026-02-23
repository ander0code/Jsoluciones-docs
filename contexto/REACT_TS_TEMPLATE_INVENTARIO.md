# React-TS Template - Inventario Completo de Componentes y Vistas

> Documento de referencia rapida. Cuando necesites un componente del template, consulta este archivo en vez de recorrer React-TS/.
> Generado: Feb 2026. Template: Tailwick (React + TypeScript + Tailwind CSS 3 + Vite)

---

## STACK DEL TEMPLATE

| Capa | Libreria | Uso |
|------|----------|-----|
| UI/CSS | Tailwind CSS 3 | Clases utilitarias |
| Interacciones JS | Preline (HSStaticMethods) | Dropdowns, modales, tabs, acordeones (clases hs-*) |
| Graficos | ApexCharts (react-apexcharts) | Bar, line, pie, donut, area, radial |
| Calendario | FullCalendar | Vista calendario completa |
| Date picker | Flatpickr | Selector de fechas |
| Scrollbar | simplebar-react | Scrollbar custom |
| Iconos | react-icons (Lucide Lu*) + @iconify/react | Iconografia |
| Router | React Router v7 | Navegacion con lazy loading |
| Estado | React Context + useLocalStorage (usehooks-ts) | Layout state persistido |

---

## ESTRUCTURA DE CARPETAS

```
React-TS/src/
├── main.tsx                    # Entry point (BrowserRouter + StrictMode)
├── App.tsx                     # Root (CSS imports + ProvidersWrapper + AppRoutes)
├── routes/
│   ├── index.tsx               # AppRoutes: renderiza rutas con/sin layout admin
│   └── Routes.tsx              # 80+ rutas definidas con React.lazy()
├── components/
│   ├── ProvidersWrapper.tsx    # LayoutProvider + Preline init
│   ├── PageWrapper.tsx         # Shell admin: Sidebar + Topbar + Footer + Customizer
│   ├── PageBreadcrumb.tsx      # Breadcrumb reutilizable
│   ├── PageMeta.tsx            # <title> tag helper
│   ├── client-wrapper/
│   │   ├── ApexChartClient.tsx # Wrapper memoizado de ApexCharts
│   │   ├── SimplebarClient.tsx # Re-export de simplebar-react
│   │   └── IconifyIcon.tsx     # Re-export de @iconify/react
│   └── layouts/
│       ├── SideNav/
│       │   ├── index.tsx       # Sidebar principal (logo + menu)
│       │   ├── AppMenu.tsx     # Menu completo con items colapsables
│       │   ├── menu.ts         # Datos del menu (todos los items)
│       │   └── HoverToggle.tsx # Toggle hover/hover-active
│       ├── topbar/
│       │   ├── index.tsx       # Topbar (search, idioma, notificaciones, perfil)
│       │   ├── ThemeModeToggle.tsx  # Boton light/dark
│       │   └── SidenavToggle.tsx    # Hamburger toggle sidebar
│       ├── customizer/
│       │   ├── index.tsx       # Panel lateral de configuracion
│       │   ├── SidenavView.tsx # 7 modos de sidebar
│       │   ├── SidenavColor.tsx # Light/Dark sidebar
│       │   ├── ThemeMode.tsx   # Light/Dark/System
│       │   ├── Direction.tsx   # LTR/RTL
│       │   ├── FullScreenToggle.tsx # Fullscreen API
│       │   └── Reset.tsx       # Reset todo a defaults
│       └── Footer.tsx          # Footer con copyright
├── context/
│   └── useLayoutContext.tsx    # Estado global layout (tema, sidebar, dir)
├── utils/
│   ├── colors.ts              # Lee CSS vars de Tailwind para ApexCharts
│   └── layout.ts              # DOM utils (toggle attrs, backdrop, etc)
├── helpers/
│   ├── debounce.ts            # Debounce generico
│   └── constants.ts           # appName, currency, colorVariants, etc
├── types/
│   └── index.ts               # ChildrenType
├── assets/                    # Imagenes (avatars, productos, flags, logos, etc)
└── app/                       # Todas las paginas organizadas por seccion
```

---

## RUTAS Y PAGINAS COMPLETAS

### A. DASHBOARDS (4 paginas)

Todas en: `src/app/(admin)/(dashboards)/`

#### 1. ECOMMERCE DASHBOARD
- **Ruta:** `/` o `/index`
- **Archivo:** `index/index.tsx`
- **Componentes internos:**
  - `WelcomeUser` - Tarjeta de bienvenida con icono de medalla
  - `ProductOrderDetails` - KPI stat cards (pedidos, ganancias, etc)
  - `OrderStatistics` - Chart linea (pendientes vs nuevos)
  - `SalesRevenueOverview` - Chart barras apiladas (ventas vs beneficio por mes)
  - `TrafficResources` - Chart radial (Direct/Referrals/Search %)
  - `ProductOrders` - Tabla de pedidos recientes
  - `CustomerService` - Tarjeta metricas servicio al cliente
  - `SalesThisMonth` - Chart area de rango (beneficio/gasto)
  - `TopSellingProducts` - Lista top productos
  - `Audience` - Chart barras apiladas (audiencia por genero)
- **Datos charts:** `data.ts` con funciones: `getOrderStatisticsChart`, `getSalesRevenueOverview`, `geTtrafficResourcesChart`, `getSalesThisMonthChart`, `getAudienceChart`
- **Ideal para:** Dashboard principal ERP, KPIs de ventas, metricas generales

#### 2. ANALYTICS DASHBOARD
- **Ruta:** `/analytics`
- **Archivo:** `analytics/index.tsx`
- **Componentes internos:**
  - `Analytics` - Cards de metricas web
  - `PerspectiveChart` - Chart de perspectiva
  - `LocationBased` - Metricas por ubicacion
  - `PagesInteraction` - Interaccion de paginas
  - `UserChart` - Chart actividad usuarios
  - `ProductsStatistics` - Estadisticas productos
  - `AnalyticsReports` - Reportes resumen
  - `StatusOfMonthlyCampaign` - Estado campanas mensuales
  - `SubscriptionDistribution` - Distribucion suscripciones
  - `TrafficSource` - Fuentes de trafico
- **Ideal para:** NO aplica directamente a ERP. Solo si necesitas charts de analytics web.

#### 3. EMAIL DASHBOARD
- **Ruta:** `/email`
- **Archivo:** `email/index.tsx`
- **Componentes internos:**
  - `EmailLineChart` - Sparklines (Enviados, Open Rate, Click Rate)
  - `EmailBarChart` - Sparklines (Click Through, Delivered, Bounce, Unsub, Spam)
  - `EmailData` - Chart linea (Open Rate vs Click Rate)
  - `EmailMarketing` - Chart radial (Enviados/Abiertos/No abiertos)
  - `ComposeEmail` - Card redaccion email
  - `EmailPerformance` - Tabla rendimiento emails
- **Datos charts:** `data.ts` con 10 funciones de opciones de charts
- **Ideal para:** Base para modulo de mensajeria/WhatsApp (futuro)

#### 4. HR DASHBOARD
- **Ruta:** `/hr`
- **Archivo:** `hr/index.tsx`
- **Componentes internos:**
  - `Activities` - Feed actividades con sparklines radiales (Total Employee, Applications, Hired, Rejected)
  - `EmployeeDetails` - Tabla/lista de empleados
  - `ApplicationReceived` - Chart area + linea (Aplicaciones vs Contratados)
  - `EmployeePerformance` - Metricas rendimiento
  - `TotalProjects` - Chart barras apiladas (New/Pending/Completed/Rejected)
  - `UpcomingInterview` - Lista entrevistas proximas
  - `BirthdayCard` - Card cumpleanos empleado
  - `RecentPayroll` - Resumen nomina reciente
  - `UpcomingScheduled` - Eventos programados
- **Datos charts:** `data.ts` con funciones chart para empleados y proyectos
- **Ideal para:** NO aplica directamente. Algunos charts reutilizables para reportes.

---

### B. APPS ECOMMERCE (9 paginas)

Todas en: `src/app/(admin)/(app)/(ecommerce)/`

#### 5. PRODUCT GRID (Catalogo visual)
- **Ruta:** `/product-grid`
- **Archivo:** `product-grid/index.tsx`
- **Componentes:**
  - `ProductFilter` - Sidebar con filtros (categoria, precio, rating, color)
  - `Products` - Grid de cards de productos con imagen, nombre, precio, rating
- **Ideal para:** POS (columna izquierda catalogo), vista rapida de inventario

#### 6. PRODUCT LIST (Tabla administrativa)
- **Ruta:** `/product-list`
- **Archivo:** `product-list/index.tsx`
- **Componentes:**
  - `ProductList` - Tabla completa con checkboxes, imagen, nombre, precio, stock, categoria, rating, acciones (edit/delete)
- **Ideal para:** Lista de inventario, gestion de productos, vista admin

#### 7. PRODUCT OVERVIEW (Detalle de producto)
- **Ruta:** `/product-overview`
- **Archivo:** `product-overview/index.tsx`
- **Componentes:**
  - `Product` - Galeria de imagenes del producto
  - `ProductDetails` - Tabs con especificaciones, info
  - `Ratings` - Seccion de reviews y calificaciones
- **Ideal para:** Ficha detalle de producto, vista de inventario individual

#### 8. PRODUCT CREATE (Crear producto)
- **Ruta:** `/product-create`
- **Archivo:** `product-create/index.tsx`
- **Componentes:**
  - `ProductCreat` - Formulario completo (nombre, descripcion, precio, categoria, etc)
  - `Preview` - Card preview del producto mientras se crea
- **Ideal para:** Formulario crear/editar producto en inventario

#### 9. SHOPPING CART (Carrito)
- **Ruta:** `/cart`
- **Archivo:** `cart/index.tsx`
- **Componentes:**
  - `CartItems` - Tabla de items con cantidad editable, subtotal, boton eliminar
  - `OrderSummary` - Resumen de precio (subtotal, descuento, envio, total)
  - `Modal` - Modal confirmacion eliminar item
- **Ideal para:** POS (columna derecha carrito), cualquier vista de items seleccionados

#### 10. CHECKOUT (Proceso de compra)
- **Ruta:** `/checkout`
- **Archivo:** `checkout/index.tsx`
- **Componentes:**
  - `ShoppingInformation` - Formulario envio/facturacion (nombre, direccion, metodo pago)
  - `OrdersSummary` - Resumen final del pedido
- **Ideal para:** Inspiracion para formularios de venta, poco uso directo en ERP

#### 11. ORDERS LIST (Lista de ordenes)
- **Ruta:** `/orders`
- **Archivo:** `orders/index.tsx`
- **Componentes:**
  - `OrderDetails` - Cards de estadisticas de ordenes (total, pendientes, completadas, etc)
  - `OrderOverView` - Chart resumen de ordenes
  - `OrderDetailTable` - Tabla principal de ordenes con #, cliente, fecha, monto, estado badge, acciones
- **Ideal para:** Lista de ventas, lista de ordenes de venta, lista de cotizaciones

#### 12. ORDER OVERVIEW (Detalle de orden)
- **Ruta:** `/order-overview`
- **Archivo:** `order-overview/index.tsx`
- **Componentes:**
  - `OrderDetails` - Header con info de la orden (#, fecha, estado)
  - `ShippingDetails` - Card direccion de envio
  - `OrdersSummary` - Tabla de items (producto, cantidad, precio, total)
  - `OrderStatus` - Timeline de estados del pedido
  - `DocumentTrackingOrder` - Panel lateral de seguimiento
- **Ideal para:** Detalle de venta, detalle de pedido, tracking

#### 13. SELLERS (Vendedores)
- **Ruta:** `/sellers`
- **Archivo:** `sellers/index.tsx`
- **Componentes:**
  - `Sallers` - Grid de cards de vendedores con avatar, nombre, ventas, rating
  - `Modal` - Modal agregar vendedor
- **Ideal para:** Poco uso directo en ERP

---

### C. APPS HR (15 paginas)

Todas en: `src/app/(admin)/(app)/(hr)/`

#### 14. EMPLOYEE LIST
- **Ruta:** `/employee`
- **Archivo:** `employee/index.tsx`
- **Componentes:**
  - `EmployeeDetails` - Tabla de empleados con avatar, nombre, email, departamento, puesto, acciones
  - `EditEmployeeData` - Modal editar empleado
  - `EmployeeDelete` - Modal confirmar eliminacion
- **Ideal para:** Gestion de usuarios ERP, lista de empleados/vendedores

#### 15. DEPARTMENT
- **Ruta:** `/department`
- **Archivo:** `department/index.tsx`
- **Componentes:**
  - `Departments` - Cards/tabla de departamentos
  - `AddDepartment` - Modal agregar departamento
  - `DeleteModal` - Modal confirmar eliminacion
- **Ideal para:** Categorias, almacenes, o cualquier entidad simple CRUD

#### 16. HOLIDAYS
- **Ruta:** `/holidays`
- **Archivo:** `holidays/index.tsx`
- **Componentes:**
  - `HoliyDays` - Tabla de dias festivos
  - `HoliydaysAdd` - Modal agregar
  - `HolidaysLeaveDeleteModal` - Modal eliminar
- **Ideal para:** Tabla simple con modales CRUD, referencia para cualquier listado simple

#### 17. LEAVE MANAGE (HR)
- **Ruta:** `/leave`
- **Archivo:** `leave/index.tsx`
- **Componentes:**
  - `LeaveCard` - Cards de estadisticas (total, aprobados, pendientes, rechazados)
  - `LeaveTabel` - Tabla de solicitudes de permiso
  - `Modal` - Modal de accion
- **Ideal para:** Cualquier vista con cards de resumen arriba + tabla abajo

#### 18. LEAVE MANAGE (EMPLOYEE)
- **Ruta:** `/leave-employee`
- **Archivo:** `leave-employee/index.tsx`
- **Componentes:**
  - `LeaveCard` - Cards de saldo de permisos
  - `EmpLeave` - Tabla de permisos del empleado
- **Ideal para:** Vista de "mis registros" de un usuario

#### 19. ADD LEAVE (HR)
- **Ruta:** `/create-leave`
- **Componentes:** `CreateLeave` - Formulario de permiso
- **Ideal para:** Formularios simples de creacion

#### 20. ADD LEAVE (EMPLOYEE)
- **Ruta:** `/create-leave-employee`
- **Componentes:** `AddLeave` - Formulario solicitud de permiso
- **Ideal para:** Formularios de solicitud/creacion desde perspectiva usuario

#### 21. ATTENDANCE (HR)
- **Ruta:** `/attendance`
- **Componentes:**
  - `EmployeeDetails` - Panel lateral info empleado
  - `EmployeeWorkDetails` - Cards resumen (horas, dias, etc)
  - `EmployeeWork` - Tabla de asistencia
- **Ideal para:** Vista detalle con panel lateral + tabla

#### 22. MAIN ATTENDANCE
- **Ruta:** `/attendance-main`
- **Componentes:**
  - `EmployeeReport` - Cards estadisticas del reporte
  - `EmployeeReportTabel` - Tabla reporte de asistencia
- **Ideal para:** Reportes con cards resumen + tabla

#### 23. SALES ESTIMATES (Estimados/Cotizaciones)
- **Ruta:** `/sales-estimates`
- **Componentes:**
  - `Estimates` - Tabla de estimados (#, cliente, fecha, monto, estado, acciones)
  - `EstimentModal` - Modal agregar/editar estimado
- **Ideal para:** Lista de cotizaciones, presupuestos, cualquier documento comercial

#### 24. SALES PAYMENTS (Pagos)
- **Ruta:** `/sales-payments`
- **Componentes:**
  - `Payments` - Tabla de pagos (#, cliente, metodo, monto, fecha, estado)
- **Ideal para:** CxC, CxP, lista de pagos/cobros

#### 25. SALES EXPENSES (Gastos)
- **Ruta:** `/sales-expenses`
- **Componentes:**
  - `Expenses` - Tabla de gastos
  - `ExpensesModal` - Modal agregar/editar gasto
- **Ideal para:** Registro de gastos, movimientos financieros

#### 26. EMPLOYEE SALARY
- **Ruta:** `/payroll-employee-salary`
- **Componentes:**
  - `EmployeeTotalSalary` - Cards resumen de salarios
  - `Salary` - Tabla de salarios
- **Ideal para:** Reportes financieros con resumen + detalle

#### 27. PAYSLIP
- **Ruta:** `/payroll-payslip`
- **Descripcion:** Pagina imprimible de recibo de pago con tabla de montos, deducciones, firma
- **Ideal para:** Vista de impresion de cualquier documento (factura, comprobante, recibo)

#### 28. CREATE PAYSLIP
- **Ruta:** `/create-payslip`
- **Componentes:** `CreatesSlip` - Formulario de creacion de recibo
- **Ideal para:** Formularios de creacion con multiples campos

---

### D. APPS INVOICE (3 paginas)

Todas en: `src/app/(admin)/(app)/(invoice)/`

#### 29. INVOICE LIST
- **Ruta:** `/list`
- **Archivo:** `list/index.tsx`
- **Componentes:**
  - `InvoiceList` - Sidebar/tabla de facturas
  - `InvoiceDetails` - Detalle de factura seleccionada
- **Ideal para:** Lista de comprobantes, facturas, documentos con preview lateral

#### 30. INVOICE OVERVIEW
- **Ruta:** `/overview`
- **Archivo:** `overview/index.tsx`
- **Componentes:**
  - `Savebutton` - Boton guardar/imprimir
  - Vista completa de factura: numero, fechas, empresa, direcciones, items, totales, notas
- **Ideal para:** Vista previa/impresion de factura, comprobante SUNAT

#### 31. ADD INVOICE
- **Ruta:** `/add-new`
- **Archivo:** `add-new/index.tsx`
- **Componentes:**
  - `AddNew` - Formulario creacion factura con tabla de items editable (agregar/eliminar filas)
- **Ideal para:** Emision de comprobantes, creacion de cotizaciones con items

---

### E. APPS USERS (2 paginas)

Todas en: `src/app/(admin)/(app)/(users)/`

#### 32. USERS LIST VIEW
- **Ruta:** `/users-list`
- **Archivo:** `users-list/index.tsx`
- **Componentes:**
  - `UserListTabel` - Tabla de usuarios con avatar, nombre, email, rol, estado, acciones
- **Ideal para:** Lista de clientes, proveedores, usuarios del sistema

#### 33. USERS GRID VIEW
- **Ruta:** `/users-grid`
- **Archivo:** `users-grid/index.tsx`
- **Componentes:**
  - `UserGrid` - Grid de cards de usuarios con avatar, nombre, acciones
- **Ideal para:** Vista rapida de contactos, directorio

---

### F. APPS STANDALONE (4 paginas)

Todas en: `src/app/(admin)/(app)/`

#### 34. CHAT
- **Ruta:** `/chat`
- **Archivo:** `chat/index.tsx`
- **Componentes:**
  - `IconTab` - Sidebar con tabs de iconos
  - `Chats` - Lista de conversaciones/contactos
  - `UserChats` - Area de mensajes activa
- **Ideal para:** Modulo WhatsApp (futuro), chat interno

#### 35. CALENDAR
- **Ruta:** `/calendar`
- **Archivo:** `calendar/index.tsx`
- **Componentes:**
  - `Calender` - Vista calendario (FullCalendar)
  - `Events` - Sidebar lista de eventos
  - `EventModal` - Modal crear/editar evento
  - `calendarEvents.ts` - Datos de eventos
- **Ideal para:** Vencimientos CxC/CxP, cotizaciones por vencer, agenda

#### 36. MAILBOX
- **Ruta:** `/mailbox`
- **Archivo:** `mailbox/index.tsx`
- **Componentes:**
  - `Emailsidebar` - Sidebar con carpetas/etiquetas
  - `Emails` - Lista de emails
  - `MailOffcanavs` - Panel lectura (offcanvas)
  - `EventModal` - Modal redaccion
- **Ideal para:** Bandeja de mensajes, notificaciones del sistema

#### 37. NOTES
- **Ruta:** `/notes`
- **Archivo:** `notes/index.tsx`
- **Componentes:**
  - `Notes` - Grid/lista de notas tipo sticky
- **Ideal para:** Notas internas, recordatorios, observaciones

---

### G. PAGINAS EXTRA (4 paginas)

Todas en: `src/app/(admin)/(pages)/`

#### 38. FAQS
- **Ruta:** `/faqs`
- **Componentes:**
  - `FaqsCard` - Cards de categorias FAQ
  - `Questions` - Acordeon de preguntas/respuestas
  - `ProductsVideo` - Seccion video
- **Ideal para:** Seccion de ayuda, base de conocimiento

#### 39. PRICING
- **Ruta:** `/pricing`
- **Componentes:**
  - `PricingCard` - Cards de planes vertical
  - `HorizontalPricing` - Tabla comparativa horizontal
- **Ideal para:** Planes/niveles de servicio (si aplica)

#### 40. STARTER
- **Ruta:** `/starter`
- **Descripcion:** Pagina vacia con solo breadcrumb y card vacia. Punto de partida para nuevas paginas.
- **Ideal para:** Plantilla base para cualquier pagina nueva

#### 41. TIMELINE
- **Ruta:** `/timeline`
- **Descripcion:** 6 variantes de timeline: Circle, Square, Progress, Outline, Avatar, Icon
- **Ideal para:** Seguimiento de pedidos, trazabilidad, historial de estados de venta/orden

---

### H. DEMOS DE LAYOUT (9 paginas)

Todas en: `src/app/(admin)/(layouts)/`

| # | Ruta | Componente | Que hace |
|---|------|------------|----------|
| 42 | `/dark-mode` | `DarkMode` | Fuerza tema oscuro |
| 43 | `/rtl-mode` | `RtlMode` | Fuerza direccion RTL |
| 44 | `/sidenav-compact` | `SideCompact` | Sidebar solo iconos |
| 45 | `/sidenav-dark` | `SideDark` | Sidebar oscuro |
| 46 | `/sidenav-hidden` | `SideHidden` | Sidebar oculto |
| 47 | `/sidenav-hover` | `SidenavHover` | Sidebar colapsa, expande al hover |
| 48 | `/sidenav-hover-active` | `SidenavHoverActive` | Hover con toggle pin |
| 49 | `/sidenav-offcanvas` | `SideOffcanvase` | Sidebar offcanvas (movil) |
| 50 | `/sidenav-small` | `SmallNav` | Sidebar mini |

Cada uno usa `useLayoutContext().updateSettings()` en useEffect para aplicar la config.

**Ideal para:** Referencia de configuracion. No se usan como paginas reales.

---

### I. AUTH PAGES (28 paginas, 4 estilos x 7 flujos)

Todas en: `src/app/(auth)/`

#### Estilos disponibles:

| Estilo | Descripcion visual | Archivos |
|--------|-------------------|----------|
| **Basic** | Card centrada sobre fondo grid sutil | `basic-login/`, `basic-register/`, `basic-create-password/`, `basic-reset-password/`, `basic-verify-email/`, `basic-logout/`, `basic-two-steps/` |
| **Cover** | Imagen full-screen de fondo con card frosted-glass | `cover-login/`, `cover-register/`, `cover-create-password/`, `cover-reset-password/`, `cover-verify-email/`, `cover-logout/`, `cover-two-steps/` |
| **Boxed** | Dos columnas: form izq + ilustracion der | `boxed-login/`, `boxed-register/`, `boxed-create-password/`, `boxed-reset-password/`, `boxed-logout/`, `boxed-two-steps/` |
| **Modern** | Gradiente azul oscuro + SVG overlay, tabs email/phone | `modern-login/`, `modern-register/`, `modern-create-password/`, `modern-reset-password/`, `modern-verify-email/`, `modern-logout/`, `modern-two-steps/` |

#### Flujos disponibles en cada estilo:

| Flujo | Que hace |
|-------|----------|
| Login | Formulario email + password + social login (Google, Apple) |
| Register | Formulario registro con nombre, email, password |
| Create Password | Crear nueva contrasena |
| Reset Password | Solicitar reset de contrasena |
| Verify Email | Verificar email con codigo |
| Logout | Confirmacion de cierre de sesion |
| Two Steps | Verificacion en dos pasos |

**Elementos comunes:** Logo (light/dark), botones social login (Google, Apple) via IconifyIcon, links entre flujos, PageMeta.

**Ideal para:** Ya se usa Modern Login customizado en JSoluciones. Las demas sirven para register, reset-password, etc.

---

### J. LANDING PAGES (2 paginas)

Todas en: `src/app/(landing)/`

#### 51. PRODUCT LANDING
- **Ruta:** `/product-landing`
- **Componentes:** `Navbar`, `Hero`, `Product`, `Features`, `About`, `Customer`, `Cta`, `Footer`, `MobileMenu`
- **Ideal para:** Pagina de presentacion del producto/servicio

#### 52. ONEPAGE LANDING
- **Ruta:** `/onepage-landing`
- **Componentes:** `Navbar`, `Hero`, `Feature`, `Works`, `About`, `Pricing`, `Contact`, `Footer`, `MobileMenu`
- **Ideal para:** Landing page single-scroll

---

### K. PAGINAS DE ERROR/ESTADO (4 paginas)

Todas en: `src/app/(others)/`

#### 53. 404 NOT FOUND
- **Ruta:** `/404`
- **Descripcion:** Ilustracion 404, mensaje, boton "Back to Home"

#### 54. COMING SOON
- **Ruta:** `/coming-soon`
- **Componentes:** `CommingSoon` - Timer countdown
- **Ideal para:** Modulos aun no implementados

#### 55. MAINTENANCE
- **Ruta:** `/maintenance`
- **Descripcion:** Ilustracion mantenimiento, boton volver

#### 56. OFFLINE
- **Ruta:** `/offline`
- **Descripcion:** Ilustracion sin conexion, boton refresh

---

## COMPONENTES COMPARTIDOS (CORE)

Estos se usan en multiples paginas y son los mas importantes:

| Componente | Archivo | Que hace | Donde se usa |
|------------|---------|----------|--------------|
| `PageWrapper` | `components/PageWrapper.tsx` | Shell admin (Sidebar+Topbar+Footer+Customizer) | Todas las rutas admin |
| `PageBreadcrumb` | `components/PageBreadcrumb.tsx` | Breadcrumb con titulo | Todas las paginas admin |
| `PageMeta` | `components/PageMeta.tsx` | Tag `<title>` | Todas las paginas |
| `ProvidersWrapper` | `components/ProvidersWrapper.tsx` | Context providers + Preline init | App root |
| `ApexChartClient` | `components/client-wrapper/ApexChartClient.tsx` | Chart wrapper memoizado | Todos los dashboards |
| `SimplebarClient` | `components/client-wrapper/SimplebarClient.tsx` | Custom scrollbar | Sidebar, topbar dropdowns |
| `IconifyIcon` | `components/client-wrapper/IconifyIcon.tsx` | Iconos Iconify | Auth pages, topbar |

---

## CONTEXT Y HOOKS

| Hook/Context | Archivo | Que maneja |
|-------------|---------|------------|
| `useLayoutContext` | `context/useLayoutContext.tsx` | Tema (light/dark/system), sidebar (7 modos), color sidebar (light/dark), direccion (ltr/rtl). Persiste en localStorage. |
| `LayoutProvider` | `context/useLayoutContext.tsx` | Provider que wrappea la app. Responde a resize: <=768px->offcanvas, <=1140px->sm, else default |

---

## UTILIDADES Y HELPERS

| Funcion | Archivo | Que hace |
|---------|---------|----------|
| `twColor(cssVar)` | `utils/colors.ts` | Lee variable CSS de Tailwind del DOM |
| `colors` | `utils/colors.ts` | Objeto con getters lazy para primary, success, danger, gray |
| `toggleAttribute` | `utils/layout.ts` | Set/remove atributos en elementos HTML |
| `toggleClassName` | `utils/layout.ts` | Toggle clases CSS |
| `getSystemTheme` | `utils/layout.ts` | Detecta preferencia dark mode del OS |
| `showBackdrop` | `utils/layout.ts` | Muestra overlay backdrop (sidebar movil) |
| `hideBackdrop` | `utils/layout.ts` | Oculta overlay backdrop |
| `debounce` | `helpers/debounce.ts` | Debounce generico |
| `appName` | `helpers/constants.ts` | "Tailwick" (cambiar a JSoluciones) |
| `currency` | `helpers/constants.ts` | "$" (cambiar a "S/") |
| `colorVariants` | `helpers/constants.ts` | Array de 12 nombres de color Tailwind |
| `currentYear` | `helpers/constants.ts` | Ano actual dinamico |

---

## ASSETS (IMAGENES)

| Carpeta | Contenido | Cantidad |
|---------|-----------|----------|
| `assets/user/` | Avatares (avatar-1 a 11.png, user-1 a 4.jpg, profile, dummy, multi) | 18 |
| `assets/small/` | Thumbnails (img-1 a 12.jpg) | 12 |
| `assets/product/` | Imagenes de productos + overview + CTA + fondo | 19+ |
| `assets/payment/` | Metodos de pago (visa, mastercard, etc) | 4 |
| `assets/brand/` | Logos de marcas (twitter, gmail, slack, figma, etc) | 12 |
| `assets/flags/` | Banderas paises (US, ES, DE, FR, JP, IT, RU, SA) | 8 |
| `assets/landing/` | Imagenes para landing pages | 2 |
| `assets/` (raiz) | Logos (sm, light, dark), fondos auth, 404, offline, maintenance, etc | 20+ |

---

## INDICE RAPIDO: QUE COMPONENTE USAR PARA CADA NECESIDAD

### Tablas/Listados
| Necesidad | Mejor componente template | Ruta archivo |
|-----------|--------------------------|--------------|
| Tabla con checkboxes + acciones | Product List | `(ecommerce)/product-list/components/ProductList.tsx` |
| Tabla con badges de estado | Orders | `(ecommerce)/orders/components/OrderDetailTable.tsx` |
| Tabla con modal editar | Employee | `(hr)/employee/components/` |
| Tabla de pagos/cobros | Sales Payments | `(hr)/sales-payments/components/Payments.tsx` |
| Tabla de estimados/cotizaciones | Sales Estimates | `(hr)/sales-estimates/components/Estimates.tsx` |
| Tabla con sidebar preview | Invoice List | `(invoice)/list/components/` |
| Tabla de usuarios | Users List | `(users)/users-list/components/UserListTabel.tsx` |

### Formularios
| Necesidad | Mejor componente template | Ruta archivo |
|-----------|--------------------------|--------------|
| Form crear producto | Product Create | `(ecommerce)/product-create/components/ProductCreat.tsx` |
| Form con tabla items editable | Add Invoice | `(invoice)/add-new/components/AddNew.tsx` |
| Form simple | Create Leave | `(hr)/create-leave/components/CreateLeave.tsx` |
| Form checkout/facturacion | Checkout | `(ecommerce)/checkout/components/ShoppingInformation.tsx` |

### Dashboards/KPIs
| Necesidad | Mejor componente template | Ruta archivo |
|-----------|--------------------------|--------------|
| KPI cards + charts ventas | Ecommerce Dashboard | `(dashboards)/index/components/` |
| Sparkline mini charts | Email Dashboard | `(dashboards)/email/components/` |
| Stats cards con radiales | HR Dashboard | `(dashboards)/hr/components/Activities.tsx` |

### Detalle/Vista individual
| Necesidad | Mejor componente template | Ruta archivo |
|-----------|--------------------------|--------------|
| Detalle de orden/venta | Order Overview | `(ecommerce)/order-overview/components/` |
| Detalle de producto | Product Overview | `(ecommerce)/product-overview/components/` |
| Vista factura imprimible | Invoice Overview | `(invoice)/overview/index.tsx` |
| Recibo imprimible | Payslip | `(hr)/payroll-payslip/index.tsx` |

### Modales
| Necesidad | Mejor componente template | Ruta archivo |
|-----------|--------------------------|--------------|
| Modal con formulario | Sellers Modal | `(ecommerce)/sellers/components/Modal.tsx` |
| Modal confirmar eliminacion | Employee Delete | `(hr)/employee/components/EmployeeDelete.tsx` |
| Modal agregar entidad | Add Department | `(hr)/department/components/AddDepartment.tsx` |
| Modal evento calendario | Event Modal | `(app)/calendar/components/EventModal.tsx` |

### Layouts especiales
| Necesidad | Mejor componente template | Ruta archivo |
|-----------|--------------------------|--------------|
| Grid cards de entidades | Users Grid | `(users)/users-grid/components/UserGrid.tsx` |
| Grid productos seleccion | Product Grid | `(ecommerce)/product-grid/components/Products.tsx` |
| Cards + tabla abajo | Leave Manage | `(hr)/leave/components/` |
| Sidebar + contenido | Chat | `(app)/chat/components/` |
| Timeline/seguimiento | Timeline page | `(pages)/timeline/index.tsx` |
| Calendario eventos | Calendar | `(app)/calendar/components/` |

### Auth
| Necesidad | Mejor estilo | Ruta archivo |
|-----------|-------------|--------------|
| Login moderno | Modern Login | `(auth)/modern-login/index.tsx` |
| Register | Modern Register | `(auth)/modern-register/index.tsx` |
| Reset password | Modern Reset | `(auth)/modern-reset-password/index.tsx` |
| Verificar email | Modern Verify | `(auth)/modern-verify-email/index.tsx` |
| Two-step auth | Modern Two Steps | `(auth)/modern-two-steps/index.tsx` |

### Paginas estado
| Necesidad | Componente | Ruta archivo |
|-----------|-----------|--------------|
| 404 | PageNotFound | `(others)/404/index.tsx` |
| En construccion | CommingSoon | `(others)/coming-soon/index.tsx` |
| Mantenimiento | Maintenance | `(others)/maintenance/index.tsx` |

---

## NOTAS PARA EL AGENTE

1. **Todas las rutas base** son relativas a: `React-TS/src/app/`
2. **Los componentes de cada pagina** estan en subcarpeta `components/` dentro de cada pagina
3. **Los datos mock/chart options** estan en `data.ts` dentro de cada pagina de dashboard
4. **Al copiar un componente a Jsoluciones-fe**, cambiar:
   - Imports de imagenes (assets) -> usar las del proyecto o nuevas
   - Datos mock -> conectar con hooks de Orval/react-query
   - `appName` en constants -> "JSoluciones"
   - `currency` -> "S/" (soles peruanos)
5. **Preline JS** necesita inicializarse: ya se hace en `ProvidersWrapper.tsx` con `HSStaticMethods.autoInit()`
6. **ApexCharts** usa `twColor()` para leer colores de CSS vars de Tailwind
7. **El layout admin** (Sidebar+Topbar+Footer) ya esta funcional en Jsoluciones-fe, no copiar de nuevo
