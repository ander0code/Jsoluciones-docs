# JSOLUCIONES ERP — REGLAS DE FRONTEND v3

> Version 3. Alineada con el estado real del proyecto (Feb 2026).
> Reemplaza v2. Elimina sobreingenieria, refleja stack actual, define patrones concretos.

---

## 1. STACK REAL DEL PROYECTO (NO CAMBIAR)

| Tecnologia | Version | Proposito |
|-----------|---------|-----------|
| React | 19.1 | Framework UI |
| TypeScript | 5.8 | Tipado estatico |
| Vite | 7.1 | Build tool + dev server con proxy |
| Tailwind CSS | 4 | Estilos (via @tailwindcss/vite) |
| Preline | 3.2 | Interacciones JS (dropdowns, modales, tabs, acordeones) |
| TanStack React Query | 5 | Data fetching, cache, mutations |
| Orval | 8 | Genera hooks y tipos desde OpenAPI |
| react-hot-toast | - | Toasts/notificaciones |
| react-apexcharts | - | Graficos dashboard |
| @fullcalendar/react | - | Calendario |
| react-flatpickr | - | Date picker |
| lucide-react / react-icons | - | Iconos |
| react-hook-form | - | Formularios complejos (agregar) |
| pnpm | - | Package manager |

**Lo que NO se usa (NO agregar):**
- Zustand (no hay necesidad de estado global mas alla de AuthContext)
- Redux / MobX (misma razon)
- Axios como cliente HTTP principal (Orval usa customFetch con fetch nativo)
- dayjs / moment (usar Intl.DateTimeFormat o flat helpers)
- Cualquier libreria de componentes (MUI, Ant Design, Chakra) — Tailwind + Preline es suficiente

---

## 2. REGLAS ESTRICTAS

### Arquitectura

```
FRONT-01: Orval genera los hooks y tipos. NUNCA escribir tipos de API a mano.
          Los tipos en src/types/erp/index.ts son SOLO para uso interno del frontend
          cuando los tipos Orval no cubren un caso especifico.

FRONT-02: NUNCA escribir fetch() o axios.get() a mano para endpoints del backend.
          Siempre usar los hooks generados por Orval (src/api/generated/).
          La unica excepcion es fetchMe() en AuthContext (bootstrap de auth).

FRONT-03: El frontend se adapta al backend, NO al reves.
          Si el backend retorna un campo, el frontend lo usa tal cual.
          Si falta un campo, se pide al backend — no se inventa en el front.

FRONT-04: Toda pagina que consume datos DEBE manejar 3 estados: loading, error, datos.
          No hay excepciones. Usar los estados de React Query (isLoading, isError, data).

FRONT-05: Estado del servidor = React Query (via Orval hooks).
          Estado global de UI = AuthContext (usuario, permisos).
          Estado local de UI = useState/useReducer (filtros, modales, formularios).
          NO hay mas capas de estado. Punto.
```

### Template Tailwick

```
FRONT-06: Los componentes base del template (sidebar, topbar, footer, customizer,
          PageWrapper, PageBreadcrumb) se pueden MODIFICAR para JSoluciones.
          Ya no son "intocables" — son nuestros. Pero los cambios deben ser
          con proposito (limpiar, conectar a datos reales, aplicar branding).

FRONT-07: Para cada vista nueva, primero buscar si existe un componente del template
          que sirva como base. SI existe, copiarlo a la ruta correcta y adaptarlo.
          NO existe → crear desde cero usando Tailwind + Preline.

FRONT-08: NUNCA crear componentes wrapper innecesarios. Si Tailwind resuelve algo
          con 2-3 clases CSS, no crear un componente React para eso.
          Ejemplo MAL:  <FlexRow gap={4}><Text bold>Hola</Text></FlexRow>
          Ejemplo BIEN: <div className="flex gap-4"><span className="font-bold">Hola</span></div>
```

### Formularios

```
FRONT-09: Formularios simples (login, busqueda, filtros) → useState directo.
          Formularios complejos (POS, crear producto, cotizacion, emitir comprobante)
          → react-hook-form con validacion.

FRONT-10: Validacion client-side es UX, NO seguridad. El backend SIEMPRE valida.
          La validacion del front es para feedback rapido al usuario.
          Campos requeridos, formatos (RUC 11 digitos, DNI 8 digitos),
          rangos (precio > 0, cantidad >= 1).

FRONT-11: Errores del servidor se muestran tal cual vienen del backend.
          El backend retorna mensajes en espanol y codigos de error claros.
          NO traducir ni reformular mensajes del backend.
```

