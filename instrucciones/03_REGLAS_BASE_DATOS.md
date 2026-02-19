# JSOLUCIONES ERP — REGLAS DE BASE DE DATOS

> Este archivo protege la integridad de la base de datos.
> NINGÚN agente o desarrollador puede modificar la DB sin seguir estas reglas.
> Si hay recomendaciones o cambios, se MUESTRAN AL USUARIO antes de ejecutar.

---

## 1. REGLAS ESTRICTAS (NO NEGOCIABLES)

```
DB-01: NUNCA modificar tablas o columnas existentes sin autorización EXPLÍCITA del usuario.
DB-02: NUNCA eliminar migraciones. Solo crear nuevas.
DB-03: Toda tabla debe tener: id (PK auto), created_at (auto_now_add), updated_at (auto_now).
DB-04: Una sola DB por instancia, schema public estándar.
       Todo modelo del ERP vive en el mismo schema.
DB-05: Toda FK debe tener on_delete definido explícitamente.
DB-06: Índices compuestos en tablas de alto volumen (movimientos stock, detalle ventas).
DB-07: NUNCA usar raw SQL salvo optimizaciones justificadas y documentadas.
DB-08: Campos monetarios → DecimalField(max_digits=12, decimal_places=2).
DB-09: Campos de precio unitario → DecimalField(max_digits=12, decimal_places=4).
DB-10: Soft delete (is_active=False), NUNCA borrar registros contables o fiscales.
DB-11: NUNCA hacer DROP TABLE, DROP COLUMN o ALTER destructivo sin autorización.
DB-12: NUNCA crear migraciones con RunPython que borren datos.
DB-13: Toda migración nueva debe probarse primero en un schema de test.
DB-14: Campos de texto largo → TextField. Campos cortos → CharField con max_length definido.
DB-15: NUNCA usar FloatField para dinero. SIEMPRE DecimalField.
```

---

## 2. PROTOCOLO PARA CAMBIOS EN LA DB

### Si un agente o desarrollador necesita modificar la DB:

```
PASO 1: Describir el cambio propuesto al usuario.
        Ejemplo: "Necesito agregar el campo 'descuento_global' a la tabla 'ventas'.
                  Tipo: DecimalField(max_digits=12, decimal_places=2, default=0).
                  Motivo: Para registrar descuentos a nivel de venta completa."

PASO 2: Esperar aprobación EXPLÍCITA del usuario.

PASO 3: Solo entonces crear la migración.

PASO 4: Mostrar el resultado de la migración al usuario.
```

### Tipos de cambio y su nivel de riesgo:

| Tipo de cambio | Riesgo | Acción requerida |
|---------------|--------|-----------------|
| Agregar campo con default | Bajo | Informar al usuario |
| Agregar campo obligatorio sin default | Medio | Pedir aprobación + plan de migración de datos |
| Renombrar campo | Alto | Pedir aprobación + verificar que nada se rompa |
| Eliminar campo | MUY ALTO | Pedir aprobación + backup + verificar dependencias |
| Cambiar tipo de campo | Alto | Pedir aprobación + plan de conversión |
| Agregar tabla nueva | Bajo | Informar al usuario |
| Eliminar tabla | PROHIBIDO sin autorización |
| Agregar índice | Bajo | Informar al usuario |
| Eliminar índice | Medio | Pedir aprobación |

---

## 3. MIXINS OBLIGATORIOS PARA MODELOS

Todo modelo del ERP debe heredar de estos mixins:

```python
# core/mixins.py

from django.db import models


class TimestampMixin(models.Model):
    """Agrega created_at y updated_at a todo modelo."""
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class SoftDeleteMixin(models.Model):
    """Permite 'eliminar' registros sin borrarlos de la DB."""
    is_active = models.BooleanField(default=True, db_index=True)

    class Meta:
        abstract = True

    def soft_delete(self):
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])

    def restore(self):
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])


class AuditMixin(models.Model):
    """Registra quién creó y quién modificó por última vez."""
    created_by = models.ForeignKey(
        'usuarios.PerfilUsuario',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='%(class)s_created',
    )
    updated_by = models.ForeignKey(
        'usuarios.PerfilUsuario',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='%(class)s_updated',
    )

    class Meta:
        abstract = True
```

