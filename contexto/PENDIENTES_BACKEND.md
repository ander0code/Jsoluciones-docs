# PENDIENTES BACKEND — JSoluciones ERP

> Actualizado: 2026-02-23 (post-implementacion B1/B2/B3/B4/C1/C2/D1)
> Metodo: Lectura directa de archivos — sin alucinar
> FE: 100% completo. Tests BE: 42/42 passing.

---

## ~~GRUPO B — MOCKS EN MEMORIA~~ RESUELTOS

- ~~B-1 WhatsappCampana~~ — modelo en BD, migration `whatsapp/0004` aplicada
- ~~B-2 Metricas WA~~ — `campanas_activas` calculado desde `WhatsappCampana.objects.filter(...)`
- ~~B-3 WhatsappAutomatizacion~~ — modelo en BD, `_automatizaciones_state` eliminado, `_seed_automatizaciones()` en GET
- ~~B-4 ConfiguracionKPI~~ — modelo singleton en BD, migration `reportes/0002` aplicada, `_configuracion_kpis_state` eliminado

---

## ~~GRUPO C — VALIDACIONES~~ RESUELTAS

- ~~C-1 requiere_serie/lote~~ — `registrar_entrada()` y `registrar_salida()` lanzan `ReglaDeNegocioError` si el campo es obligatorio y no se provee
- ~~C-2 FIFO no automatico~~ — `registrar_salida()` selecciona primer lote FIFO automaticamente si no se pasa `lote_id`

---

## ~~GRUPO D — SEGURIDAD~~ RESUELTO

- ~~D-1 nubefact_token~~ — campo cambiado a `EncryptedCharField`, `django-encrypted-model-fields` instalado, `FIELD_ENCRYPTION_KEY` en settings, migration `empresa/0004` aplicada

---

## GRUPO A — STUBS (REQUIEREN DECISION EXTERNA)

Estos no se pueden implementar sin credenciales o decisiones del cliente.

### A-1: WhatsApp — Envio real a Meta Cloud API

**Archivo:** `apps/whatsapp/services.py:4,34` y `tasks.py:17,35,61`

**Evidencia:**
- `services.py:34`: `"STUB: No envía realmente — solo crea el registro en estado 'en_espera'"`
- `tasks.py:35`: `return {"enviado": False, "mensaje": "stub"}`
- `tasks.py:61`: `return {"procesado": True, "mensaje": "stub"}`

**Que falta:**
- HTTP POST real a `https://graph.facebook.com/v17.0/{phone_number_id}/messages`
- Procesamiento real de webhooks Meta (actualizacion de estados)
- Validacion HMAC de firma del webhook

**REQUIERE:** Cuenta Meta Business verificada + `WHATSAPP_ACCESS_TOKEN` + `WHATSAPP_PHONE_NUMBER_ID`

---

### A-2: Distribucion — Optimizacion de ruta TSP real

**Archivo:** `apps/distribucion/views.py:504`

**Evidencia:** `.order_by("created_at")` con comentario `"Mock: orden cronológico, no TSP real"`. Respuesta incluye `"optimizado": False`.

**Que falta — decision pendiente del cliente:**
- **Opcion 1:** Algoritmo greedy propio (sin costo, resultados basicos)
- **Opcion 2:** Integrar servicio externo (Google Routes, OpenRouteService — requiere API key)

El FE no cambia en ninguna opcion — solo cambia la logica de ordenamiento en `RutaOptimizadaView`.

---

### A-3: SSO Google y Microsoft — flujo OAuth2 completo

**Archivo:** `apps/usuarios/views/auth.py:574,626`

**Evidencia:** Ambas vistas construyen URL de autorizacion pero no hay callback, no hay intercambio de codigo OAuth2, no hay creacion/vinculacion de usuario.

**Que falta:**
- Endpoint `GET /auth/sso/callback/` que procese el codigo OAuth2 y retorne JWT
- **REQUIERE Google:** `SOCIAL_AUTH_GOOGLE_OAUTH2_KEY` + `SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET` (Google Cloud Console)
- **REQUIERE Microsoft:** `SOCIAL_AUTH_MICROSOFT_GRAPH_KEY` + `SOCIAL_AUTH_MICROSOFT_GRAPH_SECRET` (Azure AD App Registration)

---

### A-4: PLE y PDT SUNAT reales

**Archivo:** `apps/finanzas/views.py` — `GenerarPLEView`, `GenerarPDTView`

**Evidencia:** Ambas vistas retornan `{"estado": "pendiente"}` — no generan ningun archivo real.

**Que falta:**
- PLE: generacion de archivos TXT segun formato exacto SUNAT por libro (LE0301, LE1401, etc.)
- PDT: generacion XML/ZIP segun formularios SUNAT (PDT 621, 601, etc.)
- **REQUIERE:** Especificaciones tecnicas de cada libro/formulario SUNAT

---

## RESUMEN

| Prioridad | Gap | Puede implementarse ahora |
|-----------|-----|:---:|
| ALTA | B-1 Campanas WA → modelo BD | SI |
| ALTA | B-2 Metricas WA → calcular real | SI (despues de B-1) |
| ALTA | B-3 Automatizaciones WA → modelo BD | SI |
| ALTA | B-4 Umbrales KPIs → modelo BD | SI |
| MEDIA | C-1 Validacion requiere_serie/lote | SI |
| MEDIA | C-2 FIFO automatico en salidas | SI |
| MEDIA | D-1 Nubefact token encriptado | SI |
| BAJA | A-1 WhatsApp envio real | NO — requiere token Meta Business |
| BAJA | A-2 TSP rutas | NO — requiere decision de diseno |
| BAJA | A-3 SSO OAuth2 completo | NO — requiere credenciales Google/Microsoft |
| BAJA | A-4 PLE/PDT real | NO — requiere formatos tecnicos SUNAT |

---

*Actualizado: 2026-02-23*
*Basado en lectura directa de codigo fuente — sin alucinar*
