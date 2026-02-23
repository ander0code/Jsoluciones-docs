# COMPARATIVA: JSoluciones POS vs Laravel-Amatista

> Fecha: 2026-02-21
> Metodo: Revision archivo por archivo de ambos proyectos (modelos, servicios, controladores, rutas, enums, vistas)
> Objetivo: Identificar que funcionalidades de Amatista ya cubre JSoluciones, que falta, y como seria la migracion

---

## RESUMEN EJECUTIVO

| Aspecto | JSoluciones | Laravel-Amatista |
|---|---|---|
| **Tipo de sistema** | ERP completo (9 modulos) | Sistema de gestion de entregas especializado |
| **Negocio** | Punto de venta generico multi-rubro | Floreria / regalos con delivery |
| **Stack** | Django + DRF + React + Vite | Laravel + Blade (monolitico) |
| **Arquitectura** | API REST (SPA) | MVC server-side rendering |
| **BD** | PostgreSQL | SQLite |
| **Auth** | JWT (access + refresh) | Session-based (Laravel Auth) |
| **Avance** | ~67% del spec completo | Sistema funcional en produccion |

### Veredicto

**JSoluciones es significativamente mas completo** que Amatista en casi todas las areas. Amatista tiene exactamente **3 funcionalidades** que JSoluciones no tiene aun o tiene implementadas de forma diferente:

1. **Portal del conductor** (acceso por token sin login, confirmacion con foto)
2. **Modulo de produccion** (flujo pendiente → armando → listo con urgencias)
3. **Mapa de entregas** (visualizacion por distrito con coordenadas de conductores)

Todo lo demas que hace Amatista ya lo cubre JSoluciones con mayor profundidad.

---

## MAPEO DE MODULOS: Amatista → JSoluciones

| Funcionalidad Amatista | Modulo JSoluciones Equivalente | Estado en JSoluciones |
|---|---|---|
| Reportes de entrega (pedidos) | Modulo 4: Distribucion | 32% |
| Productos | Modulo 2: Inventario | 57% |
| Conductores | Modulo 4: Distribucion (transportistas) | 32% |
| Usuarios y roles | Modulo 9: Usuarios y Roles | 67% |
| Auditoria | Gap transversal (resuelto) | ✅ Implementado |
| Dashboard | Modulo 8: Dashboard y Reportes | 50% |
| Metodos de pago | Modulo 1: Ventas/POS | 82% |
| Produccion | **No existe en JSoluciones** | ❌ Sin equivalente |
| Portal del conductor | Modulo 4: Distribucion | ❌ No implementado |
| Mapa de entregas | Modulo 4: Distribucion | ❌ No implementado |
| Excel export | Modulo 8: Dashboard (STUB) | ❌ Sin logica real |

---

## COMPARATIVA DETALLADA POR AREA

### 1. GESTION DE PEDIDOS / ENTREGAS

Esta es la funcionalidad **central** de Amatista y corresponde al **Modulo 4 (Distribucion)** de JSoluciones.

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Crear pedido con items | ✅ ReporteEntrega + ItemReporte | ✅ Pedido via ViewSet |
| Estados del pedido | 6: pendiente, en_ruta, entregado, no_entregado, reprogramado, cancelado | 7: PENDIENTE, CONFIRMADO, DESPACHADO, EN_RUTA, ENTREGADO, CANCELADO, DEVUELTO |
| Maquina de estados validada | ❌ Cambio libre (cualquier estado a cualquier estado) | ✅ Transiciones validadas en servicio |
| Datos del destinatario | ✅ nombre, telefono, distrito, direccion, enlace_ubicacion, tipo_ubicacion | ⚠️ Solo direccion basica (sin dedicatoria, tipo ubicacion, enlace maps) |
| Dedicatoria | ✅ Campo dedicatoria en el pedido | ❌ No existe |
| Turno de entrega (AM/PM) | ✅ Enum Turno con rango horario | ❌ No existe el concepto de turno |
| Asignar conductor | ✅ Masiva (multiples pedidos a un conductor) | ✅ Individual (un pedido a un transportista) |
| Confirmar entrega con foto | ✅ Conductor sube foto desde portal | ✅ Modelo EvidenciaEntrega (foto, firma, OTP) |
| Evidencia obligatoria | ❌ Foto es opcional | ✅ Minimo una evidencia requerida (spec) |
| Observacion del conductor | ✅ Campo libre | ⚠️ Via SeguimientoPedido (mas estructurado) |
| Reprogramar pedido | ✅ Estado REPROGRAMADO | ❌ No existe el estado |
| Costo de delivery separado | ✅ Campo costo_delivery | ❌ No existe |
| Fecha de compra vs entrega | ✅ Dos fechas separadas | ⚠️ Solo fecha de creacion |
| Filtros avanzados | ✅ Estado, distrito, turno, conductor, fecha, producto | ⚠️ Solo busqueda y estado |
| Paginacion | ✅ 50 por pagina con query string | ✅ Cursor pagination |
| Resumen de productos filtrados | ✅ Muestra conteo de productos cuando hay filtros activos | ❌ No existe |

