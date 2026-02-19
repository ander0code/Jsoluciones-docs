# JSOLUCIONES ERP – Roles, Permisos y Flujos Completos de Frontend

> Basado estrictamente en el PDF del proyecto. Sin multi-tenancy. Cubre cada rol, qué vistas puede ver, qué puede hacer en cada una y todos los flujos paso a paso posibles desde el frontend.

---

## Roles Definidos en el Sistema

| Rol | Área Principal |
|---|---|
| **Administrador** | Control total del sistema |
| **Gerente General / Gerente de Ventas** | Visión ejecutiva, reportes, metas |
| **Supervisor de Almacén** | Inventario, stock, transferencias |
| **Supervisor de Logística** | Distribución, rutas, transportistas |
| **Vendedor** | Cotizaciones, órdenes, clientes |
| **Cajero** | Punto de venta (POS) |
| **Almacenero** | Entradas, salidas, recepciones |
| **Contador / Financiero** | Facturación, contabilidad, declaraciones |
| **Repartidor / Conductor** | Entregas, tracking, confirmación de entrega |
| **Cliente (externo)** | Seguimiento de pedido (portal público, sin login) |

---

# ROL 1 – ADMINISTRADOR

## Vistas accesibles: TODAS

---

### FLUJO 1 – Configuración inicial del sistema

**Dónde:** Panel de Administración → Configuración

**Pasos:**
1. Ingresar a `/configuracion/empresa` → completar datos: razón social, RUC, dirección, logo, régimen tributario
2. Ir a `/configuracion/sucursales` → crear sucursales con nombre, dirección y responsable
3. Ir a `/configuracion/almacenes` → crear almacenes, asignar a cada sucursal
4. Ir a `/configuracion/series-facturacion` → definir series por tipo (F001 facturas, B001 boletas)
5. Ir a `/configuracion/certificado-digital` → cargar certificado PFX para firma SUNAT
6. Ir a `/configuracion/parametros` → definir: IGV (18%), stock mínimo por defecto, días de crédito, tolerancia de conciliación bancaria, frecuencia de actualización de dashboard
7. Ir a `/configuracion/whatsapp` → ingresar token, Phone Number ID, dominio verificado de Meta

**Acciones disponibles en estas vistas:**
- Crear / editar / desactivar sucursales y almacenes
- Subir y gestionar el certificado digital
- Configurar todos los parámetros globales del sistema
- Conectar y desconectar cuenta de WhatsApp

---

### FLUJO 2 – Gestión de usuarios y roles

**Dónde:** `/usuarios` y `/roles`

**Pasos – Crear usuario:**
1. Ir a `/usuarios` → ver tabla de todos los usuarios (nombre, email, rol, sucursal, estado activo/inactivo)
2. Clic en **"Nuevo Usuario"**
3. Completar: nombre, email, contraseña temporal, rol asignado, sucursal asignada
4. Guardar → usuario recibe email con contraseña temporal
5. Opcional: activar 2FA desde la ficha del usuario

**Pasos – Crear o editar un rol:**
1. Ir a `/roles` → tabla de roles existentes
2. Clic en **"Nuevo Rol"** o clic en uno existente
3. Asignar nombre y descripción
4. Abrir **matriz de permisos**: filas = módulos, columnas = acciones (Ver / Crear / Editar / Eliminar / Exportar)
5. Marcar o desmarcar checkboxes
6. Guardar

**Pasos – Desactivar usuario:**
1. Tabla de usuarios → clic en el usuario
2. Cambiar estado a **Inactivo** → el sistema invalida todos sus tokens activos inmediatamente
3. El usuario ya no puede ingresar

---

### FLUJO 3 – Ver Audit Log

**Dónde:** `/auditoria`

**Pasos:**
1. Ir a `/auditoria`
2. Aplicar filtros: usuario, módulo, tipo de acción, rango de fechas
3. Ver tabla: quién hizo qué, en qué objeto, cuándo, desde qué IP
4. Clic en una fila → ver detalle: datos antes y después del cambio
5. Exportar log filtrado a Excel o PDF

---

### FLUJO 4 – Gestión de backups

**Dónde:** `/administracion/backups`

**Pasos:**
1. Ver historial de backups: fecha, tamaño, estado
2. Configurar frecuencia de backup automático (diario/semanal)
3. Clic en **"Restaurar"** en un backup → confirmar modal de advertencia → ejecutar restauración

---

### FLUJO 5 – Ver Dashboard Ejecutivo Global

**Dónde:** `/dashboard`

