# JSOLUCIONES ERP — SUSTENTO DE TABLAS (v2)

> 47 tablas. Nombres limpios en español. Cada tabla justificada con su fuente.
>
> En Django se controla el nombre con `db_table` en el Meta del modelo:
> ```python
> class Meta:
>     db_table = 'ventas'  # ← nombre limpio, no "ventas_venta"
> ```
>
> **Reglas cumplidas en cada tabla:**
> - DB-03: id (PK serial), created_at, updated_at (excepto logs inmutables que solo tienen created_at)
> - DB-05: Toda FK con ON DELETE explícito
> - DB-08: Dinero → DECIMAL(12,2)
> - DB-09: Precio unitario → DECIMAL(12,4)
> - DB-10: Soft delete con is_active donde aplica
> - DB-14: Texto largo → TEXT, texto corto → VARCHAR(n)
> - DB-15: Cero FLOAT. Todo DECIMAL.

---

## MAPA DE NOMBRES: DBML anterior → SQL nuevo

| DBML anterior (estilo Django) | SQL nuevo (limpio) | Tabla # |
|---|----|:---:|
| empresa | configuracion | 1 |
| usuarios | usuarios | 2 |
| usuarios_rol | roles | 3 |
| usuarios_permiso | permisos | 4 |
| usuarios_rol_permisos | rol_permisos | 5 |
| usuarios_perfilusuario | perfiles_usuario | 6 |
| usuarios_logactividad | log_actividad | 7 |
| clientes_cliente | clientes | 8 |
| proveedores_proveedor | proveedores | 9 |
| inventario_categoria | categorias | 10 |
| inventario_producto | productos | 11 |
| inventario_almacen | almacenes | 12 |
| inventario_stock | stock | 13 |
| inventario_movimientostock | movimientos_stock | 14 |
| inventario_lote | lotes | 15 |
| ventas_cotizacion | cotizaciones | 16 |
| ventas_detallecotizacion | detalle_cotizaciones | 17 |
| ventas_ordenventa | ordenes_venta | 18 |
| ventas_detalleordenventa | detalle_ordenes_venta | 19 |
| ventas_venta | ventas | 20 |
| ventas_detalleventa | detalle_ventas | 21 |
| facturacion_seriecomprobante | series_comprobante | 22 |
| facturacion_comprobante | comprobantes | 23 |
| facturacion_detallecomprobante | detalle_comprobantes | 24 |
| facturacion_notacreditodebito | notas_credito_debito | 25 |
| facturacion_logenvionubefact | log_envio_nubefact | 26 |
| compras_ordencompra | ordenes_compra | 27 |
| compras_detalleordencompra | detalle_ordenes_compra | 28 |
| compras_facturaproveedor | facturas_proveedor | 29 |
| compras_recepcion | recepciones | 30 |
| finanzas_cuentaporcobrar | cuentas_por_cobrar | 31 |
| finanzas_cuentaporpagar | cuentas_por_pagar | 32 |
| finanzas_cobro | cobros | 33 |
| finanzas_pago | pagos | 34 |
| finanzas_cuentacontable | cuentas_contables | 35 |
| finanzas_asientocontable | asientos_contables | 36 |
| finanzas_detalleasiento | detalle_asientos | 37 |
| distribucion_transportista | transportistas | 38 |
| distribucion_pedido | pedidos | 39 |
| distribucion_seguimientopedido | seguimiento_pedidos | 40 |
| distribucion_evidenciaentrega | evidencias_entrega | 41 |
| whatsapp_configuracion | whatsapp_configuracion | 42 |
| whatsapp_plantilla | whatsapp_plantillas | 43 |
| whatsapp_mensaje | whatsapp_mensajes | 44 |
| whatsapp_logwhatsapp | whatsapp_log | 45 |
| (nueva) | detalle_recepciones | 46 |
| (nueva) | media_archivos | 47 |

---

## 1. CONFIGURACIÓN (1 tabla)

