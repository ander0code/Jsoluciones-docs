# JSOLUCIONES ERP — PLAN DE EJECUCIÓN MAESTRO

> Versión definitiva. Fusiona el plan original con el roadmap 50%.
> Prioridad del jefe: ecommerce y ventas primero.
> Estrategia: avanzar por capas (back + front juntos).
> Frontend: tipos auto-generados con Orval desde OpenAPI.
>
> **Números del proyecto:** 47 tablas, 33 ENUMs, 104 índices, 21 CHECKs.
> **SQL listo:** SQL_JSOLUCIONES.sql verificado y ejecutable.

---

## 1. CONTEXTO TÉCNICO ACTUAL

| Elemento | Estado |
|----------|--------|
| SQL (47 tablas, 33 enums) | ✅ Listo, verificado, ejecutable |
| Documentación (19 archivos) | ✅ Sincronizada con SQL |
| Proyecto Django | ⬜ Por crear |
| Proyecto React (Tailwick) | ⬜ Template comprado, por adaptar |
| PostgreSQL + Redis | ⬜ Por levantar con Docker |

### Stack fijo (NO se cambia)

| Capa | Tecnología |
|------|-----------|
| Backend | Django 4.x + DRF + drf-spectacular |
| DB | PostgreSQL 16 |
| Async | Celery + Redis |
| Auth | JWT (simplejwt) + RBAC custom |
| Frontend | React 19 + TypeScript + Tailwick |
| Tipos frontend | Orval (auto-generados desde OpenAPI) |
| Facturación | Nubefact (API externa, NO XML directo) |
| Storage | Cloudflare R2 (S3-compatible, fotos/docs) |
| Deploy | Docker + docker-compose |

---

## 2. QUÉ ES EL 50%

De los 12 módulos del ERP, el 50% cubre los **6 módulos fundamentales** para vender:

| # | Módulo | Tablas | App Django | ¿Por qué? |
|:-:|--------|:------:|------------|-----------|
| 1 | Config + Auth + RBAC | 7 | empresa, usuarios | Sin login no hay sistema |
| 2 | Inventario | 6 | inventario | Sin productos no hay ventas |
| 3 | Clientes | 1 | clientes | Sin clientes no hay a quién vender |
| 4 | Ventas + Cotiz + OV | 6 | ventas | **★ Core del negocio** |
| 5 | Facturación Nubefact | 5 | facturacion | Obligatorio legalmente (Perú) |
| 6 | Media (R2) + Proveedores base | 2 | media, proveedores | Fotos de productos + proveedores básico |
| | **SUBTOTAL 50%** | **27 de 47** | | |

**Lo que queda para el otro 50%:** Compras completas (OC, recepciones, facturas proveedor), Finanzas (CxC, CxP, contabilidad), Distribución (pedidos, seguimiento, evidencias), WhatsApp, Reportes avanzados.

---

## 3. ESTRATEGIA: CAPAS, NO BLOQUES

```
❌ INCORRECTO (bloque):
  Semana 1-4: Todo el backend → Semana 5-8: Todo el frontend
  Problema: el jefe no ve nada funcional hasta la semana 5

✅ CORRECTO (capas):
  Capa 1: Back Auth        → Orval → Front Login
  Capa 2: Back Inventario  → Orval → Front Productos
  Capa 3: Back Ventas      → Orval → Front POS + Cotizaciones ★
  Capa 4: Back Facturación → Orval → Front Comprobantes
  Capa 5: Back Media+Prov  → Orval → Front Fotos + Proveedores
  Resultado: cada semana hay algo que mostrar
```

### Flujo por capa

```
Backend: modelo → serializer → view → urls → probar en Swagger
                          ↓
              npx orval (genera tipos + hooks)
                          ↓
Frontend: importa hooks generados → conecta a componentes Tailwick
```

---

## 4. ESTRATEGIA FRONTEND: ORVAL + OPENAPI

Para NO escribir tipos TypeScript ni endpoints a mano:

```
1. Backend expone OpenAPI schema → /api/schema/ (drf-spectacular)
2. Orval lee el schema y genera automáticamente:
   - Tipos TypeScript de cada modelo
   - Hooks de TanStack Query (useProductos, useVentas, etc.)
   - Cliente Axios tipado
3. Frontend solo importa y usa
```

