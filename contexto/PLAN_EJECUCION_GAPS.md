# Plan de Ejecución — Gaps Reales ERP JSoluciones
> Generado: Feb 2026. Basado en auditoría de código real (sin alucinar).
> Actualizar estado al completar cada tarea.

---

## Clasificación de Gaps

### GRUPO A — BE real funcional → solo falta FE (conectar directo)

| # | Tarea | Gap | Módulo | Estado |
|---|---|---|---|---|
| T10 | Cliente historial | BE stub → conectar `Venta.objects.filter(cliente=pk)` + FE sección historial en ficha cliente | Ventas | ✅ COMPLETADO |
| T14 | UI permisos rol↔módulo | `RolPermisosView` GET/POST ya funciona. FE: tabla checkboxes en ficha de rol | Usuarios | ✅ COMPLETADO (ya existía) |
| T8 | Reportes FE completos | BE tiene 15 endpoints reales. FE: tabs vendedores + financiero + comparativo agregados | Reportes | ✅ COMPLETADO |

### GRUPO B — FE con datos mock + BE preparado

| # | Tarea | Gap | Módulo | Estado |
|---|---|---|---|---|
| T9 | WhatsApp FE completo | `enviar_mensaje_plantilla` es STUB (Meta API no integrada). FE mock + BE listo para conectar token después | WhatsApp | ⬜ PENDIENTE |
| T13 | Distribución UI GPS/notif | 3 tasks STUBs (`notificar_cliente_despacho`, `actualizar_ubicacion_gps`, `optimizar_ruta`). UI lista para cuando se conecte | Distribución | ⬜ PENDIENTE |
| T14b | 2FA desde perfil usuario | BE tiene TOTP implementado (`generar_totp_qr_base64`, `activar_2fa`, `desactivar_2fa`). Falta UI en página de perfil | Usuarios | ⬜ PENDIENTE |
| T11 | Conciliación bancaria | Inexistente en BE (ni modelo ni endpoint). BE desde cero + FE mock | Finanzas | ⬜ PENDIENTE |
| T12 | Asientos automáticos | Lógica no existe en BE. FE puede mostrar flujo mock (venta → asiento automático preview) | Finanzas | ⬜ PENDIENTE |

### Notas de descubrimiento
- T14 FE ya estaba implementado (modal permisos con checkboxes por módulo en `roles/index.tsx`)
- T8 FE: la página de reportes ya tenía ventas/inventario/top; se agregaron 3 tabs: vendedores, financiero, comparativo
- T10 FE ya estaba implementado (usa `useVentasList({cliente: id})` directamente, no el endpoint historial). Solo se arregló el BE stub.

---

## Orden de Ejecución

```
1. T10 — Cliente historial          (rápido, BE: ~10 líneas, FE: sección en ficha)
2. T14 — UI permisos rol↔módulo    (BE listo, FE: tabla checkboxes del template)
3. T8  — Reportes FE: 8 vistas     (BE real, FE: páginas conectadas)
4. T9  — WhatsApp FE mock           (usar chat/ del template como base)
5. T13 — Distribución UI            (GPS + notif ready-to-connect)
6. T11+T12 — Finanzas UI mock       (conciliación + asientos automáticos)
```

---

## Detalle de cada Tarea

### T10 — Cliente Historial
**BE (real):**
- Archivo: `apps/clientes/views.py` línea ~116 — método `historial` en `ClienteViewSet`
- Actualmente retorna: `{"message": "Historial de ventas disponible en CAPA 5 (Ventas)."}`
- Fix: `Venta.objects.filter(cliente=pk).select_related(...)` con serializer inline
- Campos a retornar: `id`, `numero`, `fecha`, `total`, `estado`, `tipo_comprobante`

**FE (real):**
- Archivo: buscar ficha de cliente en `(users)/cliente-detalle/` o similar
- Agregar sección "Historial de Compras" con tabla: fecha, nro comprobante, total, estado
- Patrón: tabla simple como `Payments.tsx` del template

---

### T14 — UI Permisos Rol↔Módulo
**BE (ya implementado):**
- `GET /api/v1/usuarios/roles/<pk>/permisos/` → lista permisos del rol
- `POST /api/v1/usuarios/roles/<pk>/permisos/` → reemplaza permisos (body: `{permiso_ids: [uuid,...]}`)
- `GET /api/v1/usuarios/permisos/` → lista todos los permisos disponibles

**FE (pendiente):**
- Agregar tab/sección "Permisos" en la página de detalle/edición de rol
- UI: tabla con filas=módulos, columnas=acciones, checkboxes
- Al guardar: POST con todos los IDs seleccionados
- Patrón: `AlmacenesList.tsx` para la estructura base

---

### T8 — Reportes FE (8 vistas)
**BE (todos reales, ningún stub):**

