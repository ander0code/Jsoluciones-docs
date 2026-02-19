# JSOLUCIONES ERP — CONSTANTES Y CÓDIGO COMPARTIDO

> Este archivo contiene código listo para copiar al proyecto.
> Choices, mixins, formato de respuesta API, validadores.
> Todo esto va en la carpeta `core/` del proyecto Django.

---

## 1. CONSTANTES GLOBALES (core/choices.py)

```python
# core/choices.py
# Todas las constantes del ERP centralizadas.
# Los módulos pueden tener su propio choices.py para constantes específicas,
# pero las globales van aquí.

# ═══════════════════════════════════════════
# DOCUMENTOS DE IDENTIDAD (Perú - SUNAT)
# ═══════════════════════════════════════════
TIPO_DOC_DNI = '1'
TIPO_DOC_RUC = '6'
TIPO_DOC_CE = '4'
TIPO_DOC_PASAPORTE = '7'
TIPO_DOC_OTROS = '0'

TIPO_DOCUMENTO_CHOICES = [
    (TIPO_DOC_DNI, 'DNI'),
    (TIPO_DOC_RUC, 'RUC'),
    (TIPO_DOC_CE, 'Carné de Extranjería'),
    (TIPO_DOC_PASAPORTE, 'Pasaporte'),
    (TIPO_DOC_OTROS, 'Otros'),
]

# ═══════════════════════════════════════════
# COMPROBANTES (SUNAT)
# ═══════════════════════════════════════════
COMPROBANTE_FACTURA = '01'
COMPROBANTE_BOLETA = '03'
COMPROBANTE_NOTA_CREDITO = '07'
COMPROBANTE_NOTA_DEBITO = '08'

TIPO_COMPROBANTE_CHOICES = [
    (COMPROBANTE_FACTURA, 'Factura'),
    (COMPROBANTE_BOLETA, 'Boleta'),
    (COMPROBANTE_NOTA_CREDITO, 'Nota de Crédito'),
    (COMPROBANTE_NOTA_DEBITO, 'Nota de Débito'),
]

# ═══════════════════════════════════════════
# ESTADOS DE COMPROBANTE (respuesta SUNAT/Nubefact)
# ═══════════════════════════════════════════
ESTADO_COMP_PENDIENTE = 'pendiente'
ESTADO_COMP_ACEPTADO = 'aceptado'
ESTADO_COMP_RECHAZADO = 'rechazado'
ESTADO_COMP_OBSERVADO = 'observado'
ESTADO_COMP_ANULADO = 'anulado'
ESTADO_COMP_ERROR = 'error'
ESTADO_COMP_PENDIENTE_REENVIO = 'pendiente_reenvio'

ESTADO_COMPROBANTE_CHOICES = [
    (ESTADO_COMP_PENDIENTE, 'Pendiente'),
    (ESTADO_COMP_ACEPTADO, 'Aceptado por SUNAT'),
    (ESTADO_COMP_RECHAZADO, 'Rechazado por SUNAT'),
    (ESTADO_COMP_OBSERVADO, 'Observado por SUNAT'),
    (ESTADO_COMP_ANULADO, 'Anulado'),
    (ESTADO_COMP_ERROR, 'Error de envío'),
    (ESTADO_COMP_PENDIENTE_REENVIO, 'Pendiente de reenvío'),
]

# ═══════════════════════════════════════════
# AFECTACIÓN IGV (códigos SUNAT)
# ═══════════════════════════════════════════
IGV_GRAVADO = '10'
IGV_EXONERADO = '20'
IGV_INAFECTO = '30'
IGV_GRATUITO = '21'

AFECTACION_IGV_CHOICES = [
    (IGV_GRAVADO, 'Gravado - Operación Onerosa'),
    (IGV_EXONERADO, 'Exonerado - Operación Onerosa'),
    (IGV_INAFECTO, 'Inafecto - Operación Onerosa'),
    (IGV_GRATUITO, 'Exonerado - Transferencia Gratuita'),
]

# ═══════════════════════════════════════════
# MOTIVOS DE NOTA DE CRÉDITO (SUNAT)
# ═══════════════════════════════════════════
NC_ANULACION = '01'
NC_ANULACION_ERROR = '02'
NC_DESCUENTO_GLOBAL = '03'
NC_DEVOLUCION = '06'

MOTIVO_NOTA_CREDITO_CHOICES = [
    (NC_ANULACION, 'Anulación de la operación'),
    (NC_ANULACION_ERROR, 'Anulación por error en RUC'),
    (NC_DESCUENTO_GLOBAL, 'Descuento global'),
    (NC_DEVOLUCION, 'Devolución total o parcial'),
]

# ═══════════════════════════════════════════
# MOTIVOS DE NOTA DE DÉBITO (SUNAT)
# ═══════════════════════════════════════════
ND_INTERESES = '01'
ND_PENALIDAD = '02'
ND_AUMENTO_VALOR = '03'

MOTIVO_NOTA_DEBITO_CHOICES = [
    (ND_INTERESES, 'Intereses por mora'),
    (ND_PENALIDAD, 'Aumento en el valor'),
    (ND_AUMENTO_VALOR, 'Penalidades / otros conceptos'),
]

# ═══════════════════════════════════════════
# TIPO DE NOTA (Crédito / Débito)
# ═══════════════════════════════════════════
NOTA_CREDITO = '07'
NOTA_DEBITO = '08'

TIPO_NOTA_CHOICES = [
    (NOTA_CREDITO, 'Nota de Crédito'),
    (NOTA_DEBITO, 'Nota de Débito'),
]

# ═══════════════════════════════════════════
# MÉTODOS DE PAGO
# ═══════════════════════════════════════════
PAGO_EFECTIVO = 'efectivo'
PAGO_TARJETA = 'tarjeta'
PAGO_TRANSFERENCIA = 'transferencia'
PAGO_YAPE_PLIN = 'yape_plin'
PAGO_CREDITO = 'credito'

METODO_PAGO_CHOICES = [
    (PAGO_EFECTIVO, 'Efectivo'),
    (PAGO_TARJETA, 'Tarjeta'),
    (PAGO_TRANSFERENCIA, 'Transferencia Bancaria'),
    (PAGO_YAPE_PLIN, 'Yape / Plin / QR'),
    (PAGO_CREDITO, 'Crédito'),
]

# ═══════════════════════════════════════════
# MOVIMIENTOS DE INVENTARIO
# ═══════════════════════════════════════════
MOV_ENTRADA = 'entrada'
MOV_SALIDA = 'salida'
MOV_TRANSFERENCIA = 'transferencia'
MOV_AJUSTE = 'ajuste'
MOV_DEVOLUCION = 'devolucion'

TIPO_MOVIMIENTO_CHOICES = [
    (MOV_ENTRADA, 'Entrada'),
    (MOV_SALIDA, 'Salida'),
    (MOV_TRANSFERENCIA, 'Transferencia'),
    (MOV_AJUSTE, 'Ajuste'),
    (MOV_DEVOLUCION, 'Devolución'),
]

# Origen del movimiento (para trazabilidad)
REF_VENTA = 'venta'
REF_COMPRA = 'compra'
REF_AJUSTE = 'ajuste_manual'
REF_TRANSFERENCIA = 'transferencia'
REF_DEVOLUCION = 'devolucion'

REFERENCIA_TIPO_CHOICES = [
    (REF_VENTA, 'Venta'),
    (REF_COMPRA, 'Compra'),
    (REF_AJUSTE, 'Ajuste Manual'),
    (REF_TRANSFERENCIA, 'Transferencia'),
    (REF_DEVOLUCION, 'Devolución'),
]

# ═══════════════════════════════════════════
# ESTADOS DE PEDIDO / DISTRIBUCIÓN
# ═══════════════════════════════════════════
PEDIDO_PENDIENTE = 'pendiente'
PEDIDO_CONFIRMADO = 'confirmado'
PEDIDO_DESPACHADO = 'despachado'
PEDIDO_EN_RUTA = 'en_ruta'
PEDIDO_ENTREGADO = 'entregado'
PEDIDO_CANCELADO = 'cancelado'
PEDIDO_DEVUELTO = 'devuelto'

ESTADO_PEDIDO_CHOICES = [
    (PEDIDO_PENDIENTE, 'Pendiente'),
    (PEDIDO_CONFIRMADO, 'Confirmado'),
    (PEDIDO_DESPACHADO, 'Despachado'),
    (PEDIDO_EN_RUTA, 'En Ruta'),
    (PEDIDO_ENTREGADO, 'Entregado'),
    (PEDIDO_CANCELADO, 'Cancelado'),
    (PEDIDO_DEVUELTO, 'Devuelto'),
]

# ═══════════════════════════════════════════
# PRIORIDAD DE PEDIDO
# ═══════════════════════════════════════════
PRIORIDAD_NORMAL = 'normal'
PRIORIDAD_EXPRESS = 'express'

PRIORIDAD_PEDIDO_CHOICES = [
    (PRIORIDAD_NORMAL, 'Normal'),
    (PRIORIDAD_EXPRESS, 'Express'),
]

# ═══════════════════════════════════════════
# TIPO DE EVIDENCIA DE ENTREGA
# ═══════════════════════════════════════════
EVIDENCIA_FOTO = 'foto'
EVIDENCIA_FIRMA = 'firma'
EVIDENCIA_OTP = 'otp'

TIPO_EVIDENCIA_CHOICES = [
    (EVIDENCIA_FOTO, 'Foto'),
    (EVIDENCIA_FIRMA, 'Firma digital'),
    (EVIDENCIA_OTP, 'Código OTP'),
]

# ═══════════════════════════════════════════
# ESTADOS DE COTIZACIÓN
# ═══════════════════════════════════════════
COT_BORRADOR = 'borrador'
COT_VIGENTE = 'vigente'
COT_ACEPTADA = 'aceptada'
COT_VENCIDA = 'vencida'
COT_RECHAZADA = 'rechazada'

ESTADO_COTIZACION_CHOICES = [
    (COT_BORRADOR, 'Borrador'),
    (COT_VIGENTE, 'Vigente'),
    (COT_ACEPTADA, 'Aceptada'),
    (COT_VENCIDA, 'Vencida'),
    (COT_RECHAZADA, 'Rechazada'),
]

# ═══════════════════════════════════════════
# ESTADOS DE ORDEN DE VENTA
# ═══════════════════════════════════════════
OV_PENDIENTE = 'pendiente'
OV_CONFIRMADA = 'confirmada'
OV_PARCIAL = 'parcial'
OV_COMPLETADA = 'completada'
OV_CANCELADA = 'cancelada'

ESTADO_ORDEN_VENTA_CHOICES = [
    (OV_PENDIENTE, 'Pendiente'),
    (OV_CONFIRMADA, 'Confirmada'),
    (OV_PARCIAL, 'Entrega Parcial'),
    (OV_COMPLETADA, 'Completada'),
    (OV_CANCELADA, 'Cancelada'),
]

# ═══════════════════════════════════════════
# ESTADOS DE VENTA
# ═══════════════════════════════════════════
VENTA_COMPLETADA = 'completada'
VENTA_ANULADA = 'anulada'

ESTADO_VENTA_CHOICES = [
    (VENTA_COMPLETADA, 'Completada'),
    (VENTA_ANULADA, 'Anulada'),
]

# TIPO DE VENTA
VENTA_DIRECTA = 'directa'
VENTA_ONLINE = 'online'
VENTA_CAMPO = 'campo'

TIPO_VENTA_CHOICES = [
    (VENTA_DIRECTA, 'Venta Directa (POS)'),
    (VENTA_ONLINE, 'Venta en Línea'),
    (VENTA_CAMPO, 'Venta en Campo'),
]

# ═══════════════════════════════════════════
# ESTADOS DE ORDEN DE COMPRA
# ═══════════════════════════════════════════
OC_BORRADOR = 'borrador'
OC_PENDIENTE = 'pendiente_aprobacion'
OC_APROBADA = 'aprobada'
OC_ENVIADA = 'enviada'
OC_RECIBIDA_PARCIAL = 'recibida_parcial'
OC_RECIBIDA = 'recibida'
OC_CERRADA = 'cerrada'
OC_CANCELADA = 'cancelada'

ESTADO_OC_CHOICES = [
    (OC_BORRADOR, 'Borrador'),
    (OC_PENDIENTE, 'Pendiente de Aprobación'),
    (OC_APROBADA, 'Aprobada'),
    (OC_ENVIADA, 'Enviada al Proveedor'),
    (OC_RECIBIDA_PARCIAL, 'Recibida Parcialmente'),
    (OC_RECIBIDA, 'Recibida'),
    (OC_CERRADA, 'Cerrada'),
    (OC_CANCELADA, 'Cancelada'),
]

# ═══════════════════════════════════════════
# ESTADOS DE FACTURA DE PROVEEDOR
# ═══════════════════════════════════════════
FP_REGISTRADA = 'registrada'
FP_CONCILIADA = 'conciliada'
FP_PAGADA = 'pagada'
FP_ANULADA = 'anulada'

ESTADO_FACTURA_PROVEEDOR_CHOICES = [
    (FP_REGISTRADA, 'Registrada'),
    (FP_CONCILIADA, 'Conciliada'),
    (FP_PAGADA, 'Pagada'),
    (FP_ANULADA, 'Anulada'),
]

# ═══════════════════════════════════════════
# TIPO DE RECEPCIÓN (compras)
# ═══════════════════════════════════════════
RECEPCION_TOTAL = 'total'
RECEPCION_PARCIAL = 'parcial'

TIPO_RECEPCION_CHOICES = [
    (RECEPCION_TOTAL, 'Total'),
    (RECEPCION_PARCIAL, 'Parcial'),
]

# ═══════════════════════════════════════════
# CUENTAS POR COBRAR / PAGAR
# ═══════════════════════════════════════════
CXC_PENDIENTE = 'pendiente'
CXC_VENCIDO = 'vencido'
CXC_PAGADO = 'pagado'
CXC_REFINANCIADO = 'refinanciado'

ESTADO_CUENTA_CHOICES = [
    (CXC_PENDIENTE, 'Pendiente'),
    (CXC_VENCIDO, 'Vencido'),
    (CXC_PAGADO, 'Pagado'),
    (CXC_REFINANCIADO, 'Refinanciado'),
]

# ═══════════════════════════════════════════
# ESTADOS DE ASIENTO CONTABLE
# ═══════════════════════════════════════════
ASIENTO_BORRADOR = 'borrador'
ASIENTO_CONFIRMADO = 'confirmado'
ASIENTO_ANULADO = 'anulado'

ESTADO_ASIENTO_CHOICES = [
    (ASIENTO_BORRADOR, 'Borrador'),
    (ASIENTO_CONFIRMADO, 'Confirmado'),
    (ASIENTO_ANULADO, 'Anulado'),
]

# ═══════════════════════════════════════════
# TIPOS DE CUENTA CONTABLE
# ═══════════════════════════════════════════
CUENTA_ACTIVO = 'activo'
CUENTA_PASIVO = 'pasivo'
CUENTA_PATRIMONIO = 'patrimonio'
CUENTA_INGRESO = 'ingreso'
CUENTA_GASTO = 'gasto'

TIPO_CUENTA_CONTABLE_CHOICES = [
    (CUENTA_ACTIVO, 'Activo'),
    (CUENTA_PASIVO, 'Pasivo'),
    (CUENTA_PATRIMONIO, 'Patrimonio'),
    (CUENTA_INGRESO, 'Ingreso'),
    (CUENTA_GASTO, 'Gasto'),
]

# ═══════════════════════════════════════════
# WHATSAPP
# ═══════════════════════════════════════════
WA_ENVIADO = 'enviado'
WA_ENTREGADO = 'entregado'
WA_LEIDO = 'leido'
WA_FALLIDO = 'fallido'
WA_EN_ESPERA = 'en_espera'

ESTADO_MENSAJE_WA_CHOICES = [
    (WA_ENVIADO, 'Enviado'),
    (WA_ENTREGADO, 'Entregado'),
    (WA_LEIDO, 'Leído'),
    (WA_FALLIDO, 'Fallido'),
    (WA_EN_ESPERA, 'En Espera'),
]

WA_TRANSACCIONAL = 'transaccional'
WA_MARKETING = 'marketing'
WA_ALERTA = 'alerta'

CATEGORIA_PLANTILLA_WA_CHOICES = [
    (WA_TRANSACCIONAL, 'Transaccional'),
    (WA_MARKETING, 'Marketing'),
    (WA_ALERTA, 'Alerta'),
]

# Estado de plantilla en Meta (aprobación de WhatsApp Business)
META_EN_REVISION = 'en_revision'
META_APROBADA = 'aprobada'
META_RECHAZADA = 'rechazada'

ESTADO_PLANTILLA_META_CHOICES = [
    (META_EN_REVISION, 'En Revisión'),
    (META_APROBADA, 'Aprobada'),
    (META_RECHAZADA, 'Rechazada'),
]

# ═══════════════════════════════════════════
# UNIDADES DE MEDIDA (SUNAT)
# ═══════════════════════════════════════════
UM_UNIDAD = 'NIU'
UM_KILOGRAMO = 'KGM'
UM_LITRO = 'LTR'
UM_METRO = 'MTR'
UM_CAJA = 'BX'
UM_DOCENA = 'DZN'
UM_PAQUETE = 'PK'
UM_SERVICIO = 'ZZ'

UNIDAD_MEDIDA_CHOICES = [
    (UM_UNIDAD, 'Unidad'),
    (UM_KILOGRAMO, 'Kilogramo'),
    (UM_LITRO, 'Litro'),
    (UM_METRO, 'Metro'),
    (UM_CAJA, 'Caja'),
    (UM_DOCENA, 'Docena'),
    (UM_PAQUETE, 'Paquete'),
    (UM_SERVICIO, 'Servicio'),
]

# ═══════════════════════════════════════════
# MONEDAS
# ═══════════════════════════════════════════
MONEDA_SOLES = 'PEN'
MONEDA_DOLARES = 'USD'

MONEDA_CHOICES = [
    (MONEDA_SOLES, 'Soles (S/)'),
    (MONEDA_DOLARES, 'Dólares (US$)'),
]

# ═══════════════════════════════════════════
# IGV (tasa vigente en Perú)
# ═══════════════════════════════════════════
TASA_IGV = 0.18  # 18%

# ═══════════════════════════════════════════
# SEGMENTOS DE CLIENTE
# ═══════════════════════════════════════════
SEG_NUEVO = 'nuevo'
SEG_FRECUENTE = 'frecuente'
SEG_VIP = 'vip'
SEG_CREDITO = 'credito'
SEG_CORPORATIVO = 'corporativo'

SEGMENTO_CLIENTE_CHOICES = [
    (SEG_NUEVO, 'Nuevo'),
    (SEG_FRECUENTE, 'Frecuente'),
    (SEG_VIP, 'VIP'),
    (SEG_CREDITO, 'Crédito'),
    (SEG_CORPORATIVO, 'Corporativo'),
]

# ═══════════════════════════════════════════
# MODOS DE EMISIÓN
# ═══════════════════════════════════════════
EMISION_NORMAL = 'normal'
EMISION_CONTINGENCIA = 'contingencia'

MODO_EMISION_CHOICES = [
    (EMISION_NORMAL, 'Normal'),
    (EMISION_CONTINGENCIA, 'Contingencia'),
]

# ═══════════════════════════════════════════
# ESTADOS DE ENVÍO A NUBEFACT (log)
# ═══════════════════════════════════════════
ENVIO_NF_ENVIADO = 'enviado'
ENVIO_NF_ERROR = 'error'
ENVIO_NF_PENDIENTE = 'pendiente'

ESTADO_ENVIO_NUBEFACT_CHOICES = [
    (ENVIO_NF_ENVIADO, 'Enviado'),
    (ENVIO_NF_ERROR, 'Error'),
    (ENVIO_NF_PENDIENTE, 'Pendiente de reintento'),
]

# ═══════════════════════════════════════════
# ROLES BASE DEL SISTEMA
# ═══════════════════════════════════════════
ROL_ADMIN = 'admin'
ROL_GERENTE = 'gerente'
ROL_SUPERVISOR = 'supervisor'
ROL_VENDEDOR = 'vendedor'
ROL_CAJERO = 'cajero'
ROL_ALMACENERO = 'almacenero'
ROL_CONTADOR = 'contador'
ROL_REPARTIDOR = 'repartidor'

ROLES_BASE = [
    (ROL_ADMIN, 'Administrador'),
    (ROL_GERENTE, 'Gerente'),
    (ROL_SUPERVISOR, 'Supervisor'),
    (ROL_VENDEDOR, 'Vendedor'),
    (ROL_CAJERO, 'Cajero'),
    (ROL_ALMACENERO, 'Almacenero'),
    (ROL_CONTADOR, 'Contador'),
    (ROL_REPARTIDOR, 'Repartidor'),
]

# ═══════════════════════════════════════════
# MEDIA / ARCHIVOS (Cloudflare R2)
# ═══════════════════════════════════════════
ENTIDAD_PRODUCTO = 'producto'
ENTIDAD_CONFIGURACION = 'configuracion'
ENTIDAD_PERFIL_USUARIO = 'perfil_usuario'
ENTIDAD_EVIDENCIA_ENTREGA = 'evidencia_entrega'
ENTIDAD_PROVEEDOR = 'proveedor'
ENTIDAD_CLIENTE = 'cliente'

ENTIDAD_MEDIA_CHOICES = [
    (ENTIDAD_PRODUCTO, 'Producto'),
    (ENTIDAD_CONFIGURACION, 'Configuración'),
    (ENTIDAD_PERFIL_USUARIO, 'Perfil de Usuario'),
    (ENTIDAD_EVIDENCIA_ENTREGA, 'Evidencia de Entrega'),
    (ENTIDAD_PROVEEDOR, 'Proveedor'),
    (ENTIDAD_CLIENTE, 'Cliente'),
]

ARCHIVO_IMAGEN = 'imagen'
ARCHIVO_DOCUMENTO = 'documento'
ARCHIVO_FIRMA = 'firma'

TIPO_ARCHIVO_CHOICES = [
    (ARCHIVO_IMAGEN, 'Imagen'),
    (ARCHIVO_DOCUMENTO, 'Documento'),
    (ARCHIVO_FIRMA, 'Firma'),
]
```

