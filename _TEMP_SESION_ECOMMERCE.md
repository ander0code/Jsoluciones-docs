# [TEMPORAL] Notas de sesion — E-commerce y flujos de venta

> **ESTE ARCHIVO ES TEMPORAL.**
> Fue creado para no perder el hilo de la conversacion mientras no se tiene acceso al PC.
> Una vez leido y procesado, BORRAR este archivo. No debe quedarse en `context/`.
> El contenido definitivo ya fue integrado en:
> - `context/FLOWS.md` — seccion "Flujos Genericos del Sistema"
> - `context/ROADMAP.md` — seccion 4.4 E-commerce API
>
> Este archivo es solo un recordatorio de lectura rapida.

---

## Donde "entra" el e-commerce

El e-commerce **no entra dentro del ERP**. Entra **al lado**, consumiendo su API:

```
E-commerce (frontend separado)
      ↓  consume API
JSoluciones BE
  ├── Inventario  ← catalogo de productos
  ├── Ventas      ← cada compra web genera una Venta
  ├── Distribucion ← si hay delivery, genera un Pedido
  └── Facturacion ← emite boleta/factura automaticamente
```

El ERP ya tiene todo el backend listo. Lo que falta son los endpoints publicos (sin JWT).

---

## La vista de inventario SI alimenta el e-commerce

Cuando el admin carga un producto en el ERP (nombre, descripcion, precio, fotos, stock, categoria), ese mismo producto es el que el e-commerce mostraria. **No hay catalogo separado.**

El unico gap: `GET /inventario/productos/` requiere JWT hoy. Necesita un espejo publico `GET /api/publico/productos/`.

Lo que hay que agregar al modelo `Producto` (4 campos nuevos, nada se rompe):
- `slug` — URL amigable (`/productos/ramo-primavera` en vez de UUID)
- `descripcion_larga` — texto largo (hoy solo hay `descripcion` corta)
- `destacado` — flag para portada del e-commerce
- `orden_display` — orden de aparicion en el catalogo

---

## Todo lo que se compra por e-commerce pasa a ser una Venta

El campo `tipo_venta` **ya existe** en el modelo `Venta`. Hoy `crear_venta_pos()` lo hardcodea siempre como `VENTA_DIRECTA`. Para e-commerce solo hay que pasar `tipo_venta="ecommerce"`. Es un cambio de 1 linea en el service existente.

```
Cliente web hace pedido
        ↓
POST /api/publico/checkout/
        ↓
BE crea Venta [tipo_venta="ecommerce"]  ← campo ya existe
        ↓
Si tiene delivery → crea Pedido (distribucion)
        ↓
Celery emite comprobante SUNAT
        ↓
Kanban de produccion (si aplica al negocio)
        ↓
Conductor entrega → confirmar_entrega()
```

---

## El formulario de personalizacion de Amatista NO va en el template

- `DetalleVenta` en JSoluciones: cero campos de personalizacion. Solo datos numericos. Correcto para template generico.
- `Pedido` en JSoluciones: tiene `dedicatoria` y `notas` (texto libre). Sirve para cualquier negocio.

Lo que tiene Amatista de mas y es **especifico de floreria** (NO va en el template):
- `notas_arreglista` en DetalleVenta
- `estado_produccion` por item (Kanban a nivel de producto)
- `AjustePersonalizacion` (cambiar insumos de la receta por pedido)
- `RecetaProducto` / BOM

Eso va en el modulo opcional `apps/bom/` cuando se hace fork para un negocio que lo necesite.

---

## Flujos genericos (los 4 que existen o existiran)

### Flujo 1 — Venta directa en tienda (sin delivery)
```
POS: vendedor selecciona productos + cobra
        ↓
Venta [estado=COMPLETADA] + Stock descontado [atomic]
        ↓
Celery emite comprobante SUNAT
        ↓
FIN
```

### Flujo 2 — Venta con delivery
```
Venta [COMPLETADA] + Stock descontado
Pedido [PENDIENTE] vinculado a la Venta
        ↓
[Opcional] Kanban produccion: PENDIENTE → ARMANDO → LISTO
        ↓
Supervisor asigna transportista → Pedido [EN_RUTA]
        ↓
Conductor confirma entrega + foto → Pedido [ENTREGADO]
        ↓
Celery emite comprobante SUNAT
```

### Flujo 3 — Venta desde cotizacion / OV (B2B)
```
Cotizacion → OV → Venta → [mismo final que Flujo 1 o 2]
```

### Flujo 4 — E-commerce (a implementar)
```
[FALTA] POST /api/publico/checkout/
[FALTA] Pasarela de pago (Culqi/Stripe)
        ↓
Venta [tipo_venta="ecommerce"] ← mismo codigo que Flujo 1
Si delivery → Pedido           ← mismo codigo que Flujo 2
Celery → SUNAT                 ← mismo codigo que siempre
```

El **80% del backend del e-commerce ya existe**. Lo que falta es la capa de entrada publica.

---

## Resumen de que hay que hacer para el e-commerce

| Que | Donde | Complejidad |
|-----|-------|-------------|
| Endpoints publicos de catalogo | `apps/inventario/urls_publicas.py` (nuevo) | Baja |
| `slug` y `descripcion_larga` en Producto | `apps/inventario/models.py` | Baja |
| `tipo_venta="ecommerce"` en el service | `apps/ventas/services.py` | Trivial |
| Carrito web con TTL de reserva de stock | `apps/ecommerce/` (nuevo modulo) | Media |
| Pasarela de pago (Culqi) | `apps/ecommerce/` | Alta |
| Panel ERP: filtrar ventas por canal | `apps/ventas/views.py` + FE | Baja |

---

> Recuerda: borrar este archivo cuando lo hayas leido. El contenido definitivo esta en FLOWS.md y ROADMAP.md.
