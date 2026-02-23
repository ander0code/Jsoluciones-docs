# PLAN DE INTEGRACIÓN FE COMPLETO — JSoluciones ERP

> Objetivo: FE 100% funcional con mocks donde el backend externo no exista todavía.
> Cuando lleguen credenciales reales (Nubefact, Meta WhatsApp, SUNAT, SSO), solo se activa el BE — el FE no cambia.
> Referencia spec: `JSOLUCIONES_MODULOS_CONTEXTO.md`
> Referencia template: `REACT_TS_TEMPLATE_INVENTARIO.md`
> Estado base: T12 (FE ~89%, BE ~90%)
> Creado: 2026-02-23

---

## REGLAS DE ORO PARA IMPLEMENTAR

1. **Antes de crear cualquier componente:** revisar si existe en `REACT_TS_TEMPLATE_INVENTARIO.md` o en el FE actual
2. **Patrones obligatorios:**
   - Listas CRUD → seguir `AlmacenesList.tsx` (`card > card-header > tabla > divide-y divide-default-200`)
   - Modales → seguir `AlmacenFormModal.tsx` (`fixed inset-0 z-80`, overlay negro, card centrada)
   - KPI cards → `rounded-xl border bg-white p-5` del dashboard
   - Buscadores → `ps-11 form-input` con icono absoluto en `ps-3`
   - Timelines → seguir `TrazabilidadLote.tsx`
3. **Mocks en FE:** si el endpoint BE no existe o es STUB, el FE llama igual al endpoint y muestra el dato mock que retorna el BE. No hardcodear datos en el FE.
4. **Iconos react-icons/lu:** SIEMPRE verificar con `node -e "const i = require('react-icons/lu'); console.log('LuNombre' in i);"`
5. **Al agregar campo/endpoint BE:** regenerar `openapi-schema.yaml` + `pnpm orval`

---

## MÓDULO 1 — VENTAS / POS

### Gap 1.1 — Botón "Consumidor Final" explícito en POS

**Archivo:** `src/app/(admin)/(app)/(ventas)/cart/index.tsx`

**Qué falta en FE:**
- Un botón visible "Consumidor Final" que limpie el cliente seleccionado y establezca un objeto fijo `{ id: null, razon_social: "Consumidor Final", tipo_documento: null }` en el estado del carrito
- Actualmente si no se selecciona cliente, va como "Varios" de forma implícita — no hay botón explícito

**Qué necesita el BE:**
- Nada nuevo. El endpoint `POST /ventas/venta-pos/` ya acepta `cliente_id: null`
- Campo ya existe en `VentaPOSSerializer` como `required=False`

**Cambios FE:**
- En `ClienteSelector.tsx` o directamente en `cart/index.tsx`: agregar botón `<LuUserX>` "Consumidor Final" que hace `setCliente(null)` y muestra badge "Consumidor Final"
- El botón ya existe parcialmente (línea ~288-305 en cart/index.tsx) — revisar y hacer explícito con label visible

**Template a usar:** Botón estilo `btn btn-sm` existente en el carrito, no requiere componente nuevo

---

### Gap 1.2 — Offline real (Service Worker + IndexedDB + cola de ventas)

**Archivos a crear/modificar:**
- `public/sw.js` — Service Worker
- `src/hooks/useOfflineQueue.ts` — hook para cola IndexedDB
- `src/app/(admin)/(app)/(ventas)/cart/index.tsx` — usar el hook

**Qué falta en FE:**
- Sin Service Worker ni IndexedDB, el POS no puede guardar ventas cuando no hay internet
- El banner "Sin conexión" existe (T10), pero no hay cola local
- Al reconectar, no hay sincronización automática con indicador de progreso

**Qué necesita el BE:**
- El endpoint `POST /ventas/offline-sync/` ya existe y procesa el batch cronológico
- No necesita cambios

**Cambios FE:**
1. `public/sw.js`: Service Worker mínimo — cache de assets estáticos, intercepta fetch y retorna desde cache si offline
2. `src/hooks/useOfflineQueue.ts`: hook con IndexedDB (usando `idb` o nativo), expone `enqueue(venta)`, `flush()`, `pendingCount`
3. En `cart/index.tsx`: al completar una venta y `!isOnline` → `enqueue(venta)` en vez de llamar a la API. Al reconectar → `flush()` con indicador de progreso (barra o spinner con contador "Sincronizando X de Y")
4. Añadir `<link rel="manifest">` en `index.html` con manifest mínimo para PWA

**Campo BE requerido para rastreo:** El endpoint `offline-sync` retorna `{ procesadas, fallidas }`. El FE puede mostrar el resultado en un toast o modal de resultado.

---

### Gap 1.3 — Vista de campo responsive para móvil/tablet

**Archivos a crear:**
- `src/app/(admin)/(app)/(ventas)/campo/index.tsx` — vista simplificada
- Ruta en `Routes.tsx`: `/ventas/campo`
- Entrada en `menu.ts`

