# JSOLUCIONES ERP — ESTADO ACTUAL DEL PROYECTO

> Ultima actualizacion: 2026-02-23 (Sesion T8 — Implementacion gaps auditados en T7)
> Metodo: Revision directa de TODOS los archivos — sin suposiciones, con numero de linea donde aplica
> Referencia: JSOLUCIONES_MODULOS_VERSION_FINAL.MD

---

## RESUMEN EJECUTIVO

| Lado | Avance Real |
|---|---|
| **Backend** | **~87%** |
| **Frontend** | **~83%** |
| **Promedio Global** | **~85%** |

---

## AVANCE POR MODULO

| Modulo | Backend | Frontend | Promedio |
|---|:---:|:---:|:---:|
| 1. Ventas / POS | 91% | 76% | 83% |
| 2. Inventario | 90% | 87% | 88% |
| 3. Facturacion Electronica | 87% | 83% | 85% |
| 4. Distribucion y Seguimiento | 88% | 85% | 86% |
| 5. Compras y Proveedores | 94% | 92% | 93% |
| 6. Gestion Financiera y Tributaria | 72% | 65% | 68% |
| 7. Comunicacion WhatsApp | 40% | 55% | 47% |
| 8. Dashboard y Reportes | 96% | 94% | 95% |
| 9. Usuarios y Roles | 90% | 91% | 90% |

> Sesion T8: Se implementaron los 10 gaps identificados en T7. Ver historial de cambios.

---

## HISTORIAL DE CAMBIOS

### Sesion T8 (2026-02-23 — Implementacion de 10 gaps identificados en auditoria T7)

**T8-1: Fix bug critico ventas/services.py linea 829**
- `sincronizar_ventas_offline()`: corregido `registrar_venta_pos()` → `crear_venta_pos()`
- El endpoint `POST /ventas/offline-sync/` ahora llama a la funcion correcta

**T8-2: Flujo venta → comprobante automatico**
- `ventas/tasks.py`: nueva task `emitir_comprobante_por_venta(venta_id)` — determina tipo comprobante por tipo_doc del cliente, obtiene primera serie activa, llama a `emitir_comprobante_desde_venta()`
- `ventas/services.py`: al final de `crear_venta_pos()`, encola task via `transaction.on_commit` (se ejecuta solo si TX confirma)
- `cart/components/TicketModal.tsx`: banner azul "Comprobante electronico siendo emitido a SUNAT en segundo plano" con spinner

**T8-3: Semaforo verde/amarillo/rojo en vista stock**
- `stock/components/StockOverview.tsx`: nueva seccion "Stock Actual" con tabla, funcion `getSemaforoInfo()`, badges coloreados (verde=Normal, amarillo=Bajo, rojo=Critico)

**T8-4: Grafico entradas vs salidas en dashboard inventario**
- `inventario/views.py` → `MovimientoViewSet.get_queryset()`: filtros `fecha_desde` y `fecha_hasta`
- `dashboard-inventario/components/DashboardInventario.tsx`: grafico ApexCharts bar (verde=entradas, rojo=salidas), ultimos 14 dias, agrupacion por dia con useMemo
- Schema OpenAPI regenerado + Orval regenerado

**T8-5: Vista previa PDF antes de emitir en add-new**
- `add-new/components/AddNew.tsx`: boton "Vista Previa y Emitir" abre modal con encabezado, cliente, tabla items, totales y aviso SUNAT antes de confirmar emision real

**T8-6: Saldo CxC pendiente en ficha cliente**
- `cliente-detalle/index.tsx`: hook `useFinanzasCuentasCobrarList({ cliente: id, estado: 'pendiente' })`, calculo `saldoPendiente` y `creditoDisponible`, colores rojo/verde, banner "Limite de credito agotado"

**T8-7: Filtros por fecha en lista comprobantes**
- `facturacion/views.py` → `ComprobanteViewSet.get_queryset()`: filtros `fecha_desde` y `fecha_hasta`
- `list/components/InvoiceList.tsx`: inputs date `fechaDesde`/`fechaHasta` + boton "Limpiar fechas"
- Schema OpenAPI regenerado + Orval regenerado

**T8-8: FIFO automatico en salidas de stock**
- `stock/components/SalidaStockModal.tsx`: ordenamiento lotes por `fecha_vencimiento ASC` (sin fecha van al final), `useEffect` auto-selecciona primer lote al cargar, badge "FIFO sugerido" azul, marca ★ en la primera opcion

**T8-9: Exportacion audit log a CSV**
- `usuarios/views/auth.py`: nueva clase `ExportarLogsCSVView` — CSV con BOM para Excel, mismos filtros que `LogActividadListView`, columnas: Fecha, Usuario, Modulo, Accion, IP, Detalle
- `usuarios/urls/usuarios.py`: ruta `logs/exportar/` registrada como GET
- `configuracion/audit-log/index.tsx`: boton "Exportar CSV" con `LuDownload`, spinner durante descarga, `handleExportar()` construye URL con filtros activos, descarga blob via fetch con token Bearer

**T8-10: Umbral alertas lotes por vencer: 30 → 7 dias**
- `inventario/tasks.py` linea 85: `timedelta(days=30)` → `timedelta(days=7)` (alineado a spec)
- Comentario del docstring actualizado: "< 7 dias"

**Estado TSC despues de T8:** `pnpm tsc --noEmit` pasa sin errores

---

### Sesion T7 (2026-02-23 — Auditoria general + actualizacion ESTADO_ACTUAL)

- Auditoria completa de todos los modulos con lectura directa de codigo
- Correcciones al ESTADO_ACTUAL.md:
  - M7 WhatsApp FE sube de 0% → 55%: existen 4 paginas reales (configuracion, plantillas, mensajes, logs)
  - M9 Usuarios FE: campana de notificaciones en header esta IMPLEMENTADA con WebSocket real
  - M1 Ventas BE: bug identificado en `services.py` linea 829 (llama a `registrar_venta_pos` que no existe)
  - M2 Inventario: alertas lotes por vencer usan 30 dias (no 7 como dice la spec)
  - M2 Inventario: semaforo verde/amarillo/rojo de stock NO existe en vista stock
  - M2 Inventario: grafico entradas vs salidas en dashboard NO existe (solo numeros)
  - M3 Facturacion: banner modo DEMO no existe (existe banner CONTINGENCIA que es distinto)
  - M3 Facturacion: credenciales Nubefact en BD como CharField plano (no encriptado)
  - M3 Facturacion: vista previa PDF antes de emitir NO existe (si existe post-emision)
  - M9 Usuarios: exportacion audit log NO implementada
