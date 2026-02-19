# JSOLUCIONES ERP — MAPA DEL TEMPLATE TAILWICK

> Este archivo define QUÉ del template Tailwick se usa, qué se desactiva para después,
> y qué se ignora. Es la guía para el agente de frontend.
>
> ⚠️ DATO IMPORTANTE: El template usa **TypeScript** (React 19 + TS 5.8 + Vite 7).
> Todos los archivos del proyecto serán `.tsx` / `.ts`, NO `.jsx` / `.js`.

---

## 1. STACK REAL DEL TEMPLATE (Actualización)

| Tecnología | Versión en Tailwick | Nota |
|-----------|-------------------|------|
| **React** | 19.1.0 | ✅ Última versión |
| **TypeScript** | 5.8.3 | ✅ Modo estricto activado |
| **Vite** | 7.1.7 | ✅ Build tool |
| **Tailwind CSS** | v4.1.13 | ✅ Última v4 |
| **Preline UI** | 3.2.3 | ✅ Componentes UI pre-construidos |
| **React Router** | 7.9.1 | ✅ Navegación |
| **react-apexcharts** | — | ✅ Gráficos (dashboards) |
| **FullCalendar** | 6.1.19 | ⏸ Desactivar (futuro: distribución) |
| **lucide-react** | — | ✅ Iconos principales |
| **react-icons** | — | ✅ Iconos complementarios |
| **@iconify/react** | — | ✅ Iconos extra |
| **flatpickr** | — | ✅ Date pickers |
| **Swiper** | 12.0.1 | ❌ No necesario (carruseles) |
| **simplebar-react** | — | ✅ Scrollbar custom |
| **usehooks-ts** | 3.1.1 | ✅ Hooks útiles |

### Paquetes a AGREGAR al template:

```bash
# Data fetching y estado
pnpm add @tanstack/react-query axios zustand

# Formularios y validación
pnpm add react-hook-form zod @hookform/resolvers

# Notificaciones
pnpm add react-hot-toast

# Fechas
pnpm add dayjs

# Offline (POS)
pnpm add idb

# DevTools (solo desarrollo)
pnpm add -D @tanstack/react-query-devtools
```

### Paquetes que YA TIENE y se reutilizan:

```
react-apexcharts    → Dashboard KPIs y gráficos
lucide-react        → Iconos del sidebar y botones
flatpickr           → Date pickers en formularios
simplebar-react     → Scrollbar en sidebar y tablas largas
usehooks-ts         → useDebounce, useLocalStorage, etc.
```

---

## 2. CORRECCIÓN: TypeScript, no JavaScript

Los archivos de reglas anteriores (04_REGLAS_FRONTEND_v2, 08_PROCESOS_FRONTEND) mostraban archivos `.jsx` y `.js`. Con Tailwick, todo es `.tsx` y `.ts`.

```
ANTES (en los docs):              AHORA (con Tailwick real):
─────────────────                 ────────────────────────
VentasListPage.jsx       →        VentasListPage.tsx
ventasService.js         →        ventasService.ts
useVentas.js             →        useVentas.ts
api.js                   →        api.ts
formatters.js            →        formatters.ts
AppRoutes.jsx            →        AppRoutes.tsx (ya existe en template)
ProtectedRoute.jsx       →        ProtectedRoute.tsx
AuthContext.jsx           →        AuthContext.tsx
```

Todo lo demás (patrones, hooks, services, reglas) sigue igual. Solo cambia la extensión.

---

## 3. ESTRUCTURA ACTUAL DEL TEMPLATE vs LO QUE NECESITAMOS

### 3.1 Rutas del template — Clasificación

```
✅ = USAR AHORA (adaptar para el ERP)
⏸ = DESACTIVAR (no borrar, solo quitar del routing hasta que se necesite)
❌ = IGNORAR (no se usa en el ERP, no registrar en rutas)
```