```typescript
// orval.config.ts
import { defineConfig } from 'orval';

export default defineConfig({
  jsoluciones: {
    input: {
      target: 'http://localhost:8000/api/schema/',
    },
    output: {
      target: './src/api/generated.ts',
      client: 'react-query',
      mode: 'split',
      override: {
        mutator: {
          path: './src/services/api.ts',
          name: 'customInstance',
        },
        query: {
          useQuery: true,
          useMutation: true,
        },
      },
    },
  },
});
```

**Cuándo correr Orval:**
- Al FINAL de cada capa de backend, cuando los endpoints están estables
- Después de cada `npx orval`, revisar tipos generados y hacer commit
- NO durante desarrollo activo del backend (cambia mucho)

---

## 5. CAPAS DE EJECUCIÓN

### ═══════════════════════════════════════════════
### CAPA 0: INFRAESTRUCTURA (1-2 días)
### ═══════════════════════════════════════════════

**Sin esto NO existe nada.**

#### Backend
```
□ docker-compose.yml (PostgreSQL 16 + Redis 7)
□ Levantar contenedores, verificar conexión
□ Ejecutar SQL_JSOLUCIONES.sql en PostgreSQL (referencia, Django regenera con migrate)
□ Crear proyecto Django: config/settings/{base,dev,prod}.py
□ Instalar dependencias:
  - djangorestframework, djangorestframework-simplejwt
  - drf-spectacular (Swagger/OpenAPI)
  - django-filter, django-cors-headers
  - celery, redis, boto3
  - psycopg[binary]
□ Configurar en settings: DRF, JWT, CORS, Swagger, PostgreSQL
□ Crear estructura apps/ y core/
□ Crear core/:
  - mixins.py (TimestampMixin, SoftDeleteMixin, AuditMixin)
  - choices.py (todos los CHOICES de 06_CONSTANTES)
  - pagination.py (paginación estándar 20/página)
  - exceptions.py (excepciones custom + ArchivoInvalidoError)
  - permissions.py (TienePermiso, EsAdmin)
  - exception_handler.py (handler global)
  - utils/validators.py (validar_ruc, validar_dni)
  - utils/r2_storage.py (cliente Cloudflare R2 con boto3)
□ python manage.py runserver → funciona sin errores

RESULTADO: Django arrancando, estructura lista
```

#### Frontend
```
□ Limpiar template Tailwick (quitar demos: HR, mailbox, chat, etc.)
□ npm install @tanstack/react-query axios zustand orval
□ Crear orval.config.ts
□ Crear src/services/api.ts (Axios con interceptor JWT)
□ Crear .env → VITE_API_URL=http://localhost:8000

RESULTADO: React limpio, listo para conectar
```

**Entregable:** Docker corriendo, Django arrancando, React limpio.

---

### ═══════════════════════════════════════════════
### CAPA 1: AUTH + LOGIN (3-4 días)
### ═══════════════════════════════════════════════

#### Backend (7 tablas)

Tablas: `configuracion, usuarios, roles, permisos, rol_permisos, perfiles_usuario, log_actividad`

```
□ App empresa/ → modelo Configuracion
  - Singleton (solo 1 fila, constraint en DB)
  - db_table = 'configuracion'

□ App usuarios/ → modelos:
  - Usuario (AbstractUser, email como USERNAME_FIELD, sin username)
  - Rol (codigo unique, nombre, descripcion)
  - Permiso (codigo unique, nombre, modulo)
  - RolPermiso (M2M rol↔permiso)
  - PerfilUsuario (1:1 con Usuario, FK a Rol)
  - LogActividad (inmutable, solo created_at)

□ AUTH_USER_MODEL = 'usuarios.Usuario' en settings
□ makemigrations + migrate

□ Management commands:
  - seed_permissions: crea 8 roles + 40+ permisos base
  - setup_empresa: crea configuracion + usuario admin

□ AuthService: login, refresh, logout, me
□ Views: LoginView, RefreshView, LogoutView, MeView
□ Permisos RBAC: TienePermiso(permiso_codigo), EsAdmin, EsSupervisorOAdmin

ENDPOINTS:
  POST /api/v1/auth/login/       → { access, refresh }
  POST /api/v1/auth/refresh/     → { access }
  POST /api/v1/auth/logout/      → blacklist refresh
  GET  /api/v1/auth/me/          → usuario + rol + permisos
  GET  /api/docs/                → Swagger UI (drf-spectacular)
```