### `configuracion`
**Fuente:** `01_CORE_PROYECTO.md` §4.2 + `09_PROCESOS_DATABASE.md` §4
**Por qué existe:** Almacena los datos de la empresa que usa esta instancia: RUC, razón social, tokens de Nubefact y WhatsApp, porcentaje de IGV. Solo 1 fila.

| Campo | Tipo | Por qué |
|-------|------|---------|
| ruc | VARCHAR(11) UNIQUE | Identificador fiscal. Obligatorio para emitir comprobantes SUNAT. |
| razon_social | VARCHAR(200) | Nombre legal. Aparece en toda factura/boleta. |
| nombre_comercial | VARCHAR(200) | Nombre de fantasía (opcional). |
| direccion, ubigeo, departamento, provincia, distrito | TEXT/VARCHAR | Dirección fiscal. Obligatoria en comprobantes SUNAT. |
| nubefact_token, nubefact_url | VARCHAR | Credenciales para la API de Nubefact (facturación electrónica). |
| moneda_principal | VARCHAR(3) DEFAULT 'PEN' | Soles peruanos. Configurable por si opera en USD. |
| igv_porcentaje | DECIMAL(5,2) DEFAULT 18.00 | IGV vigente en Perú = 18%. Se almacena porque puede cambiar. |

---

## 2. USUARIOS Y RBAC (6 tablas)

### `usuarios`
**Fuente:** `09_PROCESOS_DATABASE.md` §2.4
**Por qué existe:** Django requiere un modelo de usuario para autenticación. AbstractUser con email como login porque en empresas peruanas el email es el identificador estándar.

### `roles`
**Fuente:** `02_REGLAS_BACKEND_v2.md` §Roles
**Por qué existe:** 8 roles base del ERP: admin, gerente, supervisor, vendedor, cajero, almacenero, contador, repartidor. Cada rol agrupa permisos. Custom porque Django `auth_group` no tiene permisos por módulo ERP.

### `permisos`
**Fuente:** `06_CONSTANTES_COMPARTIDAS.md` + `02_REGLAS_BACKEND_v2.md`
**Por qué existe:** 40+ permisos granulares: `ventas.crear`, `ventas.anular`, `inventario.ajustar`, etc. Se usan en backend (proteger endpoints) y frontend (mostrar/ocultar menú).

### `rol_permisos`
**Por qué existe:** Tabla M2M estándar. Un rol tiene muchos permisos, un permiso pertenece a muchos roles.

### `perfiles_usuario`
**Fuente:** `09_PROCESOS_DATABASE.md` §3
**Por qué existe:** Extiende `usuarios` con datos de negocio: rol asignado, teléfono, avatar. Separado porque `usuarios` es de autenticación (Django) y el perfil es lógica de negocio.

### `log_actividad`
**Fuente:** `09_PROCESOS_DATABASE.md` §3
**Por qué existe:** Auditoría. Registra cada acción relevante (login, crear venta, anular comprobante). Solo tiene `created_at` porque es inmutable — nunca se edita ni borra.

---

## 3. CLIENTES (1 tabla)

### `clientes`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.2
**Por qué existe:** Sin clientes no hay ventas ni facturación.

| Campo clave | Por qué |
|-------------|---------|
| tipo_documento + numero_documento | SUNAT exige identificar al cliente. Factura = RUC obligatorio. Boleta = DNI o sin documento. |
| segmento | Clasificación comercial (nuevo, frecuente, VIP, crédito) para reportes y políticas. |
| limite_credito | Controla el máximo que puede deber un cliente en ventas al crédito. |

---

## 4. PROVEEDORES (1 tabla)

### `proveedores`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.3
**Por qué existe:** Sin proveedores no hay compras.

| Campo clave | Por qué |
|-------------|---------|
| condicion_pago_dias | Días de crédito del proveedor (30, 60, 90). Alimenta cuentas por pagar. |
| calificacion | Evaluación 1-5 para decisiones de recompra. |

---

## 5. INVENTARIO (6 tablas)

