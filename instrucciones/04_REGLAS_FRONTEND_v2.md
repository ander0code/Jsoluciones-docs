# JSOLUCIONES ERP — REGLAS DE FRONTEND v2 (React + Tailwick)

> Versión mejorada. Incluye: manejo de estado avanzado, Error Boundaries,
> accesibilidad, rendimiento, TanStack Query para data fetching,
> patrones de formularios complejos y manejo de estados de carga/error.

---

## 1. REGLAS ESTRICTAS DEL FRONTEND (Ampliadas)

```
FRONT-01: NUNCA modificar componentes base del template Tailwick.
FRONT-02: El frontend se adapta al backend, NO al revés.
FRONT-03: Extender Tailwick mediante composición, NO modificación directa.
FRONT-04: Toda llamada a API usa servicio centralizado (api.js con Axios).
FRONT-05: Estado global: Context API para auth/empresa + Zustand para estado complejo.
FRONT-06: JWT: access token en memoria, refresh token en httpOnly cookie.
FRONT-07: Toda ruta protegida verifica rol y permisos antes de renderizar.
FRONT-08: Mensajes de error y éxito con sistema de notificaciones (toast).
FRONT-09: NUNCA crear estilos CSS custom si Tailwind ya lo resuelve.
FRONT-10: Formularios con validación client-side Y server-side.
FRONT-11: Componentes nuevos en src/components/modules/{módulo}/.
FRONT-12: Servicios API en src/services/{módulo}Service.js.
FRONT-13: NUNCA hacer fetch directo. Siempre Axios centralizado.
FRONT-14: Variables de entorno para URLs de API.
FRONT-15: Toda tabla debe tener paginación, búsqueda y filtros.
FRONT-16: Todo componente que carga datos debe manejar 3 estados: loading, error, data.
FRONT-17: Error Boundaries en cada módulo para evitar crasheos globales.
FRONT-18: Lazy loading de módulos/páginas con React.lazy + Suspense.
FRONT-19: Debounce en campos de búsqueda (300ms mínimo).
FRONT-20: NUNCA mostrar IDs internos de la DB al usuario.
FRONT-21: Toda acción destructiva requiere confirmación (modal).
FRONT-22: Feedback visual inmediato: loading spinners, skeleton screens, disabled buttons.
FRONT-23: Formularios complejos (ventas, OC) usan patrón multi-step o wizard.
FRONT-24: Los montos siempre se muestran formateados (S/ 1,234.56).
FRONT-25: Toda tabla debe poder ordenar por columnas clickeables.
```

---

## 2. MANEJO DE ESTADO

### 2.1 Arquitectura de estado

```
┌────────────────────────────────────────────────┐
│                   ESTADO GLOBAL                 │
│                                                 │
│  AuthContext (Context API)                      │
│  ├── usuario, tokens, empresa activa             │
│  ├── login(), logout(), refreshToken()          │
│  └── tienePermiso(), tieneRol()                 │
│                                                 │
│  NotificationContext (Context API)              │
│  ├── showSuccess(), showError(), showWarning()  │
│  └── notifications[], dismiss()                 │
│                                                 │
│  useAppStore (Zustand) — estado complejo        │
│  ├── sidebar abierto/cerrado                    │
│  ├── tema claro/oscuro                          │
│  └── preferencias del usuario                   │
├────────────────────────────────────────────────┤
│              ESTADO DEL SERVIDOR                │
│                                                 │
│  TanStack Query (React Query)                   │
│  ├── useQuery para GET (auto-cache, refetch)    │
│  ├── useMutation para POST/PUT/DELETE           │
│  ├── Cache automático por query key             │
│  └── Invalidación inteligente de cache          │
├────────────────────────────────────────────────┤
│              ESTADO LOCAL                        │
│                                                 │
│  useState / useReducer                          │
│  ├── Formularios en edición                     │
│  ├── Modales abiertos/cerrados                  │
│  ├── Filtros activos en la vista actual         │
│  └── Pasos de un wizard                         │
└────────────────────────────────────────────────┘
```