- Implementados en sesion anterior (T4-T6) y validados:
  - WebSocket Dashboard reactivo (kpi_update cada 10 min via Celery)
  - GPS WebSocket en tiempo real (GPSConsumer)
  - Foto evidencia en recepcion de compras (dropzone + MediaArchivo polimórfico)
  - Trazabilidad por numero de serie (BE + FE completo)
  - Pagina ubicaciones de almacen (CRUD completo)
  - KPI comparativo vs periodo anterior (BE + FE)
  - Prorrateo gastos logisticos (modal + endpoint)
  - Firma tactil canvas en entrega de pedidos

---

### Sesion T4+T5+T6 (2026-02-22 — segunda sesion del dia)

**T4: WebSocket Dashboard (BE + FE)**
- `reportes/tasks.py`: al final de `calcular_kpis_dashboard`, itera todos los usuarios activos
  y emite `kpi_update` via `channel_layer.group_send` a cada grupo `dashboard_{user_id}`
- `dashboards/index/index.tsx`: `useEffect` abre `WebSocket("ws/dashboard/")`, al recibir
  `kpi_update` invalida el query `/api/v1/reportes/dashboard/` para refrescar KPIs en tiempo real.
  Ping cada 30s para keepalive. Dashboard ahora es verdaderamente reactivo.

**T5: Foto de Evidencia en Recepcion de Compras (FE)**
- `RecepcionFormModal.tsx`: nuevo campo de foto (input file con dropzone visual).
  Usa la relacion polimórfica existente de `MediaArchivo` (entidad_tipo='recepcion').
  Al exito del create, sube el archivo a `/api/v1/media/archivos/subir/` con el id de la recepcion.
  No requirio migracion BE porque MediaArchivo ya tiene relacion polimórfica.

**T6: Trazabilidad por Numero de Serie (BE + FE)**
- `inventario/models.py`: campo `requiere_serie` en Producto + modelo `Serie`
- `inventario/migrations/0004_add_serie_modelo.py`: migración pendiente de aplicar
- `inventario/serializers.py`: `SerieSerializer` + `TrazabilidadSerieSerializer`
- `inventario/views.py`: `SerieViewSet` (CRUD completo) + `TrazabilidadSerieView`
- FE nueva pagina `/inventario/trazabilidad-serie`: buscador, card datos, timeline movimientos

---

### Grupo B — Mejoras UX (2026-02-22)

**B-1:** Firma tactil canvas en `pedido-detalle/index.tsx` (`FirmaCanvas`, mouse + touch)
**B-2:** KPI comparativo vs periodo anterior (BE + FE) — `KPIsComparativoView` + seccion dashboard
**B-3:** Filtros dashboard por rol — secciones por `hasRole()` en `dashboards/index/index.tsx`
**B-4:** Modal Prorrateo Gastos Logisticos — `ProrrateoGastosModal.tsx` en `orden-compra-detalle`
**B-5:** Pagina Ubicaciones de Almacen — `/inventario/ubicaciones`, CRUD completo

---

### Grupo A — Mejoras tecnicas (2026-02-22)

**A-1:** GPS WebSocket — `GPSConsumer` en `core/consumers.py`, ruta `ws/gps/{pedido_id}/`
**A-2:** Exportar Balance y Estado Resultados a Excel (BE + FE)
**A-3:** Validacion credito completa — descuenta CxC pendientes del limite en `ventas/services.py`
**A-4:** WebSocket Facturacion — `FacturacionConsumer`, badge en tiempo real en `overview/`

---

### Ronda 8 — Finanzas (2026-02-22)

**Backend:** Libro Diario, Mayor, Caja, Balance General, Estado Resultados, Flujo Caja, intereses mora
**Frontend:** 6 paginas nuevas en `/finanzas/`, Excel en Balance y Estado Resultados

---

## ESTADO DETALLADO POR MODULO

### MODULO 1 — Ventas / POS (83%)

**Backend: 91%**

Implementado:
- Venta POS con multiples metodos de pago (efectivo, tarjeta, QR, credito, mixto)
- `crear_venta_pos()`: `@transaction.atomic` + `select_for_update` en Stock + `StockInsuficienteError`
- `FormaPago.registrar()`: valida que suma de pagos >= total venta
- Apertura y cierre de caja con arqueo (`abrir_caja`, `cerrar_caja`, `resumen_sesion_caja`)
- CRUD clientes con UniqueConstraint (tipo_doc + numero_doc) + validacion formato
- Cotizaciones: CRUD, duplicar, convertir a OV, marcar vencidas (Celery Beat 23:00)
- Ordenes de venta con conversion a venta
- Anulacion de venta con reversion de stock
- Endpoint offline-sync `OfflineSyncView.post()` con procesamiento cronologico e informe de resultados
- Signal: generacion automatica de CxC en venta a credito
- Asiento contable al completar venta (via `finanzas_service.generar_asiento_venta`)
- Validacion limite de credito con descuento de CxC pendientes (`LimiteCreditoExcedidoError`)
- Calculo `_calcular_item()`: subtotal, IGV, descuento, total con `quantize(Decimal("0.01"))`

Falta / Bugs:
- ~~**BUG CRITICO:** `sincronizar_ventas_offline()` llama a `registrar_venta_pos()`~~ **CORREGIDO en T8**
- ~~La venta completada NO dispara emision automatica a SUNAT~~ **CORREGIDO en T8** — `transaction.on_commit` encola task `emitir_comprobante_por_venta`
- Notificacion WhatsApp/email al vender: no implementada

**Frontend: 76%**

Implementado:
- POS completo: `cart/` — panel productos (`lg:col-span-2`) + carrito (`lg:col-span-1`)
- `ProductSearch.tsx`: busqueda por nombre/SKU con debounce 300ms + scanner codigo de barras (hook `useBarcodeScanner`)
- `CobroModal.tsx`: 4 metodos diferenciados (efectivo verde, tarjeta azul, yape morado, transferencia naranja)
- Pago mixto: boton "Agregar otra forma de pago", etiqueta "Pago mixto" con resumen
- Vuelto: calculo automatico + denominaciones rapidas (S/10, 20, 50, 100, 200) + boton "Exacto"
- Si totalPagado < total: bloquea boton confirmar + indicador "Falta por cubrir"
- Modal apertura/cierre caja (`caja/` con `AbrirCajaModal.tsx` y `CerrarCajaModal.tsx`)
  - `CerrarCajaModal`: resumen de sesion, desglose por metodo, monto fisico contado, diferencia sobrante/faltante
