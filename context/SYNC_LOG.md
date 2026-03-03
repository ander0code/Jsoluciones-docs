# JSOLUCIONES — Log de Mejoras Aplicadas al Template

> Fecha: 2026-03-03
> Cambios generales (no específicos de negocio) portados y ya aplicados al código base.
> Estos cambios YA están en el código — este documento es referencia de qué se hizo y por qué.

---

## BACKEND (Jsoluciones-be/)

### core/permissions.py
- Helper `_get_perfil()` con `select_related("rol")` y cache a nivel de request (`request._perfil_cache`)
- Evita N+1 queries en permisos — cada request consulta perfil+rol una sola vez

### core/consumers.py
- Auth enforcement — cierra conexión con code 4001 si no hay usuario autenticado
- Guard `hasattr` en `disconnect`
- Agregado `PedidoConsumer` (updates de pedido por WS)

### core/routing.py
- Ruta `ws/pedidos/<pedido_id>/` para WebSocket de pedidos

### core/choices.py
- Sub-métodos de pago más granulares: `transferencia_bcp/interbank/scotiabank/nacion/bbva`, `app_yape`, `app_plin`, `otros`, `mixto`
- Agregados `PEDIDO_NO_ENTREGADO` y `TURNO_EXPRESS`

### core/utils/nubefact.py
- Lectura de BD (razon_social, ubigeo) movida ANTES del bloque Signature
- `cbc:Name` en el XML usa el valor real de la empresa desde BD (no string hardcodeado)

### config/settings/base.py
- `PASSWORD_HASHERS` con BCrypt primero (soporte migración desde Laravel)
- `CORS_ALLOW_HEADERS` explícito con `idempotency-key`

### config/settings/production.py
- `SECURE_SSL_REDIRECT`, `SECURE_PROXY_SSL_HEADER`
- Cookies seguras: `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`
- HSTS completo: `SECURE_HSTS_SECONDS=31536000`, `SECURE_HSTS_INCLUDE_SUBDOMAINS`, `SECURE_HSTS_PRELOAD`

### config/celery.py
- Default settings module cambiado de `production` a `development` (evita accidental connection a producción)

### config/urls.py
- Serving de media files en `DEBUG=True` (`static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)`)

---

## FRONTEND (Jsoluciones-fe/)

### Archivos nuevos creados:

**`src/lib/tokenRefresh.ts`**
- Mutex-based token refresh: si 3 requests fallan con 401 simultáneamente, solo 1 hace el refresh y las otras esperan
- Emite `CustomEvent('token-refreshed')` para que WebSocketManager reconecte
- Evita race condition de múltiple refresh que rota tokens y desloguea al usuario

**`src/lib/routerNavigate.ts`**
- Singleton `setNavigate(fn)` / `getNavigate()` para acceder a React Router `navigate()` desde fuera de componentes
- Permite redirigir a `/login` sin hacer `window.location.href` (que destruye el SPA state)
- **PENDIENTE:** Requiere llamar `setNavigate(navigate)` en un componente dentro del Router:
  ```tsx
  function RouterSetup() {
    const navigate = useNavigate();
    useEffect(() => { setNavigate(navigate); }, [navigate]);
    return null;
  }
  ```

**`src/lib/createReconnectingWS.ts`**
- Factory de WebSocket con reconexión exponential backoff (1s a 30s cap, max 10 retries)
- Ping cada 30s, método `destroy()` para cleanup
- Exporta: `createReconnectingWS()`, `buildWsUrl()`, type `ReconnectingWSHandle`

**`src/lib/dateUtils.ts`**
- `localDateStr(date?)` devuelve YYYY-MM-DD en zona horaria local (no UTC)
- Evita el bug clásico Lima UTC-5 donde `new Date().toISOString().slice(0,10)` da la fecha del día anterior después de las 7pm

**`src/context/WebSocketManager.tsx`**
- Context provider con 2 WebSocket globales persistentes durante la sesión:
  - `ws/notificaciones/` → invalida query de notificaciones
  - `ws/dashboard/` → invalida query de KPIs
