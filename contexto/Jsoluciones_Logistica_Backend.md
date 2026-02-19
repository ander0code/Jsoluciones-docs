# JSOLUCIONES ERP – Lógica de Backend por Módulo

> Documento de referencia extraído del PDF del proyecto. Detalla toda la lógica de negocio, validaciones, endpoints, modelos de datos, reglas y criterios de validación para confirmar que el backend está en buen camino. Stack base: **Python/Django 4.x + Django REST Framework + PostgreSQL + Celery + Redis + Django Channels**.

---

## Stack Técnico Backend

| Capa | Tecnología |
|---|---|
| Framework principal | Django 4.x + Django REST Framework |
| Base de datos | PostgreSQL (single-tenant, una instancia por empresa) |
| Tareas asíncronas | Celery + Redis |
| Tiempo real (WebSocket) | Django Channels + ASGI + Redis |
| Autenticación | JWT (djangorestframework-simplejwt) + 2FA + OAuth2 |
| Firma XML | lxml + signxml (UBL 2.1 para SUNAT) |
| Mensajería WhatsApp | HTTP POST a Meta Cloud API |
| Envío de emails | SMTP / SendGrid |
| Almacenamiento archivos | S3 / Azure Blob (XML, CDR, PDF, fotos) |

---

## Arquitectura General

- **Single-tenant:** Una instancia de la aplicación por empresa. La configuración de la empresa se almacena en la tabla singleton `configuracion`. No se usa `empresa_id` en las tablas.
- **RBAC:** Cada endpoint valida permisos por rol antes de ejecutar lógica.
- **Módulos desacoplados:** Comunicación entre módulos via eventos/colas (Celery tasks) o señales Django, no llamadas directas síncronas.
- **Auditoría transversal:** Toda operación crítica registra `usuario_id`, `timestamp`, `ip`, `acción` en una tabla `audit_logs`.

---

## MÓDULO 1 – Gestión de Ventas

### Modelos de datos necesarios
```
clientes (id, tipo_doc, numero_doc, razon_social, email, telefono, categoria, limite_credito, tags)
productos (id, sku, nombre, precio, stock_actual, permite_venta_sin_stock, unidad_medida, categoria_id)
ventas (id, cliente_id, usuario_id, sucursal_id, caja_id, fecha, total, estado, modo_emision, metodo_pago_id)
detalle_venta (id, venta_id, producto_id, cantidad, precio_unitario, descuento, subtotal, igv, total)
cotizaciones (id, cliente_id, vendedor_id, fecha_emision, fecha_vencimiento, estado, total)
detalle_cotizacion (id, cotizacion_id, producto_id, cantidad, precio, descuento)
ordenes_venta (id, cotizacion_id, cliente_id, estado, fecha_confirmacion, total)
formas_pago (id, venta_id, metodo, monto, referencia, confirmado)
cajas (id, sucursal_id, usuario_id, estado, monto_apertura, monto_cierre, fecha_apertura, fecha_cierre)
ventas_offline (id, payload_json, sincronizado, fecha_registro_local, fecha_sync, error_sync)
```

### Endpoints REST necesarios
```
POST   /api/ventas/               → Registrar venta (POS o eCommerce)
GET    /api/ventas/               → Listar ventas con filtros
GET    /api/ventas/{id}/          → Detalle de venta
POST   /api/ventas/offline-sync/  → Sincronizar ventas offline
POST   /api/cotizaciones/         → Crear cotización
PUT    /api/cotizaciones/{id}/    → Editar cotización (solo si estado != vencida)
POST   /api/cotizaciones/{id}/duplicar/  → Duplicar cotización vencida
POST   /api/cotizaciones/{id}/convertir/ → Convertir a orden de venta
GET    /api/clientes/             → Buscar/listar clientes
POST   /api/clientes/             → Crear cliente
PUT    /api/clientes/{id}/        → Actualizar cliente
POST   /api/cajas/abrir/          → Abrir caja con monto inicial
POST   /api/cajas/cerrar/         → Cerrar caja con arqueo
GET    /api/reportes/ventas-diarias/
GET    /api/reportes/ventas-por-producto/
GET    /api/reportes/ventas-por-cliente/
```

### Lógica de negocio crítica

**Registro de venta:**
1. Validar que el usuario tiene rol permitido (cajero, vendedor, admin)
2. Validar que la caja esté abierta
3. Por cada producto en el detalle:
   - Verificar `stock_actual >= cantidad` (si `permite_venta_sin_stock = False` → error 400)
   - Si permite venta sin stock: registrar pero marcar para alerta
4. Calcular `subtotal`, `igv` (18%), `total` por línea y total general
5. Crear registro `ventas` + `detalle_venta` + `formas_pago` en una transacción atómica
6. Descontar stock en módulo de inventario via señal Django o Celery task
7. Disparar tarea Celery: generar comprobante electrónico (módulo facturación)
8. Disparar tarea Celery: enviar notificación WhatsApp/email si configurado
9. Registrar en `audit_logs`

**Cotizaciones:**
- Estado `vencida`: sistema actualiza automáticamente via Celery beat (cron) comparando `fecha_vencimiento` vs `now()`
- Cotización vencida: endpoint `PUT` debe retornar 403 con mensaje "Use duplicar"
- Endpoint `duplicar`: copia todos los detalles, asigna nueva `fecha_emision` y `fecha_vencimiento`, estado = `pendiente`

