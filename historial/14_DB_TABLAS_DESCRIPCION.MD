# JSOLUCIONES ERP — DICCIONARIO DE DATOS

> Explicación de cada campo, cada enum, y cada decisión técnica.
> Todo basado en los archivos de contexto, sin inventar.

---

## PARTE 1: DECISIONES TÉCNICAS

### ¿Por qué UUID en vez de SERIAL?

| Aspecto | SERIAL (auto-increment) | UUID |
|---------|------------------------|------|
| Seguridad | IDs predecibles: /api/ventas/1, /api/ventas/2 | IDs impredecibles: no se puede adivinar el siguiente |
| API pública | Un atacante puede iterar /api/clientes/1..1000 | No se puede enumerar recursos |
| Merges de datos | Conflictos al unir 2 bases con mismos IDs | Cero conflictos — cada UUID es globalmente único |
| Futuro multi-instancia | Si algún día se consolidan datos de empresas, hay colisiones | Sin colisiones |
| Performance | Ligeramente más rápido en inserts | 16 bytes vs 4 bytes, pero con los índices es imperceptible |
| Django | `models.AutoField` | `models.UUIDField(default=uuid.uuid4, primary_key=True)` |
| PostgreSQL | `SERIAL` | `gen_random_uuid()` nativo desde v13 |

**Decisión:** UUID. La seguridad en APIs y la compatibilidad futura pesan más que los 12 bytes extra.

### ¿Por qué ENUMs nativos de PostgreSQL?

| Aspecto | VARCHAR + validación en Django | CREATE TYPE ENUM |
|---------|-------------------------------|-----------------|
| Validación | Solo en la app (si alguien inserta directo, no valida) | La DB rechaza valores inválidos |
| Espacio | Almacena el texto completo cada vez | Almacena un integer interno (4 bytes) |
| Typos | 'pendiemte' pasa si no hay CHECK | La DB lo rechaza |
| Django ORM | `CharField(choices=...)` funciona igual con ambos | Igual, Django solo valida al guardar |
| Migración | Agregar valor = nada | `ALTER TYPE enum ADD VALUE 'nuevo_valor'` |

**Decisión:** ENUM nativo. Doble validación (Django + DB). Ahorro de espacio. Imposible insertar basura.

### DB-03: ¿Todas las tablas tienen id, created_at, updated_at?

| Tabla | id | created_at | updated_at | Nota |
|-------|:--:|:----------:|:----------:|------|
| usuarios | UUID ✓ | date_joined ✓ | — | Django usa `date_joined` como equivalente. `last_login` cubre updates. |
| log_actividad | UUID ✓ | ✓ | — | Log inmutable. No se edita. |
| movimientos_stock | UUID ✓ | ✓ | — | Log inmutable. |
| log_envio_nubefact | UUID ✓ | ✓ | — | Log inmutable. |
| seguimiento_pedidos | UUID ✓ | ✓ | — | Log inmutable. |
| evidencias_entrega | UUID ✓ | ✓ | — | Inmutable. |
| whatsapp_mensajes | UUID ✓ | ✓ | — | Inmutable. |
| whatsapp_log | UUID ✓ | ✓ | — | Inmutable. |
| **Las 37 restantes** | UUID ✓ | ✓ | ✓ | Completas DB-03. |

Las 8 tablas sin `updated_at` son logs/registros inmutables: una vez creados, no se editan. Tienen `created_at` para saber cuándo se crearon.

---

## PARTE 2: CATÁLOGO DE ENUMS (33 tipos)

Fuente: `06_CONSTANTES_COMPARTIDAS.md` (core/choices.py)

### ENUMS SUNAT (requeridos por facturación electrónica peruana)

#### 1. `enum_tipo_documento`
**Tabla:** clientes
**Fuente:** `06_CONSTANTES` → TIPO_DOCUMENTO_CHOICES
**Por qué:** SUNAT exige identificar al receptor del comprobante.

| Valor | Significado | Cuándo |
|:-----:|-------------|--------|
| '1' | DNI | Persona natural (boleta) |
| '6' | RUC | Empresa (factura obligatoria) |
| '4' | Carné de Extranjería | Extranjero residente |
| '7' | Pasaporte | Extranjero no residente |
| '0' | Otros | Casos excepcionales |

#### 2. `enum_tipo_comprobante`
**Tablas:** series_comprobante, comprobantes, log_envio_nubefact
**Fuente:** `06_CONSTANTES` → TIPO_COMPROBANTE_CHOICES

| Valor | Significado |
|:-----:|-------------|
| '01' | Factura (cliente con RUC) |
| '03' | Boleta (cliente con DNI o sin documento) |
| '07' | Nota de Crédito (anula/modifica factura/boleta) |
| '08' | Nota de Débito (incrementa valor) |