**Qué falta en FE:**
- La spec pide vista simplificada para el vendedor de campo (móvil/tablet)
- Funciones requeridas: buscar producto, agregar al carrito, seleccionar cliente, confirmar venta
- Sin modal de caja (en campo no hay caja física)

**Qué necesita el BE:**
- Mismo endpoint `POST /ventas/venta-pos/` — no necesita cambios
- El campo `origen: "campo"` ya existe en `Venta.ORIGEN_CHOICES`

**Template a usar:** `(ecommerce)/product-grid` para el grid de productos en mobile, `(ecommerce)/cart` para el carrito simplificado

**Cambios FE:**
- Layout de columna única (no dos columnas como el POS de escritorio)
- Buscador prominente arriba
- Cards de productos táctiles (tamaño mínimo 44px para touch)
- Carrito collapsable desde abajo (drawer)
- Sin modal de caja — directamente seleccionar método de pago y confirmar

---

### Gap 1.4 — Reporte cotizaciones con tasa de conversión

**Archivo:** `src/app/(admin)/(app)/(ventas)/cotizaciones/index.tsx` (ya existe)

**Qué falta en FE:**
- Un card o sección de KPIs que muestre: total emitidas, aceptadas, rechazadas, vencidas, **tasa de conversión (%)**
- La tasa de conversión = (aceptadas / total) * 100

**Qué necesita el BE:**
- El endpoint `GET /ventas/cotizaciones/` retorna la lista paginada
- Agregar endpoint mock `GET /ventas/cotizaciones/kpis/` → ya existe `CotizacionKPIsView` en `views.py` → verificar que retorne `{ total, aceptadas, rechazadas, vencidas, tasa_conversion }`
- Si no retorna `tasa_conversion`, agregar el campo al serializer mock

**Cambios FE:**
- Sección de 4 KPI cards arriba de la tabla existente (usando patron de `LeaveCard` del template HR)
- Los datos vienen del endpoint `/cotizaciones/kpis/` que ya existe como mock

---

### Gap 1.5 — Reporte ventas offline sincronizadas

**Archivo a crear:** Tab o sección en `src/app/(admin)/(app)/(ventas)/index.tsx`

**Qué falta en FE:**
- No hay UI que muestre el historial de sincronizaciones offline (qué batch se procesó, cuántas ventas, cuáles fallaron)

**Qué necesita el BE:**
- Agregar campo `origen` en `VentaListSerializer` (ya existe en modelo como `origen = CharField`)
- Filtro `?origen=offline` en `VentaViewSet`
- Mock: retorna ventas con `origen: "offline"` y campo `sync_batch_id`

**Cambios FE:**
- Tab "Offline" en la lista de ventas existente, filtrado por `?origen=offline`
- Badge de estado de sync

---

## MÓDULO 2 — INVENTARIO

### Gap 2.1 — CRUD series desde UI de producto

**Archivo:** `src/app/(admin)/(app)/(inventario)/product-list/components/ProductoFormModal.tsx` (ya existe)

**Qué falta en FE:**
- En la ficha de un producto con `requiere_serie=True`, poder ver y gestionar las series asignadas
- Actualmente `/inventario/trazabilidad-serie` es solo lectura (búsqueda)

**Qué necesita el BE:**
- `GET /inventario/series/?producto={id}` — ya existe en `SerieViewSet` con `filterset_fields = ["producto", "almacen", "is_active"]`
- `POST /inventario/series/` — ya existe (CRUD completo)
- No necesita cambios BE

**Cambios FE:**
- En el detalle de producto (cuando `requiere_serie=True`), agregar tab "Series" con tabla de series: número, estado, almacén, fecha
- Botón "Registrar Serie" abre modal pequeño con campos: `numero_serie`, `almacen`, `estado`
- **Template:** `(hr)/employee` para tabla con modal editar

---

### Gap 2.2 — Validación stock en tiempo real en TransferenciaModal

**Archivo:** `src/app/(admin)/(app)/(inventario)/stock/components/TransferenciaStockModal.tsx` (ya existe)

**Qué falta en FE:**
- Al seleccionar producto + almacén origen + cantidad, mostrar el stock disponible en tiempo real debajo del campo
- Si cantidad > stock_disponible, deshabilitar el botón de confirmar con mensaje de error inline

**Qué necesita el BE:**
- `GET /inventario/stock/?producto={id}&almacen={id}` — ya existe, retorna `{ cantidad }`
- No necesita cambios BE

**Cambios FE:**
- En `TransferenciaStockModal.tsx`: cuando `productoId` y `almacenOrigenId` estén seleccionados, hacer query `useInventarioStockList({ producto: productoId, almacen: almacenOrigenId })` y mostrar "Disponible: X unidades" debajo del campo cantidad
- Si `cantidad > stockDisponible` → input en rojo + mensaje + botón deshabilitado

---