**Diferencias de logica importantes:**

1. **Stock al crear pedido**: Amatista descuenta stock al CREAR el pedido (con `lockForUpdate`). JSoluciones tiene la logica de reservar stock al crear pedido, pero NO esta implementada (pendiente). JSoluciones descuenta stock solo via ventas POS.

2. **Restaurar stock al editar**: Amatista restaura el stock antiguo y descuenta el nuevo al editar un pedido. JSoluciones no tiene esta logica en distribucion.

3. **Stock null = ilimitado**: En Amatista, si `producto.stock` es `null`, se considera stock ilimitado (no valida). En JSoluciones el stock siempre se valida con `Stock` model separado.

---

### 2. PRODUCTOS

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Campos basicos | nombre, precio, imagen, stock, activo | nombre, descripcion, SKU, codigo_barras, precio_compra, precio_venta, stock_minimo, unidad_medida, categoria, marca, etc. |
| Imagen | ✅ Una imagen (DigitalOcean Spaces o local) | ✅ Multiples imagenes via MediaAsset (Cloudflare R2) |
| Categorias | ❌ No tiene | ✅ CRUD completo |
| SKU / Codigo barras | ❌ No tiene | ✅ Implementado + escaneo en POS |
| Control de stock | ✅ Campo directo en tabla producto | ✅ Tabla Stock separada (por producto + almacen) |
| Multi-almacen | ❌ Stock unico global | ✅ Stock por almacen |
| Lotes / vencimiento | ❌ No tiene | ✅ Modelo Lote con fecha vencimiento |
| Precio con IGV | ❌ Precio simple sin impuestos | ✅ Calculo de subtotal + IGV 18% |

**JSoluciones es vastamente mas completo en productos.** Amatista tiene un modelo de producto minimalista pensado para flores/regalos.

---

### 3. CONDUCTORES / TRANSPORTISTAS

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| CRUD | ✅ Completo (admin only) | ✅ Modelo Transportista |
| Campos | nombre, telefono, activo, preferencia_distrito, ubicacion, token, GPS | Campos basicos (modelo menor) |
| Portal sin login | ✅ Acceso por token UUID unico | ❌ No existe |
| GPS del conductor | ✅ Guarda lat/lng via POST desde portal | ⚠️ SeguimientoPedido tiene coords pero el tracking GPS cada 30s es STUB |
| Preferencia de distrito | ✅ Campo para asignacion inteligente | ❌ No existe |
| Rate limiting en portal | ✅ Throttle 60/min general, 15/min confirmaciones | ❌ No aplica |
| Validar capacidad | ❌ No tiene | ⚠️ Spec lo pide pero no implementado |

**El portal del conductor de Amatista es una funcionalidad clave que JSoluciones no tiene.** Permite al conductor ver sus entregas asignadas, actualizar su ubicacion, y confirmar entregas con foto, todo sin necesidad de cuenta o login.

---

### 4. USUARIOS Y ROLES

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Roles | 3 fijos: admin, vendedor, produccion | Dinamicos: tabla Rol con permisos configurables |
| Permisos | Hardcoded en middleware (isAdmin, canAccessProduccion) | Granulares por modulo+accion (tabla RolPermiso) |
| Auth | Session-based (Laravel) | JWT access/refresh con rotacion |
| 2FA | ❌ No | ⚠️ Campo existe pero sin logica |
| SSO | ❌ No | ⚠️ Botones decorativos |
| Cambio de password | ✅ Forzar al primer login | ⚠️ No fuerza cambio |
| Audit log acceso denegado | ✅ Registra intentos de acceso no autorizado | ❌ No registra |
| Rate limiting login | ✅ Throttle global | ✅ Rate limiting configurado |