**Qué ve el Administrador:**
- KPIs de ventas del día / semana / mes (todas las sucursales)
- KPIs de inventario: bajo stock, valor total de inventario
- KPIs financieros: CxC vencidas, flujo de caja del mes
- KPIs de logística: pedidos entregados / en ruta / fallidos
- TOP 5 productos más vendidos
- TOP 5 clientes por monto
- TOP 5 vendedores por monto
- Alertas activas del sistema (stock bajo, cotizaciones vencidas, comprobantes rechazados)
- Variación % vs. periodo anterior en cada KPI
- Actualización automática cada 10 minutos

---

# ROL 2 – GERENTE DE VENTAS / GERENTE GENERAL

## Vistas accesibles: Dashboard, Ventas, Reportes, Clientes (lectura), Cotizaciones (lectura), Facturación (lectura)

---

### FLUJO 1 – Revisión diaria del dashboard

**Dónde:** `/dashboard`

**Pasos:**
1. Al ingresar → landing en `/dashboard`
2. Ver cards KPI: ventas del día vs. meta, comparativo semanal, TOP 5 productos/clientes, cotizaciones por vencer, flujo de caja
3. Aplicar filtros de fecha y canal de venta
4. Hacer clic en cualquier KPI → navega al reporte detallado correspondiente

---

### FLUJO 2 – Análisis de ventas por canal / vendedor / categoría

**Dónde:** `/reportes/ventas`

**Pasos:**
1. Ir a `/reportes/ventas`
2. Aplicar filtros: periodo, canal (POS / eCommerce / campo), sucursal, vendedor, categoría
3. Ver tabla + gráfico de barras por canal y línea de tendencia por día
4. Cambiar a vista "Ventas por Vendedor" → ranking con monto y cantidad de transacciones
5. Cambiar a vista "Ventas por Producto" → ranking y margen por producto
6. Exportar a Excel o PDF

---

### FLUJO 3 – Seguimiento de cotizaciones del equipo

**Dónde:** `/cotizaciones`

**Pasos:**
1. Ir a `/cotizaciones` → ver todas las cotizaciones de todo el equipo
2. Filtrar por: estado, vendedor, cliente, rango de fechas
3. Ver tasa de conversión: aceptadas / total emitidas
4. Clic en cotización → ver detalle (solo lectura, no puede editar)

---

### FLUJO 4 – Revisar reporte de comisiones

**Dónde:** `/reportes/comisiones`

**Pasos:**
1. Seleccionar periodo y vendedor
2. Ver: total de ventas, % de comisión, monto generado
3. Exportar para nómina

---

### FLUJO 5 – Configurar reporte semanal automático por correo

**Dónde:** `/reportes/programaciones`

**Pasos:**
1. Clic en **"Nueva Programación"**
2. Seleccionar tipo: Rentabilidad por categoría
3. Frecuencia: Semanal, Lunes 7:00 AM, formato PDF
4. Ingresar emails destinatarios
5. Guardar → cada lunes el reporte llega automáticamente al correo

---

# ROL 3 – SUPERVISOR DE ALMACÉN

## Vistas accesibles: Inventario completo, Recepciones de compras, Reportes de inventario, Dashboard de almacén

---

### FLUJO 1 – Revisión de stock y alertas de bajo stock

**Dónde:** `/inventario/stock`

**Pasos:**
1. Ver panel con alertas activas al ingresar (productos en rojo/amarillo)
2. Ver tabla: producto, almacén, stock actual, mínimo, máximo, estado (semáforo)
3. Filtrar por almacén, categoría, estado de stock
4. Clic en un producto → ver historial de movimientos de ese producto
5. Si stock crítico → clic en **"Generar Orden de Compra"** → redirige a compras con el producto pre-cargado

---

### FLUJO 2 – Registrar entrada de mercadería

**Dónde:** `/inventario/entradas/nueva`

**Pasos:**
1. Seleccionar almacén de destino
2. Seleccionar proveedor (o transferencia interna)
3. Agregar productos: nombre/SKU, cantidad
4. Si el producto tiene trazabilidad: ingresar número de lote (obligatorio) y fecha de vencimiento
5. Revisar resumen → **"Confirmar Entrada"**
6. Stock actualizado en tiempo real y movimiento registrado

---

### FLUJO 3 – Registrar ajuste manual de stock

**Dónde:** `/inventario/ajustes/nuevo`

**Pasos:**
1. Seleccionar almacén y producto
2. Indicar nuevo stock o la diferencia (+/-)
3. Ingresar **motivo** (campo obligatorio: merma, error de conteo, daño, etc.)
4. Confirmar → movimiento de tipo `AJUSTE` registrado con usuario, motivo y timestamp

---

### FLUJO 4 – Crear transferencia entre almacenes