---

## 2. MIXINS DE MODELOS (core/mixins.py)

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
    """Soft delete: is_active=False en vez de borrar."""
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
    """Registra quién creó y modificó por última vez."""
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

---

## 3. VALIDADORES (core/utils/validators.py)

```python
# core/utils/validators.py
import re
from django.core.exceptions import ValidationError


def validar_ruc(value):
    """Valida formato de RUC peruano (11 dígitos, empieza con 10 o 20)."""
    if not value:
        raise ValidationError('El RUC es obligatorio.')
    if not re.match(r'^(10|20)\d{9}$', value):
        raise ValidationError(
            'RUC inválido. Debe tener 11 dígitos y empezar con 10 o 20.'
        )


def validar_dni(value):
    """Valida formato de DNI peruano (8 dígitos)."""
    if not value:
        raise ValidationError('El DNI es obligatorio.')
    if not re.match(r'^\d{8}$', value):
        raise ValidationError('DNI inválido. Debe tener exactamente 8 dígitos.')


def validar_documento_identidad(tipo_documento, numero_documento):
    """Valida el documento según su tipo."""
    from core.choices import TIPO_DOC_DNI, TIPO_DOC_RUC

    if tipo_documento == TIPO_DOC_DNI:
        validar_dni(numero_documento)
    elif tipo_documento == TIPO_DOC_RUC:
        validar_ruc(numero_documento)
    elif not numero_documento:
        raise ValidationError('El número de documento es obligatorio.')


def validar_precio_positivo(value):
    """Valida que un precio sea mayor a 0."""
    if value is not None and value <= 0:
        raise ValidationError('El precio debe ser mayor a 0.')


def validar_cantidad_positiva(value):
    """Valida que una cantidad sea mayor a 0."""
    if value is not None and value <= 0:
        raise ValidationError('La cantidad debe ser mayor a 0.')
```