#### 3. `enum_estado_comprobante`
**Tablas:** comprobantes, notas_credito_debito
**Fuente:** `06_CONSTANTES` → ESTADO_COMPROBANTE_CHOICES
**Por qué:** Ciclo de vida del comprobante ante SUNAT vía Nubefact.

| Valor | Significado |
|-------|-------------|
| pendiente | Creado, aún no enviado a SUNAT |
| aceptado | SUNAT aceptó el comprobante |
| rechazado | SUNAT rechazó (error en datos) |
| observado | SUNAT aceptó con observaciones |
| anulado | Anulado con nota de crédito |
| error | Error de comunicación con Nubefact |
| pendiente_reenvio | Falló, pendiente de reintento (Celery) |

#### 4. `enum_afectacion_igv`
**Tablas:** productos (codigo_afectacion_igv), detalle_comprobantes (tipo_afectacion_igv)
**Fuente:** `06_CONSTANTES` → AFECTACION_IGV_CHOICES
**Por qué:** SUNAT exige clasificar cada item del comprobante.

| Valor | Significado |
|:-----:|-------------|
| '10' | Gravado (se cobra IGV 18%) |
| '20' | Exonerado (no se cobra IGV, pero sí está en el sistema) |
| '30' | Inafecto (fuera del ámbito del IGV) |
| '21' | Gratuito (transferencia gratuita exonerada) |

#### 5. `enum_motivo_nota_credito`
**Tabla:** notas_credito_debito
**Fuente:** `06_CONSTANTES` → MOTIVO_NOTA_CREDITO_CHOICES

| Valor | Significado |
|:-----:|-------------|
| '01' | Anulación de la operación |
| '02' | Anulación por error en RUC |
| '03' | Descuento global |
| '06' | Devolución total o parcial |

#### 6. `enum_motivo_nota_debito`
**Tabla:** notas_credito_debito (cuando tipo_nota = '08')
**Fuente:** `06_CONSTANTES` → MOTIVO_NOTA_DEBITO_CHOICES
**Por qué:** SUNAT exige motivo codificado al emitir nota de débito.

| Valor | Significado |
|:-----:|-------------|
| '01' | Intereses por mora |
| '02' | Aumento en el valor |
| '03' | Penalidades / otros conceptos |

#### 7. `enum_tipo_nota`
**Tabla:** notas_credito_debito
**Fuente:** `06_CONSTANTES` → TIPO_NOTA_CHOICES
| Valor | Significado |
|:-----:|-------------|
| '07' | Nota de Crédito |
| '08' | Nota de Débito |

#### 7. `enum_unidad_medida`
**Tablas:** productos, detalle_comprobantes
**Fuente:** `06_CONSTANTES` → UNIDAD_MEDIDA_CHOICES
**Por qué:** Código SUNAT obligatorio en cada item del comprobante.

| Valor | Significado |
|:-----:|-------------|
| NIU | Unidad |
| KGM | Kilogramo |
| LTR | Litro |
| MTR | Metro |
| BX | Caja |
| DZN | Docena |
| PK | Paquete |
| ZZ | Servicio |

#### 8. `enum_moneda`
**Tablas:** configuracion, comprobantes, ordenes_compra
**Fuente:** `06_CONSTANTES` → MONEDA_CHOICES
| Valor | Significado |
|:-----:|-------------|
| PEN | Soles peruanos (S/) |
| USD | Dólares americanos (US$) |

#### 9. `enum_modo_emision`
**Tabla:** comprobantes
**Fuente:** `06_CONSTANTES` → MODO_EMISION_CHOICES
| Valor | Significado |
|-------|-------------|
| normal | Emisión online (se envía a SUNAT en tiempo real) |
| contingencia | Sin conexión (se envía después, cuando hay internet) |

---

### ENUMS DE NEGOCIO

#### 10. `enum_segmento_cliente`
**Tabla:** clientes
**Fuente:** `06_CONSTANTES` → SEGMENTO_CLIENTE_CHOICES

| Valor | Significado |
|-------|-------------|
| nuevo | Cliente recién registrado |
| frecuente | Compra regularmente |
| vip | Alto valor, trato preferencial |
| credito | Tiene línea de crédito aprobada |
| corporativo | Empresa con contrato |

#### 11. `enum_metodo_pago`
**Tablas:** ventas, cobros, pagos
**Fuente:** `06_CONSTANTES` → METODO_PAGO_CHOICES
**Por qué:** Los 5 métodos comunes en comercio peruano.

| Valor | Significado |
|-------|-------------|
| efectivo | Pago en efectivo |
| tarjeta | Visa/Mastercard (POS) |
| transferencia | Transferencia bancaria |
| yape_plin | Billeteras digitales (Yape, Plin, QR) |
| credito | Venta al crédito (genera cuenta por cobrar) |

#### 12. `enum_tipo_movimiento`
**Tabla:** movimientos_stock
**Fuente:** `06_CONSTANTES` → TIPO_MOVIMIENTO_CHOICES