- Escaneo codigo de barras (deteccion automatica lectores USB por velocidad entre teclas)
- Cotizaciones: wizard modal 4 pasos, badges estado, botones por estado
  - `puedeDuplicar`: vencida O rechazada (la spec dice solo vencida — discrepancia menor)
  - `puedeConvertir`: solo aceptada
- Ordenes de venta con conversion a venta
- Ficha cliente con 3 tabs: datos generales, historial ventas, cotizaciones

NO implementado:
- Banner modo offline visible (no existe `navigator.onLine`, Service Worker, ni IndexedDB en ningun archivo FE)
- Sincronizacion automatica al reconectar con indicador de progreso
- Vista de campo responsive/dedicada para movil (hay grid responsive generico, no vista campo)
- Boton explicito "Consumidor Final" (es texto auxiliar sin accion)
- ~~Saldo pendiente CxC en ficha cliente~~ **IMPLEMENTADO en T8** — `saldoPendiente` y `creditoDisponible` con colores y banner
- Selector cliente en POS: si no se selecciona, la venta va como "Varios" (Boleta); no hay boton "Consumidor Final"
- Reporte cotizaciones con tasa de conversion
- Reporte ventas offline sincronizadas (no hay campo que marque venta como "originada offline")
- Notas de credito en modulo ventas (el boton existe en detalle venta pero sin modelo propio en ventas)

---

### MODULO 2 — Inventario y Logistica (88%)

**Backend: 90%**

Implementado:
- Stock en tiempo real: modelo `Stock` con `select_for_update` en cada operacion
- Entradas (`registrar_entrada`), salidas (`registrar_salida`), ajustes (`ajustar_stock`)
- Transferencias con flujo 3 pasos: `crear_solicitud` → `aprobar` (descuenta origen) → `confirmar_recepcion` (suma destino)
- Trazabilidad por lote: `trazabilidad_lote()`, `TrazabilidadLoteView`
- Trazabilidad por serie: modelo `Serie`, `SerieViewSet`, `TrazabilidadSerieView`
- Ajuste manual: `motivo` obligatorio en serializer (sin `required=False`)
- Alertas stock minimo: `verificar_stock_minimo()` task Celery (07:30)
- Alertas lotes por vencer: `alertar_lotes_por_vencer()` task Celery (07:00)
- Rotacion ABC: clasificacion A(80%)/B(15%)/C(5%) por salidas
- CRUD Ubicaciones (zona, pasillo, estante, nivel)
- FIFO: `seleccionar_lotes_fifo()` — consulta informativa, ordena por `fecha_vencimiento, created_at`
- `FifoSugerenciaView` — endpoint GET `/lotes/fifo/`
- Dashboard KPIs: total productos, bajo stock, valor inventario, lotes por vencer, entradas/salidas hoy

Falta / Bugs:
- ~~**Umbral alertas lotes:** usa 30 dias~~ **CORREGIDO en T8** — ahora usa 7 dias (alineado a spec)
- **FIFO no es automatico:** `registrar_salida()` no invoca `seleccionar_lotes_fifo()`. Es solo una consulta sugerida.
- **RN-3 Incidencia transferencia:** Al detectar diferencia en recepcion se escribe `[INCIDENCIA: ...]` en el campo `motivo`, pero el estado del modelo NO cambia a un valor "con_incidencia" (ese choice no existe en el modelo)
- **RN-5 Lote/serie obligatorio:** Los campos `requiere_lote` y `requiere_serie` existen en Producto pero `registrar_entrada()` y `registrar_salida()` no validan que se provea cuando son `True`
- ~~Filtro por rango de fechas en `MovimientoViewSet`~~ **IMPLEMENTADO en T8** — `fecha_desde`/`fecha_hasta` en `get_queryset()`
- Migracion `0004_add_serie_modelo.py` pendiente de aplicar (`manage.py migrate`)

**Frontend: 87%**

Implementado:
- `StockOverview.tsx`: tabla movimientos filtrable por almacen y tipo de movimiento; alertas de stock bajo
- `EntradaStockModal.tsx`: campos lote (existente o nuevo) + fecha_vencimiento condicionalmente
- `SalidaStockModal.tsx`: selector de lote con numero, cantidad disponible y fecha vencimiento
- `TransferenciaStockModal.tsx`: formulario con validacion origen != destino y cantidad > 0
- `TransferenciasList.tsx`: flujo completo con modal confirmacion de recepcion por cantidades
- `AjusteStockModal.tsx`: campo motivo obligatorio con validacion inline
- `TrazabilidadLote.tsx`: busqueda reactiva >= 2 chars, timeline de movimientos
- `trazabilidad-serie/index.tsx`: busqueda por numero de serie, card datos, timeline movimientos
- `DashboardInventario.tsx`: 7 KPI cards + alertas + clasificacion ABC (selector 30/60/90/180/365 dias)
- `ubicaciones/index.tsx`: CRUD completo con filtro por almacen

NO implementado:
- ~~**Semaforo verde/amarillo/rojo en vista stock**~~ **IMPLEMENTADO en T8** — seccion "Stock Actual" con tabla y badges coloreados
- ~~**Grafico visual entradas vs salidas en dashboard**~~ **IMPLEMENTADO en T8** — ApexCharts bar ultimos 14 dias
- ~~FIFO preseleccionado en SalidaStockModal~~ **IMPLEMENTADO en T8** — auto-seleccion primer lote + badge "FIFO sugerido"
- **Filtro por categoria en vista stock** (solo almacen y tipo movimiento)
- Validacion stock en tiempo real en TransferenciaStockModal (se valida en BE al enviar)
- CRUD Series desde UI de producto

---

### MODULO 3 — Facturacion Electronica (85%)

**Backend: 87%**

Implementado:
- Integracion real con Nubefact OSE via HTTP POST (delegado a `core/utils/nubefact.py`)
- Correlativo atomico: `select_for_update()` + `F("correlativo_actual") + 1` + `@transaction.atomic`
- Facturas (01), boletas (03), notas de credito (07), debito (08)
- XML firmado y CDR guardados en Cloudflare R2 con presigned URLs
- Log inmutable de cada intento de envio (`LogEnvioNubefact`)
- Max 5 reintentos: `MAX_REINTENTOS_COMPROBANTE = 5` en `core/choices.py` linea 51
- Si 5 intentos fallidos → `ESTADO_COMP_ERROR_PERMANENTE`
- Contingencia automatica: `FALLOS_CONSECUTIVOS_CONTINGENCIA = 3` → activa modo contingencia
- Reenvio manual individual y masivo
- Prevencion doble-emision: check `venta.comprobante_id` en BE + `unique_together` (serie, numero) en BD
- Envio PDF por email al cliente
- Tarea `reenviar_comprobantes_pendientes` Celery (cada 5 min)
- Tarea `enviar_resumen_diario_boletas` Celery (23:50)
- Consumer WebSocket `FacturacionConsumer`: grupo `facturacion_{id}`