### DASHBOARDS

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/` o `/index` (Ecommerce Dashboard) | ✅ USAR | **Dashboard principal del ERP** — adaptar KPIs a ventas, stock, cuentas |
| `/analytics` | ⏸ DESACTIVAR | Futuro: Dashboard ejecutivo/gerencial con analytics avanzados |
| `/email` | ❌ IGNORAR | No aplica al ERP |
| `/hr` | ❌ IGNORAR | No hay módulo de RRHH en el ERP |

### ECOMMERCE (9 páginas)

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/product-list` | ✅ USAR | **Lista de productos** → `/inventario/productos` |
| `/product-grid` | ⏸ DESACTIVAR | Futuro: Vista grid de productos en el POS |
| `/product-overview` | ✅ USAR | **Detalle de producto** → `/inventario/productos/:id` |
| `/product-create` | ✅ USAR | **Crear/editar producto** → `/inventario/productos/crear` |
| `/cart` | ✅ USAR | **Adaptar como carrito del POS** → `/ventas/pos` (panel derecho) |
| `/checkout` | ⏸ DESACTIVAR | Futuro: Checkout si hay venta online |
| `/orders` | ✅ USAR | **Lista de ventas/órdenes** → `/ventas` |
| `/order-overview` | ✅ USAR | **Detalle de venta** → `/ventas/:id` |
| `/sellers` | ⏸ DESACTIVAR | Futuro: Vista de rendimiento de vendedores |

### HR (15 páginas)

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/employee` | ❌ IGNORAR | No hay módulo RRHH |
| `/holidays` | ❌ IGNORAR | — |
| `/attendance` | ❌ IGNORAR | — |
| `/attendance-main` | ❌ IGNORAR | — |
| `/department` | ❌ IGNORAR | — |
| `/leave-employee` | ❌ IGNORAR | — |
| `/create-leave-employee` | ❌ IGNORAR | — |
| `/leave` | ❌ IGNORAR | — |
| `/create-leave` | ❌ IGNORAR | — |
| `/sales-estimates` | ✅ USAR | **Adaptar como Cotizaciones** → `/ventas/cotizaciones` |
| `/sales-payments` | ✅ USAR | **Adaptar como Cobros/Pagos** → `/finanzas/cobros` |
| `/sales-expenses` | ⏸ DESACTIVAR | Futuro: Gastos en finanzas |
| `/payroll-employee-salary` | ❌ IGNORAR | — |
| `/payroll-payslip` | ❌ IGNORAR | — |
| `/create-payslip` | ❌ IGNORAR | — |

### INVOICE (3 páginas)

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/overview` (Invoice overview) | ✅ USAR | **Dashboard de facturación** → `/facturacion` |
| `/list` (Invoice list) | ✅ USAR | **Lista de comprobantes** → `/facturacion/comprobantes` |
| `/add-new` (Add invoice) | ✅ USAR | **Previsualización de comprobante** → referencia para diseño |

### USERS (2 páginas)

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/users-list` | ✅ USAR | **Gestión de usuarios** → `/configuracion/usuarios` |
| `/users-grid` | ⏸ DESACTIVAR | Futuro: Vista alternativa de usuarios |

### APPS (4 páginas)

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/chat` | ⏸ DESACTIVAR | Futuro: Posible integración con WhatsApp |
| `/calendar` | ⏸ DESACTIVAR | Futuro: Calendario de entregas/distribución |
| `/mailbox` | ❌ IGNORAR | No aplica |
| `/notes` | ❌ IGNORAR | No aplica |

### AUTH (28 páginas = 4 estilos × 7 funciones)

| Estilo | Estado | Uso en JSoluciones |
|--------|--------|-------------------|
| **Modern** (login, register, etc.) | ✅ USAR | **Estilo elegido para el ERP** |
| Basic | ❌ IGNORAR | No se usa |
| Boxed | ❌ IGNORAR | No se usa |
| Cover | ❌ IGNORAR | No se usa |

Páginas auth que se usan (solo estilo Modern):

