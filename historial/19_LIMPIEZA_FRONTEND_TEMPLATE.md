# 19 - Limpieza del Frontend (Template Tailwick)

**Fecha:** 2026-02-19  
**Estado:** Completado  
**Alcance:** Eliminacion de vistas demo, reestructuracion de rutas y menu, correccion de bugs, branding JSoluciones.

---

## Resumen

Se limpio el frontend basado en la plantilla Tailwick, eliminando todas las vistas demo que no seran usadas en el ERP y reorganizando rutas y navegacion para reflejar los modulos reales de JSoluciones.

---

## 1. Directorios eliminados (26 total)

### Dashboards no usados
- `src/app/(admin)/(dashboards)/analytics/`
- `src/app/(admin)/(dashboards)/email/`
- `src/app/(admin)/(dashboards)/hr/`

### HR demos no usados
- `src/app/(admin)/(app)/(hr)/holidays/`
- `src/app/(admin)/(app)/(hr)/attendance/`
- `src/app/(admin)/(app)/(hr)/leave/`
- `src/app/(admin)/(app)/(hr)/department/`
- `src/app/(admin)/(app)/(hr)/payroll/`
- `src/app/(admin)/(app)/(hr)/create-payslip/`
- `src/app/(admin)/(app)/(hr)/sales-expenses/`
- `src/app/(admin)/(app)/(hr)/sellers/`

### Ecommerce demos no usados
- `src/app/(admin)/(app)/(ecommerce)/checkout/`

### Layout demos (9 variantes)
- `src/app/(admin)/(layouts)/layout-sidenav/`
- `src/app/(admin)/(layouts)/layout-topbar/`
- `src/app/(admin)/(layouts)/layout-two-column/`
- `src/app/(admin)/(layouts)/layout-modern/`
- `src/app/(admin)/(layouts)/layout-horizontal/`
- `src/app/(admin)/(layouts)/layout-dual-nav/`
- `src/app/(admin)/(layouts)/layout-detached/`
- `src/app/(admin)/(layouts)/layout-compact/`
- `src/app/(admin)/(layouts)/layout-full/`

### Pages demos no usados
- `src/app/(admin)/(pages)/pricing/`
- `src/app/(admin)/(pages)/faqs/`
- `src/app/(admin)/(pages)/starter/`

### Landing pages
- `src/app/(others)/landing-classic/`
- `src/app/(others)/landing-one-page/`

### Others
- `src/app/(others)/coming-soon/`
- `src/app/(others)/maintenance/`
- `src/app/(others)/offline/`

### Apps
- `src/app/(admin)/(app)/notes/`

---

## 2. Archivos reescritos

### `src/routes/Routes.tsx`
- **Antes:** ~120 rutas incluyendo todas las demos, layouts, landing pages, auth variantes
- **Despues:** Solo rutas ERP con paths en espanol:
  - `/dashboard` - Dashboard principal (Ecommerce)
  - `/ventas` - Lista de ventas (Orders)
  - `/ventas/:id` - Detalle de venta (Order Overview)
  - `/ventas/pos` - Punto de venta (Product Grid + Cart)
  - `/ventas/cotizaciones` - Cotizaciones (Sales Estimates)
  - `/ventas/cobros` - Cuentas por cobrar (Sales Payments)
  - `/inventario/productos` - Lista de productos (Product List)
  - `/inventario/productos/crear` - Crear producto (Product Create)
  - `/inventario/productos/:id` - Detalle de producto (Product Overview)
  - `/inventario/catalogo` - Catalogo de productos (Product Grid)
  - `/clientes` - Clientes (Users List)
  - `/proveedores` - Proveedores (Users List)
  - `/facturacion` - Dashboard facturacion (Invoice Overview)
  - `/facturacion/comprobantes` - Lista de comprobantes (Invoice List)
  - `/facturacion/nuevo` - Emitir comprobante (Invoice Add New)
  - `/configuracion/usuarios` - Usuarios (Employee List)
  - `/configuracion/roles` - Roles y permisos (Users Grid)
  - `/calendario` - Calendario (Calendar)
  - `/bandeja` - Bandeja de entrada (Mailbox)
  - `/chat` - Chat (Chat)
  - `/perfil` - Perfil de usuario
  - `/linea-de-tiempo` - Timeline
  - Auth: `/login`, `/register`, `/reset-password`, `/confirm-email`, `/2fa`, `/logout`
  - `/404` - Pagina no encontrada