### `categorias`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.1
**Por qué existe:** Organizar productos. Self FK (`categoria_padre_id`) para jerarquías: Electrónica → Celulares → Samsung.

### `productos`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.1
**Por qué existe:** Tabla central. Sin productos no hay ventas, compras, ni stock.

| Campo clave | Por qué |
|-------------|---------|
| sku | Identificador único interno del producto. |
| codigo_barras | Lectura con escáner en POS. |
| unidad_medida | Código SUNAT (NIU=unidad, KGM=kilo). Obligatorio en comprobantes electrónicos. |
| precio_compra / precio_venta | DECIMAL(12,4) — 4 decimales por regla DB-09. |
| codigo_afectacion_igv | 10=gravado, 20=exonerado, 30=inafecto. SUNAT lo exige por item. |
| stock_minimo / stock_maximo | Para alertas automáticas de reposición (tarea Celery). |
| requiere_lote | Activa trazabilidad por lote (alimentos, medicinas). |

### `almacenes`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.1
**Por qué existe:** Una empresa puede tener varios almacenes. Stock se calcula por producto + almacén.

### `stock`
**Fuente:** `09_PROCESOS_DATABASE.md` §3
**Por qué existe:** Tabla desnormalizada con el stock actual por producto+almacén. Evita recalcular sumando movimientos en cada consulta. UNIQUE(producto_id, almacen_id).

### `movimientos_stock`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.1 + §6.1
**Por qué existe:** Log inmutable de TODO lo que afecta stock. NUNCA se borra (regla §7). Cada venta, compra, ajuste genera un movimiento. Solo tiene `created_at` (inmutable).

| Campo clave | Por qué |
|-------------|---------|
| referencia_tipo + referencia_id | Patrón genérico para trazar el origen: "venta #45", "OC #12", "ajuste manual". |
| 3 índices compuestos | Alto volumen — cumple regla DB-06. |

### `lotes`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.1
**Por qué existe:** Para productos con `requiere_lote = TRUE`. Trazabilidad por lote y control de vencimiento.

---

## 6. VENTAS (6 tablas)

### `cotizaciones` + `detalle_cotizaciones`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.4
**Por qué existe:** Flujo comercial: Cotización → Orden → Venta. Estados: borrador → vigente → aceptada → vencida. `fecha_validez` permite vencer automáticamente (Celery).

### `ordenes_venta` + `detalle_ordenes_venta`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.4
**Por qué existe:** Confirma el pedido del cliente antes de facturar. `cotizacion_origen_id` traza el origen. `cantidad_entregada` permite entregas parciales.

### `ventas` + `detalle_ventas`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.4
**Por qué existe:** Core del negocio. NUNCA se borra una vez emitida con comprobante.

| Campo clave | Por qué |
|-------------|---------|
| tipo_venta | directa (POS), online, campo (vendedor externo). |
| metodo_pago | efectivo, tarjeta, transferencia, yape_plin, crédito. Los 5 métodos comunes en Perú. |
| comprobante_id FK | Cada venta genera factura o boleta vía Nubefact. |
| 3 índices compuestos | Alto volumen — cumple DB-06. |

---

## 7. FACTURACIÓN ELECTRÓNICA (5 tablas)

### `series_comprobante`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.5
**Por qué existe:** SUNAT exige series (F001 facturas, B001 boletas). `correlativo_actual` se auto-incrementa.

### `comprobantes` + `detalle_comprobantes`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.5 + `01_CORE_PROYECTO.md` §8
**Por qué existe:** Documento fiscal emitido ante SUNAT vía Nubefact. NUNCA se borra.

| Campo clave | Por qué |
|-------------|---------|
| estado_sunat | Ciclo de vida: pendiente → aceptado → rechazado → observado → anulado. |
| pdf_url, xml_url, cdr_url | URLs que devuelve Nubefact al emitir. |
| nubefact_request / response | JSONB para auditoría y debugging. |
| tipo_afectacion_igv (detalle) | Código SUNAT por item: 10=gravado, 20=exonerado, 30=inafecto. |
| UNIQUE(tipo, serie, numero) | Garantiza unicidad del comprobante. |

