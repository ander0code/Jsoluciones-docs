# JSOLUCIONES ERP — PROCESOS DEL FRONTEND (Para el agente de frontend)

> Este archivo es para el agente de frontend que trabajará con React y el template Tailwick.
> Contiene: contexto del proyecto, qué se espera, qué vistas construir, qué datos
> consume del backend, y las reglas que debe seguir.

---

## 1. CONTEXTO QUE NECESITA EL AGENTE DE FRONTEND

### 1.1 Qué es el proyecto

JSoluciones es un ERP para empresas peruanas. El frontend es una SPA (Single Page Application) en React que consume una API REST en Django. El template **Tailwick** (React) ya fue comprado y se usa como base visual.

### 1.2 Stack del frontend

| Tecnología | Versión | Propósito |
|-----------|---------|-----------|
| React | 18+ | Framework UI |
| Vite | 5+ | Build tool |
| Tailwind CSS | 3+ | Estilos (viene con Tailwick) |
| Axios | 1.6+ | HTTP client |
| TanStack Query | 5+ | Data fetching, cache, mutations |
| Zustand | 4+ | Estado global liviano |
| React Router | 6+ | Routing |
| Lucide React | — | Iconos (si Tailwick los usa) |
| Chart.js o Recharts | — | Gráficos del dashboard |

### 1.3 Regla fundamental

```
EL TEMPLATE TAILWICK NO SE MODIFICA.
Se EXTIENDEN sus componentes mediante composición.
Se REUTILIZAN sus componentes de tabla, modal, form, card, badge.
Si Tailwick ya tiene algo, se usa. Si no, se crea en components/modules/.
```

### 1.4 Cómo se conecta con el backend

- La API REST está en Django DRF
- Base URL configurable por variable de entorno: `VITE_API_URL`
- Autenticación: JWT (Bearer token en header Authorization)
- Autenticación solo por JWT en header Authorization
- Formato de respuesta estándar del backend:

```json
// Éxito
{
  "success": true,
  "data": { ... },
  "message": "Operación exitosa"
}

// Éxito con lista paginada
{
  "success": true,
  "data": {
    "results": [...],
    "count": 150,
    "next": "http://api/endpoint/?page=2",
    "previous": null
  },
  "message": null
}

// Error
{
  "success": false,
  "data": null,
  "message": "Stock insuficiente para completar la operación.",
  "errors": { "campo": ["mensaje de error"] },
  "error_code": "stock_insuficiente"
}
```

---

## 2. VISTAS QUE DEBE CONSTRUIR EL AGENTE (En orden de prioridad)

### SPRINT 1 — Fundación

| # | Vista | Ruta | Componente Tailwick base | Datos del API |
|---|-------|------|-------------------------|---------------|
| 1 | **Login** | `/login` | Form + Card | `POST /auth/login/` |
| — | ~~Selección de Tenant~~ | ~~`/select-tenant`~~ | ~~Eliminado~~ | No aplica (instancia por empresa) |
| 3 | **Layout principal** | `/` (wrapper) | Sidebar + Header + Content | — |
| 4 | **Dashboard vacío** | `/dashboard` | Dashboard template | — (placeholder) |

#### Login — Detalle:
```
Campos: email, password
Botón: "Iniciar sesión"
Acción: POST /auth/login/ → recibir tokens → guardar en AuthContext
Después de login exitoso → ir directo a /dashboard
Mostrar error si credenciales inválidas
Responsive: centrado en desktop, fullscreen en móvil
```

#### Layout principal — Detalle:
```
Sidebar izquierdo:
  - Logo JSoluciones
  - Menú con ícono y label:
    - Dashboard       (siempre visible)
    - Ventas          (si tiene permiso ventas.ver)
    - POS             (si tiene permiso ventas.pos)
    - Inventario      (si tiene permiso inventario.ver)
    - Clientes        (si tiene permiso clientes.ver)
    - Proveedores     (si tiene permiso proveedores.ver)
    - Compras         (si tiene permiso compras.ver)
    - Facturación     (si tiene permiso facturacion.ver)
    - Finanzas        (si tiene permiso finanzas.ver)
    - Distribución    (si tiene permiso distribucion.ver)
    - Reportes        (si tiene permiso reportes.ver)
    - Configuración   (solo admin)
  - Solo mostrar items que el usuario tiene permiso de ver

Header superior:
  - Nombre de la empresa
  - Notificaciones (campana)
  - Avatar/nombre del usuario + dropdown (Mi perfil, Cerrar sesión)

Content area:
  - Donde se renderiza cada página
  - Breadcrumb automático

Footer (móvil):
  - Bottom navigation con 4 items principales
```