| Página | Estado | Ruta ERP |
|--------|--------|---------|
| `/modern-login` | ✅ USAR | `/login` |
| `/modern-register` | ⏸ DESACTIVAR | Futuro: Registro de nuevas empresas |
| `/modern-verify-email` | ⏸ DESACTIVAR | Futuro: Verificación de email |
| `/modern-two-step` | ⏸ DESACTIVAR | Futuro: 2FA |
| `/modern-logout` | ✅ USAR | `/logout` |
| `/modern-reset-password` | ⏸ DESACTIVAR | Futuro: Recuperar contraseña |
| `/modern-create-password` | ⏸ DESACTIVAR | Futuro: Crear contraseña |

### LAYOUTS (9 variantes)

| Variante | Estado | Uso en JSoluciones |
|----------|--------|-------------------|
| Default (sidebar normal) | ✅ USAR | **Layout principal del ERP** |
| `/sidenav-hover` | ⏸ DESACTIVAR | Opción futura de UI |
| `/sidenav-hover-active` | ⏸ DESACTIVAR | — |
| `/sidenav-small` | ⏸ DESACTIVAR | — |
| `/sidenav-compact` | ⏸ DESACTIVAR | — |
| `/sidenav-offcanvas` | ✅ AUTO | Tailwick ya lo usa en móvil automáticamente |
| `/sidenav-hidden` | ⏸ DESACTIVAR | — |
| `/sidenav-dark` | ⏸ DESACTIVAR | Opción futura (tema oscuro) |
| `/dark-mode` | ⏸ DESACTIVAR | Opción futura |
| `/rtl-mode` | ❌ IGNORAR | No se necesita (español es LTR) |

### PAGES EXTRAS

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/starter` | ✅ USAR | **Referencia para crear páginas nuevas** (estructura base) |
| `/pricing` | ⏸ DESACTIVAR | Futuro: Página de planes SaaS |
| `/faqs` | ❌ IGNORAR | — |
| `/timeline` | ✅ USAR | **Adaptar para seguimiento de pedidos** → `/distribucion/pedido/:id` |

### LANDING

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/onepage-landing` | ⏸ DESACTIVAR | Futuro: Landing page del SaaS |
| `/product-landing` | ❌ IGNORAR | — |

### OTHERS (Páginas especiales)

| Ruta template | Estado | Uso en JSoluciones |
|--------------|--------|-------------------|
| `/404` | ✅ USAR | **Página 404** |
| `/coming-soon` | ✅ USAR | **Para módulos no implementados aún** |
| `/maintenance` | ✅ USAR | **Para mantenimiento programado** |
| `/offline` | ✅ USAR | **Para modo offline del POS** |

---

## 4. RESUMEN NUMÉRICO

| Categoría | Total en template | ✅ Usar ahora | ⏸ Desactivar | ❌ Ignorar |
|-----------|:-:|:-:|:-:|:-:|
| Dashboards | 4 | 1 | 1 | 2 |
| Ecommerce | 9 | 6 | 3 | 0 |
| HR | 15 | 2 | 1 | 12 |
| Invoice | 3 | 3 | 0 | 0 |
| Users | 2 | 1 | 1 | 0 |
| Apps | 4 | 0 | 2 | 2 |
| Auth | 28 | 2 | 5 | 21 |
| Layouts | 9 | 2 | 6 | 1 |
| Pages extras | 4 | 1 | 1 | 2 |
| Landing | 2 | 0 | 1 | 1 |
| Others | 4 | 4 | 0 | 0 |
| **TOTAL** | **84** | **22** | **21** | **41** |

**22 páginas se usan, 21 se desactivan (para futuro), 41 se ignoran.**

---

## 5. CÓMO DESACTIVAR SIN BORRAR

### 5.1 En el archivo de rutas

