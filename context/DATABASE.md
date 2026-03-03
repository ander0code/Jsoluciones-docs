# JSOLUCIONES ERP — BASE DE DATOS

> Reglas, convenciones y enums de la base de datos.
> Ver SQL_JSOLUCIONES.sql para el schema completo (tablas, indices, constraints).
> Aplica unicamente a Jsoluciones-be/.

---

## 1. Mixins Obligatorios (core/mixins.py — ya implementados)

Todo modelo hereda de uno o mas de estos:

```python
class TimestampMixin(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class SoftDeleteMixin(models.Model):
    is_active = models.BooleanField(default=True)
    def soft_delete(self): self.is_active = False; self.save()
    def restore(self): self.is_active = True; self.save()

class AuditMixin(models.Model):
    creado_por = models.ForeignKey('usuarios.PerfilUsuario', SET_NULL, null=True, related_name='+')
    actualizado_por = models.ForeignKey('usuarios.PerfilUsuario', SET_NULL, null=True, related_name='+')
```

- Modelos de negocio: heredan TimestampMixin + SoftDeleteMixin + AuditMixin
- Modelos inmutables (logs, movimientos de stock, asientos confirmados): solo TimestampMixin

---

## 2. Reglas de Base de Datos

```
DB-01: NUNCA modificar tablas/columnas existentes sin autorizacion del usuario.
DB-02: NUNCA eliminar migraciones. Solo crear nuevas.
DB-03: Toda tabla tiene: id (UUID PK), created_at, updated_at.
       Excepciones: tablas intermedias M2M que no tienen sentido como entidades.
DB-04: Soft delete (is_active=False). NUNCA DELETE en registros contables/fiscales.
DB-05: Toda FK tiene on_delete explicito:
       - PROTECT para entidades referenciadas (cliente, producto, proveedor)
       - CASCADE solo para detalles que NO tienen sentido sin cabecera
       - SET_NULL para campos opcionales (creado_por, actualizado_por)
DB-06: Indices compuestos en tablas de alto volumen (movimientos, detalles, comprobantes).
DB-07: unique_together o UniqueConstraint donde la logica lo requiere.
DB-08: NUNCA raw SQL sin justificacion documentada en el codigo.
DB-09: Campos de texto largo -> TextField. Cortos -> CharField con max_length.
DB-10: Las migraciones se versionan en Git (NUNCA en .gitignore).
DB-11: Campos monetarios: DecimalField(max_digits=12, decimal_places=2).
       Precio unitario: DecimalField(max_digits=12, decimal_places=4).
       Porcentajes: DecimalField(max_digits=5, decimal_places=2).
       NUNCA FloatField para dinero.
```

---

## 3. Tablas que NUNCA se Borran

Solo soft delete o cambio de estado. NUNCA `DELETE`:

| Tabla | Razon |
|-------|-------|
| comprobantes, detalle_comprobantes | Datos fiscales SUNAT |
| notas_credito_debito | Datos fiscales |
| log_envio_nubefact | Log inmutable de intentos |
| ventas, detalle_ventas | Una vez con comprobante emitido |
| asientos_contables, detalle_asientos | Datos contables |
| movimientos_stock | Logs inmutables de inventario |
| log_actividad | Auditoria de seguridad |

Para "anular": cambiar `estado='anulado'` y crear documento inverso (nota de credito, asiento reverso).

---

## 4. Protocolo para Cambios en DB

```
1. Describir el cambio al usuario (campo, tipo, motivo, impacto en otras tablas)
2. Esperar aprobacion EXPLICITA
3. Crear migracion (makemigrations)
4. Mostrar el archivo de migracion generado al usuario
5. NUNCA aplicar migrate automaticamente en produccion sin backup
```

---

## 5. Enums y Choices Centralizados (core/choices.py)

Todos los choices estan en `core/choices.py`. NUNCA redefinir localmente en las apps.

### Roles de Usuario

```python
ROL_ADMIN = 'admin'
ROL_GERENTE = 'gerente'
ROL_SUPERVISOR = 'supervisor'
ROL_VENDEDOR = 'vendedor'
ROL_CAJERO = 'cajero'
ROL_ALMACENERO = 'almacenero'
ROL_CONTADOR = 'contador'
ROL_REPARTIDOR = 'repartidor'
```

### Estados de Cotizacion

```python
COTIZACION_BORRADOR = 'borrador'
COTIZACION_VIGENTE = 'vigente'
COTIZACION_ACEPTADA = 'aceptada'
COTIZACION_VENCIDA = 'vencida'
COTIZACION_RECHAZADA = 'rechazada'
```

### Estados de Venta

```python
VENTA_COMPLETADA = 'completada'
VENTA_ANULADA = 'anulada'
VENTA_CREDITO = 'credito'
```

### Estados de Comprobante SUNAT

```python
ESTADO_COMP_PENDIENTE = 'pendiente'
ESTADO_COMP_EN_PROCESO = 'en_proceso'
ESTADO_COMP_ACEPTADO = 'aceptado'
ESTADO_COMP_RECHAZADO = 'rechazado'
ESTADO_COMP_OBSERVADO = 'observado'
ESTADO_COMP_ERROR = 'error'
ESTADO_COMP_ERROR_PERMANENTE = 'error_permanente'
ESTADO_COMP_CONTINGENCIA = 'contingencia'
MAX_REINTENTOS_COMPROBANTE = 5
FALLOS_CONSECUTIVOS_CONTINGENCIA = 3
```