## MÓDULO 3 — FACTURACIÓN ELECTRÓNICA

### Gap 3.1 — Indicador pipeline visual Generando→Firmando→Enviando→Aceptado

**Archivo:** `src/app/(admin)/(app)/(facturacion)/overview/index.tsx` (ya existe)

**Qué falta en FE:**
- El WebSocket ya emite `estado_sunat` en tiempo real, pero la UI solo muestra el badge final
- La spec pide steps secuenciales visibles mientras el comprobante está siendo procesado

**Qué necesita el BE:**
- El `FacturacionConsumer` ya emite `estado_sunat`. Agregar un campo `paso_proceso` o usar los estados existentes:
  - `en_proceso` → "Enviando a Nubefact"
  - `pendiente` → "En cola"
  - `aceptado` → "Aceptado por SUNAT"
  - `rechazado` → "Rechazado"
- Mock: el consumer puede emitir una secuencia de estados con delay para simular el pipeline
- **No requiere cambios BE reales** — se puede mapear con los estados existentes

**Cambios FE:**
- Reemplazar el badge simple por un componente `<PipelineSteps>` con 4 pasos:
  ```
  [1: En Cola] → [2: Enviando] → [3: Procesando] → [4: Resultado]
  ```
- Cada paso se activa según el `estado_sunat` recibido por WebSocket
- Cuando el estado final llega (aceptado/rechazado), los steps se congelan con el resultado
- **Template:** `(pages)/timeline/index.tsx` — variante "Progress" es perfecta para esto

---

### Gap 3.2 — Banner modo DEMO

**Archivo:** `src/components/layouts/topbar/index.tsx` (ya existe)

**Qué falta en FE:**
- Existe `ContingenciaBanner` (naranja). La spec pide también un banner modo DEMO (distinto — indica que los comprobantes NO van a SUNAT real)
- El banner DEMO debe ser visible en todas las páginas cuando `modo_demo = True`

**Qué necesita el BE:**
- `GET /facturacion/contingencia/estado/` ya existe y retorna `{ modo_contingencia, modo_demo? }`
- Si el campo `modo_demo` no existe en el serializer, agregarlo como mock `modo_demo: False`

**Cambios FE:**
- Agregar `DemoBanner.tsx` similar a `ContingenciaBanner.tsx` pero con color azul/cyan y texto "Modo DEMO activo — los comprobantes no se envían a SUNAT real"
- Se muestra debajo del `ContingenciaBanner` si `modo_demo = True`
- Montar en `PageWrapper.tsx` junto al banner de contingencia

---

### Gap 3.3 — Filtro por cliente en InvoiceList

**Archivo:** `src/app/(admin)/(app)/(invoice)/list/components/InvoiceList.tsx` (ya existe)

**Qué falta en FE:**
- El BE ya soporta `?cliente={uuid}` en `ComprobanteViewSet`
- El FE tiene filtro por texto, tipo, estado y fechas — pero no tiene un selector de cliente

**Qué necesita el BE:**
- Nada. El filtro `?cliente=` ya existe en `ComprobanteViewSet.filterset_fields`

**Cambios FE:**
- Agregar un campo de búsqueda de cliente tipo autocompletado (igual al que ya existe en `InvoiceList.tsx` para el autocomplete de cliente en líneas 66-200)
- Al seleccionar un cliente, pasar `clienteId` al hook `useFacturacionComprobantesList`

---

## MÓDULO 4 — DISTRIBUCIÓN Y SEGUIMIENTO

### Gap 4.1 — Vista conductor móvil (PWA)

**Archivos a crear:**
- `src/app/(admin)/(app)/(distribucion)/conductor/index.tsx`
- Ruta: `/distribucion/conductor`

**Qué falta en FE:**
- Vista optimizada para el conductor: lista de entregas del día, botón de navegación GPS, formulario de confirmación
- La spec pide: lista de entregas, escanear QR, navegar, confirmar entrega con evidencia
- Actualmente hay páginas de pedido y scanner QR separadas, no una vista unificada para conductor

**Qué necesita el BE:**
- `GET /distribucion/pedidos/?transportista={id}&estado=despachado,en_ruta` — filtros ya existen
- `POST /distribucion/pedidos/{id}/evidencia/` — ya existe
- `POST /distribucion/pedidos/{id}/gps/` — ya existe
- No necesita cambios BE

**Cambios FE:**
- Layout de una sola columna, tipografía grande, botones táctiles grandes (mínimo 48px)
- Lista de pedidos asignados al transportista autenticado
- Cada pedido: dirección, cliente, botón "Navegar" (abre Google Maps/Waze con coordenadas), botón "Confirmar entrega"
- Modal confirmación entrega: foto, firma táctil o código OTP (reutilizar `FirmaCanvas.tsx` existente)
- **Template:** Estructura similar a `(ecommerce)/product-list` pero simplificada para touch

---

### Gap 4.2 — Formulario entrega fallida

