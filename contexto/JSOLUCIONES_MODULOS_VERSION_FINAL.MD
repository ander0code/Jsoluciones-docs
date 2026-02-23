# JSOLUCIONES ERP – Especificación de Módulos (Versión Final)
> Sin multi-tenancy. Sin eCommerce. Una sola empresa por instalación.
> Formato de validación para backend y frontend.

---

## Qué cambia respecto a la versión anterior del doc

**Solo dos cosas:**
- Se elimina `empresa_id` de todas las tablas y de toda la lógica
- Se elimina el módulo eCommerce del scope completamente

Todo lo demás permanece igual. Los flujos, los roles, las vistas, la lógica de negocio, Nubefact, WhatsApp — todo sigue en pie.

---

## MÓDULO 1 – Gestión de Ventas

### Qué debe hacer el backend
- Registrar ventas desde POS con múltiples métodos de pago (efectivo, tarjeta, QR, Yape, Plin, crédito, mixto)
- Gestionar apertura y cierre de caja con arqueo por usuario
- Registrar ventas desde campo (vendedor móvil) con sincronización posterior
- Recibir batch de ventas offline y procesarlas en orden cronológico, reportando cuáles fallaron
- Crear, editar y duplicar cotizaciones (las vencidas solo se duplican, no se editan)
- Convertir cotización aceptada en orden de venta
- Marcar cotizaciones como vencidas automáticamente (tarea programada nocturna)
- CRUD completo de clientes con validación de RUC/DNI único
- Descontar stock en el mismo momento de la venta, en transacción atómica
- Disparar emisión de comprobante al completar la venta
- Calcular subtotal, IGV y total correctamente por cada línea y en el total

### Qué debe hacer el frontend
- Vista POS: panel izquierdo con productos en cards, panel derecho con carrito
- Buscador de productos por nombre, SKU y código de barras
- Modal obligatorio de apertura de caja antes de la primera venta del día
- Modal de cierre de caja con resumen automático y campo para monto físico contado
- Selector de cliente con búsqueda rápida o campo "Consumidor Final"
- Botones de método de pago claramente diferenciados, soporte de pago mixto
- Campo de monto recibido en efectivo con cálculo automático del vuelto
- Banner visible cuando el sistema está en modo offline
- Sincronización automática al reconectar con indicador de progreso
- Lista de cotizaciones con badges de estado: vigente, vencida, aceptada, rechazada
- Wizard en 4 pasos para crear cotización: cliente → productos → condiciones → resumen
- Botón "Duplicar" visible solo en cotizaciones vencidas, "Convertir" solo en aceptadas
- Vista de campo responsive para móvil y tablet con funciones simplificadas
- Ficha de cliente con historial de compras, cotizaciones y saldo pendiente

### Reglas de negocio que deben estar implementadas
- No se puede vender sin stock salvo que el producto tenga el flag activado
- No se puede registrar venta si la caja no está abierta
- Cotización vencida: bloqueada para edición, solo opción de duplicar
- Venta al crédito: solo si el cliente tiene límite de crédito aprobado y tiene saldo
- Pago mixto: la suma de todos los métodos debe igualar el total de la venta
- El descuento no puede resultar en precio negativo

### Reportes que debe generar
- Ventas diarias con desglose por método de pago, cajero y caja
- Ventas por producto con cantidades y margen
- Ventas por cliente con frecuencia y ticket promedio
- Cotizaciones emitidas con tasa de conversión
- Órdenes de venta por estado
- Ventas offline sincronizadas con estado de integración
- Notas de crédito emitidas
- Dashboard gerencial: TOP 5 productos, clientes, vendedores

---

## MÓDULO 2 – Inventario y Logística

### Qué debe hacer el backend
- Mantener stock en tiempo real por producto y por almacén
- Registrar entradas, salidas y transferencias entre almacenes
- Validar stock antes de cada salida (bloquear si es insuficiente)
- Confirmar transferencias en el almacén destino antes de actualizar el stock
- Registrar ajustes manuales con motivo obligatorio y auditoría
- Manejar trazabilidad por lote o serie cuando el producto lo requiere
- Controlar fechas de vencimiento para productos perecibles
- Disparar alertas automáticas cuando el stock cae por debajo del mínimo
- Disparar alertas de lotes próximos a vencer (7 días antes)
- Aplicar FIFO automáticamente cuando hay trazabilidad activada

