# JSOLUCIONES ERP — MODULOS DEL SISTEMA

> Estado real de los modulos del template base (post-sync con Amatista, Feb 2026).
> Para cada modulo: que esta implementado, que es stub, que falta.

---

## Estado por Modulo

| Modulo | Backend | Frontend | Promedio |
|--------|:-------:|:--------:|:-------:|
| 1. Ventas / POS | ~91% | ~78% | ~85% |
| 2. Inventario | ~91% | ~87% | ~89% |
| 3. Facturacion Electronica | ~87% | ~85% | ~86% |
| 4. Distribucion y Seguimiento | ~88% | ~86% | ~87% |
| 5. Compras y Proveedores | ~94% | ~88% | ~91% |
| 6. Gestion Financiera | ~92% | ~92% | ~92% |
| 7. WhatsApp | ~45% | ~70% | ~57% |
| 8. Dashboard y Reportes | ~96% | ~100% | ~98% |
| 9. Usuarios y Roles | ~96% | ~97% | ~96% |

---

## MODULO 1 — Ventas / POS

### Backend Implementado
- Venta POS con multiples metodos de pago (efectivo, tarjeta, QR, credito, mixto)
- `crear_venta_pos()` con `@transaction.atomic` + `select_for_update` en Stock
- Apertura y cierre de caja con arqueo
- CRUD clientes con validacion RUC/DNI
- Cotizaciones: CRUD, duplicar, convertir a OV
- Ordenes de venta con conversion a venta
- Anulacion de venta con reversion de stock
- Offline-sync: recibe batch de ventas POS
- Emision automatica de comprobante post-venta (via Celery `transaction.on_commit`)
- Validacion limite de credito con descuento de CxC pendientes

### Frontend Implementado
- POS completo: panel productos + carrito
- Busqueda por nombre/SKU + scanner codigo de barras
- Modal apertura/cierre caja con arqueo
- 4 metodos de pago diferenciados, pago mixto, vuelto automatico
- Cotizaciones: wizard 4 pasos, badges estado, duplicar/convertir
- Ordenes de venta
- Banner "Sin conexion" cuando `!isOnline`
- Saldo pendiente CxC en ficha cliente

### Pendiente / Stubs
- Sin Service Worker ni IndexedDB (banner existe pero no hay cola local offline real)
- Notificacion WhatsApp/email al vender
- Vista campo responsive para movil dedicada
- Sincronizacion automatica al reconectar con indicador de progreso

---

## MODULO 2 — Inventario y Logistica

### Backend Implementado
- Stock en tiempo real por producto y almacen
- Entradas, salidas, transferencias, ajustes manuales
- Transferencias: flujo 3 pasos (crear -> aprobar -> confirmar_recepcion)
- Trazabilidad por lote y por serie (modelos Lote y Serie)
- Alertas stock minimo (Celery 07:30)
- Alertas lotes por vencer (Celery 07:00, umbral 7 dias)
- Rotacion ABC: A(80%)/B(15%)/C(5%)
- CRUD Ubicaciones (zona, pasillo, estante, nivel)
- FIFO sugerido: `seleccionar_lotes_fifo()` + `FifoSugerenciaView`

### Frontend Implementado
- Vista stock con semaforo verde/amarillo/rojo + filtros por almacen y categoria
- Formularios entrada, salida (FIFO preseleccionado), transferencia (validacion stock tiempo real), ajuste
- Trazabilidad por lote y por serie
- Dashboard: 7 KPIs + alertas + clasificacion ABC + grafico entradas vs salidas
- CRUD Ubicaciones
- CRUD Series desde UI de producto

### Pendiente / Bugs
- FIFO no es automatico en `registrar_salida()`: es solo consulta sugerida
- Al detectar diferencia en transferencia: se escribe nota en `motivo` pero estado no cambia
- `requiere_lote` y `requiere_serie`: los campos existen pero `registrar_entrada/salida()` no validan que se provea cuando son True

---

## MODULO 3 — Facturacion Electronica

