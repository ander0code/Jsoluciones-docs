# JSOLUCIONES ERP — Flujos por Rol

> Flujos paso a paso de cada rol en el sistema. Sin multi-tenancy. Una sola empresa por instalación.
> Basado en PROYECTO_JSOLUCIONES.pdf.

---

## Roles del Sistema

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

# ROL 1 — ADMINISTRADOR

## Vistas accesibles: TODAS

### FLUJO 1 — Configuración inicial del sistema

**Dónde:** Panel de Administración → Configuración

**Pasos:**
1. `/configuracion/empresa` → completar: razón social, RUC, dirección, logo, régimen tributario
2. `/configuracion/sucursales` → crear sucursales con nombre, dirección y responsable
3. `/configuracion/almacenes` → crear almacenes, asignar a cada sucursal
4. `/configuracion/series-facturacion` → definir series por tipo (F001 facturas, B001 boletas)
5. `/configuracion/certificado-digital` → cargar certificado PFX para firma SUNAT
6. `/configuracion/parametros` → definir: IGV (18%), stock mínimo por defecto, días de crédito, tolerancia conciliación bancaria
7. `/configuracion/whatsapp` → ingresar token, Phone Number ID, dominio verificado de Meta

### FLUJO 2 — Gestión de usuarios y roles

**Dónde:** `/usuarios` y `/roles`

**Crear usuario:**
1. Ir a `/usuarios` → tabla con nombre, email, rol, sucursal, estado
2. Clic en **"Nuevo Usuario"** → completar: nombre, email, contraseña temporal, rol, sucursal
3. Guardar → usuario recibe email con contraseña temporal
4. Opcional: activar 2FA desde la ficha del usuario

**Crear/editar rol:**
1. Ir a `/roles` → tabla de roles existentes
2. Clic en **"Nuevo Rol"** o en uno existente
3. Asignar nombre y descripción
4. **Matriz de permisos:** filas = módulos, columnas = acciones (Ver / Crear / Editar / Eliminar / Exportar)
5. Marcar/desmarcar checkboxes → Guardar

**Desactivar usuario:**
1. Tabla de usuarios → clic en el usuario
2. Cambiar estado a **Inactivo** → invalida todos sus tokens activos inmediatamente

### FLUJO 3 — Ver Audit Log

**Dónde:** `/auditoria`

1. Aplicar filtros: usuario, módulo, tipo de acción, rango de fechas
2. Ver tabla: quién hizo qué, en qué objeto, cuándo, desde qué IP
3. Clic en fila → detalle: datos antes y después del cambio
4. Exportar a Excel o PDF

### FLUJO 4 — Gestión de backups

**Dónde:** `/administracion/backups`

1. Ver historial de backups: fecha, tamaño, estado
2. Configurar frecuencia de backup automático (diario/semanal)
3. Clic en **"Restaurar"** en un backup → confirmar modal → ejecutar restauración

### FLUJO 5 — Dashboard Ejecutivo Global

**Dónde:** `/dashboard`

**Ve:**
- KPIs de ventas del día / semana / mes (todas las sucursales)
- KPIs de inventario: bajo stock, valor total de inventario
- KPIs financieros: CxC vencidas, flujo de caja del mes
- KPIs de logística: pedidos entregados / en ruta / fallidos
- TOP 5 productos más vendidos, clientes por monto, vendedores por monto
- Alertas activas del sistema (stock bajo, cotizaciones vencidas, comprobantes rechazados)
- Variación % vs. periodo anterior en cada KPI
- Actualización automática cada 10 minutos

---

# ROL 2 — GERENTE DE VENTAS / GERENTE GENERAL

## Vistas accesibles: Dashboard, Ventas, Reportes, Clientes (lectura), Cotizaciones (lectura), Facturación (lectura)

### FLUJO 1 — Revisión diaria del dashboard

1. Landing en `/dashboard`
2. Ver KPIs: ventas del día vs. meta, comparativo semanal, TOP 5 productos/clientes, cotizaciones por vencer, flujo de caja
3. Aplicar filtros de fecha y canal de venta
4. Clic en KPI → navega al reporte detallado

### FLUJO 2 — Análisis de ventas

**Dónde:** `/reportes/ventas`

