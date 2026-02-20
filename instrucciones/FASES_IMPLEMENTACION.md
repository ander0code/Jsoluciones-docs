# FASES DE IMPLEMENTACION — JSoluciones ERP

> Fecha: Feb 2026
> Objetivo: Tener el ERP funcional modulo a modulo, empezando por ventas.
> Facturacion electronica: SIN servicio de Nubefact por ahora.
> Excluidos: multi-tenant, eCommerce, WhatsApp, offline sync, Nubefact.

---

## REGLA DE MEJORA CONTINUA

Si durante la ejecucion de cualquier fase se detecta que:
- Algo puede mejorarse (codigo, estructura, UX, performance)
- Falta un paso que no se contemplo
- Un paso ya no aplica o cambio el contexto
- Se descubre un bug o inconsistencia

**Se debe actualizar este archivo** para reflejar la realidad. Cada vez que se complete una tarea, marcarla con [x]. Cada fase completada se marca con [COMPLETADA].

---

## FASE A — Backend fixes [COMPLETADA — Feb 2026]

- [x] A2: `imagen_url` en ProductoListSerializer y ProductoDetailSerializer
- [x] A3: Validacion de caja abierta en `crear_venta_pos`
- [x] A4: `RolPermisosView.post()` para asignar permisos a roles
- [x] A5: OpenAPI + Orval regenerado, `pnpm build` clean

---

## FASE B — POS Completo [COMPLETADA — Feb 2026]

- [x] B1: Descuentos en POS — `descuento_porcentaje` por item en carrito
- [x] B2: Validacion de caja — POS verifica caja abierta, redirige si no hay

---

## FASE C — Inventario Completo [COMPLETADA — Feb 2026]

- [x] C1: Categorias CRUD (`/inventario/categorias`)
- [x] C2: Almacenes CRUD (`/inventario/almacenes`)
- [x] C3-C6: Stock & Movimientos (`/inventario/stock`) — alertas, movimientos, ajuste, transferencia
- [x] C7: Rutas y sidebar entries
- [x] C8: `pnpm build` clean

---

## FASE D — Ventas Completo [COMPLETADA — Feb 2026]

### D1: Pago mixto en POS [COMPLETADO]
**Objetivo:** El CobroModal soporta multiples formas de pago (efectivo + tarjeta, etc).
- [x] Reescribir `CobroModal.tsx` — multiples filas de pago con metodo + monto + referencia
- [x] Botones rapidos: agregar fila, pago exacto, denominaciones rapidas
- [x] Validacion: suma de pagos >= total, vuelto para efectivo
- [x] Actualizar `cart/index.tsx` — flujo 2 pasos: crear venta + `useVentasFormasPagoVentaCreateWithJson`
- [x] Build limpio

**Archivos modificados:**
- `cart/components/CobroModal.tsx` — Reescrito completo para pago mixto
- `cart/index.tsx` — Integra formas de pago, quita estado metodoPago global

### D2: Cotizaciones wizard [COMPLETADO]
**Objetivo:** CRUD completo de cotizaciones con wizard de 4 pasos.
- [x] Lista cotizaciones con filtros y badges de estado
- [x] Botones Duplicar (vencidas/rechazadas) y Convertir a Orden (aceptadas) en lista
- [x] Wizard 4 pasos: cliente → productos (con descuento) → condiciones → resumen
- [x] Editar cotizacion (solo borrador/vigente)
- [x] Pagina detalle cotizacion `/ventas/cotizaciones/:id`
- [x] Ruta y sidebar entry

**Archivos creados/modificados:**
- `cotizaciones/index.tsx` — Mejorado con Duplicar/Convertir
- `cotizaciones/components/CotizacionModal.tsx` — Reescrito como wizard 4 pasos
- `cotizacion-detalle/index.tsx` — **NUEVO**: Detalle con acciones
- `Routes.tsx` — Rutas agregadas
- `menu.ts` — Ya tenia entry

### D3: Ordenes de venta [COMPLETADO]
**Objetivo:** Lista y detalle de ordenes de venta, con conversion a venta.
- [x] Lista ordenes con filtros (estado, busqueda)
- [x] Detalle de orden con items, totales, cotizacion origen
- [x] Convertir a Venta (solo confirmadas) con modal seleccion metodo pago
- [x] Rutas `/ventas/ordenes` y `/ventas/ordenes/:id`
- [x] Sidebar entry

