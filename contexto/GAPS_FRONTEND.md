# JSOLUCIONES ERP — GAPS FRONTEND (para cerrar antes de QA/Testing)

> Generado: 2026-02-23 (Sesión T9)
> Fuente: Lectura directa del código. Sin suposiciones.
> Regla: Si el BE no existe → se crea endpoint mock primero, luego se conecta el FE.
> Objetivo: Dejar el FE 100% visual/navegable. La lógica real de BE puede llegar después.

---

## LEYENDA

- 🔴 **CRÍTICO** — Rompe un flujo de negocio clave o la página no existe
- 🟡 **IMPORTANTE** — Flujo incompleto o información que falta en UI existente
- 🟢 **MEJORA** — Pulido visual, UX, detalle menor
- ✅ **COMPLETADO** — Ya implementado
- 🔧 **NECESITA BE MOCK** — Requiere endpoint nuevo (aunque sea mock)

---

## MÓDULO 1 — Ventas / POS

### 🔴 GAP-V1: Indicador de conexión offline en POS
**Qué falta:** No existe `navigator.onLine`, ningún banner ni indicador visual de si hay internet.
**Impacto:** El cajero no sabe si está trabajando offline y si sus ventas se están guardando o no.
**BE necesario:** No. Solo FE.
**Solución FE:**
- Hook `useOnlineStatus()` con `navigator.onLine` + listeners `online/offline`
- Banner amarillo en `cart/` cuando `!isOnline`: "Sin conexión — las ventas se guardan localmente"
- Badge en header con indicador de estado de conexión

---

### 🟡 GAP-V2: Botón "Consumidor Final" en POS
**Qué falta:** Cuando no se selecciona cliente, la venta va como "Varios" pero no hay botón explícito.
**Impacto:** Confusión para el cajero — no sabe si puede proceder sin cliente.
**BE necesario:** No.
**Solución FE:**
- Botón "Consumidor Final" en `cart/` que limpia la selección de cliente y muestra badge "CF"
- La venta con `cliente = null` ya funciona en BE, solo falta el botón

---

### 🟡 GAP-V3: Reporte de cotizaciones con tasa de conversión
**Qué falta:** No existe ningún indicador de cuántas cotizaciones se convirtieron en venta.
**Impacto:** Sin métrica clave de ventas.
**BE necesario:** 🔧 `GET /api/v1/ventas/cotizaciones/estadisticas/` (mock: devuelve datos fijos)
**Solución FE:**
- Agregar sección de KPIs en `/ventas/cotizaciones`: total, aceptadas, rechazadas, tasa conversión %
- Cards simples con los datos del endpoint

---

### 🟢 GAP-V4: Notas de crédito desde módulo Ventas
**Qué falta:** El botón existe en detalle de venta pero no hay modelo propio en ventas — va a facturación.
**Impacto:** Menor — el flujo real es desde facturación.
**BE necesario:** No.
**Solución FE:** Redirigir el botón a `/facturacion/notas?venta_id=XXX` con parámetro prefilled.

---

## MÓDULO 2 — Inventario

### 🟡 GAP-I1: CRUD de Series desde ficha de producto
**Qué falta:** El modelo `Serie` existe y `SerieViewSet` existe en BE, pero no hay UI para ver/gestionar series de un producto específico.
**Impacto:** El usuario no puede ver qué series tiene un producto desde su ficha.
**BE necesario:** No (ya existe `GET /api/v1/inventario/series/?producto=UUID`).
**Solución FE:**
- Nuevo tab "Series" en `/inventario/productos/:id` (junto a los tabs existentes)
- Lista de series con número, estado (disponible/vendida/en_uso), fecha ingreso
- Botón agregar serie manualmente (modal simple)

---

### 🟡 GAP-I2: Filtro por categoría en vista de stock
**Qué falta:** `StockOverview` solo filtra por almacén y tipo de movimiento. No por categoría.
**Impacto:** En inventarios grandes es difícil encontrar productos por categoría.
**BE necesario:** No (el endpoint ya soporta `categoria` como filterset_field si se agrega — verificar).
**Solución FE:**
- Agregar select de categoría en los filtros de `StockOverview.tsx`