1. Filtrar por: periodo, canal, sucursal, vendedor, categoría
2. Ver tabla + gráfico de barras + línea de tendencia
3. Cambiar a vista "Ventas por Vendedor" → ranking con monto y cantidad
4. Cambiar a vista "Ventas por Producto" → ranking y margen
5. Exportar a Excel o PDF

### FLUJO 3 — Seguimiento de cotizaciones del equipo

1. `/cotizaciones` → todas las cotizaciones del equipo
2. Filtrar por: estado, vendedor, cliente, rango de fechas
3. Ver tasa de conversión: aceptadas / total emitidas
4. Clic en cotización → solo lectura

### FLUJO 4 — Reporte de comisiones

1. Seleccionar periodo y vendedor
2. Ver: total de ventas, % de comisión, monto generado
3. Exportar para nómina

### FLUJO 5 — Configurar reporte semanal automático

1. `/reportes/programaciones` → **"Nueva Programación"**
2. Seleccionar tipo, frecuencia, formato PDF
3. Ingresar emails destinatarios → Guardar

---

# ROL 3 — SUPERVISOR DE ALMACÉN

## Vistas accesibles: Inventario completo, Recepciones de compras, Reportes de inventario, Dashboard de almacén

### FLUJO 1 — Revisión de stock y alertas

1. Ver panel con alertas activas al ingresar (productos en rojo/amarillo)
2. Tabla: producto, almacén, stock actual, mínimo, máximo, estado (semáforo)
3. Filtrar por almacén, categoría, estado de stock
4. Clic en producto → ver historial de movimientos
5. Si stock crítico → **"Generar Orden de Compra"** → redirige a compras con producto pre-cargado

### FLUJO 2 — Registrar entrada de mercadería

**Dónde:** `/inventario/entradas/nueva`

1. Seleccionar almacén de destino y proveedor
2. Agregar productos: nombre/SKU, cantidad
3. Si requiere trazabilidad: ingresar número de lote (obligatorio) y fecha de vencimiento
4. Revisar resumen → **"Confirmar Entrada"**
5. Stock actualizado en tiempo real, movimiento registrado

### FLUJO 3 — Registrar ajuste manual de stock

1. Seleccionar almacén y producto
2. Indicar nuevo stock o diferencia (+/-)
3. Ingresar **motivo** (campo obligatorio: merma, error de conteo, daño, etc.)
4. Confirmar → movimiento tipo `AJUSTE` registrado con usuario, motivo y timestamp

### FLUJO 4 — Crear transferencia entre almacenes

1. Seleccionar almacén origen y destino
2. Agregar productos a transferir: producto, cantidad, lote si aplica
3. Sistema valida stock en origen en tiempo real
4. Confirmar → estado = `SOLICITADA`
5. Almacenero del destino recibe notificación

### FLUJO 5 — Ver trazabilidad de un lote

1. Buscar por número de lote o serie
2. Ver historial completo de movimientos (entrada → transferencias → salida por venta)
3. Ver estado del lote: activo / agotado / vencido
4. Ver almacén actual y cantidad disponible
5. Exportar historial a PDF

---

# ROL 4 — SUPERVISOR DE LOGÍSTICA

## Vistas accesibles: Pedidos, Rutas, Transportistas, Seguimiento en tiempo real, Reportes de logística

### FLUJO 1 — Planificación de rutas del día

**Dónde:** `/logistica/rutas/nueva`

1. `/logistica/pedidos` → ver pedidos `PENDIENTE` de despacho para hoy
2. Ver en mapa los puntos de entrega como pines
3. Seleccionar pedidos a despachar hoy
4. Agrupar por zona geográfica automáticamente
5. Asignar pedidos a transportista (sistema valida capacidad peso/volumen/pedidos max)
6. **"Optimizar Ruta"** → algoritmo calcula orden óptimo (Nearest Neighbor)
7. Ver ruta resultante en el mapa
8. Confirmar → genera hoja de ruta digital con QR por pedido
9. Conductor recibe la ruta en su vista móvil automáticamente

### FLUJO 2 — Seguimiento en tiempo real

**Dónde:** `/logistica/seguimiento`

1. Mapa con iconos de cada conductor (actualización cada 30s)
2. Panel lateral: lista de pedidos con estado en tiempo real
3. Clic en pedido → ver timeline: despachado → en camino → entregado
4. Si pedido `FALLIDO` → ver motivo registrado por el conductor
5. Reasignar el pedido fallido a otro conductor o reagendar