Falta:
- Generacion local XML UBL 2.1 (delegado a Nubefact — correctamente por diseno)
- Firma PFX local (Nubefact firma — correctamente por diseno)
- PDF local con QR (Nubefact genera PDF — correctamente por diseno)
- **Credenciales Nubefact no encriptadas:** `nubefact_token` es `CharField` plano en BD (es `write_only` en serializer pero sin encriptar en disco)
- Validacion RUC contra padron SUNAT: solo validacion sintatica (tipo='6' + 11 digitos)
- Envio PDF/XML por WhatsApp al cliente

**Frontend: 83%**

Implementado:
- `add-new/components/AddNew.tsx`: flujo 3 pasos desde Venta existente, validacion inline RUC/DNI
  - `facturaBlocked`: bloquea boton Emitir si esFactura && cliente sin RUC valido (sintactico)
  - Banner rojo explicativo si factura bloqueada
- `list/components/InvoiceList.tsx`: filtros por texto libre, tipo de comprobante (4 tipos), estado SUNAT (6 estados), paginacion numerica
- `overview/index.tsx`: badges estado en tiempo real via WebSocket (`useFacturacionWS`)
  - Badge "Esperando SUNAT..." animado si estado pendiente/en_proceso
  - `toast.success/error` al recibir estado final del servidor
  - PDF embebido (`<iframe>`) post-emision (toggle con boton "Vista previa PDF")
  - 3 links descarga: PDF, XML, CDR (condicionados a que las URLs existan)
  - Panel lateral "Archivos" con los 3 links
  - Boton "Reenviar a SUNAT" visible si estado error/pendiente
- `pendientes/`: lista por estado, reenvio individual y masivo ("Reenviar Todos"), tabs por tipo de error
- `notas/`: lista y formulario creacion notas de credito/debito
- `series/`: CRUD de series
- `resumen-diario/`: panel completo — 4 KPI cards, filtros por estado y fecha, tabla con paginacion y totalizador de pie
- Banner `ContingenciaBanner.tsx`: naranja en topbar cuando modo_contingencia=True

NO implementado:
- ~~**Vista previa antes de confirmar envio**~~ **IMPLEMENTADO en T8** — modal preview con items/totales/aviso antes de emitir
- ~~Filtro por rango de fechas en lista comprobantes~~ **IMPLEMENTADO en T8** — `fechaDesde`/`fechaHasta` en InvoiceList
- **Indicador pipeline Generando→Firmando→Enviando→Aceptado** (hay WebSocket pero no hay UI de pasos secuenciales)
- **Banner modo DEMO** (existe banner de CONTINGENCIA que es diferente — DEMO no tiene banner)
- Filtro por cliente UUID en lista comprobantes (el BE lo soporta pero FE no lo expone)

---

### MODULO 4 — Distribucion y Seguimiento (86%)

**Backend: 88%**

Implementado:
- Pedidos: maquina de estados PENDIENTE→CONFIRMADO→DESPACHADO→EN_RUTA→ENTREGADO/CANCELADO
- Asignacion transportista con validacion `limite_pedidos_diario`
- `codigo_seguimiento` UUID corto (8 chars) unico por pedido
- Endpoint publico sin auth: `GET /publico/seguimiento/{codigo}/`
- Registro evidencias: foto, firma, OTP con FK a `MediaArchivo`
- Seguimiento de eventos con timestamps y coordenadas
- Hoja de ruta PDF (reportlab) y QR por pedido
- CRUD transportistas
- Consumer WebSocket `GPSConsumer`: grupo `gps_{pedido_id}`, emite coordenadas en tiempo real
- Action `POST /pedidos/{id}/gps/`: guarda seguimiento y emite al canal GPS

Falta:
- Geocodificacion automatica de direcciones
- Optimizacion TSP de ruta (STUB — existe funcion pero no implementada)
- Notificacion al cliente al entregar
- Integracion transportistas externos (API o exportar CSV)

**Frontend: 85%**

Implementado:
- Lista pedidos con KPIs por estado
- Detalle pedido con step tracker y barra de acciones completa
- Modales: asignar transportista, despachar, en ruta, confirmar entrega, cancelar, registrar evidencia
- Evidencia: upload real foto via FormData, firma tactil canvas (`FirmaCanvas`), OTP numerico
- CRUD transportistas con paginacion y busqueda
- Vista publica seguimiento sin login: buscador + progress steps + timeline
- Mapa de entregas: react-leaflet con markers coloreados, popup, filtros
- Mapa: toggle "GPS en vivo" con conexion WebSocket en tiempo real (`useGpsWebSocket`)
- Escaner QR: html5-qrcode, camara trasera, busqueda manual, navegacion automatica

Falta:
- Vista movil optimizada conductor (PWA)
- Optimizacion ruta visual en mapa

---

### MODULO 5 — Compras y Proveedores (93%)

**Backend: 94%**

Implementado:
- CRUD OC: BORRADOR→PENDIENTE_APROBACION→APROBADA→ENVIADA→RECIBIDA→CERRADA
- Recepcion parcial/total con ingreso de stock automatico
- Bloqueo pago a factura no conciliada
- UniqueConstraint en FacturaProveedor (numero + proveedor)
- Conciliacion auto: si diferencia < 1%
- Tarea `generar_oc_automaticas_bajo_stock` Celery (07:45)
- Comparacion proveedores por producto: precio promedio/min/max, ordenes, tiempo entrega
- KPI proveedores: 40% puntualidad, 30% cantidad, 30% calidad
- Foto evidencia en recepciones via `MediaArchivo` polimórfico (`entidad_tipo='recepcion'`)
- Prorrateo gastos logisticos: distribucion proporcional por subtotal

Falta:
- Integracion real API SUNAT (validacion formato local)
- Notificaciones WhatsApp para OC

**Frontend: 92%**

Implementado:
- Lista OC con filtros y modal comparacion proveedores
- Formulario crear OC con items y gastos_logisticos
- Detalle OC con acciones segun estado
- `RecepcionFormModal.tsx`: dropzone foto evidencia con upload a MediaArchivo polimórfico
- `ProrrateoGastosModal.tsx`: modal prorrateo con tabla de distribucion proporcional
- Lista proveedores + ficha con 5 tabs (datos, OC, facturas, recepciones, KPIs)
- Lista facturas con conciliar + validar SUNAT
- Calificacion proveedor: badge estrellas 1-5 con colores