### 2.2 TanStack Query (React Query) — Data fetching

```javascript
// src/hooks/useVentas.js
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import VentasService from '../services/ventasService';

// Hook para listar ventas
export function useVentas(filtros = {}) {
  return useQuery({
    queryKey: ['ventas', filtros],
    queryFn: () => VentasService.listar(filtros),
    staleTime: 30 * 1000,        // 30 seg antes de refetch
    placeholderData: keepPreviousData, // Mantener datos previos al paginar
  });
}

// Hook para obtener una venta
export function useVenta(id) {
  return useQuery({
    queryKey: ['ventas', id],
    queryFn: () => VentasService.obtener(id),
    enabled: !!id, // Solo ejecutar si hay id
  });
}

// Hook para crear venta (mutation)
export function useCrearVenta() {
  const queryClient = useQueryClient();
  const { showSuccess, showError } = useNotification();

  return useMutation({
    mutationFn: (data) => VentasService.crear(data),
    onSuccess: (data) => {
      // Invalidar cache de listado para que se refresque
      queryClient.invalidateQueries({ queryKey: ['ventas'] });
      // También invalidar stock (se afectó al vender)
      queryClient.invalidateQueries({ queryKey: ['inventario'] });
      showSuccess('Venta registrada correctamente');
    },
    onError: (error) => {
      const mensaje = error.response?.data?.message || 'Error al crear la venta';
      showError(mensaje);
    },
  });
}

// Uso en componente:
function VentasListPage() {
  const [filtros, setFiltros] = useState({ page: 1 });
  const { data, isLoading, isError, error } = useVentas(filtros);

  if (isLoading) return <TableSkeleton rows={10} />;
  if (isError) return <ErrorMessage error={error} />;

  return <VentasTable data={data.data.results} />;
}
```

### 2.3 Instalación de dependencias

```bash
npm install @tanstack/react-query zustand axios
npm install @tanstack/react-query-devtools --save-dev  # DevTools
```

```jsx
// src/App.jsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30 * 1000,  // 30 seg
      retry: 2,               // Reintentar 2 veces si falla
      refetchOnWindowFocus: false, // No refetch al cambiar de pestaña
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <NotificationProvider>
          <AppRoutes />
        </NotificationProvider>
      </AuthProvider>
      <ReactQueryDevtools initialIsOpen={false} /> {/* Solo dev */}
    </QueryClientProvider>
  );
}
```

---

## 3. ERROR BOUNDARIES (Evitar crasheos globales)

### 3.1 Error Boundary genérico

```jsx
// src/components/common/ErrorBoundary.jsx
import { Component } from 'react';

class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    // Log a servicio de monitoreo (futuro: Sentry)
    console.error('ErrorBoundary caught:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback || (
          <div className="flex flex-col items-center justify-center p-8">
            <h2 className="text-xl font-semibold text-red-600 mb-2">
              Algo salió mal
            </h2>
            <p className="text-gray-600 mb-4">
              Ocurrió un error inesperado en este módulo.
            </p>
            <button
              onClick={() => this.setState({ hasError: false, error: null })}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Reintentar
            </button>
          </div>
        )
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
```

### 3.2 Uso por módulo

```jsx
// src/routes/AppRoutes.jsx
import { Suspense, lazy } from 'react';
import ErrorBoundary from '../components/common/ErrorBoundary';
import LoadingPage from '../components/common/LoadingPage';

// Lazy load de módulos
const VentasListPage = lazy(() => import('../pages/ventas/VentasListPage'));
const InventarioPage = lazy(() => import('../pages/inventario/ProductosPage'));
const POSPage = lazy(() => import('../pages/ventas/POSPage'));

// Cada módulo tiene su propio Error Boundary
<Route
  path="/ventas"
  element={
    <ProtectedRoute permiso="ventas.ver">
      <ErrorBoundary fallback={<ModuleError modulo="Ventas" />}>
        <Suspense fallback={<LoadingPage />}>
          <VentasListPage />
        </Suspense>
      </ErrorBoundary>
    </ProtectedRoute>
  }
/>
```