### Seguridad

```
FRONT-12: JWT tokens en localStorage es el estado ACTUAL (transitorio).
          TARGET: Migrar a httpOnly cookies cuando se complete el flujo de vistas.
          Mientras tanto, NUNCA loggear tokens en console.log en produccion.

FRONT-13: Toda ruta protegida usa ProtectedRoute con verificacion de auth.
          Las rutas que requieren permiso especifico pasan el prop `requiredPermission`.
          Las rutas que requieren rol especifico pasan el prop `requiredRole`.

FRONT-14: NUNCA mostrar IDs de la DB (UUIDs) al usuario en la interfaz.
          Usar numeros de documento (F001-00000123), nombres, o SKUs.

FRONT-15: NUNCA renderizar HTML del servidor sin sanitizar.
          Si algun campo puede contener HTML, usar DOMPurify o texto plano.
```

### Rendimiento

```
FRONT-16: React Query maneja el cache. staleTime por defecto es 5 min.
          Para datos que cambian poco (categorias, almacenes, roles) → staleTime: 30 min.
          Para datos que cambian mucho (stock, ventas del dia) → staleTime: 30 seg.

FRONT-17: Paginacion es del servidor (Django PageNumberPagination, 20 por pagina).
          NUNCA cargar todos los registros y paginar en el frontend.

FRONT-18: Las imagenes de productos usan loading="lazy" y formato WebP.
          Las URLs de imagenes vienen como presigned URLs de R2 (temporales).

FRONT-19: Busquedas con debounce de 300ms minimo. Ya existe useDebounce en helpers/.
          NUNCA hacer fetch en cada keystroke.
```

---

## 3. COMO CONSUMIR LA API (PATRON OBLIGATORIO)

### 3.1 Hooks generados por Orval

Orval genera hooks en `src/api/generated/{modulo}/{modulo}.ts`. Estos hooks:
- Usan `customFetch` de `src/api/fetcher.ts` (inyecta JWT, maneja refresh 401)
- Retornan tipos generados de `src/api/models/`
- Son hooks de TanStack Query (useQuery para GET, useMutation para POST/PUT/DELETE)

```typescript
// CORRECTO — Usar hook generado por Orval
import { useInventarioProductosList } from '@/api/generated/inventario/inventario';

function ProductosPage() {
  const { data, isLoading, isError, error } = useInventarioProductosList({
    page: 1,
    search: 'laptop',
  });

  // data.data.results es tipado automaticamente
}
```

```typescript
// INCORRECTO — NUNCA hacer esto
const res = await fetch('/api/v1/inventario/productos/');
const res = await axios.get('/api/v1/inventario/productos/');
```

### 3.2 Mutations (crear, editar, eliminar)

```typescript
import { useVentasPosCreate } from '@/api/generated/ventas/ventas';
import { useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';

function usePOSVenta() {
  const queryClient = useQueryClient();

  return useVentasPosCreate({
    mutation: {
      onSuccess: () => {
        // Invalidar caches relacionados
        queryClient.invalidateQueries({ queryKey: ['/api/v1/ventas/'] });
        queryClient.invalidateQueries({ queryKey: ['/api/v1/inventario/'] });
        toast.success('Venta registrada correctamente');
      },
      onError: (error: any) => {
        const msg = error?.data?.message || error?.data?.detail || 'Error al registrar venta';
        toast.error(msg);
      },
    },
  });
}
```

### 3.3 Formato de respuesta del backend

```typescript
// Listado paginado (GET)
{
  count: 150,
  next: "/api/v1/ventas/?page=2",
  previous: null,
  results: [...] // Array de objetos tipados
}

// Detalle (GET)
{
  id: "uuid",
  numero: "V001-0001",
  cliente: { ... },
  // ... campos del modelo
}

// Error (400/403/404/500)
{
  detail: "Stock insuficiente para Laptop HP.",
  // o
  message: "Stock insuficiente.",
  errors: { cantidad: ["Excede el stock disponible (5)."] }
}
```

### 3.4 Respuesta del customFetch

El customFetch en `src/api/fetcher.ts` retorna `{ data, status, headers }`.
Los hooks de Orval envuelven esto. Cuando accedes a `data` desde un hook:
- Para listados: `data.data.results`, `data.data.count`
- Para detalle: `data.data` (el objeto directo)