---

### 🟡 GAP-I3: Series al recibir en compras
**Qué falta:** `RecepcionFormModal.tsx` no tiene campo para registrar números de serie al recibir.
**Impacto:** Productos con `requiere_serie=true` entran sin serie asignada.
**BE necesario:** No (la lógica de asignar serie al recibir ya puede manejarse en el FE + endpoint existente de series).
**Solución FE:**
- Si el producto tiene `requiere_serie=true`, mostrar campo(s) para ingresar números de serie en `RecepcionFormModal`

---

## MÓDULO 3 — Facturación Electrónica

### 🟡 GAP-F1: Indicador de pipeline SUNAT (pasos secuenciales)
**Qué falta:** El WebSocket ya existe y emite estados, pero la UI solo muestra un badge. No hay stepper visual `Generando → Firmando → Enviando → Aceptado`.
**Impacto:** El usuario no sabe en qué paso está la emisión.
**BE necesario:** No.
**Solución FE:**
- En `overview/index.tsx`: reemplazar el badge único por un stepper horizontal de 4 pasos
- El estado WebSocket ya provee la info necesaria para determinar el paso actual

---

### 🟡 GAP-F2: Filtro por cliente en lista de comprobantes
**Qué falta:** El BE soporta filtro `?cliente=UUID` en `ComprobanteViewSet` pero el FE no lo expone.
**Impacto:** No se puede buscar todos los comprobantes de un cliente específico.
**BE necesario:** No.
**Solución FE:**
- Agregar buscador de cliente (autocomplete) en los filtros de `list/components/InvoiceList.tsx`

---

### 🟢 GAP-F3: Banner modo DEMO
**Qué falta:** Existe banner de CONTINGENCIA (naranja) pero no de DEMO (cuando las credenciales Nubefact no están configuradas).
**Impacto:** Sin credenciales, los comprobantes se emiten en modo demo silenciosamente.
**BE necesario:** 🔧 `GET /api/v1/facturacion/modo/` (mock: devuelve `{ modo: "demo" | "produccion" | "contingencia" }`)
**Solución FE:**
- Banner azul "Modo DEMO — los comprobantes NO se envían a SUNAT" cuando `modo === "demo"`

---

## MÓDULO 4 — Distribución

### 🟡 GAP-D1: Exportar hoja de ruta / manifiesto como PDF
**Qué falta:** El BE genera PDF de hoja de ruta (`reportlab`), pero el FE no tiene botón para descargarlo.
**Impacto:** El transportista no puede imprimir su ruta.
**BE necesario:** Verificar si existe endpoint `GET /pedidos/{id}/hoja-ruta/` — si existe, solo falta el botón FE.
**Solución FE:**
- Botón "Descargar Hoja de Ruta PDF" en `pedido-detalle/index.tsx`

---

### 🟢 GAP-D2: Filtro de pedidos por transportista en lista
**Qué falta:** La lista de pedidos no tiene filtro por transportista asignado.
**BE necesario:** No (verificar si `TransportistaViewSet` tiene filterset_field transportista en pedidos).
**Solución FE:** Agregar select de transportista en filtros de `pedidos/`.

---

## MÓDULO 5 — Compras

### 🟢 GAP-C1: Exportar lista de OC a Excel/PDF
**Qué falta:** No hay botón de exportación en la lista de órdenes de compra.
**BE necesario:** 🔧 `GET /api/v1/compras/ordenes/exportar/` (mock: devuelve Excel vacío con headers correctos)
**Solución FE:**
- Botón "Exportar" con dropdown Excel/PDF en `ordenes-compra/`

---

## MÓDULO 6 — Finanzas

