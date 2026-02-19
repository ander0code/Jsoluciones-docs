# JSOLUCIONES ERP — REVISIÓN CRÍTICA PRE-IMPLEMENTACIÓN

> Archivo para el agente de backend.
> Cada hallazgo tiene: qué falta, dónde dice el doc que debería estar, y el SQL exacto para corregir.
> Solo cosas reales sacadas de los docs de contexto. Sin inventar.

---

## RESUMEN: 12 hallazgos

| # | Severidad | Hallazgo | Fuente en docs |
|:-:|:---------:|----------|----------------|
| 1 | CRÍTICO | Falta UNIQUE en `notas_credito_debito(tipo_nota, serie, numero)` | 03_REGLAS §5.5 — SUNAT exige serie+numero único por tipo |
| 2 | CRÍTICO | Falta UNIQUE en `numero` de cotizaciones, ordenes_venta, ventas, ordenes_compra | 03_REGLAS §5.4/§5.6 — "numero (auto)" implica correlativo único |
| 3 | CRÍTICO | Falta CHECK de cantidades positivas en detalles | 06_CONSTANTES → `validar_cantidad_positiva` existe pero la DB no lo valida |
| 4 | CRÍTICO | Falta CHECK en `detalle_asientos` para partida doble | 03_REGLAS §5.7 — debe y haber no pueden ser ambos > 0 en misma línea |
| 5 | ALTO | Falta CHECK `stock.cantidad >= 0` | Lógica de negocio — stock negativo no tiene sentido |
| 6 | ALTO | Falta CHECK `proveedores.calificacion` entre 1 y 5 | 03_REGLAS §5.3 — "calificacion (IntegerField, 1-5)" |
| 7 | ALTO | Falta CHECK `cobros.monto > 0` y `pagos.monto > 0` | Lógica de negocio — un cobro/pago de 0 o negativo no existe |
| 8 | ALTO | Falta CHECK `precios > 0` en detalles | 03_REGLAS → DB-09 + 06_CONSTANTES → `validar_precio_positivo` |
| 9 | MEDIO | `configuracion` necesita CHECK de máximo 1 fila | 01_CORE §4.2 — "Solo 1 fila por instancia" |
| 10 | MEDIO | Falta UNIQUE en `pedidos.numero` y `facturas_proveedor.numero_factura+proveedor_id` | Lógica de negocio — numeración debe ser única |
| 11 | MEDIO | `clientes` necesita UNIQUE condicional en `tipo_documento + numero_documento` | 03_REGLAS §5.2 — "numero_documento (unique por tipo)" |
| 12 | BAJO | El doc 03_REGLAS dice `centro_costo (FK null)` pero se implementó como VARCHAR | 03_REGLAS §5.7 vs 14_DICCIONARIO — ya decidido como VARCHAR, actualizar §5.7 |

---

## HALLAZGO 1 (CRÍTICO): UNIQUE en notas_credito_debito

**Doc:** `03_REGLAS_BASE_DATOS.md` §5.5 — Las notas de crédito/débito son comprobantes SUNAT con serie+numero. SUNAT rechaza duplicados.

**Problema:** Se puede insertar dos NC con serie=FC01 numero=1. SUNAT lo rechaza.

**SQL a agregar en `notas_credito_debito`:**
```sql
UNIQUE(tipo_nota, serie, numero)
```

---

## HALLAZGO 2 (CRÍTICO): UNIQUE en campos `numero`

**Doc:** `03_REGLAS_BASE_DATOS.md` §5.4 y §5.6 — Todos dicen "numero (auto)" lo que implica correlativo único.

**Problema:** Sin UNIQUE, el sistema puede generar V-0001 dos veces si hay concurrencia.

**SQL a agregar:**
```sql
-- En cotizaciones:
ALTER TABLE cotizaciones ADD CONSTRAINT uq_cotizaciones_numero UNIQUE(numero);

-- En ordenes_venta:
ALTER TABLE ordenes_venta ADD CONSTRAINT uq_ordenes_venta_numero UNIQUE(numero);

-- En ventas:
ALTER TABLE ventas ADD CONSTRAINT uq_ventas_numero UNIQUE(numero);

-- En ordenes_compra:
ALTER TABLE ordenes_compra ADD CONSTRAINT uq_ordenes_compra_numero UNIQUE(numero);
```