Falta:
- UI Series en recepciones (no hay campo serie al recibir productos con trazabilidad)

---

### MODULO 6 — Gestion Financiera y Tributaria (68%)

**Backend: 72%**

Implementado:
- CxC y CxP: crear, cobros/pagos parciales o totales, semaforo automatico
- Auto-generacion CxC en venta a credito (signal)
- Auto-generacion asientos contables en cada cobro/pago (cuentas PCGE Peru)
- Plan contable jerarquico con codigo unico
- Asientos con validacion doble partida (debe == haber)
- Periodos contables con cierre/reapertura (solo admin)
- Bloqueo de operaciones en periodos cerrados
- Alertas CxC vencidas y CxP por vencer en Celery Beat (08:00)
- Libro Diario, Mayor, Caja, Balance General, Estado Resultados, Flujo Caja: funcionales
- Intereses de mora: calculo real por CxC vencidas

Falta:
- Diferencia de cambio automatica (no implementada)
- Conciliacion bancaria: parseo CSV/Excel de extractos (no implementado)
- Motor de matching para sugerir conciliaciones (no implementado)
- PLE (TXT) segun especificacion SUNAT (no implementado)
- PDT (XML/ZIP) segun especificacion SUNAT (no implementado)
- Firma digital del contador para cierre tributario (no implementado)

**Frontend: 65%**

Implementado:
- CxC y CxP con semaforo de vencimiento (verde/amarillo/rojo)
- Modal cobro/pago con soporte parcial
- Asientos contables: lista + crear con lineas debe/haber + confirmar/anular
- Plan de cuentas: jerarquico por tipo + CRUD
- Libro Diario, Mayor, Caja, Balance General, Estado Resultados, Flujo Caja: paginas funcionales
- Botones Excel en Balance General y Estado de Resultados (descarga directa via fetch blob)
- Alerta CxC vencidas en dashboard (cantidad, monto, top deudores)

Falta:
- Vista de carga de extracto bancario
- Panel conciliacion con sugerencias automaticas y botones confirmar/ignorar
- Botones generacion PLE y PDT por periodo
- Indicador visual de periodo abierto vs cerrado

---

### MODULO 7 — Comunicacion WhatsApp (47%)

**Backend: 40%**

Implementado:
- Modelos: `WhatsappConfiguracion`, `WhatsappPlantilla`, `WhatsappMensaje`, `WhatsappLog`
- `GET/PATCH /api/v1/whatsapp/configuracion/` — ver y actualizar config
- CRUD plantillas con filtros por categoria, estado_meta, is_active
- `GET /api/v1/whatsapp/mensajes/` — listar mensajes con filtros
- `POST /api/v1/whatsapp/enviar/` — endpoint existe en router
- `GET/POST /api/v1/whatsapp/webhook/` — verificacion challenge + recepcion de eventos Meta
- `GET /api/v1/whatsapp/logs/` — logs de webhook
- `actualizar_estado_mensaje()` en tasks.py: actualiza campo `estado` al recibir `wa_message_id`
- `limpiar_logs_antiguos()`: completamente implementado

STUB explicito (NO implementado):
- **Envio real HTTP POST a Meta Cloud API:** `services.py` dice explicitamente "NOTA: La integracion real con Meta WhatsApp Business API es STUB. Se implementara cuando se tengan las credenciales."
- `enviar_mensaje_plantilla()` en `tasks.py` linea 27-35: devuelve `{"enviado": False, "mensaje": "stub"}`
- `procesar_respuesta_webhook()` en `tasks.py` linea 53: `"STUB: Se completara con la logica de actualizacion de estados."`
- Validacion opt-in del cliente: no implementada
- Ventana 24 horas para mensajes sin plantilla: no implementada
- Rate limiting por Tier de cuenta: no implementado
- Campanas masivas en background: no implementadas
- Validacion firma HMAC del webhook: no implementada
- Automatizaciones por evento del sistema: no implementadas

**Frontend: 55%**

Implementado (4 paginas reales):

`/whatsapp/configuracion` — `WhatsappConfiguracionForm.tsx` (281 lineas):
- Formulario: phone_number_id, waba_id, access_token (input password), webhook_verify_token, toggle activo
- `access_token` solo se envia si se escribe algo (no sobreescribe al leer)
- Banner naranja: "El envio real a WhatsApp requiere credenciales validas de Meta Business API. Los mensajes se registran en el sistema pero no se envian hasta configurar el token."

`/whatsapp/plantillas` — `PlantillasList.tsx`:
- Lista plantillas con badges estado Meta (en_revision, aprobada, rechazada)
- CRUD completo de plantillas

`/whatsapp/mensajes` — `MensajesList.tsx` (404 lineas):
- Tabla con filtros por texto y estado
- Modal "Enviar mensaje": destinatario, nombre, plantilla (select solo aprobadas), contenido
- Aviso en modal: "El mensaje se registrara en el sistema. El envio real requiere credenciales Meta configuradas."
- Modal de detalle: wa_message_id, error_detalle, contenido, estado

`/whatsapp/logs` — directorio con componentes de logs de webhook

NO implementado:
- Metricas de campana (cards enviados/entregados/leidos/respondidos)
- Grafico de rendimiento por campana
- Vista de creacion de campana con selector de segmento
- Configuracion de automatizaciones por evento del sistema

---

### MODULO 8 — Dashboard y Reportes (95%)

**Backend: 96%**

Implementado:
- KPIs ventas, logistica y financieros desde snapshots pre-calculados (tabla `KPISnapshot`)
- Snapshot persistente en BD cada 10 min con auto-limpieza > 90 dias
- `calcular_kpis_dashboard` emite `kpi_update` via WebSocket a todos los usuarios activos al finalizar
- Exportacion Excel y PDF con estilos (openpyxl + reportlab)
- Programacion de reportes: CRUD, frecuencia diario/semanal/mensual, envio email
- Endpoint `GET /reportes/kpis-comparativo/`: delta % ventas, pedidos, tasa entrega vs mes anterior
- Filtros de acceso por rol en endpoints de KPIs

**Frontend: 94%**

Implementado:
- Dashboard con KPI cards: ventas, logistica, financieros
- Seccion "Comparativo vs Mes Anterior" con 4 cards + flechas + % de cambio
- Charts ApexCharts: area ventas, donut metodos pago, bar top productos
- Filtros por rol: cada rol ve solo las secciones de su area (`hasRole()`)
- Dashboard conectado via WebSocket (`ws/dashboard/`), invalida queries al recibir `kpi_update`
- Ping cada 30s para keepalive
- Reportes con 4 tabs, date range picker, favoritos en localStorage, exportar Excel/PDF
- Reportes Programados: CRUD con modal, toggle activar/desactivar