| Valor | Significado | Genera |
|-------|-------------|--------|
| entrada | Ingreso de stock (compra, devolución de cliente) | +cantidad |
| salida | Egreso de stock (venta, merma) | -cantidad |
| transferencia | De un almacén a otro | -origen, +destino |
| ajuste | Corrección manual (inventario físico) | +/- según caso |
| devolucion | Devolución a proveedor | -cantidad |

#### 13. `enum_referencia_movimiento`
**Tabla:** movimientos_stock (referencia_tipo)
**Fuente:** `06_CONSTANTES` → REFERENCIA_TIPO_CHOICES
**Por qué:** Traza qué documento originó el movimiento.

| Valor | Documento origen |
|-------|-----------------|
| venta | Una venta (detalle_ventas) |
| compra | Una recepción de OC |
| ajuste_manual | Ajuste de inventario manual |
| transferencia | Transferencia entre almacenes |
| devolucion | Devolución a proveedor |

---

### ENUMS DE ESTADOS (flujos de trabajo)

#### 14. `enum_estado_cotizacion`
**Tabla:** cotizaciones
**Fuente:** `06_CONSTANTES` → ESTADO_COTIZACION_CHOICES
**Flujo:** borrador → vigente → aceptada/vencida/rechazada

#### 15. `enum_estado_orden_venta`
**Tabla:** ordenes_venta
**Fuente:** `06_CONSTANTES` → ESTADO_ORDEN_VENTA_CHOICES
**Flujo:** pendiente → confirmada → parcial → completada / cancelada

#### 16. `enum_estado_venta`
**Tabla:** ventas
**Fuente:** `06_CONSTANTES` → ESTADO_VENTA_CHOICES
**Solo 2 valores:** completada / anulada (una venta se completa o se anula con NC)

#### 17. `enum_tipo_venta`
**Tabla:** ventas
**Fuente:** `06_CONSTANTES` → TIPO_VENTA_CHOICES

| Valor | Significado |
|-------|-------------|
| directa | Venta en punto de venta (POS) |
| online | Venta por web/app |
| campo | Vendedor externo (preventa) |

#### 18. `enum_estado_orden_compra`
**Tabla:** ordenes_compra
**Fuente:** `06_CONSTANTES` → ESTADO_OC_CHOICES
**Flujo:** borrador → pendiente_aprobacion → aprobada → enviada → recibida_parcial → recibida → cerrada / cancelada

#### 19. `enum_estado_factura_proveedor`
**Tabla:** facturas_proveedor
**Flujo:** registrada → conciliada → pagada / anulada

#### 20. `enum_tipo_recepcion`
**Tabla:** recepciones
| Valor | Significado |
|-------|-------------|
| total | Se recibió todo lo de la OC |
| parcial | Se recibió solo una parte |

#### 21. `enum_estado_cuenta`
**Tablas:** cuentas_por_cobrar, cuentas_por_pagar
**Fuente:** `06_CONSTANTES` → ESTADO_CUENTA_CHOICES
**Flujo:** pendiente → vencido (automático por fecha) → pagado / refinanciado

#### 22. `enum_estado_asiento`
**Tabla:** asientos_contables
**Flujo:** borrador → confirmado / anulado (con asiento reverso)

#### 23. `enum_tipo_cuenta_contable`
**Tabla:** cuentas_contables
| Valor | Significado |
|-------|-------------|
| activo | Lo que la empresa tiene (caja, banco, inventario) |
| pasivo | Lo que la empresa debe (CxP, préstamos) |
| patrimonio | Capital, reservas, utilidades |
| ingreso | Ventas, servicios |
| gasto | Costos, gastos operativos |

#### 24. `enum_estado_pedido`
**Tablas:** pedidos, seguimiento_pedidos
**Fuente:** `06_CONSTANTES` → ESTADO_PEDIDO_CHOICES
**Flujo:** pendiente → confirmado → despachado → en_ruta → entregado / cancelado / devuelto

#### 25. `enum_prioridad_pedido`
**Tabla:** pedidos
| Valor | Significado |
|-------|-------------|
| normal | Entrega estándar |
| express | Entrega prioritaria |

#### 26. `enum_tipo_evidencia`
**Tabla:** evidencias_entrega
| Valor | Significado |
|-------|-------------|
| foto | Foto del paquete entregado |
| firma | Firma digital del receptor |
| otp | Código de verificación enviado al cliente |

#### 27. `enum_estado_envio_nubefact`
**Tabla:** log_envio_nubefact
| Valor | Significado |
|-------|-------------|
| enviado | Se envió a Nubefact exitosamente |
| error | Falló el envío |
| pendiente | En cola para reintento (Celery) |

---

### ENUMS DE WHATSAPP

#### 28. `enum_estado_mensaje_wa`
**Tabla:** whatsapp_mensajes
**Fuente:** `06_CONSTANTES` → ESTADO_MENSAJE_WA_CHOICES
**Flujo:** en_espera → enviado → entregado → leido / fallido