**Archivos creados:**
- `ordenes-venta/index.tsx` — **NUEVO**: Lista de ordenes
- `orden-detalle/index.tsx` — **NUEVO**: Detalle con Convertir a Venta
- `Routes.tsx` — Rutas agregadas
- `menu.ts` — Entry agregada

### D4: Ficha cliente con historial [COMPLETADO]
**Objetivo:** Vista detalle de cliente con historial de compras, cotizaciones y saldo.
- [x] Pagina detalle cliente `/clientes/:id`
- [x] Tabs: datos generales, historial de ventas, cotizaciones
- [x] Historial ventas con links a detalle
- [x] Cotizaciones del cliente con links a detalle
- [x] Info comercial: segmento, limite credito, estado

**Archivos creados:**
- `(users)/cliente-detalle/index.tsx` — **NUEVO**: Ficha cliente con tabs
- `Routes.tsx` — Ruta agregada

---

## FASE E — Gestion [COMPLETADA — Feb 2026]

### E1: CRUD usuarios API (backend) [COMPLETADO — ya existia]
**Descubrimiento:** El backend YA tenia views, serializers y urls para usuarios, roles y permisos.
- [x] `apps/usuarios/views/usuarios.py` — UsuarioViewSet, RolViewSet, PermisoViewSet, RolPermisosView
- [x] `apps/usuarios/serializers/usuarios.py` — Todos los serializers
- [x] `apps/usuarios/urls/usuarios.py` — Router + RolPermisos URL
- [x] Orval hooks ya generados

### E2: Roles y permisos UI [COMPLETADO]
**Objetivo:** Pagina para gestionar roles y asignar permisos.
- [x] Lista de roles con create/edit/delete modal
- [x] Asignar permisos a rol (checkboxes agrupados por modulo)
- [x] Ruta `/configuracion/roles`
- [x] Sidebar entry bajo Configuracion

**Archivos creados:**
- `(configuracion)/roles/index.tsx` — Roles CRUD + PermisosModal

### E3: Usuarios UI [COMPLETADO]
**Objetivo:** CRUD de usuarios desde el frontend.
- [x] Lista de usuarios con filtros (busqueda)
- [x] Crear/editar usuario (modal: email, nombre, password, rol, activo)
- [x] Activar/desactivar usuario
- [x] Ruta `/configuracion/usuarios`
- [x] Sidebar entry bajo Configuracion

**Archivos creados:**
- `(configuracion)/usuarios/index.tsx` — Usuarios CRUD

### E4: Config empresa [COMPLETADO]
**Objetivo:** Pagina para configurar datos de la empresa.
- [x] Formulario con datos fiscales (RUC, razon social, nombre comercial)
- [x] Ubicacion (direccion, ubigeo, departamento, provincia, distrito)
- [x] Contacto (telefono, email)
- [x] Config fiscal (moneda principal, IGV %)
- [x] Usa `useEmpresaRetrieve` y `useEmpresaPartialUpdateWithJson`
- [x] Ruta `/configuracion/empresa`
- [x] Sidebar entry bajo Configuracion

**Archivos creados:**
- `(configuracion)/empresa/index.tsx` — Config empresa singleton form

### E5: Dashboard real con KPIs [COMPLETADO]
**Objetivo:** Dashboard principal con KPIs reales del negocio.
- [x] KPI cards: ventas hoy (count + monto), ventas mes, productos bajo stock, pedidos pendientes
- [x] Top 5 productos del mes (tabla)
- [x] Top 5 clientes del mes (tabla)
- [x] Conectado a `useReportesDashboardRetrieve`, `useReportesInventarioRetrieve`, `useReportesTopProductosList`, `useReportesTopClientesList`
- [x] Mantiene WelcomeUser con auth real, elimina componentes de datos estaticos

**Archivos modificados:**
- `(dashboards)/index/index.tsx` — Reescrito con KPIs reales