### FLUJO 3 — Gestión de transportistas

1. Ver tabla: nombre, vehículo, capacidad, límite pedidos/día, estado
2. **Crear:** nombre, vehículo, peso máximo, volumen máximo, límite de pedidos por día
3. **Desactivar** cuando no está disponible
4. Ver historial de entregas: total, completadas, fallidas, puntualidad

---

# ROL 5 — VENDEDOR

## Vistas accesibles: Clientes, Cotizaciones propias, Órdenes de venta propias, Productos (consulta)

### FLUJO 1 — Crear una cotización

**Dónde:** `/ventas/cotizaciones/nueva`

1. **Paso 1 – Cliente:** buscar por nombre/RUC/DNI → si no existe: crear (nombre, RUC/DNI, teléfono, email)
2. **Paso 2 – Productos:** buscar por nombre/SKU, agregar con cantidad y precio; ver stock en tiempo real
3. **Paso 3 – Condiciones:** fecha de validez, condiciones de pago, notas al cliente
4. **Paso 4 – Resumen:** ver total con IGV desglosado
5. Guardar → estado = `VIGENTE`
6. Opción de enviar por email o WhatsApp al cliente

### FLUJO 2 — Seguimiento de cotizaciones propias

1. Ver tabla: estado, cliente, fecha, monto
2. Ver alertas de cotizaciones próximas a vencer (amarillo) y vencidas (rojo)
3. **Si cliente aceptó:** → **"Convertir a Orden de Venta"** → OV creada, cotización = `ACEPTADA`
4. **Si cotización venció:** → solo disponible **"Duplicar"** → copia con nueva fecha, estado = `VIGENTE`
5. **Si cliente rechazó:** → marcar como `RECHAZADA` con nota de motivo

### FLUJO 3 — Registro de pedido desde campo (móvil)

**Dónde:** `/ventas/pedido-campo` (vista responsive)

1. Ingresar desde móvil → vista simplificada de campo
2. Buscar o crear cliente rápidamente
3. Agregar productos (búsqueda por nombre o código)
4. Ver precios y stock en tiempo real
5. Confirmar dirección (puede usar geolocalización del dispositivo)
6. Ingresar notas y hora estimada de entrega
7. Enviar pedido → aparece en el sistema con estado `PENDIENTE`

---

# ROL 6 — CAJERO

## Vistas accesibles: POS, Historial de ventas del día, Cierre de caja, Clientes y Productos (solo consulta)

### FLUJO 1 — Abrir caja

1. Ingresar al sistema → si caja cerrada, modal obligatorio de **"Apertura de Caja"**
2. Ingresar monto inicial en efectivo
3. Confirmar → caja abierta con registro de usuario, hora y monto
4. El sistema carga la pantalla del POS

### FLUJO 2 — Registrar una venta en POS

**Dónde:** `/pos`

1. Buscar producto: nombre, SKU o código de barras
2. Clic en producto → se agrega al carrito
3. Seleccionar cliente (o dejar como "Consumidor Final")
4. Aplicar descuento si tiene permiso
5. Seleccionar método de pago:
   - **Efectivo:** ingresar monto recibido → vuelto automático
   - **Tarjeta:** ingresar referencia
   - **QR / Yape / Plin:** confirmar
   - **Crédito:** solo si cliente tiene crédito aprobado y saldo disponible
   - **Mixto:** combinar métodos
6. Clic en **"Cobrar"** → genera venta, descuenta stock, emite comprobante
7. Opciones: imprimir ticket, enviar por email o WhatsApp

### FLUJO 3 — Modo offline (sin internet)

1. Caída de conexión → banner automático **"Modo Offline"**
2. El POS sigue con datos locales en caché
3. Ventas se guardan en IndexedDB del navegador
4. **Disponible offline:** registrar ventas en efectivo, ver productos precargados
5. **No disponible offline:** verificar stock en tiempo real, emitir comprobante SUNAT, verificar crédito
6. Al reconectar → **"Sincronizando X ventas offline"** → procesamiento cronológico

### FLUJO 4 — Emitir nota de crédito (devolución o anulación)

**Dónde:** `/pos/notas-credito`

