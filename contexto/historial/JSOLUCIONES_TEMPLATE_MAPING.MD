# JSOLUCIONES ERP – Mapeo de Vistas → Componentes Tailwick
> Documento para agente de template. Por cada vista se indica: qué entidades de DB consume, qué componentes Tailwick/Tailwind usar, y el layout esperado.

---

## Convenciones de Componentes Tailwick

| Alias usado aquí | Componente Tailwick |
|---|---|
| `DataTable` | Tabla con paginación, sorting, filtros inline |
| `KPICard` | Card con número grande, variación %, ícono |
| `BadgeStatus` | Badge de color por estado |
| `ModalForm` | Modal con formulario interno |
| `WizardForm` | Formulario multi-paso (stepper) |
| `SidePanel` | Panel lateral deslizable (drawer) |
| `PageHeader` | Header de página con título + botones CTA |
| `FilterBar` | Barra de filtros combinables (dropdowns + datepickers) |
| `Timeline` | Línea de tiempo vertical de eventos |
| `KanbanBoard` | Vista kanban de columnas arrastrables |
| `ChartBar` | Gráfico de barras (Recharts o Chart.js) |
| `ChartLine` | Gráfico de líneas |
| `ChartPie` | Gráfico circular/donut |
| `TreeView` | Lista jerárquica expandible |
| `MapView` | Mapa embebido (Leaflet/Google Maps) |
| `PermissionMatrix` | Tabla de checkboxes filas×columnas |
| `AuditLog` | Tabla de log con timestamp, usuario, acción |

---

## MÓDULO 1 – Gestión de Ventas

### 1.1 Vista POS (Punto de Venta)
**Layout:** Full-screen, 2 columnas (70/30). Sin sidebar global visible.

**DB / Entidades:**
- `Producto` (id, nombre, sku, precio, imagen, stock)
- `Cliente` (id, nombre, ruc, dni)
- `Venta` / `DetalleVenta`
- `MetodoPago`, `Caja`, `Sucursal`

**Componentes a usar:**
- **Columna izquierda:** Grid de `Cards` de producto (imagen, nombre, precio, stock badge) + Buscador input con debounce
- **Columna derecha (carrito):** Lista con cantidad editable, subtotal, total, selector `MetodoPago` como botones grandes táctiles
- **Header:** Selector de `Sucursal` + `Caja` (dropdowns), indicador OFFLINE (`AlertBanner` rojo)
- **Modales:** `ModalForm` para apertura/cierre de caja (arqueo), búsqueda de cliente por RUC/DNI
- **Footer:** Botón "Cobrar" (CTA primario grande), botón imprimir/enviar ticket

---

### 1.2 Vista Venta en Línea / eCommerce
**Layout:** Página estándar con sidebar + contenido.

**DB / Entidades:**
- `PedidoOnline` (id, canal, estado, cliente_id, fecha)
- `DetalleVenta`, `Comprobante`

**Componentes:**
- `PageHeader` con título + botón "Generar Comprobante"
- `FilterBar` (fecha, canal: WooCommerce/Shopify, estado)
- `DataTable` columnas: N°, Cliente, Canal, Fecha, Monto, Estado (`BadgeStatus`), Acciones
- `SidePanel` al hacer clic en pedido: detalle del pedido + botón generar comprobante

---

### 1.3 Vista de Cotizaciones
**Layout:** Página estándar + modal/página de creación.

**DB / Entidades:**
- `Cotizacion` (id, numero, cliente_id, vendedor_id, fecha, fecha_vencimiento, monto_total, estado)
- `DetalleCotizacion`

**Componentes:**
- `PageHeader` + botón "Nueva Cotización"
- `FilterBar` (estado, vendedor, fecha)
- `DataTable` con `BadgeStatus` (vigente/vencida/aceptada/rechazada), acciones: ver, duplicar, convertir
- **Alerta:** Banner o card de cotizaciones próximas a vencer (< 3 días)
- **Creación:** `WizardForm` 4 pasos: [1. Cliente] → [2. Productos] → [3. Condiciones] → [4. Resumen]
- **Detalle:** `SidePanel` o página separada con `Timeline` de negociaciones