**Dónde:** `/inventario/transferencias/nueva`

**Pasos:**
1. Seleccionar almacén origen y almacén destino
2. Agregar productos a transferir: producto, cantidad, lote si aplica
3. El sistema valida que el stock en origen sea suficiente en tiempo real
4. Confirmar → estado = `SOLICITADA`
5. El almacenero del almacén destino recibe notificación

---

### FLUJO 5 – Ver trazabilidad de un lote

**Dónde:** `/inventario/trazabilidad`

**Pasos:**
1. Buscar por número de lote o serie
2. Ver historial completo de movimientos (entrada → transferencias → salida por venta)
3. Ver estado del lote: activo / agotado / vencido
4. Ver almacén actual y cantidad disponible
5. Exportar historial a PDF

---

### FLUJO 6 – Dashboard de inventario

**Dónde:** `/dashboard` (vista de almacén)

**Qué ve:**
- Stock total valorizado
- Productos con bajo stock (lista con alerta)
- Lotes con vencimiento próximo (próximos 7 días)
- Rotación ABC (A = alta, B = media, C = baja)
- Últimos 10 movimientos del día
- Gráfico de entradas vs. salidas por semana

---

# ROL 4 – SUPERVISOR DE LOGÍSTICA

## Vistas accesibles: Pedidos, Rutas, Transportistas, Seguimiento en tiempo real, Reportes de logística

---

### FLUJO 1 – Planificación de rutas del día

**Dónde:** `/logistica/rutas/nueva`

**Pasos:**
1. Ir a `/logistica/pedidos` → ver todos los pedidos `PENDIENTE` de despacho para hoy
2. Ver en mapa los puntos de entrega como pines (Google Maps / Leaflet)
3. Seleccionar pedidos a despachar hoy (checkbox o drag & drop)
4. Agrupar por zona geográfica automáticamente
5. Asignar grupo de pedidos a transportista:
   - Ver capacidad del transportista (peso/volumen/pedidos max)
   - Si supera capacidad → sistema bloquea con mensaje de error
6. Clic en **"Optimizar Ruta"** → algoritmo calcula orden óptimo
7. Ver ruta resultante en el mapa
8. Confirmar → se genera hoja de ruta digital con QR por pedido
9. El conductor recibe la ruta en su vista móvil automáticamente

---

### FLUJO 2 – Seguimiento en tiempo real de entregas

**Dónde:** `/logistica/seguimiento`

**Pasos:**
1. Ver mapa con iconos de cada conductor en movimiento (actualización cada 30s)
2. Panel lateral: lista de pedidos con estado en tiempo real
3. Clic en un pedido → ver timeline: despachado → en camino → entregado
4. Si pedido `FALLIDO` → ver motivo registrado por el conductor
5. Desde esta vista: reasignar el pedido fallido a otro conductor o reagendar

---

### FLUJO 3 – Gestión de transportistas

**Dónde:** `/logistica/transportistas`

**Pasos:**
1. Ver tabla: nombre, vehículo, capacidad, límite pedidos/día, estado
2. **Crear:** nombre, vehículo, peso máximo, volumen máximo, límite de pedidos por día
3. **Editar** capacidades cuando cambia el vehículo
4. **Desactivar** cuando no está disponible
5. Ver historial de entregas: total, completadas, fallidas, puntualidad

---

### FLUJO 4 – Gestión con transportistas externos

**Dónde:** `/logistica/transportistas-externos`

**Pasos:**
1. Ver lista de operadores externos configurados (Olva, Urbano, etc.)
2. Asignar pedidos al operador externo
3. Si tiene API: se envía automáticamente y se recibe código de tracking
4. Si no tiene API: descargar CSV estándar → cargar manualmente en su plataforma
5. El sistema consulta el estado del pedido externo periódicamente y actualiza

---

# ROL 5 – VENDEDOR

## Vistas accesibles: Clientes, Cotizaciones propias, Órdenes de venta propias, Productos (consulta de stock y precio)

---

### FLUJO 1 – Crear una cotización

**Dónde:** `/ventas/cotizaciones/nueva`

**Pasos:**
1. **Paso 1 – Cliente:** buscar por nombre / RUC / DNI
   - Si existe: seleccionar
   - Si no existe: **"Crear Cliente"** → nombre, RUC/DNI, teléfono, email
2. **Paso 2 – Productos:** buscar por nombre/SKU, agregar con cantidad y precio
   - Ver stock disponible en tiempo real (solo consulta, no puede modificarlo)
   - Aplicar descuento por línea (si el rol tiene permiso)