---

## HALLAZGO 3 (CRÍTICO): CHECK cantidades positivas

**Doc:** `06_CONSTANTES_COMPARTIDAS.md` §3 — Existe `validar_cantidad_positiva` en Django, pero si algo inserta directo en DB, pasa.

**SQL a agregar en CADA tabla de detalle:**
```sql
-- detalle_cotizaciones
ALTER TABLE detalle_cotizaciones ADD CONSTRAINT chk_dc_cantidad CHECK (cantidad > 0);

-- detalle_ordenes_venta
ALTER TABLE detalle_ordenes_venta ADD CONSTRAINT chk_dov_cantidad CHECK (cantidad > 0);

-- detalle_ventas
ALTER TABLE detalle_ventas ADD CONSTRAINT chk_dv_cantidad CHECK (cantidad > 0);

-- detalle_comprobantes
ALTER TABLE detalle_comprobantes ADD CONSTRAINT chk_dcomp_cantidad CHECK (cantidad > 0);

-- detalle_ordenes_compra
ALTER TABLE detalle_ordenes_compra ADD CONSTRAINT chk_doc_cantidad CHECK (cantidad > 0);

-- detalle_recepciones
ALTER TABLE detalle_recepciones ADD CONSTRAINT chk_dr_cantidad CHECK (cantidad_recibida > 0);

-- movimientos_stock
ALTER TABLE movimientos_stock ADD CONSTRAINT chk_ms_cantidad CHECK (cantidad > 0);
```

---

## HALLAZGO 4 (CRÍTICO): CHECK partida doble en detalle_asientos

**Doc:** `03_REGLAS_BASE_DATOS.md` §5.7 — "debe (DecimalField), haber (DecimalField)". Partida doble exige que en cada línea solo uno de los dos sea > 0.

**SQL:**
```sql
ALTER TABLE detalle_asientos ADD CONSTRAINT chk_partida_doble CHECK (
    (debe > 0 AND haber = 0) OR (debe = 0 AND haber > 0)
);
```

---

## HALLAZGO 5 (ALTO): CHECK stock no negativo

**Problema:** Un bug en la lógica podría dejar stock.cantidad = -5. La DB debe proteger.

**SQL:**
```sql
ALTER TABLE stock ADD CONSTRAINT chk_stock_no_negativo CHECK (cantidad >= 0);
```

---

## HALLAZGO 6 (ALTO): CHECK calificación proveedores

**Doc:** `03_REGLAS_BASE_DATOS.md` §5.3 — "calificacion (IntegerField, 1-5)"

**SQL:**
```sql
ALTER TABLE proveedores ADD CONSTRAINT chk_calificacion CHECK (calificacion BETWEEN 1 AND 5);
```

---

## HALLAZGO 7 (ALTO): CHECK montos positivos en cobros/pagos

**SQL:**
```sql
ALTER TABLE cobros ADD CONSTRAINT chk_cobro_monto CHECK (monto > 0);
ALTER TABLE pagos ADD CONSTRAINT chk_pago_monto CHECK (monto > 0);
```

---

## HALLAZGO 8 (ALTO): CHECK precios positivos

**Doc:** `06_CONSTANTES_COMPARTIDAS.md` §3 — `validar_precio_positivo` existe en Django.

**SQL:**
```sql
ALTER TABLE detalle_cotizaciones ADD CONSTRAINT chk_dc_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ordenes_venta ADD CONSTRAINT chk_dov_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ventas ADD CONSTRAINT chk_dv_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_comprobantes ADD CONSTRAINT chk_dcomp_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ordenes_compra ADD CONSTRAINT chk_doc_precio CHECK (precio_unitario > 0);
```

---

## HALLAZGO 9 (MEDIO): Máximo 1 fila en configuracion

**Doc:** `01_CORE_PROYECTO.md` §4.2 — "Solo 1 fila por instancia". El SQL no lo impone.

**Solución en Django (en el modelo):**
```python
def save(self, *args, **kwargs):
    if not self.pk and Configuracion.objects.exists():
        raise ValidationError('Solo puede existir una configuración.')
    super().save(*args, **kwargs)
```

