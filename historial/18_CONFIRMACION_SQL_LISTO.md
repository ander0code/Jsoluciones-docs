# JSOLUCIONES ERP — SQL LISTO PARA EJECUTAR

> Mensaje del agente de documentacion para el agente de backend.
> Fecha: 17 Feb 2026

---

## ESTADO: TODO SINCRONIZADO. PUEDES EJECUTAR EL SQL.

El archivo `SQL_JSOLUCIONES.sql` esta completo y verificado contra todos los docs de contexto.
No le falta nada. No sobra nada.

---

## NUMEROS FINALES (verificados con grep, no inventados)

| Dato | Valor |
|------|:-----:|
| Tablas (CREATE TABLE) | **47** |
| ENUMs nativos (CREATE TYPE) | **33** |
| Indices (CREATE INDEX + CREATE UNIQUE INDEX) | **104** (16 inline + 88 adicionales) |
| FKs con ON DELETE explicito | **100%** (0 sin ON DELETE) |
| CHECK constraints | **21** |
| UNIQUE constraints adicionales | **8** (fuera de las columnas UNIQUE inline) |
| FLOAT | **0** |
| SERIAL | **0** (todo UUID con gen_random_uuid()) |
| Lineas SQL | **~1230** |

---

## LAS 47 TABLAS POR MODULO

| # | Modulo | Tablas | App Django |
|:-:|--------|:------:|------------|
| 1 | Configuracion | configuracion | apps.empresa |
| 2-7 | Usuarios/RBAC | usuarios, roles, permisos, rol_permisos, perfiles_usuario, log_actividad | apps.usuarios |
| 8 | Clientes | clientes | apps.clientes |
| 9 | Proveedores | proveedores | apps.proveedores |
| 10-15 | Inventario | categorias, productos, almacenes, lotes, stock, movimientos_stock | apps.inventario |
| 16-21 | Ventas | cotizaciones, detalle_cotizaciones, ordenes_venta, detalle_ordenes_venta, ventas, detalle_ventas | apps.ventas |
| 22-26 | Facturacion | series_comprobante, comprobantes, detalle_comprobantes, notas_credito_debito, log_envio_nubefact | apps.facturacion |
| 27-31 | Compras | ordenes_compra, detalle_ordenes_compra, facturas_proveedor, recepciones, detalle_recepciones | apps.compras |
| 32-38 | Finanzas | cuentas_por_cobrar, cuentas_por_pagar, cobros, pagos, cuentas_contables, asientos_contables, detalle_asientos | apps.finanzas |
| 39-42 | Distribucion | transportistas, pedidos, seguimiento_pedidos, evidencias_entrega | apps.distribucion |
| 43-46 | WhatsApp | whatsapp_configuracion, whatsapp_plantillas, whatsapp_mensajes, whatsapp_log | apps.whatsapp |
| 47 | Media | media_archivos | apps.media |

---

## LOS 33 ENUMs

1-9: SUNAT (tipo_documento, tipo_comprobante, estado_comprobante, afectacion_igv, motivo_nota_credito, motivo_nota_debito, tipo_nota, unidad_medida, moneda)
10-11: Inventario (tipo_movimiento, referencia_movimiento)
12: Pago (metodo_pago)
13: Emision (modo_emision)
14-18: Ventas (estado_cotizacion, estado_orden_venta, estado_venta, tipo_venta)
19-21: Compras (estado_orden_compra, estado_factura_proveedor, tipo_recepcion)
22-24: Finanzas (estado_cuenta, estado_asiento, tipo_cuenta_contable)
25-28: Distribucion (estado_pedido, prioridad_pedido, tipo_evidencia, estado_envio_nubefact)
29-31: WhatsApp (estado_mensaje_wa, categoria_plantilla_wa, estado_plantilla_meta)
32-33: Media (entidad_media, tipo_archivo)

---

## CORRECCIONES QUE YA SE APLICARON (no tienes que hacer nada)

| Correccion | Fuente |
|------------|--------|
| motivo_codigo separado en motivo_codigo_nc + motivo_codigo_nd con CHECK | Sesion anterior |
| whatsapp_phone_id/whatsapp_token eliminados de configuracion | Sesion anterior |
| centro_costo como VARCHAR(100), no FK | Sesion anterior |
| detalle_recepciones (tabla #46) agregada | Sesion anterior |
| 11 constraints de integridad (UNIQUE + CHECK) del doc 16 | Sesion anterior |
| media_archivos + 2 ENUMs del doc 17 | Esta sesion |
| Singleton en configuracion | Doc 16 |
| 88 indices adicionales para FKs y queries frecuentes | Esta sesion |

---

## DOCUMENTOS DE REFERENCIA (jerarquia de verdad)

1. **SQL_JSOLUCIONES.sql** — estructura de tablas, tipos, constraints (FUENTE PRIMARIA)
2. **06_CONSTANTES_COMPARTIDAS.md** — valores de ENUMs/CHOICES en Python (33 CHOICES + ROLES_BASE)
3. **14_DB_TABLAS_DESCRIPCION.MD** — justificacion de cada campo y cada ENUM
4. **03_REGLAS_BASE_DATOS.md** — reglas DB-01 a DB-15, modelos conceptuales
5. **12_SUSTENTO_TABLAS_DB.MD** — justificacion de cada tabla
6. **17_INTEGRACION_CLOUDFARE.MD** — arquitectura R2, service Python, setup Cloudflare

---

## PARA IMPLEMENTAR LOS MODELOS DJANGO

1. Cada modelo con `db_table` limpio en Meta
2. UUID PK: `id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)`
3. Los 3 mixins: TimestampMixin, SoftDeleteMixin, AuditMixin (segun tabla)
4. Tablas inmutables (8 logs) solo heredan TimestampMixin y solo usan created_at
5. notas_credito_debito tiene motivo_codigo_nc y motivo_codigo_nd (no motivo_codigo)
6. configuracion NO tiene whatsapp_phone_id ni whatsapp_token
7. centro_costo en asientos_contables es CharField, no FK
8. media_archivos usa patron polimorfico entidad_tipo + entidad_id
9. Los campos logo, avatar, archivo se mantienen como cache de URL de R2
10. boto3 para R2, ArchivoInvalidoError en core/exceptions.py

---

## SIGUIENTE PASO

Ejecutar el SQL en PostgreSQL, crear el proyecto Django, y hacer makemigrations + migrate.
El SQL esta disenado para ejecutarse de arriba a abajo sin errores (las dependencias circulares estan resueltas con ALTER TABLE diferido).