### Qué debe hacer el frontend
- Vista de stock con tabla filtrable por almacén, categoría y estado (semáforo verde/amarillo/rojo)
- Formulario de entrada de mercadería con campos de lote y vencimiento cuando aplica
- Formulario de salida con selector de lote (FIFO sugerido)
- Formulario de transferencia con validación de stock en tiempo real
- Vista de confirmación de transferencia para el almacén destino
- Formulario de ajuste manual con campo de motivo obligatorio
- Buscador de trazabilidad por número de lote o serie
- Dashboard de inventario con rotación ABC, alertas activas y gráfico entradas vs. salidas

### Reglas de negocio que deben estar implementadas
- No se puede hacer salida si no hay stock disponible (salvo autorización especial)
- Transferencia no se completa hasta que el destino confirma recepción
- Si hay diferencia en la recepción: queda en estado "Con incidencia", no se cierra
- Ajuste manual siempre requiere motivo
- Producto con trazabilidad activada: obligatorio ingresar lote/serie en cada movimiento

### Reportes que debe generar
- Stock actual por almacén con alertas
- Movimientos de inventario por periodo, producto, almacén
- Trazabilidad completa por lote o serie
- Transferencias entre almacenes con estado
- Productos bajo stock mínimo
- Lotes próximos a vencer

---

## MÓDULO 3 – Facturación Electrónica (con Nubefact OSE)

### Qué debe hacer el backend
- Generar XML UBL 2.1 correcto para facturas, boletas, notas de crédito y débito
- Firmar el XML con el certificado PFX configurado
- Empaquetar en ZIP con nombre exacto: `{RUC}-{TIPO}-{SERIE}-{NUMERO}.zip`
- Enviar al endpoint SOAP de Nubefact (DEMO o producción según configuración)
- Parsear la respuesta de Nubefact correctamente (formato diferente al de SUNAT directo)
- Guardar el XML firmado y el CDR en storage persistente
- Registrar cada intento de envío con respuesta completa
- Manejar modo contingencia: guardar en cola y reintentar automáticamente cada 15 minutos
- Limitar reintentos automáticos (máximo 5 intentos, luego requiere intervención manual)
- Generar PDF del comprobante con QR válido
- Enviar PDF al cliente por email o WhatsApp si está configurado
- Asignar correlativos de forma atómica para evitar duplicados
- Permitir que un comprobante rechazado se corrija y reenvíe con el mismo número

### Qué debe hacer el frontend
- Formulario de emisión manual con validación de RUC/DNI en tiempo real
- Vista previa del comprobante en PDF embebido antes de confirmar el envío
- Indicador visual del estado de envío en tiempo real: Generando → Firmando → Enviando → Aceptado/Rechazado
- Badges de estado por comprobante: Aceptado, Rechazado, Observado, Pendiente, Contingencia
- Lista de comprobantes con filtros por tipo, serie, cliente, estado y fecha
- Vista de detalle con PDF, XML y CDR descargables
- Cola de pendientes y rechazados con motivo del rechazo visible
- Botón de reenvío manual para rechazados y en contingencia
- Banner visible cuando el sistema está en modo DEMO
- Panel de resumen diario de boletas con estado de envío a SUNAT

### Reglas de negocio que deben estar implementadas
- No pueden existir dos comprobantes con la misma serie y número
- No se puede emitir con fecha futura
- La sumatoria de líneas debe cuadrar exactamente con el total del comprobante
- RUC del receptor validado antes del envío
- El botón de emitir se bloquea inmediatamente al hacer clic (evitar doble envío)
- Credenciales de Nubefact nunca en código, siempre en configuración encriptada
- Al pasar a producción: nunca enviar también a SUNAT directo

### Documentos que debe soportar
- Factura electrónica
- Boleta electrónica
- Nota de crédito (vinculada a comprobante origen)
- Nota de débito (vinculada a comprobante origen)
- Resumen diario de boletas

### Reportes que debe generar
- Comprobantes emitidos por periodo con estado SUNAT
- Comprobantes rechazados con motivo
- Resúmenes diarios enviados
- Reporte mensual de ventas electrónicas para exportar a Excel/PDF