#### 29. `enum_categoria_plantilla_wa`
**Tabla:** whatsapp_plantillas
**Fuente:** `06_CONSTANTES` → CATEGORIA_PLANTILLA_WA_CHOICES

| Valor | Significado |
|-------|-------------|
| transaccional | Confirmación de pedido, factura, etc. |
| marketing | Ofertas, promociones |
| alerta | Stock bajo, vencimientos, cobranzas |

#### 30. `enum_estado_plantilla_meta`
**Tabla:** whatsapp_plantillas
**Por qué:** Meta revisa y aprueba cada plantilla antes de poder usarla.
**Flujo:** en_revision → aprobada / rechazada

---

### ENUMS DE MEDIA (Cloudflare R2)

#### 31. `enum_entidad_media`
**Tabla:** media_archivos
**Fuente:** `17_INTEGRACION_CLOUDFARE.MD`
**Por qué:** Identifica a qué entidad pertenece un archivo (relación polimórfica).

| Valor | Significado |
|-------|-------------|
| producto | Fotos de producto (galería, múltiples) |
| configuracion | Logo de la empresa |
| perfil_usuario | Avatar del usuario |
| evidencia_entrega | Foto/firma de entrega |
| proveedor | Documentos del proveedor |
| cliente | Documentos del cliente |

#### 32. `enum_tipo_archivo`
**Tabla:** media_archivos
**Fuente:** `17_INTEGRACION_CLOUDFARE.MD`

| Valor | Significado |
|-------|-------------|
| imagen | JPEG, PNG, WebP (fotos, logos, avatares) |
| documento | PDF (contratos, fichas) |
| firma | Firma digital (evidencias de entrega) |

---

## PARTE 3: EXPLICACIÓN CAMPO POR CAMPO

### configuracion

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| ruc | VARCHAR(11) UNIQUE | Identificador fiscal. 11 dígitos. Obligatorio para emitir comprobantes. |
| razon_social | VARCHAR(200) | Nombre legal de la empresa. Aparece en facturas/boletas. |
| nombre_comercial | VARCHAR(200) | Nombre de fantasía. Opcional. |
| direccion | TEXT | Dirección fiscal completa. Obligatoria en comprobantes SUNAT. |
| ubigeo | VARCHAR(6) | Código de ubicación geográfica SUNAT (6 dígitos: depto+prov+dist). |
| departamento, provincia, distrito | VARCHAR(50) | Desglose legible de la ubicación. Para formularios y reportes. |
| telefono | VARCHAR(20) | Contacto. VARCHAR(20) para incluir código país (+51). |
| email | VARCHAR(254) | Correo de la empresa. RFC 5321 define 254 como máximo. |
| logo | VARCHAR(200) NULL | Path de imagen. Nullable porque se puede configurar después. |
| nubefact_token | VARCHAR(200) | Token de autenticación para API Nubefact. Sin esto no se factura. |
| nubefact_url | VARCHAR(500) | URL de la API Nubefact. Default al endpoint real. |
| moneda_principal | enum_moneda | PEN por default. Configurable si opera en dólares. |
| igv_porcentaje | DECIMAL(5,2) | 18.00 hoy en Perú. Se almacena porque puede cambiar por ley. |

### usuarios

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| email | VARCHAR(254) UNIQUE | USERNAME_FIELD. Login con email, sin username. |
| password | VARCHAR(128) | Hash del password. Django usa PBKDF2/Argon2 que genera ~128 chars. |
| first_name, last_name | VARCHAR(150) | Datos del usuario. 150 = default de Django AbstractUser. |
| is_active | BOOLEAN | Soft delete. FALSE = usuario desactivado, no puede loguearse. |
| is_staff | BOOLEAN | Acceso al admin de Django. Solo para admins del sistema. |
| is_superuser | BOOLEAN | Todos los permisos. Solo para el superadmin inicial. |
| date_joined | TIMESTAMPTZ | Equivalente a created_at en Django. Cuándo se registró. |
| last_login | TIMESTAMPTZ NULL | Django lo actualiza automáticamente en cada login. |

### roles

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| codigo | VARCHAR(30) UNIQUE | Identificador programático: 'admin', 'vendedor', 'cajero'. Se usa en código. |
| nombre | VARCHAR(100) | Nombre legible: 'Administrador', 'Vendedor'. Se muestra en UI. |
| descripcion | TEXT | Explicación del rol. Para documentación interna. |
| is_active | BOOLEAN | Soft delete. Permite desactivar un rol sin borrarlo. |

### permisos

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| codigo | VARCHAR(50) UNIQUE | Identificador programático: 'ventas.crear', 'inventario.ajustar'. Se usa en decoradores. |
| nombre | VARCHAR(100) | Nombre legible para la UI de asignación de permisos. |
| modulo | VARCHAR(30) | Agrupa permisos por módulo (ventas, inventario, facturacion). Para filtrar en UI. |