**Archivo:** `src/app/(admin)/(app)/(distribucion)/pedidos/[id]/index.tsx` (ya existe como `pedido-detalle`)

**Qué falta en FE:**
- No hay modal de "Entrega Fallida" con selector de motivo + campo observación
- La spec requiere que al registrar entrega fallida el supervisor reciba alerta

**Qué necesita el BE:**
- Agregar endpoint mock `POST /distribucion/pedidos/{id}/entrega-fallida/` → body: `{ motivo: string, observacion: string }` → retorna pedido con estado `cancelado` o nuevo estado `entrega_fallida`
- Si agregar nuevo estado rompe tests, usar `cancelado` con campo `motivo_cancelacion` (ya existe en modelo)
- La alerta al supervisor ya existe vía `Notificacion` (Task Celery)

**Cambios FE:**
- Botón "Registrar Entrega Fallida" en el detalle del pedido (visible cuando estado = `en_ruta`)
- Modal con:
  - Select de motivo: "Cliente ausente", "Dirección incorrecta", "Producto dañado", "Rechazado por cliente", "Otro"
  - Textarea observación
  - Botón confirmar
- **Template:** `AlmacenFormModal.tsx` como base de modal

---

### Gap 4.3 — Optimización de ruta visual en mapa

**Archivo:** `src/app/(admin)/(app)/(distribucion)/mapa/index.tsx` (ya existe)

**Qué falta en FE:**
- El mapa existe con Leaflet y GPS en vivo, pero no muestra el orden optimizado de entregas
- La spec pide "orden sugerido en el mapa"

**Qué necesita el BE:**
- El endpoint de optimización TSP es STUB en BE (`apps/distribucion/services.py`)
- Agregar mock `GET /distribucion/pedidos/ruta-optimizada/?transportista={id}` → retorna array de pedidos ordenados con `orden: 1, 2, 3...` y coordenadas
- Mock retorna el mismo orden de llegada (sin optimización real) con campo `optimizado: false` y mensaje

**Cambios FE:**
- En el mapa, si se selecciona un transportista, mostrar una polyline conectando los pedidos en el orden sugerido
- Numerar los markers (1, 2, 3...) según el orden de la ruta
- Badge "Ruta optimizada" o "Orden por llegada" según el campo `optimizado` del mock

---

## MÓDULO 5 — COMPRAS Y PROVEEDORES

### Gap 5.1 — UI series en recepciones

**Archivo:** `src/app/(admin)/(app)/(compras)/recepciones/components/RecepcionFormModal.tsx` (ya existe)

**Qué falta en FE:**
- Al recibir un producto con `requiere_serie=True`, el formulario no pide los números de serie
- La spec requiere registrar serie por cada unidad recibida

**Qué necesita el BE:**
- `POST /inventario/series/` — ya existe (SerieViewSet CRUD)
- En `RecepcionFormModal`, al confirmar la recepción, llamar también a `POST /inventario/series/` para cada ítem con `requiere_serie=True`
- No necesita nuevo endpoint BE

**Cambios FE:**
- En `RecepcionFormModal.tsx`, para cada ítem de la recepción donde el producto tenga `requiere_serie=True`:
  - Mostrar un campo de texto por cada unidad: "Serie 1", "Serie 2", etc. (cantidad = cantidad_recibida)
  - Al confirmar la recepción, además de la llamada de recepción, hacer POST a `/inventario/series/` para cada número ingresado
- **Template:** Sección expandible tipo acordeón por ítem, usando el patrón de items de `AddNew.tsx`

---

## MÓDULO 6 — FINANZAS (el más rezagado — 78%)

### Gap 6.1 — Vista de carga de extracto bancario + tabla de movimientos importados

**Archivos a crear:**
- `src/app/(admin)/(app)/(finanzas)/conciliacion/components/ImportarExtractoPanel.tsx`

**Qué falta en FE:**
- La página `/finanzas/conciliacion` ya existe con CRUD de conciliaciones
- En el detalle de una conciliación (ConciliacionDetalle.tsx, 810 líneas) **ya existe** un Dropzone de importación que llama a `POST /finanzas/conciliaciones/{id}/importar-extracto/`
- Lo que falta: mostrar la tabla de movimientos importados con columnas: fecha, descripción, monto, tipo, estado (conciliado/pendiente)

**Qué necesita el BE:**
- El endpoint `POST /importar-extracto/` ya existe en `ConciliacionBancariaViewSet`
- Verificar que retorne `{ importados: N, movimientos: [...] }` con la estructura completa
- Si solo retorna `{ importados: N, errores: [] }`, agregar `movimientos` al mock de respuesta con datos plausibles

**Cambios FE:**
- En `ConciliacionDetalle.tsx`: después de importar, mostrar tabla de movimientos (`MovimientoBancario`) con:
  - Fecha, descripción, monto, tipo (crédito/débito), estado (conciliado/pendiente)
  - Semáforo: verde=conciliado, amarillo=pendiente, rojo=error