1. Historial de ventas → buscar la venta → **"Emitir Nota de Crédito"**
2. Seleccionar motivo: anulación, devolución parcial, error en precio, etc.
3. Si devolución parcial: seleccionar qué productos y en qué cantidad
4. Confirmar → nota de crédito electrónica emitida a SUNAT
5. Stock de productos devueltos repuesto automáticamente

### FLUJO 5 — Cerrar caja

**Dónde:** `/pos/cierre-caja`

1. Clic en **"Cerrar Caja"** desde el menú del POS
2. Ver resumen automático: total ventas por método de pago, total en efectivo esperado
3. Ingresar monto físico contado en caja
4. Sistema calcula diferencia (sobrante o faltante)
5. Confirmar cierre → caja en estado `CERRADA`
6. Opción de imprimir o enviar reporte de cierre

---

# ROL 7 — ALMACENERO

## Vistas accesibles: Entradas, Salidas, Transferencias (confirmar recepción), Recepciones de compras, Trazabilidad (consulta)

### FLUJO 1 — Recibir mercadería de una orden de compra

**Dónde:** `/compras/recepciones`

1. Ver lista de OC con estado `APROBADA` o `ENVIADA` pendientes de recepción
2. Clic en la OC → ver productos esperados con cantidades
3. Por cada línea de producto:
   - Ingresar **cantidad recibida** (puede diferir de la esperada)
   - Si tiene trazabilidad: ingresar número de lote y fecha de vencimiento (obligatorios)
   - Estado del ítem: `OK` / `DAÑADO` / `FALTANTE` / `VENCIDO`
   - Si hay problema: tomar foto como evidencia
4. Todo OK → **"Confirmar Recepción Total"** → stock actualizado, OC = `RECIBIDA`
5. Parcial → **"Confirmar Recepción Parcial"** → OC sigue abierta
6. Con incidencias → sistema notifica al supervisor y al proveedor automáticamente

### FLUJO 2 — Registrar salida interna de productos

1. Seleccionar almacén origen
2. Tipo de salida: consumo interno / baja / devolución a proveedor
3. Agregar productos y cantidad; si tiene trazabilidad: seleccionar el lote (FIFO por defecto)
4. Ingresar motivo (obligatorio)
5. Confirmar → stock descontado, movimiento registrado

### FLUJO 3 — Confirmar recepción de transferencia interna

1. Ver transferencias pendientes de recepción para su almacén (estado `SOLICITADA`)
2. Clic en transferencia → ver detalle de productos
3. Al recibir físicamente: ingresar cantidad recibida por ítem
4. Si coincide → **"Confirmar Recepción"** → stock actualizado, transferencia = `CONFIRMADA`
5. Si hay diferencia → registrar con observación → supervisor recibe alerta → transferencia = `CON_INCIDENCIA`

---

# ROL 8 — CONTADOR / FINANCIERO

## Vistas accesibles: Facturación completa, CxC, CxP, Conciliación bancaria, Libros contables, Declaraciones tributarias, Aprobación y pago de facturas de proveedores

### FLUJO 1 — Emitir comprobante electrónico manualmente

**Dónde:** `/facturacion/emitir`

1. Seleccionar tipo: Factura / Boleta / Nota de Crédito / Nota de Débito
2. Buscar y seleccionar cliente (validación de RUC/DNI automática contra SUNAT)
3. Agregar productos/servicios: descripción, cantidad, precio, tipo de afectación IGV
4. Verificar totales calculados automáticamente
5. Vista previa en PDF embebido antes de enviar
6. **"Emitir y Enviar a SUNAT"**
7. Ver estado en tiempo real: `Generando XML` → `Firmando` → `Enviando` → `Aceptado` ✅ o `Rechazado` ❌
8. Si aceptado: disponible para descargar en PDF, XML y CDR

### FLUJO 2 — Gestión de comprobantes rechazados o en contingencia

**Dónde:** `/facturacion/cola-pendientes`

1. Ver lista por estado: `RECHAZADO` / `PENDIENTE` / `CONTINGENCIA`
2. Para rechazados: ver el mensaje de error de SUNAT con el campo problemático
3. Si es corregible: **"Corregir y Reenviar"** → editar campo → confirmar
4. Si no es corregible: emitir Nota de Crédito para anular
5. Los de contingencia: reintento automático cada 15 min o reintento manual

### FLUJO 3 — Registrar cobro de una cuenta por cobrar

**Dónde:** `/finanzas/cuentas-cobrar`

