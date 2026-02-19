# JSOLUCIONES ERP — MAPEO DE VISTAS FRONTEND ↔ TABLAS DB

> **Propósito:** Documentar qué vistas del template Tailwick usaremos, qué tablas
> de la DB alimentan cada vista, y cuáles son las más frecuentes en el día a día.
>
> **Fuentes:**
> - `12_SUSTENTO_TABLAS_DB.MD` (v2) → 47 tablas con nombres limpios en español
> - `08_PROCESOS_FRONTEND.md` → Vistas a construir
> - `10_MAPA_TEMPLATE_TAILWICK.md` → Qué usar/ignorar del template
> - Estructura real de `Jsoluciones-fe/src/`
>
> **Nota:** Los nombres de tablas en este archivo coinciden con los de `12_SUSTENTO_TABLAS_DB.MD` v2
> (nombres SQL limpios, no estilo Django). Ej: `productos` en vez de `inventario_producto`.

---

## 1. OPCIONES DE DISEÑO DISPONIBLES EN EL TEMPLATE

### 1.1 Estilos de Auth (4 opciones — elegir 1)

| Estilo | Ruta template | Vista previa | Veredicto |
|--------|--------------|--------------|-----------|
| **Modern** | `/modern-login` | Diseño elegante, split screen con ilustración | **USAR** — ya conectado como `/login` |
| Basic | `/basic-login` | Minimalista, centrado | Disponible para probar |
| Boxed | `/boxed-login` | Card centrada con fondo | Disponible para probar |
| Cover | `/cover-login` | Imagen de fondo grande | Disponible para probar |

Cada estilo tiene 7 páginas: Login, Register, Verify Email, Two Steps, Logout, Reset Password, Create Password.

**Para probar los 4 estilos, navega a:**
```
/modern-login    → Actual (conectado)
/basic-login     → Opción alternativa
/boxed-login     → Opción alternativa
/cover-login     → Opción alternativa
```

---

### 1.2 Dashboards (4 opciones — elegir 1 principal)

| Dashboard | Ruta | Contenido mock | Útil para ERP |
|-----------|------|---------------|---------------|
| **Ecommerce** | `/dashboard` | KPIs ventas, gráfico revenue, top productos, órdenes | **PRINCIPAL** — adaptar para KPIs ERP |
| Analytics | `/analytics` | Tráfico, sesiones, fuentes, métricas web | No aplica directamente, pero buen diseño de gráficos |
| Email | `/email` | Métricas de email marketing | No aplica |
| HR | `/hr` | Empleados, nómina, asistencia | No aplica ahora (futuro RRHH) |

**Para probar:**
```
/dashboard    → Principal (ya mapeado)
/analytics    → Ver diseño de gráficos
/hr           → Ver diseño de tablas con avatares
/email        → Ver diseño de stats cards
```

---

### 1.3 Layouts del Sidebar (9 opciones)

| Layout | Ruta | Descripción |
|--------|------|-------------|
| **Default** | `/dashboard` (actual) | Sidebar completo, siempre visible |
| Hover | `/sidenav-hover` | Sidebar colapsado, expande al hover |
| Hover Active | `/sidenav-hover-active` | Como hover pero mantiene expandido |
| Small | `/sidenav-small` | Solo íconos, sin texto |
| Compact | `/sidenav-compact` | Más angosto que default |
| Offcanvas | `/sidenav-offcanvas` | Sidebar como drawer (móvil style) |
| Hidden | `/sidenav-hidden` | Sin sidebar, solo topbar |
| Dark Sidebar | `/sidenav-dark` | Sidebar con fondo oscuro |
| Dark Mode | `/dark-mode` | Todo el app en modo oscuro |

**Nota:** Todas estas opciones ya están disponibles via el **Customizer** (botón de engranaje flotante). No necesitas elegir una sola — el usuario puede cambiar en runtime.

---

### 1.4 Estilos de Tablas / Listas

| Componente template | Ruta | Estilo | Útil para |
|--------------------|------|--------|-----------|
| **Product List** | `/product-list` | Tabla con imagen, badges, acciones | Inventario productos |
| **Product Grid** | `/product-grid` | Cards en grid con filtros laterales | Vista alternativa de productos |
| **Orders** | `/orders` | Tabla con tabs de estado, badges | Lista de ventas |
| **Users List** | `/users-list` | Tabla con avatar, rol, acciones | Clientes, Usuarios |
| **Users Grid** | `/users-grid` | Cards con avatar y stats | Vista de roles |
| **Employee List** | `/employee` | Tabla con foto, depto, contacto | Referencia para listas con detalle |
| **Invoice List** | `/list` | Tabla con estado, montos, fechas | Comprobantes |
| **Sales Estimates** | `/sales-estimates` | Tabla con estado, cliente, monto | Cotizaciones |
| **Sales Payments** | `/sales-payments` | Tabla de pagos con método y fecha | Cuentas por cobrar |