### Tipos de Comprobante

```python
TIPO_FACTURA = '01'
TIPO_BOLETA = '03'
TIPO_NOTA_CREDITO = '07'
TIPO_NOTA_DEBITO = '08'
TIPO_RESUMEN_DIARIO = 'RC'
```

### Estados de Orden de Compra

```python
OC_BORRADOR = 'borrador'
OC_PENDIENTE = 'pendiente_aprobacion'
OC_APROBADA = 'aprobada'
OC_ENVIADA = 'enviada'
OC_RECIBIDA_PARCIAL = 'recibida_parcial'
OC_RECIBIDA = 'recibida'
OC_CERRADA = 'cerrada'
OC_CANCELADA = 'cancelada'
```

### Estados de Pedido (Distribucion)

```python
PEDIDO_PENDIENTE = 'pendiente'
PEDIDO_CONFIRMADO = 'confirmado'
PEDIDO_DESPACHADO = 'despachado'
PEDIDO_EN_RUTA = 'en_ruta'
PEDIDO_ENTREGADO = 'entregado'
PEDIDO_CANCELADO = 'cancelado'
PEDIDO_DEVUELTO = 'devuelto'
```

### Tipos de Movimiento de Stock

```python
MOV_ENTRADA = 'entrada'
MOV_SALIDA = 'salida'
MOV_AJUSTE = 'ajuste'
MOV_TRANSFERENCIA_SALIDA = 'transferencia_salida'
MOV_TRANSFERENCIA_ENTRADA = 'transferencia_entrada'
MOV_DEVOLUCION = 'devolucion'
```

### Estados de Cuenta por Cobrar/Pagar

```python
CXC_PENDIENTE = 'pendiente'
CXC_PAGADO = 'pagado'
CXC_VENCIDO = 'vencido'
CXC_REFINANCIADO = 'refinanciado'
```

### Tipos de Documento de Identidad

```python
TIPO_DNI = '1'
TIPO_RUC = '6'
TIPO_PASAPORTE = '7'
TIPO_CE = '4'
```

### Estados de Mensajes WhatsApp

```python
WA_ENVIADO = 'enviado'
WA_ENTREGADO = 'entregado'
WA_LEIDO = 'leido'
WA_FALLIDO = 'fallido'
WA_EN_ESPERA = 'en_espera'
```

---

## 6. Estructura de las Apps en DB

| App | Tablas principales | Notas |
|-----|-------------------|-------|
| empresa | configuracion | Singleton (1 sola fila), `singleton_lock=1` |
| usuarios | usuario, rol, permiso, perfil_usuario, log_actividad | UUID PK en usuario, email unico |
| clientes | cliente | unique_together (tipo_doc, numero_doc) |
| proveedores | proveedor | RUC unico |
| inventario | producto, categoria, almacen, stock, movimiento_stock, lote, serie, ubicacion | stock tiene unique(producto, almacen) |
| ventas | cotizacion, orden_venta, venta, detalle_venta, caja, forma_pago, comision | venta immutable post-comprobante |
| facturacion | comprobante, nota_credito_debito, serie_comprobante, log_envio_nubefact, resumen_diario | unique(serie, numero) en comprobante |
| media | media_archivo | Relacion polimorfca (entidad_tipo + entidad_id) |
| compras | orden_compra, detalle_orden, factura_proveedor, recepcion | |
| finanzas | cuenta_cobrar, cuenta_pagar, cobro, pago, cuenta_contable, asiento_contable, detalle_asiento, movimiento_bancario, periodo_contable | |
| distribucion | transportista, pedido, seguimiento_pedido, evidencia_entrega | |
| whatsapp | configuracion_wa (singleton), plantilla, mensaje, log_wa, campana, automatizacion | |
| reportes | configuracion_kpi | Sin modelos propios (queries cross-app) |

---

## 7. Indices y Constraints Importantes

```sql
-- Stock: unico por producto y almacen
UNIQUE (producto_id, almacen_id) en inventario_stock

-- Comprobante: unico por serie y numero
UNIQUE (serie_id, numero) en facturacion_comprobante

-- Cliente: unico documento por tipo
UNIQUE (tipo_documento, numero_documento) en clientes_cliente

-- Empresa singleton
UNIQUE (singleton_lock) en empresa_configuracion

-- WhatsApp config singleton
UNIQUE (singleton_lock) en whatsapp_configuracion

-- Indices de performance
INDEX en movimiento_stock (producto_id, created_at)
INDEX en comprobante (estado_sunat, fecha_emision)
INDEX en venta (fecha_venta, estado)
```

---

## 8. Referencia Schema SQL

El archivo `SQL_JSOLUCIONES.sql` en la raiz de este repo contiene el schema completo:
- Todas las tablas con sus columnas y tipos exactos
- Enums definidos a nivel de DB
- Indices y constraints
- Relaciones FK

SIEMPRE verificar en ese archivo antes de "inventar" campos. Si no esta ahi, no existe en la DB.