- La tabla ya carga movimientos vía `useFinanzasConciliacionesMovimientosList` — revisar si ya existe y conectar

---

### Gap 6.2 — Panel de conciliación con sugerencias automáticas y botones confirmar/ignorar

**Archivo:** `src/app/(admin)/(app)/(finanzas)/conciliacion/[id]/index.tsx` (ConciliacionDetalle.tsx)

**Qué falta en FE:**
- El Dropzone y el endpoint de matching ya existen (T12 auditó esto)
- Lo que falta: mostrar las sugerencias de matching con botones "Confirmar" e "Ignorar" por cada par

**Qué necesita el BE:**
- `POST /finanzas/conciliaciones/{id}/matching/` ya existe
- Verificar que retorne `{ analizados: N, conciliados: N, sin_match: N, detalle: [{ movimiento_bancario_id, cxc_id, score, monto_diferencia }] }`
- Si el detalle está vacío en el mock, agregar datos plausibles de ejemplo

**Cambios FE:**
- Después de ejecutar matching, mostrar tabla de sugerencias:
  - Columnas: Movimiento bancario (fecha, monto, descripción) | CxC/CxP sugerida (cliente, monto) | Confianza (%) | Acciones
  - Botón "Confirmar" → llama a endpoint de confirmación (crear si no existe: `POST /conciliaciones/{id}/movimientos/` ya existe)
  - Botón "Ignorar" → marca el movimiento como ignorado
- **Template:** Tabla con acciones inline — patron de `OrderDetailTable.tsx` del template

---

### Gap 6.3 — Checklist previo al cierre de periodo tributario

**Archivo:** `src/app/(admin)/(app)/(finanzas)/declaraciones/index.tsx` (ya existe)

**Qué falta en FE:**
- La página de declaraciones tiene los tabs PLE y PDT
- Falta el "checklist previo al cierre": lista de ítems que deben estar OK antes de cerrar el periodo

**Qué necesita el BE:**
- Agregar endpoint mock `GET /finanzas/periodos/{id}/checklist/` → retorna array:
  ```json
  [
    { "item": "CxC sin conciliar", "ok": false, "cantidad": 3 },
    { "item": "Asientos sin confirmar", "ok": true, "cantidad": 0 },
    { "item": "Comprobantes pendientes SUNAT", "ok": false, "cantidad": 1 }
  ]
  ```

**Cambios FE:**
- En la página de declaraciones, antes del botón "Cerrar Periodo", mostrar el checklist como lista de ítems con:
  - Check verde si `ok: true`, advertencia roja si `ok: false` con la cantidad de problemas
  - El botón "Cerrar Periodo" se deshabilita si hay algún ítem con `ok: false`
- **Template:** Lista con iconos tipo `LuCircleCheck` / `LuCircleX`, patrón simple sin necesidad de template externo

---

### Gap 6.4 — Firma digital del contador para cierre tributario

**Archivo:** `src/app/(admin)/(app)/(finanzas)/declaraciones/index.tsx`

**Qué falta en FE:**
- No hay UI para que el contador "firme" digitalmente el cierre del periodo
- La spec dice "firma digital obligatoria para cierre tributario"

**Qué necesita el BE:**
- Agregar campo `firmado_por` + `fecha_firma` en `PeriodoContable`
- Endpoint mock `POST /finanzas/periodos/{id}/firmar/` → body `{ pin_confirmacion: "1234" }` → retorna periodo con `firmado: true`
- Mock: acepta cualquier PIN de 4 dígitos y retorna `firmado: true`

**Cambios FE:**
- Modal "Firmar y Cerrar Periodo" con:
  - Resumen del periodo (fechas, total asientos, total movimientos)
  - Campo PIN de confirmación (4 dígitos) — en producción esto sería firma real
  - Botón "Firmar y Cerrar"
- Después de firmar, el periodo queda en estado `cerrado` con badge verde y nombre del contador + fecha

---

## MÓDULO 7 — WHATSAPP (el más incompleto — 65% FE)

> TODOS los gaps de este módulo se implementan con mocks en FE y STUB en BE.
> Cuando llegue el token Meta Business, solo se activa `services.py` — la UI no cambia.

### Gap 7.1 — Métricas de campaña (cards enviados/entregados/leídos/respondidos)

**Archivo a crear:** `src/app/(admin)/(app)/(whatsapp)/metricas/index.tsx`
**Ruta:** `/whatsapp/metricas`

**Qué falta en FE:**
- No existe ninguna página de métricas de WhatsApp
- La spec pide: cards con enviados, entregados, leídos, respondidos + gráfico de rendimiento por campaña

**Qué necesita el BE:**
- Agregar endpoint mock `GET /whatsapp/metricas/` → retorna:
  ```json
  {
    "enviados": 0,
    "entregados": 0,
    "leidos": 0,
    "respondidos": 0,
    "tasa_entrega": 0,
    "tasa_lectura": 0,
    "por_campana": []
  }
  ```