---

## MÓDULO 4 – Distribución y Seguimiento de Pedidos

### Qué debe hacer el backend
- Registrar pedidos con origen (POS, campo) y asociarlos a cliente, productos y dirección
- Validar y reservar stock al crear el pedido (no descontar hasta entrega confirmada)
- Geocodificar direcciones si no vienen con coordenadas
- Asignar pedidos a transportistas con validación de capacidad máxima
- Ejecutar optimización de orden de entrega por ruta
- Generar QR único por pedido para escaneo en despacho
- Exponer endpoint público de seguimiento sin autenticación
- Recibir y guardar coordenadas GPS del transportista cada 30 segundos
- Emitir actualizaciones en tiempo real vía WebSocket
- Registrar evidencias de entrega: foto, firma digital o código OTP
- No permitir marcar como entregado sin al menos una evidencia
- Descontar stock definitivamente al confirmar la entrega
- Integrar con transportistas externos vía API o exportar CSV

### Qué debe hacer el frontend
- Vista de logística con mapa (Google Maps o Leaflet) y lista de pedidos pendientes
- Panel de asignación de pedidos a transportistas con validación de capacidad visible
- Vista de optimización de ruta con orden sugerido en el mapa
- Panel de seguimiento en tiempo real con iconos de transportistas en movimiento
- Timeline de eventos por pedido: despachado → en camino → entregado
- Vista pública de seguimiento accesible por URL sin login
- Vista móvil para el conductor: lista de entregas, botón de navegación, formulario de confirmación
- Escáner de QR en el móvil del conductor para recoger pedidos en almacén
- Opciones de evidencia de entrega: tomar foto, firma táctil, ingresar código OTP
- Badges de estado dinámicos por pedido: verde, amarillo, rojo
- Formulario de entrega fallida con selector de motivo y campo de observación

### Reglas de negocio que deben estar implementadas
- No se puede despachar sin stock reservado confirmado
- No se puede marcar como entregado sin evidencia (mínimo una)
- Transportista no puede recibir más pedidos de lo que permite su capacidad
- La URL pública de seguimiento no requiere login y es accesible por cualquier dispositivo
- Al registrar entrega fallida el supervisor recibe alerta inmediata

---

## MÓDULO 5 – Compras y Proveedores

### Qué debe hacer el backend
- Crear órdenes de compra manualmente o automáticamente por bajo stock
- Gestionar flujo de estados: Borrador → Pendiente aprobación → Aprobada → Enviada → Cerrada
- Requerir aprobación de usuario autorizado cuando el monto supera el límite configurado
- Registrar facturas de proveedores con validación contra SUNAT
- Calcular fechas de vencimiento según condiciones del proveedor
- Impedir registrar facturas duplicadas (mismo número + RUC)
- Gestionar recepción parcial o total con registro de incidencias y foto
- Bloquear el pago de facturas no conciliadas con la recepción
- Calcular KPIs de proveedores trimestralmente: puntualidad, calidad, precio
- Generar alerta cuando OC supera la fecha estimada de entrega sin recibirse

### Qué debe hacer el frontend
- Lista de órdenes de compra con estados y filtros
- Formulario de creación de OC con validación de proveedor activo
- Vista de comparador de proveedores por producto
- Formulario de recepción con campo de cantidad recibida por ítem y estado
- Opción de tomar foto como evidencia de incidencia
- Lista de facturas de proveedores con botón de validación SUNAT
- Vista de ficha de proveedor con historial y KPIs de desempeño
- Alerta de condiciones comerciales vencidas (revisión trimestral)

### Reglas de negocio que deben estar implementadas
- Factura no puede pagarse si no está conciliada completamente
- Proveedor inactivo no puede usarse en una nueva OC
- Solo el rol financiero puede aprobar el pago de facturas
- Toda OC necesita fecha estimada de entrega válida

---

## MÓDULO 6 – Gestión Financiera y Tributaria