---

## 4. ESTADOS DE CARGA Y ERROR (Obligatorio en toda vista)

### 4.1 Componentes de estado

```jsx
// src/components/common/Loading/TableSkeleton.jsx
// Skeleton que imita la forma de una tabla mientras carga
const TableSkeleton = ({ rows = 5, cols = 4 }) => (
  <div className="animate-pulse">
    {/* Header */}
    <div className="grid grid-cols-{cols} gap-4 p-4 bg-gray-100 rounded-t">
      {Array(cols).fill(0).map((_, i) => (
        <div key={i} className="h-4 bg-gray-300 rounded" />
      ))}
    </div>
    {/* Rows */}
    {Array(rows).fill(0).map((_, i) => (
      <div key={i} className="grid grid-cols-{cols} gap-4 p-4 border-b">
        {Array(cols).fill(0).map((_, j) => (
          <div key={j} className="h-3 bg-gray-200 rounded" />
        ))}
      </div>
    ))}
  </div>
);

// src/components/common/ErrorMessage.jsx
const ErrorMessage = ({ error, onRetry }) => {
  const mensaje = error?.response?.data?.message || error?.message || 'Error desconocido';
  const codigo = error?.response?.data?.error_code || 'unknown';

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
      <p className="text-red-800 font-medium mb-1">{mensaje}</p>
      <p className="text-red-500 text-sm mb-4">Código: {codigo}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
        >
          Reintentar
        </button>
      )}
    </div>
  );
};

// src/components/common/EmptyState.jsx
const EmptyState = ({ titulo, descripcion, accion }) => (
  <div className="flex flex-col items-center justify-center p-12 text-center">
    <div className="text-gray-400 mb-4">
      {/* Ícono de Tailwick o Lucide */}
    </div>
    <h3 className="text-lg font-medium text-gray-900 mb-1">{titulo}</h3>
    <p className="text-gray-500 mb-4">{descripcion}</p>
    {accion}
  </div>
);
```

### 4.2 Patrón obligatorio en toda página de listado

```jsx
function ProductosPage() {
  const [filtros, setFiltros] = useState({ page: 1, search: '' });
  const { data, isLoading, isError, error, refetch } = useProductos(filtros);

  return (
    <PageLayout titulo="Productos">
      {/* Barra de filtros siempre visible */}
      <FiltrosProductos filtros={filtros} onChange={setFiltros} />

      {/* Estado: Cargando */}
      {isLoading && <TableSkeleton rows={10} cols={5} />}

      {/* Estado: Error */}
      {isError && <ErrorMessage error={error} onRetry={refetch} />}

      {/* Estado: Sin datos */}
      {data && data.data.results.length === 0 && (
        <EmptyState
          titulo="No hay productos"
          descripcion="Comienza agregando tu primer producto al inventario."
          accion={<BtnCrearProducto />}
        />
      )}

      {/* Estado: Con datos */}
      {data && data.data.results.length > 0 && (
        <>
          <ProductosTable data={data.data.results} />
          <Pagination
            total={data.data.count}
            page={filtros.page}
            onChange={(p) => setFiltros({...filtros, page: p})}
          />
        </>
      )}
    </PageLayout>
  );
}
```

---

## 5. FORMULARIOS COMPLEJOS

### 5.1 Patrón para formularios de venta/cotización

