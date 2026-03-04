# JSoluciones — Roadmap del Template y Estrategia Multi-Negocio

> Este documento responde tres preguntas clave:
> 1. Que es este sistema y por que es valioso.
> 2. Que le falta para ser un template 100% reutilizable (fork-and-go).
> 3. Que le falta para alimentar un e-commerce.
>
> **NO es multi-tenant.** El modelo es: un fork del template por cada empresa cliente. Cada instalacion es independiente.

---

## 1. Que es JSoluciones

### ERP + POS = un solo sistema

**ERP** (Enterprise Resource Planning): sistema que integra todos los procesos de una empresa en una sola plataforma con una sola fuente de verdad. Inventario, compras, ventas, finanzas, facturacion, reportes, usuarios — todo conectado.

**POS** (Point of Sale): el modulo donde ocurre la venta en mostrador en tiempo real. No es un sistema separado. Es un modulo dentro del ERP.

JSoluciones es ambos: ERP completo con POS integrado en el modulo de ventas (`pedido-pos`). Eso es valor real porque muchos sistemas cobran el POS por separado o requieren integracion externa.

### Modulos actuales y estado (Mar 2026)

| # | Modulo | BE | FE | Promedio |
|---|--------|:--:|:--:|:--------:|
| 1 | Ventas / POS | ~91% | ~78% | ~85% |
| 2 | Inventario | ~91% | ~87% | ~89% |
| 3 | Facturacion Electronica (SUNAT) | ~87% | ~85% | ~86% |
| 4 | Distribucion y Seguimiento | ~88% | ~86% | ~87% |
| 5 | Compras y Proveedores | ~94% | ~88% | ~91% |
| 6 | Gestion Financiera | ~92% | ~92% | ~92% |
| 7 | WhatsApp | ~45% | ~70% | ~57% |
| 8 | Dashboard y Reportes | ~96% | ~100% | ~98% |
| 9 | Usuarios y Roles | ~96% | ~97% | ~96% |
| **TOTAL** | | **~91%** | **~87%** | **~89%** |

---

## 2. El template hoy: problema real

Mirando como se construyo Amatista (floristeria) a partir de JSoluciones, el patron actual es **fork + edicion invasiva**. Esto funciona pero tiene un costo alto en cada nuevo cliente:

| Problema identificado | Impacto |
|-----------------------|---------|
| Paleta de colores hardcodeada en 5+ lugares (PDFs, CSS, JS) | Hay que editar `distribucion/services.py`, `tailwind.config.ts`, y 3+ archivos mas para cambiar colores |
| Nombre de empresa hardcodeado en footers de PDFs (`"Amatista ERP"`) | Hay que buscar y reemplazar en todo el codigo |
| Choices especificos del negocio mezclados en `core/choices.py` | Contamina el core del template con logica de un negocio especifico |
| Campos de negocio directo en modelos base (`estado_frescura` en `Lote`) | Imposible separar lo generico de lo especifico sin migraciones complejas |
| `appName` hardcodeado en `helpers/constants.ts` | Requiere edicion manual en el FE |
| README del template nunca actualizado en Amatista | Confusion entre template base y derivado |

**Conclusion:** cada nuevo cliente hoy requiere editar codigo en 20+ archivos solo para cambiar identidad visual y nombre. Los modulos especificos del negocio van mezclados con el core.

---

## 3. Estrategia: template fork-and-go

El objetivo es que al hacer fork del template, el desarrollador solo necesite:

1. Configurar `.env` (credenciales DB, Nubefact, R2, etc.)
2. Correr `setup_empresa` para cargar datos base de la empresa cliente
3. Activar/desactivar modulos segun el tipo de negocio
4. Agregar los modulos especificos del negocio (si aplica) sin tocar el core

### 3.1 Lo que hay que mejorar en el template base (sin cambiar arquitectura)

#### Backend — cambios en `apps/empresa/`

El modelo `Empresa` (singleton, ya existe) debe recibir los campos de identidad visual que hoy van hardcodeados:

```python
# Agregar al modelo Empresa en apps/empresa/models.py
color_primario      = models.CharField(max_length=7, default='#D65A42')   # Hex
color_secundario    = models.CharField(max_length=7, default='#1A1A1A')   # Hex
color_superficie    = models.CharField(max_length=7, default='#F9F7F2')   # Hex
fuente_titulos      = models.CharField(max_length=100, default='Playfair Display')
fuente_cuerpo       = models.CharField(max_length=100, default='Inter')
nombre_sistema      = models.CharField(max_length=100, default='JSoluciones ERP')
```