**JSoluciones tiene un sistema de permisos mucho mas flexible**, pero Amatista tiene mejor forzado de cambio de password y registro de accesos denegados.

---

### 5. AUDITORIA

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Modelo | Auditoria (tabla auditoria) | LogActividad (apps/usuarios/models) |
| Trait automatico | ✅ Trait `Auditable` en modelos | ✅ Signals Django |
| Datos antes/despues | ✅ JSON completo del registro | ❌ Solo registra operacion, no detalle |
| Inmutable | ✅ Bloquea update y delete en el modelo | ⚠️ No hay validacion explicita |
| Acciones registradas | created, updated, deleted, login, password_changed, unauthorized_access | Crear/modificar operaciones criticas |
| UI de auditoria | ✅ Pagina con filtros, iconos, badges | ❌ No existe pagina |
| IP del usuario | ✅ Registra IP | ❌ No registra |
| Traduccion de campos | ✅ `traducirCampo()` para mostrar nombres legibles | ❌ No aplica |

**Amatista tiene un sistema de auditoria superior**: guarda datos antes/despues, es verdaderamente inmutable, registra IP, y tiene interfaz web. JSoluciones registra operaciones pero sin el detalle del antes/despues.

---

### 6. MODULO DE PRODUCCION

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Estado de produccion | ✅ pendiente → armando → listo | ❌ **No existe** |
| Transiciones validadas | ✅ Solo permitidas: pendiente→armando, armando→listo, listo→armando | - |
| Timestamps de produccion | ✅ produccion_iniciada_en, produccion_completada_en | - |
| Vista Kanban | ✅ 3 columnas (pendiente, armando, listo) | - |
| Flag urgente | ✅ es_urgente (manual) + auto (>30min o pedido temprano para hoy) | - |
| Resumen de materiales | ✅ Suma productos pendientes (excluyendo chocolates/adicionales) | - |
| Acceso por rol | ✅ Admin + Produccion | - |
| Filtro por turno | ✅ Manana/Tarde | - |

**Este modulo NO tiene equivalente en JSoluciones.** Es especifico para negocios donde los productos se "arman" o "producen" bajo pedido (flores, regalos, comida). Si Amatista se migra a JSoluciones, habria que crear un modulo de produccion o adaptarlo.

---

### 7. DASHBOARD

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| KPIs cards | ✅ Total, pendientes, en ruta, entregados, tasa exito | ✅ Ventas hoy, mes, bajo stock, pedidos pendientes |
| Entregas por estado | ✅ Grafico | ❌ No existe para distribucion |
| Entregas por distrito | ✅ Top 10 | ❌ No aplica |
| Tendencia diaria | ✅ Grafico de linea (7 o 30 dias) | ✅ Area chart ventas diarias |
| Top vendedores | ✅ Por cantidad de pedidos | ❌ Endpoint existe pero sin parametrizar |
| Top productos | ✅ Mas pedidos en periodo | ✅ Top 5 por cantidad vendida |
| Filtro por periodo | ✅ Hoy, semana, mes | ✅ Date range picker |
| Reporte vendedores dedicado | ✅ Pagina completa con desglose por estado y monto | ❌ Solo endpoint basico |

**Ambos tienen dashboard funcional**, pero orientados a metricas distintas. JSoluciones enfoca ventas; Amatista enfoca entregas/logistica.

---

### 8. MAPA DE ENTREGAS

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Mapa interactivo | ✅ Con puntos por distrito | ❌ **No implementado** (spec lo pide) |
| Ubicacion conductores | ✅ Muestra conductores con GPS reciente (<120 min) | ❌ No implementado |
| Filtros en mapa | ✅ Fecha, estado, turno, conductor | - |
| Coordenadas por distrito | ✅ Helper `DistritoCoordinates` con offset aleatorio | - |

---