### 🔴 GAP-FIN1: Carga de extracto bancario (CSV/Excel)
**Qué falta:** No existe UI para cargar el extracto del banco. Solo se pueden agregar movimientos manualmente uno a uno.
**Impacto:** La conciliación bancaria es prácticamente inutilizable sin importación masiva.
**BE necesario:** 🔧 `POST /api/v1/finanzas/conciliaciones/{id}/importar-extracto/`
  - Mock: acepta un archivo, devuelve lista de movimientos parseados (hardcodeados de ejemplo)
  - Formato real pendiente: CSV o Excel con columnas fecha, descripción, monto, referencia
**Solución FE:**
- Botón "Importar Extracto" en `ConciliacionDetalle.tsx`
- Modal con dropzone (ya existe patrón en `RecepcionFormModal.tsx`)
- Tabla preview de los movimientos a importar → botón "Confirmar importación"

---

### 🟡 GAP-FIN2: Panel de matching / sugerencias en conciliación
**Qué falta:** Ver movimientos bancarios vs movimientos del sistema lado a lado y poder marcarlos como conciliados.
**Impacto:** Sin esto, la conciliación bancaria es solo un registro manual sin valor real.
**BE necesario:** 🔧 `GET /api/v1/finanzas/conciliaciones/{id}/sugerencias/`
  - Mock: devuelve pares `{ movimiento_bancario, cobro_o_pago_sugerido, confianza }` vacíos por ahora
**Solución FE:**
- Nuevo tab "Matching" en `ConciliacionDetalle.tsx`
- Tabla de 2 columnas: movimientos banco (izq) vs movimientos sistema (der)
- Botones "Conciliar" y "Descartar sugerencia" por fila

---

### 🟡 GAP-FIN3: Gestión de períodos contables desde UI
**Qué falta:** Los endpoints `POST /periodos/cerrar/` y `POST /periodos/reabrir/` existen en BE, pero no hay página dedicada a gestionar períodos. Solo el `PeriodoBadge` los muestra.
**Impacto:** Un admin no puede cerrar/reabrir períodos desde la UI.
**BE necesario:** No (endpoints ya existen).
**Solución FE:**
- Nueva página `/finanzas/periodos` con lista de períodos, badge abierto/cerrado, botones cerrar/reabrir
- Agregar al sidebar bajo Finanzas

---

## MÓDULO 7 — WhatsApp

### 🟡 GAP-W1: Métricas de campaña
**Qué falta:** No hay cards de `enviados / entregados / leídos / respondidos` en ninguna página.
**Impacto:** No se puede medir el rendimiento de las campañas.
**BE necesario:** 🔧 `GET /api/v1/whatsapp/metricas/` (mock: devuelve conteos fijos por estado)
**Solución FE:**
- 4 KPI cards en `/whatsapp/mensajes`: Enviados, Entregados, Leídos, Respondidos
- Usar los datos de `useFinanzasXxx` pattern pero para whatsapp

---

### 🟡 GAP-W2: Vista de creación de campaña masiva
**Qué falta:** No existe página ni modal para enviar un mensaje a múltiples destinatarios a la vez.
**Impacto:** Solo se puede enviar mensajes de uno en uno.
**BE necesario:** 🔧 `POST /api/v1/whatsapp/campana/` (mock: acepta lista de destinatarios + plantilla, devuelve `{ programados: N }`)
**Solución FE:**
- Nueva página `/whatsapp/campanas` con formulario: plantilla, lista destinatarios (textarea o CSV), botón enviar
- Agregar al sidebar

---

### 🟢 GAP-W3: Configuración de automatizaciones por evento
**Qué falta:** No hay UI para configurar "al ocurrir X → enviar plantilla Y a Z".
**BE necesario:** 🔧 `GET/POST /api/v1/whatsapp/automatizaciones/` (mock CRUD)
**Solución FE:**
- Nueva página `/whatsapp/automatizaciones` con lista de reglas y modal de creación
- Eventos disponibles: venta_completada, pedido_entregado, factura_vencida, cotizacion_enviada

---

## MÓDULO 8 — Reportes/Dashboard