**Ventas offline:**
- El frontend envía un batch de ventas en JSON al endpoint `/offline-sync/`
- Backend procesa cada una en orden cronológico
- Si hay conflicto de stock: marcar como `error_sync` con descripción
- Las que sí pasan: procesar normalmente y marcar `sincronizado = True`

### ✅ Cómo validar que el backend va bien
- [ ] `POST /api/ventas/` con producto sin stock retorna 400 si `permite_venta_sin_stock = False`
- [ ] La venta se crea y el stock se descuenta en la misma transacción (rollback si falla alguno)
- [ ] No se puede editar una cotización con estado `vencida` (retorna 403)
- [ ] El cron de vencimiento de cotizaciones corre cada noche y actualiza estados
- [ ] `/offline-sync/` procesa correctamente un batch de 10 ventas y reporta cuáles fallaron
- [ ] Todos los endpoints requieren JWT válido (retorna 401 sin token)
- [ ] Todos los datos pertenecen a la empresa configurada en `configuracion`

---

## MÓDULO 2 – Inventario y Logística

### Modelos de datos necesarios
```
almacenes (id, nombre, tipo, sucursal_id, activo)
ubicaciones_almacen (id, almacen_id, zona, estanteria, seccion)
productos_almacen (id, producto_id, almacen_id, stock_actual, stock_minimo, stock_maximo, stock_seguridad)
movimientos_stock (id, producto_id, almacen_origen_id, almacen_destino_id, tipo_movimiento, cantidad, motivo, usuario_id, lote_id, referencia_doc, created_at)
lotes_series (id, producto_id, almacen_id, numero_lote, numero_serie, fecha_vencimiento, cantidad_inicial, cantidad_actual, estado)
transferencias (id, almacen_origen_id, almacen_destino_id, estado, usuario_origen_id, usuario_destino_id, fecha_solicitud, fecha_confirmacion)
detalle_transferencia (id, transferencia_id, producto_id, lote_id, cantidad_enviada, cantidad_recibida)
```

**Índices críticos en `movimientos_stock`:**
- Índice compuesto: `(producto_id, created_at)`
- Índice compuesto: `(almacen_id, tipo_movimiento)`
- Particionado horizontal por mes si supera 5M registros

### Endpoints REST necesarios
```
GET    /api/almacenes/                        → Listar almacenes
POST   /api/almacenes/                        → Crear almacén
GET    /api/inventario/stock/                 → Stock actual por almacén/producto
POST   /api/inventario/entrada/               → Registrar entrada de mercadería
POST   /api/inventario/salida/                → Registrar salida
POST   /api/inventario/transferencia/         → Crear transferencia entre almacenes
POST   /api/inventario/transferencia/{id}/confirmar/ → Confirmar recepción en destino
POST   /api/inventario/ajuste/                → Ajuste manual de stock (con motivo)
GET    /api/inventario/movimientos/           → Historial con filtros
GET    /api/inventario/trazabilidad/{lote}/   → Historial completo de un lote/serie
GET    /api/inventario/alertas-stock/         → Productos bajo stock mínimo
```

### Lógica de negocio crítica

**Movimiento de stock:**
1. Verificar que el usuario tiene permiso sobre ese almacén
2. Para salidas: `stock_actual >= cantidad` → si no, error 400 (salvo autorización especial con flag)
3. Actualizar `productos_almacen.stock_actual` en transacción atómica con el movimiento
4. Si producto tiene trazabilidad activada: validar que se informe `numero_lote` o `numero_serie`
5. Registrar `movimientos_stock` con todos los campos (no se puede modificar, solo consultar)
6. Si `stock_actual <= stock_minimo`: disparar Celery task para enviar alerta (email/notificación interna)

**Transferencias:**
- Estado inicial: `SOLICITADA`
- Al confirmar recepción: comparar `cantidad_enviada` vs `cantidad_recibida`
  - Si difieren: registrar incidencia, no cerrar hasta resolución
  - Si coinciden: actualizar stock en almacén destino, descontar en origen, estado = `CONFIRMADA`
- No se puede transferir si el stock en origen es insuficiente

**Ajuste manual de stock:**
- Requiere campo `motivo` obligatorio
- Solo roles: admin, supervisor de almacén
- Registra en `movimientos_stock` con `tipo_movimiento = 'AJUSTE'`
- Registra en `audit_logs` con referencia al ajuste

**Tarea Celery periódica:**
- Revisar lotes con `fecha_vencimiento <= now() + 7 días` → generar alertas
- Revisar productos con `stock_actual <= stock_minimo` → generar alertas

### ✅ Cómo validar que el backend va bien
- [ ] Salida de 10 unidades con stock de 5 retorna 400
- [ ] Entrada de mercadería incrementa `productos_almacen.stock_actual` correctamente
- [ ] Una transferencia no cierra hasta que el destino confirma recepción
- [ ] El ajuste manual sin `motivo` retorna 400
- [ ] Tarea Celery de alertas corre diariamente y genera registros en tabla de notificaciones
- [ ] Consulta de historial de movimientos con filtro por fecha tarda < 300ms con 1M+ registros (verificar con `EXPLAIN ANALYZE` en PostgreSQL)
- [ ] Usuario sin permiso sobre almacén retorna 403

---

## MÓDULO 3 – Facturación Electrónica