---

### 1.5 Estilos de Formularios / Detalle

| Componente template | Ruta | Estilo | Útil para |
|--------------------|------|--------|-----------|
| **Product Create** | `/product-create` | Form con preview, categorías, upload | Crear/editar producto |
| **Product Overview** | `/product-overview` | Detalle con galería, tabs, ratings | Detalle de producto |
| **Order Overview** | `/order-overview` | Timeline + detalle + resumen | Detalle de venta |
| **Invoice Overview** | `/overview` | Dashboard con stats y gráficos | Dashboard facturación |
| **Invoice Add** | `/add-new` | Formulario de factura con items | Detalle comprobante |
| **Checkout** | `/checkout` | Formulario multi-step con resumen | Crear venta completa |
| **Cart** | `/cart` | Lista de items con cantidades y total | POS / punto de venta |

---

### 1.6 Componentes Extras Disponibles

| Componente | Ruta | Para qué sirve |
|-----------|------|----------------|
| Calendar | `/calendar` | Para programar entregas, vencimientos |
| Chat | `/chat` | Referencia de diseño para futuro WhatsApp |
| Pricing | `/pricing` | Referencia para planes (futuro) |
| Timeline | `/timeline` | Referencia para seguimiento de pedidos |
| FAQ | `/faqs` | Referencia de diseño expandible |

---

## 2. VISTAS QUE USAREMOS — Mapeo con tablas DB

### PRIORIDAD ALTA — Uso diario (operaciones core)

Estas son las vistas que un vendedor/cajero/supervisor usa **todos los días**.

#### POS (Punto de Venta) — Ruta: `/ventas/pos`
```
Template base: /cart (Shopping Cart)
Frecuencia: ALTÍSIMA — cada venta del día pasa por aquí

TABLAS QUE CONSULTA/MODIFICA:
  ├── productos               → Buscar productos (SKU, nombre, código barras)
  ├── stock                   → Verificar stock disponible
  ├── clientes                → Seleccionar cliente (o "Varios")
  ├── ventas                  → Crear la venta
  ├── detalle_ventas          → Items de la venta
  ├── movimientos_stock       → Descontar stock (automático)
  ├── comprobantes            → Generar boleta/factura (automático)
  ├── detalle_comprobantes    → Items del comprobante
  └── series_comprobante      → Correlativo (automático)

ENDPOINTS:
  POST /api/v1/ventas/pos/               → Venta rápida
  GET  /api/v1/inventario/productos/buscar/ → Buscar productos
  GET  /api/v1/clientes/buscar/          → Buscar cliente
```

#### Lista de Ventas — Ruta: `/ventas`
```
Template base: /orders (Orders)
Frecuencia: ALTA — varias veces al día

TABLAS QUE CONSULTA:
  ├── ventas                 → Lista principal
  ├── clientes               → Nombre del cliente
  ├── usuarios               → Vendedor que registró
  └── comprobantes           → Número de comprobante

ENDPOINTS:
  GET  /api/v1/ventas/        → Listar (paginado, filtros)
  GET  /api/v1/ventas/{id}/   → Detalle
```

#### Detalle de Venta — Ruta: `/ventas/:id`
```
Template base: /order-overview (Order Details)
Frecuencia: ALTA — para revisar, reimprimir, anular

TABLAS QUE CONSULTA:
  ├── ventas                    → Cabecera
  ├── detalle_ventas            → Items
  ├── clientes                  → Datos del cliente
  ├── comprobantes              → PDF, XML, estado SUNAT
  └── usuarios                  → Quién vendió
```

#### Lista de Productos — Ruta: `/inventario/productos`
```
Template base: /product-list (Product List)
Frecuencia: ALTA — consulta de stock, precios

TABLAS QUE CONSULTA:
  ├── productos              → Lista principal
  ├── categorias             → Filtro por categoría
  ├── stock                  → Stock actual
  └── almacenes              → Filtro por almacén

ENDPOINTS:
  GET /api/v1/inventario/productos/ → Listar (paginado, filtros)
```