**O con SQL (trigger o constraint):**
```sql
-- Opción simple: crear un campo singleton y hacerlo UNIQUE
ALTER TABLE configuracion ADD COLUMN singleton BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE configuracion ADD CONSTRAINT uq_configuracion_singleton UNIQUE(singleton);
ALTER TABLE configuracion ADD CONSTRAINT chk_singleton CHECK (singleton = TRUE);
```

---

## HALLAZGO 10 (MEDIO): UNIQUE en pedidos y facturas_proveedor

**SQL:**
```sql
ALTER TABLE pedidos ADD CONSTRAINT uq_pedidos_numero UNIQUE(numero);
ALTER TABLE facturas_proveedor ADD CONSTRAINT uq_factura_prov UNIQUE(proveedor_id, numero_factura);
```

---

## HALLAZGO 11 (MEDIO): UNIQUE condicional en clientes

**Doc:** `03_REGLAS_BASE_DATOS.md` §5.2 — "numero_documento (unique por tipo)"

**Problema:** Dos clientes pueden tener tipo_documento='6' (RUC) y numero_documento='20100130204'. Eso no debería pasar.

**SQL:**
```sql
CREATE UNIQUE INDEX idx_clientes_doc_unico
    ON clientes(tipo_documento, numero_documento)
    WHERE is_active = TRUE;
```
**Nota:** Ya existe un INDEX no-unique. Reemplazar por este UNIQUE parcial (solo activos, para permitir re-registrar clientes desactivados con mismo documento).

---

## HALLAZGO 12 (BAJO): centro_costo en docs

**Doc:** `03_REGLAS_BASE_DATOS.md` §5.7 dice "centro_costo (FK null)" pero en el SQL y en `14_DB_TABLAS_DESCRIPCION.MD` se decidió VARCHAR(100).

**Acción:** Actualizar §5.7 de `03_REGLAS_BASE_DATOS.md`:
```
Antes:  ├── centro_costo (FK null)
Después: ├── centro_costo (VARCHAR(100), no FK, etiqueta libre)
```

---

## SCRIPT CONSOLIDADO DE CONSTRAINTS

Para que el agente de backend agregue todo de una vez al SQL:

```sql
-- ============================================================
-- CONSTRAINTS ADICIONALES — Agregar al final del SQL principal
-- ============================================================

-- HALLAZGO 1: UNIQUE notas crédito/débito
ALTER TABLE notas_credito_debito
    ADD CONSTRAINT uq_notas_tipo_serie_numero UNIQUE(tipo_nota, serie, numero);

-- HALLAZGO 2: UNIQUE correlativos
ALTER TABLE cotizaciones ADD CONSTRAINT uq_cotizaciones_numero UNIQUE(numero);
ALTER TABLE ordenes_venta ADD CONSTRAINT uq_ordenes_venta_numero UNIQUE(numero);
ALTER TABLE ventas ADD CONSTRAINT uq_ventas_numero UNIQUE(numero);
ALTER TABLE ordenes_compra ADD CONSTRAINT uq_ordenes_compra_numero UNIQUE(numero);
ALTER TABLE pedidos ADD CONSTRAINT uq_pedidos_numero UNIQUE(numero);

-- HALLAZGO 3: Cantidades positivas
ALTER TABLE detalle_cotizaciones ADD CONSTRAINT chk_dc_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_ordenes_venta ADD CONSTRAINT chk_dov_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_ventas ADD CONSTRAINT chk_dv_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_comprobantes ADD CONSTRAINT chk_dcomp_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_ordenes_compra ADD CONSTRAINT chk_doc_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_recepciones ADD CONSTRAINT chk_dr_cantidad CHECK (cantidad_recibida > 0);
ALTER TABLE movimientos_stock ADD CONSTRAINT chk_ms_cantidad CHECK (cantidad > 0);

-- HALLAZGO 4: Partida doble
ALTER TABLE detalle_asientos ADD CONSTRAINT chk_partida_doble CHECK (
    (debe > 0 AND haber = 0) OR (debe = 0 AND haber > 0)
);

-- HALLAZGO 5: Stock no negativo
ALTER TABLE stock ADD CONSTRAINT chk_stock_no_negativo CHECK (cantidad >= 0);

-- HALLAZGO 6: Calificación 1-5
ALTER TABLE proveedores ADD CONSTRAINT chk_calificacion CHECK (calificacion BETWEEN 1 AND 5);

-- HALLAZGO 7: Montos positivos
ALTER TABLE cobros ADD CONSTRAINT chk_cobro_monto CHECK (monto > 0);
ALTER TABLE pagos ADD CONSTRAINT chk_pago_monto CHECK (monto > 0);

-- HALLAZGO 8: Precios positivos
ALTER TABLE detalle_cotizaciones ADD CONSTRAINT chk_dc_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ordenes_venta ADD CONSTRAINT chk_dov_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ventas ADD CONSTRAINT chk_dv_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_comprobantes ADD CONSTRAINT chk_dcomp_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ordenes_compra ADD CONSTRAINT chk_doc_precio CHECK (precio_unitario > 0);

-- HALLAZGO 9: Singleton configuracion
ALTER TABLE configuracion ADD COLUMN singleton BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE configuracion ADD CONSTRAINT uq_configuracion_singleton UNIQUE(singleton);
ALTER TABLE configuracion ADD CONSTRAINT chk_singleton CHECK (singleton = TRUE);

-- HALLAZGO 10: Facturas proveedor únicas
ALTER TABLE facturas_proveedor ADD CONSTRAINT uq_factura_prov UNIQUE(proveedor_id, numero_factura);

-- HALLAZGO 11: Documento único por cliente activo
DROP INDEX IF EXISTS idx_clientes_documento;
CREATE UNIQUE INDEX idx_clientes_doc_unico
    ON clientes(tipo_documento, numero_documento)
    WHERE is_active = TRUE;
```

