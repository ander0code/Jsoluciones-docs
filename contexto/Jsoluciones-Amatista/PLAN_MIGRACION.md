# PLAN DE MIGRACION: Amatista → JSoluciones

> Fecha: 2026-02-21
> Este documento describe COMO seria la migracion, NO la ejecuta
> Prerequisito: JSoluciones debe estar 100% completo antes de migrar

---

## COMPLEJIDAD DE MIGRACION POR AREA

| Area | Complejidad | Motivo |
|---|---|---|
| Productos | 🟢 Baja | Solo mapear campos simples a modelo mas completo |
| Usuarios | 🟢 Baja | Mapear 3 roles fijos a sistema de roles dinamicos |
| Datos de pedidos | 🟡 Media | Requiere agregar campos especificos (destinatario, turno, dedicatoria) |
| Flujo de estados | 🟡 Media | Agregar estado REPROGRAMADO y ajustar maquina de estados |
| Conductores → Transportistas | 🟡 Media | Agregar portal con token, preferencia distrito, GPS |
| Produccion | 🔴 Alta | Modulo completamente nuevo que no existe en JSoluciones |
| PDFs de entrega | 🔴 Alta | Funcionalidad nueva (JSoluciones solo tiene PDFs de Nubefact) |
| Mapa | 🔴 Alta | Requiere integracion con mapas (Leaflet/Google Maps) |
| Auditoria mejorada | 🟡 Media | Agregar datos antes/despues, IP, inmutabilidad |
| Excel export | 🟢 Baja | Implementar la logica (el STUB ya existe) |

---

## MIGRACION DE DATOS

### Tabla: productos → inventario_producto

```
AMATISTA                    JSOLUCIONES
─────────────────────────   ──────────────────────────────
nombre                  →   nombre
precio                  →   precio_venta
imagen                  →   MediaAsset (entidad separada)
stock                   →   Stock.cantidad (tabla separada)
activo                  →   activo
(no tiene)                  descripcion = ''
(no tiene)                  sku = auto-generar
(no tiene)                  codigo_barras = null
(no tiene)                  precio_compra = precio * 0.6 (estimado)
(no tiene)                  stock_minimo = 5 (default)
(no tiene)                  unidad_medida = 'UNIDAD'
(no tiene)                  almacen = almacen principal
```

### Tabla: conductores → distribucion_transportista

```
AMATISTA                    JSOLUCIONES
─────────────────────────   ──────────────────────────────
nombre                  →   nombre (o split en nombre/apellido)
telefono                →   telefono
activo                  →   activo
token                   →   NUEVO: campo token para portal
preferencia_distrito    →   NUEVO: campo preferencia_zona
last_lat/lng            →   NUEVO: campos GPS
last_location_at        →   NUEVO: timestamp ultima ubicacion
```

### Tabla: reporte_entregas → distribucion_pedido

```
AMATISTA                    JSOLUCIONES
─────────────────────────   ──────────────────────────────
nombre_cliente          →   cliente_id (buscar o crear)
telefono_cliente        →   cliente.telefono
fecha_compra            →   created_at
fecha_entrega           →   fecha_entrega_estimada
turno_entrega           →   NUEVO: campo turno_entrega
observacion             →   observaciones
nombre_destinatario     →   NUEVO: campo nombre_destinatario
telefono_destinatario   →   NUEVO: campo telefono_destinatario
distrito                →   direccion (texto libre, no enum)
direccion_destinatario  →   direccion_detalle
enlace_ubicacion        →   NUEVO: campo enlace_ubicacion
tipo_ubicacion          →   NUEVO: campo tipo_ubicacion
dedicatoria             →   NUEVO: campo dedicatoria
costo_delivery          →   NUEVO: campo costo_delivery
metodo_pago             →   metodo_pago (mapear enums)
estado                  →   estado (mapear: reprogramado es nuevo)
conductor_id            →   transportista_id
foto_entrega            →   EvidenciaEntrega.foto
observacion_conductor   →   SeguimientoPedido.descripcion
estado_produccion       →   NUEVO: campo o tabla separada
es_urgente              →   NUEVO: campo prioridad
created_by              →   creado_por (user_id)
```

### Tabla: item_reportes → distribucion_pedido_item

```
AMATISTA                    JSOLUCIONES
─────────────────────────   ──────────────────────────────
reporte_id              →   pedido_id
producto_id             →   producto_id
cantidad                →   cantidad
precio_unitario         →   precio_unitario
```

### Tabla: auditoria → usuarios_logactividad

```
AMATISTA                    JSOLUCIONES
─────────────────────────   ──────────────────────────────
user_id                 →   usuario_id
user_nombre             →   (obtener de relacion)
accion                  →   accion
modelo                  →   modulo
registro_id             →   entidad_id
datos_anteriores        →   NUEVO: campo datos_anteriores
datos_nuevos            →   NUEVO: campo datos_nuevos
ip                      →   NUEVO: campo ip
created_at              →   fecha
```