- Reconecta automáticamente cuando el token se refresca
- Posición en árbol: `AuthProvider > WebSocketManager > LayoutProvider`

**`src/hooks/usePedidoWS.ts`**
- Suscribe al WebSocket `ws/pedidos/<id>/` e invalida queries de React Query cuando llega `pedido_actualizado`
- Usa `createReconnectingWS` con backoff automático

**`src/components/common/RowDropdown.tsx`**
- Menú dropdown de acciones por fila de tabla
- Usa `createPortal` + `position:fixed` + `getBoundingClientRect` para que el menú nunca quede cortado por overflow del contenedor

**`src/components/common/PhoneInput.tsx`**
- Input de teléfono con selector de país (29 países, banderas emoji, validación per-country)
- Default Perú (+51, 9 dígitos)
- Exporta `validatePhone()` y `validatePhoneOptional()`

**`src/components/common/DistritoSelect.tsx`**
- Selector 2-step departamento > distrito para Perú
- Datos INEI 2024 embebidos (~486 distritos de capitales de provincia + principales)

### Archivos reescritos:

**`src/api/fetcher.ts`**
- Usa `refreshAccessToken()` del mutex centralizado
- Detecta `FormData` y no fuerza `Content-Type` (necesario para file uploads multipart)
- Usa `getNavigate()` en vez de `window.location.href`

**`src/services/api.ts`**
- Usa `refreshAccessToken()` centralizado y `getNavigate()`
- Eliminada lógica de refresh duplicada

### Archivos editados:

**`src/context/AuthContext.tsx`**
- `queryClient.clear()` en logout (previene data leak entre usuarios)
- `hasRole` incluye bypass para admin: `rol === 'admin'` siempre retorna `true`

**`src/components/ProvidersWrapper.tsx`**
- `WebSocketManager` envuelve a `LayoutProvider`

**`src/components/common/DataTable.tsx`**
- Generic constraint `<T extends Record<string, unknown>>`
- Prop `rowKey?: (item: T) => string | number` para keys estables en filas
- Cell rendering type-safe: `String(item[col.key] ?? '')` (sin `any` cast)

**`src/components/common/ProtectedRoute.tsx`**
- Import desde `react-router` (v7)
- Root-path fallback: si la ruta denegada es `/`, redirige a `/perfil`
- Botón "Ir al inicio" en pantallas de acceso denegado

**`src/components/layouts/topbar/NotificacionesCampana.tsx`**
- WebSocket inline eliminado (36 líneas de setup manual)
- Ahora delega al `WebSocketManager` central
- `hs-dropdown` reemplazado con React state + click-outside handler
- `try/catch` en `marcarLeida` y `marcarTodasLeidas`

**`src/components/layouts/topbar/index.tsx`**
- `hs-dropdown` del perfil reemplazado con React state (`profileOpen` + `useRef` click-outside)
- `data-hs-overlay` del Customizer reemplazado con React state (`customizerOpen`)
- Render de `<Customizer isOpen={...} onClose={...} />`

**`src/components/layouts/customizer/index.tsx`**
- Reescrito de `hs-overlay` a componente controlado con props `isOpen`/`onClose`
- Backdrop con click-to-close
- Cierre con tecla Escape
- Atributos de accesibilidad: `role="dialog"`, `aria-modal`, `aria-label`

**`vite.config.ts`**
- `build.rollupOptions.output.manualChunks` con 7 chunks de vendor: `vendor-react`, `vendor-query`, `vendor-charts`, `vendor-maps`, `vendor-calendar`, `vendor-qr`, `vendor-ui`
- Build de producción genera chunks cacheables por separado

---

## Nota sobre LSP errors en Amatista-be/

Los errores LSP reportados durante estas ediciones son **pre-existentes** en Amatista (Django Channels, lxml, decouple, ORM typing). No son regresiones de estos cambios. `Amatista-be/` es READ ONLY — no se toca.
