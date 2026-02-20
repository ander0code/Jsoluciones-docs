# JSOLUCIONES ERP — PROCESOS DEL FRONTEND v2

> Version 2. Alineada con el estado real del proyecto (Feb 2026).
> Reemplaza v1. Refleja stack actual, Orval como unica fuente de hooks/tipos,
> y las vistas que ya existen vs las que faltan.
> Leer SIEMPRE junto con 04_REGLAS_FRONTEND_v3.md.

---

## 1. CONTEXTO ACTUAL

### 1.1 Que es el proyecto

JSoluciones es un ERP para empresas peruanas (single-tenant). El frontend es una SPA
en React 19 + TypeScript que consume una API REST Django via hooks auto-generados por Orval.
El template Tailwick (React) se usa como base visual y ya ha sido parcialmente adaptado.

### 1.2 Que ya existe (NO recrear)

| Componente | Estado | Ubicacion |
|-----------|--------|-----------|
| Login/Logout | Funcional con API | `(auth)/modern-login/`, `modern-logout/` |
| AuthContext + RBAC | Funcional | `context/AuthContext.tsx` |
| ProtectedRoute | Funcional | `components/common/ProtectedRoute.tsx` |
| Layout (sidebar+topbar+footer) | Funcional (con restos template) | `(admin)/layout.tsx` |
| Dashboard con KPIs reales | Funcional | `(dashboards)/index/` |
| Lista ventas + detalle | Funcional | `(ventas)/orders/`, `order-overview/` |
| Lista productos + detalle + catalogo | Funcional | `product-list/`, `product-overview/`, `product-grid/` |
| Lista clientes | Funcional (solo lectura) | `(users)/users-list/` |
| Lista proveedores | Funcional (solo lectura) | Comparte componente con clientes |
| Lista cotizaciones | Funcional (solo lectura) | `(hr)/sales-estimates/` |
| Lista comprobantes + emision | Funcional | `(invoice)/list/`, `add-new/` |
| Lista CxC | Funcional (solo lectura) | `(hr)/sales-payments/` |
| Lista usuarios | Funcional (solo lectura) | `(hr)/employee/` |
| Perfil usuario | Funcional | `perfil/` |
| Orval hooks + tipos (14 modulos) | Generados | `api/generated/`, `api/models/` |
| DataTable, Badge, ConfirmModal, EmptyState, ErrorBoundary, ErrorMessage | Basicos | `components/common/` |

### 1.3 Stack real (NO cambiar)

| Tecnologia | Version | Como se usa |
|-----------|---------|-------------|
| React | 19.1 | Framework UI |
| TypeScript | 5.8 | Tipado |
| Vite | 7.1 | Build + dev proxy (`/api` → Django 8000) |
| Tailwind CSS | 4 | Estilos (via @tailwindcss/vite) |
| Preline | 3.2 | Dropdowns, modales, tabs (JS del template) |
| TanStack React Query | 5 | Cache + data fetching (via Orval hooks) |
| Orval | 8 | Genera hooks y tipos desde openapi-schema.yaml |
| react-hot-toast | - | Toasts |
| react-apexcharts | - | Graficos |
| react-flatpickr | - | Date picker |
| lucide-react / react-icons / @iconify/react | - | Iconos |
| react-hook-form | - | Formularios complejos (AGREGAR) |
| pnpm | - | Package manager |

**NO se usa:** Zustand, Axios (excepto legacy), dayjs, idb, Redux.

### 1.4 Como se conecta con el backend

```
Orval genera hooks desde openapi-schema.yaml
  → Los hooks usan customFetch (src/api/fetcher.ts)
    → customFetch usa fetch() nativo
      → Inyecta JWT Bearer token desde localStorage
      → Maneja refresh automatico en 401
      → Redirige a /login si refresh falla
  → Vite proxy reenvía /api/* a http://127.0.0.1:8000
```

**Formato de respuesta del backend:**

```
Listado:  { count, next, previous, results[] }
Detalle:  { id, campo1, campo2, ... }
Error:    { detail: "mensaje" } o { message: "msg", errors: { campo: ["error"] } }
```

**Formato de customFetch wrapper:**
```
Retorna: { data: <respuesta>, status: number, headers: Headers }
Desde un hook: data.data.results (listado) o data.data (detalle)
```

---

## 2. VISTAS QUE FALTAN (en orden de prioridad)

### PRIORIDAD 1 — Completar flujo core de ventas