### Backend Implementado
- Integracion real con Nubefact OSE via HTTP POST
- Correlativo atomico con `select_for_update()`
- Facturas (01), boletas (03), notas de credito (07), debito (08)
- XML firmado y CDR guardados en Cloudflare R2
- Log inmutable de cada intento de envio
- Max 5 reintentos, luego `ESTADO_COMP_ERROR_PERMANENTE`
- Contingencia automatica: 3 fallos consecutivos activan modo contingencia
- Reenvio manual individual y masivo
- Prevencion doble-emision: `unique_together` (serie, numero) en BD
- Envio PDF por email al cliente
- Task `reenviar_comprobantes_pendientes` (cada 5 min)
- Task `enviar_resumen_diario_boletas` (23:50)
- Credenciales Nubefact encriptadas con `EncryptedCharField`
- DEMO VERIFICADO: F001-101 ACEPTADA por Nubefact OSE

### Frontend Implementado
- Formulario emision manual con validacion RUC/DNI
- Vista previa antes de confirmar envio
- Badges estado SUNAT en tiempo real via WebSocket
- Lista con filtros por tipo, cliente, estado, fecha
- Detalle con PDF, XML, CDR descargables
- Cola pendientes/rechazados con motivo visible
- Reenvio manual
- Banner ContingenciaBanner (naranja) cuando modo_contingencia=True
- Banner DemoBanner (azul) cuando modo_demo=True
- Resumen diario boletas

### Pendiente
- Validacion RUC contra padron SUNAT: solo validacion sintactica (tipo='6' + 11 digitos)
- Envio PDF/XML por WhatsApp al cliente
- Indicador pipeline visual Generando->Firmando->Enviando->Aceptado (badges existen, no hay step tracker)

---

## MODULO 4 — Distribucion y Seguimiento

### Backend Implementado
- Pedidos: maquina de estados PENDIENTE->CONFIRMADO->DESPACHADO->EN_RUTA->ENTREGADO/CANCELADO
- Asignacion transportista con validacion `limite_pedidos_diario`
- Codigo seguimiento UUID corto (8 chars)
- Endpoint publico sin auth: `GET /publico/seguimiento/{codigo}/`
- Registro evidencias: foto, firma, OTP via MediaArchivo
- Hoja de ruta PDF (reportlab) y QR por pedido
- Consumer WebSocket GPSConsumer: coordenadas en tiempo real
- Optimizacion de ruta: Nearest Neighbor + Haversine

### Frontend Implementado
- Lista pedidos con estados y filtros
- Detalle pedido con timeline de eventos
- Modal asignacion transportista
- Modal evidencia entrega (foto, firma canvas)
- Modal entrega fallida con selector de motivo
- Seguimiento publico (URL sin login)

### Pendiente
- Geocodificacion automatica de direcciones
- Mapa visual con iconos de transportistas (requiere react-leaflet o Google Maps)
- Vista movil dedicada para conductor (QR scanner, lista compacta)
- Integracion API transportistas externos (Olva, Urbano)

---

## MODULO 5 — Compras y Proveedores

### Backend Implementado
- Ordenes de compra: Borrador -> Pendiente -> Aprobada -> Enviada -> Cerrada
- Aprobacion con validacion monto limite
- Facturas proveedor con validacion contra SUNAT (sintactica)
- Recepcion parcial o total con foto de evidencia
- KPIs de proveedores
- Alertas OC vencida sin recibir

### Frontend Implementado
- Lista OC con estados y filtros
- Formulario creacion OC
- Recepcion con accordeon por item + ingreso numeros de serie
- Foto de evidencia en recepcion (dropzone)
- Lista facturas proveedor
- Ficha proveedor con historial

---

## MODULO 6 — Gestion Financiera y Tributaria

### Backend Implementado
- CxC automatica al registrar venta al credito
- CxP automatica al registrar factura proveedor
- Pagos parciales o totales
- Conciliacion bancaria: carga extracto CSV, motor de matching, confirmar/ignorar
- Asientos contables con validacion doble partida
- Libro Diario, Mayor, Caja, Balance General, Estado Resultados
- PLE real: 6 libros TXT SUNAT (LE140100, LE080100, LE050100, LE060100, LE010100, LE030100)
- PDT621 con calculo real debito/credito fiscal
- Cierre de periodo con firma digital (PIN)
- Bloqueo modificaciones en periodos cerrados