### perfiles_usuario

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| usuario_id | UUID UNIQUE FK | 1:1 con usuarios. Separa datos de autenticación (Django) de datos de negocio. |
| rol_id | UUID FK RESTRICT | Rol asignado. RESTRICT impide borrar rol que tiene usuarios asignados. |
| telefono | VARCHAR(20) | Contacto del empleado. Para comunicación interna. |
| avatar | VARCHAR(200) NULL | Path de imagen de perfil. Nullable, se sube después. |

### log_actividad

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| usuario_id | UUID FK SET NULL | Quién hizo la acción. SET NULL si se borra el perfil (el log se conserva). |
| accion | VARCHAR(50) | Qué hizo: 'login', 'crear_venta', 'anular_comprobante'. |
| modulo | VARCHAR(30) | En qué módulo: 'ventas', 'inventario'. Para filtrar. |
| detalle | TEXT | Info adicional: "Venta #V-0045 por S/1,500.00". |
| ip_address | VARCHAR(45) | IP del usuario. 45 chars cubre IPv6. Para seguridad. |

### clientes

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| tipo_documento | enum_tipo_documento | SUNAT exige identificar al receptor. Factura = RUC obligatorio. |
| numero_documento | VARCHAR(15) | DNI=8 dígitos, RUC=11, CE=12, Pasaporte=variable. 15 cubre todos. |
| razon_social | VARCHAR(200) | Nombre legal. Aparece en comprobantes. |
| nombre_comercial | VARCHAR(200) | Nombre de fantasía. Opcional. Para búsquedas. |
| ubigeo | VARCHAR(6) | Código SUNAT de ubicación del cliente. Para comprobantes. |
| segmento | enum_segmento_cliente | Clasificación comercial. Para reportes y políticas de descuento/crédito. |
| limite_credito | DECIMAL(12,2) | Máximo que puede deber. Si metodo_pago='credito', se valida contra esto. |
| creado_por_id, actualizado_por_id | UUID FK | Auditoría: quién creó y quién editó por última vez. |

### proveedores

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| ruc | VARCHAR(11) UNIQUE | Todo proveedor en Perú tiene RUC. Es la clave para facturación. |
| contacto_nombre, contacto_telefono | VARCHAR | Persona de contacto. Para comunicación de OC. |
| condicion_pago_dias | INTEGER DEFAULT 0 | Días de crédito: 0=contado, 30, 60, 90. Alimenta cuentas por pagar. |
| calificacion | INTEGER DEFAULT 3 | Evaluación 1-5. Para comparar proveedores en decisiones de compra. |

### productos

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| sku | VARCHAR(50) UNIQUE | Código interno del producto. Obligatorio para operación. |
| codigo_barras | VARCHAR(50) | Para lectura con escáner en POS. Opcional (no todos tienen). |
| categoria_id | UUID FK SET NULL | Organización. SET NULL si se borra la categoría (producto queda sin categoría). |
| unidad_medida | enum_unidad_medida | Código SUNAT. Obligatorio en comprobantes electrónicos. |
| precio_compra | DECIMAL(12,4) | Costo de adquisición. 4 decimales por DB-09. |
| precio_venta | DECIMAL(12,4) NOT NULL | Precio de venta. Sin default — obligatorio definirlo. |
| codigo_afectacion_igv | enum_afectacion_igv | Clasificación fiscal SUNAT. Se envía a Nubefact en cada item. |
| stock_minimo, stock_maximo | DECIMAL(12,2) | Umbrales para alertas automáticas de reposición (Celery). |
| requiere_lote | BOOLEAN | Si TRUE, al vender/mover stock se debe indicar el lote. |

### stock

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| producto_id + almacen_id | UUID UNIQUE | Stock por combinación producto+almacén. Un producto puede estar en varios almacenes. |
| cantidad | DECIMAL(12,2) | Stock actual. Se actualiza automáticamente con cada movimiento. |

### movimientos_stock

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| tipo_movimiento | enum_tipo_movimiento | Qué tipo de movimiento es. |
| cantidad | DECIMAL(12,2) | Cuánto se movió. Siempre positivo; el tipo indica si suma o resta. |
| almacen_destino_id | UUID FK NULL | Solo para transferencias. El almacén origen es `almacen_id`. |
| referencia_tipo + referencia_id | ENUM + UUID | Trazabilidad: qué documento originó este movimiento. |
| lote_id | UUID FK NULL | Si el producto usa lotes, indica de cuál lote se movió. |
| motivo | TEXT | Razón del movimiento. Obligatorio en ajustes manuales. |