---

## 4. ESTRUCTURA DE ARCHIVOS

### Estructura actual (respetar)

```
src/
  api/
    fetcher.ts                    # Custom fetch con JWT (NO tocar salvo bugs)
    generated/                    # AUTO-GENERADO por Orval (NO editar a mano)
      auth/auth.ts
      ventas/ventas.ts
      inventario/inventario.ts
      ... (14 modulos)
    models/                       # AUTO-GENERADO por Orval (NO editar a mano)
      *.ts                        # ~250 archivos de tipos

  app/
    (admin)/                      # Paginas autenticadas
      layout.tsx                  # Layout con sidebar + topbar + footer
      (dashboards)/index/         # Dashboard principal
      (app)/
        (ventas)/                 # POS, lista ventas, detalle venta
        (inventario)/             # Productos, catalogo, crear producto
        (hr)/                     # Vistas de cotizaciones, cobros, usuarios
        (invoice)/                # Vistas de facturacion
        (users)/                  # Vistas de clientes, proveedores, usuarios
        calendar/                 # Calendario
        perfil/                   # Perfil de usuario
    (auth)/                       # Paginas publicas
      modern-login/               # Login (funcional)
      modern-logout/              # Logout (funcional)

  components/
    common/                       # Componentes reutilizables del ERP
      Badge.tsx
      ConfirmModal.tsx
      DataTable.tsx
      EmptyState.tsx
      ErrorBoundary.tsx
      ErrorMessage.tsx
      ProtectedRoute.tsx
    layouts/                      # Layout del template (sidebar, topbar, etc.)
    client-wrapper/               # Wrappers para librerias (ApexChart, Iconify)
    PageBreadcrumb.tsx
    PageMeta.tsx
    PageWrapper.tsx

  config/
    constants.ts                  # Constantes del negocio (estados, tipos, monedas)
    env.ts                        # Variables de entorno

  context/
    AuthContext.tsx                # Estado de autenticacion + RBAC

  helpers/
    constants.ts                  # Constantes de la app (ACTUALIZAR: quitar "Tailwick")
    debounce.ts                   # Utilidad debounce

  types/
    erp/index.ts                  # Tipos manuales complementarios

  assets/
    css/                          # Estilos (themes.css = design system)
    images/                       # Logos, avatars, fondos
```

### Donde va cada cosa nueva

| Tipo de archivo | Ubicacion | Ejemplo |
|-----------------|-----------|---------|
| Pagina nueva | `src/app/(admin)/(app)/{seccion}/{vista}/index.tsx` | `(ventas)/cart/index.tsx` |
| Componente de pagina | `src/app/(admin)/(app)/{seccion}/{vista}/components/` | `cart/components/CartItems.tsx` |
| Componente reutilizable | `src/components/common/` | `FilterBar.tsx` |
| Hook custom | Al lado del componente que lo usa, o en `src/hooks/` si es global | `useDebounce.ts` |
| Constantes | `src/config/constants.ts` | Nuevos estados, mapeos |
| Tipos manuales | `src/types/erp/index.ts` | Solo si Orval no genera lo que necesitas |
| Tipos/hooks de API | NUNCA a mano → regenerar Orval | `pnpm orval` |

---

## 5. DESIGN SYSTEM — PALETA Y TIPOGRAFIA

> Fuente: DESIGN_SYSTEM.md + themes.css

### Colores

| Token | Color | Hex | Uso |
|-------|-------|-----|-----|
| `primary` | Terracota | `#D65A42` | CTAs, links activos, badges primarios |
| `brand-dark` | Negro Carbon | `#1A1A1A` | Titulos H1/H2, texto alto contraste |
| `brand-body` | Gris Pizarra | `#555555` | Texto cuerpo, labels, descripciones |
| `brand-surface` | Blanco Crema | `#F9F7F2` | Fondo general de pagina |
| `brand-border` | Gris Nube | `#E8E8E8` | Bordes de inputs, cards, divisores |
| `brand-accent` | Gris Topo | `#9E9188` | Iconos secundarios, decorativos |

### Tipografia

| Rol | Familia | Pesos |
|-----|---------|-------|
| Titulos (H1-H3) | Playfair Display | 600, 700 |
| Cuerpo y UI | Inter | 400, 500, 600 |

### Variables CSS (ya en themes.css)