```jsx
// Formulario de venta: cabecera + N items dinámicos + cálculos en tiempo real
function VentaForm({ onSubmit }) {
  const [cabecera, setCabecera] = useState({
    cliente_id: null,
    metodo_pago: 'efectivo',
  });
  const [items, setItems] = useState([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Cálculos derivados (NO en state, se calculan al renderizar)
  const subtotal = items.reduce((acc, item) =>
    acc + (item.cantidad * item.precio_unitario), 0
  );
  const descuentoTotal = items.reduce((acc, item) =>
    acc + (item.descuento || 0), 0
  );
  const gravada = subtotal - descuentoTotal;
  const igv = gravada * 0.18;
  const total = gravada + igv;

  const agregarItem = (producto) => {
    // Verificar si ya existe
    const existe = items.find(i => i.producto_id === producto.id);
    if (existe) {
      actualizarCantidad(producto.id, existe.cantidad + 1);
      return;
    }
    setItems([...items, {
      producto_id: producto.id,
      nombre: producto.nombre,
      sku: producto.sku,
      cantidad: 1,
      precio_unitario: producto.precio_venta,
      descuento: 0,
    }]);
  };

  const handleSubmit = async () => {
    // Validación client-side
    if (!cabecera.cliente_id) {
      showError('Debe seleccionar un cliente');
      return;
    }
    if (items.length === 0) {
      showError('Debe agregar al menos un producto');
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit({ ...cabecera, items, total_venta: total });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
      {/* Columna izquierda: búsqueda de productos */}
      <div className="lg:col-span-2">
        <BuscadorProductos onSelect={agregarItem} />
        <ItemsTable
          items={items}
          onUpdate={actualizarItem}
          onRemove={removerItem}
        />
      </div>

      {/* Columna derecha: resumen y totales */}
      <div>
        <ClienteSelector
          value={cabecera.cliente_id}
          onChange={(id) => setCabecera({...cabecera, cliente_id: id})}
        />
        <ResumenTotales
          subtotal={subtotal}
          descuento={descuentoTotal}
          igv={igv}
          total={total}
        />
        <MetodoPagoSelector
          value={cabecera.metodo_pago}
          onChange={(m) => setCabecera({...cabecera, metodo_pago: m})}
        />
        <button
          onClick={handleSubmit}
          disabled={isSubmitting || items.length === 0}
          className="w-full mt-4 py-3 bg-green-600 text-white rounded-lg
                     font-semibold hover:bg-green-700
                     disabled:bg-gray-300 disabled:cursor-not-allowed"
        >
          {isSubmitting ? 'Procesando...' : `Registrar Venta — ${formatMoney(total)}`}
        </button>
      </div>
    </div>
  );
}
```

### 5.2 Búsqueda con debounce

```jsx
// src/hooks/useDebounce.js
import { useState, useEffect } from 'react';

export function useDebounce(value, delay = 300) {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
}

// Uso en búsqueda de productos:
function BuscadorProductos({ onSelect }) {
  const [termino, setTermino] = useState('');
  const terminoDebounced = useDebounce(termino, 300);

  const { data, isLoading } = useQuery({
    queryKey: ['productos-buscar', terminoDebounced],
    queryFn: () => InventarioService.buscar({ search: terminoDebounced }),
    enabled: terminoDebounced.length >= 2, // Mínimo 2 caracteres
  });

  return (
    <div className="relative">
      <input
        type="text"
        value={termino}
        onChange={(e) => setTermino(e.target.value)}
        placeholder="Buscar por SKU, nombre o código de barras..."
        className="w-full p-3 border rounded-lg"
        autoComplete="off"
      />
      {isLoading && <Spinner className="absolute right-3 top-3" />}
      {data && <ResultadosBusqueda items={data.data.results} onSelect={onSelect} />}
    </div>
  );
}
```

---

## 6. ACCESIBILIDAD (a11y) — Requisitos mínimos

```
A11Y-01: Todo <img> debe tener alt descriptivo.
A11Y-02: Botones deben tener texto visible o aria-label.
A11Y-03: Formularios: cada input debe tener <label> asociado (htmlFor).
A11Y-04: Modales: focus trap (el foco no sale del modal mientras esté abierto).
A11Y-05: Tablas: usar <thead>, <tbody>, <th scope="col">.
A11Y-06: Colores: contraste mínimo 4.5:1 texto/fondo (WCAG AA).
A11Y-07: Navegación por teclado: Tab, Enter, Escape deben funcionar.
A11Y-08: Alertas y errores: usar role="alert" para que lectores de pantalla las anuncien.
A11Y-09: Estados de carga: usar aria-busy="true" en contenedores que cargan.
A11Y-10: Inputs numéricos: usar inputMode="decimal" en móvil para precio/cantidad.
```