### ventas

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| numero | VARCHAR(20) | Número auto-generado: V-0001, V-0002. Para referencia interna. |
| hora | TIME NULL | Hora de la venta. Separado de fecha para reportes por horario. |
| orden_origen_id | UUID FK NULL | Si la venta viene de una orden, se traza. NULL = venta directa. |
| sucursal | VARCHAR(100) | Desde qué sucursal se vendió. Para reportes por local. |
| caja | VARCHAR(50) | Número de caja. Para arqueo de caja. |
| tipo_venta | enum_tipo_venta | Canal de venta. |
| metodo_pago | enum_metodo_pago | Cómo pagó el cliente. |
| total_gravada | DECIMAL(12,2) | Base imponible (sin IGV). |
| total_igv | DECIMAL(12,2) | Monto del IGV. |
| total_descuento | DECIMAL(12,2) | Descuentos aplicados. |
| total_venta | DECIMAL(12,2) | Total final = gravada + igv - descuento. |
| comprobante_id | UUID FK NULL | FK al comprobante generado. NULL si aún no se emitió. |

### comprobantes

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| serie + numero | VARCHAR(4) + INTEGER | Numeración SUNAT: F001-1, F001-2, B001-1. UNIQUE constraint. |
| total_gravada, total_exonerada, total_inafecta | DECIMAL(12,2) | SUNAT exige desglosar por tipo de afectación. |
| total_igv, total_venta | DECIMAL(12,2) | Totales del comprobante. |
| estado_sunat | enum_estado_comprobante | Estado ante SUNAT. |
| pdf_url, xml_url, cdr_url | VARCHAR(500) | URLs que devuelve Nubefact. Para descargar el comprobante. |
| hash_sunat | TEXT | Hash de firma digital. Para QR del comprobante impreso. |
| qr_sunat | TEXT | Contenido del QR. SUNAT lo exige en la representación impresa. |
| nubefact_request | JSONB | JSON exacto enviado a Nubefact. Para debugging. |
| nubefact_response | JSONB | Respuesta completa de Nubefact. Para debugging y auditoría. |
| modo_emision | enum_modo_emision | Normal = online. Contingencia = sin internet, se envía después. |

### notas_credito_debito

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| comprobante_origen_id | UUID FK RESTRICT | Comprobante que se anula/modifica. RESTRICT: no se puede borrar un comprobante que tiene notas. |
| tipo_nota | enum_tipo_nota | '07' = Nota de Crédito, '08' = Nota de Débito. |
| motivo_codigo_nc | enum_motivo_nota_credito NULL | Motivo SUNAT para NC: anulación, error RUC, descuento, devolución. Solo se llena si tipo_nota = '07'. |
| motivo_codigo_nd | enum_motivo_nota_debito NULL | Motivo SUNAT para ND: intereses, aumento valor, penalidades. Solo se llena si tipo_nota = '08'. |
| motivo_descripcion | TEXT | Descripción libre del motivo. SUNAT lo incluye en el XML. |
| estado_sunat | enum_estado_comprobante | Mismo ciclo de vida que comprobantes (pendiente → aceptado/rechazado). |
| CHECK constraint | `chk_motivo_nota` | Garantiza que exactamente uno de los dos motivos esté presente según tipo_nota. |

### detalle_recepciones

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| recepcion_id | UUID FK CASCADE | Cabecera de la recepción. Si se borra la recepción, se borran los detalles. |
| detalle_orden_compra_id | UUID FK PROTECT | Línea de la OC que se recibe. PROTECT: no se puede borrar la línea de OC si ya tiene recepciones. |
| producto_id | UUID FK PROTECT | Producto recibido. Redundante con OC pero necesario para generar movimiento de stock directamente. |
| cantidad_recibida | DECIMAL(12,2) | Unidades recibidas de este producto en esta recepción. Se suma a `detalle_ordenes_compra.cantidad_recibida`. |
| lote_id | UUID FK NULL | Si `producto.requiere_lote = TRUE`, se asigna/crea el lote al recibir. |
| observaciones | TEXT | Daños, diferencias vs OC, notas del almacenero. |

### cuentas_por_cobrar / cuentas_por_pagar

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| monto_original | DECIMAL(12,2) | Cuánto se debía originalmente. |
| monto_pendiente | DECIMAL(12,2) | Cuánto falta por pagar/cobrar. Se reduce con cada pago/cobro parcial. |
| fecha_emision | DATE | Cuándo se creó la deuda. |
| fecha_vencimiento | DATE | Cuándo vence. Tarea Celery marca como 'vencido' automáticamente. |

### asientos_contables

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| numero | VARCHAR(20) | Número correlativo del asiento: A-0001, A-0002. |
| centro_costo | VARCHAR(100) NULL | Etiqueta libre para centro de costo (ej: "Sucursal Lima", "Proyecto X"). VARCHAR en vez de FK porque no existe tabla de centros de costo — sería overengineering para el alcance actual. |
| referencia_tipo + referencia_id | VARCHAR + UUID | Qué originó el asiento: venta #X, pago #Y, ajuste. |
| estado | enum_estado_asiento | borrador (editable) → confirmado (inmutable) → anulado (con reverso). |