- URL: `apps/whatsapp/urls.py`

**Cambios FE:**
- 4 KPI cards con los contadores (usando patrón del dashboard)
- Gráfico de barras ApexCharts mostrando rendimiento por campaña (datos del array `por_campana`)
- Banner azul: "Las métricas se activarán cuando se configure el token Meta Business"
- **Template:** `(dashboards)/email/index.tsx` — tiene exactamente `EmailLineChart` (sparklines) y `EmailBarChart` que son perfectos para esto. Adaptar a WhatsApp.

---

### Gap 7.2 — Vista de creación de campaña masiva con selector de segmento

**Archivo a crear:** `src/app/(admin)/(app)/(whatsapp)/campanas/index.tsx`
**Ruta:** `/whatsapp/campanas`

**Qué falta en FE:**
- No existe página de campañas
- La spec pide: crear campaña, seleccionar segmento de clientes (nuevo/frecuente/VIP/etc.), elegir plantilla aprobada, programar envío

**Qué necesita el BE:**
- Agregar modelo `WhatsappCampana` con campos: nombre, plantilla, segmento_clientes, estado, fecha_programada, total_destinatarios
- Endpoint mock `GET/POST /whatsapp/campanas/` → retorna lista vacía / crea campaña con estado `programada`
- Endpoint mock `POST /whatsapp/campanas/{id}/ejecutar/` → retorna `{ enviados: 0, mensaje: "Pendiente de implementacion — requiere token Meta" }`

**Cambios FE:**
- Lista de campañas con badges de estado (borrador, programada, en_proceso, completada)
- Modal "Nueva Campaña":
  - Nombre, plantilla (select solo aprobadas), segmento (select de valores existentes en Cliente.segmento), fecha programada
  - Estimado de destinatarios (query a `GET /ventas/clientes/?segmento={segmento}&count=true`)
- Botón "Ejecutar ahora" con aviso de que requiere token Meta configurado
- **Template:** `(hr)/sales-estimates/components/Estimates.tsx` para la tabla, `AlmacenFormModal.tsx` para el modal

---

### Gap 7.3 — Configuración de automatizaciones por evento

**Archivo a crear:** `src/app/(admin)/(app)/(whatsapp)/automatizaciones/index.tsx`
**Ruta:** `/whatsapp/automatizaciones`

**Qué falta en FE:**
- No existe página de automatizaciones
- La spec pide: configurar qué plantilla se envía ante cada evento del sistema (confirmación de venta, estado de pedido, vencimiento de cotización)

**Qué necesita el BE:**
- Agregar modelo `WhatsappAutomatizacion` con campos: evento, plantilla, activo, variables_mapeadas
- Eventos posibles (enum): `venta_confirmada`, `pedido_despachado`, `pedido_entregado`, `cotizacion_por_vencer`, `cxc_vencida`
- Endpoint mock `GET/PATCH /whatsapp/automatizaciones/` → retorna lista de automatizaciones con `activo: false` por defecto

**Cambios FE:**
- Tabla con los 5 eventos fijos, cada fila tiene:
  - Nombre del evento (descriptivo)
  - Select de plantilla aprobada (o "Sin plantilla")
  - Toggle activo/inactivo
  - Variables disponibles (badge informativo)
- Guardar con `PATCH /whatsapp/automatizaciones/{id}/`
- Banner: "Las automatizaciones se ejecutarán cuando el token Meta esté configurado"
- **Template:** Tabla simple con toggles — patrón de `(hr)/holidays` o usar la tabla base

---

## MÓDULO 8 — DASHBOARD Y REPORTES

### Gap 8.1 — Umbrales configurables en semáforos de KPIs

**Archivo:** `src/app/(admin)/(app)/(dashboards)/index/index.tsx` (ya existe)

**Qué falta en FE:**
- Los umbrales del semáforo (verde/amarillo/rojo) están hardcodeados
- La spec pide que sean configurables por usuario

**Qué necesita el BE:**
- Agregar endpoint mock `GET/PATCH /reportes/configuracion-kpis/` → retorna:
  ```json
  {
    "ventas_diarias_umbral_verde": 10000,
    "ventas_diarias_umbral_amarillo": 5000,
    "stock_bajo_umbral": 10
  }
  ```

**Cambios FE:**
- Botón de engranaje en el dashboard → modal "Configurar Umbrales" con inputs numéricos por KPI
- Los valores se guardan con `PATCH /reportes/configuracion-kpis/` y se persisten en el servidor (no solo localStorage)
- Los semáforos en los KPI cards usan estos umbrales para el color

---

### Gap 8.2 — Guardado de filtros favoritos en el Dashboard principal

**Archivo:** `src/app/(admin)/(app)/(dashboards)/index/index.tsx` (ya existe)

**Qué falta en FE:**
- El módulo de Reportes tiene favoritos en `localStorage` (T8)
- El Dashboard principal no tiene guardado de filtros