#### Verificación Capa 1
```
✅ PostgreSQL con tablas base + usuario admin
✅ Login retorna JWT
✅ /auth/me/ retorna datos + rol + permisos
✅ Swagger documenta todos los endpoints
✅ 8 roles con permisos creados (seed)
✅ Sin token → 401
✅ Sin permiso → 403
```

#### → Orval
```
□ npx orval → genera useLogin, useMe, tipos Usuario, Rol, Permiso
```

#### Frontend
```
□ Adaptar login de Tailwick → POST /auth/login/
□ AuthContext: JWT (access en memoria, refresh en cookie httpOnly)
□ ProtectedRoute: verifica token + permisos
□ Layout principal: sidebar filtrado por permisos del usuario
□ Página /perfil → GET /auth/me/
□ Redirect a /dashboard después de login exitoso
□ Logout → limpia tokens → redirige a /login

RESULTADO:
  /login     → Funciona con API
  /dashboard → Solo autenticado
  Sidebar    → Solo módulos con permiso
```

**Entregable:** Login funcional, sidebar con permisos, Swagger.

---

### ═══════════════════════════════════════════════
### CAPA 2: INVENTARIO + PRODUCTOS (4-5 días)
### ═══════════════════════════════════════════════

#### Backend (6 tablas)

Tablas: `categorias, productos, almacenes, lotes, stock, movimientos_stock`

```
□ App inventario/ → 6 modelos con db_table limpio
□ makemigrations + migrate

□ InventarioService:
  - CRUD productos con filtros (categoría, precio, stock, búsqueda texto)
  - Gestión stock: consulta por producto+almacén, ajuste, transferencia
  - Movimientos inmutables (nunca se editan/borran)
  - Alerta stock mínimo (Celery task)
  - select_for_update en ajustes de stock (concurrencia)

□ Serializers:
  - ProductoListSerializer (ligero, para listados)
  - ProductoDetailSerializer (completo, con stock por almacén)
  - ProductoCreateUpdateSerializer (validaciones de negocio)
  - StockSerializer, MovimientoSerializer, CategoriaSerializer

□ ViewSets con django-filter + paginación estándar
□ Permisos: inventario.ver, inventario.crear, inventario.editar, inventario.ajustar

ENDPOINTS:
  GET/POST     /api/v1/inventario/productos/
  GET/PATCH    /api/v1/inventario/productos/{id}/
  GET          /api/v1/inventario/productos/{id}/stock/
  GET          /api/v1/inventario/productos/buscar/?q=
  GET/POST     /api/v1/inventario/categorias/
  GET/POST     /api/v1/inventario/almacenes/
  GET          /api/v1/inventario/movimientos/
  POST         /api/v1/inventario/movimientos/ajuste/
  POST         /api/v1/inventario/movimientos/transferencia/

  # TODO [CAPA-7]: Importación masiva CSV
  # TODO [CAPA-7]: Exportar a Excel
  # TODO [CAPA-8]: Alertas visuales de stock bajo en dashboard
```

#### → Orval
```
□ npx orval → genera useProductos, useProducto, useCrearProducto,
  useCategorias, tipos Producto, Categoria, Stock, Movimiento
```

#### Frontend
```
□ /inventario/productos → listado con búsqueda, filtros, paginación
  (adaptar product-list de Tailwick)
□ /inventario/productos/crear → formulario completo
  (adaptar product-create de Tailwick)
□ /inventario/productos/:id → detalle con stock por almacén
  (adaptar product-overview de Tailwick)
□ /inventario/categorias → CRUD simple (modal o página)
□ /inventario/almacenes → CRUD simple

  # TODO [CAPA-7]: Vista de movimientos con timeline
  # TODO [CAPA-8]: Gráficos de stock por producto
```

**Entregable:** CRUD de productos funcional, stock visible por almacén.

---

### ═══════════════════════════════════════════════
### CAPA 3: CLIENTES + VENTAS (5-7 días) ★ PRIORIDAD
### ═══════════════════════════════════════════════

#### Backend Clientes (1 tabla)