3. **Paso 3 – Condiciones:** fecha de validez, condiciones de pago, notas al cliente
4. **Paso 4 – Resumen:** ver total con IGV desglosado
5. **"Guardar Cotización"** → estado = `VIGENTE`
6. Opción de enviar por email o WhatsApp al cliente directamente

---

### FLUJO 2 – Seguimiento de cotizaciones propias

**Dónde:** `/ventas/cotizaciones`

**Pasos:**
1. Ver tabla de sus cotizaciones: estado, cliente, fecha, monto
2. Ver alertas de cotizaciones próximas a vencer (amarillo) y vencidas (rojo)
3. **Si el cliente aceptó:**
   - Clic en cotización → **"Convertir a Orden de Venta"**
   - Se crea la OV, cotización = `ACEPTADA`
4. **Si la cotización venció:**
   - Solo disponible el botón **"Duplicar"**
   - Se crea copia con nueva fecha, estado = `VIGENTE`
   - Original queda bloqueada para edición
5. **Si el cliente rechazó:**
   - Marcar como `RECHAZADA` con nota de motivo

---

### FLUJO 3 – Seguimiento de órdenes de venta propias

**Dónde:** `/ventas/ordenes`

**Pasos:**
1. Ver sus órdenes con estados: `PENDIENTE` → `EN_PROCESO` → `COMPLETADA` / `CANCELADA` / `PARCIAL`
2. Ver cuándo fue despachado el pedido (dato de logística)
3. Si la OV está `PENDIENTE` y no fue procesada: cancelar con motivo

---

### FLUJO 4 – Registro de pedido desde campo (móvil)

**Dónde:** `/ventas/pedido-campo` (vista responsive)

**Pasos:**
1. Ingresar al sistema desde móvil → vista simplificada de campo
2. Buscar o crear cliente rápidamente
3. Agregar productos al pedido (búsqueda por nombre o código)
4. Ver precios y stock en tiempo real (requiere conexión)
5. Confirmar dirección (puede usar geolocalización del dispositivo)
6. Ingresar notas y hora estimada de entrega
7. Enviar pedido → aparece en el sistema con estado `PENDIENTE`
8. Confirmación con número de pedido en pantalla

---

### FLUJO 5 – Consultar ficha de un cliente

**Dónde:** `/clientes/{id}`

**Pasos:**
1. Buscar por nombre, RUC o email
2. Ver ficha completa: datos de contacto, categoría, historial de cotizaciones, historial de compras, saldo pendiente, tags
3. Desde la ficha: crear nueva cotización pre-cargada con los datos del cliente

---

# ROL 6 – CAJERO

## Vistas accesibles: POS, Historial de sus ventas del día, Cierre de caja, Clientes y Productos (solo consulta)

---

### FLUJO 1 – Abrir caja

**Dónde:** `/pos`

**Pasos:**
1. Ingresar al sistema → si caja cerrada, aparece modal obligatorio de **"Apertura de Caja"**
2. Ingresar monto inicial en efectivo
3. Confirmar → caja abierta con registro de usuario, hora y monto
4. El sistema carga la pantalla del POS

---

### FLUJO 2 – Registrar una venta en POS

**Dónde:** `/pos`

**Pasos:**
1. Buscar producto: escribir nombre, SKU o escanear código de barras
2. Clic en el producto → se agrega al carrito (panel derecho)
3. Ajustar cantidad si es necesario
4. Repetir para cada producto
5. Seleccionar cliente: buscar por nombre/RUC/DNI o dejar como "Consumidor Final"
6. Aplicar descuento si tiene permiso
7. Seleccionar método de pago:
   - **Efectivo:** ingresar monto recibido → sistema calcula vuelto
   - **Tarjeta:** ingresar referencia
   - **QR / Yape / Plin:** confirmar
   - **Crédito:** solo si el cliente tiene crédito aprobado y saldo disponible
   - **Mixto:** combinar métodos (ej: efectivo + tarjeta)
8. Clic en **"Cobrar"**
9. El sistema genera la venta, descuenta el stock y emite el comprobante
10. Pantalla de confirmación con número de comprobante
11. Opciones: imprimir ticket, enviar por email o enviar por WhatsApp

---

### FLUJO 3 – Modo offline (sin internet)

**Dónde:** `/pos`

**Pasos:**
1. Caída de conexión → sistema detecta automáticamente → muestra banner **"Modo Offline"**
2. El POS sigue con datos locales en caché
3. Ventas se guardan en IndexedDB del navegador
4. **Disponible offline:** registrar ventas en efectivo, ver productos precargados
5. **No disponible offline:** verificar stock en tiempo real, emitir comprobante SUNAT (queda en cola), verificar crédito del cliente
6. Al reconectar → aviso **"Sincronizando X ventas offline"**
7. Sistema procesa cada venta offline en orden cronológico
8. Si alguna falla (ej: stock insuficiente): aparece en lista de errores para revisión