### Uso obligatorio:

```python
# ✅ CORRECTO — Modelo con los 3 mixins
class Venta(TimestampMixin, SoftDeleteMixin, AuditMixin):
    cliente = models.ForeignKey('clientes.Cliente', on_delete=models.PROTECT)
    # ...

# ❌ INCORRECTO — Modelo sin mixins
class Venta(models.Model):
    cliente = models.ForeignKey('clientes.Cliente')  # Falta on_delete
    # Sin created_at, updated_at, is_active
```

---

## 4. CONVENCIONES DE CAMPOS

### 4.1 Nombres de campos

```python
# Español, snake_case, descriptivo
razon_social = models.CharField(max_length=200)
numero_documento = models.CharField(max_length=15)
fecha_emision = models.DateField()
total_venta = models.DecimalField(max_digits=12, decimal_places=2)
precio_unitario = models.DecimalField(max_digits=12, decimal_places=4)
```

### 4.2 Tipos de campo obligatorios por tipo de dato

| Tipo de dato | Campo Django | Restricción |
|-------------|-------------|------------|
| Dinero (totales, subtotales) | `DecimalField(max_digits=12, decimal_places=2)` | NUNCA FloatField |
| Precio unitario | `DecimalField(max_digits=12, decimal_places=4)` | 4 decimales para precisión |
| Cantidades | `DecimalField(max_digits=12, decimal_places=2)` | Permite fracciones (kg, litros) |
| Porcentajes | `DecimalField(max_digits=5, decimal_places=2)` | Ej: 18.00 para IGV |
| RUC | `CharField(max_length=11)` | Validar 11 dígitos |
| DNI | `CharField(max_length=8)` | Validar 8 dígitos |
| Email | `EmailField()` | Validación automática |
| Teléfono | `CharField(max_length=20)` | Flexible para formatos |
| Descripción larga | `TextField(blank=True, default='')` | Sin max_length |
| Estado/Tipo | `CharField(max_length=30, choices=CHOICES)` | Siempre con choices |
| Booleano | `BooleanField(default=False)` | Siempre con default |
| Fecha | `DateField()` | Sin auto_now salvo en mixins |
| Fecha+hora | `DateTimeField()` | Sin auto_now salvo en mixins |
| URL (PDF, XML) | `URLField(max_length=500, blank=True)` | Para urls de Nubefact |
| Archivo | `FileField(upload_to='...')` | Para evidencias, contratos |

### 4.3 Foreign Keys — on_delete obligatorio

```python
# Referencia a datos que NO se pueden perder:
cliente = models.ForeignKey('clientes.Cliente', on_delete=models.PROTECT)
# PROTECT evita borrar un cliente que tiene ventas

# Referencia a datos opcionales:
created_by = models.ForeignKey('usuarios.PerfilUsuario', on_delete=models.SET_NULL, null=True)

# Referencia dentro del mismo flujo (cascada controlada):
venta = models.ForeignKey('ventas.Venta', on_delete=models.CASCADE, related_name='detalles')
# CASCADE solo para detalles que NO tienen sentido sin la cabecera

# NUNCA usar on_delete=models.DO_NOTHING
```

---

## 5. MODELO CONCEPTUAL DE DATOS POR MÓDULO

### 5.1 Módulo Inventario (Prioridad 2)