### pedidos (distribución)

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| direccion_entrega | TEXT NOT NULL | A dónde hay que entregar. Puede diferir de la dirección del cliente. |
| latitud, longitud | DECIMAL(10,7) | Coordenadas para mapa y seguimiento GPS. 7 decimales = ~1cm precisión. |
| estado | enum_estado_pedido | Ciclo de vida de la entrega. |
| transportista_id | UUID FK NULL | Quién lo entrega. NULL si aún no se asignó. |
| fecha_estimada_entrega | DATE NULL | Cuándo se espera entregar. |
| fecha_entrega_real | DATE NULL | Cuándo se entregó realmente. Para calcular cumplimiento. |
| prioridad | enum_prioridad_pedido | normal o express. |

### media_archivos

| Campo | Tipo | Por qué existe |
|-------|------|----------------|
| entidad_tipo | enum_entidad_media | A qué tipo de entidad pertenece: producto, configuracion, perfil_usuario, etc. |
| entidad_id | UUID NOT NULL | ID de la entidad. No es FK formal (polimórfica) — se valida en Django. |
| tipo_archivo | enum_tipo_archivo | imagen, documento o firma. Para filtrar y validar en frontend. |
| nombre_original | VARCHAR(255) | Nombre que subió el usuario. Se muestra en UI, no se usa como key. |
| r2_key | VARCHAR(500) UNIQUE | Key en el bucket R2: `productos/uuid.webp`. Único para evitar sobreescritura. |
| url_publica | VARCHAR(500) | URL completa del CDN: `https://cdn.empresa.com/productos/uuid.webp`. El frontend carga directo. |
| mime_type | VARCHAR(100) | `image/jpeg`, `image/webp`, `application/pdf`. Para validación y Content-Type. |
| tamano_bytes | INTEGER CHECK > 0 | Peso del archivo. Para control de cuota y validación. |
| es_principal | BOOLEAN DEFAULT FALSE | Marca la foto principal de un producto. Para mostrar en listados sin cargar todas. |
| orden | INTEGER DEFAULT 0 | Orden en la galería de fotos de un producto. |
| alt_text | VARCHAR(200) | Texto alternativo para accesibilidad. |
| subido_por_id | UUID FK SET NULL | Quién subió el archivo. SET NULL si se borra el perfil. |

---

## PARTE 4: CONSTRAINTS DE INTEGRIDAD

> Fuente: `16_REVISION_TECNICA.MD` — validados y aplicados al SQL.

### UNIQUE constraints adicionales

| Tabla | Constraint | Por qué |
|-------|-----------|---------|
| notas_credito_debito | UNIQUE(tipo_nota, serie, numero) | SUNAT rechaza comprobantes con serie+numero duplicados |
| cotizaciones | UNIQUE(numero) | Correlativo auto-generado no puede repetirse |
| ordenes_venta | UNIQUE(numero) | Idem |
| ventas | UNIQUE(numero) | Idem |
| ordenes_compra | UNIQUE(numero) | Idem |
| pedidos | UNIQUE(numero) | Idem |
| facturas_proveedor | UNIQUE(proveedor_id, numero_factura) | Mismo proveedor no puede tener 2 facturas con mismo numero |
| clientes | UNIQUE parcial (tipo_documento, numero_documento) WHERE is_active=TRUE | Evita duplicados pero permite re-registrar clientes desactivados |

### CHECK constraints

| Tabla | Constraint | Regla |
|-------|-----------|-------|
| detalle_cotizaciones, detalle_ordenes_venta, detalle_ventas, detalle_comprobantes, detalle_ordenes_compra, movimientos_stock | cantidad > 0 | Cantidades siempre positivas |
| detalle_recepciones | cantidad_recibida > 0 | Idem |
| detalle_cotizaciones, detalle_ordenes_venta, detalle_ventas, detalle_comprobantes, detalle_ordenes_compra | precio_unitario > 0 | Precios siempre positivos |
| detalle_asientos | debe >= 0 AND haber >= 0 AND NOT (debe > 0 AND haber > 0) | Partida doble: solo un lado por linea |
| stock | cantidad >= 0 | Stock no puede ser negativo |
| proveedores | calificacion BETWEEN 1 AND 5 | Rango definido en doc 03 |
| cobros | monto > 0 | Cobro de 0 o negativo no existe |
| pagos | monto > 0 | Pago de 0 o negativo no existe |

### Singleton

| Tabla | Mecanismo | Por qué |
|-------|-----------|---------|
| configuracion | Columna `singleton BOOLEAN DEFAULT TRUE` + UNIQUE + CHECK | Solo puede existir 1 fila. Doc 01 §4.2. |

## PARTE 5: INDICES (104 índices)

> PostgreSQL NO crea índices automáticos para columnas FK.
> Sin índices en FKs, los JOINs y CASCADE deletes hacen sequential scan.
> Todos los índices están definidos en `SQL_JSOLUCIONES.sql`.