```typescript
// src/routes/index.tsx

// ✅ RUTAS ACTIVAS — ERP JSoluciones
const erpRoutes: RouteProps[] = [
  // Dashboard
  { path: '/dashboard', element: lazy(() => import('@/app/(admin)/(dashboards)/index')) },

  // Inventario (adaptado de ecommerce)
  { path: '/inventario/productos', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-list')) },
  { path: '/inventario/productos/crear', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-create')) },
  { path: '/inventario/productos/:id', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-overview')) },

  // Ventas
  { path: '/ventas', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/orders')) },
  { path: '/ventas/:id', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/order-overview')) },
  { path: '/ventas/pos', element: lazy(() => import('@/pages/ventas/POSPage')) },
  { path: '/ventas/cotizaciones', element: lazy(() => import('@/app/(admin)/(app)/(hr)/sales-estimates')) },

  // Facturación
  { path: '/facturacion', element: lazy(() => import('@/app/(admin)/(app)/(invoice)/overview')) },
  { path: '/facturacion/comprobantes', element: lazy(() => import('@/app/(admin)/(app)/(invoice)/list')) },

  // Usuarios
  { path: '/configuracion/usuarios', element: lazy(() => import('@/app/(admin)/(app)/(users)/users-list')) },

  // Páginas especiales
  { path: '/coming-soon', element: lazy(() => import('@/app/(others)/coming-soon')) },
];

// ⏸ RUTAS DESACTIVADAS — Disponibles para activar en el futuro
// Descomentarlas cuando se necesiten
/*
const futureRoutes: RouteProps[] = [
  { path: '/analytics', element: lazy(() => import('@/app/(admin)/(dashboards)/analytics')) },
  { path: '/inventario/productos-grid', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/product-grid')) },
  { path: '/checkout', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/checkout')) },
  { path: '/rendimiento-vendedores', element: lazy(() => import('@/app/(admin)/(app)/(ecommerce)/sellers')) },
  { path: '/chat', element: lazy(() => import('@/app/(admin)/(app)/chat')) },
  { path: '/calendario', element: lazy(() => import('@/app/(admin)/(app)/calendar')) },
  { path: '/planes', element: lazy(() => import('@/app/(admin)/(pages)/pricing')) },
  { path: '/landing', element: lazy(() => import('@/app/(landing)/onepage-landing')) },
];
*/

// ❌ RUTAS IGNORADAS — NO registrar en ningún lado
// HR completo (employee, holidays, attendance, department, leave, payroll)
// Auth: basic-*, boxed-*, cover-* (solo se usa modern-*)
// Apps: mailbox, notes
// Landing: product-landing
// Pages: faqs
// Layouts: rtl-mode
```

### 5.2 En el sidebar/menú