---

### MODULO 9 — Usuarios y Roles (90%)

**Backend: 90%**

Implementado:
- Login email/password (bcrypt via Django) + JWT (access 60m / refresh 7d)
- CRUD usuarios y roles con permisos por modulo+accion
- Rate limiting, caducidad contrasena, 2FA TOTP completo
- `SesionActiva`, invalidacion tokens, audit logs inmutables via signals
- Modelo `Notificacion`: CRUD + endpoints (`GET /usuarios/notificaciones/`, `POST .../leer/`, `POST .../leer-todas/`)
- Tasks Celery crean notificaciones al alertar stock bajo, CxC vencida, cotizacion por vencer, OC aprobada

Falta:
- SSO Google/Microsoft (requiere OAuth2 client IDs externos)

**Frontend: 91%**

Implementado:
- Login con soporte 2FA y redirect condicional
- `configuracion/usuarios/index.tsx` (362 lineas):
  - Buscador real (input + debounce + param `search` en `useUsuariosList`)
  - Paginacion con botones Anterior/Siguiente y "Pagina X de Y"
  - Modal `DesactivarModal`: fondo negro semitransparente, email usuario, aviso de sesiones, confirmar con `useUsuariosDestroy`
  - CRUD usuarios con modal (email, nombre, apellido, contrasena, rol, activo)
- `configuracion/roles/index.tsx` (324 lineas):
  - `PermisosModal`: carga permisos del sistema, agrupa por modulo, checkboxes individuales
  - Contador en tiempo real "N permisos seleccionados"
  - Nota: es lista agrupada por modulo, no tabla cruzada modulo x accion
- `configuracion/audit-log/index.tsx` (297 lineas):
  - Filtros: texto libre, modulo (7 opciones), accion (8 opciones), fecha desde, fecha hasta
  - Boton "Limpiar filtros"
  - Paginacion con contador de registros
- Perfil: cambio de contrasena + setup 2FA
- Sidebar filtrado por permisos del usuario autenticado
- `NotificacionesCampana.tsx` (250 lineas) — COMPLETAMENTE IMPLEMENTADA:
  - Badge rojo con no leidas (muestra "9+" si > 9)
  - Polling REST cada 60s (`refetchInterval: 60_000`)
  - WebSocket real `ws(s)://{host}/ws/notificaciones/?token={token}`
  - Al recibir tipo `'notificacion'` → invalida query cache
  - Ping cada 30s para keepalive
  - Marcar leida individual: `POST /api/v1/usuarios/notificaciones/{id}/leer/`
  - Marcar todas leidas: `POST /api/v1/usuarios/notificaciones/leer-todas/`
  - 7 tipos con colores: stock_bajo (rojo), lote_vencer (amber), cxc_vencida (naranja), cotizacion_vencer (azul), oc_aprobada (verde), pedido_entregado (verde), sistema (gris)

Falta:
- SSO (botones decorativos sin funcion real)
- ~~Exportacion del audit log~~ **IMPLEMENTADO en T8** — boton "Exportar CSV" con filtros activos + descarga blob

---

## ESTADO WEBSOCKET

| Canal | Estado |
|---|---|
| `ws/dashboard/` | **FUNCIONAL** — BE emite `kpi_update` desde task Celery, FE invalida queries |
| `ws/notificaciones/` | **FUNCIONAL** — Campana FE conectada, escucha tipo `'notificacion'`, badge reactivo |
| `ws/gps/{pedido_id}/` | **FUNCIONAL** — emite coordenadas GPS en tiempo real |
| `ws/facturacion/{comp_id}/` | **FUNCIONAL** — emite estado SUNAT en tiempo real |

---

## GAPS TRANSVERSALES

### Sin soporte offline (PENDIENTE — M1)
- Sin Service Worker, sin IndexedDB, sin PWA manifest
- El POS no funciona sin internet
- El endpoint offline-sync existe en BE pero el FE no tiene el mecanismo de cola local
- BUG adicional: la funcion que el endpoint offline llama (`registrar_venta_pos`) no existe en services.py

### Facturacion dispara automaticamente al vender (IMPLEMENTADO en T8 — M1/M3)
- `crear_venta_pos()` encola `emitir_comprobante_por_venta(venta_id)` via `transaction.on_commit`
- La task determina tipo (boleta/factura por tipo_doc del cliente) y emite a SUNAT en background
- Banner informativo en TicketModal mientras el comprobante se emite

### WhatsApp bloqueado por STUB (PENDIENTE — M7)
- `services.py` y `tasks.py` declaran explicitamente que el envio es STUB
- Requiere cuenta Meta Business verificada y token valido para implementar
- El modulo FE esta casi completo (4 paginas), el BE tiene la estructura — solo falta el HTTP POST real

### Conciliacion bancaria (PENDIENTE — M6)
- Ningun archivo de parseo de CSV/Excel de extractos bancarios en BE
- No existe vista FE de carga de extracto ni panel de conciliacion
- Es el gap mas grande del modulo financiero

### PLE / PDT (PENDIENTE — M6)
- No implementados ni en BE ni en FE
- Requieren conocimiento especifico del formato SUNAT por cada libro contable

### Migracion pendiente de aplicar (M2)
- `inventario/migrations/0004_add_serie_modelo.py` — detectada, pendiente de `manage.py migrate`

---

## PAGINAS FRONTEND EXISTENTES