```
Producto
├── id, sku (unique), nombre, descripcion
├── categoria (FK → Categoria)
├── unidad_medida (CharField choices)
├── precio_compra, precio_venta (DecimalField)
├── stock_minimo, stock_maximo (DecimalField)
├── requiere_lote (BooleanField)
├── is_active, created_at, updated_at

Categoria
├── id, nombre, descripcion, categoria_padre (FK self, null)
├── is_active, created_at, updated_at

Almacen
├── id, nombre, direccion, sucursal
├── es_principal (BooleanField)
├── is_active, created_at, updated_at

MovimientoStock
├── id, producto (FK), almacen (FK)
├── tipo_movimiento (choices: entrada/salida/transferencia/ajuste/devolucion)
├── cantidad (DecimalField)
├── almacen_destino (FK null, solo para transferencias)
├── referencia_tipo (CharField: venta/compra/ajuste)
├── referencia_id (IntegerField, id del documento origen)
├── lote (FK null), motivo (TextField)
├── usuario (FK), created_at
├── ÍNDICES: (producto_id, created_at), (almacen_id, tipo_movimiento)

Lote
├── id, producto (FK), numero_lote, fecha_vencimiento
├── cantidad_inicial, cantidad_actual
├── almacen (FK)
├── is_active, created_at, updated_at
```

### 5.2 Módulo Clientes (Prioridad 3)

```
Cliente
├── id, tipo_documento (choices: DNI/RUC/CE/PASAPORTE)
├── numero_documento (unique por tipo)
├── razon_social, nombre_comercial
├── direccion, ubigeo, email, telefono
├── segmento (choices: frecuente/nuevo/credito/vip)
├── limite_credito (DecimalField, default=0)
├── is_active, created_at, updated_at
```

### 5.3 Módulo Proveedores (Prioridad 3)

```
Proveedor
├── id, ruc (unique, 11 chars), razon_social
├── nombre_comercial, direccion, email, telefono
├── contacto_nombre, contacto_telefono
├── condicion_pago_dias (IntegerField, default=0)
├── calificacion (IntegerField, 1-5)
├── is_active, created_at, updated_at
```

### 5.4 Módulo Ventas (Prioridad 4)

```
Cotizacion
├── id, numero (auto), fecha_emision, fecha_validez
├── cliente (FK PROTECT), vendedor (FK)
├── estado (choices: borrador/vigente/aceptada/vencida/rechazada)
├── total_gravada, total_igv, total_venta
├── notas, condiciones_comerciales
├── is_active, created_at, updated_at, created_by

DetalleCotizacion
├── id, cotizacion (FK CASCADE)
├── producto (FK PROTECT), cantidad, precio_unitario
├── descuento_porcentaje, subtotal, igv, total

OrdenVenta
├── id, numero (auto), fecha
├── cotizacion_origen (FK null, si viene de cotización)
├── cliente (FK PROTECT), vendedor (FK)
├── estado (choices: pendiente/confirmada/parcial/completada/cancelada)
├── total_gravada, total_igv, total_venta
├── is_active, created_at, updated_at, created_by

DetalleOrdenVenta
├── id, orden_venta (FK CASCADE)
├── producto (FK PROTECT), cantidad, cantidad_entregada
├── precio_unitario, descuento, subtotal, igv, total

Venta
├── id, numero (auto), fecha, hora
├── orden_origen (FK null), cliente (FK PROTECT)
├── vendedor (FK), sucursal, caja
├── tipo_venta (choices: directa/online/campo)
├── metodo_pago (choices: efectivo/tarjeta/transferencia/yape_plin/credito)
├── total_gravada, total_igv, total_descuento, total_venta
├── estado (choices: completada/anulada)
├── comprobante (FK null → Comprobante)
├── is_active, created_at, updated_at, created_by

DetalleVenta
├── id, venta (FK CASCADE)
├── producto (FK PROTECT), cantidad
├── precio_unitario, descuento_porcentaje
├── subtotal, igv, total
├── lote (FK null)
```

### 5.5 Módulo Facturación — Nubefact (Prioridad 5)