---

### 1.4 Vista de Órdenes de Venta
**Layout:** Página con toggle Lista/Kanban.

**DB / Entidades:**
- `OrdenVenta` (id, cotizacion_id, cliente_id, vendedor_id, estado, fecha)
- `DetalleOrden`

**Componentes:**
- `PageHeader` + toggle "Vista Lista / Kanban"
- Vista Lista: `FilterBar` + `DataTable` con `BadgeStatus`
- Vista Kanban: `KanbanBoard` (columnas: Pendiente → Aprobada → En Proceso → Completada → Cancelada)
- `Timeline` stepper en detalle: Cotización → Orden → Venta → Despacho

---

### 1.5 Vista de Clientes
**Layout:** Listado + ficha lateral o página de detalle.

**DB / Entidades:**
- `Cliente` (id, tipo_doc, num_doc, razon_social, telefono, email, categoria, tags)
- `HistorialCompra`, `Cotizacion`, `Deuda`

**Componentes:**
- `PageHeader` + botón "Nuevo Cliente"
- `FilterBar` (búsqueda texto, categoría, tag)
- `DataTable` columnas: Nombre, RUC/DNI, Teléfono, Categoría, Deuda, Acciones
- **Ficha de cliente:** Tabs → [Datos Generales] [Historial Compras] [Cotizaciones] [Deudas] [Tickets POS]
- `ModalForm` para alta/edición con validación RUC/DNI SUNAT en tiempo real

---

### 1.6 Vista Ventas en Campo (App Web Móvil)
**Layout:** Mobile-first, una columna, UI simplificada.

**DB / Entidades:**
- `Pedido`, `DetalleVenta`, `Cliente`, `Producto`

**Componentes:**
- Buscador de cliente grande (input prominente)
- Lista de productos con stock badge
- Resumen del pedido (lista compacta + total)
- Botón "Enviar Pedido" (CTA flotante)
- Indicador de estado de sincronización (banner si offline)

---

### 1.7 Reportes de Ventas
**Layout:** Página de reportes con tabs por tipo de reporte.

**Componentes por reporte:**
- **Ventas Diarias:** `ChartBar` (por hora/caja) + `DataTable`
- **Por Producto:** Ranking tabla con columna margen, `ChartBar` horizontal
- **Por Cliente:** `DataTable` con ticket promedio, `ChartPie` por segmento
- **Cotizaciones:** `DataTable` + `ChartPie` por estado
- **Métodos de Pago:** `ChartPie` + `ChartLine` de tendencia
- **Dashboard Gerencial:** 3×2 grid de `KPICard` + TOP 5 listas

---

## MÓDULO 2 – Inventario y Logística

### 2.1 Vista de Almacenes
**DB:** `Almacen`, `Zona`, `Estanteria`, `Sucursal`

**Componentes:**
- `PageHeader` + botón "Nuevo Almacén"
- `DataTable` con stock resumen por almacén, acciones
- `ModalForm` para alta/edición
- `TreeView`: Almacén → Zona → Estantería (expandible)
- Panel de permisos por rol (checkboxes inline)

---

### 2.2 Vista de Stock en Tiempo Real
**DB:** `Producto`, `Stock` (por almacén), `StockMinimo`, `StockMaximo`

**Componentes:**
- `FilterBar` (almacén, categoría, estado de stock)
- `DataTable` con columnas stock actual, mínimo, máximo + indicador semaforo inline (`BadgeStatus`)
- Panel derecho o superior: `ChartPie` por categoría, `ChartBar` por almacén
- Notificaciones de bajo stock en header (badge contador)

---

### 2.3 Vista de Movimientos
**DB:** `Movimiento` (tipo: entrada/salida/transferencia, producto_id, almacen_origen, almacen_destino, lote, usuario_id, motivo, timestamp)