### 9. PDF E IMAGENES

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| PDF de entrega | ✅ PDF personalizado (15.5x21cm) con productos e imagenes | ❌ Solo PDF de Nubefact (comprobantes) |
| PDF interno | ✅ PDF A4 con datos completos + creado por | ❌ No existe |
| Conversion a imagen | ✅ PDF → PNG/JPG via Ghostscript (para WhatsApp) | ❌ No existe |
| Imagenes de productos en PDF | ✅ Base64 embebido | ❌ No aplica |

**Amatista genera PDFs de entrega personalizados** que el negocio usa para incluir en los paquetes y enviar por WhatsApp. JSoluciones solo genera PDFs de comprobantes via Nubefact.

---

### 10. ASIGNACION MASIVA

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Asignar multiples pedidos a conductor | ✅ Seleccion checkbox + conductor | ❌ Solo individual |
| Crear conductor al vuelo | ✅ Si no existe, lo crea en el momento | ❌ CRUD separado |
| Filtros de asignacion | ✅ Fecha + distritos (multi-select) | ❌ No aplica |
| Portal URL generada | ✅ Devuelve link del portal al asignar | ❌ No aplica |
| Cambio automatico a EN_RUTA | ✅ Al asignar conductor, cambia estado si era PENDIENTE | ✅ Endpoint POST /despachar/ |

---

### 11. EXPORTACION EXCEL

| Caracteristica | Amatista | JSoluciones |
|---|---|---|
| Export con filtros | ✅ Usa Maatwebsite\Excel con filtros activos | ❌ STUB (task existe sin logica) |
| Formato | ✅ .xlsx funcional | ❌ No genera archivo |

---

### 12. FUNCIONALIDADES QUE JSOLUCIONES TIENE Y AMATISTA NO

JSoluciones es un ERP completo. Estas son las areas donde Amatista no tiene equivalente:

| Modulo JSoluciones | Lo tiene Amatista? |
|---|---|
| POS con carrito y multiples metodos de pago | ❌ No es POS, solo pedidos |
| Cotizaciones y ordenes de venta | ❌ No |
| Apertura/cierre de caja con arqueo | ❌ No |
| Inventario multi-almacen con transferencias | ❌ Solo stock simple |
| Lotes y vencimientos | ❌ No |
| Facturacion electronica (Nubefact) | ❌ No |
| Notas de credito/debito | ❌ No |
| Compras y ordenes de compra | ❌ No |
| Proveedores con KPIs | ❌ No |
| Recepciones de mercaderia | ❌ No |
| Cuentas por cobrar y pagar | ❌ No |
| Plan contable y asientos | ❌ No |
| WhatsApp integration | ❌ No |
| Escaneo de codigo de barras | ❌ No |
| Modo contingencia facturacion | ❌ No |

---

## DIFERENCIAS DE LOGICA CLAVE (NO SOLO CAMPOS)

### 1. Flujo de stock

```
AMATISTA:
  Crear pedido → lockForUpdate → validar stock → descontar → crear items
  Editar pedido → restaurar stock antiguo → validar nuevo → descontar nuevo
  Stock null = ilimitado

JSOLUCIONES:
  Venta POS → select_for_update → validar stock → descontar (atomico)
  Distribucion → NO descuenta stock al crear pedido (pendiente implementar)
  Stock se maneja en tabla separada Stock(producto_id, almacen_id, cantidad)
```

**Implicacion para migracion**: Si Amatista necesita que el stock se descuente al crear el pedido de entrega, hay que implementar esa logica en el servicio de distribucion de JSoluciones.

### 2. Flujo de estados

```
AMATISTA (cambio libre, sin validacion):
  pendiente ←→ en_ruta ←→ entregado
  pendiente ←→ no_entregado
  pendiente ←→ reprogramado
  pendiente ←→ cancelado
  (cualquier combinacion es valida)

JSOLUCIONES (maquina de estados estricta):
  PENDIENTE → CONFIRMADO → DESPACHADO → EN_RUTA → ENTREGADO
  Cualquier estado → CANCELADO
  EN_RUTA → DEVUELTO
```

**Implicacion para migracion**: Amatista es mas flexible pero menos seguro. JSoluciones ya implementa las transiciones de forma correcta. El estado REPROGRAMADO de Amatista no existe en JSoluciones; habria que agregarlo si el negocio lo necesita.

### 3. Asignacion de conductor