```css
--color-primary: #D65A42;
--color-brand-dark: #1A1A1A;
--color-brand-body: #555555;
--color-brand-surface: #F9F7F2;
--color-brand-border: #E8E8E8;
--color-brand-accent: #9E9188;
--font-heading: 'Playfair Display', Georgia, serif;
--font-body: 'Inter', system-ui, sans-serif;
```

### Reglas de color

```
COLOR-01: Botones primarios: bg-primary text-white. Hover: 10% mas oscuro (#BF4F3A).
COLOR-02: Botones secundarios/outline: border-primary text-primary bg-transparent.
COLOR-03: Botones destructivos (eliminar, anular): bg-red-600 text-white.
COLOR-04: Links: text-primary. Hover: underline.
COLOR-05: Focus de inputs: ring-primary/50 border-primary.
COLOR-06: Fondo de pagina: bg-brand-surface (#F9F7F2) — NO gris/blanco puro.
COLOR-07: Cards: bg-white con shadow-sm y border border-brand-border.
COLOR-08: Texto principal: text-brand-dark. Texto secundario: text-brand-body.
COLOR-09: Dark mode: ya configurado en themes.css con [data-theme=dark].
COLOR-10: NUNCA usar colores hardcodeados. Usar las variables CSS o tokens de Tailwind.
```

---

## 6. MAPEO DE ESTADOS A COLORES (Badge)

Todos los estados del backend tienen un color consistente en todo el sistema:

```typescript
// src/config/constants.ts — agregar este mapeo

export const ESTADO_COLOR_MAP: Record<string, 'default' | 'success' | 'warning' | 'danger' | 'info'> = {
  // Cotizaciones
  borrador: 'default',
  vigente: 'info',
  aceptada: 'success',
  vencida: 'warning',
  rechazada: 'danger',

  // Ordenes de venta
  pendiente: 'warning',
  confirmada: 'info',
  parcial: 'info',
  completada: 'success',
  cancelada: 'danger',

  // Ventas
  // completada -> success (ya arriba)
  anulada: 'danger',

  // Comprobantes SUNAT
  aceptado: 'success',
  rechazado: 'danger',
  observado: 'warning',
  error: 'danger',
  pendiente_reenvio: 'warning',

  // Compras
  pendiente_aprobacion: 'warning',
  aprobada: 'info',
  enviada: 'info',
  recibida_parcial: 'warning',
  recibida: 'success',
  cerrada: 'default',

  // CxC / CxP
  vencido: 'danger',
  pagado: 'success',
  refinanciado: 'info',

  // Distribucion
  confirmado: 'info',
  despachado: 'info',
  en_ruta: 'info',
  entregado: 'success',
  devuelto: 'warning',

  // WhatsApp
  enviado: 'info',
  entregado: 'success',
  leido: 'success',
  fallido: 'danger',
  en_espera: 'warning',
} as const;
```

Uso:

```tsx
import { Badge } from '@/components/common/Badge';
import { ESTADO_COLOR_MAP } from '@/config/constants';

<Badge variant={ESTADO_COLOR_MAP[venta.estado] || 'default'}>
  {venta.estado_display || venta.estado}
</Badge>
```

---

## 7. PATRONES DE PAGINA (copiar para cada vista nueva)

### 7.1 Pagina de listado