---

## MAPEO DE ENUMS

### Estado (Amatista) → Estado Pedido (JSoluciones)

| Amatista | JSoluciones | Accion |
|---|---|---|
| `pendiente` | `PENDIENTE` | Mapeo directo |
| `en_ruta` | `EN_RUTA` | Mapeo directo |
| `entregado` | `ENTREGADO` | Mapeo directo |
| `no_entregado` | `DEVUELTO` | Mapeo aproximado |
| `reprogramado` | **No existe** | Agregar a JSoluciones |
| `cancelado` | `CANCELADO` | Mapeo directo |

### MetodoPago (Amatista) → FormasPago (JSoluciones)

| Amatista | JSoluciones |
|---|---|
| `yape` | Crear si no existe |
| `plin` | Crear si no existe |
| `efectivo` | `EFECTIVO` |
| `izipay` | `TARJETA` / Crear especifico |
| `payum` | Crear si no existe |
| `bcp`, `interbank`, `bbva`, `scotiabank`, `bn` | `TRANSFERENCIA` / Crear especificos |
| `otro` | `OTRO` |

### Rol (Amatista) → Roles (JSoluciones)

| Amatista | JSoluciones |
|---|---|
| `admin` | Rol "Administrador" con todos los permisos |
| `vendedor` | Rol "Vendedor" con permisos: ventas.*, inventario.ver, clientes.*, distribucion.crear |
| `produccion` | Crear rol "Produccion" con permisos del modulo de produccion |

### Distrito (Amatista) → Direccion (JSoluciones)

Amatista usa un enum con 48 distritos de Lima. JSoluciones usa texto libre para direcciones.

**Opciones:**
1. Mantener los distritos como catalogo configurable en JSoluciones
2. Migrar como parte de la direccion en texto libre
3. Agregar campo `distrito` como filtro adicional

---

## ORDEN DE IMPLEMENTACION SUGERIDO

### Fase 1: Campos y ajustes al modelo de distribucion
1. Agregar campos al modelo Pedido: turno, destinatario, dedicatoria, costo_delivery, enlace_ubicacion, tipo_ubicacion, es_urgente
2. Agregar estado REPROGRAMADO a la maquina de estados
3. Agregar campo preferencia_distrito a Transportista
4. Implementar descuento de stock al crear pedido
5. Implementar restauracion de stock al editar/cancelar

### Fase 2: Portal del conductor
1. Endpoint publico GET /distribucion/portal/{token}/ (sin JWT)
2. Endpoint POST /distribucion/portal/{token}/confirmar/{id}/
3. Endpoint POST /distribucion/portal/{token}/ubicacion/
4. Rate limiting especifico para portal
5. Frontend: pagina PWA simple para conductores

### Fase 3: Asignacion masiva
1. Endpoint POST /distribucion/pedidos/asignar-masivo/
2. Creacion rapida de transportista
3. Cambio automatico a EN_RUTA al asignar

### Fase 4: Modulo de produccion
1. Modelo EstadoProduccion o campo en Pedido
2. Servicio con transiciones validadas
3. ViewSet con endpoints de cambio de estado
4. Frontend: vista Kanban con 3 columnas
5. Resumen de materiales necesarios

### Fase 5: Mapa y GPS
1. Integracion con Leaflet o Google Maps
2. Coordenadas por distrito/zona
3. Tracking GPS del conductor
4. Vista de mapa con filtros

### Fase 6: Documentos
1. Generacion de PDF de entrega
2. Generacion de PDF interno
3. Conversion PDF → imagen
4. Export Excel funcional

### Fase 7: Migracion de datos
1. Script de migracion de datos historicos
2. Validacion de integridad
3. Corte y cambio

---

## RIESGOS Y CONSIDERACIONES

1. **Amatista usa SQLite, JSoluciones usa PostgreSQL**: La migracion de datos es sencilla pero hay que tener cuidado con tipos de datos (ej: boolean, datetime)

2. **Enums hardcodeados vs dinamicos**: Amatista usa PHP enums (fijos en codigo). JSoluciones puede usar tablas de catalogo para mayor flexibilidad

3. **Portal del conductor**: Es una funcionalidad critica para Amatista. Si se migra sin ella, los conductores pierden acceso al sistema

4. **Produccion**: Si el negocio de Amatista requiere el flujo de produccion, hay que construirlo de cero en JSoluciones

5. **PDFs personalizados**: Los PDFs de entrega de Amatista son criticos para el negocio (van dentro del paquete). Hay que replicar el diseno exacto

6. **Rendimiento**: Amatista funciona con SQLite para un volumen bajo. JSoluciones con PostgreSQL escala mucho mejor, pero hay que asegurar que los queries del mapa y dashboard no sean pesados

7. **UX**: Amatista es server-side (recarga de pagina). JSoluciones es SPA (mas fluido). Los usuarios de Amatista pueden necesitar adaptacion