### Modelos de datos necesarios
```
comprobantes (id, tipo, serie, numero, fecha_emision, hora_emision, cliente_id, moneda, total_gravada, total_igv, total_venta, estado_sunat, hash, qr, xml_path, cdr_path, modo_emision, firma_digital, created_at)
detalle_comprobante (id, comprobante_id, codigo_producto, descripcion, cantidad, unidad_medida, precio_unitario, subtotal, igv, total, afectacion_igv)
notas_credito_debito (id, comprobante_origen_id, tipo_nota, serie, numero, fecha_emision, motivo_codigo, motivo_descripcion, estado_sunat, xml_path, cdr_path)
envios_sunat (id, comprobante_id, fecha_envio, respuesta_sunat, codigo_respuesta, mensaje_respuesta, cdr_xml, estado, intentos)
resumen_diario (id, fecha, cantidad_documentos, estado_envio, codigo_ticket, cdr_path, created_at)
```

### Endpoints REST necesarios
```
POST   /api/facturacion/emitir/              → Generar y enviar comprobante a SUNAT
GET    /api/facturacion/comprobantes/         → Listar con filtros (estado, fecha, tipo, cliente)
GET    /api/facturacion/comprobantes/{id}/pdf/ → Descargar PDF
GET    /api/facturacion/comprobantes/{id}/xml/ → Descargar XML firmado
GET    /api/facturacion/comprobantes/{id}/cdr/ → Descargar CDR
POST   /api/facturacion/comprobantes/{id}/reenviar/ → Reenvío manual
POST   /api/facturacion/notas/               → Emitir nota de crédito/débito
GET    /api/facturacion/cola-contingencia/   → Ver comprobantes en cola offline
POST   /api/facturacion/resumen-diario/      → Generar y enviar resumen de boletas
```

### Lógica de negocio crítica

**Flujo de emisión estándar:**
1. Recibir datos de venta (desde módulo ventas o llamada directa)
2. Validar RUC/DNI del cliente (conexión a padrón SUNAT o validación de formato)
3. Validar campos: montos con 2 decimales, sumatoria correcta, fechas no futuras, códigos UOM válidos
4. Generar número correlativo de serie (ej: F001-00001) → atómico para evitar duplicados (usar `SELECT FOR UPDATE` o secuencia de BD)
5. Construir JSON estructurado de la factura
6. Convertir JSON → XML UBL 2.1 (usando lxml)
7. Firmar XML con certificado digital PFX (usando signxml o equivalente)
8. Enviar XML firmado a SUNAT via API REST (SEE)
9. Recibir CDR (Comprobante de Recepción) → parsear respuesta
10. Si aceptado: guardar XML + CDR en storage, estado = `ACEPTADO`
11. Si rechazado: estado = `RECHAZADO`, registrar en `envios_sunat` con mensaje de error
12. Si sin conexión: modo contingencia → guardar en cola, estado = `PENDIENTE`
13. Generar PDF del comprobante (usando reportlab o weasyprint)
14. Si configurado: enviar PDF por email/WhatsApp al cliente (Celery task)

**Modo contingencia (offline):**
- Comprobante se guarda localmente con estado `CONTINGENCIA`
- Tarea Celery periódica intenta reenvío cada X minutos
- Al restablecer conexión: procesar cola en orden cronológico

**Numeración correlativa:**
- Serie por tipo: F001 (facturas), B001 (boletas)
- Debe ser única por `(tipo, serie, numero)`
- Usar secuencia de PostgreSQL o `SELECT MAX(numero) + 1 FOR UPDATE` en transacción

**Resumen diario de boletas:**
- Celery beat ejecuta tarea cada día a las 23:50
- Agrupa todas las boletas del día con estado `ACEPTADO`
- Genera archivo de resumen y envía a SUNAT
- Guarda código de ticket de respuesta

### ✅ Cómo validar que el backend va bien
- [ ] Emitir factura con RUC válido → recibir CDR de SUNAT con código 0 (aceptado)
- [ ] Emitir con RUC inválido → SUNAT retorna error, estado = `RECHAZADO`, se registra en `envios_sunat`
- [ ] No se pueden crear dos comprobantes con la misma serie+número (constraint único en BD)
- [ ] Modo contingencia: simular caída de SUNAT → comprobante queda en cola → al "reconectar" se envía automáticamente
- [ ] El XML generado pasa validación con el validador de SUNAT (Anexo 8, UBL 2.1)
- [ ] El PDF se genera correctamente y tiene QR válido
- [ ] El resumen diario de boletas se envía automáticamente sin intervención manual

---

## MÓDULO 4 – Distribución y Seguimiento de Pedidos

### Modelos de datos necesarios
```
pedidos (id, cliente_id, origen, estado, prioridad, direccion_entrega, latitud, longitud, tipo_entrega, hora_estimada_despacho, notas, created_at)
detalle_pedido (id, pedido_id, producto_id, cantidad, precio, subtotal)
transportistas (id, nombre, vehiculo, capacidad_max_peso, capacidad_max_volumen, limite_pedidos_dia, activo)
rutas (id, transportista_id, fecha, estado)
asignaciones_pedido (id, ruta_id, pedido_id, orden_entrega, estado, evidencia_foto_url, firma_digital, otp_codigo, otp_verificado)
eventos_pedido (id, pedido_id, estado_nuevo, descripcion, latitud_evento, longitud_evento, usuario_id, created_at)
tracking_transportista (id, transportista_id, latitud, longitud, timestamp)
```