**Qué necesita el BE:**
- Nada. Se puede hacer en localStorage como ya se hizo en Reportes

**Cambios FE:**
- Botón "Guardar filtros" en la barra de filtros del dashboard
- Al guardar, persistir en `localStorage` con clave `dashboard_filtros_${userId}`
- Al cargar el dashboard, restaurar los filtros guardados automáticamente

---

### Gap 8.3 — Widgets configurables por rol (layout configurable)

**Archivo:** `src/app/(admin)/(app)/(dashboards)/index/index.tsx` (ya existe)

**Qué falta en FE:**
- Los filtros por rol existen (cada rol ve su sección)
- Lo que falta: que el usuario pueda reordenar o mostrar/ocultar widgets

**Qué necesita el BE:**
- Endpoint mock `GET/PATCH /reportes/layout-dashboard/` → retorna array de widgets con `visible: true/false` y `orden: N`

**Cambios FE:**
- Botón "Personalizar" en el dashboard → panel lateral con lista de widgets disponibles y toggles on/off
- El orden se guarda en `localStorage` o en el endpoint mock
- Los widgets se renderizan en el orden configurado

---

## MÓDULO 9 — USUARIOS Y ROLES

### Gap 9.1 — Matriz de permisos formato tabla cruzada

**Archivo:** `src/app/(admin)/(app)/(configuracion)/roles/index.tsx` (ya existe, `PermisosModal.tsx`)

**Qué falta en FE:**
- Actualmente es lista agrupada por módulo con checkboxes
- La spec dice "filas = módulos, columnas = acciones"

**Qué necesita el BE:**
- Nada. El endpoint `GET /usuarios/permisos/` ya retorna todos los permisos con campos `modulo` y `accion`

**Cambios FE:**
- Reemplazar la lista en `PermisosModal.tsx` por una tabla donde:
  - Filas: módulos (Ventas, Inventario, Facturación, etc.)
  - Columnas: acciones (ver, crear, editar, eliminar, aprobar)
  - Celda: checkbox marcado si el rol tiene ese permiso
- Agregar fila "Seleccionar todo" por columna y columna "Seleccionar todo" por fila
- **Template:** No hay un componente exacto en el template. Construir tabla con `<table>` estándar usando clases Tailwind del proyecto.

---

### Gap 9.2 — Forzar cambio de contraseña al expirar

**Archivo:** `src/app/(auth)/modern-login/index.tsx` (ya existe como el login de JSoluciones)
**Archivo:** `src/app/(auth)/two-steps/index.tsx` (ya existe)

**Qué falta en FE:**
- El login actual no detecta si la contraseña expiró y no redirige a cambio forzado
- La spec pide redirect automático a "Crear nueva contraseña" si la contraseña expiró

**Qué necesita el BE:**
- El endpoint `POST /auth/login/` ya puede retornar `{ require_password_change: true }` si la contraseña expiró
- Verificar que el campo exista en la respuesta del login — si no, agregarlo al serializer con valor `false` por defecto

**Cambios FE:**
- En el handler `onSuccess` del login, si `response.data.require_password_change === true` → navegar a `/auth/cambiar-password-forzado` en vez del dashboard
- Crear página simple `/auth/cambiar-password-forzado` con formulario de nueva contraseña
- **Template:** `(auth)/modern-create-password/` del template — ya tiene el formulario exacto

---

### Gap 9.3 — SSO Google y Microsoft

**Archivos:** Login page (ya existe)

**Qué falta en FE:**
- Los botones de SSO son decorativos

**Qué necesita el BE:**
- Endpoints OAuth2: `GET /auth/sso/google/` y `GET /auth/sso/microsoft/` → retornan URL de redirect a OAuth2
- Callback: `GET /auth/sso/callback/` → procesa el código, crea/actualiza usuario, retorna JWT
- Mock: `GET /auth/sso/google/` retorna `{ url: "https://accounts.google.com/...", disponible: false, mensaje: "Requiere Google OAuth2 client ID configurado" }`

**Cambios FE:**
- Los botones SSO al hacer clic llaman al endpoint mock
- Si `disponible: false` → mostrar toast "SSO no disponible — configura las credenciales en el panel de administración"
- Si `disponible: true` → redirigir a la URL OAuth2

---

## RESUMEN: ORDEN DE IMPLEMENTACIÓN RECOMENDADO

### Prioridad ALTA — Impactan flujos principales (hacer primero)

| # | Módulo | Gap | Tipo | BE necesario |
|---|--------|-----|------|-------------|
| 1 | M6 | Tabla movimientos importados en conciliación | Conectar UI existente | Revisar respuesta mock |
| 2 | M6 | Panel matching con confirmar/ignorar | Componente nuevo | Verificar mock detalle |
| 3 | M7 | Métricas campaña (cards + gráfico) | Página nueva | Endpoint mock nuevo |
| 4 | M7 | Vista creación campaña masiva | Página nueva | Modelo + endpoints mock |
| 5 | M7 | Automatizaciones por evento | Página nueva | Modelo + endpoint mock |
| 6 | M1 | Botón "Consumidor Final" explícito | Mejora existente | Nada |
| 7 | M4 | Formulario entrega fallida | Modal nuevo | Endpoint mock |
| 8 | M3 | Pipeline visual Generando→Aceptado | Mejora existente | Mapear estados |