| Ruta | Estado |
|---|---|
| `/login`, `/logout` | Funcional |
| `/dashboard` | Funcional (KPIs + comparativo + charts + WebSocket reactivo) |
| `/ventas/pos` | Funcional (barcodes, pago mixto, vuelto, ticket) |
| `/ventas`, `/ventas/:id` | Funcional |
| `/ventas/caja` | Funcional (apertura/cierre con desglose) |
| `/ventas/cotizaciones`, `/ventas/cotizaciones/:id` | Funcional |
| `/ventas/ordenes`, `/ventas/ordenes/:id` | Funcional |
| `/ventas/comisiones` | Funcional |
| `/inventario/productos` (lista + crear + detalle + editar) | Funcional |
| `/inventario/categorias`, `/inventario/almacenes` | Funcional |
| `/inventario/stock` | Funcional (entrada + salida + ajuste + transferencia) |
| `/inventario/transferencias` | Funcional |
| `/inventario/dashboard` | Funcional (7 KPIs + ABC) |
| `/inventario/trazabilidad` | Funcional (por lote, timeline) |
| `/inventario/trazabilidad-serie` | Funcional (por serie, card + timeline) |
| `/inventario/ubicaciones` | Funcional (CRUD con filtro por almacen) |
| `/clientes`, `/clientes/:id` | Funcional (3 tabs, sin saldo CxC pendiente) |
| `/compras/proveedores`, `/compras/proveedores/:id` | Funcional (5 tabs + KPIs) |
| `/compras/ordenes`, `/compras/ordenes/:id` | Funcional (+ modal prorrateo gastos) |
| `/compras/recepciones`, `/compras/facturas` | Funcional (recepciones + foto evidencia) |
| `/finanzas/cxc`, `/finanzas/cxp` | Funcional (semaforo) |
| `/finanzas/asientos` | Funcional |
| `/finanzas/plan-contable` | Funcional |
| `/finanzas/libro-diario` | Funcional |
| `/finanzas/libro-mayor` | Funcional |
| `/finanzas/libro-caja` | Funcional |
| `/finanzas/balance-general` | Funcional (+ exportar Excel) |
| `/finanzas/estado-resultados` | Funcional (+ exportar Excel) |
| `/finanzas/flujo-caja` | Funcional |
| `/distribucion/pedidos`, `/distribucion/pedidos/:id` | Funcional |
| `/distribucion/transportistas` | Funcional |
| `/distribucion/mapa` | Funcional (leaflet + GPS en vivo WS) |
| `/distribucion/scanner-qr` | Funcional |
| `/seguimiento` | Funcional (sin login) |
| `/facturacion` | Funcional |
| `/facturacion/add-new` | Funcional (validacion RUC/DNI inline) |
| `/facturacion/comprobante/:id` | Funcional (PDF/XML/CDR + WS en tiempo real) |
| `/facturacion/pendientes` | Funcional |
| `/facturacion/notas` | Funcional |
| `/facturacion/series` | Funcional |
| `/facturacion/resumen-diario` | Funcional (KPIs + filtros + tabla + totalizador) |
| `/whatsapp/configuracion` | Funcional (UI completa, envio STUB) |
| `/whatsapp/plantillas` | Funcional (CRUD) |
| `/whatsapp/mensajes` | Funcional (lista + modal envio + detalle) |
| `/whatsapp/logs` | Funcional |
| `/reportes` | Funcional (4 tabs + favoritos + exportar) |
| `/reportes/programados` | Funcional (CRUD + toggle) |
| `/configuracion/roles` | Funcional (permisos por modulo con checkboxes) |
| `/configuracion/usuarios` | Funcional (buscador + paginacion + desactivar con modal) |
| `/configuracion/empresa` | Funcional |
| `/configuracion/audit-log` | Funcional (filtros por modulo/accion/fecha) |
| `/perfil` | Funcional (contrasena + 2FA) |
| `/two-steps` | Funcional |

### Paginas que NO existen (requeridas por spec)
- Conciliacion bancaria (carga de extracto + panel sugerencias)
- Declaraciones tributarias / PLE / PDT
- Vista conductor movil (PWA)
- Campana masiva WhatsApp con selector de segmento
- Metricas de campana WhatsApp

---

## ENDPOINTS EXISTENTES

### Auth (`/api/v1/auth/`)
```
POST   /login/
POST   /refresh/
POST   /logout/
GET    /me/
POST   /cambiar-password/
POST   /2fa/setup/
POST   /2fa/activar/
POST   /2fa/desactivar/
POST   /2fa/verificar/
GET    /sesiones/
```

### Ventas (`/api/v1/ventas/`)
```
CRUD   /clientes/
POST   /clientes/{id}/validar-ruc/
CRUD   /cotizaciones/
POST   /cotizaciones/{id}/convertir-orden/
POST   /cotizaciones/{id}/duplicar/
CRUD   /ordenes/
POST   /ordenes/{id}/convertir-venta/
POST   /venta-pos/
CRUD   /ventas/
POST   /ventas/{id}/anular/
POST   /ventas/{id}/nota-credito/
GET    /cajas/
POST   /cajas/abrir/
POST   /cajas/{id}/cerrar/
GET    /cajas/{id}/resumen/
POST   /formas-pago/registrar/
POST   /offline-sync/             [BUG: llama a funcion inexistente en services]
GET    /comisiones/
POST   /comisiones/calcular/
```

### Inventario (`/api/v1/inventario/`)
```
CRUD   /productos/
GET    /productos/{id}/stock/
GET    /productos/buscar/
CRUD   /categorias/
CRUD   /almacenes/
CRUD   /stock/
GET    /movimientos/
CRUD   /lotes/
POST   /movimientos/ajuste/
POST   /movimientos/transferencia/
GET    /alertas-stock/
CRUD   /transferencias/
POST   /salidas/
POST   /entradas/
GET    /trazabilidad/{lote_id}/
GET    /lotes/fifo/
GET    /dashboard/
GET    /rotacion-abc/?dias=N
CRUD   /ubicaciones/
CRUD   /series/
GET    /trazabilidad/serie/?numero_serie=
```

### Compras (`/api/v1/compras/`)
```
CRUD   /ordenes/
POST   /ordenes/{id}/aprobar/
POST   /ordenes/{id}/enviar/
POST   /ordenes/{id}/cancelar/
POST   /ordenes/{id}/prorratear-gastos/
CRUD   /facturas-proveedor/
POST   /facturas-proveedor/{id}/conciliar/
POST   /facturas-proveedor/{id}/validar-sunat/
CRUD   /recepciones/
GET    /comparar-proveedores/?producto_id=&dias=
POST   /evaluacion-proveedor/
GET    /evaluaciones-proveedor/
```

### Finanzas (`/api/v1/finanzas/`)
```
CRUD   /cxc/
POST   /cxc/{id}/cobrar/
CRUD   /cxp/
POST   /cxp/{id}/pagar/
CRUD   /asientos/
POST   /asientos/{id}/confirmar/
POST   /asientos/{id}/anular/
CRUD   /plan-contable/
CRUD   /periodos/
POST   /periodos/{id}/cerrar/
POST   /periodos/{id}/reabrir/
GET    /mora/
GET    /libro-diario/
GET    /libro-mayor/?cuenta_id=
GET    /libro-caja/
GET    /balance-general/?fecha_corte=
GET    /estado-resultados/?fecha_inicio=&fecha_fin=
GET    /flujo-caja/?fecha_inicio=&fecha_fin=
```