### Endpoints REST necesarios
```
POST   /api/pedidos/                          → Crear pedido
GET    /api/pedidos/                          → Listar pedidos con filtros
GET    /api/pedidos/{id}/                     → Detalle de pedido
PUT    /api/pedidos/{id}/estado/              → Actualizar estado
GET    /api/pedidos/seguimiento/{codigo}/     → Endpoint PÚBLICO de seguimiento (sin auth)
POST   /api/rutas/                            → Crear ruta/planificación
POST   /api/rutas/{id}/asignar/              → Asignar pedidos a transportista
POST   /api/rutas/{id}/optimizar/            → Optimizar ruta (algoritmo TSP)
POST   /api/entregas/{id}/confirmar/          → Confirmar entrega (foto/firma/OTP)
POST   /api/tracking/actualizar/             → Actualizar posición GPS del transportista
GET    /api/transportistas/{id}/ubicacion/   → Ubicación actual del transportista
```

### Lógica de negocio crítica

**Creación de pedido:**
1. Validar stock disponible en almacén de despacho → si no hay: error 400
2. Reservar stock (campo `stock_reservado` en `productos_almacen`) sin descontarlo aún
3. Estado inicial: `PENDIENTE`
4. Geocodificar dirección de entrega si no vienen coordenadas (Google Maps Geocoding API)
5. Registrar evento en `eventos_pedido`

**Planificación y optimización de rutas:**
1. Recibir lista de pedidos a despachar en el día
2. Agrupar por zona geográfica
3. Ejecutar algoritmo de optimización (TSP simplificado o llamada a Google Routes / HERE API)
4. Validar que la suma de pedidos asignados al transportista no supere `capacidad_max_peso`, `capacidad_max_volumen` y `limite_pedidos_dia`
5. Generar hoja de ruta con QR único por pedido
6. Estado pedido: `PLANIFICADO`

**Tracking en tiempo real:**
- Transportista envía coordenadas GPS cada 30s via endpoint `/api/tracking/actualizar/`
- Se guarda en `tracking_transportista` y se emite via WebSocket (Django Channels) a todos los clientes suscritos al canal del pedido
- El endpoint público `/seguimiento/{codigo}/` consulta el último estado + eventos + última coordenada del transportista asignado

**Confirmación de entrega:**
1. Transportista sube foto O firma digital O ingresa OTP enviado al cliente
2. Validar al menos una evidencia presente → si no: error 400
3. Actualizar estado pedido a `ENTREGADO`
4. Registrar evento con coordenadas y timestamp
5. Descontar stock definitivamente (ya no reservado)
6. Disparar Celery task: notificación WhatsApp/email al cliente
7. Disparar Celery task: disparar generación de comprobante si no fue emitido aún

**Regla de despacho:**
- No se puede mover pedido a estado `EN_RUTA` si `stock_reservado < cantidad_pedido`

### ✅ Cómo validar que el backend va bien
- [ ] Crear pedido sin stock disponible retorna 400
- [ ] El stock se reserva al crear el pedido y no se descuenta hasta confirmación de entrega
- [ ] El endpoint público `/seguimiento/{codigo}/` responde sin JWT y retorna estado actual + coordenada
- [ ] Actualizar posición GPS emite mensaje via WebSocket (verificar con cliente WS)
- [ ] Confirmar entrega sin evidencia (ni foto, ni firma, ni OTP) retorna 400
- [ ] Asignar más pedidos de lo que permite la capacidad del transportista retorna 400
- [ ] Al confirmar entrega el stock se descuenta definitivamente

---

## MÓDULO 5 – Compras y Proveedores

### Modelos de datos necesarios
```
proveedores (id, ruc, razon_social, direccion, contacto, email, condiciones_pago, limite_credito, activo, ultima_evaluacion)
ordenes_compra (id, proveedor_id, usuario_creador_id, usuario_aprobador_id, estado, fecha_creacion, fecha_estimada_entrega, almacen_destino_id, moneda, total, notas)
detalle_orden_compra (id, orden_id, producto_id, cantidad, precio_unitario, subtotal)
facturas_proveedor (id, proveedor_id, orden_id, numero_factura, fecha_emision, fecha_vencimiento, monto_base, igv, total, estado_sunat, estado_pago, contabilizado)
recepciones (id, orden_id, usuario_id, fecha, estado)
detalle_recepcion (id, recepcion_id, producto_id, lote_id, cantidad_esperada, cantidad_recibida, estado_item, observacion, foto_url)
incidencias_compra (id, recepcion_id, producto_id, tipo_incidencia, descripcion, cantidad_afectada, evidencia_url, notificado_proveedor)
evaluaciones_proveedor (id, proveedor_id, periodo, puntualidad_score, calidad_score, precio_score, total_entregas, entregas_completas, created_at)
```

### Endpoints REST necesarios
```
POST   /api/compras/ordenes/                  → Crear OC
PUT    /api/compras/ordenes/{id}/aprobar/     → Aprobar OC (requiere permiso)
GET    /api/compras/ordenes/                  → Listar OC con filtros
POST   /api/compras/recepciones/              → Registrar recepción (parcial o total)
POST   /api/compras/recepciones/{id}/cerrar/  → Cerrar OC completamente
GET    /api/proveedores/                      → Listar proveedores
POST   /api/proveedores/                      → Crear proveedor
GET    /api/proveedores/{id}/comparar/{producto_id}/ → Comparar proveedores por producto
POST   /api/compras/facturas/                 → Registrar factura de proveedor
POST   /api/compras/facturas/{id}/validar-sunat/ → Validar factura vs. SUNAT
POST   /api/compras/facturas/{id}/conciliar/  → Conciliar con recepción
```