### E6: Reportes basicos [COMPLETADO]
**Objetivo:** Pagina de reportes con filtros por fecha y tabs.
- [x] Selector de rango de fechas
- [x] Tab Ventas: resumen por periodo (total ventas, monto, gravada, IGV, descuentos, ticket promedio)
- [x] Tab Inventario: resumen (total productos, activos, bajo stock, valor inventario)
- [x] Tab Top Productos: tabla top 10 con SKU, nombre, cantidad, monto
- [x] Tab Top Clientes: tabla top 10 con nombre, compras, monto
- [x] Ruta `/reportes`
- [x] Sidebar entry con icono

**Archivos creados:**
- `reportes/index.tsx` — Reportes con tabs y date range

---

## FASE F — Compras y Proveedores [PENDIENTE]

**Objetivo:** Backend ya tiene modelos y services. Frontend CRUD completo.

### F1: Proveedores CRUD
- [ ] Lista de proveedores con filtros
- [ ] Crear/editar proveedor (modal)
- [ ] Ruta `/compras/proveedores`

### F2: Ordenes de compra
- [ ] Lista de OC con filtros (estado, proveedor)
- [ ] Crear/editar OC con items
- [ ] Flujo de aprobacion (borrador → aprobada → enviada)
- [ ] Ruta `/compras/ordenes`

### F3: Recepciones
- [ ] Recepcion de mercaderia contra OC
- [ ] Verificar cantidades vs OC
- [ ] Entrada de stock automatica
- [ ] Ruta `/compras/recepciones`

### F4: Facturas de proveedor
- [ ] Registro de facturas de proveedor
- [ ] Asociar a OC/recepcion
- [ ] Ruta `/compras/facturas`

---

## FASE G — Finanzas [PENDIENTE]

**Objetivo:** Backend ya tiene modelos basicos. Frontend para CxC, CxP, cobros y pagos.

### G1: Cuentas por Cobrar (CxC)
- [ ] Lista de CxC con filtros (cliente, estado, vencimiento)
- [ ] Detalle de CxC con pagos asociados
- [ ] Ruta `/finanzas/cxc`

### G2: Cobros
- [ ] Registrar cobro contra CxC
- [ ] Cobro parcial o total
- [ ] Ruta `/finanzas/cobros`

### G3: Cuentas por Pagar (CxP)
- [ ] Lista de CxP con filtros (proveedor, estado, vencimiento)
- [ ] Detalle de CxP
- [ ] Ruta `/finanzas/cxp`

### G4: Pagos a proveedores
- [ ] Registrar pago contra CxP
- [ ] Ruta `/finanzas/pagos`

---

## LIMPIEZA — Archivos deprecados eliminados (Feb 2026)

Se eliminaron 10 componentes del dashboard original del template Tailwick que ya no se usan
(fueron reemplazados por KPIs reales en E5):

- `(dashboards)/index/components/CustomerService.tsx` — ELIMINADO
- `(dashboards)/index/components/ProductOrderDetails.tsx` — ELIMINADO
- `(dashboards)/index/components/SalesThisMonth.tsx` — ELIMINADO
- `(dashboards)/index/components/TopSellingProducts.tsx` — ELIMINADO
- `(dashboards)/index/components/SalesRevenueOverview.tsx` — ELIMINADO
- `(dashboards)/index/components/OrderStatistics.tsx` — ELIMINADO
- `(dashboards)/index/components/ProductOrders.tsx` — ELIMINADO
- `(dashboards)/index/components/TrafficResources.tsx` — ELIMINADO
- `(dashboards)/index/components/Audience.tsx` — ELIMINADO
- `(dashboards)/index/components/data.ts` — ELIMINADO (datos estaticos fake)

Solo queda `WelcomeUser.tsx` que usa datos reales del auth context.

---

## NOTAS

- **Nubefact**: No se usa. Comprobantes se crean en BD con estado pendiente/error. Cuando se configure, funciona automaticamente.
- **Hooks Orval**: Si cambia schema backend → `manage.py spectacular` + `pnpm orval`.
- **Permisos**: Ejecutar `python manage.py seed_permissions` para que existan en BD.
- **Backend venv**: `.venv` en `Jsoluciones-be/.venv`.
- **Frontend**: `pnpm` (no npm/yarn).