1. Ver tabla con semáforo: verde (vigente), amarillo (por vencer), rojo (vencido)
2. Clic en documento → **"Registrar Cobro"**
3. Ingresar: monto (puede ser parcial), método de pago, referencia, fecha
4. Si parcial → saldo actualizado, documento sigue `PENDIENTE`
5. Si cubre el total → documento pasa a `PAGADO`
6. Asiento contable generado automáticamente

### FLUJO 4 — Conciliación bancaria

**Dónde:** `/finanzas/conciliacion`

1. Seleccionar banco y cuenta
2. **"Cargar Extracto"** → subir CSV/Excel del banco
3. Sistema muestra movimientos importados
4. Motor de matching muestra sugerencias con % de confianza
5. Por cada sugerencia: **"Confirmar"** ✅ / **"Ignorar"** / **"Crear diferencia"**
6. Ver resumen: conciliados vs. pendientes
7. Movimientos no conciliados después de X días generan alerta automática

### FLUJO 5 — Aprobar factura de proveedor y registrar pago

**Dónde:** `/compras/facturas`

1. Ver facturas con estado `PENDIENTE_CONCILIACION`
2. Verificar que la factura ya fue conciliada por el almacenero (prerequisito)
3. Si está conciliada: **"Validar en SUNAT"** → verifica validez del comprobante
4. Si es válida: **"Aprobar para Pago"** → estado = `APROBADA_PARA_PAGO`
5. Registrar el pago: método, monto, referencia bancaria, fecha
6. Asiento contable del pago generado automáticamente

### FLUJO 6 — Cierre tributario mensual

**Dónde:** `/finanzas/tributario`

1. Seleccionar mes a cerrar
2. Ver checklist previo:
   - Todos los comprobantes del mes tienen CDR aceptado
   - No hay asientos sin cuadrar
   - Conciliación bancaria del mes completada
   - CxC y CxP actualizadas
3. Si hay ítems pendientes → no se puede cerrar (se muestran en rojo con enlace directo)
4. Si todo OK → **"Generar PLE"** → archivos TXT de Libros SUNAT generados
5. Descargar y revisar archivos PLE
6. **"Cerrar Periodo"** → ingresar PIN de firma digital → periodo = `CERRADO`
7. Periodo cerrado: no se puede modificar nada de ese mes

### FLUJO 7 — Enviar resumen diario de boletas a SUNAT

**Dónde:** `/facturacion/resumen-diario`

1. Ver resumen de boletas del día
2. Si el sistema no lo envió automáticamente (tarea programada a las 23:50): clic en **"Enviar Resumen Diario"**
3. Ver estado: `PENDIENTE` → `ENVIADO` → `ACEPTADO` / `ERROR`
4. Si hay error: ver código de respuesta SUNAT y reintentar

---

# ROL 9 — REPARTIDOR / CONDUCTOR

## Vistas accesibles: Solo sus entregas del día. Vista 100% optimizada para móvil (PWA).

### FLUJO 1 — Iniciar jornada y ver ruta del día

**Dónde:** `/conductor/inicio`

1. Ingresar al sistema desde el celular → landing en vista de conductor
2. Ver resumen de jornada: total entregas asignadas, mapa con todos los puntos en orden
3. Clic en **"Iniciar Jornada"** → sistema empieza a registrar ubicación GPS cada 30 segundos
4. Clientes y supervisor pueden ver ubicación en tiempo real desde ese momento

### FLUJO 2 — Navegar al punto de entrega y escanear pedido

1. Ver lista de entregas en orden de ruta sugerido
2. Clic en la primera entrega → nombre del cliente, dirección, productos, notas, QR
3. En el almacén: **"Escanear Pedido"** → escanear QR → verificar productos físicamente
4. **"Pedido Recogido"** → estado pasa de `PLANIFICADO` a `EN_RUTA`
5. Clic en **"Navegar"** → abre Google Maps / Waze con la dirección cargada

### FLUJO 3 — Confirmar entrega exitosa

**Dónde:** `/conductor/entrega/{pedido_id}`

1. Al llegar → **"Confirmar Entrega"**
2. Registrar al menos UNA evidencia (mínimo obligatorio):
   - **Foto:** tomar foto del paquete entregado o del cliente recibiendo
   - **Firma digital:** cliente firma en la pantalla táctil del celular del conductor
   - **OTP:** **"Enviar Código al Cliente"** → cliente recibe código por WhatsApp/SMS → conductor lo ingresa