### Lógica de negocio crítica

**Generación automática de OC:**
- Celery beat revisa diariamente `productos_almacen` donde `stock_actual <= stock_minimo`
- Para cada producto: busca proveedor habitual o sugiere el de mejor precio/tiempo de entrega
- Crea OC en estado `BORRADOR` o `PENDIENTE_APROBACION` según configuración
- Notifica al supervisor responsable

**Flujo de aprobación:**
- Si total OC > monto configurado: requiere aprobación de usuario con rol financiero/admin
- Endpoint `aprobar` valida que el aprobador tenga permiso y registra en `audit_logs`

**Registro de factura de proveedor:**
1. Validar que no exista ya una factura con mismo `(numero_factura, ruc_proveedor)` → constraint único
2. Validar que esté vinculada a una OC aprobada
3. Verificar validez en SUNAT (API de consulta de comprobantes)
4. Calcular fecha de vencimiento según condiciones del proveedor
5. Prorratear gastos logísticos si aplica

**Conciliación con inventario:**
1. Comparar líneas de factura vs. lo efectivamente recibido en recepciones
2. Si coinciden en cantidad y precio: estado = `CONCILIADA`, habilitar para pago
3. Si hay diferencias: estado = `EN_REVISION`, no se puede pagar
4. Regla dura: `factura.estado_pago` solo puede cambiar a `PAGADA` si `estado = CONCILIADA`

**Evaluación periódica de proveedores:**
- Celery beat trimestral calcula KPIs: puntualidad (% entregas a tiempo), calidad (% sin incidencias), precio (comparativo)
- Guarda en `evaluaciones_proveedor`
- Genera tarea/recordatorio para revisar condiciones comerciales

### ✅ Cómo validar que el backend va bien
- [ ] No se puede registrar dos facturas con mismo número+RUC (constraint único)
- [ ] No se puede pagar una factura no conciliada (campo `estado = CONCILIADA` es prerequisito)
- [ ] OC generada automáticamente por bajo stock aparece en estado `BORRADOR` o `PENDIENTE_APROBACION`
- [ ] Factura con monto diferente a la OC no se puede conciliar sin justificación
- [ ] El cron trimestral de evaluación de proveedores genera registros en `evaluaciones_proveedor`
- [ ] Aprobar una OC con usuario sin permiso retorna 403

---

## MÓDULO 6 – Gestión Financiera y Tributaria

### Modelos de datos necesarios
```
cuentas_por_cobrar (id, cliente_id, comprobante_id, monto_total, monto_pagado, saldo, fecha_vencimiento, estado, moneda)
cuentas_por_pagar (id, proveedor_id, factura_proveedor_id, monto_total, monto_pagado, saldo, fecha_vencimiento, estado)
pagos_cobros (id, tipo, cuenta_cobrar_id, cuenta_pagar_id, monto, metodo_pago, moneda, tipo_cambio, referencia, usuario_id, fecha, created_at)
movimientos_bancarios (id, banco_id, cuenta_id, fecha, descripcion, monto, tipo, referencia, conciliado, documento_id)
asientos_contables (id, fecha, descripcion, centro_costo_id, referencia_doc, usuario_id, estado)
lineas_asiento (id, asiento_id, cuenta_contable_id, debe, haber, descripcion)
cuentas_contables (id, codigo_puc, nombre, tipo, activo)
centros_costo (id, nombre, activo)
periodos_tributarios (id, mes, anio, estado, firmado_por, fecha_cierre)
```

### Endpoints REST necesarios
```
GET    /api/finanzas/cuentas-cobrar/          → Listar con filtros (estado, vencidas, cliente)
POST   /api/finanzas/cobros/                  → Registrar cobro (total o parcial)
GET    /api/finanzas/cuentas-pagar/           → Listar cuentas por pagar
POST   /api/finanzas/pagos/                   → Registrar pago a proveedor
POST   /api/finanzas/conciliacion/cargar/     → Cargar extracto bancario CSV/Excel
GET    /api/finanzas/conciliacion/sugerencias/ → Obtener sugerencias de coincidencia
POST   /api/finanzas/conciliacion/confirmar/{id}/ → Confirmar conciliación
GET    /api/finanzas/libros/diario/           → Libro diario filtrado por periodo
GET    /api/finanzas/libros/mayor/            → Libro mayor por cuenta
GET    /api/finanzas/reportes/balance-general/
GET    /api/finanzas/reportes/estado-resultados/
POST   /api/finanzas/tributario/generar-ple/  → Generar archivos PLE del mes
POST   /api/finanzas/tributario/cerrar-periodo/ → Cerrar periodo tributario (requiere firma)
```

### Lógica de negocio crítica

**Generación automática de CxC:**
- Al crear una venta al crédito → señal Django dispara creación de `cuentas_por_cobrar` con:
  - `monto_total` = total de la venta
  - `fecha_vencimiento` = fecha_venta + días_credito (configurado por cliente)
  - `estado` = `PENDIENTE`