```tsx
// src/app/(admin)/(app)/(ventas)/orders/index.tsx
import { useState } from 'react';
import { useVentasList } from '@/api/generated/ventas/ventas';
import { DataTable } from '@/components/common/DataTable';
import { Badge } from '@/components/common/Badge';
import { EmptyState } from '@/components/common/EmptyState';
import { ErrorMessage } from '@/components/common/ErrorMessage';
import { ESTADO_COLOR_MAP, PAGINATION } from '@/config/constants';
import PageBreadcrumb from '@/components/PageBreadcrumb';
import PageMeta from '@/components/PageMeta';

export default function VentasPage() {
  const [page, setPage] = useState(PAGINATION.DEFAULT_PAGE);
  const [search, setSearch] = useState('');

  const { data, isLoading, isError, error, refetch } = useVentasList({
    page,
    search: search || undefined,
  });

  const ventas = data?.data?.results ?? [];
  const totalCount = data?.data?.count ?? 0;

  return (
    <>
      <PageMeta title="Ventas" />
      <PageBreadcrumb title="Ventas" items={[{ label: 'Ventas' }]} />

      <div className="card">
        {/* Barra de busqueda y filtros */}
        <div className="card-body border-b border-brand-border">
          <div className="flex flex-col sm:flex-row gap-3">
            <input
              type="text"
              placeholder="Buscar por numero, cliente..."
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              className="form-input flex-1"
            />
            {/* Filtros adicionales aqui */}
          </div>
        </div>

        {/* Estado: Error */}
        {isError && <ErrorMessage error={error} onRetry={refetch} />}

        {/* Estado: Cargando */}
        {isLoading && (
          <DataTable
            columns={columns}
            data={[]}
            isLoading={true}
          />
        )}

        {/* Estado: Sin datos */}
        {!isLoading && !isError && ventas.length === 0 && (
          <EmptyState
            title="No hay ventas"
            description={search ? `No se encontraron ventas para "${search}"` : 'Aun no se han registrado ventas.'}
          />
        )}

        {/* Estado: Con datos */}
        {!isLoading && ventas.length > 0 && (
          <>
            <DataTable columns={columns} data={ventas} />
            {/* Paginacion */}
            <div className="card-body border-t border-brand-border">
              <div className="flex items-center justify-between">
                <span className="text-sm text-brand-body">
                  Mostrando {ventas.length} de {totalCount}
                </span>
                <div className="flex gap-2">
                  <button
                    onClick={() => setPage(p => Math.max(1, p - 1))}
                    disabled={page === 1}
                    className="btn btn-sm btn-outline"
                  >
                    Anterior
                  </button>
                  <button
                    onClick={() => setPage(p => p + 1)}
                    disabled={ventas.length < PAGINATION.DEFAULT_LIMIT}
                    className="btn btn-sm btn-outline"
                  >
                    Siguiente
                  </button>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </>
  );
}
```

### 7.2 Pagina de detalle

```tsx
export default function VentaDetallePage() {
  const { id } = useParams<{ id: string }>();
  const { data, isLoading, isError, error } = useVentasRetrieve(id!);

  if (isLoading) return <LoadingSkeleton />;
  if (isError) return <ErrorMessage error={error} />;
  if (!data?.data) return <EmptyState title="Venta no encontrada" />;

  const venta = data.data;

  return (
    <>
      <PageMeta title={`Venta ${venta.numero}`} />
      {/* ... contenido ... */}
    </>
  );
}
```

### 7.3 Formulario con mutation

```tsx
import { useForm } from 'react-hook-form';
import { useClientesCreate } from '@/api/generated/clientes/clientes';
import toast from 'react-hot-toast';

export default function CrearClienteForm({ onSuccess }: { onSuccess: () => void }) {
  const { register, handleSubmit, formState: { errors }, setError } = useForm();
  const crear = useClientesCreate();

  const onSubmit = async (formData: any) => {
    try {
      await crear.mutateAsync({ data: formData });
      toast.success('Cliente creado correctamente');
      onSuccess();
    } catch (err: any) {
      // Mapear errores del servidor a campos del formulario
      const serverErrors = err?.data?.errors || err?.data;
      if (serverErrors && typeof serverErrors === 'object') {
        Object.entries(serverErrors).forEach(([field, messages]) => {
          setError(field, {
            type: 'server',
            message: Array.isArray(messages) ? messages[0] : String(messages),
          });
        });
      } else {
        toast.error(err?.data?.detail || err?.data?.message || 'Error al crear cliente');
      }
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label htmlFor="razon_social" className="form-label">Razon Social</label>
        <input
          id="razon_social"
          {...register('razon_social', { required: 'Este campo es obligatorio' })}
          className={`form-input ${errors.razon_social ? 'border-red-500' : ''}`}
        />
        {errors.razon_social && (
          <p className="text-sm text-red-600 mt-1">{errors.razon_social.message as string}</p>
        )}
      </div>

      {/* ... mas campos ... */}

      <button
        type="submit"
        disabled={crear.isPending}
        className="btn bg-primary text-white hover:bg-primary/90 disabled:opacity-50"
      >
        {crear.isPending ? 'Guardando...' : 'Guardar Cliente'}
      </button>
    </form>
  );
}
```

---

## 8. COMPONENTES COMUNES (mejorar/crear)

### 8.1 DataTable — Mejorar el existente