### SPRINT 2 — Inventario

| # | Vista | Ruta | Datos del API |
|---|-------|------|---------------|
| 5 | **Lista de productos** | `/inventario/productos` | `GET /inventario/productos/` |
| 6 | **Crear/Editar producto** | `/inventario/productos/crear` | `POST /inventario/productos/` |
| 7 | **Detalle de producto** | `/inventario/productos/:id` | `GET /inventario/productos/:id/` |
| 8 | **Categorías** | `/inventario/categorias` | `GET /inventario/categorias/` |
| 9 | **Almacenes** | `/inventario/almacenes` | `GET /inventario/almacenes/` |
| 10 | **Movimientos de stock** | `/inventario/movimientos` | `GET /inventario/movimientos/` |
| 11 | **Alertas de stock** | `/inventario/alertas` | `GET /inventario/alertas-stock/` |

#### Lista de productos — Detalle:
```
Tabla con columnas: SKU, Nombre, Categoría, Precio Venta, Stock, Estado
Filtros: categoría (select), estado (activo/inactivo), búsqueda por nombre/SKU
Paginación: 20 por página
Acciones por fila: Ver, Editar, Eliminar (solo admin/supervisor)
Botón superior: "Nuevo Producto"
Estado de carga: Skeleton de tabla
Estado vacío: "No hay productos. Comienza agregando tu primer producto."
Mobile: Modo card en vez de tabla
```

### SPRINT 3 — Clientes + Ventas

| # | Vista | Ruta | Datos del API |
|---|-------|------|---------------|
| 12 | **Lista de clientes** | `/clientes` | `GET /clientes/` |
| 13 | **Crear/Editar cliente** | `/clientes/crear` | `POST /clientes/` |
| 14 | **Lista de ventas** | `/ventas` | `GET /ventas/` |
| 15 | **Crear venta** | `/ventas/crear` | `POST /ventas/` |
| 16 | **POS (Punto de Venta)** | `/ventas/pos` | `POST /ventas/pos/` |
| 17 | **Cotizaciones** | `/ventas/cotizaciones` | `GET /ventas/cotizaciones/` |
| 18 | **Órdenes de venta** | `/ventas/ordenes` | `GET /ventas/ordenes/` |
| 19 | **Detalle de venta** | `/ventas/:id` | `GET /ventas/:id/` |

#### POS (Punto de Venta) — Detalle:
```
Vista fullscreen optimizada para tablet/desktop.
Layout 2 columnas (o 1 en móvil):

IZQUIERDA (70%):
  - Barra de búsqueda (por SKU, nombre, código de barras)
  - Grid de productos rápidos (botones grandes, touch-friendly, 44x44px mínimo)
  - Cada producto muestra: nombre, precio, stock disponible
  - Al click → se agrega al carrito

DERECHA (30%):
  - Selector de cliente (búsqueda rápida, puede ser "Varios" = sin identificar)
  - Lista de items agregados (producto, cantidad, precio, subtotal)
  - Botón +/- para cantidad
  - Cálculo en tiempo real: Subtotal, IGV (18%), Total
  - Selector de método de pago (efectivo, tarjeta, Yape/Plin, transferencia)
  - Botón grande "COBRAR S/ X,XXX.XX"
  - Al cobrar: POST /ventas/pos/ → mostrar modal de éxito con número de comprobante

Funcionalidades extra:
  - Teclado numérico para cantidad (en tablet)
  - Descuento por item (solo supervisor+)
  - Descuento global (solo supervisor+)
  - Imprimir comprobante (link al PDF de Nubefact)

Responsive:
  - Desktop: 2 columnas 70/30
  - Tablet: 2 columnas 60/40
  - Móvil: Stack vertical (búsqueda arriba, carrito abajo, total fijo en footer)
```

### SPRINT 4-5 — Facturación + Proveedores