**Componentes:**
- Tabs: [Entradas] [Salidas] [Transferencias]
- Botón "Registrar Movimiento" por tab → `ModalForm` específico
  - Entrada: proveedor, lote, fecha vencimiento, cantidad
  - Salida: motivo (enum), cantidad
  - Transferencia: almacén origen → destino, confirmación receptor
- `DataTable` con historial + `FilterBar`

---

### 2.4 Vista de Trazabilidad por Lote/Serie
**DB:** `Lote` (numero, producto_id, fecha_vencimiento, estado), `MovimientoLote`

**Componentes:**
- Buscador grande por N° lote o serie (input principal)
- Card de resultado: estado del lote (`BadgeStatus`), fecha vencimiento, alerta si próximo a vencer
- `Timeline` vertical de movimientos del lote

---

### 2.5 Reportes de Inventario
**Componentes:** igual estructura que reportes de ventas — `DataTable` + `ChartBar`/`ChartPie` + `FilterBar` + botón exportar

---

## MÓDULO 3 – Facturación Electrónica

### 3.1 Vista de Emisión de Comprobantes
**DB:** `Comprobante` (tipo, serie, numero, cliente_id, items, igv, estado_sunat), `ItemComprobante`

**Componentes:**
- `PageHeader` "Emitir Comprobante"
- Formulario en una página: selector tipo comprobante (tabs o radio grande), datos cliente con validación SUNAT async, tabla de productos editable (add/remove row)
- Preview PDF embebido (`<iframe>` o visor PDF) antes de enviar
- Botón "Enviar a SUNAT" con spinner de carga
- `BadgeStatus` de respuesta SUNAT: Emitido ✅ / Rechazado ❌ / Observado ⚠️ / Pendiente 🕐

---

### 3.2 Vista de Listado de Comprobantes
**Componentes:**
- `FilterBar` (cliente, RUC, serie, número, fecha, tipo, estado SUNAT)
- `DataTable` con acciones por fila: ver PDF, ver XML, ver CDR, reenviar, anular
- Botón "Exportar" (Excel/PDF) con selector de rango de fechas

---

### 3.3 Vista de Notas de Crédito/Débito
**Componentes:**
- Buscador de comprobante origen
- `ModalForm`: tipo nota (NC/ND), motivo (select), monto, estado SUNAT badge

---

### 3.4 Vista de Contingencia y Reenvíos
**Componentes:**
- `DataTable` de cola: comprobante, timestamp, intentos, código respuesta SUNAT, `BadgeStatus`
- Botón "Reenviar" por fila y "Reenviar Todo"

---

### 3.5 Vista de Resumen Diario
**Componentes:**
- `KPICard` total boletas del día
- Botón "Enviar Resumen a SUNAT" + `BadgeStatus` del envío
- `DataTable` de boletas incluidas en el resumen

---

### 3.6 Matriz de Pruebas QA
**Componentes:**
- `DataTable` con columnas: ID, Escenario, Entrada, Resultado Esperado, Obtenido, Estado (badge OK/Error)

---

## MÓDULO 4 – Distribución y Seguimiento

### 4.1 Vista de Registro de Pedidos (Logística)
**DB:** `Pedido` (cliente_id, productos, direccion_geo, estado, tipo_entrega, hora_estimada), `EstadoPedido`

**Componentes:**
- `FilterBar` + `DataTable` con `BadgeStatus` (PENDIENTE/PLANIFICADO/EN RUTA/ENTREGADO/FALLIDO)
- `ModalForm` para crear/editar pedido (validación stock inline)

---

### 4.2 Vista de Planificación de Rutas
**DB:** `Ruta`, `Transportista`, `PedidoRuta`

**Componentes:**
- Layout 50/50: `MapView` (Leaflet, pines por pedido) + Panel lateral
- Panel lateral: lista de pedidos arrastrables + selector de transportista
- Ruta optimizada visualizada en el mapa (polyline)
- `KanbanBoard` tipo "Task Board" por transportista (columnas = transportistas, cards = pedidos)

---