Estas vistas ya EXISTEN pero les falta funcionalidad de escritura (crear, editar, eliminar).
Los hooks de Orval para las mutations ya estan generados.

| # | Vista | Ruta actual | Que falta | Endpoint mutation |
|---|-------|------------|-----------|-------------------|
| 1 | **POS (Punto de Venta)** | `/ventas/pos` (cart/) | Conectar a API. Es 100% mock. La vista mas critica. | `POST /ventas/pos/` |
| 2 | **Crear producto** | `/inventario/productos/crear` | Conectar form submit a API | `POST /inventario/productos/` |
| 3 | **Editar producto** | No existe | Crear vista o modal | `PATCH /inventario/productos/{id}/` |
| 4 | **Crear/Editar cliente** | Botones van a `#` | Crear modal o pagina | `POST /clientes/`, `PATCH /clientes/{id}/` |
| 5 | **Crear/Editar proveedor** | Botones van a `#` | Crear modal o pagina | `POST /proveedores/`, `PATCH /proveedores/{id}/` |
| 6 | **Anular venta** | Detalle venta sin boton | Agregar boton + confirmacion | `POST /ventas/{id}/anular/` |

### PRIORIDAD 2 — Vistas de inventario que faltan

| # | Vista | Ruta | Template base | Endpoint |
|---|-------|------|---------------|----------|
| 7 | **Categorias** | `/inventario/categorias` | DataTable + ModalForm | `GET/POST /inventario/categorias/` |
| 8 | **Almacenes** | `/inventario/almacenes` | DataTable + ModalForm | `GET/POST /inventario/almacenes/` |
| 9 | **Stock por almacen** | `/inventario/stock` | DataTable read-only | `GET /inventario/stock/` |
| 10 | **Movimientos de stock** | `/inventario/movimientos` | DataTable + filtros | `GET /inventario/movimientos/` |
| 11 | **Ajuste de stock** | Modal en movimientos | ModalForm | `POST /inventario/movimientos/ajuste/` |

### PRIORIDAD 3 — Completar facturacion y ventas

| # | Vista | Ruta | Template base | Endpoint |
|---|-------|------|---------------|----------|
| 12 | **Ordenes de venta** | `/ventas/ordenes` | DataTable | `GET/POST /ventas/ordenes/` |
| 13 | **Convertir cotizacion → orden** | Accion en cotizaciones | Boton + confirm | `POST /cotizaciones/{id}/convertir-orden/` |
| 14 | **Convertir orden → venta** | Accion en ordenes | Boton + confirm | `POST /ordenes/{id}/convertir-venta/` |
| 15 | **Cajas (apertura/cierre)** | `/ventas/cajas` | DataTable + acciones | `POST /cajas/abrir/`, `POST /cajas/{id}/cerrar/` |
| 16 | **Notas credito/debito** | `/facturacion/notas` | DataTable + form | `POST /facturacion/notas/crear/` |
| 17 | **Detalle comprobante** | `/facturacion/comprobantes/:id` | Vista detalle | `GET /facturacion/comprobantes/{id}/` |

### PRIORIDAD 4 — Modulos secundarios (backend completo, frontend = 0)

| # | Modulo | Vistas minimas | Endpoints |
|---|--------|---------------|-----------|
| 18 | **Compras** | OC lista, OC detalle, aprobar/enviar/cancelar, recepciones | `/compras/ordenes/`, acciones |
| 19 | **Finanzas** | CxC, CxP, registrar cobro, registrar pago | `/finanzas/cuentas-cobrar/`, `/cobros/` |
| 20 | **Distribucion** | Pedidos lista, asignar, despachar, seguimiento | `/distribucion/pedidos/`, acciones |
| 21 | **Configuracion** | Empresa (editar), Roles (ver), Permisos (ver) | `/empresa/`, `/usuarios/roles/` |

### PRIORIDAD 5 — Nice-to-have

| # | Vista | Notas |
|---|-------|-------|
| 22 | WhatsApp config + plantillas | Backend es stub, solo UI cuando Meta API este lista |
| 23 | Reportes export (Excel/PDF) | Backend es stub |
| 24 | Calendario de vencimientos | Conectar FullCalendar a fechas de CxC/CxP |

---