**Asientos contables automáticos:**
- Toda operación financiera (venta, compra, cobro, pago) genera asiento automáticamente via señal
- Regla de doble partida: `SUM(debe) == SUM(haber)` → si no se cumple: rollback de la operación
- No se puede crear asiento con `centro_costo_id = NULL`
- No se puede usar cuenta contable con `activo = False`

**Diferencia de cambio:**
- Si pago/cobro en moneda distinta a la factura: calcular diferencia automáticamente con tipo de cambio del día
- Generar asiento de diferencia de cambio (cuenta contable específica)

**Conciliación bancaria (motor de matching):**
1. Al cargar extracto CSV: parsear movimientos y guardar en `movimientos_bancarios` como no conciliados
2. Para cada movimiento bancario: buscar en `pagos_cobros` donde:
   - `|monto_banco - monto_sistema| < tolerancia_configurada` (ej: S/0.10)
   - `|fecha_banco - fecha_sistema| <= X días` (configurable)
   - Referencia/descripción similar (fuzzy match opcional)
3. Si se encuentra coincidencia: sugerir con score de confianza
4. Usuario confirma → ambos registros quedan `conciliado = True`

**Cierre tributario:**
- Endpoint `cerrar-periodo` valida:
  - Todos los comprobantes del mes tienen CDR aceptado
  - No hay asientos sin cuadrar
  - El usuario tiene firma digital configurada
- Una vez cerrado: `periodos_tributarios.estado = CERRADO` → no se puede modificar nada de ese mes

**Generación de PLE:**
- Leer todos los comprobantes y asientos del periodo
- Formatear según especificación SUNAT (TXT con separadores "|")
- Generar archivos: LE010100 (Libro de Compras), LE080100 (Libro de Ventas), etc.
- Comprimir en ZIP y guardar en storage

### ✅ Cómo validar que el backend va bien
- [ ] Crear venta al crédito → automáticamente aparece registro en `cuentas_por_cobrar`
- [ ] Asiento contable donde `SUM(debe) != SUM(haber)` retorna 400
- [ ] Asiento sin centro de costo retorna 400
- [ ] Usar cuenta contable inactiva retorna 400
- [ ] Cerrar periodo sin firma digital retorna 403
- [ ] Periodo cerrado: intentar modificar un comprobante de ese mes retorna 400
- [ ] El motor de conciliación sugiere coincidencia correcta para 80%+ de los movimientos (test con dataset de prueba)
- [ ] Los archivos PLE generados pasan la validación del PLE Contable de SUNAT

---

## MÓDULO 7 – Comunicación con Clientes (WhatsApp API)

### Modelos de datos necesarios
```
wa_cuentas (id, phone_number_id, business_account_id, token, estado, nombre_display)
wa_plantillas (id, wa_cuenta_id, nombre, categoria, texto, variables_count, estado_meta, meta_template_id)
wa_mensajes (id, wa_cuenta_id, plantilla_id, cliente_id, numero_destino, parametros_json, meta_message_id, estado, fecha_envio, fecha_entrega, fecha_lectura, error_codigo, error_mensaje)
wa_campañas (id, nombre, plantilla_id, segmento_clientes, estado, fecha_programada, total_destinatarios, enviados, entregados, leidos)
wa_logs_webhook (id, payload_raw, tipo_evento, procesado, created_at)
```

### Endpoints REST necesarios
```
POST   /api/whatsapp/cuentas/                 → Configurar cuenta WhatsApp
POST   /api/whatsapp/plantillas/              → Crear plantilla y enviar a Meta para aprobación
GET    /api/whatsapp/plantillas/              → Listar plantillas con estado
POST   /api/whatsapp/mensajes/enviar/         → Enviar mensaje individual
POST   /api/whatsapp/campañas/               → Crear campaña masiva
POST   /api/whatsapp/campañas/{id}/ejecutar/ → Ejecutar campaña
GET    /api/whatsapp/mensajes/               → Log de mensajes con filtros
POST   /api/whatsapp/webhook/                → Recibir eventos de Meta (PÚBLICO, sin auth)
GET    /api/whatsapp/metricas/               → Estadísticas de entregabilidad
```

### Lógica de negocio crítica

**Envío de mensaje:**
1. Verificar que la plantilla tiene `estado_meta = APROBADA`
2. Verificar que el cliente tiene `opt_in = True` (consentimiento)
3. Construir payload JSON con variables dinámicas resueltas
4. Enviar HTTP POST a `https://graph.facebook.com/v17.0/{phone_number_id}/messages` con Bearer token
5. Registrar en `wa_mensajes` con `meta_message_id` de la respuesta
6. Si error 429 (rate limit): encolar en Celery con delay exponencial
7. Si error 400: registrar error, no reintentar automáticamente

**Webhook de Meta (actualizaciones de estado):**
- Endpoint público recibe eventos: `sent`, `delivered`, `read`, `failed`
- Validar firma HMAC del webhook (campo `X-Hub-Signature-256`)
- Actualizar estado en `wa_mensajes` según `meta_message_id`
- Guardar payload raw en `wa_logs_webhook` para auditoría

**Campañas masivas:**
- Ejecutar via Celery task en background (nunca síncrono)
- Respetar límite de mensajes por minuto/hora según Tier de la cuenta (Tier 1: 1000/día, Tier 2: 10000/día, etc.)
- Rate limiting en Celery: procesar N mensajes por minuto con delay entre lotes
- Actualizar métricas de campaña en tiempo real