### 4.3 Vista de Seguimiento en Tiempo Real
**Componentes:**
- `MapView` con marcadores GPS en vivo (WebSocket)
- Panel de pedidos: `Timeline` de eventos por pedido seleccionado
- ETA badge por pedido
- Modal para registrar evidencia entrega: upload foto, firma canvas, input OTP

---

### 4.4 Vista Pública de Seguimiento (sin login)
**Layout:** Página pública minimal, sin sidebar.

**Componentes:**
- Input de código de seguimiento (landing simple)
- Card de estado con `Timeline` de eventos
- `MapView` embebido con ubicación repartidor (si habilitado)

---

### 4.5 Vista de Integración Transportistas Externos
**Componentes:**
- Cards por operador (Olva, Urbano...) con estado de conexión + config API (token, endpoint)
- `DataTable` de pedidos con código de rastreo externo + estado sincronizado
- Botón "Exportar CSV" para operadores sin API

---

## MÓDULO 5 – Compras y Proveedores

### 5.1 Vista de Órdenes de Compra
**DB:** `OrdenCompra` (proveedor_id, productos, almacen_destino, fecha_estimada, moneda, monto, estado), `DetalleOC`

**Componentes:**
- `PageHeader` + botón "Nueva OC"
- `FilterBar` + `DataTable` con `BadgeStatus` (Borrador/Pendiente Aprobación/Aprobada/Enviada/Cerrada/Cancelada)
- `WizardForm` para creación: [Proveedor] → [Productos] → [Condiciones] → [Resumen]
- Alerta de OCs vencidas sin recibir (banner o badge)

---

### 5.2 Vista de Proveedores
**DB:** `Proveedor` (ruc, razon_social, condiciones_comerciales, kpi_entregas), `HistorialCompraProveedor`

**Componentes:**
- `DataTable` + `ModalForm` alta/edición
- **Ficha proveedor:** Tabs → [Datos] [Historial Compras] [KPIs: entregas a tiempo vs fallidas] [Contratos PDF]
- Tabla comparadora de proveedores por producto (precio/tiempo/calidad)

---

### 5.3 Vista de Facturas de Proveedores
**Componentes:**
- `ModalForm` vinculado a OC: N° factura, RUC, fechas, monto, IGV, prorrateo flete
- Validación SUNAT async
- `DataTable` de facturas registradas con estado conciliación

---

### 5.4 Vista de Conciliación con Inventario
**Componentes:**
- Formulario de recepción: tabla editable cantidad pedida vs recibida
- Sección de incidencias: fila por incidencia con tipo (dañado/faltante/vencido) + upload foto
- Botón "Cerrar OC" habilitado solo si todas las líneas conciliadas
- `BadgeStatus` de estado conciliación

---

## MÓDULO 6 – Gestión Financiera y Tributaria

### 6.1 Vista de Cuentas por Cobrar
**DB:** `DocumentoCobro` (cliente_id, monto, fecha_vencimiento, estado, moneda)

**Componentes:**
- `FilterBar` + `DataTable` con `BadgeStatus` (Pendiente/Vencido/Pagado/Refinanciado)
- Modal para registrar pago: monto, método, moneda, fecha
- Banner de alerta: documentos vencidos > 0
- Columna de intereses mora calculados inline

---

### 6.2 Vista de Cuentas por Pagar
**Igual estructura que CxC**, hacia proveedores. Agregar:
- Calendario de vencimientos (componente `Calendar` del template)
- Restricción de botón "Registrar contablemente" solo para rol Contador/Financiero

---

### 6.3 Vista de Conciliación Bancaria
**DB:** `ExtractoBancario`, `MovimientoContable`, `ConciliacionBancaria`

**Componentes:**
- Uploader de archivo (Excel/CSV con selector de banco: BBVA/BCP/Interbank)
- Tabla de dos columnas: extracto (izq) vs. sistema (der) con sugerencias auto-match resaltadas
- Botones inline por fila: Confirmar / Diferencia / Ignorar
- `BadgeStatus` estado conciliación + alerta de movimientos no conciliados > X días
- Selector multi-banco / multi-cuenta en header

