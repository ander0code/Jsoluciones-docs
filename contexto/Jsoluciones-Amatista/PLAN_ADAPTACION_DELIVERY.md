# Plan de Adaptacion: JSoluciones → Delivery completo (inspirado en Amatista)

> Fecha: 2026-02-23
> Basado en: lectura directa del codigo real de ambos proyectos (sin alucinar)
> Objetivo: hacer que JSoluciones cubra todo lo que Amatista ofrece, sin tocar el POS
>   y sin personalizarlo para floreria — todo debe ser universal para cualquier negocio con reparto.
> El POS, inventario, facturacion, compras, finanzas — no se tocan en ningun paso.

---

## Que tiene Amatista que es universal (no es de floreria)

Antes de implementar hay que entender que de Amatista aplica a CUALQUIER negocio
con delivery: restaurante, farmacia, tienda de ropa, ferreteria, etc.

| Funcionalidad | Universal? | Nota |
|---|---|---|
| Destinatario distinto al comprador | Si | El que recibe != el que paga |
| Telefono del destinatario | Si | Para que el conductor coordine |
| Turno de entrega AM/PM | Si | Cualquier delivery usa franjas horarias |
| Costo de delivery separado | Si | Es un cargo real que va en el total |
| Enlace de ubicacion (Google Maps) | Si | El cliente manda el pin de Maps |
| Flag de urgencia en pedido | Si | Priorizar una entrega sobre otras |
| Fecha de compra vs fecha de entrega separadas | Si | Siempre son distintas en delivery |
| Portal del conductor sin login | Si | Conductor ve sus entregas y confirma sin cuenta |
| GPS del conductor en tiempo real | Si | Mapa funcional requiere coords del conductor |
| Asignacion masiva de pedidos | Si | Con volumen, asignar uno a uno es inviable |
| Estado REPROGRAMADO | Si | Cualquier delivery puede necesitar reprogramar |
| PDF de entrega (va dentro del paquete) | Si | Cualquier negocio fisico necesita documentar |
| Modulo de produccion Kanban | NO — es de nicho | Solo aplica si el negocio "arma" pedidos (cocina, floreria, taller). Se implementa como modulo opcional. |
| Dedicatoria en pedido | NO — es de nicho | Solo regalos/flores. Campo opcional. |

---

## Estado actual de JSoluciones (codigo real, sin suposiciones)

### Modelo Pedido — campos que YA tiene
- id, numero, codigo_seguimiento (8 chars publico)
- cliente (FK), venta (FK, nullable)
- direccion_entrega, latitud, longitud
- estado (PENDIENTE/CONFIRMADO/DESPACHADO/EN_RUTA/ENTREGADO/CANCELADO/DEVUELTO)
- transportista (FK, nullable)
- fecha_estimada_entrega, fecha_entrega_real
- notas, prioridad, is_active

### Modelo Pedido — campos que FALTAN
- nombre_destinatario
- telefono_destinatario
- turno_entrega (AM / PM)
- costo_delivery (decimal)
- enlace_ubicacion (URL del pin de Maps)
- es_urgente (boolean, default False)
- fecha_pedido separada de fecha_entrega (hoy solo hay fecha de creacion)
- estado_produccion (pendiente / armando / listo) — para modulo produccion
- dedicatoria (text, nullable) — campo de nicho, pero cuesta nada agregarlo

### Modelo Transportista — campos que YA tiene
- id, nombre, telefono, email, tipo_vehiculo, placa
- limite_pedidos_diario, is_active

### Modelo Transportista — campos que FALTAN
- token (UUID unico, auto-generado al crear) — REQUERIDO para portal sin login
- last_lat, last_lng (decimal 8 digitos) — para mapa en tiempo real
- last_location_at (datetime) — timestamp ultima ubicacion GPS
- preferencia_zona (text) — ayuda a asignar por zona geografica

### Maquina de estados — lo que FALTA
- Estado REPROGRAMADO no existe
- Logica de descontar stock al crear pedido de distribucion (hoy solo descuenta via POS)
- Logica de restaurar stock al cancelar/editar pedido de distribucion

### Portal publico — lo que FALTA
- `SeguimientoPublicoView` EXISTE en `distribucion/views.py` pero NO tiene URL registrada
- Solo es GET de lectura — no permite confirmar entrega ni actualizar GPS
- No hay endpoints POST sin JWT para conductor