3. Con evidencia registrada → **"Marcar como Entregado"**
4. Pedido pasa a estado `ENTREGADO`
5. Cliente recibe notificación automática (WhatsApp/email)

### FLUJO 4 — Registrar intento fallido de entrega

1. Si no puede entregar → **"No se pudo entregar"**
2. Seleccionar motivo: cliente ausente / dirección no encontrada / cliente rechazó / producto dañado / otro
3. Campo de texto para observación adicional + foto opcional
4. Confirmar → pedido pasa a estado `FALLIDO`
5. Supervisor recibe alerta inmediata con motivo
6. Sistema puede reagendar automáticamente para el día siguiente

---

# ROL 10 — CLIENTE (Portal Público de Seguimiento)

## Sin login. Acceso solo vía URL única del pedido.

### FLUJO 1 — Consultar estado del pedido

**Dónde:** `empresa.com/seguimiento?codigo=XXXX`

1. Recibe la URL por WhatsApp o email al hacer su pedido
2. Ingresa al link sin necesidad de cuenta ni login
3. Ve la pantalla de seguimiento:
   - Estado actual: `Confirmado` → `Preparando` → `En camino` → `Entregado`
   - Timeline de eventos con fecha y hora de cada cambio
   - Datos del pedido: número, productos, dirección de entrega
   - Fecha estimada de entrega (ETA)
4. Si el pedido está `EN_RUTA`:
   - Ver mapa con ubicación en tiempo real del repartidor (si está habilitado)
   - Distancia estimada y tiempo restante
5. Si el pedido fue `ENTREGADO`:
   - Confirmación con fecha y hora
   - Foto de evidencia si el conductor la tomó

**Puede hacer:** Solo ver. No puede modificar nada.

---

# Flujos Genericos del Sistema (Independientes del Rol)

> Estos flujos describen como se mueven los datos internamente, sin importar que rol los inicia.
> Son la referencia para entender como conectar modulos nuevos (e-commerce, reservas, OT) con el nucleo del sistema.

## FLUJO A — Venta directa en tienda (sin delivery)

**Cuando aplica:** cualquier negocio con POS y el cliente retira en el local (floreria, mecanica, retail, hotel).

```
Cajero abre caja (abrir_caja)
    ↓
POST /ventas/pos/  [es_delivery=False]
    ↓
crear_venta_pos() [@transaction.atomic + select_for_update en Stock]
    1. Valida cliente (si se proporciona; puede ser "Consumidor Final")
    2. Valida almacen activo
    3. Valida caja abierta
    4. Por cada item:
       - Valida producto activo
       - Valida stock >= cantidad solicitada
       - Calcula subtotal / IGV / total
    5. Si metodo_pago=credito → valida limite de credito vs CxC pendientes
    6. Crea Venta [estado=COMPLETADA, tipo_venta=VENTA_DIRECTA]
    7. Crea DetalleVenta por cada item
    8. Descuenta stock (MovimientoStock tipo MOV_SALIDA)
    9. Genera asiento contable automatico
   10. on_commit → Celery encola emitir_comprobante_por_venta(venta_id)
    ↓
Celery emite comprobante electronico via Nubefact OSE
[PENDIENTE → ENVIADO → ACEPTADO por SUNAT]
    ↓
FIN — cliente se lleva el producto, comprobante disponible para descarga
```

**Campos involucrados en Venta:**
- `tipo_venta = VENTA_DIRECTA`
- `estado = COMPLETADA` (desde el inicio — no tiene estado intermedio)
- `metodo_pago` — efectivo, tarjeta, QR, credito, mixto
- `comprobante_id` — se llena en diferido por Celery

**Campos involucrados en DetalleVenta:**
- `producto`, `cantidad`, `precio_unitario`, `descuento_porcentaje`
- `subtotal`, `igv`, `total`
- `lote` (FK opcional — para trazabilidad)
- **NO tiene campos de personalizacion, notas ni texto libre** — eso va en el Pedido

---

## FLUJO B — Venta con delivery

**Cuando aplica:** floreria (entrega de arreglos), retail online, cualquier negocio que despacha a domicilio.