Con esto, los PDFs generados con ReportLab leen `empresa.color_primario` en vez de tener `COLOR_PRIMARY = "#D65A42"` hardcodeado. El nombre del sistema en footers de PDFs viene de `empresa.nombre_sistema`.

#### Backend — separar choices

Dividir `core/choices.py` en dos archivos:

```
core/
  choices.py           # Solo choices universales (roles, estados HTTP, metodos pago genericos)
  choices_negocio.py   # Choices especificos del negocio (se edita al hacer fork: estado_frescura para floreria, tipo_habitacion para hotel, etc.)
```

#### Frontend — cargar identidad visual desde la API

Al bootear la app, antes de renderizar el layout, hacer `GET /empresa/configuracion/` y aplicar los valores al documento:

```typescript
// En ProvidersWrapper.tsx o en AuthContext al hacer login
document.documentElement.style.setProperty('--color-primary', empresa.color_primario)
document.documentElement.style.setProperty('--color-brand-surface', empresa.color_superficie)
// appName tambien viene de empresa.nombre_sistema
```

Las variables CSS ya estan tokenizadas en el template (`--color-primary`, etc.). Solo falta que el valor inicial venga de la API en vez de estar hardcodeado en `themes.css`.

#### Frontend — `appName` dinamico

```typescript
// helpers/constants.ts — hoy:
export const appName = 'JSoluciones ERP'

// Despues del cambio: leerlo de AuthContext que ya tiene la info de empresa
```

### 3.2 Modulos opcionales por tipo de negocio

El campo `modulos_activos` en `Empresa` (JSONField) controla que modulos estan habilitados en esta instalacion. El FE lee este campo para mostrar/ocultar secciones del menu.

```python
# Ejemplo de valor en Empresa.modulos_activos
{
  "pos": true,
  "inventario": true,
  "facturacion": true,
  "distribucion": true,
  "compras": true,
  "finanzas": true,
  "whatsapp": false,
  "reportes": true,
  "ecommerce": false,
  "reservas": false,
  "ordenes_trabajo": false,
  "bom": false
}
```

| Modulo | Floreria | Hotel | Mecanica | E-commerce | Retail |
|--------|:--------:|:-----:|:--------:|:----------:|:------:|
| Inventario base | SI | SI | SI | SI | SI |
| POS | SI | SI | SI | NO | SI |
| Facturacion SUNAT | SI | SI | SI | SI | SI |
| Finanzas | SI | SI | SI | SI | SI |
| Compras/Proveedores | SI | SI | SI | SI | SI |
| Usuarios/Roles | SI | SI | SI | SI | SI |
| Dashboard/Reportes | SI | SI | SI | SI | SI |
| WhatsApp | SI | SI | SI | SI | SI |
| Distribucion/Delivery | SI | NO | NO | SI | NO |
| BOM / Recetas | SI | NO | NO | NO | NO |
| Reservas/Citas | NO | SI | SI | NO | NO |
| Habitaciones/Recursos | NO | SI | NO | NO | NO |
| Ordenes de Trabajo (OT) | NO | NO | SI | NO | NO |
| Ecommerce API | NO | NO | NO | SI | SI |
| Programa de Lealtad | NO | NO | NO | SI | SI |
| RRHH basico | NO | SI | SI | NO | SI |

---

## 4. Modulos que faltan en el template para ser universal

Estos modulos no existen todavia y son los que permiten cubrir los tipos de negocio planificados.

### 4.1 Reservas / Citas (`apps/reservas/`)

**Para:** hoteles, mecanicas, salones, clinicas, canchas deportivas, coworkings.

Cualquier negocio que vende **tiempo** en lugar de (o ademas de) productos fisicos.

**Modelos necesarios:**

```
Recurso         — lo que se reserva: habitacion, bahia de taller, mesa, cancha
                  campos: nombre, tipo, capacidad, precio_base, esta_activo
DisponibilidadRecurso — bloqueos manuales: mantenimiento, limpieza, etc.
Reserva         — la reserva en si
                  campos: cliente, recurso, fecha_inicio, fecha_fin, estado
                  estados: pendiente | confirmada | en_uso | completada | cancelada | no_show
PagoReserva     — pago parcial o total al momento de reservar (anticipo)
ServicioAdicional — servicios extras: minibar, desayuno, cambio de aceite premium, etc.
```