### Frontend Implementado
- Lista CxC y CxP con semaforo de vencimiento
- Modal cobro/pago con soporte pago parcial
- Carga extracto bancario + panel conciliacion con botones confirmar/ignorar
- Libro Diario, Mayor, Caja, Balance General, Estado Resultados
- Panel declaraciones PLE/PDT con selector de libro/periodo
- Checklist pre-cierre de periodo
- Firma digital PIN para cierre
- Indicador periodo abierto/cerrado

### Pendiente
- PDT626 y PDT601 (retenciones/planilla): retornan "no_disponible" — requieren datos fuera del alcance actual
- Calculo diferencia de cambio automatico
- Conciliacion bancaria avanzada (mas bancos, mas formatos)

---

## MODULO 7 — Comunicacion WhatsApp

### Backend Implementado
- Modelo WhatsappConfiguracion (singleton)
- CRUD Plantillas
- Mensajes (read-only)
- LogWA
- Webhook endpoint (sin auth, para Meta)
- WhatsappCampana y WhatsappAutomatizacion (modelos en BD)

### Backend STUB (no funcional)
- `POST /whatsapp/enviar/` — STUB, no envia real a Meta
- Validacion firma HMAC del webhook
- Opt-in/opt-out de clientes
- Procesamiento real de webhooks entrantes de Meta

### Frontend Implementado
- Pagina configuracion
- Lista plantillas con badges estado
- Lista mensajes con filtros
- Pagina logs de webhook con auto-refresh
- Metricas: KPIs y tasas
- Campanas: lista + modal nueva campana
- Automatizaciones: lista + estado

### Dependencia para activar WhatsApp
- Credenciales Meta: `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_APP_SECRET`

---

## MODULO 8 — Dashboard y Reportes

### Backend Implementado
- KPIs pre-calculados cada 10 min (Celery Beat)
- Emision via WebSocket `kpi_update` a cada usuario activo
- Filtros de acceso por rol
- KPI comparativo vs periodo anterior
- Configuracion umbrales semaforos (ConfiguracionKPI)
- Exportacion Excel Balance y Estado Resultados
- PLE/PDT (ver Modulo 6)

### Frontend Implementado
- Dashboard con KPIs por rol
- Semaforos con umbrales configurables
- Comparativo vs periodo anterior
- Actualizacion automatica via WebSocket (cada 10 min)
- Modal configuracion de umbrales (solo admin/gerente)
- Exportar Excel en Balance y Estado Resultados

---

## MODULO 9 — Usuarios y Roles

### Backend Implementado
- Auth: email + password (bcrypt)
- JWT: access 60min, refresh 7d, rotacion + blacklist Redis
- 2FA con TOTP (Google Authenticator)
- SSO Google + Microsoft (OAuth2 Authorization Code completo)
- Rate limiting en login (max 5 intentos)
- Audit log: toda operacion critica (usuario, IP, modulo, dato antes/despues)
- Permisos RBAC: 8 roles, 40+ permisos granulares
- management command `seed_permissions`

### Frontend Implementado
- Login con 2FA y SSO
- Tabla usuarios con busqueda y filtros
- Formulario creacion/edicion usuario con selector rol
- Matriz permisos: tabla cruzada filas=modulos, columnas=acciones
- Audit log con filtros por usuario, modulo, accion, fecha
- Exportacion audit log a CSV
- Notificaciones en tiempo real via WebSocket (campana en topbar)

---

## Notas Importantes

- **WhatsApp es el modulo mas incompleto (~57%)**: el envio real esta en STUB y depende de credenciales Meta.
- **POS offline**: el banner de "sin conexion" existe pero no hay Service Worker ni IndexedDB. Las ventas offline no se encolan localmente.
- **FIFO**: es sugerido, no automatico en `registrar_salida()`.
- **SSO**: el codigo esta implementado pero requiere configurar las variables de entorno para activarse.
- **Certificados Nubefact DEMO**: estan en `Jsoluciones-be/apps/facturacion/certs/`. Para produccion, reemplazar con certificados del cliente.