### `notas_credito_debito`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.5
**Por qué existe:** SUNAT no permite borrar facturas. Para anular o corregir se emite nota de crédito (07) o débito (08). `motivo_codigo_nc` / `motivo_codigo_nd` = código SUNAT del motivo según tipo de nota (CHECK constraint garantiza que solo uno aplique).

### `log_envio_nubefact`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.5
**Por qué existe:** Cada intento de envío a la API de Nubefact. Si falla, `intentos` cuenta reintentos. Request/response para debugging. Inmutable.

---

## 8. COMPRAS (5 tablas)

### `ordenes_compra` + `detalle_ordenes_compra`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.6
**Por qué existe:** Gestión de compras a proveedores. `cantidad_recibida` en detalle permite recepciones parciales.

### `facturas_proveedor`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.6
**Por qué existe:** La factura que envía el proveedor. Se concilia contra la OC. Alimenta cuentas por pagar.

### `recepciones`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.6
**Por qué existe:** Registro de recepción física de mercadería. Total o parcial. Genera movimientos_stock tipo "entrada".

### `detalle_recepciones`
**Fuente:** Derivada de `recepciones` + `detalle_ordenes_compra`
**Por qué existe:** Sin detalle, una recepción no sabe QUÉ productos se recibieron ni en qué cantidad. Necesario para actualizar `cantidad_recibida` en `detalle_ordenes_compra` y generar `movimientos_stock` por producto.

| Campo clave | Por qué |
|-------------|---------|
| recepcion_id FK | Cabecera de la recepción. CASCADE. |
| detalle_orden_compra_id FK | Línea de la OC que se está recibiendo. PROTECT. |
| producto_id FK | Redundante con la OC pero necesario para generar movimiento de stock directamente. PROTECT. |
| cantidad_recibida | Cuántas unidades de este producto se recibieron en esta recepción. |
| lote_id FK NULL | Si el producto `requiere_lote`, se asigna el lote al recibir. |
| observaciones | Daños, diferencias, etc. |

---

## 9. FINANZAS (7 tablas)

### `cuentas_por_cobrar`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.7
**Por qué existe:** Se genera automáticamente en ventas al crédito. `monto_pendiente` se reduce con cada cobro.

### `cuentas_por_pagar`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.7
**Por qué existe:** Se genera al registrar factura de proveedor con crédito. `monto_pendiente` se reduce con cada pago.

### `cobros` + `pagos`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.7
**Por qué existe:** Registran cada pago/cobro parcial o total. Un cliente puede pagar 50% hoy, 50% el mes que viene.

### `cuentas_contables`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.7
**Por qué existe:** Plan contable jerárquico (activo, pasivo, patrimonio, ingreso, gasto). Necesario para asientos y reportes tributarios.

### `asientos_contables` + `detalle_asientos`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.7
**Por qué existe:** Registro contable de partida doble. Se genera automáticamente con ventas, compras, cobros, pagos. NUNCA se borra — solo se anula con asiento reverso.

---

## 10. DISTRIBUCIÓN (4 tablas)

### `transportistas`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.8
**Por qué existe:** Registro de transportistas disponibles para entregas.

### `pedidos`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.8
**Por qué existe:** Cada venta que requiere entrega genera un pedido. Estados: pendiente → despachado → en_ruta → entregado.

### `seguimiento_pedidos`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.8
**Por qué existe:** Log de eventos del pedido con lat/long. Permite seguimiento público vía URL. Inmutable.

### `evidencias_entrega`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.8
**Por qué existe:** Prueba de entrega: foto, firma digital, código OTP. Protección legal. Inmutable.

---

## 11. WHATSAPP (4 tablas)

### `whatsapp_configuracion`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.9
**Por qué existe:** Tokens y config de Meta Cloud API. **Fuente única** de credenciales WA (phone_number_id, token_acceso, business_id). No se duplican en `configuracion`.