---

### 6.4 Vista de Libros Contables
**DB:** `AsientoContable`, `CuentaContable`

**Componentes:**
- Tabs: [Libro Diario] [Mayor] [Caja] [Estado de Resultados] [Balance General]
- `DataTable` con paginación por cada libro
- Botón "Exportar PDF/Excel" en cada tab
- Modal de validación: asiento desbalanceado muestra alerta inline

---

### 6.5 Vista de Declaraciones Tributarias
**DB:** `DeclaracionTributaria`, `ResumenMensual`

**Componentes:**
- Selector mes/año + régimen fiscal (RMT/RER/MYPE)
- Cards de resumen: ingresos, egresos, IGV neto, renta, detracciones
- Botones: "Generar PLE (TXT)", "Generar PDT (XML/ZIP)"
- Calendario de vencimientos del mes
- Botón "Firma Digital Contador" (flujo de firma con modal de confirmación)

---

## MÓDULO 7 – WhatsApp API

### 7.1 Vista de Configuración
**Componentes:**
- Cards por línea/sucursal: token, número, dominio, estado conexión (badge activo/error)
- `ModalForm` para conectar nueva cuenta

---

### 7.2 Vista de Plantillas
**DB:** `PlantillaWhatsApp` (nombre, texto, variables, categoria, estado_meta)

**Componentes:**
- `DataTable` con `BadgeStatus` (En revisión/Aprobada/Rechazada)
- Editor de plantilla: textarea con resalto de variables `{{1}}`, selector categoría
- Validación frontend: max 3 variables
- Botón "Enviar a Meta para aprobación"

---

### 7.3 Vista de Mensajes Automáticos / Campañas
**DB:** `Disparador` (evento, plantilla_id, segmento, activo), `Campaña`

**Componentes:**
- Lista de disparadores automáticos (toggle activo/inactivo por evento)
- Formulario campaña fidelización: selector segmento (inactivos > 60 días), plantilla, CTA
- Preview del mensaje con variables resueltas en card tipo "burbuja WhatsApp"

---

### 7.4 Vista de Logs y Métricas
**DB:** `LogMensaje` (id, numero_destino, hora, estado_api, plantilla_id, campaña_id)

**Componentes:**
- 4 `KPICard`: Enviados / Entregados / Leídos / Respondidos
- `FilterBar` + `DataTable` con `BadgeStatus` (Entregado/Leído/Fallido/En espera)
- `ChartLine` de tasa de apertura/respuesta por campaña
- Card: tiempo promedio de respuesta del cliente

---

## MÓDULO 8 – Dashboard & Reportes

### 8.1 Dashboard Principal (por Rol)
**Layout:** Grid dinámico según rol logueado.

**Componentes:**
- **Admin:** Grid 4 cols `KPICard` (ventas día, ingresos mes, pedidos activos, stock crítico) + `ChartBar` ventas semana + `ChartLine` tendencia + tabla TOP 5 productos/clientes/vendedores
- **Gerente Ventas:** KPIs ingresos + meta (progress bar), `ChartLine` proyección, conversión cotizaciones (`ChartPie`)
- **Supervisor Almacén:** Cards stock crítico (semáforo), `ChartBar` entradas/salidas, lista alertas bajo stock
- **Contador/Financiero:** Cards CxC vencidas, flujo caja, calendario vencimientos tributarios
- Actualización automática cada 10 min (configurable) con timestamp "última actualización"

---

### 8.2 Vista de Filtros Dinámicos
**Componentes:**
- `FilterBar` sticky: sucursal, zona, categoría, vendedor, canal, rango fechas, estado, cliente
- Aplicación sin recarga (estado React/Vue + llamadas AJAX)
- Botón "Guardar filtro favorito" → input nombre del filtro → listado de favoritos guardados por usuario

---

### 8.3 Vista de Exportación de Reportes
**Componentes:**
- Por módulo: botón "Exportar" con dropdown (Excel / PDF)
- Modal de programación: frecuencia (diaria/semanal/mensual), emails destinatarios
- `DataTable` del log de exportaciones: usuario, fecha, reporte, filtros, descarga