### 🟢 GAP-R1: Filtro de fecha en dashboard principal
**Qué falta:** Los KPIs del dashboard siempre muestran el período actual. No se puede ver "ayer" o "semana pasada".
**BE necesario:** No (el endpoint ya acepta parámetros de fecha — verificar).
**Solución FE:**
- Date range picker en header del dashboard principal

---

## MÓDULO 9 — Usuarios/Roles

### 🟢 GAP-U1: SSO Google/Microsoft (botones decorativos → funcionales)
**Qué falta:** Los botones de login social son decorativos.
**BE necesario:** Requiere OAuth2 client IDs externos — **no implementable sin credenciales reales**.
**Estado:** Dejar como está. Marcar claramente en UI "Próximamente".

---

## RESUMEN EJECUTIVO DE GAPS

### A implementar AHORA (FE visual completo):

| # | Gap | Módulo | Dificultad | Necesita BE mock |
|---|-----|--------|------------|------------------|
| 1 | GAP-V1: Indicador offline en POS | Ventas | Baja | No |
| 2 | GAP-V2: Botón Consumidor Final | Ventas | Baja | No |
| 3 | GAP-FIN3: Página gestión períodos | Finanzas | Baja | No |
| 4 | GAP-F1: Stepper pipeline SUNAT | Facturación | Media | No |
| 5 | GAP-F2: Filtro por cliente en comprobantes | Facturación | Baja | No |
| 6 | GAP-I1: Tab Series en ficha producto | Inventario | Media | No |
| 7 | GAP-D1: Botón hoja de ruta PDF | Distribución | Baja | Verificar |
| 8 | GAP-FIN1: Importar extracto bancario | Finanzas | Media | Sí (mock) |
| 9 | GAP-FIN2: Panel matching conciliación | Finanzas | Alta | Sí (mock) |
| 10 | GAP-W1: Métricas campaña WhatsApp | WhatsApp | Baja | Sí (mock) |
| 11 | GAP-W2: Campaña masiva WhatsApp | WhatsApp | Media | Sí (mock) |
| 12 | GAP-F3: Banner modo DEMO facturación | Facturación | Baja | Sí (mock) |
| 13 | GAP-V3: KPIs cotizaciones | Ventas | Baja | Sí (mock) |

### Dejar para después (requieren integración externa real):
- GAP-U1: SSO Google/Microsoft → necesita OAuth2 client IDs
- PLE/PDT real → necesita formato TXT SUNAT por libro
- PDT real → necesita integración formularios SUNAT
- Modo offline completo (PWA + IndexedDB) → requiere arquitectura Service Worker
- Vista conductor móvil (PWA) → requiere PWA manifest + SW
- WhatsApp envío real → requiere cuenta Meta Business verificada

---

## ORDEN DE IMPLEMENTACIÓN SUGERIDO

### Sprint 1 — Rápidos sin BE (1 sesión)
1. GAP-V1: Banner offline POS
2. GAP-V2: Botón Consumidor Final
3. GAP-FIN3: Página períodos contables
4. GAP-F2: Filtro cliente en comprobantes
5. GAP-D1: Botón hoja de ruta (verificar endpoint BE primero)

### Sprint 2 — Media dificultad (1-2 sesiones)
6. GAP-F1: Stepper pipeline SUNAT en overview
7. GAP-I1: Tab Series en ficha producto
8. GAP-W1: KPIs campaña WhatsApp (+ BE mock)
9. GAP-F3: Banner modo DEMO (+ BE mock)
10. GAP-V3: KPIs cotizaciones (+ BE mock)

### Sprint 3 — Complejos (2+ sesiones)
11. GAP-FIN1: Importar extracto bancario (+ BE mock)
12. GAP-FIN2: Panel matching conciliación (+ BE mock)
13. GAP-W2: Campaña masiva WhatsApp (+ BE mock)

---

*Documento generado desde lectura directa del código fuente — 2026-02-23*
*Actualizar al completar cada gap.*