### `whatsapp_plantillas`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.9
**Por qué existe:** Meta exige plantillas pre-aprobadas para WhatsApp Business. `estado_meta` = en_revision/aprobada/rechazada.

### `whatsapp_mensajes`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.9
**Por qué existe:** Cada mensaje enviado. `referencia_tipo + referencia_id` traza el origen. Inmutable.

### `whatsapp_log`
**Fuente:** `03_REGLAS_BASE_DATOS.md` §5.9
**Por qué existe:** Request/response crudo de cada llamada a Meta. Para debugging. Inmutable.

---

## 12. MEDIA / ARCHIVOS — Cloudflare R2 (1 tabla)

### `media_archivos`
**Fuente:** `17_INTEGRACION_CLOUDFARE.MD`
**Por qué existe:** Tabla polimórfica centralizada para todos los archivos del ERP (fotos de productos, logos, avatares, evidencias de entrega). Usa patrón `entidad_tipo + entidad_id` (igual que `movimientos_stock`). Los archivos físicos viven en Cloudflare R2; esta tabla guarda la metadata y la URL pública.

| Campo clave | Por qué |
|-------------|---------|
| entidad_tipo + entidad_id | Relación polimórfica: producto, configuracion, perfil_usuario, evidencia_entrega, proveedor, cliente. |
| r2_key UNIQUE | Key del archivo en el bucket R2. Único para evitar sobreescritura. |
| url_publica | URL del CDN de Cloudflare. El frontend carga directo de aquí, sin pasar por Django. |
| es_principal | Marca la foto principal de un producto (para mostrar en listados). |
| orden | Orden de las fotos de un producto (galería). |

**Nota:** Los campos `logo` (configuracion), `avatar` (perfiles_usuario) y `archivo` (evidencias_entrega) se **mantienen** como cache de la URL principal. Cuando se sube un archivo, se guarda en `media_archivos` Y se actualiza el campo cache.

---

## RESUMEN

| Módulo | Tablas | Prioridad |
|--------|:------:|:---------:|
| Configuración | 1 | 1 |
| Usuarios y RBAC | 6 | 1 |
| Clientes | 1 | 3 |
| Proveedores | 1 | 3 |
| Inventario | 6 | 2 |
| Ventas | 6 | 4 |
| Facturación | 5 | 5 |
| Compras | 5 | 6 |
| Finanzas | 7 | 7 |
| Distribución | 4 | 8 |
| WhatsApp | 4 | 9 |
| Media / Archivos | 1 | 2 |
| **TOTAL** | **47** | |

Más 11 tablas automáticas de Django (auth, sessions, migrations, simplejwt) = **58 tablas en la DB**.

---

## TABLAS INMUTABLES (solo created_at, sin updated_at)

Estas tablas son logs que NUNCA se editan ni borran:

1. `log_actividad` — auditoría de acciones
2. `movimientos_stock` — log de stock
3. `log_envio_nubefact` — intentos de envío
4. `seguimiento_pedidos` — tracking de entregas
5. `evidencias_entrega` — pruebas de entrega
6. `whatsapp_mensajes` — mensajes enviados
7. `whatsapp_log` — llamadas a API Meta

Las demás tablas tienen `created_at` + `updated_at` por regla DB-03.

---

## TABLAS QUE NUNCA SE BORRAN (solo soft delete o anulación)

Según `03_REGLAS_BASE_DATOS.md` §7:

1. `comprobantes` — documento fiscal
2. `detalle_comprobantes` — detalle fiscal
3. `notas_credito_debito` — documento fiscal
4. `log_envio_nubefact` — auditoría fiscal
5. `ventas` (con comprobante emitido) — solo se anula
6. `detalle_ventas` (con comprobante) — asociada a venta
7. `asientos_contables` — contabilidad
8. `detalle_asientos` — contabilidad
9. `movimientos_stock` — trazabilidad de inventario