```typescript
// src/components/layouts/SideNav/menu.ts
// SOLO definir los items que están activos en el ERP

import {
  LayoutDashboard, ShoppingCart, Package, Users, FileText,
  Truck, DollarSign, Settings, BarChart3, MessageSquare
} from 'lucide-react';

export type MenuItem = {
  key: string;
  label: string;
  icon: any;
  url?: string;
  children?: MenuItem[];
  permiso?: string;       // Permiso requerido para ver este item
  badge?: string;          // Badge opcional (ej: "Nuevo")
};

export const menuItems: MenuItem[] = [
  {
    key: 'dashboard',
    label: 'Dashboard',
    icon: LayoutDashboard,
    url: '/dashboard',
    // Sin permiso = visible para todos
  },
  {
    key: 'ventas',
    label: 'Ventas',
    icon: ShoppingCart,
    permiso: 'ventas.ver',
    children: [
      { key: 'ventas-pos', label: 'Punto de Venta', url: '/ventas/pos', permiso: 'ventas.pos' },
      { key: 'ventas-lista', label: 'Ventas', url: '/ventas', permiso: 'ventas.ver' },
      { key: 'cotizaciones', label: 'Cotizaciones', url: '/ventas/cotizaciones', permiso: 'ventas.cotizaciones' },
      { key: 'ordenes', label: 'Órdenes de Venta', url: '/ventas/ordenes', permiso: 'ventas.ver' },
    ],
  },
  {
    key: 'inventario',
    label: 'Inventario',
    icon: Package,
    permiso: 'inventario.ver',
    children: [
      { key: 'productos', label: 'Productos', url: '/inventario/productos', permiso: 'inventario.ver' },
      { key: 'categorias', label: 'Categorías', url: '/inventario/categorias', permiso: 'inventario.ver' },
      { key: 'almacenes', label: 'Almacenes', url: '/inventario/almacenes', permiso: 'inventario.ver' },
      { key: 'movimientos', label: 'Movimientos', url: '/inventario/movimientos', permiso: 'inventario.ver' },
    ],
  },
  {
    key: 'clientes',
    label: 'Clientes',
    icon: Users,
    url: '/clientes',
    permiso: 'clientes.ver',
  },
  {
    key: 'facturacion',
    label: 'Facturación',
    icon: FileText,
    permiso: 'facturacion.ver',
    children: [
      { key: 'comprobantes', label: 'Comprobantes', url: '/facturacion/comprobantes', permiso: 'facturacion.ver' },
      { key: 'notas-credito', label: 'Notas de Crédito', url: '/facturacion/notas-credito', permiso: 'facturacion.nota_credito' },
    ],
  },
  // ⏸ DESACTIVADOS (descomentar cuando se desarrolle el módulo)
  /*
  {
    key: 'proveedores',
    label: 'Proveedores',
    icon: Truck,
    url: '/proveedores',
    permiso: 'proveedores.ver',
  },
  {
    key: 'compras',
    label: 'Compras',
    icon: ShoppingBag,
    permiso: 'compras.ver',
    children: [
      { key: 'ordenes-compra', label: 'Órdenes de Compra', url: '/compras/ordenes' },
      { key: 'recepciones', label: 'Recepciones', url: '/compras/recepciones' },
    ],
  },
  {
    key: 'finanzas',
    label: 'Finanzas',
    icon: DollarSign,
    permiso: 'finanzas.ver',
    children: [
      { key: 'cobros', label: 'Cuentas por Cobrar', url: '/finanzas/cobros' },
      { key: 'pagos', label: 'Cuentas por Pagar', url: '/finanzas/pagos' },
      { key: 'asientos', label: 'Asientos Contables', url: '/finanzas/asientos' },
    ],
  },
  {
    key: 'distribucion',
    label: 'Distribución',
    icon: Truck,
    permiso: 'distribucion.ver',
    children: [
      { key: 'pedidos', label: 'Pedidos', url: '/distribucion/pedidos' },
      { key: 'rutas', label: 'Rutas', url: '/distribucion/rutas' },
    ],
  },
  {
    key: 'whatsapp',
    label: 'WhatsApp',
    icon: MessageSquare,
    permiso: 'whatsapp.ver',
    badge: 'Nuevo',
  },
  {
    key: 'reportes',
    label: 'Reportes',
    icon: BarChart3,
    permiso: 'reportes.ver',
    children: [
      { key: 'reporte-ventas', label: 'Ventas', url: '/reportes/ventas' },
      { key: 'reporte-inventario', label: 'Inventario', url: '/reportes/inventario' },
      { key: 'reporte-tributario', label: 'Tributarios', url: '/reportes/tributarios' },
    ],
  },
  */
  {
    key: 'configuracion',
    label: 'Configuración',
    icon: Settings,
    permiso: 'usuarios.ver', // Solo admin
    children: [
      { key: 'usuarios', label: 'Usuarios', url: '/configuracion/usuarios' },
      { key: 'roles', label: 'Roles y Permisos', url: '/configuracion/roles' },
      { key: 'empresa', label: 'Datos de Empresa', url: '/configuracion/empresa' },
      { key: 'series', label: 'Series de Comprobantes', url: '/configuracion/series' },
    ],
  },
];
```

---

## 6. COMPONENTES DEL TEMPLATE QUE SE REUTILIZAN

### 6.1 Layout (se usa completo)

```
✅ components/layouts/topbar/           → Topbar del ERP (adaptar contenido)
✅ components/layouts/SideNav/          → Sidebar (reemplazar menu.ts con menuItems ERP)
✅ components/layouts/Footer.tsx        → Footer
✅ components/layouts/customizer/       → ⏸ Desactivar (no mostrar al usuario por ahora)
✅ context/useLayoutContext.tsx         → Se reutiliza el context de layout tal cual
```

### 6.2 Componentes de páginas que se adaptan