```
□ App clientes/ → modelo Cliente
□ ClienteService: CRUD con validación RUC/DNI (utils/validators.py)
□ Serializers + ViewSet + Filtros (tipo_documento, segmento, búsqueda)
□ Permisos: clientes.ver, clientes.crear, clientes.editar

ENDPOINTS:
  GET/POST     /api/v1/clientes/
  GET/PATCH    /api/v1/clientes/{id}/
  GET          /api/v1/clientes/buscar/?q=
  GET          /api/v1/clientes/{id}/historial-ventas/

  # TODO [CAPA-7]: Importación masiva
  # TODO [CAPA-8]: Segmentación automática
  # TODO [CAPA-9]: Dashboard de cliente
```

#### Backend Ventas (6 tablas)

Tablas: `cotizaciones, detalle_cotizaciones, ordenes_venta, detalle_ordenes_venta, ventas, detalle_ventas`

```
□ App ventas/ → 6 modelos
□ VentaService:
  - Venta directa (POS): valida stock → @transaction.atomic
    → crea venta + detalle → descuenta stock (select_for_update)
    → genera comprobante (conecta con facturación)
  - Calcular totales: gravada, IGV (18%), descuentos, total
  - Validar límite de crédito si metodo_pago='credito'
  - Anular venta: cambia estado, nunca DELETE

□ CotizacionService:
  - CRUD + duplicar cotización
  - Flujo: borrador → vigente → aceptada / vencida / rechazada
  - Convertir cotización → orden de venta
  - Tarea Celery: vencer cotizaciones expiradas automáticamente

□ OrdenVentaService:
  - CRUD + convertir orden → venta
  - Flujo: pendiente → confirmada → parcial → completada / cancelada

□ Serializers por operación (crear ≠ listar ≠ detalle)
□ Permisos: ventas.crear, ventas.ver, ventas.anular, cotizaciones.crear

ENDPOINTS:
  # Ventas
  GET/POST     /api/v1/ventas/
  GET          /api/v1/ventas/{id}/
  POST         /api/v1/ventas/{id}/anular/
  GET          /api/v1/ventas/resumen-dia/

  # POS (endpoint optimizado)
  POST         /api/v1/ventas/pos/

  # Cotizaciones
  GET/POST     /api/v1/ventas/cotizaciones/
  GET/PATCH    /api/v1/ventas/cotizaciones/{id}/
  POST         /api/v1/ventas/cotizaciones/{id}/duplicar/
  POST         /api/v1/ventas/cotizaciones/{id}/convertir-orden/

  # Órdenes de Venta
  GET/POST     /api/v1/ventas/ordenes/
  GET/PATCH    /api/v1/ventas/ordenes/{id}/
  POST         /api/v1/ventas/ordenes/{id}/convertir-venta/

  # TODO [CAPA-7]: Descuentos por volumen
  # TODO [CAPA-7]: Listas de precio por cliente
  # TODO [CAPA-8]: Venta campo (preventa)
```

#### → Orval
```
□ npx orval → genera useClientes, useVentas, useCrearVentaPOS,
  useCotizaciones, tipos Cliente, Venta, DetalleVenta, Cotizacion, etc.
```

#### Frontend
```
□ /clientes → listado con búsqueda RUC/DNI/nombre
  (adaptar users-list de Tailwick)
□ /clientes/crear → formulario con validación documento
□ /clientes/:id → detalle con historial de ventas

□ /ventas → listado con filtros fecha/estado/vendedor
  (adaptar orders de Tailwick)
□ /ventas/:id → detalle con items
  (adaptar order-overview de Tailwick)

□ /ventas/pos → ★ PÁGINA POS (100% custom)
  - Buscador de productos (texto + código de barras)
  - Carrito con cantidades editables
  - Selector de cliente (buscar/crear rápido)
  - Selector de método de pago
  - Botón "Cobrar" → POST /ventas/pos/
  - Impresión de ticket/comprobante

□ /ventas/cotizaciones → listado + crear + duplicar
  (adaptar sales-estimates de Tailwick)

□ Dashboard: KPIs reales
  - Ventas del día (monto + cantidad)
  - Productos más vendidos (top 5)
  - Stock bajo (alertas)

  # TODO [CAPA-8]: Gráficos de tendencia ventas
  # TODO [CAPA-8]: Comparativa periodos
  # TODO [CAPA-9]: Metas de ventas por vendedor
```

**Entregable:** POS funcional, cotizaciones, dashboard con datos reales.

---

### ═══════════════════════════════════════════════
### CAPA 4: FACTURACIÓN NUBEFACT (3-4 días)
### ═══════════════════════════════════════════════