### `src/components/layouts/SideNav/menu.ts`
- **Antes:** Menu completo del template (Dashboards, Apps, Pages, Components, etc.)
- **Despues:** Menu ERP organizado en secciones:
  - **General:** Dashboard, Calendario, Bandeja, Chat
  - **Ventas:** Lista, POS, Cotizaciones, Cobros
  - **Inventario:** Productos, Crear Producto, Catalogo
  - **Facturacion:** Dashboard, Comprobantes, Emitir Comprobante
  - **Herramientas:** Clientes, Proveedores
  - **Configuracion:** Usuarios, Roles y Permisos, Perfil

---

## 3. Bugs corregidos

### Bug 1: QueryClient duplicado
- **Archivo:** `src/App.tsx`
- **Problema:** `QueryClientProvider` se instanciaba tanto en `main.tsx` como en `App.tsx`, causando dos caches de React Query independientes
- **Fix:** Eliminado `QueryClientProvider` y la instancia de `QueryClient` de `App.tsx`. Se conserva solo la de `main.tsx`

### Bug 2: AuthProvider duplicado
- **Archivo:** `src/App.tsx`
- **Problema:** `AuthProvider` se envolvia en `main.tsx` y en `App.tsx`
- **Fix:** Eliminado `AuthProvider` de `App.tsx`. Se conserva solo el de `main.tsx`

### Bug 3: Profile page doble layout
- **Archivo:** `src/app/(admin)/(app)/perfil/index.tsx`
- **Problema:** El componente renderizaba `PageWrapper` internamente, pero el router ya lo envolvia en `PageWrapper`, causando doble sidebar/header
- **Fix:** Eliminado `PageWrapper` del componente. Aplicados colores de marca (text-brand-dark, bg-primary/10, etc.)

### Bug 4: Branding incorrecto en constantes
- **Archivo:** `src/helpers/constants.ts`
- **Problema:** Decia "Tailwick" y "Themesdesign" en lugar de JSoluciones
- **Fix:** Actualizado a "JSoluciones ERP", "JSoluciones", moneda "S/." y URLs correctas

### Bug 5: Rutas muertas en sidebar
- **Problema:** Menu tenia enlaces a Basic Auth, Boxed Auth, Cover Auth que llevaban a 404
- **Fix:** Eliminadas al reescribir `menu.ts`

### Bug 6: Import de tipo inexistente `AuthLoginCreateWithJsonBody`
- **Archivos:** `src/context/AuthContext.tsx`, `src/app/(auth)/modern-login/index.tsx`
- **Problema:** Importaban `AuthLoginCreateWithJsonBody` que no existe como export en `generated.ts`. El tipo correcto es `Login`
- **Fix:** Cambiado import y todas las referencias a usar `type Login` directamente

### Bug 7: Tipo `void` testeado para truthiness
- **Archivo:** `src/context/AuthContext.tsx`
- **Problema:** Orval genera `data: void` en el response type del login (el backend no declara response schema en OpenAPI). El codigo hacia `if (data.data && ...)` que TypeScript 5.8 rechaza
- **Fix:** Cast explicito `data as unknown as Record<string, unknown> | undefined` antes del chequeo

### Bug 8: Variable `navigate` sin usar
- **Archivo:** `src/app/(auth)/modern-logout/index.tsx`
- **Problema:** `const navigate = useNavigate()` declarado pero nunca usado (el logout redirige via Link, no programaticamente)
- **Fix:** Eliminados el import de `useNavigate` y la declaracion de la variable

