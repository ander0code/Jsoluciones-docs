# JSOLUCIONES ERP — REGLAS DE FRONTEND

> Eres un desarrollador senior de React/TypeScript.
> Este documento define los patrones, convenciones y reglas no negociables del frontend.
> Aplica unicamente a Jsoluciones-fe/. NO a Amatista-fe/.

---

## 1. STACK (NO CAMBIAR)

| Tecnologia | Version | Proposito |
|-----------|---------|-----------|
| React | 19 | Framework UI |
| TypeScript | 5.8 | Tipado estatico |
| Vite | 7 | Build tool + dev server con proxy |
| Tailwind CSS | 4 | Estilos (via @tailwindcss/vite) |
| Preline | 3.2 | Interacciones JS (dropdowns, modales, tabs, acordeones) |
| TanStack React Query | 5 | Data fetching, cache, mutations |
| Orval | 8 | Genera hooks y tipos desde OpenAPI |
| react-hot-toast | - | Toasts/notificaciones |
| react-apexcharts | - | Graficos dashboard |
| react-hook-form | - | Formularios complejos |
| lucide-react / react-icons | - | Iconos |
| pnpm | - | Package manager |

**NO agregar:**
- Zustand / Redux / MobX (AuthContext es suficiente para estado global)
- Axios (Orval usa customFetch con fetch nativo)
- dayjs / moment (usar Intl.DateTimeFormat)
- MUI, Ant Design, Chakra, o cualquier libreria de componentes (Tailwind + Preline es suficiente)

---

## 2. REGLAS ESTRICTAS

### Arquitectura

```
FRONT-01: Orval genera los hooks y tipos. NUNCA escribir tipos de API a mano.
          Los tipos en src/types/erp/index.ts son SOLO para uso interno del frontend
          cuando los tipos Orval no cubren un caso especifico.

FRONT-02: NUNCA escribir fetch() a mano para endpoints del backend.
          Siempre usar los hooks generados por Orval (src/api/generated/).
          La unica excepcion es fetchMe() en AuthContext (bootstrap de auth).

FRONT-03: El frontend se adapta al backend, NO al reves.
          Si el backend retorna un campo, el frontend lo usa tal cual.
          Si falta un campo, se pide al backend — no se inventa en el front.

FRONT-04: Toda pagina que consume datos DEBE manejar 3 estados: loading, error, datos.
          Usar los estados de React Query (isLoading, isError, data).

FRONT-05: Estado del servidor = React Query (via Orval hooks).
          Estado global de UI = AuthContext.
          Estado local de UI = useState/useReducer.
          NO hay mas capas de estado.
```

### Formularios

```
FRONT-06: Formularios simples (busqueda, filtros) -> useState directo.
          Formularios complejos (POS, crear producto, cotizacion, emitir comprobante)
          -> react-hook-form con validacion.

FRONT-07: Validacion client-side es UX, NO seguridad. El backend SIEMPRE valida.
          Campos requeridos, formatos (RUC 11 digitos, DNI 8 digitos), rangos (precio > 0).

FRONT-08: Errores del servidor se muestran tal cual vienen del backend.
          NO traducir ni reformular mensajes del backend.
```

### Seguridad

```
FRONT-09: Toda ruta protegida usa ProtectedRoute con verificacion de auth.
          Las rutas que requieren permiso especifico pasan el prop requiredPermission.

FRONT-10: NUNCA mostrar IDs de la DB (UUIDs) al usuario en la interfaz.
          Usar numeros de documento (F001-00000123), nombres, o SKUs.

FRONT-11: NUNCA renderizar HTML del servidor sin sanitizar.
```

### Performance

```
FRONT-12: React Query maneja el cache.
          staleTime para datos estaticos (categorias, roles): 30 min.
          staleTime para datos dinamicos (stock, ventas del dia): 30 seg.

FRONT-13: Paginacion es del servidor (20 por pagina). NUNCA cargar todo y paginar en FE.

FRONT-14: Busquedas con debounce de 300ms minimo. NUNCA fetch en cada keystroke.
```

---

## 3. COMO CONSUMIR LA API

### GET con hook de Orval

```typescript
// CORRECTO
import { useInventarioProductosList } from '@/api/generated/inventario/inventario';

function ProductosPage() {
  const { data, isLoading, isError, error, refetch } = useInventarioProductosList({
    page: 1,
    search: 'laptop',
  });

  const productos = data?.data?.results ?? [];
  const totalCount = data?.data?.count ?? 0;
}
```

```typescript
// INCORRECTO — NUNCA hacer esto
const res = await fetch('/api/v1/inventario/productos/');
const res = await axios.get('/api/v1/inventario/productos/');
```

### Mutations (crear, editar, eliminar)