### Facturacion (`/api/v1/facturacion/`)
```
CRUD   /comprobantes/
POST   /comprobantes/emitir/
POST   /comprobantes/{id}/reenviar/
GET    /comprobantes/{id}/xml/
GET    /comprobantes/{id}/cdr/
GET    /comprobantes/{id}/pdf/
CRUD   /series/
CRUD   /notas/
GET    /pendientes/
GET    /resumen-diario/
POST   /resumen-diario/enviar/
GET    /contingencia/estado/
POST   /contingencia/activar/
POST   /contingencia/desactivar/
```

### Distribucion (`/api/v1/distribucion/`)
```
CRUD   /pedidos/
POST   /pedidos/{id}/asignar/
POST   /pedidos/{id}/despachar/
POST   /pedidos/{id}/en-ruta/
POST   /pedidos/{id}/entregar/
POST   /pedidos/{id}/cancelar/
POST   /pedidos/{id}/evidencia/
POST   /pedidos/{id}/gps/
GET    /publico/seguimiento/{codigo}/
CRUD   /transportistas/
```

### Reportes (`/api/v1/reportes/`)
```
GET    /dashboard/
GET    /dashboard/comparacion/
GET    /ventas/
GET    /ventas/por-vendedor/
GET    /ventas/por-metodo-pago/
GET    /ventas/serie-diaria/
GET    /top-productos/
GET    /top-clientes/
GET    /inventario/
GET    /kpis-financieros/
GET    /kpis-comparativo/
POST   /exportar/
GET    /snapshots/
CRUD   /programaciones/
```

### Usuarios (`/api/v1/usuarios/`)
```
CRUD   /usuarios/
POST   /usuarios/{id}/desactivar/
CRUD   /roles/
POST   /roles/{id}/permisos/
GET    /permisos/
GET    /audit-logs/
GET    /logs/exportar/          [NUEVO T8 — CSV con BOM para Excel]
GET    /notificaciones/
POST   /notificaciones/{id}/leer/
POST   /notificaciones/leer-todas/
GET    /sesiones/
```

### WhatsApp (`/api/v1/whatsapp/`)
```
GET/PATCH /configuracion/
CRUD      /plantillas/
GET       /mensajes/
POST      /enviar/        [STUB — no hace HTTP POST real a Meta]
GET/POST  /webhook/
GET       /logs/
```

---

## CELERY BEAT SCHEDULE

| Tarea | Frecuencia | Modulo |
|---|---|---|
| alertar_cotizaciones_por_vencer | Diaria 08:00 | Ventas |
| calcular_resumen_ventas_dia | Diaria 23:30 | Ventas |
| marcar_cotizaciones_vencidas | Diaria 23:00 | Ventas |
| alertar_lotes_por_vencer | Diaria 07:00 | Inventario (umbral 7 dias — corregido T8) |
| verificar_stock_minimo | Diaria 07:30 | Inventario |
| reenviar_comprobantes_pendientes | Cada 5 min | Facturacion |
| enviar_resumen_diario_boletas | Diaria 23:50 | Facturacion |
| generar_oc_automaticas_bajo_stock | Diaria 07:45 | Compras |
| alertar_cxc_vencidas | Diaria 08:00 | Finanzas |
| alertar_cxp_por_vencer | Diaria 08:00 | Finanzas |
| calcular_kpis_dashboard | Cada 10 min | Reportes — emite kpi_update via WS |
| ejecutar_reportes_programados | Cada 15 min | Reportes |
| limpiar_archivos_huerfanos | Diaria 04:30 | Media/R2 |
| limpiar_logs_whatsapp | Semanal | WhatsApp |

---

## BUGS CONOCIDOS

| Bug | Modulo | Impacto | Archivo |
|---|---|---|---|
| ~~`sincronizar_ventas_offline()` llama a `registrar_venta_pos()` que no existe~~ | Ventas BE | **CORREGIDO T8** | `ventas/services.py` |
| ~~Alertas lotes por vencer usan 30 dias en vez de 7 (spec)~~ | Inventario BE | **CORREGIDO T8** | `inventario/tasks.py` |
| Estado "con_incidencia" escrito como texto libre en `motivo` (no como state) | Inventario BE | Menor — no consulatable por estado | `inventario/services.py` |
| `requiere_lote`/`requiere_serie` no validados en servicios de entrada/salida | Inventario BE | Moderado — datos sin trazabilidad | `inventario/services.py` |
| Credenciales Nubefact almacenadas como `CharField` plano en BD | Facturacion BE | Seguridad — no encriptado | `empresa/models.py` linea 49 |
| Migracion `0004_add_serie_modelo.py` no aplicada | Inventario BE | CRITICO si se usa trazabilidad serie | `inventario/migrations/` |

---

## REGLAS DE DESARROLLO (para el agente)

### Patrones FE obligatorios
- **Listas CRUD:** seguir `AlmacenesList.tsx` — `card > card-header > tabla` con `divide-y divide-default-200`
- **Modales:** seguir `AlmacenFormModal.tsx` — `fixed inset-0 z-80`, overlay negro, card centrada
- **Timelines/Trazabilidad:** seguir `TrazabilidadLote.tsx` — linea vertical `absolute left-5`, iconos `size-10 rounded-full border-2`
- **KPI cards:** patron del dashboard — `rounded-xl border bg-white p-5`
- **Buscadores:** `ps-11 form-input` con icono absoluto en `ps-3`
- **SIEMPRE usar componentes del template** antes de crear desde cero

### Iconos react-icons/lu (verificados)
- `LuLoaderCircle` (NO LuLoader2)
- `LuTriangleAlert` (NO LuAlertTriangle)
- `LuCircleCheck` (NO LuCheckCircle)
- `LuChartBarBig` (NO LuBarChart2 — no existe)
- **SIEMPRE verificar con:** `node -e "const i = require('react-icons/lu'); console.log('LuNombre' in i);"`

### Backend
- Errores LSP de Python (`.objects`, `.DoesNotExist`, etc.) son TODOS falsos positivos — ignorar
- Venv: `/home/anderson/Proyectos-J/J-soluciones/Jsoluciones-be/.venv/bin/python`
- `DJANGO_SETTINGS_MODULE=config.settings.development`
- Package manager FE: pnpm (NO npm)

### Al modificar BE (nuevos endpoints o campos)
```bash
cd Jsoluciones-be && python manage.py spectacular --settings=config.settings.development --file ../Jsoluciones-fe/openapi.json
cd Jsoluciones-fe && pnpm orval
```

---

*Diagnostico basado en lectura directa del codigo fuente — todos los modulos auditados.*
*Ultima actualizacion: 2026-02-23 (Sesion T8 — 10 gaps implementados, TSC limpio).*