#### Crear/Editar Producto — Ruta: `/inventario/productos/crear`
```
Template base: /product-create (Add Products)
Frecuencia: MEDIA — al ingresar mercadería nueva

TABLAS QUE MODIFICA:
  ├── productos               → Crear/editar
  ├── categorias              → Seleccionar categoría
  └── stock                   → Stock inicial (si se crea con stock)
```

#### Lista de Clientes — Ruta: `/clientes` (usa `/users-list` como base)
```
Template base: /users-list (Users List)
Frecuencia: ALTA — buscar cliente para venta, registrar nuevo

TABLAS QUE CONSULTA/MODIFICA:
  ├── clientes                → Lista y CRUD
  └── ventas                  → Historial del cliente
```

---

### PRIORIDAD MEDIA — Uso semanal (gestión comercial)

#### Cotizaciones — Ruta: `/ventas/cotizaciones`
```
Template base: /sales-estimates (Sales Estimates)
Frecuencia: MEDIA — no todas las empresas cotizan

TABLAS:
  ├── cotizaciones              → Lista y CRUD
  ├── detalle_cotizaciones      → Items
  ├── clientes                  → Cliente
  └── productos                 → Productos cotizados
```

#### Cuentas por Cobrar — Ruta: `/ventas/cobros`
```
Template base: /sales-payments (Sales Payments)
Frecuencia: MEDIA — ventas al crédito

TABLAS:
  ├── cuentas_por_cobrar       → Lista de deudas
  ├── cobros                   → Registrar pagos
  ├── clientes                 → Quién debe
  └── ventas                   → Venta origen
```

#### Dashboard — Ruta: `/dashboard`
```
Template base: / (Ecommerce Dashboard)
Frecuencia: DIARIA — resumen del negocio

TABLAS QUE CONSULTA (solo lectura, queries de agregación):
  ├── ventas                 → Ventas del día/semana/mes, totales
  ├── productos              → Productos bajo stock
  ├── stock                  → Alertas stock mínimo
  ├── clientes               → Total clientes
  ├── comprobantes           → Comprobantes pendientes/fallidos
  └── cuentas_por_cobrar     → Deudas pendientes
```

#### Comprobantes Electrónicos — Ruta: `/facturacion/comprobantes`
```
Template base: /list (Invoice List)
Frecuencia: MEDIA — revisión de comprobantes emitidos

TABLAS:
  ├── comprobantes                   → Lista principal
  ├── detalle_comprobantes           → Items
  ├── series_comprobante             → Serie
  ├── clientes                       → Cliente del comprobante
  └── log_envio_nubefact             → Estado de envío
```

#### Dashboard Facturación — Ruta: `/facturacion`
```
Template base: /overview (Invoice Overview)
Frecuencia: MEDIA — resumen de facturación

TABLAS (queries de agregación):
  ├── comprobantes           → Stats por estado, tipo, período
  └── log_envio_nubefact     → Errores/reintentos
```

---

### PRIORIDAD BAJA — Uso ocasional (configuración, administración)

#### Gestión de Usuarios — Ruta: `/configuracion/usuarios`
```
Template base: /users-list (Users List)
Frecuencia: BAJA — solo admin configura usuarios

TABLAS:
  ├── usuarios               → CRUD usuarios
  ├── perfiles_usuario       → Perfil, rol
  ├── roles                  → Asignar rol
  └── permisos               → Ver permisos del rol
```

#### Roles y Permisos — Ruta: `/configuracion/roles` (usa `/users-grid`)
```
Template base: /users-grid (Users Grid)
Frecuencia: MUY BAJA — setup inicial

TABLAS:
  ├── roles                   → Lista de roles
  ├── permisos                → Lista de permisos
  └── rol_permisos            → Asignación
```

#### Detalle de Producto — Ruta: `/inventario/productos/:id`
```
Template base: /product-overview (Product Details)
Frecuencia: MEDIA — revisar stock, historial

TABLAS:
  ├── productos                  → Datos del producto
  ├── stock                      → Stock por almacén
  ├── movimientos_stock          → Historial de movimientos
  ├── lotes                      → Lotes (si aplica)
  └── categorias                 → Categoría
```

---

## 3. RANKING DE TABLAS MÁS CONSULTADAS

Basado en las vistas de arriba, estas son las tablas que más se golpean:

| # | Tabla | Lecturas | Escrituras | Desde qué vistas |
|---|-------|:--------:|:----------:|------------------|
| 1 | `productos` | ALTÍSIMA | Media | POS, Lista productos, Crear venta, Cotizaciones, Dashboard |
| 2 | `stock` | ALTÍSIMA | Alta | POS (verificar), Lista productos, Dashboard (alertas) |
| 3 | `ventas` | ALTA | Alta | POS, Lista ventas, Dashboard, Cuentas por cobrar |
| 4 | `detalle_ventas` | ALTA | Alta | POS, Detalle venta |
| 5 | `clientes` | ALTA | Media | POS, Lista clientes, Ventas, Cotizaciones |
| 6 | `comprobantes` | ALTA | Alta | POS (auto), Lista comprobantes, Detalle venta |
| 7 | `movimientos_stock` | Media | Alta | Se escribe en cada venta/compra/ajuste |
| 8 | `detalle_comprobantes` | Media | Alta | Se escribe junto con comprobante |
| 9 | `series_comprobante` | Media | Media | Correlativo en cada emisión |
| 10 | `usuarios` | Media | Baja | Auth, Permisos, Auditoría |

**Las 3 tablas más críticas en rendimiento:**
1. `stock` — se consulta Y modifica en cada venta (necesita `select_for_update`)
2. `productos` — se busca en cada operación del POS (necesita índices y caché)
3. `series_comprobante` — el correlativo se incrementa atómicamente (necesita `select_for_update`)

---

## 4. RESUMEN VISUAL — Qué probar en el template

```
VISTAS PRINCIPALES (probar diseño):
  /dashboard              → Dashboard con KPIs y gráficos
  /ventas/pos   (o /cart) → Punto de Venta
  /ventas       (o /orders) → Lista de ventas
  /ventas/:id   (o /order-overview) → Detalle venta
  /inventario/productos  (o /product-list) → Productos
  /inventario/productos/crear (o /product-create) → Crear producto
  /facturacion/comprobantes (o /list) → Comprobantes
  /login        (o /modern-login) → Login

VISTAS ALTERNATIVAS (para comparar diseño):
  /product-grid           → Productos en cards (alternativa a tabla)
  /product-overview       → Detalle producto con galería
  /checkout               → Form multi-step (para crear venta completa)
  /overview               → Dashboard de facturación
  /add-new                → Form de factura con items dinámicos

ESTILOS DE AUTH (probar cuál queda mejor):
  /modern-login           → Actual
  /basic-login            → Alternativa minimalista
  /boxed-login            → Alternativa boxed
  /cover-login            → Alternativa con imagen

LAYOUTS DE SIDEBAR (probar via Customizer o directamente):
  /sidenav-hover          → Sidebar hover
  /sidenav-small          → Solo íconos
  /sidenav-dark           → Sidebar oscuro
  /dark-mode              → Todo oscuro
```

---

## 5. RUTAS TEMPLATE ↔ RUTAS ERP (referencia cruzada)

| Ruta template (mock) | Ruta ERP (producción) | Tablas DB |
|-----------------------|----------------------|-----------|
| `/` , `/dashboard` | `/dashboard` | ventas, stock, clientes, comprobantes (aggregaciones) |
| `/product-list` | `/inventario/productos` | productos, stock |
| `/product-create` | `/inventario/productos/crear` | productos, categorias |
| `/product-overview` | `/inventario/productos/:id` | productos, stock, movimientos_stock |
| `/product-grid` | (alternativa visual) | productos |
| `/cart` | `/ventas/pos` | ventas, stock, clientes |
| `/orders` | `/ventas` | ventas, clientes |
| `/order-overview` | `/ventas/:id` | ventas, detalle_ventas, comprobantes |
| `/checkout` | (referencia para form de venta) | — |
| `/sales-estimates` | `/ventas/cotizaciones` | cotizaciones, detalle_cotizaciones |
| `/sales-payments` | `/ventas/cobros` | cuentas_por_cobrar, cobros |
| `/list` | `/facturacion/comprobantes` | comprobantes |
| `/overview` | `/facturacion` | comprobantes (aggregaciones) |
| `/add-new` | `/facturacion/comprobante/:id` | comprobantes, detalle_comprobantes |
| `/users-list` | `/configuracion/usuarios` | usuarios, perfiles_usuario, roles |
| `/users-grid` | `/configuracion/roles` | roles, permisos |
| `/modern-login` | `/login` | usuarios (auth JWT) |
| `/modern-logout` | `/logout` | token_blacklist (JWT) |
| `/sellers` | (futuro: vendedores) | usuarios con rol vendedor |
| `/employee` | (futuro: RRHH) | — |
| `/404` | `/404` | — |