#### Backend (5 tablas)

Tablas: `series_comprobante, comprobantes, detalle_comprobantes, notas_credito_debito, log_envio_nubefact`

```
□ App facturacion/ → 5 modelos
□ core/utils/nubefact.py → cliente HTTP para API Nubefact

□ FacturacionService:
  - generar_comprobante(venta_id):
    arma JSON → POST a Nubefact → guarda pdf_url, xml_url, cdr_url, estado_sunat
  - Serie + correlativo automático (select_for_update para concurrencia)
  - Reenviar comprobante fallido
  - Generar nota de crédito (motivo_codigo_nc)
  - Generar nota de débito (motivo_codigo_nd)

□ Tarea Celery: reintentar comprobantes con estado 'error' / 'pendiente_reenvio'
□ Conectar con VentaService: al crear venta → genera comprobante automáticamente
□ Permisos: facturacion.ver, facturacion.reenviar, facturacion.anular

ENDPOINTS:
  GET          /api/v1/facturacion/comprobantes/
  GET          /api/v1/facturacion/comprobantes/{id}/
  POST         /api/v1/facturacion/comprobantes/{id}/reenviar/
  POST         /api/v1/facturacion/notas-credito/
  POST         /api/v1/facturacion/notas-debito/
  GET          /api/v1/facturacion/series/

  # TODO [CAPA-7]: Resumen diario de boletas
  # TODO [CAPA-7]: Comunicación de baja
  # TODO [CAPA-8]: Guías de remisión
```

#### → Orval
```
□ npx orval → genera useComprobantes, tipos Comprobante, NotaCredito, etc.
```

#### Frontend
```
□ /facturacion → dashboard comprobantes del día
  (adaptar invoice-overview de Tailwick)
□ /facturacion/comprobantes → listado con filtros tipo/estado/fecha
  (adaptar invoice-list de Tailwick)
□ /facturacion/comprobantes/:id → detalle con links a PDF/XML
□ Botón "Reenviar" en comprobantes con error
□ Indicador visual: pendiente=amarillo, aceptado=verde, error=rojo

  # TODO [CAPA-8]: Vista de notas de crédito/débito
  # TODO [CAPA-8]: Reportes SUNAT
```

**Entregable:** Ventas generan comprobantes automáticos, PDF descargable.

---

### ═══════════════════════════════════════════════
### CAPA 5: MEDIA + PROVEEDORES BASE (2-3 días)
### ═══════════════════════════════════════════════

#### Backend Media (1 tabla)

```
□ App media/ → modelo MediaArchivo (polimórfico: entidad_tipo + entidad_id)
□ core/utils/r2_storage.py → ya creado en Capa 0
□ MediaService: upload a R2, delete, listar por entidad
□ Validación: tipo (jpeg/png/webp), tamaño (max 5MB)

ENDPOINTS:
  POST         /api/v1/media/upload/
  DELETE       /api/v1/media/{id}/
  GET          /api/v1/productos/{id}/imagenes/
  POST         /api/v1/productos/{id}/imagenes/
```

#### Backend Proveedores (1 tabla)

```
□ App proveedores/ → modelo Proveedor (CRUD básico)
□ Solo modelo y endpoints CRUD. Sin compras, OC ni recepciones.

ENDPOINTS:
  GET/POST     /api/v1/proveedores/
  GET/PATCH    /api/v1/proveedores/{id}/

  # TODO [CAPA-6]: Órdenes de compra
  # TODO [CAPA-6]: Recepciones de mercadería
  # TODO [CAPA-6]: Facturas de proveedor
  # TODO [CAPA-7]: Calificación automática
```

#### → Orval
```
□ npx orval → genera useUploadMedia, useProveedores, etc.
```

#### Frontend
```
□ Fotos en fichas de producto (upload + preview + reordenar)
□ Logo de empresa (upload en configuración)
□ /proveedores → listado básico
□ /proveedores/crear → formulario
```

**Entregable:** Productos con fotos desde R2, proveedores registrados.

---

## 6. RESUMEN VISUAL