```jsx
// Ejemplo de input accesible:
<div>
  <label htmlFor="precio_venta" className="block text-sm font-medium mb-1">
    Precio de venta
  </label>
  <input
    id="precio_venta"
    type="text"
    inputMode="decimal"           // Teclado numérico en móvil
    aria-describedby="precio_help"
    value={precio}
    onChange={(e) => setPrecio(e.target.value)}
    className="w-full p-2 border rounded"
  />
  <p id="precio_help" className="text-xs text-gray-500 mt-1">
    Ingrese el precio en soles sin IGV
  </p>
</div>

// Ejemplo de alerta de error accesible:
{error && (
  <div role="alert" className="bg-red-50 border-red-200 p-3 rounded mt-2">
    <p className="text-red-800 text-sm">{error}</p>
  </div>
)}
```

---

## 7. RENDIMIENTO

### 7.1 Lazy loading obligatorio

```jsx
// src/routes/AppRoutes.jsx
import { Suspense, lazy } from 'react';

// CADA página se carga lazy (code splitting automático)
const DashboardPage = lazy(() => import('../pages/dashboard/DashboardPage'));
const VentasListPage = lazy(() => import('../pages/ventas/VentasListPage'));
const POSPage = lazy(() => import('../pages/ventas/POSPage'));
const ProductosPage = lazy(() => import('../pages/inventario/ProductosPage'));
const ClientesPage = lazy(() => import('../pages/clientes/ClientesPage'));
// ... etc

// Esto genera un JS bundle por módulo → carga más rápido
```

### 7.2 Memoización donde importa

```jsx
import { useMemo, useCallback, memo } from 'react';

// Memo en componentes de tabla (evita re-render de filas al cambiar filtros)
const VentaRow = memo(({ venta, onSelect }) => (
  <tr onClick={() => onSelect(venta.id)}>
    <td>{venta.numero}</td>
    <td>{venta.cliente_razon_social}</td>
    <td>{formatMoney(venta.total_venta)}</td>
    <td><Badge estado={venta.estado} /></td>
  </tr>
));

// useMemo para cálculos derivados pesados
function ResumenVentas({ ventas }) {
  const estadisticas = useMemo(() => ({
    total: ventas.reduce((acc, v) => acc + v.total_venta, 0),
    cantidad: ventas.length,
    promedio: ventas.length > 0 ? ventas.reduce((acc, v) => acc + v.total_venta, 0) / ventas.length : 0,
  }), [ventas]);

  return <KPICards stats={estadisticas} />;
}

// useCallback para funciones pasadas a hijos
function VentasPage() {
  const handleSelect = useCallback((id) => {
    navigate(`/ventas/${id}`);
  }, [navigate]);

  return <VentasTable onSelect={handleSelect} />;
}
```

### 7.3 Imágenes y assets

```
- Usar formato WebP para imágenes de productos (menor peso).
- Lazy load de imágenes fuera del viewport: loading="lazy".
- Placeholder de baja resolución mientras carga la imagen real.
- Logos y iconos: SVG inline o sprite (no PNG gigantes).
```

---

## 8. RESPONSIVE — Breakpoints y estrategia por vista

### 8.1 Estrategia mobile-first

```
REGLA: TODO se diseña primero para 320px (móvil), luego se adapta.

Breakpoints de Tailwind:
  sm:  640px   → Móvil grande / Landscape
  md:  768px   → Tablet
  lg:  1024px  → Laptop
  xl:  1280px  → Desktop
  2xl: 1536px  → Pantalla grande
```

### 8.2 Adaptaciones por vista