## 3. ESPECIFICACION DEL POS (vista mas critica)

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ [Buscar productos...]                    [Cliente: Varios ▼] │
├─────────────────────────────┬────────────────────────────────┤
│                             │ CARRITO                        │
│  PRODUCTOS (Grid)           │                                │
│  ┌─────┐ ┌─────┐ ┌─────┐   │  Laptop HP ............. S/2,500│
│  │ IMG │ │ IMG │ │ IMG │   │  qty: 1  [+][-]    x   │
│  │nom. │ │nom. │ │nom. │   │                                │
│  │S/XX │ │S/XX │ │S/XX │   │  Mouse Logi ........... S/ 150│
│  └─────┘ └─────┘ └─────┘   │  qty: 2  [+][-]    x   │
│  ┌─────┐ ┌─────┐ ┌─────┐   │                                │
│  │ ... │ │ ... │ │ ... │   │ ─────────────────────────────  │
│  └─────┘ └─────┘ └─────┘   │  Subtotal:        S/ 2,650.00 │
│                             │  IGV (18%):       S/   477.00 │
│                             │  TOTAL:           S/ 3,127.00 │
│                             │                                │
│                             │  Metodo: [Efectivo ▼]          │
│                             │                                │
│                             │  ┌────────────────────────────┐│
│                             │  │   COBRAR S/ 3,127.00       ││
│                             │  └────────────────────────────┘│
└─────────────────────────────┴────────────────────────────────┘
```

### Flujo de datos

```
1. Buscar producto → GET /inventario/productos/buscar/?q=... (con debounce)
   O click en grid de productos frecuentes

2. Agregar al carrito → estado local (useState)
   - Si ya existe: incrementar cantidad
   - Si no: agregar con cantidad 1, precio del producto
   - Validar: cantidad <= stock disponible

3. Seleccionar cliente → GET /clientes/buscar/?q=... (con debounce)
   - Default: "Varios" (null en el payload)
   - Para factura: obligatorio seleccionar cliente con RUC

4. Calcular totales → derivado del estado (NO en state separado)
   subtotal = sum(item.cantidad * item.precio_unitario)
   igv = subtotal * 0.18
   total = subtotal + igv

5. Cobrar → POST /ventas/pos/
   Payload:
   {
     "cliente_id": "uuid" | null,
     "tipo_comprobante": "03",  // boleta default
     "metodo_pago": "efectivo",
     "observaciones": "",
     "items": [
       {
         "producto_id": "uuid",
         "cantidad": 2,
         "precio_unitario": "150.00",
         "descuento": "0.00"
       }
     ]
   }

6. Exito → toast.success + modal con numero de comprobante + boton imprimir
   → Limpiar carrito
   → Invalidar queries: ventas, inventario (stock cambio)

7. Error → toast.error con mensaje del backend
   (ej: "Stock insuficiente para Laptop HP. Disponible: 3, solicitado: 5")
```

### Componentes del POS

| Componente | Responsabilidad |
|-----------|----------------|
| `POSPage` | Layout 2 columnas, estado del carrito, submit |
| `ProductSearch` | Input busqueda + dropdown resultados |
| `ProductGrid` | Grid de productos frecuentes (touch-friendly) |
| `CartItemList` | Lista de items con qty editable |
| `CartSummary` | Subtotal, IGV, total, metodo pago, boton cobrar |
| `ClienteSelector` | Busqueda de cliente con opcion "Varios" |

### Lo que NO incluir en v1 del POS

- Teclado numerico en pantalla
- Lector de codigo de barras (funciona si el scanner envia texto al input)
- Descuentos por item (agregar despues)
- Multiples metodos de pago en una venta (agregar despues)
- Modo offline / IndexedDB
- Impresion directa (usar link al PDF por ahora)

---

## 4. COMO CREAR UNA VISTA NUEVA (paso a paso)

### Paso 1: Verificar que el hook de Orval existe

```bash
# Buscar el hook que necesitas
grep -r "useVentasPosCreate\|useClientesCreate" src/api/generated/
```

Si no existe, regenerar Orval:
```bash
pnpm orval
```

### Paso 2: Crear el archivo de pagina

```
src/app/(admin)/(app)/(ventas)/nueva-vista/
  index.tsx            ← Pagina principal
  components/
    MiComponente.tsx   ← Componentes especificos de esta pagina