---

### FLUJO 4 – Emitir nota de crédito (devolución o anulación)

**Dónde:** `/pos/notas-credito`

**Pasos:**
1. Ir a historial de ventas → buscar la venta a anular o devolver
2. Clic en la venta → **"Emitir Nota de Crédito"**
3. Seleccionar motivo: anulación, devolución parcial, error en precio, etc.
4. Si es devolución parcial: seleccionar qué productos y en qué cantidad
5. Confirmar → nota de crédito electrónica emitida a SUNAT
6. Stock de productos devueltos repuesto automáticamente
7. Nota queda vinculada al comprobante original

---

### FLUJO 5 – Cerrar caja

**Dónde:** `/pos/cierre-caja`

**Pasos:**
1. Clic en **"Cerrar Caja"** desde el menú del POS
2. Ver resumen automático de la jornada:
   - Total de ventas por método de pago
   - Total en efectivo esperado
   - Total de transacciones del día
3. Ingresar el monto físico contado en caja
4. Sistema calcula diferencia (sobrante o faltante)
5. Confirmar cierre → caja en estado `CERRADA`
6. Opción de imprimir o enviar reporte de cierre

---

# ROL 7 – ALMACENERO

## Vistas accesibles: Entradas, Salidas, Transferencias (confirmar recepción), Recepciones de compras, Trazabilidad (consulta)

---

### FLUJO 1 – Recibir mercadería de una orden de compra

**Dónde:** `/compras/recepciones`

**Pasos:**
1. Ver lista de OC con estado `APROBADA` o `ENVIADA` pendientes de recepción
2. Clic en la OC a recibir → ver productos esperados con cantidades
3. Por cada línea de producto:
   - Ingresar **cantidad recibida** (puede diferir de la esperada)
   - Si tiene trazabilidad: ingresar número de lote y fecha de vencimiento (obligatorios)
   - Estado del ítem: `OK` / `DAÑADO` / `FALTANTE` / `VENCIDO`
   - Si hay problema: tomar foto como evidencia
4. Al terminar todos los ítems:
   - Todo OK → **"Confirmar Recepción Total"** → stock actualizado, OC = `RECIBIDA`
   - Parcial → **"Confirmar Recepción Parcial"** → OC sigue abierta
   - Con incidencias → sistema notifica al supervisor y al proveedor automáticamente

---

### FLUJO 2 – Registrar salida interna de productos

**Dónde:** `/inventario/salidas/nueva`

**Pasos:**
1. Seleccionar almacén origen
2. Tipo de salida: consumo interno / baja / devolución a proveedor
3. Agregar productos y cantidad
4. Si tiene trazabilidad: seleccionar el lote específico (FIFO por defecto)
5. Ingresar motivo (obligatorio)
6. Confirmar → stock descontado, movimiento registrado

---

### FLUJO 3 – Confirmar recepción de transferencia interna

**Dónde:** `/inventario/transferencias`

**Pasos:**
1. Ver transferencias pendientes de recepción para su almacén (estado `SOLICITADA`)
2. Clic en la transferencia → ver detalle de productos que llegan
3. Al recibir físicamente: ingresar cantidad recibida por ítem
4. Si coincide → **"Confirmar Recepción"** → stock actualizado, transferencia = `CONFIRMADA`
5. Si hay diferencia → registrar con observación → supervisor recibe alerta → transferencia = `CON_INCIDENCIA`

---

### FLUJO 4 – Consultar stock y ubicación de un producto

**Dónde:** `/inventario/stock`

**Pasos:**
1. Buscar producto por nombre o SKU
2. Ver en qué almacenes tiene stock y cuánto hay en cada uno
3. Ver ubicación dentro del almacén: zona / estantería (si está configurado)
4. Ver si hay stock reservado por pedidos pendientes de despacho

---

# ROL 8 – CONTADOR / FINANCIERO

## Vistas accesibles: Facturación completa, CxC, CxP, Conciliación bancaria, Libros contables, Declaraciones tributarias, Aprobación y pago de facturas de proveedores

---

### FLUJO 1 – Emitir comprobante electrónico manualmente

**Dónde:** `/facturacion/emitir`