```
✅ Ecommerce product-list      → Tabla de productos (adaptar columnas)
✅ Ecommerce product-create    → Formulario de producto (adaptar campos)
✅ Ecommerce product-overview  → Detalle de producto (adaptar info)
✅ Ecommerce orders            → Tabla de ventas/órdenes
✅ Ecommerce order-overview    → Detalle de venta
✅ Ecommerce cart              → Panel del POS (carrito de venta)
✅ Invoice list                → Tabla de comprobantes
✅ Invoice overview            → Dashboard de facturación
✅ Invoice add-new             → Referencia de diseño para comprobante
✅ Users list                  → Tabla de usuarios
✅ HR sales-estimates          → Tabla de cotizaciones
✅ HR sales-payments           → Tabla de cobros/pagos
✅ Dashboard ecommerce         → Dashboard principal (adaptar KPIs)
✅ Timeline                    → Seguimiento de pedidos
✅ 404, coming-soon, offline   → Páginas de error/estado
```

### 6.3 Componentes wrapper (se mantienen)

```
✅ client-wrapper/ApexChartClient.tsx    → Para gráficos del dashboard
✅ client-wrapper/IconifyIcon.tsx        → Para iconos extra
✅ client-wrapper/SimplebarClient.tsx    → Para scrollbar
```

### 6.4 Preline UI — Se sigue usando

El template usa Preline UI para componentes interactivos (dropdowns, modales, tabs, accordions, etc.). Se mantiene tal cual, la auto-inicialización en cada cambio de ruta ya está implementada.

```typescript
// Ya implementado en el template — NO tocar
useEffect(() => {
  import('preline/preline').then(() => {
    window.HSStaticMethods.autoInit();
  });
}, [path]);
```

---

## 7. CARPETAS A AGREGAR AL TEMPLATE

El template actual no tiene estas carpetas. Se crean nuevas:

```
src/
├── app/                          # ← Ya existe (páginas del template)
├── pages/                        # ✨ NUEVO: Páginas custom del ERP
│   ├── ventas/
│   │   └── POSPage.tsx           # POS es 100% custom
│   ├── distribucion/
│   │   └── SeguimientoPedido.tsx # Seguimiento es custom
│   └── ...
├── services/                     # ✨ NUEVO: API layer
│   ├── api.ts
│   ├── authService.ts
│   ├── ventasService.ts
│   ├── inventarioService.ts
│   └── ...
├── hooks/                        # ✨ NUEVO: TanStack Query hooks
│   ├── useAuth.ts
│   ├── useVentas.ts
│   ├── useProductos.ts
│   └── ...
├── stores/                       # ✨ NUEVO: Zustand stores
│   └── useAppStore.ts
├── config/                       # ✨ NUEVO: Configuración
│   ├── env.ts
│   └── constants.ts
├── components/
│   ├── layouts/                  # ← Ya existe (NO tocar)
│   ├── client-wrapper/           # ← Ya existe (NO tocar)
│   ├── common/                   # ✨ NUEVO: Componentes reutilizables ERP
│   │   ├── ErrorBoundary.tsx
│   │   ├── ProtectedRoute.tsx
│   │   ├── DataTable.tsx
│   │   ├── ConfirmModal.tsx
│   │   ├── ErrorMessage.tsx
│   │   ├── EmptyState.tsx
│   │   ├── TableSkeleton.tsx
│   │   └── Badge.tsx
│   └── modules/                  # ✨ NUEVO: Componentes por módulo ERP
│       ├── ventas/
│       ├── inventario/
│       ├── facturacion/
│       └── ...
├── context/
│   ├── useLayoutContext.tsx       # ← Ya existe (NO tocar)
│   ├── AuthContext.tsx            # ✨ NUEVO
│   └── NotificationContext.tsx    # ✨ NUEVO
└── types/                        # ← Ya existe
    ├── ... (tipos del template)
    └── erp/                      # ✨ NUEVO: Tipos del ERP
        ├── venta.ts
        ├── producto.ts
        ├── cliente.ts
        └── ...
```

---

## 8. CONFIGURACIÓN DEL TEMPLATE QUE NO SE TOCA