El DataTable actual (`src/components/common/DataTable.tsx`) es basico. Mejorar con:
- Hover en filas (ya tiene)
- Skeleton loader (ya tiene)
- Empty state (ya tiene)
- **Agregar:** className prop para personalizar
- **NO agregar aun:** sorting, seleccion multiple, acciones en fila
  (cada tabla de pagina implementa sus propias acciones segun necesidad)

### 8.2 FilterBar — Crear nuevo

```tsx
// src/components/common/FilterBar.tsx
// Barra reutilizable con: busqueda (input), filtros (selects), boton CTA
// Props: onSearch, filters[], ctaLabel, onCta
// Los filtros se pasan como array de { key, label, options[] }
// Internamente usa debounce para busqueda
```

### 8.3 Pagination — Crear nuevo

```tsx
// src/components/common/Pagination.tsx
// Paginacion simple: "Mostrando X de Y" + botones Anterior/Siguiente
// Props: page, totalCount, pageSize, onPageChange
// NO crear paginacion numerada compleja — el patron Anterior/Siguiente es suficiente
// y funciona bien con la paginacion offset del backend
```

### 8.4 ConfirmModal — Ya existe, esta bien

### 8.5 MoneyDisplay — Crear helper

```typescript
// src/helpers/formatters.ts
export function formatMoney(amount: number | string, currency = 'PEN'): string {
  const num = typeof amount === 'string' ? parseFloat(amount) : amount;
  return new Intl.NumberFormat('es-PE', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(num);
}
// formatMoney(1234.5) → "S/ 1,234.50"

export function formatDate(dateStr: string): string {
  return new Intl.DateTimeFormat('es-PE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(new Date(dateStr));
}
// formatDate('2026-02-20') → "20/02/2026"

export function formatDateTime(dateStr: string): string {
  return new Intl.DateTimeFormat('es-PE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(dateStr));
}

export function formatDocNumber(serie: string, numero: number): string {
  return `${serie}-${String(numero).padStart(8, '0')}`;
}
// formatDocNumber('F001', 123) → "F001-00000123"
```

---

## 9. INTERACCIONES (Preline)

Preline maneja las interacciones JS del template. Las clases clave:

| Clase | Que hace | Uso |
|-------|----------|-----|
| `hs-dropdown` | Dropdown menu | Acciones de fila, filtros select |
| `hs-overlay` | Modal/drawer | Modales de formulario, confirmacion |
| `hs-tab` | Tabs | Navegacion dentro de una pagina |
| `hs-accordion` | Acordeon | Secciones colapsables |
| `hs-tooltip` | Tooltip | Ayuda contextual |

**Importante:** Preline necesita `HSStaticMethods.autoInit()` cuando el DOM cambia dinamicamente (React re-renders). Esto ya esta manejado en `ProvidersWrapper.tsx` con un `useEffect` en cambio de ruta.

Para modales programaticos (abrir/cerrar desde React state), NO depender de Preline:
usar `useState` + renderizado condicional + clases CSS de transicion.

---

## 10. UX OBLIGATORIA

```
UX-01: Toda accion exitosa → toast.success() (verde, 3 seg, auto-dismiss).
UX-02: Todo error de API → toast.error() con mensaje del backend.
UX-03: Botones de submit se deshabilitan mientras isPending (mutation).
UX-04: Tablas/listas muestran skeleton animado mientras isLoading.
UX-05: Formularios muestran errores inline debajo de cada campo erroneo.
UX-06: Montos SIEMPRE formateados: formatMoney() → "S/ 1,234.56".
UX-07: Fechas formateadas: formatDate() → "20/02/2026" (dd/mm/yyyy).
UX-08: Acciones destructivas (eliminar, anular) requieren ConfirmModal.
UX-09: NUNCA mostrar UUIDs al usuario. Usar numeros de documento o nombres.
UX-10: Al crear algo exitosamente, cerrar modal/redirigir + invalidar cache.
UX-11: Empty states con mensaje descriptivo y CTA cuando aplique.
UX-12: Breadcrumb en toda pagina: Dashboard > Modulo > Pagina actual.
UX-13: Inputs de busqueda con debounce de 300ms.
UX-14: Texto de la interfaz en espanol (botones, labels, mensajes).
UX-15: NUNCA dejar texto del template en ingles visible al usuario
       ("Tailwick", "Paula Keenan", "Themesdesign", etc.).
```

---

## 11. ACCESIBILIDAD (minima)