```
Vendedor/Cajero registra venta + datos de entrega
    ↓
POST /ventas/pos/  [es_delivery=True, datos_pedido={...}]
    ↓
crear_venta_con_pedido_pos() [@transaction.atomic]
    ├── crear_venta_pos()   [mismo flujo que Flujo A]
    └── crear_pedido()      [distribucion/services.py]
          1. Genera numero "PED-XXXXX" y codigo_seguimiento (8 chars UUID)
          2. Vincula venta_id al pedido
          3. Valida transportista si se asigna en el momento
          4. Crea Pedido [estado=PENDIENTE]
          5. Crea primer SeguimientoPedido ("Pedido creado")
    ↓
[Si el negocio tiene produccion/armado]
Estado produccion: PENDIENTE → ARMANDO → LISTO
    ↓
Supervisor Logistica asigna transportista
Pedido [estado=EN_RUTA]
SeguimientoPedido registrado
    ↓
Conductor confirma entrega (foto + firma + OTP)
Pedido [estado=ENTREGADO]
fecha_entrega_real registrada
    ↓
[WhatsApp/email al cliente — PENDIENTE de implementar]
```

**Conexion Venta → Pedido:**
```python
# En distribucion/models.py
Pedido.venta = ForeignKey("ventas.Venta", null=True, blank=True, on_delete=SET_NULL)
# La relacion inversa: venta.pedidos.all()
# Es opcional: una Venta puede no tener Pedido (retiro en tienda)
#              un Pedido puede no tener Venta (creado manualmente)
```

**Campos relevantes en Pedido:**
- `codigo_seguimiento` — 8 chars, para el portal publico sin login
- `nombre_destinatario`, `telefono_destinatario` — puede diferir del cliente que pago
- `turno_entrega` — manana | tarde (choices generico)
- `dedicatoria`, `notas` — texto libre (disponible para cualquier negocio)
- `es_urgente` — flag booleano
- `estado_produccion` — pendiente | armando | listo (Kanban de armado/preparacion)
- `foto_entrega`, `observacion_conductor` — evidencia de entrega

**Estados del Pedido:**
```
PENDIENTE → CONFIRMADO → DESPACHADO → EN_RUTA → ENTREGADO
                                            ↘ CANCELADO
```

**Estados de Produccion (Kanban interno):**
```
PENDIENTE → ARMANDO → LISTO
```
Este Kanban es generico: sirve para armar arreglos florales, preparar pedidos de cocina,
empacar productos, o cualquier proceso previo al despacho.

---

## FLUJO C — Venta desde Orden de Venta (B2B / Empresas)

**Cuando aplica:** clientes corporativos que solicitan cotizacion antes de comprar.

```
Vendedor crea Cotizacion
    ↓
Cliente aprueba → "Convertir a Orden de Venta"
Cotizacion [estado=ACEPTADA]
OrdenVenta creada [estado=PENDIENTE]
    ↓
Cajero/Vendedor convierte OV a Venta
POST /ventas/desde-orden/{orden_id}/
    ↓
[Mismo flujo que Flujo A o B segun si hay delivery]
OrdenVenta [estado=FACTURADA]
```

**Relacion OrdenVenta → Venta:**
```python
# En ventas/models.py
Venta.orden_origen = ForeignKey("OrdenVenta", null=True, blank=True)
```

---

## FLUJO D — E-commerce (a implementar)

**Cuando aplica:** cualquier negocio con tienda online.

> **Estado actual:** este flujo NO existe en el sistema. Los modelos marcados con [FALTA] hay que crearlos.
> El 80% del backend ya existe — solo falta la capa de entrada publica.

```
Cliente web agrega productos al carrito
    ↓
POST /api/publico/carrito/agregar/  [FALTA]
    → Crea/actualiza CarritoWeb [FALTA]
    → Reserva stock temporalmente (TTL 15-30 min en Redis)  [FALTA]
    ↓
Cliente confirma pedido → checkout
POST /api/publico/checkout/  [FALTA]
    ↓
Pasarela de pago (Culqi / Niubiz / Stripe)  [FALTA]
    → Pago exitoso → webhook confirma
    ↓
El sistema crea:
    Venta [tipo_venta="ecommerce"]   ← campo ya existe en el modelo, solo falta usarlo
    DetalleVenta por cada item       ← mismo modelo existente
    Stock descontado via registrar_salida()  ← codigo existente
    ↓
Si el negocio tiene delivery:
    Pedido creado en distribucion    ← mismo modelo existente
    Conductor asignado y entrega     ← mismo flujo que Flujo B
    ↓
Si NO tiene delivery (retiro en tienda):
    Cliente recibe notificacion "Tu pedido esta listo para retirar"
    ↓
Celery emite comprobante electronico  ← mismo codigo existente
```