---

## PLAN DE EJECUCION — 5 fases, en orden

Cada fase es independiente. No rompe el POS ni los demas modulos.

---

### FASE 1 — Campos al modelo (BE: migraciones puras)

**Archivos a modificar:**
- `Jsoluciones-be/apps/distribucion/models.py`
- Crear migracion nueva

**Que agregar al modelo Pedido:**

```python
# Datos del destinatario (quien recibe, puede ser distinto al cliente)
nombre_destinatario = models.CharField(max_length=200, blank=True)
telefono_destinatario = models.CharField(max_length=20, blank=True)

# Delivery
turno_entrega = models.CharField(
    max_length=10,
    choices=[('manana', 'Manana (AM)'), ('tarde', 'Tarde (PM)')],
    blank=True
)
costo_delivery = models.DecimalField(max_digits=10, decimal_places=2, default=0)
enlace_ubicacion = models.URLField(blank=True)  # pin de Google Maps
es_urgente = models.BooleanField(default=False)
fecha_pedido = models.DateField(null=True, blank=True)  # fecha cuando se hizo el pedido

# Produccion (modulo opcional)
estado_produccion = models.CharField(
    max_length=20,
    choices=[('pendiente', 'Pendiente'), ('armando', 'Produciendo'), ('listo', 'Listo')],
    default='pendiente'
)
produccion_iniciada_en = models.DateTimeField(null=True, blank=True)
produccion_completada_en = models.DateTimeField(null=True, blank=True)

# Campo de nicho (regalos) — opcional, costo cero agregarlo
dedicatoria = models.TextField(blank=True)
```

**Que agregar al modelo Transportista:**

```python
# Portal sin login
token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)

# GPS en tiempo real
last_lat = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
last_lng = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
last_location_at = models.DateTimeField(null=True, blank=True)

# Asignacion inteligente
preferencia_zona = models.CharField(max_length=200, blank=True)
```

**Despues de modificar modelos:**
```bash
cd Jsoluciones-be
python manage.py makemigrations distribucion
python manage.py migrate
# Regenerar schema
python manage.py spectacular --settings=config.settings.development --file ../Jsoluciones-fe/openapi.json
cd Jsoluciones-fe && pnpm orval
```

**Impacto en POS:** Ninguno. Son adiciones en tablas de distribucion.

---

### FASE 2 — Estado REPROGRAMADO + logica de stock en distribucion

**Archivos a modificar:**
- `Jsoluciones-be/apps/distribucion/services.py`

**Que agregar:**

1. Agregar `REPROGRAMADO` a los choices de estado en `models.py`:
```python
('REPROGRAMADO', 'Reprogramado'),
```

2. En `services.py`, agregar funcion `reprogramar_pedido(pedido, nueva_fecha, motivo)`:
```python
# Valida que el pedido NO este en ENTREGADO ni CANCELADO
# Cambia estado a REPROGRAMADO
# Guarda nueva fecha_estimada_entrega
# Registra en SeguimientoPedido
```

3. En `services.py`, en `crear_pedido()` (si existe): agregar descuento de stock
   atomico igual a como lo hace el POS (`select_for_update`).

4. En `cancelar_pedido()`: si el pedido tenia items, restaurar stock.

**Impacto en POS:** Ninguno.

---

### FASE 3 — Portal del conductor (la mas importante)

Este es el corazon de lo que Amatista tiene y JSoluciones no.

**Como funciona en Amatista (referencia):**
- Conductor recibe una URL: `https://sistema.com/conductor/{token-uuid}`
- Sin login, sin cuenta, sin JWT
- Ve la lista de sus entregas del dia
- Puede marcar cada una como: en_ruta / entregado / no_entregado / reprogramado / cancelado
- Puede subir foto de la entrega
- Puede actualizar su ubicacion GPS (boton en la pagina)
- Rate limiting: 60 req/min general, 15 req/min para confirmaciones

**Que crear en JSoluciones BE:**

Archivo: `Jsoluciones-be/apps/distribucion/views_portal.py` (nuevo, separado)