```
SerieComprobante
├── id, tipo_comprobante (choices: 01/03/07/08)
├── serie (CharField, ej: F001, B001)
├── correlativo_actual (IntegerField)
├── is_active

Comprobante
├── id, tipo_comprobante, serie, numero
├── fecha_emision, hora_emision
├── cliente (FK PROTECT)
├── moneda (default='PEN')
├── total_gravada, total_exonerada, total_inafecta
├── total_igv, total_venta
├── estado_sunat (choices: pendiente/aceptado/rechazado/observado/anulado)
├── pdf_url, xml_url, cdr_url (URLField, guardados desde respuesta Nubefact)
├── hash_sunat, qr_sunat (TextField)
├── nubefact_request (JSONField, el JSON enviado a Nubefact)
├── nubefact_response (JSONField, la respuesta completa de Nubefact)
├── modo_emision (choices: normal/contingencia)
├── venta (FK null → Venta)
├── created_at, updated_at, created_by

DetalleComprobante
├── id, comprobante (FK CASCADE)
├── codigo_producto, descripcion
├── cantidad, unidad_medida
├── precio_unitario, subtotal, igv, total
├── tipo_afectacion_igv (choices: 10=gravado, 20=exonerado, 30=inafecto)

NotaCreditoDebito
├── id, comprobante_origen (FK PROTECT → Comprobante)
├── tipo_nota (choices: 07=crédito, 08=débito)
├── serie, numero, fecha_emision
├── motivo_codigo_nc (enum NC, null si es ND)
├── motivo_codigo_nd (enum ND, null si es NC)
├── motivo_descripcion
├── total_gravada, total_igv, total
├── estado_sunat, pdf_url, xml_url, cdr_url
├── nubefact_request, nubefact_response
├── created_at, updated_at, created_by

LogEnvioNubefact
├── id, comprobante (FK)
├── tipo_documento, fecha_envio
├── request_json (JSONField), response_json (JSONField)
├── codigo_respuesta, mensaje_respuesta
├── estado (choices: enviado/error/pendiente)
├── intentos (IntegerField)
├── created_at
```

### 5.6 Módulo Compras (Prioridad 6)

```
OrdenCompra
├── id, numero (auto), fecha, fecha_estimada_entrega
├── proveedor (FK PROTECT)
├── estado (choices: borrador/pendiente_aprobacion/aprobada/enviada/recibida/cerrada/cancelada)
├── almacen_destino (FK)
├── moneda, total_base, total_igv, total
├── notas, aprobado_por (FK null)
├── is_active, created_at, updated_at, created_by

DetalleOrdenCompra
├── id, orden_compra (FK CASCADE)
├── producto (FK PROTECT), cantidad, cantidad_recibida
├── precio_unitario, subtotal, igv, total

FacturaProveedor
├── id, proveedor (FK PROTECT)
├── numero_factura, ruc_proveedor
├── fecha_emision, fecha_vencimiento
├── total_base, total_igv, total
├── orden_compra (FK null)
├── estado (choices: registrada/conciliada/pagada/anulada)
├── created_at, updated_at

Recepcion
├── id, orden_compra (FK)
├── fecha_recepcion, almacen (FK)
├── tipo (choices: total/parcial)
├── observaciones, recibido_por (FK)
├── created_at

DetalleRecepcion
├── id, recepcion (FK CASCADE)
├── detalle_orden_compra (FK PROTECT)
├── producto (FK PROTECT), cantidad_recibida
├── lote (FK null)
├── observaciones
├── created_at
```

### 5.7 Módulo Finanzas (Prioridad 7)

```
CuentaPorCobrar
├── id, cliente (FK), comprobante (FK null)
├── monto_original, monto_pendiente
├── fecha_emision, fecha_vencimiento
├── estado (choices: pendiente/vencido/pagado/refinanciado)
├── created_at, updated_at

CuentaPorPagar
├── id, proveedor (FK), factura_proveedor (FK null)
├── monto_original, monto_pendiente
├── fecha_emision, fecha_vencimiento
├── estado (choices: pendiente/vencido/pagado)
├── created_at, updated_at

Pago / Cobro
├── id, cuenta (FK), monto, fecha
├── metodo_pago, referencia
├── usuario (FK), notas
├── created_at

AsientoContable
├── id, numero, fecha, descripcion
├── centro_costo (VARCHAR(100) null — etiqueta libre, no FK)
├── referencia_tipo, referencia_id
├── estado (choices: borrador/confirmado/anulado)
├── created_at, created_by

DetalleAsiento
├── id, asiento (FK CASCADE)
├── cuenta_contable (FK)
├── debe (DecimalField), haber (DecimalField)
├── descripcion
```

### 5.8 Módulo Distribución (Prioridad 8)