**Regla de ventana 24h:**
- Para mensajes de texto libre (no plantilla): verificar que el cliente envió un mensaje en las últimas 24h
- Si `ultima_interaccion_cliente > 24h`: solo permitir envío con plantilla aprobada

### ✅ Cómo validar que el backend va bien
- [ ] Enviar mensaje con plantilla no aprobada retorna 400
- [ ] El webhook de Meta actualiza correctamente el estado de `wa_mensajes` (probar con Meta Webhooks Tester)
- [ ] La firma HMAC del webhook se valida correctamente (envío con firma incorrecta retorna 403)
- [ ] Campaña de 1000 mensajes se ejecuta en background sin bloquear la API
- [ ] Rate limiting activo: no excede el límite del Tier configurado
- [ ] Mensaje a cliente sin opt-in retorna 400

---

## MÓDULO 8 – Dashboard & Reportes en Tiempo Real

### Modelos de datos necesarios
```
snapshots_kpi (id, tipo_kpi, valor, dimensiones_json, fecha, created_at)
configuraciones_dashboard (id, usuario_id, rol, widgets_config_json)
exportaciones_log (id, usuario_id, tipo_reporte, filtros_json, formato, fecha, archivo_url)
programaciones_reporte (id, usuario_id, tipo_reporte, frecuencia, hora_envio, emails_destino, activo)
```

### Endpoints REST necesarios
```
GET    /api/dashboard/kpis/ventas/            → KPIs de ventas en tiempo real
GET    /api/dashboard/kpis/inventario/        → KPIs de stock
GET    /api/dashboard/kpis/financiero/        → KPIs financieros
GET    /api/dashboard/kpis/logistica/         → KPIs de distribución
POST   /api/reportes/exportar/                → Exportar reporte a Excel/PDF
GET    /api/reportes/programaciones/          → Ver reportes programados
POST   /api/reportes/programaciones/          → Crear reporte programado
WS     /ws/dashboard/                         → WebSocket para actualización en tiempo real
```

### Lógica de negocio crítica

**Generación de KPIs en tiempo real:**
- Los endpoints de KPIs consultan principalmente sobre `snapshots_kpi` (vistas materializadas o resúmenes pre-calculados)
- Evitar queries pesadas directas en tablas de transacciones para cada request del dashboard
- Celery beat actualiza `snapshots_kpi` cada 10 minutos con los valores frescos
- Para KPIs críticos (ventas del día en curso): query directa con índices optimizados

**WebSocket del dashboard:**
- Al conectarse un usuario autenticado: suscribirse al canal `dashboard_{rol}`
- Cuando Celery actualiza snapshots: emitir evento al canal via Django Channels
- El cliente recibe el dato actualizado sin recargar la página

**Exportación:**
1. Recibir tipo de reporte + filtros + formato (xlsx/pdf)
2. Ejecutar query con los filtros
3. Generar archivo con openpyxl (Excel) o reportlab/weasyprint (PDF) con branding
4. Guardar en storage temporal (S3/local)
5. Registrar en `exportaciones_log` con usuario, filtros, fecha
6. Retornar URL de descarga firmada (válida por X minutos)

**Reportes programados:**
- Celery beat revisa `programaciones_reporte` a la hora configurada
- Genera el reporte con los filtros guardados
- Envía por email a la lista de destinatarios
- Registra resultado del envío

**Control de acceso a KPIs:**
- Rol `ADMIN`: ve KPIs de todas las sucursales
- Rol `GERENTE_VENTAS`: solo KPIs de ventas de sus sucursales asignadas
- Rol `SUPERVISOR_ALMACEN`: solo KPIs de inventario de sus almacenes
- Filtrado aplicado siempre en backend, nunca confiar en el frontend

### ✅ Cómo validar que el backend va bien
- [ ] El endpoint de KPIs responde en < 200ms (los snapshots están pre-calculados)
- [ ] Celery beat actualiza `snapshots_kpi` cada 10 minutos (verificar timestamps en BD)
- [ ] WebSocket emite actualización cuando se registra una venta nueva (probar con `wscat`)
- [ ] Usuario con rol `SUPERVISOR_ALMACEN` no puede ver KPIs financieros (retorna 403)
- [ ] La exportación a Excel descarga correctamente con filtros aplicados
- [ ] El reporte programado llega por email a la hora configurada
- [ ] La URL de descarga de exportaciones expira después del tiempo configurado

---

## MÓDULO 9 – Gestión de Usuarios y Roles

### Modelos de datos necesarios
```
usuarios (id, nombre, email, password_hash, rol_id, sucursal_id, activo, 2fa_activo, 2fa_secret, ultimo_acceso, created_at)
roles (id, nombre, descripcion)
permisos (id, rol_id, modulo, accion, permitido)
sesiones (id, usuario_id, token_jti, ip, user_agent, activo, created_at, expires_at)
audit_logs (id, usuario_id, modulo, accion, objeto_tipo, objeto_id, datos_anteriores_json, datos_nuevos_json, ip, user_agent, created_at)
```