```

### Paso 3: Seguir el patron de pagina

Para listados → ver seccion 7.1 de 04_REGLAS_FRONTEND_v3.md
Para detalle → ver seccion 7.2
Para formularios → ver seccion 7.3

### Paso 4: Agregar ruta al router

Verificar que la ruta este registrada en el sistema de rutas de la app.
Las rutas se definen por convencion de carpetas en `src/app/`.

### Paso 5: Agregar al menu del sidebar

Editar `src/components/layouts/SideNav/menu.ts` para agregar el item
con el permiso requerido.

### Paso 6: Verificar

```bash
# Compilar sin errores
pnpm tsc --noEmit

# Verificar en navegador
pnpm dev
```

---

## 5. COMPONENTES A CREAR (solo cuando se necesiten)

NO crear componentes "por si acaso". Crear solo cuando una vista lo requiera.

### 5.1 FilterBar (crear con PRIORIDAD 1)

Barra de filtros reutilizable. Necesaria para todas las listas.

```tsx
interface FilterBarProps {
  onSearch: (term: string) => void;
  searchPlaceholder?: string;
  filters?: {
    key: string;
    label: string;
    options: { value: string; label: string }[];
    value: string;
    onChange: (value: string) => void;
  }[];
  ctaLabel?: string;
  onCta?: () => void;
}
```

### 5.2 Pagination (crear con PRIORIDAD 1)

```tsx
interface PaginationProps {
  page: number;
  totalCount: number;
  pageSize?: number; // default 20
  onPageChange: (page: number) => void;
}
```

### 5.3 FormModal (crear con PRIORIDAD 2)

Modal generico con formulario. Para CRUD de entidades simples (categorias, almacenes, clientes).

```tsx
interface FormModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode; // Campos del formulario
  onSubmit: () => void;
  isSubmitting: boolean;
  submitLabel?: string;
}
```

### 5.4 ClienteSelector (crear con PRIORIDAD 1 — necesario para POS)

Buscador de clientes con debounce y opcion "Varios".

### 5.5 ProductoSelector (crear con PRIORIDAD 1 — necesario para POS)

Buscador de productos con debounce, muestra stock disponible.

### 5.6 formatters.ts (crear con PRIORIDAD 1)

Funciones de formato: formatMoney, formatDate, formatDateTime, formatDocNumber.
Ver seccion 8 de 04_REGLAS_FRONTEND_v3.md.

---

## 6. PERMISOS Y NAVEGACION POR ROL

La tabla de permisos por rol esta definida en 04_REGLAS_FRONTEND_v3.md y no cambia.
El sidebar filtra items segun `user.permisos` del AuthContext.

Implementacion actual en `src/components/layouts/SideNav/menu.ts`:
- El menu tiene items del ERP + items del template original.
- **Pendiente:** Limpiar items del template que no corresponden al ERP.
- **Pendiente:** Agregar filtrado por permisos (actualmente muestra todo).

---

## 7. LIMPIEZA PENDIENTE DEL TEMPLATE

Estas tareas se pueden hacer en paralelo con las vistas nuevas:

| # | Tarea | Archivo(s) | Impacto |
|---|-------|-----------|---------|
| 1 | Cambiar `<title>` a "JSoluciones ERP" | `index.html` | Visual |
| 2 | Cambiar suffix PageMeta | `PageMeta.tsx` | Visual |
| 3 | Cambiar root breadcrumb | `PageBreadcrumb.tsx` | Visual |
| 4 | Topbar: user real del AuthContext | `topbar/index.tsx` | Visual |
| 5 | Topbar: Sign Out → `/logout` | `topbar/index.tsx` | Funcional |
| 6 | helpers/constants: appName → 'JSoluciones' | `helpers/constants.ts` | Config |
| 7 | Limpiar menu sidebar (quitar Template -) | `SideNav/menu.ts` | Navegacion |
| 8 | Centralizar METODO_PAGO_LABELS | `config/constants.ts` | Codigo |
| 9 | Eliminar paginas de template no usadas | Varios | Peso del bundle |

---

## 8. DEPENDENCIA A INSTALAR

Solo UNA dependencia nueva es necesaria:

```bash
pnpm add react-hook-form
```

**Justificacion:** Formularios del POS, crear producto, crear cliente, emitir comprobante
requieren validacion avanzada, manejo de errores del servidor por campo, y performance
(no re-renderizar 50 inputs en cada keystroke).

**NO instalar:** Zustand, dayjs, idb, axios (ya hay alternativas en el proyecto).

---

*v2 — Feb 2026. Refleja estado real. Sin sobreingenieria.*