**Pasos:**
1. Seleccionar tipo: Factura / Boleta / Nota de Crédito / Nota de Débito
2. Buscar y seleccionar cliente (validación de RUC/DNI automática contra SUNAT)
3. Agregar productos/servicios: descripción, cantidad, precio, tipo de afectación IGV
4. Verificar totales calculados automáticamente: subtotal, IGV, total
5. Seleccionar serie (asignada automáticamente, puede elegirla)
6. Vista previa en PDF embebido antes de enviar
7. **"Emitir y Enviar a SUNAT"**
8. Ver estado en tiempo real: `Generando XML` → `Firmando` → `Enviando` → `Aceptado` ✅ o `Rechazado` ❌
9. Si aceptado: disponible para descargar en PDF, XML y CDR

---

### FLUJO 2 – Gestión de comprobantes rechazados o en contingencia

**Dónde:** `/facturacion/cola-pendientes`

**Pasos:**
1. Ver lista de comprobantes: `RECHAZADO` / `PENDIENTE` / `CONTINGENCIA`
2. Para rechazados: ver el mensaje de error de SUNAT con el campo problemático
3. Si es corregible: **"Corregir y Reenviar"** → editar campo con error → confirmar
4. Si no es corregible: emitir Nota de Crédito para anular
5. Los de contingencia: esperan reintento automático (cada 15 min) o reintento manual

---

### FLUJO 3 – Consultar y gestionar comprobantes emitidos

**Dónde:** `/facturacion/comprobantes`

**Pasos:**
1. Filtrar por: tipo, serie, número, cliente, RUC, estado SUNAT, rango de fechas
2. Ver tabla con badge de estado por comprobante
3. Clic en cualquier comprobante → ver PDF embebido, XML firmado (descargable), CDR (descargable), historial de envíos
4. Acciones: descargar PDF, descargar XML, reenviar, emitir nota de crédito/débito
5. Exportar reporte filtrado a Excel/PDF

---

### FLUJO 4 – Registrar cobro de una cuenta por cobrar

**Dónde:** `/finanzas/cuentas-cobrar`

**Pasos:**
1. Ver tabla con semáforo: verde (vigente), amarillo (por vencer), rojo (vencido)
2. Filtrar por cliente o estado
3. Clic en documento → **"Registrar Cobro"**
4. Ingresar: monto (puede ser parcial), método de pago, moneda, tipo de cambio si aplica, referencia, fecha
5. Si es parcial → saldo actualizado, documento sigue `PENDIENTE`
6. Si cubre el total → documento pasa a `PAGADO`
7. Asiento contable generado automáticamente

---

### FLUJO 5 – Conciliación bancaria

**Dónde:** `/finanzas/conciliacion`

**Pasos:**
1. Seleccionar banco y cuenta
2. **"Cargar Extracto"** → subir CSV/Excel del banco
3. Sistema muestra movimientos importados
4. El motor de matching muestra sugerencias de coincidencia con % de confianza
5. Por cada sugerencia:
   - **"Confirmar"** → ambos movimientos quedan conciliados ✅
   - **"Ignorar"** → movimiento bancario queda sin conciliar
   - **"Crear diferencia"** → para comisiones, redondeos, etc.
6. Ver resumen: conciliados vs. pendientes
7. Movimientos no conciliados después de X días generan alerta automática

---

### FLUJO 6 – Aprobar factura de proveedor y registrar pago

**Dónde:** `/compras/facturas`

**Pasos:**
1. Ver facturas con estado `PENDIENTE_CONCILIACION`
2. Verificar que la factura ya fue conciliada por el almacenero (prerequisito)
3. Si está conciliada: **"Validar en SUNAT"** → verifica validez del comprobante
4. Si es válida: **"Aprobar para Pago"** → estado = `APROBADA_PARA_PAGO`
5. Registrar el pago: método, monto, referencia bancaria, fecha
6. Asiento contable del pago generado automáticamente

---

### FLUJO 7 – Cierre tributario mensual

**Dónde:** `/finanzas/tributario`

**Pasos:**
1. Seleccionar mes a cerrar
2. Ver checklist previo al cierre:
   - ✅ Todos los comprobantes del mes tienen CDR aceptado
   - ✅ No hay asientos sin cuadrar
   - ✅ Conciliación bancaria del mes completada
   - ✅ CxC y CxP actualizadas
3. Si hay ítems pendientes → no se puede cerrar (se muestran en rojo con enlace directo)
4. Si todo OK → **"Generar PLE"** → archivos TXT de Libro de Compras y Ventas generados
5. Descargar y revisar archivos PLE
6. **"Cerrar Periodo"** → ingresar firma digital → periodo = `CERRADO`
7. Periodo cerrado: no se puede modificar nada de ese mes

---

### FLUJO 8 – Enviar resumen diario de boletas a SUNAT