```
❌ NO TOCAR:
  - tailwind.config.ts          → Ya está bien configurado
  - vite.config.ts              → Solo agregar alias si hace falta
  - tsconfig.json               → Ya tiene modo estricto y alias @/
  - eslint.config.js            → Solo agregar reglas, no quitar
  - src/assets/css/style.css    → Solo agregar imports si hay nuevas libs
  - components/layouts/*        → Solo adaptar contenido, no estructura
  - context/useLayoutContext.tsx → Se reutiliza tal cual

✅ SÍ MODIFICAR:
  - src/routes/index.tsx         → Reemplazar rutas del template con rutas ERP
  - src/App.tsx                  → Agregar providers (QueryClient, Auth, Notifications)
  - components/layouts/SideNav/menu.ts → Reemplazar menú con items del ERP
  - package.json                 → Agregar dependencias nuevas
```

---

## 9. INSTRUCCIONES PARA EL AGENTE DE FRONTEND

```
INSTRUCCIÓN 1: Lee este archivo COMPLETO antes de tocar cualquier código.

INSTRUCCIÓN 2: El template ya tiene un sistema de layout funcional.
               NO lo recrees. Solo adapta el contenido (menú, rutas).

INSTRUCCIÓN 3: Las páginas del template que se marcan como ✅ USAR
               se ADAPTAN, no se reescriben. Cambia columnas, campos,
               textos y conexiones a API, pero mantén la estructura visual.

INSTRUCCIÓN 4: Para páginas 100% custom (POS, seguimiento),
               créalas en src/pages/ siguiendo el patrón de las páginas
               existentes del template (PageMeta, PageBreadcrumb, grid layout).

INSTRUCCIÓN 5: Todo archivo nuevo es .tsx o .ts (TypeScript).

INSTRUCCIÓN 6: Usa los iconos de lucide-react que ya están instalados.

INSTRUCCIÓN 7: Los gráficos usan react-apexcharts (ya instalado).

INSTRUCCIÓN 8: Para Preline UI: los componentes se activan con data-* attributes.
               No necesitas JS custom para dropdowns, modales, tabs, etc.

INSTRUCCIÓN 9: NO instales librerías de UI adicionales (no Material UI,
               no Ant Design, no Chakra). Tailwind + Preline es suficiente.

INSTRUCCIÓN 10: Los módulos ⏸ DESACTIVADOS se dejan comentados.
                Cuando el usuario pida activarlos, se descomenta y adapta.
```

---

## 10. ORDEN DE TRABAJO DEL FRONTEND

```
PASO 1: Configuración base
  - Instalar paquetes nuevos (TanStack Query, Axios, Zustand, etc.)
  - Crear src/services/api.ts (Axios instance)
  - Crear src/context/AuthContext.tsx
  - Crear src/components/common/ProtectedRoute.tsx
  - Modificar src/App.tsx (agregar providers)
  - Modificar src/routes/index.tsx (rutas ERP)
  - Modificar menu.ts (sidebar ERP)

PASO 2: Login y autenticación
  - Adaptar /modern-login como /login
  - Conectar a POST /api/v1/auth/login/
  - Implementar JWT flow (access en memoria, refresh)
  - Redirect a /dashboard después de login

PASO 3: Dashboard
  - Adaptar dashboard ecommerce como dashboard ERP
  - Conectar KPIs a la API (o mostrar placeholders)

PASO 4: Inventario
  - Adaptar product-list → /inventario/productos
  - Adaptar product-create → /inventario/productos/crear
  - Adaptar product-overview → /inventario/productos/:id
  - Conectar a API de inventario

PASO 5: Clientes
  - Crear página de clientes (basada en users-list)
  - Conectar a API de clientes

PASO 6: Ventas
  - Adaptar orders → /ventas
  - Adaptar order-overview → /ventas/:id
  - Crear POS desde cero en src/pages/ventas/POSPage.tsx
  - Adaptar sales-estimates → /ventas/cotizaciones

PASO 7: Facturación
  - Adaptar invoice list → /facturacion/comprobantes
  - Adaptar invoice overview → /facturacion
```