### Qué debe hacer el backend
- Generar automáticamente cuenta por cobrar al registrar venta al crédito
- Generar automáticamente cuenta por pagar al registrar factura de proveedor
- Registrar pagos parciales o totales en múltiples métodos y monedas
- Calcular diferencia de cambio automáticamente cuando se paga en moneda distinta
- Parsear extractos bancarios en CSV/Excel por banco (BBVA, BCP, Interbank)
- Ejecutar motor de matching para sugerir conciliaciones (monto + fecha + referencia)
- Generar asientos contables automáticamente por cada operación financiera
- Validar doble partida: debe = haber siempre, rollback si no cuadra
- Bloquear uso de cuentas contables inactivas
- Bloquear asientos sin centro de costo
- Generar archivos PLE (TXT) y PDT (XML/ZIP) según especificación SUNAT
- Requerir firma digital del contador para cerrar un periodo tributario
- Bloquear modificaciones en periodos cerrados

### Qué debe hacer el frontend
- Lista de CxC y CxP con semáforo de vencimiento (verde/amarillo/rojo)
- Modal de registro de cobro/pago con soporte de pago parcial
- Vista de carga de extracto bancario con tabla de movimientos importados
- Panel de conciliación con sugerencias automáticas y botones confirmar/ignorar
- Vistas de Libro Diario, Mayor y Caja en formato tabular paginado
- Balance General y Estado de Resultados exportables
- Panel de declaraciones tributarias con checklist previo al cierre
- Botón de generación de PLE y PDT por periodo
- Indicador claro de periodo abierto vs. cerrado
- Alerta visual de CxC vencidas en el dashboard del contador

### Reglas de negocio que deben estar implementadas
- Ningún asiento sin centro de costo
- Periodo cerrado: no se puede modificar nada de ese mes
- Firma digital del contador es obligatoria para cierre tributario
- CxC vencida genera alerta automática
- Toda diferencia de cambio genera su asiento automático

---

## MÓDULO 7 – Comunicación con Clientes (WhatsApp API)

### Qué debe hacer el backend
- Conectar con Cloud API oficial de Meta usando token y número verificado
- Enviar mensajes automáticos por eventos del sistema: confirmación de venta, estado de pedido, vencimiento de cotización
- Gestionar plantillas: crear, enviar a aprobación de Meta, y usar solo las aprobadas
- Validar que el cliente tiene opt-in antes de enviar
- Respetar la ventana de 24 horas para mensajes sin plantilla
- Respetar límite de mensajes diarios según Tier de la cuenta
- Ejecutar campañas masivas en background con rate limiting
- Registrar cada mensaje enviado con su estado: enviado, entregado, leído, fallido
- Recibir y procesar webhooks de Meta (actualizaciones de estado)
- Validar firma HMAC de cada webhook recibido

### Qué debe hacer el frontend
- Panel de configuración de conexión con Meta: token, número, estado de conexión
- Lista de plantillas con badge de estado: en revisión, aprobada, rechazada
- Editor de plantillas con variables dinámicas y contador (máximo 3)
- Configuración de automatizaciones por evento del sistema
- Vista de creación de campaña con selector de segmento de clientes
- Log de mensajes enviados con filtros por fecha, plantilla y cliente
- Cards de métricas: enviados, entregados, leídos, respondidos
- Gráfico de rendimiento por campaña

### Reglas de negocio que deben estar implementadas
- Solo se usan plantillas aprobadas por Meta
- Opt-in del cliente es obligatorio antes de cualquier envío
- Máximo 3 variables dinámicas por plantilla
- Campañas siempre en background, nunca bloquean la API
- Webhook sin firma HMAC válida se rechaza

---

## MÓDULO 8 – Dashboard y Reportes en Tiempo Real

### Qué debe hacer el backend
- Pre-calcular KPIs cada 10 minutos mediante tarea programada
- Servir KPIs desde snapshots pre-calculados (no desde queries pesadas en tiempo real)
- Emitir actualizaciones vía WebSocket al actualizar snapshots
- Aplicar filtros de acceso por rol en todos los endpoints de KPIs
- Generar archivos Excel con openpyxl y PDF con branding al exportar
- Guardar archivo exportado en storage temporal con URL de descarga con expiración
- Registrar cada exportación con usuario, filtros y fecha
- Ejecutar reportes programados y enviarlos por correo a la hora configurada