**Dónde:** `/facturacion/resumen-diario`

**Pasos:**
1. Ver resumen de boletas del día generadas
2. Si el sistema no lo envió automáticamente (tarea programada a las 23:50): clic en **"Enviar Resumen Diario"**
3. Ver estado: `PENDIENTE` → `ENVIADO` → `ACEPTADO` / `ERROR`
4. Si hay error: ver código de respuesta SUNAT y reintentar

---

# ROL 9 – REPARTIDOR / CONDUCTOR

## Vistas accesibles: Solo sus entregas del día. Vista 100% optimizada para móvil (PWA).

---

### FLUJO 1 – Iniciar jornada y ver ruta del día

**Dónde:** `/conductor/inicio`

**Pasos:**
1. Ingresar al sistema desde el celular → landing en vista de conductor
2. Ver resumen de jornada: total de entregas asignadas, mapa con todos los puntos en orden
3. Clic en **"Iniciar Jornada"** → el sistema empieza a registrar su ubicación GPS cada 30 segundos
4. Desde ese momento clientes y supervisor pueden ver su ubicación en tiempo real

---

### FLUJO 2 – Navegar al punto de entrega

**Dónde:** `/conductor/ruta`

**Pasos:**
1. Ver lista de entregas del día en orden de ruta sugerido
2. Clic en la primera entrega → ver: nombre del cliente, dirección, productos del pedido, notas especiales, código QR
3. Clic en **"Navegar"** → abre Google Maps / Waze con la dirección cargada
4. Al llegar → clic en **"He llegado"** → registra evento con coordenadas GPS actuales

---

### FLUJO 3 – Escanear QR para recoger pedido en almacén

**Dónde:** `/conductor/escanear`

**Pasos:**
1. En el almacén de despacho → **"Escanear Pedido"**
2. Abrir cámara del celular → escanear QR de la hoja de ruta del pedido
3. Sistema muestra detalle del pedido vinculado al QR
4. Verificar que los productos físicos coincidan
5. **"Pedido Recogido"** → estado pasa de `PLANIFICADO` a `EN_RUTA`
6. Repetir para cada pedido al cargar el vehículo

---

### FLUJO 4 – Confirmar entrega exitosa

**Dónde:** `/conductor/entrega/{pedido_id}`

**Pasos:**
1. Al llegar al punto de entrega → clic en el pedido → **"Confirmar Entrega"**
2. Registrar al menos UNA evidencia (el sistema requiere mínimo una):

   **Opción A – Foto:**
   - Clic en **"Tomar Foto"** → abre cámara del celular
   - Tomar foto del paquete entregado o del cliente recibiendo
   - Confirmar y subir

   **Opción B – Firma digital:**
   - El cliente firma en la pantalla táctil del celular del conductor
   - **"Guardar Firma"**

   **Opción C – OTP:**
   - **"Enviar Código al Cliente"** → cliente recibe código de 6 dígitos por WhatsApp/SMS
   - Cliente le dice el código al conductor
   - El conductor lo ingresa → sistema lo verifica

3. Con evidencia registrada → **"Marcar como Entregado"**
4. Pedido pasa a estado `ENTREGADO`
5. Cliente recibe notificación automática (WhatsApp/email)
6. Conductor ve el siguiente pedido en su lista

---

### FLUJO 5 – Registrar intento fallido de entrega

**Dónde:** `/conductor/entrega/{pedido_id}`

**Pasos:**
1. Si no puede entregar → **"No se pudo entregar"**
2. Seleccionar motivo: cliente ausente / dirección no encontrada / cliente rechazó / producto dañado / otro
3. Campo de texto para observación adicional
4. Opcional: tomar foto como evidencia
5. Confirmar → pedido pasa a estado `FALLIDO`
6. Supervisor recibe alerta inmediata con motivo
7. Sistema puede reagendar automáticamente para el día siguiente

---

### FLUJO 6 – Ver historial de sus entregas del día

**Dónde:** `/conductor/historial`

**Pasos:**
1. Clic en **"Mi Historial"** desde el menú del conductor
2. Ver pedidos del día: entregados ✅, fallidos ❌, pendientes ⏳
3. Ver evidencias registradas (fotos, firmas)
4. No puede modificar entregas ya confirmadas

---

# ROL 10 – CLIENTE (Portal Público de Seguimiento)

## Sin login. Acceso solo vía URL única del pedido.

---

### FLUJO 1 – Consultar estado del pedido

**Dónde:** `empresa.com/seguimiento?codigo=XXXX`