---

## DOC A ACTUALIZAR

| Archivo | Cambio |
|---------|--------|
| `03_REGLAS_BASE_DATOS.md` §5.7 | `centro_costo (FK null)` → `centro_costo (VARCHAR(100), etiqueta libre)` |

Es el único doc que tiene inconsistencia con el SQL final. Todo lo demás ya está sincronizado según `15_VALIDACION_FINAL_SQL.md`.

---

## MÓDULOS vs TABLAS — ¿CUBRIMOS TODO?

Cruzando `01_CORE_PROYECTO.md` §5 (INSTALLED_APPS) con las 46 tablas:

| App Django (01_CORE §5) | Tablas en SQL | ¿Completo? |
|--------------------------|:---:|:---:|
| apps.empresa | configuracion (1) | ✓ |
| apps.usuarios | usuarios, roles, permisos, rol_permisos, perfiles_usuario, log_actividad (6) | ✓ |
| apps.clientes | clientes (1) | ✓ |
| apps.proveedores | proveedores (1) | ✓ |
| apps.inventario | categorias, productos, almacenes, lotes, stock, movimientos_stock (6) | ✓ |
| apps.ventas | cotizaciones, detalle_cotizaciones, ordenes_venta, detalle_ordenes_venta, ventas, detalle_ventas (6) | ✓ |
| apps.facturacion | series_comprobante, comprobantes, detalle_comprobantes, notas_credito_debito, log_envio_nubefact (5) | ✓ |
| apps.compras | ordenes_compra, detalle_ordenes_compra, facturas_proveedor, recepciones, detalle_recepciones (5) | ✓ |
| apps.finanzas | cuentas_por_cobrar, cuentas_por_pagar, cobros, pagos, cuentas_contables, asientos_contables, detalle_asientos (7) | ✓ |
| apps.distribucion | transportistas, pedidos, seguimiento_pedidos, evidencias_entrega (4) | ✓ |
| apps.whatsapp | whatsapp_configuracion, whatsapp_plantillas, whatsapp_mensajes, whatsapp_log (4) | ✓ |
| apps.reportes | Sin modelos propios (solo services) | ✓ — correcto según doc |
| **TOTAL** | **46 tablas en 11 apps + 1 app sin modelos** | **✓ COMPLETO** |

---

## CONCLUSIÓN

El SQL está bien estructurado. Las 5 correcciones del otro agente fueron correctas. Lo que falta son **constraints de integridad** que los docs ya piden (validadores Django existen, pero la DB no los refuerza). El script consolidado de arriba cierra esa brecha.

Una vez que el agente de backend aplique los constraints, el SQL queda listo para `makemigrations + migrate`.