| Vista | Móvil (< 768px) | Tablet (768-1024px) | Desktop (> 1024px) |
|-------|-----------------|--------------------|--------------------|
| **Dashboard** | KPIs en stack vertical, 1 gráfico | KPIs 2x2, 2 gráficos | KPIs en fila, 3+ gráficos |
| **Listados** | Card view (sin tabla), filtros en drawer | Tabla compacta, filtros en sidebar colapsable | Tabla completa, filtros laterales |
| **POS** | Fullscreen, búsqueda arriba, items abajo, total fijo en footer | Split 60/40: productos/resumen | Split 70/30: productos/resumen |
| **Formulario venta** | Steps (wizard) | 2 columnas | 3 columnas |
| **Detalle comprobante** | Stack vertical, botones flotantes | 2 columnas | Previsualización tipo factura |
| **Seguimiento pedido** | Timeline vertical, mapa pequeño | Split 50/50: mapa/timeline | Mapa grande + sidebar |

### 8.3 Navegación responsiva

```jsx
// Sidebar: Overlay en móvil, fijo en desktop
<aside className="
  fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg
  transform -translate-x-full transition-transform
  lg:translate-x-0 lg:static lg:z-0
  {sidebarOpen ? 'translate-x-0' : ''}
">
  <SidebarContent />
</aside>

// Bottom navigation en móvil (para roles que usan mucho el móvil)
<nav className="fixed bottom-0 left-0 right-0 bg-white border-t lg:hidden">
  <div className="flex justify-around py-2">
    <NavItem icon="home" label="Inicio" to="/dashboard" />
    <NavItem icon="cart" label="Vender" to="/ventas/pos" />
    <NavItem icon="box" label="Inventario" to="/inventario" />
    <NavItem icon="user" label="Perfil" to="/perfil" />
  </div>
</nav>
```

---

## 9. CONVENCIONES DE NOMBRADO

```
Archivos de componente: PascalCase.jsx
  VentasListPage.jsx, ProductoForm.jsx, ClienteSelector.jsx

Archivos de hook: camelCase con use prefix
  useVentas.js, useDebounce.js, usePermission.js

Archivos de servicio: camelCase + Service
  ventasService.js, inventarioService.js

Archivos de utilidad: camelCase
  formatters.js, validators.js, constants.js

Carpetas: kebab-case o camelCase (consistente)
  components/modules/ventas/, hooks/, services/

Props: camelCase
  onSelect, isLoading, clienteId

Eventos: on + acción
  onClick, onSubmit, onChange, onSelect, onDelete, onFilter

Variables de estado: sustantivo o is/has + adjetivo
  isLoading, hasError, ventas, filtroActivo, modalAbierto
```

---

## 10. SEGURIDAD FRONTEND

```
SEC-01: NUNCA guardar tokens en localStorage (XSS vulnerable).
SEC-02: Sanitizar inputs que puedan contener HTML (DOMPurify si es necesario).
SEC-03: NUNCA interpoler datos del usuario directamente en el DOM sin escapar.
SEC-04: Validar permisos en el frontend ANTES de mostrar botones/acciones.
SEC-05: NUNCA confiar solo en validación frontend. El backend siempre valida también.
SEC-06: Las URLs de API usan HTTPS en producción.
SEC-07: CORS configurado correctamente en el backend para aceptar solo el dominio del frontend.
SEC-08: Logout limpia TODA la memoria: tokens, cache de react-query, estado global.
SEC-09: Auto-logout por inactividad (configurable, default: 30 min).
SEC-10: NUNCA loggear tokens o datos sensibles en console.log en producción.
```

---

## 11. ESTRUCTURA FINAL DEL PROYECTO REACT