**Pasos:**
1. Recibe la URL por WhatsApp o email al hacer su pedido
2. Ingresa al link sin necesidad de cuenta ni login
3. Ve la pantalla de seguimiento:
   - Estado actual del pedido (badge visual): `Confirmado` → `Preparando` → `En camino` → `Entregado`
   - Timeline de eventos con fecha y hora de cada cambio de estado
   - Datos del pedido: número, productos, dirección de entrega
   - Fecha estimada de entrega (ETA)
4. Si el pedido está `EN_RUTA`:
   - Ver mapa con ubicación en tiempo real del repartidor (si está habilitado)
   - Distancia estimada y tiempo restante
5. Si el pedido fue `ENTREGADO`:
   - Confirmación con fecha y hora de entrega
   - Foto de evidencia si el conductor la tomó

**Puede hacer:** Solo ver. No puede modificar nada.

---

# Flujos Comunes a Todos los Roles

### Login y autenticación

**Pasos:**
1. Ingresar a la URL del sistema
2. Pantalla de login: email + contraseña
3. Si tiene 2FA: ingresar código de Google Authenticator
4. Si usa SSO: clic en **"Continuar con Google"** o **"Continuar con Microsoft"**
5. Según el rol → redirige automáticamente a su vista de inicio
6. Si la contraseña expiró → fuerza cambio antes de continuar

### Cambio de contraseña

**Pasos:**
1. Menú de perfil → **"Cambiar Contraseña"**
2. Ingresar contraseña actual + nueva contraseña + confirmación
3. La nueva debe cumplir requisitos mínimos de seguridad

### Notificaciones internas

- Icono de campana en el header con contador de no leídas
- Al hacer clic: lista de notificaciones relevantes para el rol

Ejemplos por rol:
- **Almacenero / Supervisor Almacén:** alerta de producto bajo stock mínimo, lote próximo a vencer
- **Conductor:** nuevo pedido asignado a su ruta del día
- **Cajero:** OV convertida pendiente de cobro
- **Contador:** comprobante rechazado por SUNAT, cuenta por cobrar vencida
- **Supervisor Logística:** entrega fallida registrada por conductor
- **Gerente:** cotizaciones próximas a vencer del equipo, meta de ventas por debajo del objetivo
- **Vendedor:** cotización aceptada por el cliente lista para convertir

---

# Resumen de Accesos por Rol

| Vista / Módulo | Admin | Gerente | Sup. Almacén | Sup. Logística | Vendedor | Cajero | Almacenero | Contador | Conductor |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Dashboard global completo | ✅ | ✅ | Solo almacén | Solo logística | Solo ventas propias | ❌ | ❌ | Solo finanzas | ❌ |
| POS | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Cotizaciones | ✅ | Solo lectura | ❌ | ❌ | ✅ solo propias | ❌ | ❌ | ❌ | ❌ |
| Órdenes de Venta | ✅ | Solo lectura | ❌ | Solo despacho | ✅ solo propias | ❌ | ❌ | ❌ | ❌ |
| Clientes | ✅ | Solo lectura | ❌ | ❌ | ✅ | Solo consulta | ❌ | ❌ | ❌ |
| Inventario / Stock | ✅ | Solo lectura | ✅ | Solo consulta | Solo consulta | Solo consulta | ✅ | ❌ | ❌ |
| Transferencias almacén | ✅ | ❌ | ✅ crear | ❌ | ❌ | ❌ | ✅ confirmar | ❌ | ❌ |
| Ajuste manual de stock | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Trazabilidad lotes | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | Solo consulta | ❌ | ❌ |
| Facturación SUNAT | ✅ | ❌ | ❌ | ❌ | ❌ | Solo boletas POS | ❌ | ✅ | ❌ |
| CxC / CxP | ✅ | Solo lectura | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Conciliación bancaria | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Libros contables | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Declaraciones SUNAT / PLE | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Compras / Proveedores | ✅ | Solo lectura | ✅ recepción | ❌ | ❌ | ❌ | ✅ recepción | ✅ pago | ❌ |
| Rutas y planificación | ✅ | Solo lectura | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Solo sus rutas |
| Seguimiento entregas | ✅ | Solo lectura | ❌ | ✅ | Solo sus pedidos | ❌ | ❌ | ❌ | Solo sus entregas |
| WhatsApp / Mensajería | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Usuarios y Roles | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Audit Log | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Reportes globales | ✅ | ✅ | Solo inventario | Solo logística | Solo ventas propias | Solo cierre de caja | ❌ | Finanzas / tributario | ❌ |
| Configuración sistema | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

*Generado desde: PROYECTO_JSOLUCIONES.pdf – Sin multi-tenancy – Basado estrictamente en las funcionalidades descritas en el documento.*