---

## MÓDULO 9 – Usuarios y Roles

### 9.1 Administración de Usuarios
**DB:** `Usuario` (nombre, email, rol_id, sucursal_id, activo, 2fa_activo)

**Componentes:**
- `DataTable` + `ModalForm` alta/edición
- Panel de permisos por módulo (checkboxes agrupados por módulo)
- Toggle "Activar 2FA" por usuario
- Sección SSO: botones conectar Google/Microsoft con estado

---

### 9.2 Vista de Roles y Permisos
**Componentes:**
- `PermissionMatrix`: filas = módulos (Ventas, Inventario, Facturación...), columnas = acciones (Ver / Crear / Editar / Eliminar / Exportar)
- Checkbox en cada celda, guardado con botón "Guardar Rol"

---

### 9.3 Vista de Auditoría
**DB:** `AuditLog` (usuario_id, fecha, ip, modulo, accion, dato_anterior, dato_nuevo)

**Componentes:**
- `FilterBar` (usuario, módulo, tipo de acción, fecha)
- `AuditLog` / `DataTable` con columnas: Usuario, Fecha, IP, Módulo, Acción, Detalle (expandible)
- Botón "Exportar Log"

---

## Módulos Complementarios

### Seguridad
- **Login:** Card centrada con campos email/pass + botón 2FA (input OTP), botones SSO Google/Microsoft
- **Sesiones activas:** `DataTable` con IP, dispositivo, último acceso + botón "Cerrar sesión remota"
- **Políticas:** Formulario de configuración (caducidad sesión, intentos máximos, complejidad contraseña)

### Panel Admin SaaS (Multitenant)
- `DataTable` tenants: nombre, módulos activos, plan, usuarios, uso recursos
- Barras de progreso de uso por tenant
- `AuditLog` por tenant

### Motor de Workflow
- Canvas visual tipo BPMN (librería react-flow o similar)
- Panel de propiedades por nodo: tipo (condición/notificación/aprobación), configuración de regla
- `DataTable` de tareas pendientes de aprobación por usuario

### Backup y Restauración
- Cards de configuración: frecuencia, alcance (módulos)
- `DataTable` historial de backups: fecha, tamaño, estado + botón "Restaurar"

---

## Resumen para el Agente de Template

| Componente | Vistas donde se usa |
|---|---|
| `DataTable` | Todas las vistas de listado (≥ 20 vistas) |
| `FilterBar` | Todas las vistas de listado |
| `KPICard` | Dashboard, Reportes, WhatsApp métricas |
| `BadgeStatus` | POS, Cotizaciones, Órdenes, Facturación, Pedidos, CxC, WA |
| `ModalForm` | Clientes, Productos, Cotizaciones, OC, Usuarios, etc. |
| `WizardForm` | Cotizaciones (4 pasos), Órdenes de Compra (4 pasos) |
| `Timeline` | Órdenes de Venta, Trazabilidad, Seguimiento Pedidos |
| `KanbanBoard` | Órdenes de Venta, Planificación de Rutas |
| `MapView` | Planificación de Rutas, Seguimiento Tiempo Real, Vista Pública |
| `ChartBar` | Reportes de Ventas, Inventario, Dashboard |
| `ChartLine` | Dashboard, WhatsApp métricas |
| `ChartPie` | Stock por categoría, Métodos de Pago, Cotizaciones |
| `TreeView` | Almacenes (estructura Almacén→Zona→Estantería) |
| `PermissionMatrix` | Roles y Permisos (Módulo 9.2) |
| `AuditLog` | Auditoría (Módulo 9.3), Libros Contables |
| `SidePanel` | Ficha Cliente, detalle PedidoOnline |
| `WizardForm` | Cotizaciones, Órdenes de Compra |

---

*Generado para: JSOLUCIONES ERP – Agente de Template Tailwick. Basado en JSOLUCIONES_FRONTEND_VISTAS.md*