```
frontend/
├── public/
│   ├── manifest.json
│   └── favicon.ico
├── src/
│   ├── components/
│   │   ├── common/                   # Reutilizables (basados en Tailwick)
│   │   │   ├── Table/
│   │   │   │   ├── DataTable.jsx     # Tabla con sort, pagination, search
│   │   │   │   └── TableSkeleton.jsx
│   │   │   ├── Form/
│   │   │   │   ├── InputField.jsx    # Input con label, error, helper
│   │   │   │   ├── SelectField.jsx
│   │   │   │   ├── DatePicker.jsx
│   │   │   │   └── SearchInput.jsx   # Con debounce integrado
│   │   │   ├── Feedback/
│   │   │   │   ├── ErrorBoundary.jsx
│   │   │   │   ├── ErrorMessage.jsx
│   │   │   │   ├── EmptyState.jsx
│   │   │   │   ├── LoadingPage.jsx
│   │   │   │   └── ConfirmModal.jsx  # Modal de confirmación genérico
│   │   │   ├── Layout/
│   │   │   │   ├── PageLayout.jsx    # Wrapper con título + breadcrumb
│   │   │   │   ├── Sidebar.jsx
│   │   │   │   └── BottomNav.jsx     # Nav móvil
│   │   │   ├── Badge.jsx
│   │   │   ├── KPICard.jsx
│   │   │   └── Pagination.jsx
│   │   └── modules/
│   │       ├── auth/
│   │       ├── dashboard/
│   │       ├── ventas/
│   │       │   ├── VentaForm.jsx
│   │       │   ├── VentasTable.jsx
│   │       │   ├── ItemsTable.jsx
│   │       │   ├── POSInterface.jsx
│   │       │   ├── CotizacionForm.jsx
│   │       │   ├── ClienteSelector.jsx
│   │       │   └── ResumenTotales.jsx
│   │       ├── inventario/
│   │       ├── facturacion/
│   │       ├── clientes/
│   │       ├── proveedores/
│   │       ├── compras/
│   │       ├── distribucion/
│   │       ├── finanzas/
│   │       ├── whatsapp/
│   │       └── usuarios/
│   ├── pages/                         # 1 archivo por ruta
│   ├── services/                      # Axios centralizado
│   ├── hooks/                         # Custom hooks
│   │   ├── useAuth.js
│   │   ├── useDebounce.js
│   │   ├── usePermission.js
│   │   ├── useVentas.js              # TanStack Query hooks
│   │   ├── useProductos.js
│   │   ├── useClientes.js
│   │   └── ...
│   ├── context/
│   │   ├── AuthContext.jsx
│   │   └── NotificationContext.jsx
│   ├── stores/                        # Zustand stores
│   │   └── useAppStore.js
│   ├── utils/
│   │   ├── formatters.js
│   │   ├── validators.js
│   │   └── constants.js
│   ├── routes/
│   │   ├── AppRoutes.jsx
│   │   └── ProtectedRoute.jsx
│   └── App.jsx
├── .env
└── vite.config.js
```

---

## 12. CHECKLIST FRONTEND AMPLIADO

- [ ] ¿Se usó componente Tailwick existente o se justificó crear uno nuevo?
- [ ] ¿La vista funciona en móvil (320px)?
- [ ] ¿Se usa el servicio API centralizado?
- [ ] ¿Se usa TanStack Query (useQuery/useMutation) para data fetching?
- [ ] ¿Hay validación client-side en formularios?
- [ ] ¿La ruta está protegida con ProtectedRoute + permiso?
- [ ] ¿Hay Error Boundary envolviendo el módulo?
- [ ] ¿La vista maneja los 3 estados: loading, error, data?
- [ ] ¿Hay skeleton/spinner mientras carga?
- [ ] ¿Hay empty state cuando no hay datos?
- [ ] ¿Las tablas tienen paginación Y ordenamiento?
- [ ] ¿Los inputs de búsqueda tienen debounce?
- [ ] ¿Las acciones destructivas piden confirmación?
- [ ] ¿Los montos se muestran formateados?
- [ ] ¿Los inputs tienen labels y son accesibles?
- [ ] ¿No se modificó ningún componente base de Tailwick?
- [ ] ¿Se usa lazy loading para la página?