**Relacion con modulos existentes:**
- `Reserva` genera una `Venta` al hacer checkout (conecta con ventas y facturacion existentes)
- El anticipo genera una `CuentaCobrar` (conecta con finanzas existente)
- El inventario de recursos perecibles (desayunos, amenities) se descuenta del stock existente

**Endpoints clave:**
```
GET  /reservas/disponibilidad/?recurso=X&fecha_inicio=Y&fecha_fin=Z
POST /reservas/crear/
POST /reservas/{id}/confirmar/
POST /reservas/{id}/checkin/
POST /reservas/{id}/checkout/   <- genera la Venta automaticamente
GET  /reservas/calendario/      <- vista mensual para el panel
```

### 4.2 Ordenes de Trabajo (`apps/ordenes_trabajo/`)

**Para:** mecanicas, talleres electronicos, servicios tecnicos, lavanderia.

Cualquier negocio que recibe un bien del cliente, le hace trabajo, y lo devuelve.

**Modelos necesarios:**

```
OrdenTrabajo    — la OT principal
                  campos: cliente, descripcion_problema, fecha_ingreso, fecha_prometida,
                          estado, tecnico_asignado, diagnostico, observaciones_entrega
                  estados: recibido | diagnosticando | esperando_repuestos | en_proceso
                           | listo | entregado | cancelado
ItemOT          — trabajos/servicios a realizar
                  campos: descripcion, tipo (mano_de_obra | repuesto | servicio_externo),
                          cantidad, precio_unitario, completado
RepuestoOT      — repuestos consumidos de inventario
                  campos: producto (FK inventario), cantidad, costo_unitario
FotoOT          — fotos de ingreso y entrega (via MediaArchivo existente)
HistorialOT     — log de cambios de estado (inmutable, como LogActividad)
```

**Relacion con modulos existentes:**
- `RepuestoOT` descuenta del `Stock` existente con `MovimientoStock` tipo `salida`
- Al cerrar la OT se genera una `Venta` (conecta con ventas y facturacion existentes)
- El tecnico asignado es un `Usuario` del sistema existente

**Endpoints clave:**
```
POST /ordenes-trabajo/crear/
POST /ordenes-trabajo/{id}/asignar-tecnico/
POST /ordenes-trabajo/{id}/agregar-repuesto/    <- descuenta stock
POST /ordenes-trabajo/{id}/cambiar-estado/
POST /ordenes-trabajo/{id}/generar-venta/       <- cierre de OT
GET  /ordenes-trabajo/publico/{codigo}/         <- portal cliente sin auth (como seguimiento Amatista)
```

### 4.3 BOM / Recetas de Produccion (`apps/produccion/`)

**Para:** florerias, restaurantes, panaderias, manufactura ligera.

Cualquier negocio que **transforma insumos en productos finales** antes de venderlos.

Ya implementado en Amatista. Este es el modulo que hay que traer al template base como modulo opcional activable.

**Modelos necesarios:**

```
RecetaProducto      — la receta de un producto final
DetalleReceta       — cada insumo de la receta con cantidad y si es sustituible
AjustePersonalizacion — variacion de receta por pedido especifico (sin modificar receta base)
OrdenProduccion     — cuando se decide fabricar un lote del producto
DetalleConsumo      — log inmutable de insumos consumidos al producir (trazabilidad)
```

**Relacion con modulos existentes:**
- Los insumos son `Producto` del inventario existente con `tipo_registro = insumo`
- Al completar produccion se hace `MovimientoStock` entrada para el producto final y salida para cada insumo
- El `DetalleVenta` puede tener `estado_produccion` para el Kanban del productor

### 4.4 E-commerce API (`apps/ecommerce/`)

**Para:** cualquier negocio que quiera vender en linea ademas del POS fisico.

Este es el modulo mas critico para el crecimiento del producto. Hoy **no existe** en el template.

#### Donde entra el e-commerce en la arquitectura

El e-commerce no reemplaza el ERP ni vive dentro de el. Vive **al lado**, consumiendo la misma API:

```
Frontend del e-commerce (proyecto separado)
         ↓  consume API publica
Jsoluciones BE
  ├── inventario/  ← catalogo de productos (ya existe, falta endpoint publico)
  ├── ventas/      ← cada compra web genera una Venta (ya existe, falta tipo_venta=ecommerce)
  ├── distribucion/ ← si hay delivery, genera un Pedido (ya existe)
  └── facturacion/ ← emite boleta/factura automaticamente (ya existe)
```

El ERP gestiona los pedidos del e-commerce desde el panel administrativo, igual que gestiona las ventas del POS. No son dos sistemas separados — son dos canales de entrada al mismo backend.

#### Lo que ya existe y se puede reutilizar directamente

El **80% del backend del e-commerce ya existe** en el template:

| Componente e-commerce | Donde existe en el template | Estado |
|-----------------------|-----------------------------|--------|
| Catalogo de productos | `apps/inventario/Producto` | Existe. Falta endpoint publico sin JWT |
| Fotos del producto | `apps/media/MediaArchivo` | Existe. Falta asociacion al catalogo web |
| Control de stock | `registrar_salida()` en inventario | Existe. Falta reserva temporal con TTL |
| Crear Venta post-pago | `crear_venta_pos()` en ventas | Existe. Solo hay que pasar `tipo_venta="ecommerce"` |
| Canal de venta | `Venta.tipo_venta` | Campo existe en el modelo. Hoy siempre hardcodeado a `VENTA_DIRECTA` |
| Distribucion/Delivery | `apps/distribucion/Pedido` | Existe. Se conecta igual que una venta con delivery |
| Facturacion SUNAT | `apps/facturacion/` | Existe. Funciona igual para ventas web |
| Finanzas / Cobros | `apps/finanzas/Cobro` | Existe. El pago digital registra un Cobro igual |
| Tracking publico | Implementado en Amatista | Hay que traerlo al template base |

#### Lo que hay que agregar al modelo Producto (4 campos)

El inventario del ERP **es el mismo catalogo** del e-commerce. No hay un catalogo separado. Solo hay que agregar 4 campos al modelo existente:

```python
# Agregar a apps/inventario/models.py — Producto
slug             = models.SlugField(unique=True, blank=True)    # URL amigable: /productos/ramo-primavera
descripcion_larga = models.TextField(blank=True, default="")   # Texto completo con formato (hoy solo hay descripcion corta)
destacado        = models.BooleanField(default=False)           # Mostrar en portada del e-commerce
orden_display    = models.PositiveIntegerField(default=0)       # Orden de aparicion en el catalogo
```

Estos 4 campos no rompen nada de lo existente. El admin los llena desde la vista de productos del ERP (la misma vista que ya existe). El e-commerce los consume via el endpoint publico.

#### Lo que hay que crear

**Critico — sin esto el e-commerce no funciona:**

| Qué | Donde | Complejidad |
|-----|-------|-------------|
| Endpoint `GET /api/publico/productos/` sin JWT | `apps/inventario/urls_publicas.py` | Baja |
| Endpoint `GET /api/publico/categorias/` sin JWT | `apps/inventario/urls_publicas.py` | Baja |
| `CarritoWeb` + `ItemCarrito` con TTL en Redis | `apps/ecommerce/models.py` | Media |
| Reserva temporal de stock (TTL 15-30 min) | `apps/ecommerce/services.py` | Media |
| Endpoint `POST /api/publico/checkout/` | `apps/ecommerce/views.py` | Alta |
| Pasarela de pago (Culqi Peru o Stripe) | `apps/ecommerce/` | Alta |
| Campo `tipo_venta="ecommerce"` en el service | `apps/ventas/services.py` | Trivial |
| Panel ERP: filtrar ventas por `tipo_venta` | `apps/ventas/views.py` + FE | Baja |

**Importante — experiencia del cliente web:**

| Qué | Descripcion |
|-----|-------------|
| Perfil cliente web | Registro, login, historial de pedidos, direcciones guardadas |
| Cupones y descuentos | Por codigo, porcentaje o monto fijo, con limite de usos y fechas |
| Wishlist / favoritos | Lista de productos guardados por el cliente |
| Resenas y ratings | Calificacion 1-5 + comentario post-compra |
| Notificaciones por email | Confirmacion, cambio de estado, entrega confirmada |
| Devolucion desde el cliente | Solicitar devolucion con motivo, ver estado |