| # | Vista | Ruta |
|---|-------|------|
| 20 | **Comprobantes electrónicos** | `/facturacion/comprobantes` |
| 21 | **Detalle comprobante** | `/facturacion/comprobantes/:id` |
| 22 | **Notas de crédito** | `/facturacion/notas-credito` |
| 23 | **Lista de proveedores** | `/proveedores` |
| 24 | **Órdenes de compra** | `/compras/ordenes` |

---

## 3. COMPONENTES COMUNES QUE EL AGENTE DEBE CREAR/ADAPTAR

### 3.1 DataTable (adaptar de Tailwick)

```
Funcionalidades:
  - Columnas configurables (label, key, sortable, render custom)
  - Paginación integrada (page, page_size)
  - Búsqueda global con debounce (300ms)
  - Filtros (select, date range, estado)
  - Ordenamiento por columna (click en header)
  - Acciones por fila (ver, editar, eliminar)
  - Export CSV/Excel (botón)
  - Skeleton loader mientras carga
  - Empty state cuando no hay datos
  - Responsive: tabla en desktop, cards en móvil

Props esperadas:
  columns: [{ key, label, sortable, render }]
  data: array de objetos
  isLoading: boolean
  pagination: { total, page, pageSize, onChange }
  onSearch: function(term)
  onSort: function(field, direction)
  actions: [{ label, icon, onClick, visible: (row) => boolean }]
```

### 3.2 FormModal (adaptar de Tailwick)

```
Funcionalidades:
  - Modal con título, formulario y botones
  - Validación client-side (mostrar errores inline)
  - Validación server-side (mostrar errores del backend)
  - Botón submit con loading state (disabled + spinner)
  - Focus trap (accesibilidad)
  - Cerrar con Escape

Props:
  isOpen, onClose, titulo
  onSubmit: async function → puede lanzar error
  isSubmitting: boolean
  children: campos del formulario
```

### 3.3 ConfirmModal

```
"¿Está seguro de anular esta venta?"
[Cancelar] [Sí, anular]

Props:
  isOpen, onClose, onConfirm
  titulo, mensaje
  confirmLabel, confirmColor (red para destructivo, blue para normal)
  isLoading: boolean (mientras procesa)
```

### 3.4 ClienteSelector (buscador de clientes)

```
- Input de búsqueda con debounce
- Dropdown con resultados (nombre, RUC/DNI)
- Botón "Crear nuevo" si no existe
- Opción "Varios" (cliente genérico para boletas)
- Muestra RUC/DNI y razón social seleccionado

Props:
  value: clienteId
  onChange: function(clienteId)
  required: boolean
```

### 3.5 ProductoSelector (buscador de productos)

```
- Input de búsqueda (SKU, nombre, código barras)
- Dropdown con resultados (nombre, SKU, precio, stock)
- Resalta stock = 0 en rojo
- No permite seleccionar si stock = 0

Props:
  onSelect: function(producto)
  almacenId: number (para filtrar stock por almacén)
```

### 3.6 Badge (componente de estado)

```
Usa colores consistentes definidos en constants.js.
Muestra el estado en texto legible.

Props:
  estado: string ('pendiente', 'aceptado', etc.)
  
Mapeo de colores definido en 04_REGLAS_FRONTEND_v2.md sección 8.
```

---

## 4. HOOKS PERSONALIZADOS QUE DEBE CREAR

```javascript
// Cada módulo tiene su archivo de hooks con TanStack Query

// src/hooks/useProductos.js
useProductos(filtros)           → GET /inventario/productos/
useProducto(id)                 → GET /inventario/productos/:id/
useCrearProducto()              → POST mutation
useEditarProducto()             → PATCH mutation
useBuscarProductos(termino)     → GET /inventario/productos/buscar/
useAlertasStock()               → GET /inventario/alertas-stock/

// src/hooks/useVentas.js
useVentas(filtros)              → GET /ventas/
useVenta(id)                    → GET /ventas/:id/
useCrearVenta()                 → POST mutation
useCrearVentaPOS()              → POST /ventas/pos/ mutation
useAnularVenta()                → POST /ventas/:id/anular/ mutation
useCotizaciones(filtros)        → GET /ventas/cotizaciones/
useCrearCotizacion()            → POST mutation
useConvertirCotizacion()        → POST mutation

// src/hooks/useClientes.js
useClientes(filtros)            → GET /clientes/
useCliente(id)                  → GET /clientes/:id/
useCrearCliente()               → POST mutation
useBuscarClientes(termino)      → GET /clientes/buscar/

// src/hooks/useAuth.js
useAuth()                       → AuthContext (usuario, permisos, login, logout)
usePermission(codigo)           → boolean (tiene o no el permiso)
```