### Qué debe hacer el frontend
- Dashboard con widgets configurables por rol (cards KPI, gráficos, tablas)
- Indicadores semaforizados con umbrales configurables
- Comparativo vs. periodo anterior en cada KPI principal
- Filtros sin recargar la página: sucursal, vendedor, categoría, canal, fecha
- Guardado de filtros favoritos por usuario
- Botón de exportar en cada reporte con selector de formato (Excel/PDF)
- Configuración de reportes programados con selector de frecuencia y destinatarios
- Actualización automática de widgets cada 10 minutos (ajustable)

### Reglas de negocio que deben estar implementadas
- Supervisor de almacén solo ve KPIs de inventario
- Gerente de ventas solo ve KPIs de ventas
- Contador solo ve KPIs financieros
- Admin ve todo
- Todo reporte exportado queda registrado con quién lo generó y con qué filtros
- URL de descarga de exportaciones expira después del tiempo configurado

---

## MÓDULO 9 – Gestión de Usuarios y Roles

### Qué debe hacer el backend
- Autenticar con email + contraseña (bcrypt)
- Emitir JWT con: usuario_id, rol, sucursales_permitidas, expiración
- Soporte de 2FA con TOTP (Google Authenticator)
- Soporte de SSO con Google y Microsoft
- Invalidar tokens al hacer logout (blacklist en Redis)
- Invalidar todos los tokens de un usuario al desactivarlo
- Aplicar rate limiting en el endpoint de login
- Verificar permisos específicos en cada endpoint antes de ejecutar
- Registrar en audit log toda operación crítica: usuario, IP, módulo, dato antes/después
- Los logs de auditoría no pueden ser eliminados ni modificados

### Qué debe hacer el frontend
- Pantalla de login con soporte de 2FA y botones de SSO
- Forzar cambio de contraseña si expiró
- Tabla de usuarios con búsqueda y filtros
- Formulario de creación/edición de usuario con selector de rol y sucursal
- Matriz de permisos: filas = módulos, columnas = acciones con checkboxes
- Activación/desactivación de 2FA por usuario desde su ficha
- Vista de audit log con filtros por usuario, módulo, acción y fecha
- Exportación del log de auditoría

### Reglas de negocio que deben estar implementadas
- Usuario desactivado: todos sus tokens activos quedan inválidos inmediatamente
- Sin 2FA verificado no se emite el JWT completo
- Máximo 5 intentos de login fallidos antes de bloqueo temporal por IP
- Todo acceso a un endpoint sin permiso retorna 403 (nunca 404)

---

## Tabla resumen de validación

| Módulo | Backend listo cuando... | Frontend listo cuando... |
|---|---|---|
| Ventas / POS | Venta se registra, stock se descuenta y comprobante se dispara en una sola transacción atómica | POS funciona offline, se sincroniza al reconectar y el cajero puede completar una venta sin errores |
| Inventario | Salida sin stock retorna error, transferencia no cierra hasta confirmación del destino | El semáforo de stock se actualiza en tiempo real y las alertas aparecen en el dashboard |
| Facturación | Envío a Nubefact funciona, CDR se guarda y los rechazados se pueden corregir y reenviar | El contador puede ver el estado del comprobante en tiempo real y descargar PDF, XML y CDR |
| Distribución | El endpoint público de seguimiento responde sin JWT y el GPS se actualiza por WebSocket | El conductor puede escanear QR, navegar y confirmar entrega con evidencia desde su móvil |
| Compras | Factura de proveedor no se puede pagar sin conciliación previa | El almacenero puede registrar una recepción con incidencias y foto desde su dispositivo |
| Financiero | Asiento sin cuadrar hace rollback y periodo cerrado bloquea modificaciones | El contador puede cargar extracto bancario, confirmar conciliaciones y cerrar el periodo |
| WhatsApp | Solo se usan plantillas aprobadas y los webhooks de Meta se procesan correctamente | El administrador puede ver logs de mensajes y métricas de campaña en tiempo real |
| Dashboard | Los KPIs se sirven desde snapshots pre-calculados y los filtros de rol funcionan | Los widgets se actualizan automáticamente y el usuario puede exportar con los filtros aplicados |
| Usuarios | JWT inválido retorna 401 y endpoint sin permiso retorna 403 en todos los casos | El admin puede crear usuarios, configurar permisos por módulo y ver el audit log |

---

*Sin multi-tenancy. Sin eCommerce. Una instalación = una empresa.*
*Basado en el PDF de Jsoluciones.*