```
GET  /api/v1/distribucion/portal/{token}/
     → Sin JWT, valida token UUID en Transportista
     → Devuelve: datos del transportista + lista pedidos asignados del dia
     → Solo pedidos con estado != ENTREGADO y != CANCELADO

POST /api/v1/distribucion/portal/{token}/pedidos/{pedido_id}/confirmar/
     → Sin JWT, valida token + que el pedido pertenece a ese transportista
     → Body: { estado, observacion, foto_entrega (file, opcional) }
     → Ejecuta la transicion de estado correspondiente
     → Guarda foto en MediaArchivo (entidad_tipo='evidencia_portal')
     → Throttle: max 15 req/min por IP

POST /api/v1/distribucion/portal/{token}/ubicacion/
     → Sin JWT, valida token
     → Body: { lat, lng }
     → Actualiza last_lat, last_lng, last_location_at en Transportista
     → Emite por WebSocket al canal gps_{pedido_activo_id} si hay pedido EN_RUTA
     → Throttle: max 30 req/min por IP
```

**Permisos:** `authentication_classes = []`, `permission_classes = [AllowAny]`
Validacion de autorizacion: manual, verificando que el token UUID exista en Transportista.is_active=True

**Que crear en JSoluciones FE:**

Ruta nueva: `/portal/conductor/{token}` — pagina publica (sin sidebar, sin header de admin)

Componentes:
- `PortalConductorPage`: layout minimalista (sin sidebar), muestra nombre del conductor
- Lista de entregas del dia: tarjetas con estado, destinatario, direccion, productos
- Boton "Actualizar mi ubicacion" — llama a GPS del navegador + POST /ubicacion/
- Por cada entrega: botones de accion segun estado actual
- Modal de confirmacion: selector de estado + campo observacion + upload foto (opcional)

**Nota de UX:** El portal debe funcionar bien en movil (el conductor usa el celular).
Clases Tailwind responsive, botones grandes, sin tablas horizontales.

**Impacto en POS:** Ninguno. Es una ruta publica completamente separada.

---

### FASE 4 — Asignacion masiva + FE de distribucion mejorado

**BE:**

Endpoint nuevo: `POST /api/v1/distribucion/pedidos/asignar-masivo/`
```python
# Body: { pedido_ids: [uuid, ...], transportista_id: uuid }
# Usa DB transaction + select_for_update en cada pedido
# Valida que cada pedido este en estado PENDIENTE o CONFIRMADO
# Asigna transportista_id a cada uno
# Cambia estado a CONFIRMADO si estaba PENDIENTE
# Registra en SeguimientoPedido para cada uno
# Retorna: { asignados: N, errores: [...] }
```

**FE — mejoras a la pagina de pedidos:**
- Checkboxes en la tabla de pedidos (seleccion multiple)
- Toolbar que aparece cuando hay seleccion: "N pedidos seleccionados — Asignar a conductor"
- Modal de asignacion masiva: select de transportista + boton confirmar
- Filtros adicionales: turno AM/PM, es_urgente, fecha_pedido

**FE — formulario de crear/editar pedido:**
- Agregar los campos nuevos: nombre_destinatario, telefono_destinatario
- Selector turno AM/PM
- Campo costo_delivery
- Input enlace_ubicacion (URL)
- Toggle es_urgente (rojo si activo)
- Campo dedicatoria (textarea, colapsable por defecto)

**Impacto en POS:** Ninguno.

---

### FASE 5 — Modulo de produccion (OPCIONAL — solo si el negocio lo necesita)

Este modulo es de nicho. Solo aplica para negocios que "producen" o "arman" pedidos
antes de entregarlos: cocinas, florerías, talleres, confitería, etc.

Se implementa como modulo separado con su propio permiso. Si una instancia no
lo necesita, no aparece en el sidebar (se controla desde los permisos del rol).

**BE:**

ViewSet o endpoints dedicados en `distribucion/views.py`:
```
GET  /api/v1/distribucion/produccion/?fecha=YYYY-MM-DD&turno=manana|tarde
     → Agrupa pedidos por estado_produccion para el Kanban
     → Incluye resumen de productos pendientes (suma por producto, excluye adicionales)

POST /api/v1/distribucion/produccion/{pedido_id}/estado/
     → Transiciones validas:
        pendiente → armando  (guarda produccion_iniciada_en)
        armando   → listo    (guarda produccion_completada_en)
        listo     → armando  (limpia produccion_completada_en — reversion)
     → Cualquier otra transicion → 400 Bad Request
```