---

## 5. NAVEGACIÓN Y PERMISOS POR ROL

### Qué ve cada rol en el sidebar:

| Menú item | admin | gerente | supervisor | vendedor | cajero | almacenero | contador | repartidor |
|-----------|-------|---------|-----------|----------|--------|-----------|----------|-----------|
| Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| POS | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Ventas | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Inventario | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Clientes | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Proveedores | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Compras | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Facturación | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Finanzas | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Distribución | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Reportes | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Configuración | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

### Cómo implementarlo:

```jsx
// El /auth/me/ retorna:
{
  "data": {
    "id": 1,
    "email": "usuario@empresa.com",
    "nombre": "Juan Pérez",
    "rol": {
      "codigo": "vendedor",
      "nombre": "Vendedor"
    },
    "permisos": [
      "ventas.ver", "ventas.crear", "ventas.pos",
      "clientes.ver", "clientes.crear",
      "inventario.consultar_stock",
      "dashboard.operativo"
    ],
    "empresa": {
      "id": 1,
      "ruc": "20123456789",
      "razon_social": "Mi Empresa SAC"
    }
  }
}

// En el sidebar, filtrar por permisos:
const menuItems = [
  { label: 'Dashboard', icon: 'home', to: '/dashboard', permiso: null },
  { label: 'POS', icon: 'shopping-cart', to: '/ventas/pos', permiso: 'ventas.pos' },
  { label: 'Ventas', icon: 'receipt', to: '/ventas', permiso: 'ventas.ver' },
  // ...
].filter(item => !item.permiso || tienePermiso(item.permiso));
```

---

## 6. REQUISITOS DE UI/UX OBLIGATORIOS

```
UX-01: Toda acción exitosa muestra toast verde (3 seg, auto-dismiss).
UX-02: Todo error muestra toast rojo con mensaje del backend.
UX-03: Botones de submit se deshabilitan mientras procesan.
UX-04: Tablas muestran skeleton mientras cargan (NO spinner genérico).
UX-05: Formularios muestran errores inline debajo de cada campo.
UX-06: Montos siempre formateados: S/ 1,234.56 (usar formatMoney).
UX-07: Fechas formateadas: 04/06/2024 (usar formatDate, formato dd/mm/yyyy).
UX-08: RUC/DNI validados en tiempo real (antes de enviar al backend).
UX-09: Breadcrumb visible en toda página (Dashboard > Ventas > Detalle #123).
UX-10: Modal de confirmación en acciones destructivas (eliminar, anular).
UX-11: NUNCA mostrar IDs internos de la DB al usuario.
UX-12: Números de documento formateados: F001-00012345.
UX-13: Al crear algo exitosamente, redirigir al listado o al detalle.
UX-14: Inputs de búsqueda con ícono de lupa y botón de limpiar.
UX-15: Tablas: resaltar fila al hover para facilitar lectura.
```

---

## 7. PAQUETES NPM A INSTALAR

```json
{
  "dependencies": {
    "react": "^18.2",
    "react-dom": "^18.2",
    "react-router-dom": "^6.20",
    "axios": "^1.6",
    "@tanstack/react-query": "^5.17",
    "zustand": "^4.4",
    "react-hot-toast": "^2.4",
    "dayjs": "^1.11",
    "react-hook-form": "^7.49",
    "idb": "^8.0"
  },
  "devDependencies": {
    "@tanstack/react-query-devtools": "^5.17",
    "vite": "^5.0",
    "@vitejs/plugin-react": "^4.2",
    "tailwindcss": "^3.4",
    "autoprefixer": "^10.4",
    "postcss": "^8.4"
  }
}
```

**Notas:**
- `react-hot-toast`: Notificaciones toast ligeras
- `dayjs`: Manejo de fechas (más liviano que moment.js)
- `react-hook-form`: Formularios performantes con validación
- `idb`: IndexedDB wrapper para modo offline del POS
- Los paquetes de Tailwick (charts, iconos, etc.) ya vienen con el template