**Que existe hoy vs que falta:**

| Componente | Existe | Falta |
|------------|--------|-------|
| Catalogo de productos | SI — `apps/inventario/` | Endpoint publico sin JWT |
| Cargar fotos del producto | SI — `apps/media/` | Asociacion al catalogo web |
| Stock y descuento | SI — `registrar_salida()` | Reserva temporal con TTL |
| Crear Venta | SI — `crear_venta_pos()` | Adaptacion para `tipo_venta=ecommerce` |
| Distribucion/Delivery | SI — `distribucion/` | Solo conectar con el pedido web |
| Facturacion SUNAT | SI — `facturacion/` | Nada — funciona igual |
| Finanzas / CxC | SI — `finanzas/` | Nada — funciona igual |
| Carrito con TTL | NO | Crear `CarritoWeb` + reserva en Redis |
| Pasarela de pago | NO | Integrar Culqi o similar |
| Endpoints publicos | NO | `urls_publicas.py` en inventario |
| Panel ERP para pedidos web | NO | Vista que filtre por `tipo_venta=ecommerce` |
| Perfil cliente web | NO | Registro/login separado del ERP |
| Cupones | NO | Modelo `Cupon` + validacion en checkout |

**Relacion con modulos existentes:**
- `PedidoEcommerce.confirmar()` llama a `crear_venta_pos()` con `tipo_venta="ecommerce"`
- El `Cobro` del pago digital se registra en `finanzas.Cobro` igual que un pago normal
- El despacho del pedido usa `distribucion.crear_pedido()` igual que el Flujo B

---

## Relacion entre Inventario y E-commerce

La vista de inventario del ERP (donde el admin carga productos) **es el mismo catalogo** que consume el e-commerce. No hay un catalogo separado.

**Lo que ya tiene el modelo Producto que sirve al e-commerce:**
- `nombre`, `descripcion` — titulo y descripcion corta
- `precio` — precio de venta
- `sku` — codigo del producto
- `categoria` — para filtros y navegacion
- `is_active` — para publicar/despublicar
- `imagenes` — via `MediaArchivo` (relacion polimorfica existente)

**Lo que hay que agregar al modelo Producto para e-commerce:**
- `descripcion_larga` — texto largo con formato (hoy solo hay `descripcion` corta)
- `slug` — URL amigable (`/productos/ramo-primavera` en vez de UUID)
- `destacado` — flag para mostrar en portada del e-commerce
- `orden_display` — orden de aparicion en el catalogo

Estos 4 campos se agregan al modelo existente sin romper nada.

---

## La Personalizacion de Pedidos: que es generico vs que es especifico del negocio

**Generico (ya en el template):**
- `Pedido.notas` — campo de texto libre para cualquier instruccion
- `Pedido.dedicatoria` — mensaje para el destinatario (util para floreria, regalos, etc.)
- `Pedido.estado_produccion` — Kanban generico: pendiente → armando → listo

**Especifico de floreria (en Amatista, NO en el template):**
- `DetalleVenta.notas_arreglista` — instrucciones por producto, no por pedido
- `AjustePersonalizacion` — cambiar insumos de la receta base por pedido
- `RecetaProducto` + `DetalleReceta` — BOM: que flores componen cada arreglo
- `estado_produccion` por item (no solo por pedido)

**Conclusion:** el template base tiene suficiente generalizacion para delivery con notas y dedicatoria. La personalizacion granular por item de pedido es el modulo BOM/Produccion que se activa solo para negocios que lo necesitan (floreria, restaurante, manufactura).

---

# Flujos Comunes a Todos los Roles

### Login y autenticación

1. Ingresar a la URL del sistema
2. Pantalla de login: email + contraseña
3. Si tiene 2FA: ingresar código de Google Authenticator
4. Si usa SSO: clic en **"Continuar con Google"** o **"Continuar con Microsoft"**
5. Según el rol → redirige automáticamente a su vista de inicio
6. Si la contraseña expiró → fuerza cambio antes de continuar

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

# Tabla de Accesos por Rol

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