```typescript
import { useVentasPosCreate } from '@/api/generated/ventas/ventas';
import { useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';

function usePOSVenta() {
  const queryClient = useQueryClient();

  return useVentasPosCreate({
    mutation: {
      onSuccess: () => {
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

### Acceder a los datos del customFetch

El customFetch en `src/api/fetcher.ts` retorna `{ data, status, headers }`:
- Para listados: `data.data.results`, `data.data.count`
- Para detalle: `data.data` (el objeto directo)

---

## 4. ESTRUCTURA DE ARCHIVOS

```
src/
  api/
    fetcher.ts                -> Custom fetch con JWT (NO tocar salvo bugs)
    generated/                -> AUTO-GENERADO por Orval (NO editar a mano)
    models/                   -> AUTO-GENERADO por Orval (NO editar a mano)

  app/
    (admin)/
      layout.tsx              -> Layout con sidebar + topbar + footer
      (dashboards)/index/     -> Dashboard principal
      (app)/
        (ventas)/
        (inventario)/
        (hr)/
        (invoice)/
        (users)/
        (whatsapp)/
        (finanzas)/
        (distribucion)/
        (compras)/
        (configuracion)/
        perfil/
    (auth)/
      modern-login/
      modern-logout/

  components/
    common/
      Badge.tsx
      ConfirmModal.tsx
      DataTable.tsx
      EmptyState.tsx
      ErrorBoundary.tsx
      ErrorMessage.tsx
      ProtectedRoute.tsx
    layouts/

  config/
    constants.ts              -> ESTADO_COLOR_MAP, PAGINATION, constantes del negocio
    env.ts                    -> Variables de entorno

  context/
    AuthContext.tsx            -> Estado de autenticacion + RBAC

  helpers/
    constants.ts              -> appName, etc.
    debounce.ts
    formatters.ts             -> formatMoney, formatDate, formatDateTime, formatDocNumber

  types/
    erp/index.ts              -> Tipos manuales complementarios
```

### Donde va cada archivo nuevo

| Tipo | Ubicacion |
|------|-----------|
| Pagina nueva | `src/app/(admin)/(app)/{seccion}/{vista}/index.tsx` |
| Componente de pagina | `src/app/(admin)/(app)/{seccion}/{vista}/components/` |
| Componente reutilizable | `src/components/common/` |
| Hook custom global | `src/hooks/` |
| Constantes | `src/config/constants.ts` |
| Tipos manuales | `src/types/erp/index.ts` |
| Tipos/hooks de API | NUNCA a mano -> regenerar Orval |

---

## 5. DESIGN SYSTEM

### Paleta JSoluciones

| Token | Color | Hex |
|-------|-------|-----|
| `primary` | Terracota | `#D65A42` |
| `brand-dark` | Negro Carbon | `#1A1A1A` |
| `brand-body` | Gris Pizarra | `#555555` |
| `brand-surface` | Blanco Crema | `#F9F7F2` |
| `brand-border` | Gris Nube | `#E8E8E8` |
| `brand-accent` | Gris Topo | `#9E9188` |

Tipografia: Playfair Display (titulos H1-H3) + Inter (cuerpo y UI).

### Reglas de Color

```
COLOR-01: Botones primarios: bg-primary text-white. Hover: #BF4F3A.
COLOR-02: Botones secundarios: border-primary text-primary bg-transparent.
COLOR-03: Botones destructivos: bg-red-600 text-white.
COLOR-04: Links: text-primary. Hover: underline.
COLOR-05: Focus de inputs: ring-primary/50 border-primary.
COLOR-06: Fondo de pagina: bg-brand-surface (#F9F7F2). NO gris/blanco puro.
COLOR-07: Cards: bg-white con shadow-sm y border border-brand-border.
COLOR-08: Texto principal: text-brand-dark. Texto secundario: text-brand-body.
COLOR-09: NUNCA usar colores hardcodeados. Usar variables CSS o tokens Tailwind.
```

### Mapeo Estados -> Badge

```typescript
export const ESTADO_COLOR_MAP: Record<string, 'default' | 'success' | 'warning' | 'danger' | 'info'> = {
  // Cotizaciones
  borrador: 'default', vigente: 'info', aceptada: 'success', vencida: 'warning', rechazada: 'danger',
  // Ordenes
  pendiente: 'warning', confirmada: 'info', parcial: 'info', completada: 'success', cancelada: 'danger',
  // Ventas
  anulada: 'danger',
  // Comprobantes SUNAT
  aceptado: 'success', rechazado: 'danger', observado: 'warning', error: 'danger',
  // Distribucion
  despachado: 'info', en_ruta: 'info', entregado: 'success', devuelto: 'warning',
  // WhatsApp
  enviado: 'info', fallido: 'danger', en_espera: 'warning', leido: 'success',
};
```

---