**Modelos a crear en `apps/ecommerce/`:**

```
CarritoWeb          — carrito del cliente web (sesion o usuario registrado)
                      campos: cliente_web (null si es anonimo), session_key, expira_en
ItemCarrito         — cada producto en el carrito
                      campos: carrito, producto, cantidad, precio_snapshot
                      La cantidad en carrito reserva stock temporalmente (TTL Redis)
PedidoEcommerce     — orden confirmada tras el pago
                      estados: pendiente_pago | pagado | en_preparacion | despachado | entregado | cancelado | reembolsado
                      Al confirmar: llama a crear_venta_pos() con tipo_venta="ecommerce"
DetallePedidoEcommerce — items confirmados (snapshot de precio al momento del pago)
PagoEcommerce       — registro del pago con referencia de la pasarela externa
DireccionEntrega    — direcciones guardadas del cliente web (para autocompletar)
ReseñaProducto      — calificacion 1-5 + comentario (solo clientes que compraron)
Cupon               — codigo, tipo (porcentaje/monto_fijo), usos_maximos, fecha_expiracion
```

**Relacion con modulos existentes:**
- `PedidoEcommerce.confirmar()` → llama a `crear_venta_pos()` con `tipo_venta="ecommerce"` (1 linea de cambio en el service existente)
- El pago registra un `Cobro` en `finanzas.Cobro` igual que un pago normal
- Si el negocio tiene delivery → `distribucion.crear_pedido()` igual que el Flujo B
- El stock se descuenta via `registrar_salida()` existente (sin cambios)
- Facturacion SUNAT → `emitir_comprobante_por_venta()` existente (sin cambios)
- Sincronizacion de stock en tiempo real → WebSocket existente ya emite cambios de stock

### 4.5 RRHH Basico (`apps/rrhh/`)

**Para:** hoteles, mecanicas, cualquier negocio con empleados y turnos.

**Modelos necesarios:**

```
Empleado        — datos laborales: cargo, fecha_ingreso, sueldo_base, turno_default
Turno           — definicion de turno: nombre, hora_inicio, hora_fin, dias_semana
AsignacionTurno — que empleado trabaja que turno que semana
Asistencia      — registro de entrada/salida (manual o via QR/biometrico)
Incidencia      — falta, tardanza, hora extra
```

**Relacion con modulos existentes:**
- El `Empleado` es un `Usuario` del sistema (relacion OneToOne con `PerfilUsuario`)
- Las horas extras pueden generar costos en finanzas existente

### 4.6 Programa de Lealtad (`apps/lealtad/`)

**Para:** retail, e-commerce, restaurantes, cualquier negocio que quiera fidelizar clientes.

**Modelos necesarios:**

```
CuentaLealtad   — puntos acumulados por cliente
MovimientoLealtad — acumulacion o canje de puntos (inmutable)
ReglaPuntos     — X puntos por cada S/. Y gastado, multiplicadores por producto/categoria
RecompensaLealtad — que se puede canjear con puntos
```

**Relacion con modulos existentes:**
- Cada `Venta` completada dispara acumulacion de puntos via signal o `transaction.on_commit`
- El canje de puntos genera un descuento en la siguiente `Venta`
- El cliente web ve su saldo en el perfil del e-commerce

### 4.7 Multi-sucursal (`apps/sucursales/`)

**Para:** cadenas con mas de una tienda o punto de venta.

Aclaracion: el template sigue siendo **single-tenant** (una empresa por instalacion). Multi-sucursal significa que la misma empresa tiene varias ubicaciones fisicas, cada una con su propio stock, caja y personal.

**Modelos necesarios:**

```
Sucursal        — nombre, direccion, telefono, esta_activa
```

**Lo que cambia en modulos existentes:**
- `Almacen` ya existe. Solo hay que relacionarlo con `Sucursal` (FK)
- `Caja` se relaciona con `Sucursal`
- Los `PerfilUsuario` se asignan a una `Sucursal` (campo ya planificado: `sucursal_default`)
- Los reportes filtran por sucursal
- Los permisos RBAC ya soportan `SoloSusDatos` — extenderlo a `SoloDeSuSucursal`

---

## 5. Que hacer al hacer fork del template

Cuando una empresa nueva quiere usar JSoluciones, el proceso es:

### Paso 1 — Fork y configuracion base (1 dia)

```bash
# Fork del repo template
git clone https://github.com/jsoluciones/template-be mi-empresa-be
git clone https://github.com/jsoluciones/template-fe mi-empresa-fe

# Configurar entorno
cp .env.example .env
# Editar .env: DB_NAME, SECRET_KEY, NUBEFACT_TOKEN, R2_*, etc.

# Crear DB y correr migraciones
createdb mi_empresa
python manage.py migrate

# Cargar datos base de la empresa
python manage.py setup_empresa \
  --ruc=20XXXXXXXXX \
  --razon_social="Mi Empresa S.A.C." \
  --color_primario="#2563EB" \
  --color_superficie="#F0F4FF" \
  --nombre_sistema="Mi Empresa ERP"

# Activar/desactivar modulos segun el negocio
python manage.py configurar_modulos \
  --activar pos,inventario,facturacion,finanzas,compras,reportes,whatsapp \
  --desactivar distribucion,ecommerce,reservas,bom,rrhh,lealtad
```

### Paso 2 — Identidad visual (2 horas)

Solo hay que cambiar los tokens en el `.env` de la empresa. El FE los lee de la API al bootear:

```
COLOR_PRIMARIO=#2563EB
COLOR_SUPERFICIE=#F0F4FF
NOMBRE_SISTEMA=Mi Empresa ERP
LOGO_URL=https://r2.miempresa.com/logo.png
```

No hay que tocar `tailwind.config.ts`, `themes.css`, ni ningun archivo de codigo para cambiar la identidad visual.

### Paso 3 — Modulos especificos del negocio (variable)

Si el negocio necesita algo que no esta en el template base:

```
apps/
  reservas/     <- hotel o mecanica: copiar desde el modulo opcional
  bom/          <- floreria o restaurante: copiar desde el modulo opcional
  ordenes_trabajo/ <- mecanica: copiar desde el modulo opcional
  ecommerce/    <- tienda online: copiar desde el modulo opcional
```

Cada modulo opcional tiene su propio `models.py`, `services.py`, `views.py`, `urls.py` y migraciones. No modifica ninguno de los modulos base.

---

## 6. Relaciones entre modulos

```
                    ┌─────────────┐
                    │   Empresa   │  singleton — configuracion + modulos_activos
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
   │  Usuarios/  │  │ Inventario  │  │  Clientes   │
   │   Roles     │  │  + Stock    │  │             │
   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
          │                │                │
          └────────┬───────┘                │
                   │                        │
          ┌────────▼────────┐               │
          │  Ventas / POS   │◄──────────────┘
          │  (+ Ecommerce)  │
          └────────┬────────┘
                   │
          ┌────────┼──────────────────┐
          │        │                  │
   ┌──────▼──────┐ ┌▼────────────┐  ┌▼─────────────┐
   │ Facturacion │ │ Distribucion│  │   Finanzas   │
   │   SUNAT     │ │  / Delivery │  │  CxC / CxP  │
   └─────────────┘ └─────────────┘  └─────────────┘
          │
   ┌──────▼────────────────────────────┐
   │ Compras / Proveedores             │
   │ (cierra el ciclo: insumo → venta) │
   └───────────────────────────────────┘

Modulos opcionales (se conectan a los base sin modificarlos):

   BOM/Produccion ──► Inventario (consume stock de insumos, produce stock de producto final)
   Reservas       ──► Ventas (checkout genera Venta), Finanzas (anticipo genera CxC)
   Ordenes Trabajo ──► Inventario (consume repuestos), Ventas (cierre genera Venta)
   Ecommerce      ──► Inventario (reserva y descuenta stock), Ventas (pedido confirmado = Venta)
                      Distribucion (despacho genera Pedido delivery), Finanzas (pago genera Cobro)
   RRHH           ──► Usuarios (Empleado es PerfilUsuario extendido)
   Lealtad        ──► Ventas (acumula puntos en cada Venta), Clientes (CuentaLealtad)
   Multi-sucursal ──► Inventario (Almacen por Sucursal), Ventas (Caja por Sucursal)
   WhatsApp       ──► Ventas (notifica post-venta), Distribucion (notifica cambio de estado pedido)
```

---

## 7. Cronograma por etapas (prioridad sugerida)