**FE:**

Ruta: `/distribucion/produccion`

Componente: `ProduccionKanban`
- 3 columnas: Pendiente / Produciendo / Listo
- Cada tarjeta: destinatario, productos, turno (badge AM/PM), flag urgente (borde rojo)
- Drag-and-drop entre columnas O botones de avance
- Panel lateral: resumen de materiales (lista de productos con cantidad total pendiente)
- Filtro por fecha y turno
- La logica de urgencia: `es_urgente == true` O `created_at` hace mas de 30 minutos

**Permiso requerido:** `produccion.ver` — si el rol no tiene este permiso, la pagina no aparece.

**Impacto en POS:** Ninguno.

---

### FASE 6 — PDF de entrega (para negocios fisicos con empaque)

Amatista genera dos PDFs por pedido que van en el paquete fisico:
1. PDF de entrega (15.5×21cm): va dentro del paquete, tiene imagen de productos
2. PDF interno (A4): para uso administrativo, datos completos

En JSoluciones, ya existe `reportlab` en el backend (usado para reportes y comprobantes).

**BE:**

```
GET /api/v1/distribucion/pedidos/{id}/pdf-entrega/
    → Genera PDF 15.5x21cm con: destinatario, direccion, turno, productos + imagen, dedicatoria
    → Content-Type: application/pdf

GET /api/v1/distribucion/pedidos/{id}/pdf-interno/
    → Genera PDF A4 con: todos los campos del pedido, creado_por, conductor asignado
    → Content-Type: application/pdf
```

**FE — en el detalle del pedido:**
- Boton "PDF Entrega" — abre en nueva pestaña o descarga
- Boton "PDF Interno" — abre en nueva pestaña o descarga
- (Opcional) Boton "Compartir imagen" — descarga PNG para enviar por WhatsApp

**Impacto en POS:** Ninguno.

---

## Orden de prioridad real

Si mañana empezara a ejecutar este plan, el orden seria:

```
1. FASE 1  — Campos al modelo         (1-2 horas, migraciones puras, cero riesgo)
2. FASE 2  — Estado REPROGRAMADO      (1 hora, solo logica de estados)
3. FASE 3  — Portal del conductor     (el mas valioso, 4-6 horas BE + FE)
4. FASE 4  — Asignacion masiva + FE   (3-4 horas)
5. FASE 5  — Produccion Kanban        (3-4 horas, solo si el negocio lo necesita)
6. FASE 6  — PDFs de entrega          (2-3 horas, solo si el negocio los necesita)
```

Total estimado: 15-20 horas de desarrollo.

---

## Lo que JSoluciones ya tiene MEJOR que Amatista (no tocar)

| Funcionalidad | JSoluciones | Amatista |
|---|---|---|
| Mapa con Leaflet + WebSocket GPS | Ya existe y funciona con coords reales | Usa tabla de coordenadas por distrito (aproximado) |
| Stock multi-almacen con lotes | Completo | Campo simple por producto |
| POS con carrito, caja, arqueo | Completo | No tiene POS |
| Facturacion electronica SUNAT | Completo | No tiene |
| Compras con OC y proveedores | Completo | No tiene |
| Finanzas contables | Completo | No tiene |
| Roles y permisos granulares | Dinamicos por modulo+accion | 3 roles fijos hardcodeados |
| Notificaciones WebSocket | Implementadas | No tiene |
| 2FA TOTP | Implementado | No tiene |

---

## Nota final sobre el POS

El punto de venta NO se modifica en ninguna fase de este plan.

Los pedidos de distribucion pueden crearse de dos formas:
1. Desde una venta POS (el pedido queda vinculado a la venta via `venta` FK)
2. Directamente en distribucion sin pasar por el POS (delivery directo)

Ambos flujos son validos y coexisten sin conflicto.
El stock en el caso 2 se descuenta en la Fase 2 de este plan
(actualmente solo se descuenta en el caso 1).

> Ultima actualizacion: 2026-02-23
> Basado en codigo real de ambos proyectos (Amatista commit actual + JSoluciones sesion T8)