### Endpoints REST necesarios
```
POST   /api/auth/login/                       → Login con JWT
POST   /api/auth/login/2fa/                   → Verificar código 2FA
POST   /api/auth/refresh/                     → Renovar token
POST   /api/auth/logout/                      → Invalidar token (blacklist)
POST   /api/auth/sso/google/                  → Login via Google OAuth2
GET    /api/usuarios/                         → Listar usuarios (solo admin)
POST   /api/usuarios/                         → Crear usuario
PUT    /api/usuarios/{id}/                    → Editar usuario
POST   /api/usuarios/{id}/activar-2fa/        → Configurar 2FA
GET    /api/roles/                            → Listar roles
POST   /api/roles/                            → Crear rol
PUT    /api/roles/{id}/permisos/              → Actualizar permisos del rol
GET    /api/audit-logs/                       → Ver logs de auditoría (filtros)
```

### Lógica de negocio crítica

**Login con JWT + 2FA:**
1. Validar email + password (bcrypt)
2. Si usuario tiene `2fa_activo = True`:
   - Retornar token temporal de 2FA (no JWT completo aún)
   - Cliente envía código TOTP
   - Validar código contra `2fa_secret` con pyotp
   - Si correcto: emitir JWT completo
3. JWT contiene: `user_id`, `rol`, `sucursales_permitidas`, `exp`
4. Registrar en `sesiones` con JTI del token

**Middleware de autorización (en cada request):**
1. Extraer JWT del header `Authorization: Bearer {token}`
2. Verificar firma y expiración
3. Verificar que JTI no esté en blacklist (tokens invalidados)
4. Verificar permiso específico: `permisos.where(rol=user.rol, modulo=X, accion=Y, permitido=True)`
5. Si no hay permiso: retornar 403

**Auditoría:**
- Decorador o signal Django registra automáticamente en `audit_logs` para operaciones críticas: create/update/delete en cualquier modelo sensible
- Campos: usuario, IP, módulo, objeto afectado, datos antes/después (JSON diff)
- Los logs NO pueden ser eliminados ni modificados (permisos de BD)

**Caducidad forzada de sesión:**
- Al hacer logout: agregar JTI a blacklist en Redis (TTL = tiempo restante del token)
- Si el admin desactiva un usuario: agregar todos sus JTIs activos a blacklist

### ✅ Cómo validar que el backend va bien
- [ ] Login sin 2FA correcto retorna JWT válido
- [ ] Login con 2FA activo: sin código TOTP no se emite JWT completo
- [ ] Token expirado retorna 401
- [ ] Token en blacklist (post-logout) retorna 401
- [ ] Usuario con rol VENDEDOR intentando acceder a endpoint de finanzas retorna 403
- [ ] Toda operación de create/update/delete en modelos críticos genera registro en `audit_logs`
- [ ] Usuario desactivado por admin no puede usar sus tokens existentes (blacklist aplicada)

---

## Consideraciones Transversales de Backend

### Single-tenant
- **Arquitectura:** Una instancia de la aplicación (backend + base de datos) por empresa.
- La configuración de la empresa (RUC, razón social, tokens Nubefact, etc.) se almacena en la tabla singleton `configuracion`.
- No se usa `empresa_id` en las tablas de datos. Todos los datos pertenecen a la única empresa configurada.
- Si en el futuro se necesita multi-tenant, se evaluará como evolución (no es prioridad actual).

### Control de errores y respuestas
```
400 Bad Request       → Validación fallida (incluir detalle de campo y mensaje)
401 Unauthorized      → Token inválido, expirado o ausente
403 Forbidden         → Usuario autenticado pero sin permiso
404 Not Found         → Recurso no existe (retornar 404 genérico para evitar enumeration)
409 Conflict          → Violación de constraint único (duplicado)
422 Unprocessable     → Datos semánticamente incorrectos (ej: fecha fin < fecha inicio)
500 Internal Server   → Error no controlado (siempre loguear en Sentry/similar)
```

### Tareas Celery críticas (resumen)
| Tarea | Frecuencia | Módulo |
|---|---|---|
| Actualizar estado cotizaciones vencidas | Diaria (23:00) | Ventas |
| Alertas de bajo stock | Diaria (08:00) | Inventario |
| Alertas de vencimiento de lotes | Diaria (08:00) | Inventario |
| Reintento de comprobantes pendientes | Cada 15 min | Facturación |
| Resumen diario de boletas SUNAT | Diaria (23:50) | Facturación |
| Generar OC automáticas por bajo stock | Diaria (07:00) | Compras |
| Evaluación trimestral de proveedores | Trimestral | Compras |
| Actualizar snapshots KPI | Cada 10 min | Dashboard |
| Enviar reportes programados | Según config | Dashboard |
| Procesar cola WhatsApp | Continuo (rate limited) | WhatsApp |

### Seguridad mínima obligatoria
- [ ] HTTPS en todos los endpoints
- [ ] CORS configurado solo para dominios permitidos
- [ ] Headers de seguridad: CSP, X-Frame-Options, X-Content-Type-Options
- [ ] Protección CSRF en endpoints que usan cookies
- [ ] Rate limiting en endpoints de login (max 5 intentos/IP/minuto)
- [ ] Sanitización de inputs contra SQL Injection (usar ORM, no raw queries)
- [ ] Validación y sanitización contra XSS en campos de texto libre
- [ ] Encriptación de campos sensibles: contraseñas (bcrypt), tokens API, certificados PFX
- [ ] Secrets en variables de entorno, nunca en código (usar .env + django-environ)

---

*Generado desde: PROYECTO_JSOLUCIONES.pdf – Especificaciones del ERP SaaS multimodular.*