---

## 4. PAGINACIÓN ESTÁNDAR (core/pagination.py)

```python
# core/pagination.py
from rest_framework.pagination import PageNumberPagination


class StandardPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
```

---

## 5. EXCEPCIONES CUSTOM (core/exceptions.py)

```python
# core/exceptions.py
from rest_framework.exceptions import APIException


class StockInsuficienteError(APIException):
    status_code = 400
    default_detail = 'Stock insuficiente para completar la operación.'
    default_code = 'stock_insuficiente'


class NubefactError(APIException):
    status_code = 502
    default_detail = 'Error de comunicación con Nubefact.'
    default_code = 'nubefact_error'


class ComprobanteRechazadoError(APIException):
    status_code = 400
    default_detail = 'Comprobante rechazado por SUNAT.'
    default_code = 'comprobante_rechazado'


class PermisoInsuficienteError(APIException):
    status_code = 403
    default_detail = 'No tiene permisos para esta operación.'
    default_code = 'permiso_insuficiente'


class CotizacionVencidaError(APIException):
    status_code = 400
    default_detail = 'La cotización está vencida. Debe duplicarla para continuar.'
    default_code = 'cotizacion_vencida'


class LimiteCreditoExcedidoError(APIException):
    status_code = 400
    default_detail = 'El cliente ha excedido su límite de crédito.'
    default_code = 'limite_credito_excedido'


class OrdenNoAprobadaError(APIException):
    status_code = 400
    default_detail = 'La orden de compra no ha sido aprobada.'
    default_code = 'orden_no_aprobada'


class ConciliacionPendienteError(APIException):
    status_code = 400
    default_detail = 'No se puede procesar el pago sin conciliación con almacén.'
    default_code = 'conciliacion_pendiente'


class ArchivoInvalidoError(APIException):
    status_code = 400
    default_detail = 'Archivo inválido. Verifique tipo y tamaño.'
    default_code = 'archivo_invalido'
```

---

## 6. PERMISOS RBAC (core/permissions.py)

```python
# core/permissions.py
from rest_framework.permissions import BasePermission


class TienePermiso(BasePermission):
    """
    Permiso genérico basado en código.
    Uso en views:
        permission_classes = [IsAuthenticated, TienePermiso]
        required_permission = 'ventas.crear'
    """
    def has_permission(self, request, view):
        required = getattr(view, 'required_permission', None)
        if not required:
            return True
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.perfil.tiene_permiso(required)


class EsAdmin(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.perfil.rol.codigo == 'admin'


class EsSupervisorOAdmin(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.perfil.rol.codigo in ['admin', 'supervisor', 'gerente']


class EsContador(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.perfil.rol.codigo in ['admin', 'contador']
```