```
Pedido
├── id, numero, fecha
├── venta (FK null), cliente (FK)
├── direccion_entrega, latitud, longitud
├── estado (choices: pendiente/confirmado/despachado/en_ruta/entregado/cancelado)
├── transportista (FK null)
├── fecha_estimada_entrega, fecha_entrega_real
├── notas, prioridad (choices: normal/express)
├── created_at, updated_at

Transportista
├── id, nombre, telefono, email
├── tipo_vehiculo, placa
├── limite_pedidos_diario
├── is_active

SeguimientoPedido
├── id, pedido (FK)
├── estado, latitud, longitud
├── descripcion, fecha_evento
├── created_at

EvidenciaEntrega
├── id, pedido (FK)
├── tipo (choices: foto/firma/otp)
├── archivo (FileField null), codigo_otp
├── created_at
```

### 5.9 Módulo WhatsApp (Prioridad 9)

```
ConfiguracionWhatsApp
├── id, phone_number_id, token_acceso
├── business_id, numero_verificado
├── is_active

PlantillaWhatsApp
├── id, nombre, categoria (choices: transaccional/marketing/alerta)
├── contenido_template, variables_count
├── estado_meta (choices: en_revision/aprobada/rechazada)
├── is_active, created_at

MensajeWhatsApp
├── id, plantilla (FK null), destinatario_telefono
├── cliente (FK null), contenido_enviado
├── estado (choices: enviado/entregado/leido/fallido/en_espera)
├── meta_message_id, codigo_respuesta_api
├── referencia_tipo (venta/pedido/cobranza/campana)
├── referencia_id
├── created_at

LogWhatsApp
├── id, mensaje (FK), request_json, response_json
├── codigo_http, created_at
```

---

## 6. OPTIMIZACIONES OBLIGATORIAS

### 6.1 Índices compuestos (crear desde el inicio)

```python
class MovimientoStock(TimestampMixin):
    # ... campos ...

    class Meta:
        indexes = [
            models.Index(fields=['producto', 'created_at'], name='idx_mov_producto_fecha'),
            models.Index(fields=['almacen', 'tipo_movimiento'], name='idx_mov_almacen_tipo'),
            models.Index(fields=['referencia_tipo', 'referencia_id'], name='idx_mov_referencia'),
        ]

class DetalleVenta(models.Model):
    # ... campos ...

    class Meta:
        indexes = [
            models.Index(fields=['venta', 'producto'], name='idx_dv_venta_producto'),
        ]

class Comprobante(TimestampMixin):
    # ... campos ...

    class Meta:
        indexes = [
            models.Index(fields=['tipo_comprobante', 'serie', 'numero'], name='idx_comp_tipo_serie_num'),
            models.Index(fields=['cliente', 'fecha_emision'], name='idx_comp_cliente_fecha'),
            models.Index(fields=['estado_sunat'], name='idx_comp_estado'),
        ]
        unique_together = [['tipo_comprobante', 'serie', 'numero']]
```

### 6.2 select_related y prefetch_related (obligatorio en querysets)

```python
# ❌ MAL — Genera N+1 queries
ventas = Venta.objects.all()
for v in ventas:
    print(v.cliente.razon_social)  # 1 query por venta

# ✅ BIEN
ventas = Venta.objects.select_related('cliente', 'vendedor').all()

# Para relaciones inversas (many):
ventas = Venta.objects.prefetch_related('detalles', 'detalles__producto').all()
```

---

## 7. TABLAS QUE NUNCA SE BORRAN (Solo soft delete)

Estas tablas contienen datos fiscales o legales. PROHIBIDO hacer DELETE:

- `comprobantes` (facturas, boletas)
- `detalle_comprobante`
- `notas_credito_debito`
- `log_envio_nubefact`
- `ventas` (una vez emitida con comprobante)
- `detalle_venta` (asociado a venta con comprobante)
- `asientos_contables`
- `detalle_asiento`
- `movimientos_stock` (son logs, nunca se borran)

Para "anular", se cambia el estado a `anulado` y se crea el documento inverso correspondiente (nota de crédito, asiento reverso, etc.).