### Bug 9: Dependencias runtime en devDependencies
- **Archivo:** `package.json`
- **Problema:** `axios`, `@tanstack/react-query`, `@tanstack/react-query-devtools` estaban en `devDependencies` pero son dependencias de runtime
- **Fix:** Movidos a `dependencies`

---

## 4. Vistas del template conservadas (mapeadas a modulos ERP)

| Modulo ERP | Vista template base | Ruta ERP |
|---|---|---|
| Dashboard | Ecommerce Dashboard | `/dashboard` |
| POS | Product Grid + Cart | `/ventas/pos` |
| Lista de Ventas | Orders | `/ventas` |
| Detalle de Venta | Order Overview | `/ventas/:id` |
| Cotizaciones | Sales Estimates | `/ventas/cotizaciones` |
| Cuentas por Cobrar | Sales Payments | `/ventas/cobros` |
| Lista de Productos | Product List | `/inventario/productos` |
| Crear Producto | Product Create | `/inventario/productos/crear` |
| Detalle de Producto | Product Overview | `/inventario/productos/:id` |
| Catalogo | Product Grid | `/inventario/catalogo` |
| Clientes | Users List | `/clientes` |
| Proveedores | Users List | `/proveedores` |
| Dashboard Facturacion | Invoice Overview | `/facturacion` |
| Comprobantes | Invoice List | `/facturacion/comprobantes` |
| Emitir Comprobante | Invoice Add New | `/facturacion/nuevo` |
| Usuarios | Employee List | `/configuracion/usuarios` |
| Roles | Users Grid | `/configuracion/roles` |
| Calendario | Calendar | `/calendario` |
| Bandeja | Mailbox | `/bandeja` |
| Chat | Chat | `/chat` |

---

## 5. Estado de verificacion

- **Build (`tsc -b && vite build`):** PASA - 0 errores TypeScript, bundle generado exitosamente
- **Dev server (`vite`):** PASA - Inicia en ~180ms
- **Colores de marca:** Ya aplicados en `themes.css` (primary #D65A42, brand-dark #1A1A1A, etc.)

---

## 6. Tablas SQL pendientes (referenciadas en mapeo pero no existen en DB)

Estas entidades aparecen en `JSOLUCIONES_TEMPLATE_MAPING.MD` pero no tienen tablas en `SQL_JSOLUCIONES.sql`:

1. **PedidoOnline** - Pedidos desde tienda online
2. **ExtractoBancario** - Extractos bancarios para conciliacion
3. **DeclaracionTributaria** - Declaraciones SUNAT
4. **Disparador** - Triggers de automatizacion
5. **Campana** - Campanas de marketing
6. **Ruta** - Rutas de distribucion
7. **Zona** - Zonas geograficas de reparto
8. **Estanteria** - Ubicaciones dentro de almacen

---

## 7. Endpoints backend sin frontend aun

Estos modulos tienen API completa pero no se les creo vista frontend todavia (usaran las vistas template conservadas cuando se conecten):

1. **Almacenes** (`/api/v1/inventario/almacenes/`)
2. **Stock** (`/api/v1/inventario/stock/`)
3. **Movimientos de inventario** (`/api/v1/inventario/movimientos/`)
4. **Lotes** (`/api/v1/inventario/lotes/`)
5. **Proveedores CRUD** (`/api/v1/proveedores/`)
6. **Ordenes de Venta** (`/api/v1/ventas/ordenes-venta/`)
7. **Notas de Credito/Debito** (`/api/v1/facturacion/notas-credito/`, `/notas-debito/`)
8. **Series de Comprobante** (`/api/v1/facturacion/series/`)

---

## Proximos pasos

1. Conectar las vistas conservadas al backend real (reemplazar mock data por llamadas API via Orval)
2. Adaptar el contenido visual de cada vista al contexto peruano (moneda S/., RUC, tipos de comprobante SUNAT)
3. Crear vistas para los endpoints sin frontend (almacenes, stock, lotes, etc.)
4. Implementar las tablas SQL pendientes cuando se definan los requerimientos