### Prioridad MEDIA — Completan la spec sin bloquear nada

| # | Módulo | Gap | Tipo | BE necesario |
|---|--------|-----|------|-------------|
| 9 | M6 | Checklist cierre periodo | Sección en página existente | Endpoint mock |
| 10 | M6 | Firma digital cierre | Modal nuevo | Endpoint mock + campo modelo |
| 11 | M3 | Banner modo DEMO | Componente global | Campo en respuesta contingencia |
| 12 | M5 | UI series en recepciones | Sección en modal existente | Nada (CRUD ya existe) |
| 13 | M9 | Matriz permisos tabla cruzada | Refactor modal existente | Nada |
| 14 | M2 | CRUD series desde producto | Tab en detalle producto | Nada (CRUD ya existe) |
| 15 | M2 | Validación stock tiempo real | Mejora modal existente | Nada |
| 16 | M8 | Umbrales semáforos configurables | Modal nuevo | Endpoint mock |
| 17 | M1 | Filtros cliente en InvoiceList | Mejora existente | Nada |

### Prioridad BAJA — Dependen de externos o son de polish final

| # | Módulo | Gap | Tipo | BE necesario |
|---|--------|-----|------|-------------|
| 18 | M4 | Vista conductor PWA | Página nueva | Nada |
| 19 | M4 | Ruta optimizada en mapa | Mejora mapa existente | Endpoint mock |
| 20 | M8 | Filtros favoritos Dashboard | Mejora existente | Nada (localStorage) |
| 21 | M8 | Widgets configurables | Panel personalización | Endpoint mock |
| 22 | M1 | Vista campo responsive | Página nueva | Nada |
| 23 | M1 | Offline real (SW + IndexedDB) | Infraestructura PWA | Nada |
| 24 | M9 | Forzar cambio contraseña | Flujo auth | Campo en login response |
| 25 | M9 | SSO Google/Microsoft | Flujo auth | Endpoints OAuth2 mock |
| 26 | M1 | Reporte cotizaciones con tasa conv | Mejora existente | Verificar endpoint mock |
| 27 | M1 | Reporte ventas offline sync | Tab en lista ventas | Filtro `?origen=offline` |
| 28 | M3 | Filtro cliente InvoiceList | Mejora existente | Nada |

---

## DEPENDENCIAS ENTRE GAPS Y EXTERNOS

```
Nubefact (credenciales reales)
  └── M3 Gap 3.1 (pipeline visual) → ya puede implementarse con mock de estados
  └── M3 Gap 3.2 (banner DEMO) → independiente del token

Meta WhatsApp Business API
  └── M7 Gap 7.1 (métricas) → implementar con mock, activar BE cuando llegue token
  └── M7 Gap 7.2 (campañas) → implementar con mock
  └── M7 Gap 7.3 (automatizaciones) → implementar con mock

SUNAT / Nubefact PLE/PDT
  └── M6 (PLE/PDT real) → la UI ya está completa en T9, solo falta BE real

Google OAuth2 client ID
  └── M9 Gap 9.3 (SSO Google) → implementar flujo con mock que retorna "no disponible"

Microsoft Azure AD client ID
  └── M9 Gap 9.3 (SSO Microsoft) → mismo patrón que Google
```

---

## NOTAS DE IMPLEMENTACIÓN

### Cómo manejar los mocks BE

Cada endpoint mock debe:
1. Retornar la **estructura exacta** que usará cuando sea real
2. Incluir campo `mock: true` o `pendiente_implementacion: true` en la respuesta para que el FE pueda mostrar banners informativos
3. Retornar datos plausibles (no arrays vacíos) para que la UI se pueda probar visualmente

### Cuándo NO crear un mock BE

Si el FE puede funcionar completamente con datos locales (localStorage, estado React) sin necesitar el servidor, no crear endpoint. Ejemplos:
- Gap 8.2 (filtros favoritos Dashboard) → localStorage directo
- Gap 2.2 (validación stock tiempo real) → query a endpoint existente, no nuevo endpoint

### Patrón de banner informativo para mocks

```tsx
{data?.mock && (
  <div className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-700 mb-4">
    Esta sección está en modo simulación. Se activará completamente cuando se integre [servicio externo].
  </div>
)}
```

---

*Creado: 2026-02-23 — Sesión T12*
*Basado en: auditoría directa del código + JSOLUCIONES_MODULOS_CONTEXTO.md*
*Sin alucinar — todos los gaps verificados contra archivos reales*
