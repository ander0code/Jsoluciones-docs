Con el análisis real del código, aquí van los dos flujos:
---
Flujo 1 — Venta presencial sin distribución (con factura)
Pre-requisito: Abrir caja
Ventas → Caja
- Si no hay caja abierta verás el aviso amarillo
- Clic en "Abrir Caja" → ingresas el monto inicial → confirmas
- El card se pone verde con tu nombre y hora de apertura
---
Paso 1: Registrar la venta
Ventas → Punto de Venta
- El sistema verifica que hay caja abierta (si no, te redirige automáticamente a Caja)
- Buscas o haces clic en los productos del grid para agregarlos al carrito
- En el panel derecho: buscas y seleccionas el cliente (importante: si vas a emitir Factura, el cliente debe tener RUC)
- Si el cliente no tiene RUC o es venta rápida: clic en "Consumidor Final" → se emite Boleta
- Revisas los totales en el panel CartSummary (Subtotal, IGV, TOTAL)
- Clic en "COBRAR S/ XX.XX"
- Se abre el CobroModal → seleccionas método de pago (Efectivo, Tarjeta, Yape/Plin, etc.) → confirmas
- Aparece el TicketModal con el comprobante de la venta → el carrito se limpia
---
Paso 2: Emitir el comprobante electrónico a SUNAT
Facturación → Emitir Comprobante
- Paso 1 del wizard: seleccionas Tipo (Factura o Boleta) y la Serie activa correspondiente
- Paso 2: en el buscador aparecen las ventas completadas sin comprobante aún — buscas la venta que acabas de hacer y la seleccionas
- Paso 3: se muestran los ítems y totales. Verificas que el cliente tenga RUC si es Factura (aparece ✓ verde o ✗ rojo). Revisas base gravada + IGV + Total
- Clic en "Vista Previa y Emitir" → se abre el modal de confirmación con el resumen completo
- Clic en "Confirmar y Emitir" → se envía a SUNAT vía Nubefact → te redirige a Facturación → Comprobantes donde verás el estado SUNAT (Aceptado/Pendiente)
---
Paso 3: Cerrar caja al fin del día
Ventas → Caja
- Ves el card verde con la caja abierta
- Clic en "Cerrar Caja" (rojo) → se abre CerrarCajaModal
- Ingresas el monto final contado
- Confirmas → la tabla de historial muestra la caja cerrada con Monto Inicial, Monto Final y Diferencia (verde si cuadra, rojo si hay descuadre)
---
Flujo 2 — Venta con distribución/delivery (pedido sin POS)
Este flujo es cuando el pedido se crea directamente en el módulo de distribución, sin pasar por el POS.
---
Paso 1: Crear el pedido de distribución
Logística → Pedidos y Distribución
- Clic en "Nuevo Pedido" (botón azul en el toolbar)
- Se abre PedidoFormModal con estos campos:
  - Cliente (buscador con dropdown, requerido)
  - Nombre y teléfono del destinatario
  - Dirección de entrega (requerido)
  - Enlace de Google Maps (opcional)
  - Fecha de entrega + Turno (Mañana/Tarde)
  - Prioridad (Normal / Express)
  - Costo delivery + Transportista (opcional al crear)
  - Dedicatoria + Notas internas
- Clic en "Crear Pedido" → el pedido aparece en la lista en estado Pendiente
---
Paso 2: Gestionar el pedido
Logística → Pedidos y Distribución → (clic en el pedido)
Entras al detalle del pedido. En la barra de acciones:
1. Clic en "Asignar Transportista" → seleccionas de la lista → el estado cambia automáticamente a En Ruta
2. Si necesitas: "Despachar" → estado Despachado → "Marcar En Ruta" → estado En Ruta
3. Cuando se entrega: "Confirmar Entrega" → estado Entregado
4. Si algo falla: "Entrega Fallida" → seleccionas motivo (Cliente ausente, Dirección incorrecta, etc.) → se cancela
Los botones "Comprobante PDF" y "Hoja de Ruta PDF" están siempre visibles — los puedes descargar en cualquier estado.
---
Paso 3: Seguimiento en tiempo real (opcional)
Logística → Mapa de Entregas
- Ves los conductores con GPS activo marcados en el mapa (ícono 🚛 azul)
- El mapa se refresca automáticamente cada 30 segundos
---
Lo que este flujo 2 NO hace
- No abre ni cierra caja — el pedido de distribución no pasa por el POS
- No emite comprobante SUNAT directamente — si el cliente necesita factura, tendrías que crear la venta en el POS por separado y luego emitir el comprobante desde Facturación → Emitir Comprobante
---
Resumen visual
FLUJO 1 (presencial con factura):
Caja → Abrir Caja
  └→ POS → agregar productos → cliente con RUC → COBRAR → pagar → ticket
       └→ Facturación → Emitir Comprobante → seleccionar venta → Confirmar y Emitir → SUNAT ✓
            └→ Caja → Cerrar Caja
FLUJO 2 (delivery sin POS):
Logística → Pedidos → Nuevo Pedido → rellenar datos → Crear
  └→ Detalle del pedido → Asignar Transportista → En Ruta
       └→ Confirmar Entrega → Entregado → descargar Comprobante PDF