```
A11Y-01: Todo <img> tiene alt descriptivo.
A11Y-02: Botones con solo icono tienen aria-label.
A11Y-03: Inputs tienen <label> con htmlFor (o aria-label si no hay label visible).
A11Y-04: Tablas usan <thead>, <tbody>, <th scope="col">.
A11Y-05: Alertas y errores usan role="alert".
A11Y-06: Inputs de precio/cantidad usan inputMode="decimal" para movil.
```

---

## 12. REGENERAR ORVAL

Cuando el backend agrega o modifica endpoints:

```bash
# 1. Backend genera nuevo schema
cd ../Jsoluciones-be
python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml

# 2. Frontend regenera hooks y tipos
cd ../Jsoluciones-fe
pnpm orval

# 3. Verificar que compila
pnpm tsc --noEmit

# 4. Commit
git add src/api/generated/ src/api/models/ openapi-schema.yaml
git commit -m "regen: actualizar tipos y hooks desde OpenAPI"
```

**NUNCA editar archivos en `src/api/generated/` o `src/api/models/` a mano.**
Si los tipos generados no son correctos, el problema esta en el backend
(serializers, drf-spectacular annotations). Corregir alla y regenerar.

---

## 13. CHECKLIST ANTES DE CADA VISTA

- [ ] Existe hook de Orval para los endpoints que necesito?
- [ ] Manejo los 3 estados (loading, error, datos)?
- [ ] Los montos usan formatMoney()?
- [ ] Las fechas usan formatDate()?
- [ ] Los estados usan Badge con ESTADO_COLOR_MAP?
- [ ] La ruta esta protegida con ProtectedRoute?
- [ ] Los textos visibles estan en espanol?
- [ ] No quedan restos del template (nombres, textos en ingles)?
- [ ] El toast se muestra en exito y error?
- [ ] Las acciones destructivas piden confirmacion?
- [ ] El formulario valida campos requeridos antes de enviar?
- [ ] La busqueda tiene debounce?
- [ ] Se ve bien en la paleta JSoluciones (terracota, crema, etc.)?

---

## 14. LO QUE NO SE HACE (ANTI-PATRONES)

```
NO-01: NO crear servicios api manuales (ya no usar src/services/api.ts ni authService.ts).
       Todo pasa por Orval hooks.
NO-02: NO duplicar constantes. Un solo lugar: src/config/constants.ts.
NO-03: NO crear componentes wrapper para cosas que Tailwind resuelve.
NO-04: NO instalar librerias de UI (MUI, Ant, etc.).
NO-05: NO escribir CSS custom si Tailwind lo resuelve.
NO-06: NO crear hooks custom que solo envuelven un hook de Orval sin agregar logica.
NO-07: NO hardcodear URLs de API. Todo sale de Orval + proxy de Vite.
NO-08: NO crear paginas sin los 3 estados (loading, error, datos).
NO-09: NO dejar console.log en codigo que va a produccion.
NO-10: NO inventar campos que el backend no retorna.
```

---

## 15. BUGS CONOCIDOS A CORREGIR

Estos son problemas heredados del template que deben corregirse:

| # | Problema | Archivo | Solucion |
|---|----------|---------|----------|
| 1 | `<title>` dice "tailwick" | `index.html` | Cambiar a "JSoluciones ERP" |
| 2 | PageMeta suffix dice "Tailwick" | `PageMeta.tsx` | Cambiar a "JSoluciones" |
| 3 | Breadcrumb root dice "Tailwick" | `PageBreadcrumb.tsx` | Cambiar a "JSoluciones" |
| 4 | Topbar profile: "Paula Keenan / CEO & Founder" | `topbar/index.tsx` | Usar datos de AuthContext (user.first_name, user.rol) |
| 5 | Topbar Sign Out va a `/basic-logout` | `topbar/index.tsx` | Cambiar a `/logout` |
| 6 | helpers/constants.ts: appName='Tailwick' | `helpers/constants.ts` | Cambiar a 'JSoluciones' |
| 7 | Register page footer: "2025 Tailwick. Crafted by Themesdesign" | register page | Cambiar a JSoluciones |
| 8 | 404 page texto en ingles | 404 page | Traducir a espanol |
| 9 | Topbar notificaciones hardcodeadas en ingles | topbar | Eliminar datos mock, dejar vacio o conectar |
| 10 | METODO_PAGO_LABELS duplicado en 4+ archivos | varios | Centralizar en constants.ts |

---

*v3 — Feb 2026. Alineada con estado real del proyecto. Sin sobreingenieria.*