### Resumen por módulo

| Módulo | Índices inline | Índices adicionales | Total |
|--------|:--------------:|:-------------------:|:-----:|
| Clientes | 2 (documento, razon_social) | 2 (creado_por, segmento) + 1 UNIQUE parcial | 5 |
| Proveedores | 0 | 1 (razon_social) | 1 |
| Inventario | 6 (productos×3, movimientos×3) | 8 (categorias, productos, lotes×3, stock, movimientos×3) | 14 |
| Ventas | 4 (ventas×3, detalle_ventas×1) | 17 (cotizaciones×4, det_cot×2, OV×5, det_OV×2, ventas×3, det_ventas×2) | 21 |
| Facturación | 2 (comprobantes×2) | 8 (comprobantes×3, det_comprobantes×1, notas_cd×3, log_nubefact×2) | 10 |
| Compras | 0 | 13 (OC×4, det_OC×2, facturas_prov×3, recepciones×2, det_recepciones×3) | 13 |
| Finanzas | 0 | 15 (CxC×3, CxP×3, cobros×2, pagos×2, cuentas_contables×2, asientos×3, det_asientos×2) | 15 |
| Distribución | 0 | 6 (pedidos×4, seguimiento×1, evidencias×1) | 6 |
| WhatsApp | 0 | 5 (mensajes×4, log×1) | 5 |
| Media | 2 (entidad, principal) | 1 (subido_por) | 3 |
| RBAC | 0 | 6 (rol_permisos×2, perfiles×1, log_actividad×3) | 6 |
| **TOTAL** | **16** | **88** | **104** |

### Índices más críticos (performance)

| Índice | Tabla | Columnas | Por qué es crítico |
|--------|-------|----------|-------------------|
| idx_det_asientos_cuenta | detalle_asientos | cuenta_contable_id | Libro Mayor: lista todos los movimientos de una cuenta |
| idx_cxc_estado_vencimiento | cuentas_por_cobrar | estado, fecha_vencimiento | Módulo cobranzas: listar deudas pendientes/vencidas |
| idx_cxp_estado_vencimiento | cuentas_por_pagar | estado, fecha_vencimiento | Módulo pagos: listar deudas pendientes/vencidas |
| idx_det_cotizaciones_cotizacion | detalle_cotizaciones | cotizacion_id | CASCADE delete y carga de detalle |
| idx_det_ov_orden | detalle_ordenes_venta | orden_venta_id | CASCADE delete y carga de detalle |
| idx_det_oc_orden | detalle_ordenes_compra | orden_compra_id | CASCADE delete y carga de detalle |
| idx_det_comprobantes_comprobante | detalle_comprobantes | comprobante_id | CASCADE delete y carga de detalle |
| idx_det_recepciones_recepcion | detalle_recepciones | recepcion_id | CASCADE delete y carga de detalle |
| idx_cotizaciones_estado_fecha | cotizaciones | estado, fecha_emision | Listado filtrado de cotizaciones |
| idx_oc_estado_fecha | ordenes_compra | estado, fecha | Listado filtrado de OC |
| idx_pedidos_estado_fecha | pedidos | estado, fecha | Dashboard de distribución |

### Convención de nombres

- **Inline (junto al CREATE TABLE):** `idx_<tabla>_<columna(s)>` — índices que existían desde el diseño inicial
- **Adicionales (sección separada):** `idx_<abreviatura>_<columna>` — abreviaturas: det=detalle, ov=ordenes_venta, oc=ordenes_compra, cxc=cuentas_por_cobrar, cxp=cuentas_por_pagar, cc=cuentas_contables, fp=facturas_proveedor, wa=whatsapp, mov=movimientos
- **Parciales:** `WHERE` clause para indices condicionales (ej: `idx_clientes_doc_unico WHERE is_active = TRUE`)

---

## PARTE 6: ARCHIVOS QUE NECESITAN ACTUALIZACIÓN

Con el cambio a UUID, estos archivos necesitan ajuste menor:

| Archivo | Qué cambiar |
|---------|-------------|
| `09_PROCESOS_DATABASE.md` §4 | Modelo Empresa: `id = models.UUIDField(primary_key=True, default=uuid.uuid4)` en vez de `SERIAL` implícito |
| `09_PROCESOS_DATABASE.md` §2.4 | Modelo Usuario: agregar `id = models.UUIDField(primary_key=True, default=uuid.uuid4)` |
| `03_REGLAS_BASE_DATOS.md` regla DB-03 | Actualizar: "id (UUID PK)" en vez de "id (PK auto)" |
| `06_CONSTANTES_COMPARTIDAS.md` §2 | En los mixins, las FKs ya apuntan a UUID (no cambia el código Django, solo el tipo) |

El SQL ya refleja todos estos cambios. Los archivos .md son documentación — cuando comencemos a implementar, actualizamos.