```
AMATISTA:
  Admin selecciona N pedidos + 1 conductor → DB::transaction + lockForUpdate
  Si estado es PENDIENTE → cambia a EN_RUTA automaticamente
  Almacena nombre_conductor y telefono_conductor redundantemente en reporte
  Puede crear conductor nuevo al vuelo

JSOLUCIONES:
  POST /pedidos/{id}/asignar/ → individual
  POST /pedidos/{id}/despachar/ → cambia a DESPACHADO
  No tiene asignacion masiva
  Solo asigna transportistas existentes
```

**Implicacion para migracion**: Falta implementar asignacion masiva y la creacion rapida de transportista en JSoluciones.

### 4. Confirmacion de entrega

```
AMATISTA:
  Conductor accede por URL con token (sin login)
  Sube foto (opcional) + observacion + selecciona estado
  Todo en una transaccion con lockForUpdate

JSOLUCIONES:
  EvidenciaEntrega con foto + firma + OTP
  Modelo mas robusto pero NO tiene portal publico
  Requiere JWT para acceder a la API
```

**Implicacion para migracion**: Hay que crear un portal publico de conductor o una PWA que funcione con tokens como Amatista.

### 5. Produccion

```
AMATISTA:
  estado_produccion: pendiente → armando → listo (con reversion listo → armando)
  Timestamps: produccion_iniciada_en, produccion_completada_en
  Flag urgente: manual + automatico (>30min o pedido temprano del dia)
  Vista Kanban con 3 columnas
  Resumen de materiales necesarios (suma productos pendientes)

JSOLUCIONES:
  No existe concepto de produccion
```

**Implicacion para migracion**: Este es un modulo completamente nuevo que habria que crear si Amatista lo necesita en JSoluciones.

### 6. Generacion de documentos

```
AMATISTA:
  PDF de entrega (para incluir en paquete) → DomPDF → Blade template
  PDF interno (con datos completos) → DomPDF → Blade template
  Conversion PDF → PNG/JPG → Ghostscript (para compartir por WhatsApp)

JSOLUCIONES:
  Solo PDFs via Nubefact (comprobantes SUNAT)
  No genera documentos de entrega
```

---

## RESUMEN: QUE NECESITA JSOLUCIONES PARA ABSORBER AMATISTA

### Ya cubierto (no requiere cambios)
- [x] CRUD productos (mucho mas completo)
- [x] Control de stock (mas robusto, multi-almacen)
- [x] Gestion de usuarios y roles (mas granular)
- [x] Auditoria basica (implementada via signals)
- [x] Dashboard con KPIs
- [x] Estados de pedido con transiciones

### Requiere ajustes menores
- [ ] Agregar estado REPROGRAMADO a la maquina de estados de distribucion
- [ ] Agregar campo `costo_delivery` a pedidos
- [ ] Agregar campos de destinatario (nombre, telefono, dedicatoria, tipo_ubicacion)
- [ ] Agregar campo `turno_entrega` (enum AM/PM)
- [ ] Agregar campo `enlace_ubicacion` (link de Google Maps)
- [ ] Asignacion masiva de pedidos a transportista
- [ ] Creacion rapida de transportista al asignar
- [ ] Agregar campo `preferencia_distrito` a transportistas
- [ ] Descuento de stock al crear pedido (no solo via venta POS)
- [ ] Restaurar stock al editar/cancelar pedido

### Requiere modulos/funcionalidades nuevas
- [ ] **Portal del conductor**: endpoint publico con token, sin JWT
- [ ] **Modulo de produccion**: estado_produccion con flujo pendiente→armando→listo
- [ ] **Mapa de entregas**: visualizacion con Leaflet/Google Maps + coordenadas
- [ ] **GPS del conductor**: tracking de ubicacion desde portal
- [ ] **PDF de entrega**: generacion de documento para incluir en paquete
- [ ] **PDF interno**: documento completo para uso administrativo
- [ ] **Conversion PDF a imagen**: para compartir por WhatsApp
- [ ] **Export Excel funcional**: implementar la logica real (actualmente STUB)

### Requiere mejoras a auditoria
- [ ] Guardar datos antes/despues (JSON) como Amatista
- [ ] Registrar IP del usuario
- [ ] UI de auditoria con filtros
- [ ] Hacer registros verdaderamente inmutables (bloquear update/delete)
- [ ] Registrar intentos de acceso denegado