```
CAPA 0 (1-2 días)  │ Docker + Django + React limpios
                    │
CAPA 1 (3-4 días)  │ Auth ──────────── Login + Sidebar
                    │     ↓ orval
CAPA 2 (4-5 días)  │ Inventario ────── Productos + Stock
                    │     ↓ orval
CAPA 3 (5-7 días)  │ Clientes+Ventas ─ POS + Cotizaciones + Dashboard ★
                    │     ↓ orval
CAPA 4 (3-4 días)  │ Facturación ───── Comprobantes + Nubefact
                    │     ↓ orval
CAPA 5 (2-3 días)  │ Media+Proveed. ── Fotos R2 + CRUD proveedores
                    │
                    ★ 50% COMPLETADO (18-25 días hábiles)
```

---

## 7. EL OTRO 50% (futuro)

| Capa | Módulo | Tablas | Complejidad |
|:----:|--------|:------:|:-----------:|
| 6 | Compras (OC, recepciones, facturas prov.) | 5 | Media |
| 7 | Finanzas (CxC, CxP, cobros, pagos, contabilidad) | 7 | Alta |
| 8 | Distribución (pedidos, seguimiento, evidencias) | 4 | Media |
| 9 | WhatsApp (config, plantillas, mensajes, logs) | 4 | Media |
| 10 | Reportes avanzados (dashboards por rol, exportar) | 0 | Alta |

---

## 8. CONVENCIÓN DE TODOs

Todo lo que NO se implementa en el 50% se marca así:

```python
# Backend
# TODO [CAPA-6]: Implementar órdenes de compra completas
# TODO [CAPA-7]: Dashboard financiero con gráficos CxC/CxP
```

```typescript
// Frontend
// TODO [CAPA-8]: Vista de distribución con mapa
// TODO [CAPA-9]: Integrar WhatsApp para notificaciones
```

---

## 9. CONTEXTO POR AGENTE

### Agente Backend (archivos base)

```
contexto/01_CORE_PROYECTO.md           → Stack, arquitectura, apps Django
contexto/06_CONSTANTES_COMPARTIDAS.md  → Choices, mixins, validadores (código Python)
contexto/14_DB_TABLAS_DESCRIPCION.MD   → Justificación de cada campo
contexto/17_INTEGRACION_CLOUDFARE.MD   → R2 storage (cuando implemente media)
contexto/18_CONFIRMACION_SQL_LISTO.md  → Estado actual, 47 tablas, 33 enums

instrucciones/02_REGLAS_BACKEND_v2.md  → Cómo escribir código backend
instrucciones/03_REGLAS_BASE_DATOS.md  → Reglas DB-01 a DB-15, mixins, modelos
instrucciones/05_REGLAS_AGENTE.md      → Comportamiento del agente
instrucciones/07_PROCESOS_BACKEND.md   → Paso a paso: qué construir
instrucciones/09_PROCESOS_DATABASE.md  → Setup DB, migraciones

SQL_JSOLUCIONES.sql                    → Fuente de verdad de la estructura
```

### Agente Frontend (archivos base)

```
contexto/01_CORE_PROYECTO.md               → Stack, arquitectura
contexto/10_MAPA_TEMPLATE_TAILWICK.md      → Componentes del template
contexto/resumen_proyecto.md               → Resumen general

instrucciones/04_REGLAS_FRONTEND_v2.md     → Cómo escribir código frontend
instrucciones/05_REGLAS_AGENTE.md          → Comportamiento del agente
instrucciones/08_PROCESOS_FRONTEND.md      → Qué vistas construir

+ tipos generados por Orval (src/api/generated.ts)
```

---

## 10. LO QUE NO SE DEBE HACER (ANTI-PATRONES)

- NO generar XML UBL manualmente (Nubefact lo hace)
- NO conectar directo a SUNAT (Nubefact es el intermediario)
- NO crear UI desde cero (usar Tailwick como base)
- NO usar SQLite (siempre PostgreSQL)
- NO escribir tipos TypeScript a mano (Orval los genera)
- NO guardar archivos en filesystem del servidor (Cloudflare R2)
- NO hacer queries N+1 (usar select_related / prefetch_related)
- NO poner lógica de negocio en signals, views o serializers (va en services)
- NO crear migraciones que borren datos sin backup
- NO hardcodear URLs de API en el frontend (VITE_API_URL en .env)
- NO ignorar los flujos de estado definidos (cotización → orden → venta)
- NO implementar compras, finanzas, distribución ni WhatsApp en el 50%
- NO crear modelos PlanSuscripcion ni UsuarioGlobal (eso era multi-tenant, ya eliminado)