### Etapa 0 — Completar lo que ya existe (ahora)
Terminar los pendientes del template base antes de agregar modulos nuevos.

| Tarea | Modulo afectado |
|-------|----------------|
| WhatsApp envio real a Meta | WhatsApp (~57%) |
| Mapa visual de distribucion (react-leaflet) | Distribucion |
| POS offline con IndexedDB | Ventas |
| Tracking publico de pedidos (traer de Amatista) | Distribucion |
| Portal conductor (traer de Amatista) | Distribucion |

### Etapa 1 — Hacer el template dinamico (antes de cualquier fork nuevo)
Sin esto, cada fork sigue siendo costoso.

| Tarea | Donde |
|-------|-------|
| Agregar campos de identidad visual al modelo `Empresa` | `apps/empresa/models.py` |
| Endpoint `GET /empresa/configuracion/` retorna colores + modulos_activos | `apps/empresa/views.py` |
| Management command `configurar_modulos` | `core/management/` |
| FE lee colores de la API al bootear y aplica CSS variables | `ProvidersWrapper.tsx` |
| FE lee `modulos_activos` y oculta secciones del menu | `menu.ts` + `ProtectedRoute.tsx` |
| Separar `core/choices.py` en `choices.py` + `choices_negocio.py` | `core/` |
| PDFs leen colores y nombre de `Empresa` en vez de hardcodeado | Todos los `services.py` con ReportLab |

### Etapa 2 — E-commerce API (alto impacto de negocio)

| Tarea | Prioridad |
|-------|-----------|
| Endpoints publicos de catalogo sin auth | Alta |
| Modelo `CarritoWeb` + `ItemCarrito` con TTL de reserva | Alta |
| Modelo `PedidoEcommerce` con su maquina de estados | Alta |
| Integracion Culqi (pasarela peruana) | Alta |
| Panel en ERP para gestionar pedidos web | Media |
| Cupones y descuentos por codigo | Media |
| Perfil del cliente web (registro, historial) | Media |
| Resenas y wishlist | Baja |

### Etapa 3 — Modulos opcionales (segun demanda de clientes)

Implementar en este orden segun los clientes que lleguen:

1. **Reservas/Citas** — hotel o mecanica son los mas probables despues de la floreria
2. **Ordenes de Trabajo** — mecanica
3. **BOM/Produccion** — traer de Amatista al template base (ya esta probado)
4. **RRHH Basico** — hotel, mecanica
5. **Programa de Lealtad** — e-commerce, retail
6. **Multi-sucursal** — cuando un cliente crezca a mas de 1 local

---

## 8. Design System del template (referencia)

El template usa la identidad visual de JSoluciones como punto de partida. Al hacer fork, el cliente la reemplaza via la API (`Empresa.color_primario`, etc.) sin tocar codigo.

| Token | Nombre | Hex (template base) | Variable CSS |
|-------|--------|---------------------|--------------|
| `primary` | Terracota | `#D65A42` | `--color-primary` |
| `brand-dark` | Negro Carbon | `#1A1A1A` | `--color-brand-dark` |
| `brand-body` | Gris Pizarra | `#555555` | `--color-brand-body` |
| `brand-surface` | Blanco Crema | `#F9F7F2` | `--color-brand-surface` |
| `brand-border` | Gris Nube | `#E8E8E8` | `--color-brand-border` |
| `brand-accent` | Gris Topo | `#9E9188` | `--color-brand-accent` |

Tipografia del template: **Playfair Display** (titulos H1-H3) + **Inter** (cuerpo y UI).

Ver `Jsoluciones-fe/DESIGN_SYSTEM.md` para detalle completo.

---

## 9. Lo que NO hace este template

Para evitar confusion al hacer fork:

- **No es multi-tenant**: una instalacion = una empresa. Si dos empresas usan el sistema, son dos instalaciones separadas con su propia DB y backend.
- **No es SaaS listo para usar**: requiere un desarrollador para hacer el fork, configurar el entorno y adaptar los modulos del negocio.
- **No reemplaza un sistema de contabilidad completo**: genera los libros PLE para SUNAT y los asientos contables, pero no es un sistema contable con plan de cuentas personalizable al nivel de un ERP contable especializado.
- **No tiene app movil nativa**: hay portales web responsivos (conductor, seguimiento publico) pero no apps iOS/Android en stores.