## 6. PATRON DE PAGINA DE LISTADO

```tsx
export default function VentasPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');

  const { data, isLoading, isError, error, refetch } = useVentasList({
    page, search: search || undefined,
  });

  const ventas = data?.data?.results ?? [];
  const totalCount = data?.data?.count ?? 0;

  return (
    <>
      <PageMeta title="Ventas" />
      <PageBreadcrumb title="Ventas" items={[{ label: 'Ventas' }]} />
      <div className="card">
        {/* Filtros */}
        <div className="card-body border-b border-brand-border">
          <input type="text" placeholder="Buscar..." value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            className="form-input" />
        </div>

        {isError && <ErrorMessage error={error} onRetry={refetch} />}
        {isLoading && <DataTable columns={columns} data={[]} isLoading />}
        {!isLoading && !isError && ventas.length === 0 && <EmptyState title="No hay ventas" />}
        {!isLoading && ventas.length > 0 && (
          <>
            <DataTable columns={columns} data={ventas} />
            {/* Paginacion */}
            <div className="card-body border-t border-brand-border flex items-center justify-between">
              <span className="text-sm text-brand-body">Mostrando {ventas.length} de {totalCount}</span>
              <div className="flex gap-2">
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
                  className="btn btn-sm btn-outline">Anterior</button>
                <button onClick={() => setPage(p => p + 1)} disabled={ventas.length < 20}
                  className="btn btn-sm btn-outline">Siguiente</button>
              </div>
            </div>
          </>
        )}
      </div>
    </>
  );
}
```

---

## 7. HELPERS DE FORMATO (src/helpers/formatters.ts)

```typescript
// Dinero
formatMoney(1234.5) -> "S/ 1,234.50"
formatMoney(1234.5, 'USD') -> "$ 1,234.50"

// Fechas
formatDate('2026-02-20') -> "20/02/2026"
formatDateTime('2026-02-20T10:30:00') -> "20/02/2026, 10:30"

// Numero de documento
formatDocNumber('F001', 123) -> "F001-00000123"
```

---

## 8. REGENERAR ORVAL

Cuando el backend agrega o modifica endpoints:

```bash
# 1. Backend genera nuevo schema
cd Jsoluciones-be/
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

NUNCA editar archivos en `src/api/generated/` o `src/api/models/` a mano.
Si los tipos generados son incorrectos, el problema esta en el backend (serializers, drf-spectacular). Corregir alla y regenerar.

---

## 9. UX OBLIGATORIA

```
UX-01: Toda accion exitosa -> toast.success() (verde, 3 seg, auto-dismiss).
UX-02: Todo error de API -> toast.error() con mensaje del backend.
UX-03: Botones de submit se deshabilitan mientras isPending.
UX-04: Tablas muestran skeleton animado mientras isLoading.
UX-05: Formularios muestran errores inline debajo de cada campo erroneo.
UX-06: Montos SIEMPRE formateados: formatMoney() -> "S/ 1,234.56".
UX-07: Fechas: formatDate() -> "20/02/2026" (dd/mm/yyyy).
UX-08: Acciones destructivas requieren ConfirmModal.
UX-09: NUNCA mostrar UUIDs al usuario. Usar numeros de documento o nombres.
UX-10: Al crear algo exitosamente, cerrar modal/redirigir + invalidar cache.
UX-11: Empty states con mensaje descriptivo y CTA cuando aplique.
UX-12: Breadcrumb en toda pagina.
UX-13: Inputs de busqueda con debounce de 300ms.
UX-14: Texto de la interfaz en espanol.
UX-15: NUNCA dejar texto del template en ingles visible al usuario (Tailwick, etc.).
```

---

## 10. ANTI-PATRONES (NO HACER)

```
NO-01: NO crear servicios api manuales. Todo pasa por Orval hooks.
       src/services/ no existe — no crear.

NO-02: NO duplicar constantes. Un solo lugar: src/config/constants.ts.

NO-03: NO crear componentes wrapper para cosas que Tailwind resuelve.
       MAL:  <FlexRow gap={4}><Text bold>Hola</Text></FlexRow>
       BIEN: <div className="flex gap-4"><span className="font-bold">Hola</span></div>

NO-04: NO instalar librerias de UI (MUI, Ant, etc.).

NO-05: NO escribir CSS custom si Tailwind lo resuelve.

NO-06: NO crear hooks custom que solo envuelven un hook de Orval sin agregar logica.

NO-07: NO hardcodear URLs de API. Todo sale de Orval + proxy de Vite.

NO-08: NO crear paginas sin los 3 estados (loading, error, datos).

NO-09: NO dejar console.log en codigo que va a produccion.

NO-10: NO inventar campos que el backend no retorna.
```

---

## 11. CHECKLIST ANTES DE CADA VISTA

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