| Endpoint | URL | Datos que retorna |
|---|---|---|
| `DashboardKPIView` | `/api/v1/reportes/dashboard/` | KPIs principales por rol |
| `ReporteVentasView` | `/api/v1/reportes/ventas/` | ventas por período |
| `VentasPorVendedorView` | `/api/v1/reportes/ventas/por-vendedor/` | ranking vendedores |
| `VentasPorMetodoPagoView` | `/api/v1/reportes/ventas/por-metodo-pago/` | desglose por método |
| `VentasSerieDiariaView` | `/api/v1/reportes/ventas/serie-diaria/` | serie temporal diaria |
| `TopProductosView` | `/api/v1/reportes/top-productos/` | top N productos |
| `TopClientesView` | `/api/v1/reportes/top-clientes/` | top N clientes |
| `ReporteInventarioView` | `/api/v1/reportes/inventario/` | stock, rotación, alertas |
| `KPIsFinancierosView` | `/api/v1/reportes/kpis-financieros/` | CxC, CxP, flujo |
| `ExportacionView` | `/api/v1/reportes/exportar/` | POST → FileResponse Excel/PDF |
| `ProgramacionReporteListCreateView` | `/api/v1/reportes/programaciones/` | CRUD programaciones |

**FE (pendiente):** Páginas en `(reportes)/`:
1. `ventas/` — gráfico barras serie diaria + tabla top productos/clientes
2. `vendedores/` — ranking con gráfico radial
3. `inventario/` — stock actual + alertas + rotación ABC
4. `financiero/` — CxC/CxP/flujo con semáforos
5. `exportar/` — selector tipo + formato + botón descarga
6. `programados/` — ya existe, verificar si está completo

---

### T9 — WhatsApp FE (mock)
**BE preparado (STUBs):**
- `POST /api/v1/whatsapp/enviar/` — estructura lista, envío no funciona hasta integrar token Meta
- `GET /api/v1/whatsapp/plantillas/` — CRUD real de plantillas
- `GET /api/v1/whatsapp/mensajes/` — log real de mensajes
- `GET/PATCH /api/v1/whatsapp/configuracion/` — token/número (sin validación real)

**Nota al conectar después:** Solo reemplazar `enviar_mensaje_plantilla` task con llamada real a `https://graph.facebook.com/v19.0/{phone_number_id}/messages`

**FE (mock):** Páginas en `(whatsapp)/`:
1. `configuracion/` — form token + número + estado (mock: siempre "conectado")
2. `plantillas/` — CRUD real (el BE de plantillas sí funciona)
3. `mensajes/` — log con filtros (real)
4. `campanas/` — crear campaña mock (BE no tiene endpoint real aún)

---

### T13 — Distribución UI GPS/Notificaciones
**BE (STUBs con estructura lista):**
- `notificar_cliente_despacho` — STUB, estructura: `task(pedido_id)` lista
- `actualizar_ubicacion_gps` — STUB, modelo `SeguimientoPedido` con lat/lng existe
- `optimizar_ruta` — STUB, `Pedido` tiene `orden_entrega` campo

**FE (pendiente):**
- Vista mapa con marcadores mock (Leaflet o Google Maps placeholder)
- Panel conductor mobile: lista entregas del día + botón "actualizar GPS"
- UI lista para cuando el task se implemente: solo cambiar URL del WS

---

### T11 — Conciliación Bancaria (mock)
**BE (inexistente — crear desde cero cuando se tenga acceso a APIs bancarias):**
- Modelos a crear: `ExtractoBancario`, `LineaExtracto`, `ConciliacionBancaria`
- Por ahora: mock data hardcodeada

**FE (mock):**
- Página `(finanzas)/conciliacion/` con tabla de movimientos importados
- Botón "cargar extracto CSV" (mock: carga archivo pero no procesa)
- Sugerencias de conciliación mock (monto ≈ CxC/CxP)

---

### T12 — Asientos Automáticos (mock)
**BE (no existe — agregar cuando haya tiempo):**
- Signal `post_save` en `Venta` → crear `AsientoContable` automáticamente
- Por ahora: solo mostrar el flujo en UI

**FE (mock):**
- En detalle de venta: sección "Asiento contable generado" con tabla debe/haber mock
- En configuración: toggle "Generar asientos automáticamente"

---

## Estado de Módulos Post-T7

| Módulo | BE | FE | Global |
|---|---|---|---|
| 1. Ventas | ~95% | ~90% | ~92% |
| 2. Inventario | ~97% | ~93% | ~95% |
| 3. Facturación | ~85% | ~82% | ~83% |
| 4. Distribución | ~80% | ~78% | ~79% |
| 5. Compras | ~92% | ~88% | ~90% |
| 6. Finanzas | ~78% | ~82% | ~80% |
| 7. WhatsApp | ~30% | 0% | ~15% |
| 8. Dashboard/Reportes | ~90% | ~55% | ~72% |
| 9. Usuarios/Roles | ~93% | ~82% | ~87% |
| **Global** | | | **~77%** |

### Meta: subir a ~90% global completando este plan
- T10 completo: Ventas sube a ~94%
- T14 completo: Usuarios sube a ~91%
- T8 completo: Reportes sube a ~90%
- T9 completo: WhatsApp sube a ~55% (FE mock)
- T13 completo: Distribución sube a ~85%
- T11+T12 completo: Finanzas sube a ~88%
- **Estimado post-plan: ~86% global**
