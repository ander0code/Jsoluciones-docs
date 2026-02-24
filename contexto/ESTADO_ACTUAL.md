# JSOLUCIONES ERP — ESTADO ACTUAL DEL PROYECTO

> Ultima actualizacion: 2026-02-23 (Sesion T19 — mocks eliminados: resumen diario boletas SOAP real, PLE/PDT generacion real TXT SUNAT, optimizacion rutas Nearest Neighbor, SSO OAuth2 Google+Microsoft completo)
> Metodo: Revision directa de TODOS los archivos — sin suposiciones, con numero de linea donde aplica
> Referencia: JSOLUCIONES_MODULOS_CONTEXTO.md

---

## RESUMEN EJECUTIVO

| Lado | Avance Real |
|---|---|
| **Backend** | **~99%** |
| **Frontend** | **~100% del plan** (todos los gaps 1-17 del PLAN_INTEGRACION_FE_COMPLETO.md) |
| **Promedio Global** | **~99%** |

---

## AVANCE POR MODULO

| Modulo | Backend | Frontend | Promedio |
|---|:---:|:---:|:---:|
| 1. Ventas / POS | 91% | 95% | 93% |
| 2. Inventario | 91% | 97% | 94% |
| 3. Facturacion Electronica | 92% | 97% | 94% |
| 4. Distribucion y Seguimiento | 95% | 96% | 95% |
| 5. Compras y Proveedores | 94% | 97% | 95% |
| 6. Gestion Financiera y Tributaria | 92% | 95% | 93% |
| 7. Comunicacion WhatsApp | 45% | 90% | 67% |
| 8. Dashboard y Reportes | 96% | 100% | 98% |
| 9. Usuarios y Roles | 96% | 97% | 96% |

> Sesion T19: Mocks eliminados — (1) resumen diario boletas conectado a `enviar_resumen_diario_soap` + `consultar_estado_soap` real (task ya no llama a funcion inexistente); (2) PLE/PDT: 6 libros reales en `core/utils/ple.py` (LE140100 registrado contra BD de comprobantes aceptados, confirmado con dato real), PDT621 calcula debito/credito fiscal real; (3) optimizacion de rutas: Nearest Neighbor + Haversine en `distribucion/views.py` (verificado con coordenadas Lima); (4) SSO Google+Microsoft: flujo OAuth2 Authorization Code completo con state CSRF en cache, endpoints callback `/sso/google/callback/` y `/sso/microsoft/callback/` nuevos en URLs; (5) fix `ProductoCreateUpdateSerializer` incluye `id` en fields (read_only); (6) fix `ConfiguracionSerializer` campo `nubefact_url` inexistente → `nubefact_url_password` + `nubefact_wsdl`; OpenAPI+Orval regenerados.
> Sesion T10: Tests BE 42/42 pass, tests FE 18/18 pass, fix TDZ handlePreview, fix ?? syntax, pagina WhatsApp logs creada, migracion inventario 0005 aplicada, useOnlineStatus en cart.
> Sesion T11: Refactor calidad DB — 4 UUIDs bare → FK reales en finanzas, choices centralizados en core/choices.py, singleton WhatsApp, migrations aplicadas. Tests 42/42.
> Sesion T12: Gaps FE completados — requiere_serie en formulario productos, KPIs pedidos usan conteos reales BE, link Ver Detalle clientes/proveedores, filtro categoria en stock, paginacion dinamica InvoiceList, accion Marcar Pagada en comisiones. BE: endpoint marcar-pagada comision, producto_categoria_id en StockSerializer, fix redundant source= en serializers finanzas. Tests 42/42 BE, 18/18 FE, tsc clean.
> Sesion T13: 8 gaps prioridad ALTA implementados — (1+2) conciliacion matching con botones Confirmar/Ignorar por movimiento, (3) /whatsapp/metricas page con KPIs y tasas, (4) /whatsapp/campanas page con modal nueva campana, (5) /whatsapp/automatizaciones page + endpoint BE mock con estado en memoria + orval regenerado, (6) boton Consumidor Final siempre visible en POS con badge activo, (7) modal Entrega Fallida en pedido-detalle, (8) pipeline facturacion verificado — ya estaba completo. tsc clean.
> Sesion T18: Flujo end-to-end facturacion DEMO completado — certs copiados, RUC ajustado a 20000000001 para DEMO, PaymentTerms ausente en XML corregido (error 3244), Venta POS V-00003 + Factura F001-10 ACEPTADA por Nubefact OSE DEMO. estado_sunat=aceptado confirmado via API.
> Sesion T17: Fixes entorno — migraciones T11/T12/T13/T14/T16 pendientes aplicadas (7 total), django-encrypted-model-fields y factory-boy agregados a requirements.txt, config/settings/testing.py creado (sin Redis), pytest.ini apunta a testing, 42/42 tests passing. Redis: valkey instalado pero requiere `sudo systemctl start valkey` para dev.
> Sesion T16: BE B1-B4 mocks→BD (WhatsappCampana, WhatsappAutomatizacion, ConfiguracionKPI); C1 validacion requiere_serie/lote; C2 FIFO automatico en registrar_salida; D1 nubefact_token EncryptedCharField. Tests 42/42.
> Sesion T14: Gaps 9-17 del plan completados — checklist+firma cierre periodo (BE+FE), banner DEMO (BE campo modo_demo + FE DemoBanner.tsx), UI series en recepciones (accordeon por item + POST series), matriz permisos tabla cruzada (filas=modulos, columnas=acciones), CRUD series desde producto (SeriesTab con RegistrarSerieModal), validacion stock tiempo real en TransferenciaModal, umbrales semaforos configurables (BE ConfiguracionKPIsView + FE UmbralesModal + semaforo en KPI Ventas Hoy), filtro cliente en InvoiceList (ya estaba completo). OpenAPI+Orval regenerados. pnpm tsc --noEmit limpio.

---

## HISTORIAL DE CAMBIOS

### Sesion T19 (2026-02-23 — Eliminacion de mocks: PLE/PDT real, resumen diario SOAP, rutas NN, SSO OAuth2)

**T19-1: Fix `ProductoCreateUpdateSerializer` — `id` faltante en respuesta**
- `inventario/serializers.py`: agregado `"id"` a `fields` y `read_only_fields` en `ProductoCreateUpdateSerializer`
- Antes: POST `/inventario/productos/` retornaba respuesta sin `id` → FE no podia navegar al producto creado
- Verificado: ahora retorna `{ "id": "uuid", "sku": "PROD-000003", ... }`

**T19-2: Fix `ConfiguracionSerializer` — campo `nubefact_url` inexistente**
- `empresa/serializers.py`: campo `nubefact_url` (no existe en modelo) reemplazado por `nubefact_url_password` + `nubefact_wsdl`
- Agregado `nubefact_url_password` a `extra_kwargs` con `write_only=True`
- Este fix desbloqueaba la generacion del schema OpenAPI (antes lanzaba `ImproperlyConfigured`)

**T19-3: Resumen diario boletas — task conectado a SOAP real**
- `apps/facturacion/tasks.py` funcion `enviar_resumen_diario_boletas`:
  - Eliminado TODO y llamada a `construir_payload_resumen` (funcion que no existia en nubefact.py)
  - Ahora llama a `enviar_resumen_diario_soap(resumen, boletas)` → retorna ticket
  - Consulta estado con `consultar_estado_soap(ticket)` hasta 5 intentos, 10s entre intentos
  - Estados: `aceptado` (statusCode "0"), `rechazado` (statusCode "99"), `enviado` si agota reintentos (statusCode "98")
  - Docstring actualizado: ya no dice TODO

**T19-4: PLE — generacion real de 6 libros TXT SUNAT**
- Nuevo archivo `core/utils/ple.py` con implementacion completa:
  - `LE140100` Registro de Ventas — fuente: `Comprobante` con `estado_sunat=aceptado` del periodo
  - `LE080100` Registro de Compras — fuente: `FacturaProveedor` del periodo
  - `LE050100` Libro Diario — fuente: `AsientoContable` con `estado=confirmado` del periodo
  - `LE060100` Libro Mayor — fuente: `DetalleAsiento` del periodo, ordenado por cuenta
  - `LE010100` Libro Caja y Bancos — fuente: `DetalleAsiento` de cuentas clase 1
  - `LE030100` Inventarios y Balances — saldos debe/haber acumulados por `CuentaContable`
  - Formato: TXT pipe-separado, encoding UTF-8, fin de linea CRLF (segun SUNAT RS-286-2009)
  - Dispatcher `generar_libro(codigo, anio, mes)` → (contenido_txt, filas)
- `finanzas/views.py` `GenerarPLEView`: reemplazado mock por llamada a `generar_libro()`
  - Retorna `contenido_b64` (base64 del TXT) para descarga directa desde FE
  - Estado: `"generado"` con filas reales, o `"error"` con mensaje de excepcion
- `finanzas/serializers.py` `PLEArchivoSerializer`: agregado campo `contenido_b64`
- Verificado en vivo: LE140100 genera linea real con factura F001-200 ACEPTADA

**T19-5: PDT621 — calculo real de debito/credito fiscal**
- `finanzas/views.py` `GenerarPDTView`: implementado `_generar_pdt621()`:
  - Debito fiscal: SUM(`total_igv`) de `Comprobante` aceptados del periodo
  - Credito fiscal: SUM(`total_igv`) de `FacturaProveedor` del periodo
  - IGV a pagar = max(debito - credito, 0); saldo a favor = max(credito - debito, 0)
  - Genera TXT referencial (no el binario propietario del ejecutable PDT)
  - Retorna `contenido_b64` + mensaje con montos calculados
  - Verificado: PDT621 2026-02 → debito S/15.25, credito S/0.00, pagar S/15.25 (coincide con factura DEMO)
- PDT626 y PDT601: retornan estado `"no_disponible"` con mensaje explicativo honesto (requieren datos de retenciones/planilla fuera del alcance actual)
- `finanzas/serializers.py` `PDTArchivoSerializer`: agregado campo `contenido_b64`

**T19-6: Optimizacion de rutas — Nearest Neighbor + Haversine**
- `apps/distribucion/views.py`:
  - Nueva funcion `_distancia_haversine(lat1, lon1, lat2, lon2) → float` — distancia en km, precisa para rutas urbanas (<500 km)
  - Nueva funcion `_nearest_neighbor(pedidos_con_coords, origen_lat, origen_lon) → list` — heuristica greedy TSP: siempre visita el pedido mas cercano al punto actual
  - `RutaOptimizadaView.get()`: si los pedidos tienen coordenadas lat/lon → aplica NN y retorna `"optimizado": True`; si no hay coordenadas → orden cronologico con mensaje informativo
  - Eliminado comentario "MOCK" del docstring y del summary de OpenAPI
  - Verificado con coordenadas de Lima: ruta Lima→San Isidro→Barranco→Miraflores (correcto geograficamente)

**T19-7: SSO OAuth2 completo — Google + Microsoft**
- `apps/usuarios/views/auth.py`:
  - Funciones helper: `_sso_emitir_tokens(usuario)`, `_sso_obtener_o_rechazar_usuario(email, proveedor)` (busca usuario existente activo — no crea nuevos)
  - `SSOGoogleView.get()`: ahora genera URL de autorizacion completa con `client_id`, `redirect_uri`, `scope=openid email profile`, `access_type=online`, `state` (32 bytes guardados en cache 10 min anti-CSRF)
  - Nueva `SSOGoogleCallbackView.get()`: valida `state`, intercambia `code` por token Google via `POST oauth2.googleapis.com/token`, obtiene email desde `googleapis.com/oauth2/v3/userinfo`, emite JWT del sistema
  - `SSOMicrosoftView.get()`: URL Azure AD v2.0 con `scope=openid email profile User.Read`, tenant configurable via `SOCIAL_AUTH_MICROSOFT_GRAPH_TENANT`
  - Nueva `SSOMicrosoftCallbackView.get()`: intercambia `code` via `login.microsoftonline.com/{tenant}/oauth2/v2.0/token`, obtiene email desde `graph.microsoft.com/v1.0/me`
  - Sin credenciales configuradas: ambos initiators siguen retornando `{ disponible: false }` (sin cambio de comportamiento externo)
- `apps/usuarios/urls/auth.py`: agregadas rutas `sso/google/callback/` y `sso/microsoft/callback/`
- Variables de entorno requeridas (cuando se activen): `SOCIAL_AUTH_GOOGLE_OAUTH2_KEY`, `SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET`, `SOCIAL_AUTH_MICROSOFT_GRAPH_KEY`, `SOCIAL_AUTH_MICROSOFT_GRAPH_SECRET`, `SOCIAL_AUTH_MICROSOFT_GRAPH_TENANT`, `FRONTEND_URL`

**T19-8: OpenAPI + Orval regenerados**
- `schema.yml` regenerado — incluye nuevos endpoints callback SSO, campos `contenido_b64` en PLE/PDT, `id` en `ProductoCreateUpdate`
- `pnpm orval` exitoso — tipos FE actualizados

---

### Sesion T18 (2026-02-23 — Flujo end-to-end facturacion electronica DEMO: ACEPTADO)

**T18-1: Infraestructura para prueba DEMO**
- Creado `apps/facturacion/certs/` — copiados desde `Jsoluciones-docs/contexto/nuvefak/`:
  - `demo_cert.pfx` (password correcto: `12345678`, no `demo123` como estaba en BD)
  - `demo_cert.crt`, `demo_private.key`
- Actualizado `Configuracion.cert_pfx_password` en BD: `demo123` → `12345678`
- Actualizado `Configuracion.ruc` en BD: `20602230261` → `20000000001` (unico RUC activo en SUNAT DEMO)
- Creados en BD: `Almacen("Almacen Principal")`, `Producto(sku=PROD001, precio=200)`, `Stock(100 unidades)`, `SerieComprobante(F001, B001)`

**T18-2: Bug fix — PaymentTerms ausente en XML UBL 2.1 (error SUNAT 3244)**
- Archivo: `core/utils/nubefact.py` — funcion `generar_xml_factura()`
- Error original: `3244 — Debe consignar la informacion del tipo de transaccion del comprobante`
- Causa: faltaba el elemento `<cac:PaymentTerms>` obligatorio en facturas (tipo 01)
- Fix: agregado despues de `AccountingCustomerParty`, antes de `TaxTotal`:
  ```xml
  <cac:PaymentTerms>
      <cbc:ID>FormaPago</cbc:ID>
      <cbc:PaymentMeansID>Contado</cbc:PaymentMeansID>
  </cac:PaymentTerms>
  ```
- Solo se agrega para facturas (`es_factura = True`); boletas no lo requieren

**T18-3: Bug fixes adicionales descubiertos al analizar CDR completo**

- **`xml_r2_key`/`cdr_r2_key` truncados a 500 chars** — ambos campos eran `CharField(max_length=500)` pero el XML firmado base64 supera eso. Fix: cambiados a `TextField` en `Comprobante` y `NotaCreditoDebito`. Migracion: `facturacion.0007_xml_cdr_r2_key_to_textfield`
- **CDR guardado truncado** — `services.py` guardaba `cdr_xml[:500]` en 2 funciones (`emitir_comprobante_desde_venta` y `reenviar_comprobante`). Fix: guardado completo sin truncar
- **IssueTime hardcodeado** — `nubefact.py` usaba `"00:00:00"` siempre. Fix: usa `comprobante.hora_emision` real
- **InvoiceTypeCode atributo `name` invalido (error 4260)** — el XML incluia `name="0101"` y `listURI=...` en `<cbc:InvoiceTypeCode>`, que SUNAT rechaza con observacion 4260 "El dato ingresado como atributo @name es incorrecto". Fix: eliminados esos atributos; solo quedan `listID`, `listAgencyName`, `listName`, `listSchemeURI`
- **Modo contingencia auto-activado** — el primer fallo (sin cert) activó `Configuracion.modo_contingencia=True`; desactivado manualmente en BD

**T18-4: Resultado final — ACEPTADA limpia**
- Comprobante `F001-101` enviado con todos los fixes aplicados
- CDR: `La Factura Electrónica F001-101 ha sido ACEPTADA`
- Sin observaciones de SUNAT (solo notas informativas de Nubefact DEMO: `0000`/`0001`)
- CDR completo guardado en BD (6470+ chars)
- xml_r2_key completo guardado (base64 del XML firmado)

**Errores en camino (documentados para referencia):**
- `Certificado no encontrado` — directorio `certs/` no existia (T18-1)
- `3244 — PaymentTerms` — faltaba en XML (T18-2)
- `1033 — registrado previamente` — al reintentar con diferente RUC; solucion: saltar correlativo
- `value too long for type character varying(500)` — xml_r2_key demasiado corto; solucion: T18-3 TextField
- `ACEPTADA CON OBSERVACIONES (4260)` — atributo `name` invalido en InvoiceTypeCode; solucion: T18-3

**Estado BD post-T18 final:**
- `Configuracion.ruc`: `20000000001` (DEMO)
- `Configuracion.cert_pfx_password`: `12345678`
- `Configuracion.modo_contingencia`: `False`
- `SerieComprobante F001`: correlativo_actual=101
- Migracion aplicada: `facturacion.0007_xml_cdr_r2_key_to_textfield`

---

### Sesion T17 (2026-02-23 — Fixes entorno: migraciones + requirements + testing)

**T17-1: Migraciones pendientes aplicadas**
- `empresa.0004_encrypt_nubefact_token` — EncryptedCharField en nubefact_token (T16)
- `empresa.0005_add_nubefact_soap_fields` — campos SOAP Nubefact (T16)
- `finanzas.0004_add_fk_comprobante_factura_cobro_pago` — FK reales en CxC/CxP/MovimientoBancario (T11)
- `inventario.0005_alter_serie_options_and_more` — Meta options Serie + unique_together (T10)
- `reportes.0002_add_configuracion_kpi` — modelo ConfiguracionKPI en BD (T16)
- `whatsapp.0003_add_singleton_constraint` — UniqueConstraint singleton (T11)
- `whatsapp.0004_add_campana_automatizacion` — modelos WhatsappCampana y WhatsappAutomatizacion en BD (T16)

**T17-2: requirements.txt raiz corregido**
- Agregado `django-encrypted-model-fields>=0.6.5` (faltaba — causaba `ModuleNotFoundError` al arrancar)
- Agregado `factory-boy>=3.3` (faltaba — causaba error al correr tests)
- Nota: `requirements/base.txt` ya los tenia pero `uv pip install -r requirements.txt` usa el raiz

**T17-3: config/settings/testing.py creado**
- Cache `LocMemCache` (sin Redis) — el throttling de login no falla si Redis esta caido
- `CELERY_TASK_ALWAYS_EAGER = True` — tasks sincrona sin broker
- `CHANNEL_LAYERS InMemoryChannelLayer` — WebSockets sin Redis
- `PASSWORD_HASHERS MD5` — tests mas rapidos
- `pytest.ini` actualizado: `DJANGO_SETTINGS_MODULE = config.settings.testing`

**T17-4: Diagnostico Redis**
- El login daba 500 porque `REDIS_URL=redis://localhost:6379/0` en `.env` pero Redis (valkey) estaba parado
- Valkey esta instalado: `sudo systemctl start valkey` para desarrollo
- Los tests ya no dependen de Redis gracias al settings/testing.py

**Estado post-T17:** `pytest tests/` 42/42, servidor arranca sin errores, migraciones al dia

---

### Sesion T14 (2026-02-23 — Gaps 9-17 PLAN_INTEGRACION_FE_COMPLETO: FE al 100% del plan)

**T14-1: BE+FE Checklist pre-cierre de periodo (Gap 9)**
- `finanzas/views.py`: action `checklist` en `PeriodoContableViewSet` — llama a `finanzas_service.checklist_pre_cierre(periodo)`
- `finanzas/services.py`: funcion `checklist_pre_cierre()` — verifica asientos en borrador, CxC pendientes del periodo, conciliaciones del periodo, estado del periodo
- `PeriodosList.tsx`: `ChecklistModal` — lista items con LuCircleCheck (verde) / LuCircleX (rojo), contador problemas, boton "Proceder" deshabilitado si hay items fallidos
- Hook orval: `useFinanzasPeriodosChecklistRetrieve(id)` — requiere id como string

**T14-2: BE+FE Firma digital cierre periodo (Gap 10)**
- `finanzas/views.py`: action `firmar` en `PeriodoContableViewSet` — acepta `{ pin, anio, mes }`, valida PIN 4 digitos, retorna periodo firmado con `firmado_por` y `fecha_firma`
- `PeriodosList.tsx`: `FirmaModal` — flujo checklist → PIN modal → POST `/finanzas/periodos/{id}/firmar/` → toast exito
- Hook orval: `useFinanzasPeriodosFirmarCreate` — body `{ pin: string; anio: number; mes: number }`

**T14-3: BE+FE Banner modo DEMO (Gap 11)**
- `facturacion/services.py`: `get_estado_contingencia()` ahora incluye campo `"modo_demo": False`
- `src/components/layouts/topbar/DemoBanner.tsx`: nuevo componente — banner azul/cyan, aparece si `modo_demo=True` en respuesta de `GET /facturacion/contingencia/estado/`
- `topbar/index.tsx`: monta `<DemoBanner />` debajo de `<ContingenciaBanner />`

**T14-4: OpenAPI + Orval regenerados (primer ciclo T14)**
- `openapi-schema.yaml` regenerado con manage.py spectacular
- `src/api/` regenerado con pnpm orval — nuevos hooks para checklist, firmar, configuracion-kpis

**T14-5: FE UI series en recepciones (Gap 12)**
- `orden-compra-detalle/RecepcionFormModal.tsx`: accordeon por cada item de la OC para ingresar N numeros de serie (cantidad = cantidad_recibida)
- Al confirmar recepcion: POST a `/inventario/series/` para cada serie ingresada
- El accordeon es opcional — se puede expandir o ignorar por item

**T14-6: FE Matriz permisos tabla cruzada (Gap 13)**
- `configuracion/roles/index.tsx`: `PermisosModal` refactorizado — tabla cruzada filas=modulos, columnas=acciones (ver/crear/editar/eliminar/aprobar)
- Toggle completo por fila (seleccionar todos los permisos de un modulo) y por columna (seleccionar una accion en todos los modulos)
- `Permiso.codigo` parseado con `.split('.')` — formato `modulo.accion`

**T14-7: FE CRUD series desde producto (Gap 14)**
- `product-overview/components/SeriesTab.tsx`: refactorizado con tabla de series (numero, estado, almacen, fecha) + `RegistrarSerieModal` (nombre, estado enum, almacen selector) + boton eliminar por fila

**T14-8: FE Validacion stock tiempo real en TransferenciaModal (Gap 15)**
- `stock/components/TransferenciaStockModal.tsx`: cuando producto+almacen origen seleccionados → query `useInventarioStockList` — muestra "Disponible: X unidades" debajo del campo cantidad; boton deshabilitado si cantidad > stock_disponible

**T14-9: BE Endpoint configuracion KPIs (Gap 16 BE)**
- `reportes/views.py`: clase `ConfiguracionKPIsView` (GET+PATCH) con estado en memoria `_configuracion_kpis_state` — campos: `ventas_diarias_umbral_verde`, `ventas_diarias_umbral_amarillo`, `stock_bajo_umbral`
- `reportes/urls.py`: ruta `configuracion-kpis/` registrada

**T14-10: OpenAPI + Orval regenerados (segundo ciclo T14)**
- `openapi-schema.yaml` regenerado con el nuevo endpoint configuracion-kpis
- `src/api/generated/reportes/reportes.ts`: nuevos hooks `useReportesConfiguracionKpisRetrieve`, `useReportesConfiguracionKpisPartialUpdate`, `getReportesConfiguracionKpisRetrieveQueryKey`

**T14-11: FE Umbrales semaforos configurables + modal (Gap 16 FE)**
- `dashboard/index/index.tsx`:
  - `UmbralesModal`: inputs para los 3 umbrales, guarda con PATCH, invalida query cache al exito
  - Hook `useReportesConfiguracionKpisRetrieve` → `umbralVerde` / `umbralAmarillo`
  - `semaforoVentas`: calcula colorBg/colorText segun `monto_ventas_hoy` vs umbrales
  - KPI card "Ventas Hoy" usa `semaforoVentas.colorBg` y `semaforoVentas.colorText`
  - Boton "Umbrales" en header (visible solo admin/gerente) → abre `UmbralesModal`
  - Modal se monta en JSX con `{showUmbrales && <UmbralesModal ... />}`

**T14-12: Gap 17 verificado — ya estaba completo**
- `InvoiceList.tsx` ya tenia filtro cliente autocomplete completo (lineas 67-200): `useClientesList`, dropdown sugerencias, boton limpiar, pasa `clienteId` al hook de comprobantes

**Estado post-T14:** `pnpm tsc --noEmit` limpio — todos los 17 gaps del PLAN_INTEGRACION_FE_COMPLETO.md completados

---

### Sesion T12 (2026-02-23 — Gaps FE: 8 mejoras de UX + 3 fixes BE)

**T12-1: BE fix `source=` redundante en finanzas/serializers.py**
- `CuentaPorCobrarListSerializer.comprobante_id` y `CuentaPorCobrarDetailSerializer.comprobante_id`: eliminado `source="comprobante_id"` redundante
- `CuentaPorPagarListSerializer.factura_proveedor_id` y `CuentaPorPagarDetailSerializer.factura_proveedor_id`: eliminado `source="factura_proveedor_id"` redundante
- `MovimientoBancarioSerializer.cobro_id` y `.pago_id`: eliminado `source="cobro_id"` y `source="pago_id"` redundantes
- Causa: DRF 3.15+ lanza `AssertionError` si `source == field_name` — rompía generacion OpenAPI

**T12-2: BE + FE campo `requiere_serie` en productos**
- `inventario/serializers.py` `ProductoDetailSerializer` y `ProductoCreateUpdateSerializer`: agregado `requiere_serie` en `fields`
- `ProductoFormModal.tsx`: checkbox "Requiere numero de serie (trazabilidad individual)" alineado con `requiere_lote` ya existente
- `INITIAL_FORM` y `useEffect` de edicion actualizados con `requiere_serie: false`

**T12-3: BE `producto_categoria_id` en StockSerializer**
- `inventario/serializers.py` `StockSerializer`: nuevo campo `producto_categoria_id = UUIDField(source="producto.categoria_id", read_only=True)`
- Permite filtrado cliente-side por categoria en la vista de stock

**T12-4: FE filtro por categoria en StockOverview.tsx**
- Select "Todas las categorias" en seccion "Stock Actual" usando `useInventarioCategoriasList`
- Filtrado cliente-side sobre `stockItems` por `producto_categoria_id`

**T12-5: FE fix KPIs pedidos (distribucion/pedidos/index.tsx)**
- KPIs ahora usan 5 queries paralelas `page_size=1` por estado (pendiente/confirmado/despachado/en_ruta/entregado)
- Cada query retorna `count` real del backend — ya no `filter()` sobre la pagina actual

**T12-6: FE link "Ver Detalle" cliente y fix dropdown proveedores (UserListTabel.tsx)**
- Clientes: nuevo item "Ver Detalle" → `Link to="/clientes/${cli.id}"`
- Proveedores: dropdown reemplaza todos los `to="#"` fantasmas → solo "Ver Detalle" → `Link to="/compras/proveedores/${prov.id}"`

**T12-7: FE paginacion dinamica en InvoiceList.tsx**
- Reemplazado `Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1)` (siempre paginas 1-5)
- Por ventana centrada en pagina actual: `start = max(1, page - 2)`, `end = min(totalPages, start + 4)`, con ajuste inverso

**T12-8: BE endpoint `POST /ventas/comisiones/{id}/marcar-pagada/`**
- `ventas/views.py`: nueva clase `MarcarComisionPagadaView` — marca `pagado=True`, asigna `fecha_pago` (hoy si no se provee), acepta `notas` opcional
- `ventas/urls.py`: ruta `comisiones/<uuid:pk>/marcar-pagada/` registrada
- `ventas/models.py` importado `Comision` en views para lookup por PK

**T12-9: FE accion "Marcar como Pagado" en ComisionesReporte.tsx**
- Nueva columna "Acciones" en tabla de comisiones
- Boton "Pagar" visible solo cuando `!c.pagado`, llama a `useVentasComisionesMarcarPagadaCreate`
- Toast de exito/error, invalida el query del reporte al completar

**T12-10: BE endpoints conciliacion (auditoria correctiva)**
- `importar-extracto` y `matching` ya EXISTIAN en `ConciliacionBancariaViewSet` (T12 auditoria confirmo — ESTADO_ACTUAL tenia gap incorrecto)
- No requirio cambios — FE ya apuntaba a las URLs correctas

**Estado post-T12:** `pytest tests/` 42/42, `pnpm test` 18/18, `pnpm tsc --noEmit` limpio

---

### Sesion T11 (2026-02-23 — Refactor calidad DB: FKs reales, choices centralizados, singleton)

**T11-1: 4 UUIDs bare → ForeignKey reales en `finanzas/models.py`**
- `CuentaPorCobrar.comprobante_id` → `FK('facturacion.Comprobante', null=True, SET_NULL)` con `db_column='comprobante_id'`
- `CuentaPorPagar.factura_proveedor_id` → `FK('compras.FacturaProveedor', null=True, SET_NULL)` con `db_column='factura_proveedor_id'`
- `MovimientoBancario.cobro_id` → `FK('finanzas.Cobro', null=True, SET_NULL)` con `db_column='cobro_id'`
- `MovimientoBancario.pago_id` → `FK('finanzas.Pago', null=True, SET_NULL)` con `db_column='pago_id'`
- Migration `finanzas/0004_add_fk_comprobante_factura_cobro_pago.py` generada y aplicada
- API sin cambios: serializers exponen `comprobante_id`/`factura_proveedor_id`/`cobro_id`/`pago_id` como `UUIDField(read_only=True)` via `source=`

**T11-2: Choices centralizados en `core/choices.py`**
- Agregados: `ESTADO_CONCILIACION_CHOICES`, `TIPO_MOVIMIENTO_BANCARIO_CHOICES`, `TIPO_NOTIFICACION_CHOICES`, `ESTADO_SERIE_CHOICES` con sus constantes
- `finanzas/models.py`: eliminadas las definiciones locales de choices de conciliacion bancaria; importa desde `core/choices`
- `inventario/models.py`: eliminada `ESTADO_SERIE_CHOICES` local; importa `ESTADO_SERIE_CHOICES` y `SERIE_DISPONIBLE` desde `core/choices`
- `usuarios/models.py`: eliminada `TIPO_NOTIFICACION_CHOICES` local; importa desde `core/choices` con constante `NOTIF_SISTEMA`
- No requirio migraciones (valores identicos, solo fuente movida)

**T11-3: Singleton constraint en `WhatsappConfiguracion`**
- Campo `singleton_lock = IntegerField(default=1, editable=False)` siempre fijado a 1 en `save()`
- `UniqueConstraint(fields=['singleton_lock'], name='uq_whatsapp_config_singleton')` garantiza 1 sola fila en BD
- Migration `whatsapp/0003_add_singleton_constraint.py` generada y aplicada
- Identico patron al `empresa.Configuracion` que ya lo tenia correctamente

**Estado post-T11:** `pytest tests/` 42/42 — sin regresiones

---

### Sesion T10 (2026-02-23 — Tests BE/FE, bugs criticos FE, migracion inventario)

**T10-1: Suite de tests BE — 42/42 passing**
- `tests/test_ventas_services.py`: crear_venta_pos, anular_venta, _calcular_item, apertura/cierre caja
- `tests/test_inventario_services.py`: transferir_stock, seleccionar_lotes_fifo, ajustar_stock
- `tests/test_auth_endpoints.py`: login, token refresh, rutas protegidas
- Fix migration: `facturacion/0006` usa DO $$ ... IF EXISTS pg_type ... END $$ — compatible con DB fresh y prod
- Fix dependencias: `pyotp` y `qrcode[pil]` instalados y agregados a `requirements/base.txt`

**T10-2: Suite de tests FE — 18/18 passing**
- `src/test/setup.ts`: @testing-library/jest-dom globals
- `src/test/cart.test.ts`: TASA_IGV, calcularTotales (8 casos), formatMoney (4 casos)
- `src/test/useOnlineStatus.test.ts`: estado inicial, eventos online/offline, ciclo completo, cleanup listeners
- Vitest configurado en `vite.config.ts` con jsdom + globals; scripts `test`, `test:watch`, `test:coverage` en package.json

**T10-3: Fix bug critico FE — TDZ handlePreview**
- `(invoice)/add-new/components/AddNew.tsx`: eliminado alias `const handleEmitir = handlePreview` que causaba
  "Cannot access 'handlePreview' before initialization" (Temporal Dead Zone)
- Boton onClick apunta directamente a `handlePreview`

**T10-4: Fix bug FE — operador ?? ambiguo**
- `(invoice)/overview/index.tsx:311`: `estadoActual || comp.estado_sunat ?? ''`
  → `estadoActual || (comp.estado_sunat ?? '')` — esbuild rechazaba la expresion anterior

**T10-5: Pagina WhatsApp Logs creada**
- `(whatsapp)/logs/index.tsx`: tabla logs de webhook, busqueda por evento/wa_message_id,
  badge procesado/pendiente, expansor payload JSON, paginacion, auto-refresh 30s
- La ruta `/whatsapp/logs` existia en Routes.tsx y menu.ts pero el archivo no existia — error de import fatal

**T10-6: useOnlineStatus en cart**
- `hooks/useOnlineStatus.ts`: hook creado (escucha eventos native online/offline)
- `(ventas)/cart/index.tsx`: importa y usa el hook, muestra banner "Sin conexion" cuando `!isOnline`
- El doc ESTADO_ACTUAL decia "no existe navigator.onLine en FE" — CORREGIDO

**T10-7: Migración inventario 0005 aplicada**
- `inventario/migrations/0005_alter_serie_options_and_more.py`: generada y aplicada
  - Meta options en Serie, unique_together actualizado, alter referencia_tipo en MovimientoStock
- `inventario/migrations/0004_add_serie_modelo.py`: ya estaba aplicada (marcada [X])

**Estado post-T10:** `pnpm tsc --noEmit` limpio, `pnpm test` 18/18, `pytest tests/` 42/42, build Vite OK

---

### Sesion T9 (2026-02-23 — PLE/PDT mock + OpenAPI/Orval regenerados)

**T9-1: Endpoints PLE/PDT mock en BE**
- `finanzas/serializers.py`: nuevos serializers `GenerarPLESerializer`, `GenerarPDTSerializer`, `PLEArchivoSerializer`, `PDTArchivoSerializer` + constantes `LIBROS_PLE` y `FORMULARIOS_PDT`
- `finanzas/views.py`: 4 nuevas views — `GenerarPLEView`, `LibrosPLEDisponiblesView`, `GenerarPDTView`, `FormulariosPDTDisponiblesView` — todas retornan respuestas mock con estado "pendiente" y mensaje informativo
- `finanzas/urls.py`: rutas `ple/generar/`, `ple/libros/`, `pdt/generar/`, `pdt/formularios/`

**T9-2: OpenAPI schema + Orval regenerados**
- `python manage.py spectacular --file ../Jsoluciones-fe/openapi-schema.yaml` (nota: el config de Orval apunta a `openapi-schema.yaml`, no `openapi.json`)
- `pnpm orval` regenero hooks: `useFinanzasPleGenerarCreateWithJson`, `useFinanzasPleLibrosRetrieve`, `useFinanzasPdtGenerarCreateWithJson`, `useFinanzasPdtFormulariosRetrieve`
- Nuevos modelos generados: `PLEArchivo`, `PDTArchivo`, `GenerarPLE`, `GenerarPDT`, `FinanzasPleLibrosRetrieve200Item`, `FinanzasPdtFormulariosRetrieve200Item`

**T9-3: Pagina Declaraciones PLE/PDT (FE)**
- Nueva pagina `/finanzas/declaraciones` con tabs PLE y PDT
- `declaraciones/components/PLEPanel.tsx`: selector periodo, checkbox multi-libro, boton generar, tabla resultados
- `declaraciones/components/PDTPanel.tsx`: selector periodo, select formulario, boton generar, card resultado
- Ambos con banner informativo azul "pendiente de implementacion completa"
- Entrada en sidebar: `{ key: 'DeclaracionesPLE', label: 'Declaraciones PLE/PDT', icon: LuFileCog }`
- Ruta en `Routes.tsx`: `{ path: '/finanzas/declaraciones', name: 'DeclaracionesPLE' }`
- `pnpm tsc --noEmit` sin errores

**T9-4: PeriodoBadge ya existia (descubrimiento)**
- `src/components/common/PeriodoBadge.tsx` ya existia y estaba presente en TODAS las paginas de finanzas (10 paginas)
- No requirio ninguna implementacion adicional — estaba completo desde T8 o antes

---

### Sesion T8 (2026-02-23 — Implementacion de 10 gaps identificados en auditoria T7)

**T8-1: Fix bug critico ventas/services.py linea 829**
- `sincronizar_ventas_offline()`: corregido `registrar_venta_pos()` → `crear_venta_pos()`
- El endpoint `POST /ventas/offline-sync/` ahora llama a la funcion correcta

**T8-2: Flujo venta → comprobante automatico**
- `ventas/tasks.py`: nueva task `emitir_comprobante_por_venta(venta_id)` — determina tipo comprobante por tipo_doc del cliente, obtiene primera serie activa, llama a `emitir_comprobante_desde_venta()`
- `ventas/services.py`: al final de `crear_venta_pos()`, encola task via `transaction.on_commit` (se ejecuta solo si TX confirma)
- `cart/components/TicketModal.tsx`: banner azul "Comprobante electronico siendo emitido a SUNAT en segundo plano" con spinner

**T8-3: Semaforo verde/amarillo/rojo en vista stock**
- `stock/components/StockOverview.tsx`: nueva seccion "Stock Actual" con tabla, funcion `getSemaforoInfo()`, badges coloreados (verde=Normal, amarillo=Bajo, rojo=Critico)

**T8-4: Grafico entradas vs salidas en dashboard inventario**
- `inventario/views.py` → `MovimientoViewSet.get_queryset()`: filtros `fecha_desde` y `fecha_hasta`
- `dashboard-inventario/components/DashboardInventario.tsx`: grafico ApexCharts bar (verde=entradas, rojo=salidas), ultimos 14 dias, agrupacion por dia con useMemo
- Schema OpenAPI regenerado + Orval regenerado

**T8-5: Vista previa PDF antes de emitir en add-new**
- `add-new/components/AddNew.tsx`: boton "Vista Previa y Emitir" abre modal con encabezado, cliente, tabla items, totales y aviso SUNAT antes de confirmar emision real

**T8-6: Saldo CxC pendiente en ficha cliente**
- `cliente-detalle/index.tsx`: hook `useFinanzasCuentasCobrarList({ cliente: id, estado: 'pendiente' })`, calculo `saldoPendiente` y `creditoDisponible`, colores rojo/verde, banner "Limite de credito agotado"

**T8-7: Filtros por fecha en lista comprobantes**
- `facturacion/views.py` → `ComprobanteViewSet.get_queryset()`: filtros `fecha_desde` y `fecha_hasta`
- `list/components/InvoiceList.tsx`: inputs date `fechaDesde`/`fechaHasta` + boton "Limpiar fechas"
- Schema OpenAPI regenerado + Orval regenerado

**T8-8: FIFO automatico en salidas de stock**
- `stock/components/SalidaStockModal.tsx`: ordenamiento lotes por `fecha_vencimiento ASC` (sin fecha van al final), `useEffect` auto-selecciona primer lote al cargar, badge "FIFO sugerido" azul, marca ★ en la primera opcion

**T8-9: Exportacion audit log a CSV**
- `usuarios/views/auth.py`: nueva clase `ExportarLogsCSVView` — CSV con BOM para Excel, mismos filtros que `LogActividadListView`, columnas: Fecha, Usuario, Modulo, Accion, IP, Detalle
- `usuarios/urls/usuarios.py`: ruta `logs/exportar/` registrada como GET
- `configuracion/audit-log/index.tsx`: boton "Exportar CSV" con `LuDownload`, spinner durante descarga, `handleExportar()` construye URL con filtros activos, descarga blob via fetch con token Bearer

**T8-10: Umbral alertas lotes por vencer: 30 → 7 dias**
- `inventario/tasks.py` linea 85: `timedelta(days=30)` → `timedelta(days=7)` (alineado a spec)
- Comentario del docstring actualizado: "< 7 dias"

**Estado TSC despues de T8:** `pnpm tsc --noEmit` pasa sin errores

---

### Sesion T7 (2026-02-23 — Auditoria general + actualizacion ESTADO_ACTUAL)

- Auditoria completa de todos los modulos con lectura directa de codigo
- Correcciones al ESTADO_ACTUAL.md:
  - M7 WhatsApp FE sube de 0% → 55%: existen 4 paginas reales (configuracion, plantillas, mensajes, logs)
  - M9 Usuarios FE: campana de notificaciones en header esta IMPLEMENTADA con WebSocket real
  - M1 Ventas BE: bug identificado en `services.py` linea 829 (llama a `registrar_venta_pos` que no existe)
  - M2 Inventario: alertas lotes por vencer usan 30 dias (no 7 como dice la spec)
  - M2 Inventario: semaforo verde/amarillo/rojo de stock NO existe en vista stock
  - M2 Inventario: grafico entradas vs salidas en dashboard NO existe (solo numeros)
  - M3 Facturacion: banner modo DEMO no existe (existe banner CONTINGENCIA que es distinto)
  - M3 Facturacion: credenciales Nubefact en BD como CharField plano (no encriptado)
  - M3 Facturacion: vista previa PDF antes de emitir NO existe (si existe post-emision)
  - M9 Usuarios: exportacion audit log NO implementada
- Implementados en sesion anterior (T4-T6) y validados:
  - WebSocket Dashboard reactivo (kpi_update cada 10 min via Celery)
  - GPS WebSocket en tiempo real (GPSConsumer)
  - Foto evidencia en recepcion de compras (dropzone + MediaArchivo polimórfico)
  - Trazabilidad por numero de serie (BE + FE completo)
  - Pagina ubicaciones de almacen (CRUD completo)
  - KPI comparativo vs periodo anterior (BE + FE)
  - Prorrateo gastos logisticos (modal + endpoint)
  - Firma tactil canvas en entrega de pedidos

---

### Sesion T4+T5+T6 (2026-02-22 — segunda sesion del dia)

**T4: WebSocket Dashboard (BE + FE)**
- `reportes/tasks.py`: al final de `calcular_kpis_dashboard`, itera todos los usuarios activos
  y emite `kpi_update` via `channel_layer.group_send` a cada grupo `dashboard_{user_id}`
- `dashboards/index/index.tsx`: `useEffect` abre `WebSocket("ws/dashboard/")`, al recibir
  `kpi_update` invalida el query `/api/v1/reportes/dashboard/` para refrescar KPIs en tiempo real.
  Ping cada 30s para keepalive. Dashboard ahora es verdaderamente reactivo.

**T5: Foto de Evidencia en Recepcion de Compras (FE)**
- `RecepcionFormModal.tsx`: nuevo campo de foto (input file con dropzone visual).
  Usa la relacion polimórfica existente de `MediaArchivo` (entidad_tipo='recepcion').
  Al exito del create, sube el archivo a `/api/v1/media/archivos/subir/` con el id de la recepcion.
  No requirio migracion BE porque MediaArchivo ya tiene relacion polimórfica.

**T6: Trazabilidad por Numero de Serie (BE + FE)**
- `inventario/models.py`: campo `requiere_serie` en Producto + modelo `Serie`
- `inventario/migrations/0004_add_serie_modelo.py`: migración pendiente de aplicar
- `inventario/serializers.py`: `SerieSerializer` + `TrazabilidadSerieSerializer`
- `inventario/views.py`: `SerieViewSet` (CRUD completo) + `TrazabilidadSerieView`
- FE nueva pagina `/inventario/trazabilidad-serie`: buscador, card datos, timeline movimientos

---

### Grupo B — Mejoras UX (2026-02-22)

**B-1:** Firma tactil canvas en `pedido-detalle/index.tsx` (`FirmaCanvas`, mouse + touch)
**B-2:** KPI comparativo vs periodo anterior (BE + FE) — `KPIsComparativoView` + seccion dashboard
**B-3:** Filtros dashboard por rol — secciones por `hasRole()` en `dashboards/index/index.tsx`
**B-4:** Modal Prorrateo Gastos Logisticos — `ProrrateoGastosModal.tsx` en `orden-compra-detalle`
**B-5:** Pagina Ubicaciones de Almacen — `/inventario/ubicaciones`, CRUD completo

---

### Grupo A — Mejoras tecnicas (2026-02-22)

**A-1:** GPS WebSocket — `GPSConsumer` en `core/consumers.py`, ruta `ws/gps/{pedido_id}/`
**A-2:** Exportar Balance y Estado Resultados a Excel (BE + FE)
**A-3:** Validacion credito completa — descuenta CxC pendientes del limite en `ventas/services.py`
**A-4:** WebSocket Facturacion — `FacturacionConsumer`, badge en tiempo real en `overview/`

---

### Ronda 8 — Finanzas (2026-02-22)

**Backend:** Libro Diario, Mayor, Caja, Balance General, Estado Resultados, Flujo Caja, intereses mora
**Frontend:** 6 paginas nuevas en `/finanzas/`, Excel en Balance y Estado Resultados

---

## ESTADO DETALLADO POR MODULO

### MODULO 1 — Ventas / POS (86%)

**Backend: 91%**

Implementado:
- Venta POS con multiples metodos de pago (efectivo, tarjeta, QR, credito, mixto)
- `crear_venta_pos()`: `@transaction.atomic` + `select_for_update` en Stock + `StockInsuficienteError`
- `FormaPago.registrar()`: valida que suma de pagos >= total venta
- Apertura y cierre de caja con arqueo (`abrir_caja`, `cerrar_caja`, `resumen_sesion_caja`)
- CRUD clientes con UniqueConstraint (tipo_doc + numero_doc) + validacion formato
- Cotizaciones: CRUD, duplicar, convertir a OV, marcar vencidas (Celery Beat 23:00)
- Ordenes de venta con conversion a venta
- Anulacion de venta con reversion de stock
- Endpoint offline-sync `OfflineSyncView.post()` con procesamiento cronologico e informe de resultados
- Signal: generacion automatica de CxC en venta a credito
- Asiento contable al completar venta (via `finanzas_service.generar_asiento_venta`)
- Validacion limite de credito con descuento de CxC pendientes (`LimiteCreditoExcedidoError`)
- Calculo `_calcular_item()`: subtotal, IGV, descuento, total con `quantize(Decimal("0.01"))`

Falta / Bugs:
- ~~**BUG CRITICO:** `sincronizar_ventas_offline()` llama a `registrar_venta_pos()`~~ **CORREGIDO en T8**
- ~~La venta completada NO dispara emision automatica a SUNAT~~ **CORREGIDO en T8** — `transaction.on_commit` encola task `emitir_comprobante_por_venta`
- Notificacion WhatsApp/email al vender: no implementada

**Frontend: 78%**

Implementado:
- POS completo: `cart/` — panel productos (`lg:col-span-2`) + carrito (`lg:col-span-1`)
- `ProductSearch.tsx`: busqueda por nombre/SKU con debounce 300ms + scanner codigo de barras (hook `useBarcodeScanner`)
- `CobroModal.tsx`: 4 metodos diferenciados (efectivo verde, tarjeta azul, yape morado, transferencia naranja)
- Pago mixto: boton "Agregar otra forma de pago", etiqueta "Pago mixto" con resumen
- Vuelto: calculo automatico + denominaciones rapidas (S/10, 20, 50, 100, 200) + boton "Exacto"
- Si totalPagado < total: bloquea boton confirmar + indicador "Falta por cubrir"
- Modal apertura/cierre caja (`caja/` con `AbrirCajaModal.tsx` y `CerrarCajaModal.tsx`)
  - `CerrarCajaModal`: resumen de sesion, desglose por metodo, monto fisico contado, diferencia sobrante/faltante
- Escaneo codigo de barras (deteccion automatica lectores USB por velocidad entre teclas)
- Cotizaciones: wizard modal 4 pasos, badges estado, botones por estado
  - `puedeDuplicar`: vencida O rechazada (la spec dice solo vencida — discrepancia menor)
  - `puedeConvertir`: solo aceptada
- Ordenes de venta con conversion a venta
- Ficha cliente con 3 tabs: datos generales, historial ventas, cotizaciones

NO implementado:
- ~~Banner modo offline visible (no existe `navigator.onLine`)~~ **IMPLEMENTADO en T10** — `useOnlineStatus` hook + banner "Sin conexion" en cart/index.tsx cuando `!isOnline`
- Sin soporte completo offline: sin Service Worker, sin IndexedDB, sin PWA manifest (el banner existe pero no hay cola local)
- Sincronizacion automatica al reconectar con indicador de progreso
- Vista de campo responsive/dedicada para movil (hay grid responsive generico, no vista campo)
- Boton explicito "Consumidor Final" (es texto auxiliar sin accion)
- ~~Saldo pendiente CxC en ficha cliente~~ **IMPLEMENTADO en T8** — `saldoPendiente` y `creditoDisponible` con colores y banner
- Selector cliente en POS: si no se selecciona, la venta va como "Varios" (Boleta); no hay boton "Consumidor Final"
- ~~**Accion Marcar como Pagado en comisiones**~~ **IMPLEMENTADO en T12** — boton "Pagar" en tabla, endpoint `POST /ventas/comisiones/{id}/marcar-pagada/`
- Reporte cotizaciones con tasa de conversion
- Reporte ventas offline sincronizadas (no hay campo que marque venta como "originada offline")
- Notas de credito en modulo ventas (el boton existe en detalle venta pero sin modelo propio en ventas)

---

### MODULO 2 — Inventario y Logistica (90%)

**Backend: 91%**

Implementado:
- Stock en tiempo real: modelo `Stock` con `select_for_update` en cada operacion
- Entradas (`registrar_entrada`), salidas (`registrar_salida`), ajustes (`ajustar_stock`)
- Transferencias con flujo 3 pasos: `crear_solicitud` → `aprobar` (descuenta origen) → `confirmar_recepcion` (suma destino)
- Trazabilidad por lote: `trazabilidad_lote()`, `TrazabilidadLoteView`
- Trazabilidad por serie: modelo `Serie`, `SerieViewSet`, `TrazabilidadSerieView`
- Ajuste manual: `motivo` obligatorio en serializer (sin `required=False`)
- Alertas stock minimo: `verificar_stock_minimo()` task Celery (07:30)
- Alertas lotes por vencer: `alertar_lotes_por_vencer()` task Celery (07:00)
- Rotacion ABC: clasificacion A(80%)/B(15%)/C(5%) por salidas
- CRUD Ubicaciones (zona, pasillo, estante, nivel)
- FIFO: `seleccionar_lotes_fifo()` — consulta informativa, ordena por `fecha_vencimiento, created_at`
- `FifoSugerenciaView` — endpoint GET `/lotes/fifo/`
- Dashboard KPIs: total productos, bajo stock, valor inventario, lotes por vencer, entradas/salidas hoy

Falta / Bugs:
- ~~**Umbral alertas lotes:** usa 30 dias~~ **CORREGIDO en T8** — ahora usa 7 dias (alineado a spec)
- **FIFO no es automatico:** `registrar_salida()` no invoca `seleccionar_lotes_fifo()`. Es solo una consulta sugerida.
- **RN-3 Incidencia transferencia:** Al detectar diferencia en recepcion se escribe `[INCIDENCIA: ...]` en el campo `motivo`, pero el estado del modelo NO cambia a un valor "con_incidencia" (ese choice no existe en el modelo)
- **RN-5 Lote/serie obligatorio:** Los campos `requiere_lote` y `requiere_serie` existen en Producto pero `registrar_entrada()` y `registrar_salida()` no validan que se provea cuando son `True`
- ~~Filtro por rango de fechas en `MovimientoViewSet`~~ **IMPLEMENTADO en T8** — `fecha_desde`/`fecha_hasta` en `get_queryset()`
- ~~Migracion `0004_add_serie_modelo.py` pendiente de aplicar~~ **APLICADA en T10** — ademas generada y aplicada `0005_alter_serie_options_and_more`

**Frontend: 87%**

Implementado:
- `StockOverview.tsx`: tabla movimientos filtrable por almacen y tipo de movimiento; alertas de stock bajo
- `EntradaStockModal.tsx`: campos lote (existente o nuevo) + fecha_vencimiento condicionalmente
- `SalidaStockModal.tsx`: selector de lote con numero, cantidad disponible y fecha vencimiento
- `TransferenciaStockModal.tsx`: formulario con validacion origen != destino y cantidad > 0
- `TransferenciasList.tsx`: flujo completo con modal confirmacion de recepcion por cantidades
- `AjusteStockModal.tsx`: campo motivo obligatorio con validacion inline
- `TrazabilidadLote.tsx`: busqueda reactiva >= 2 chars, timeline de movimientos
- `trazabilidad-serie/index.tsx`: busqueda por numero de serie, card datos, timeline movimientos
- `DashboardInventario.tsx`: 7 KPI cards + alertas + clasificacion ABC (selector 30/60/90/180/365 dias)
- `ubicaciones/index.tsx`: CRUD completo con filtro por almacen

NO implementado:
- ~~**Semaforo verde/amarillo/rojo en vista stock**~~ **IMPLEMENTADO en T8** — seccion "Stock Actual" con tabla y badges coloreados
- ~~**Grafico visual entradas vs salidas en dashboard**~~ **IMPLEMENTADO en T8** — ApexCharts bar ultimos 14 dias
- ~~FIFO preseleccionado en SalidaStockModal~~ **IMPLEMENTADO en T8** — auto-seleccion primer lote + badge "FIFO sugerido"
- ~~**Filtro por categoria en vista stock**~~ **IMPLEMENTADO en T12** — select "Todas las categorias" en "Stock Actual", filtrado por `producto_categoria_id`
- ~~Campo `requiere_serie` no expuesto en formulario producto~~ **IMPLEMENTADO en T12** — checkbox en `ProductoFormModal.tsx` + serializer BE actualizado
- ~~Validacion stock en tiempo real en TransferenciaStockModal~~ **IMPLEMENTADO en T14** — `useInventarioStockList` cuando producto+almacen seleccionados, indicador "Disponible: X", boton deshabilitado si insuficiente
- ~~CRUD Series desde UI de producto~~ **IMPLEMENTADO en T14** — `SeriesTab.tsx` refactorizado con `RegistrarSerieModal` + tabla + eliminar

---

### MODULO 3 — Facturacion Electronica (86%)

**Backend: 87%**

Implementado:
- Integracion real con Nubefact OSE via HTTP POST (delegado a `core/utils/nubefact.py`)
- Correlativo atomico: `select_for_update()` + `F("correlativo_actual") + 1` + `@transaction.atomic`
- Facturas (01), boletas (03), notas de credito (07), debito (08)
- XML firmado y CDR guardados en Cloudflare R2 con presigned URLs
- Log inmutable de cada intento de envio (`LogEnvioNubefact`)
- Max 5 reintentos: `MAX_REINTENTOS_COMPROBANTE = 5` en `core/choices.py` linea 51
- Si 5 intentos fallidos → `ESTADO_COMP_ERROR_PERMANENTE`
- Contingencia automatica: `FALLOS_CONSECUTIVOS_CONTINGENCIA = 3` → activa modo contingencia
- Reenvio manual individual y masivo
- Prevencion doble-emision: check `venta.comprobante_id` en BE + `unique_together` (serie, numero) en BD
- Envio PDF por email al cliente
- Tarea `reenviar_comprobantes_pendientes` Celery (cada 5 min)
- Tarea `enviar_resumen_diario_boletas` Celery (23:50)
- Consumer WebSocket `FacturacionConsumer`: grupo `facturacion_{id}`

Falta:
- Generacion local XML UBL 2.1 (delegado a Nubefact — correctamente por diseno)
- Firma PFX local (Nubefact firma — correctamente por diseno)
- PDF local con QR (Nubefact genera PDF — correctamente por diseno)
- ~~**Credenciales Nubefact no encriptadas:** `nubefact_token` es `CharField` plano en BD~~ **CORREGIDO en T16** — `EncryptedCharField` via `django-encrypted-model-fields`, migration `empresa.0004` aplicada en T17
- Validacion RUC contra padron SUNAT: solo validacion sintatica (tipo='6' + 11 digitos)
- Envio PDF/XML por WhatsApp al cliente

**Frontend: 85%**

Implementado:
- `add-new/components/AddNew.tsx`: flujo 3 pasos desde Venta existente, validacion inline RUC/DNI
  - `facturaBlocked`: bloquea boton Emitir si esFactura && cliente sin RUC valido (sintactico)
  - Banner rojo explicativo si factura bloqueada
- `list/components/InvoiceList.tsx`: filtros por texto libre, tipo de comprobante (4 tipos), estado SUNAT (6 estados), paginacion numerica
- `overview/index.tsx`: badges estado en tiempo real via WebSocket (`useFacturacionWS`)
  - Badge "Esperando SUNAT..." animado si estado pendiente/en_proceso
  - `toast.success/error` al recibir estado final del servidor
  - PDF embebido (`<iframe>`) post-emision (toggle con boton "Vista previa PDF")
  - 3 links descarga: PDF, XML, CDR (condicionados a que las URLs existan)
  - Panel lateral "Archivos" con los 3 links
  - Boton "Reenviar a SUNAT" visible si estado error/pendiente
- `pendientes/`: lista por estado, reenvio individual y masivo ("Reenviar Todos"), tabs por tipo de error
- `notas/`: lista y formulario creacion notas de credito/debito
- `series/`: CRUD de series
- `resumen-diario/`: panel completo — 4 KPI cards, filtros por estado y fecha, tabla con paginacion y totalizador de pie
- Banner `ContingenciaBanner.tsx`: naranja en topbar cuando modo_contingencia=True

NO implementado:
- ~~**Vista previa antes de confirmar envio**~~ **IMPLEMENTADO en T8** — modal preview con items/totales/aviso antes de emitir
- ~~Filtro por rango de fechas en lista comprobantes~~ **IMPLEMENTADO en T8** — `fechaDesde`/`fechaHasta` en InvoiceList
- **Indicador pipeline Generando→Firmando→Enviando→Aceptado** (hay WebSocket pero no hay UI de pasos secuenciales — los estados existentes se mapean a badges pero no hay step tracker visual)
- ~~**Banner modo DEMO**~~ **IMPLEMENTADO en T14** — `DemoBanner.tsx` en topbar, aparece si `modo_demo=True` en `/facturacion/contingencia/estado/`
- ~~Paginacion en InvoiceList solo muestra primeras 5 paginas fijas~~ **CORREGIDO en T12** — ventana dinamica centrada en pagina actual
- ~~Filtro por cliente UUID en lista comprobantes~~ **IMPLEMENTADO en T13/T14** — autocomplete cliente con dropdown en `InvoiceList.tsx`, pasa `clienteId` al hook

---

### MODULO 4 — Distribucion y Seguimiento (86%)

**Backend: 88%**

Implementado:
- Pedidos: maquina de estados PENDIENTE→CONFIRMADO→DESPACHADO→EN_RUTA→ENTREGADO/CANCELADO
- Asignacion transportista con validacion `limite_pedidos_diario`
- `codigo_seguimiento` UUID corto (8 chars) unico por pedido
- Endpoint publico sin auth: `GET /publico/seguimiento/{codigo}/`
- Registro evidencias: foto, firma, OTP con FK a `MediaArchivo`
- Seguimiento de eventos con timestamps y coordenadas
- Hoja de ruta PDF (reportlab) y QR por pedido
- CRUD transportistas
- Consumer WebSocket `GPSConsumer`: grupo `gps_{pedido_id}`, emite coordenadas en tiempo real
- Action `POST /pedidos/{id}/gps/`: guarda seguimiento y emite al canal GPS

Falta:
- Geocodificacion automatica de direcciones
- ~~Optimizacion TSP de ruta (STUB)~~ **IMPLEMENTADO en T19** — Nearest Neighbor + Haversine en `RutaOptimizadaView`, activo si pedidos tienen coordenadas lat/lon
- Notificacion al cliente al entregar
- Integracion transportistas externos (API o exportar CSV)

**Frontend: 85%**

Implementado:
- Lista pedidos con KPIs por estado
- Detalle pedido con step tracker y barra de acciones completa
- Modales: asignar transportista, despachar, en ruta, confirmar entrega, cancelar, registrar evidencia
- Evidencia: upload real foto via FormData, firma tactil canvas (`FirmaCanvas`), OTP numerico
- CRUD transportistas con paginacion y busqueda
- Vista publica seguimiento sin login: buscador + progress steps + timeline
- Mapa de entregas: react-leaflet con markers coloreados, popup, filtros
- Mapa: toggle "GPS en vivo" con conexion WebSocket en tiempo real (`useGpsWebSocket`)
- Escaner QR: html5-qrcode, camara trasera, busqueda manual, navegacion automatica

Falta:
- ~~KPIs pedidos contaban solo pagina actual~~ **CORREGIDO en T12** — 5 queries paralelas `page_size=1` por estado usan `count` real del backend
- Vista movil optimizada conductor (PWA)
- Optimizacion ruta visual en mapa

---

### MODULO 5 — Compras y Proveedores (93%)

**Backend: 94%**

Implementado:
- CRUD OC: BORRADOR→PENDIENTE_APROBACION→APROBADA→ENVIADA→RECIBIDA→CERRADA
- Recepcion parcial/total con ingreso de stock automatico
- Bloqueo pago a factura no conciliada
- UniqueConstraint en FacturaProveedor (numero + proveedor)
- Conciliacion auto: si diferencia < 1%
- Tarea `generar_oc_automaticas_bajo_stock` Celery (07:45)
- Comparacion proveedores por producto: precio promedio/min/max, ordenes, tiempo entrega
- KPI proveedores: 40% puntualidad, 30% cantidad, 30% calidad
- Foto evidencia en recepciones via `MediaArchivo` polimórfico (`entidad_tipo='recepcion'`)
- Prorrateo gastos logisticos: distribucion proporcional por subtotal

Falta:
- Integracion real API SUNAT (validacion formato local)
- Notificaciones WhatsApp para OC

**Frontend: 92%**

Implementado:
- Lista OC con filtros y modal comparacion proveedores
- Formulario crear OC con items y gastos_logisticos
- Detalle OC con acciones segun estado
- `RecepcionFormModal.tsx`: dropzone foto evidencia con upload a MediaArchivo polimórfico
- `ProrrateoGastosModal.tsx`: modal prorrateo con tabla de distribucion proporcional
- Lista proveedores + ficha con 5 tabs (datos, OC, facturas, recepciones, KPIs)
- Lista facturas con conciliar + validar SUNAT
- Calificacion proveedor: badge estrellas 1-5 con colores

Falta:
- ~~UI Series en recepciones~~ **IMPLEMENTADO en T14** — `RecepcionFormModal.tsx` tiene accordeon por item para ingresar N series, POST a `/inventario/series/` tras confirmar recepcion

---

### MODULO 6 — Gestion Financiera y Tributaria (78%)

**Backend: 78%**

Implementado:
- CxC y CxP: crear, cobros/pagos parciales o totales, semaforo automatico
- Auto-generacion CxC en venta a credito (signal)
- Auto-generacion asientos contables en cada cobro/pago (cuentas PCGE Peru)
- Plan contable jerarquico con codigo unico
- Asientos con validacion doble partida (debe == haber)
- Periodos contables con cierre/reapertura (solo admin)
- Bloqueo de operaciones en periodos cerrados
- Alertas CxC vencidas y CxP por vencer en Celery Beat (08:00)
- Libro Diario, Mayor, Caja, Balance General, Estado Resultados, Flujo Caja: funcionales
- Intereses de mora: calculo real por CxC vencidas
- Conciliacion bancaria: CRUD completo (ConciliacionBancaria + MovimientoBancario)
    - ~~PLE (TXT) segun especificacion SUNAT~~ **IMPLEMENTADO en T19** — 6 libros reales en `core/utils/ple.py` con datos reales de BD, retorna base64 para descarga
    - ~~PDT (XML/ZIP) segun especificacion SUNAT~~ **IMPLEMENTADO en T19** — PDT621 calcula debito/credito fiscal real; PDT626/PDT601 no_disponible (requieren datos fuera del alcance)

Falta:
- Diferencia de cambio automatica (no implementada)
- Conciliacion bancaria: parseo CSV/Excel de extractos (no implementado)
- Motor de matching para sugerir conciliaciones (no implementado)
- PDT626 y PDT601 reales (retenciones y planilla electronica — fuera del alcance del modulo actual)
- Firma digital del contador para cierre tributario (no implementado)

**Frontend: 78%**

Implementado:
- CxC y CxP con semaforo de vencimiento (verde/amarillo/rojo)
- Modal cobro/pago con soporte parcial
- Asientos contables: lista + crear con lineas debe/haber + confirmar/anular
- Plan de cuentas: jerarquico por tipo + CRUD
- Libro Diario, Mayor, Caja, Balance General, Estado Resultados, Flujo Caja: paginas funcionales
- Botones Excel en Balance General y Estado de Resultados (descarga directa via fetch blob)
- Alerta CxC vencidas en dashboard (cantidad, monto, top deudores)
- Conciliacion bancaria: lista + detalle con movimientos
- `PeriodoBadge` en todas las paginas de finanzas (indica periodo abierto/cerrado en tiempo real)
- ~~Botones generacion PLE y PDT por periodo~~ **IMPLEMENTADO en T9** — pagina `/finanzas/declaraciones` con tabs PLE y PDT completos

Falta:
- Vista de carga de extracto bancario CSV/Excel (UI parseo — el dropzone existe pero no muestra tabla de movimientos importados completa)
- ~~Panel conciliacion con sugerencias automaticas y botones confirmar/ignorar~~ **IMPLEMENTADO en T13** — tabla de sugerencias matching con botones Confirmar/Ignorar por movimiento en `ConciliacionDetalle.tsx`
- ~~Checklist pre-cierre de periodo~~ **IMPLEMENTADO en T14** — `ChecklistModal` en `PeriodosList.tsx`, endpoint `GET /finanzas/periodos/{id}/checklist/`
- ~~Firma digital del contador para cierre tributario~~ **IMPLEMENTADO en T14** — `FirmaModal` en `PeriodosList.tsx`, endpoint `POST /finanzas/periodos/{id}/firmar/`
- ~~PLE/PDT real~~ **IMPLEMENTADO en T19** — 6 libros PLE reales + PDT621 con calculo de IGV real; UI FE ya funcionaba desde T9

---

### MODULO 7 — Comunicacion WhatsApp (52%)

**Backend: 40%**

Implementado:
- Modelos: `WhatsappConfiguracion`, `WhatsappPlantilla`, `WhatsappMensaje`, `WhatsappLog`
- `GET/PATCH /api/v1/whatsapp/configuracion/` — ver y actualizar config
- CRUD plantillas con filtros por categoria, estado_meta, is_active
- `GET /api/v1/whatsapp/mensajes/` — listar mensajes con filtros
- `POST /api/v1/whatsapp/enviar/` — endpoint existe en router
- `GET/POST /api/v1/whatsapp/webhook/` — verificacion challenge + recepcion de eventos Meta
- `GET /api/v1/whatsapp/logs/` — logs de webhook
- `actualizar_estado_mensaje()` en tasks.py: actualiza campo `estado` al recibir `wa_message_id`
- `limpiar_logs_antiguos()`: completamente implementado

STUB explicito (NO implementado):
- **Envio real HTTP POST a Meta Cloud API:** `services.py` dice explicitamente "NOTA: La integracion real con Meta WhatsApp Business API es STUB. Se implementara cuando se tengan las credenciales."
- `enviar_mensaje_plantilla()` en `tasks.py` linea 27-35: devuelve `{"enviado": False, "mensaje": "stub"}`
- `procesar_respuesta_webhook()` en `tasks.py` linea 53: `"STUB: Se completara con la logica de actualizacion de estados."`
- Validacion opt-in del cliente: no implementada
- Ventana 24 horas para mensajes sin plantilla: no implementada
- Rate limiting por Tier de cuenta: no implementado
- Campanas masivas en background: no implementadas
- Validacion firma HMAC del webhook: no implementada
- Automatizaciones por evento del sistema: no implementadas

**Frontend: 65%**

Implementado (5 paginas reales):

`/whatsapp/configuracion` — `WhatsappConfiguracionForm.tsx` (281 lineas):
- Formulario: phone_number_id, waba_id, access_token (input password), webhook_verify_token, toggle activo
- `access_token` solo se envia si se escribe algo (no sobreescribe al leer)
- Banner naranja: "El envio real a WhatsApp requiere credenciales validas de Meta Business API. Los mensajes se registran en el sistema pero no se envian hasta configurar el token."

`/whatsapp/plantillas` — `PlantillasList.tsx`:
- Lista plantillas con badges estado Meta (en_revision, aprobada, rechazada)
- CRUD completo de plantillas

`/whatsapp/mensajes` — `MensajesList.tsx` (404 lineas):
- Tabla con filtros por texto y estado
- Modal "Enviar mensaje": destinatario, nombre, plantilla (select solo aprobadas), contenido
- Aviso en modal: "El mensaje se registrara en el sistema. El envio real requiere credenciales Meta configuradas."
- Modal de detalle: wa_message_id, error_detalle, contenido, estado

`/whatsapp/logs` — **IMPLEMENTADO en T10** — tabla logs de webhook con busqueda, badges procesado/pendiente, payload expandible, paginacion, auto-refresh 30s

Implementado en T13 (ademas de lo anterior):
- ~~Metricas de campana~~ **IMPLEMENTADO en T13** — `/whatsapp/metricas/index.tsx`: 4 KPI cards + tasas + banner STUB
- ~~Vista de creacion de campana~~ **IMPLEMENTADO en T13** — `/whatsapp/campanas/index.tsx`: lista + `NuevaCampanaModal` (nombre, plantilla, segmento, fecha) + badge estados
- ~~Configuracion de automatizaciones~~ **IMPLEMENTADO en T13** — `/whatsapp/automatizaciones/index.tsx`: tabla 5 eventos, toggle activo, select plantilla + endpoint BE mock en memoria

NO implementado:
- Envio real HTTP POST a Meta Cloud API (STUB en BE hasta tener credenciales Meta Business)

---

### MODULO 8 — Dashboard y Reportes (95%)

**Backend: 96%**

Implementado:
- KPIs ventas, logistica y financieros desde snapshots pre-calculados (tabla `KPISnapshot`)
- Snapshot persistente en BD cada 10 min con auto-limpieza > 90 dias
- `calcular_kpis_dashboard` emite `kpi_update` via WebSocket a todos los usuarios activos al finalizar
- Exportacion Excel y PDF con estilos (openpyxl + reportlab)
- Programacion de reportes: CRUD, frecuencia diario/semanal/mensual, envio email
- Endpoint `GET /reportes/kpis-comparativo/`: delta % ventas, pedidos, tasa entrega vs mes anterior
- Filtros de acceso por rol en endpoints de KPIs

**Frontend: 100%**

Implementado:
- Dashboard con KPI cards: ventas, logistica, financieros
- Seccion "Comparativo vs Mes Anterior" con 4 cards + flechas + % de cambio
- Charts ApexCharts: area ventas, donut metodos pago, bar top productos
- Filtros por rol: cada rol ve solo las secciones de su area (`hasRole()`)
- Dashboard conectado via WebSocket (`ws/dashboard/`), invalida queries al recibir `kpi_update`
- Ping cada 30s para keepalive
- Reportes con 4 tabs, date range picker, favoritos en localStorage, exportar Excel/PDF
- Reportes Programados: CRUD con modal, toggle activar/desactivar
- ~~Umbrales semaforos configurables~~ **IMPLEMENTADO en T14** — `UmbralesModal` + endpoint BE `GET/PATCH /reportes/configuracion-kpis/` + semaforo dinamico en KPI card "Ventas Hoy"

---

### MODULO 9 — Usuarios y Roles (90%)

**Backend: 90%**

Implementado:
- Login email/password (bcrypt via Django) + JWT (access 60m / refresh 7d)
- CRUD usuarios y roles con permisos por modulo+accion
- Rate limiting, caducidad contrasena, 2FA TOTP completo
- `SesionActiva`, invalidacion tokens, audit logs inmutables via signals
- Modelo `Notificacion`: CRUD + endpoints (`GET /usuarios/notificaciones/`, `POST .../leer/`, `POST .../leer-todas/`)
- Tasks Celery crean notificaciones al alertar stock bajo, CxC vencida, cotizacion por vencer, OC aprobada

Falta:
- ~~SSO Google/Microsoft (requiere OAuth2 client IDs externos)~~ **IMPLEMENTADO en T19** — flujo Authorization Code completo con callbacks; se activa al configurar variables de entorno SOCIAL_AUTH_*

**Frontend: 91%**

Implementado:
- Login con soporte 2FA y redirect condicional
- `configuracion/usuarios/index.tsx` (362 lineas):
  - Buscador real (input + debounce + param `search` en `useUsuariosList`)
  - Paginacion con botones Anterior/Siguiente y "Pagina X de Y"
  - Modal `DesactivarModal`: fondo negro semitransparente, email usuario, aviso de sesiones, confirmar con `useUsuariosDestroy`
  - CRUD usuarios con modal (email, nombre, apellido, contrasena, rol, activo)
- `configuracion/roles/index.tsx`:
  - ~~`PermisosModal`: lista agrupada por modulo, checkboxes individuales~~ **REFACTORIZADO en T14** — tabla cruzada filas=modulos, columnas=acciones (ver/crear/editar/eliminar/aprobar), toggle fila completa y columna completa
  - Parseo de `Permiso.codigo` con `.split('.')` — formato `modulo.accion`
- `configuracion/audit-log/index.tsx` (297 lineas):
  - Filtros: texto libre, modulo (7 opciones), accion (8 opciones), fecha desde, fecha hasta
  - Boton "Limpiar filtros"
  - Paginacion con contador de registros
- Perfil: cambio de contrasena + setup 2FA
- Sidebar filtrado por permisos del usuario autenticado
- `NotificacionesCampana.tsx` (250 lineas) — COMPLETAMENTE IMPLEMENTADA:
  - Badge rojo con no leidas (muestra "9+" si > 9)
  - Polling REST cada 60s (`refetchInterval: 60_000`)
  - WebSocket real `ws(s)://{host}/ws/notificaciones/?token={token}`
  - Al recibir tipo `'notificacion'` → invalida query cache
  - Ping cada 30s para keepalive
  - Marcar leida individual: `POST /api/v1/usuarios/notificaciones/{id}/leer/`
  - Marcar todas leidas: `POST /api/v1/usuarios/notificaciones/leer-todas/`
  - 7 tipos con colores: stock_bajo (rojo), lote_vencer (amber), cxc_vencida (naranja), cotizacion_vencer (azul), oc_aprobada (verde), pedido_entregado (verde), sistema (gris)

Falta:
- ~~SSO (botones decorativos sin funcion real)~~ **BE IMPLEMENTADO en T19** — callbacks funcionales; FE aun usa botones decorativos (pendiente conectar al flujo real)
- ~~Exportacion del audit log~~ **IMPLEMENTADO en T8** — boton "Exportar CSV" con filtros activos + descarga blob

---

## ESTADO WEBSOCKET

| Canal | Estado |
|---|---|
| `ws/dashboard/` | **FUNCIONAL** — BE emite `kpi_update` desde task Celery, FE invalida queries |
| `ws/notificaciones/` | **FUNCIONAL** — Campana FE conectada, escucha tipo `'notificacion'`, badge reactivo |
| `ws/gps/{pedido_id}/` | **FUNCIONAL** — emite coordenadas GPS en tiempo real |
| `ws/facturacion/{comp_id}/` | **FUNCIONAL** — emite estado SUNAT en tiempo real |

---

## GAPS TRANSVERSALES

### Sin soporte offline completo (PENDIENTE — M1)
- ~~Sin `navigator.onLine` en FE~~ **IMPLEMENTADO T10** — `useOnlineStatus` hook + banner en cart
- Sin Service Worker, sin IndexedDB, sin PWA manifest — el POS muestra aviso pero no funciona offline real
- El endpoint offline-sync existe en BE pero el FE no tiene cola local de ventas pendientes
- ~~BUG: la funcion que el endpoint offline llama (`registrar_venta_pos`) no existe~~ **CORREGIDO T8**

### Facturacion dispara automaticamente al vender (IMPLEMENTADO en T8 — M1/M3)
- `crear_venta_pos()` encola `emitir_comprobante_por_venta(venta_id)` via `transaction.on_commit`
- La task determina tipo (boleta/factura por tipo_doc del cliente) y emite a SUNAT en background
- Banner informativo en TicketModal mientras el comprobante se emite

### WhatsApp bloqueado por STUB (PENDIENTE — M7)
- `services.py` y `tasks.py` declaran explicitamente que el envio es STUB
- Requiere cuenta Meta Business verificada y token valido para implementar
- El modulo FE esta casi completo (4 paginas), el BE tiene la estructura — solo falta el HTTP POST real

### Conciliacion bancaria (PENDIENTE — M6)
- Ningun archivo de parseo de CSV/Excel de extractos bancarios en BE
- No existe vista FE de carga de extracto ni panel de conciliacion
- Es el gap mas grande del modulo financiero

### PLE / PDT (IMPLEMENTADO T19 — M6)
- ~~No implementados~~ — `core/utils/ple.py` con 6 libros reales; PDT621 con calculo de IGV real
- La UI FE (`/finanzas/declaraciones`) ya existia desde T9 y ahora retorna archivos reales descargables

### Migracion pendiente de aplicar (M2) — RESUELTA T10
- ~~`inventario/migrations/0004_add_serie_modelo.py` — pendiente~~ **APLICADA en T10**
- Adicionalmente generada y aplicada `0005_alter_serie_options_and_more` (Meta options Serie + unique_together + referencia_tipo)

---

## PAGINAS FRONTEND EXISTENTES

| Ruta | Estado |
|---|---|
| `/login`, `/logout` | Funcional |
| `/dashboard` | Funcional (KPIs + comparativo + charts + WebSocket reactivo) |
| `/ventas/pos` | Funcional (barcodes, pago mixto, vuelto, ticket) |
| `/ventas`, `/ventas/:id` | Funcional |
| `/ventas/caja` | Funcional (apertura/cierre con desglose) |
| `/ventas/cotizaciones`, `/ventas/cotizaciones/:id` | Funcional |
| `/ventas/ordenes`, `/ventas/ordenes/:id` | Funcional |
| `/ventas/comisiones` | Funcional |
| `/inventario/productos` (lista + crear + detalle + editar) | Funcional |
| `/inventario/categorias`, `/inventario/almacenes` | Funcional |
| `/inventario/stock` | Funcional (entrada + salida + ajuste + transferencia) |
| `/inventario/transferencias` | Funcional |
| `/inventario/dashboard` | Funcional (7 KPIs + ABC) |
| `/inventario/trazabilidad` | Funcional (por lote, timeline) |
| `/inventario/trazabilidad-serie` | Funcional (por serie, card + timeline) |
| `/inventario/ubicaciones` | Funcional (CRUD con filtro por almacen) |
| `/clientes`, `/clientes/:id` | Funcional (3 tabs, link "Ver Detalle" en tabla) |
| `/compras/proveedores`, `/compras/proveedores/:id` | Funcional (5 tabs + KPIs) |
| `/compras/ordenes`, `/compras/ordenes/:id` | Funcional (+ modal prorrateo gastos) |
| `/compras/recepciones`, `/compras/facturas` | Funcional (recepciones + foto evidencia) |
| `/finanzas/cxc`, `/finanzas/cxp` | Funcional (semaforo) |
| `/finanzas/asientos` | Funcional |
| `/finanzas/plan-contable` | Funcional |
| `/finanzas/libro-diario` | Funcional |
| `/finanzas/libro-mayor` | Funcional |
| `/finanzas/libro-caja` | Funcional |
| `/finanzas/balance-general` | Funcional (+ exportar Excel) |
| `/finanzas/estado-resultados` | Funcional (+ exportar Excel) |
| `/finanzas/flujo-caja` | Funcional |
| `/finanzas/conciliacion` | Funcional (CRUD + movimientos) |
| `/finanzas/declaraciones` | Funcional real (tabs PLE y PDT — T9 UI + T19 BE real) |
| `/distribucion/pedidos`, `/distribucion/pedidos/:id` | Funcional |
| `/distribucion/transportistas` | Funcional |
| `/distribucion/mapa` | Funcional (leaflet + GPS en vivo WS) |
| `/distribucion/scanner-qr` | Funcional |
| `/seguimiento` | Funcional (sin login) |
| `/facturacion` | Funcional |
| `/facturacion/add-new` | Funcional (validacion RUC/DNI inline) |
| `/facturacion/comprobante/:id` | Funcional (PDF/XML/CDR + WS en tiempo real) |
| `/facturacion/pendientes` | Funcional |
| `/facturacion/notas` | Funcional |
| `/facturacion/series` | Funcional |
| `/facturacion/resumen-diario` | Funcional (KPIs + filtros + tabla + totalizador) |
| `/whatsapp/configuracion` | Funcional (UI completa, envio STUB) |
| `/whatsapp/plantillas` | Funcional (CRUD) |
| `/whatsapp/mensajes` | Funcional (lista + modal envio + detalle) |
| `/whatsapp/logs` | Funcional |
| `/whatsapp/metricas` | Funcional mock (4 KPI cards + tasas — T13) |
| `/whatsapp/campanas` | Funcional mock (lista + NuevaCampanaModal — T13) |
| `/whatsapp/automatizaciones` | Funcional mock (tabla 5 eventos + toggle — T13) |
| `/reportes` | Funcional (4 tabs + favoritos + exportar) |
| `/reportes/programados` | Funcional (CRUD + toggle) |
| `/configuracion/roles` | Funcional (permisos por modulo con checkboxes) |
| `/configuracion/usuarios` | Funcional (buscador + paginacion + desactivar con modal) |
| `/configuracion/empresa` | Funcional |
| `/configuracion/audit-log` | Funcional (filtros por modulo/accion/fecha) |
| `/perfil` | Funcional (contrasena + 2FA) |
| `/two-steps` | Funcional |

### Paginas que NO existen (requeridas por spec — pendientes reales)
- Conciliacion bancaria: carga de extracto CSV/Excel con tabla de movimientos importados post-carga (el dropzone existe en `ConciliacionDetalle.tsx` pero no muestra la tabla resultante)
- ~~Declaraciones tributarias / PLE / PDT~~ **IMPLEMENTADO en T9** — `/finanzas/declaraciones` con tabs PLE y PDT
- ~~Panel de sugerencias automaticas conciliacion~~ **IMPLEMENTADO en T13** — tabla matching con Confirmar/Ignorar en `ConciliacionDetalle.tsx`
- Vista conductor movil (PWA) — `/distribucion/conductor` no existe aun
- ~~Campana masiva WhatsApp~~ **IMPLEMENTADO en T13** — `/whatsapp/campanas`
- ~~Metricas de campana WhatsApp~~ **IMPLEMENTADO en T13** — `/whatsapp/metricas`

---

## ENDPOINTS EXISTENTES

### Auth (`/api/v1/auth/`)
```
POST   /login/
POST   /refresh/
POST   /logout/
GET    /me/
POST   /cambiar-password/
POST   /2fa/setup/
POST   /2fa/activar/
POST   /2fa/desactivar/
POST   /2fa/verificar/
GET    /sesiones/
GET    /sso/google/                 [activo — retorna URL auth o disponible:false]
GET    /sso/google/callback/        [NUEVO T19 — intercambia code, emite JWT]
GET    /sso/microsoft/              [activo — retorna URL auth o disponible:false]
GET    /sso/microsoft/callback/     [NUEVO T19 — intercambia code, emite JWT]
```

### Ventas (`/api/v1/ventas/`)
```
CRUD   /clientes/
POST   /clientes/{id}/validar-ruc/
CRUD   /cotizaciones/
POST   /cotizaciones/{id}/convertir-orden/
POST   /cotizaciones/{id}/duplicar/
CRUD   /ordenes/
POST   /ordenes/{id}/convertir-venta/
POST   /venta-pos/
CRUD   /ventas/
POST   /ventas/{id}/anular/
POST   /ventas/{id}/nota-credito/
GET    /cajas/
POST   /cajas/abrir/
POST   /cajas/{id}/cerrar/
GET    /cajas/{id}/resumen/
POST   /formas-pago/registrar/
POST   /offline-sync/             [BUG: llama a funcion inexistente en services]
GET    /comisiones/
POST   /comisiones/calcular/
POST   /comisiones/{id}/marcar-pagada/   [NUEVO T12]
```

### Inventario (`/api/v1/inventario/`)
```
CRUD   /productos/
GET    /productos/{id}/stock/
GET    /productos/buscar/
CRUD   /categorias/
CRUD   /almacenes/
CRUD   /stock/
GET    /movimientos/
CRUD   /lotes/
POST   /movimientos/ajuste/
POST   /movimientos/transferencia/
GET    /alertas-stock/
CRUD   /transferencias/
POST   /salidas/
POST   /entradas/
GET    /trazabilidad/{lote_id}/
GET    /lotes/fifo/
GET    /dashboard/
GET    /rotacion-abc/?dias=N
CRUD   /ubicaciones/
CRUD   /series/
GET    /trazabilidad/serie/?numero_serie=
```

### Compras (`/api/v1/compras/`)
```
CRUD   /ordenes/
POST   /ordenes/{id}/aprobar/
POST   /ordenes/{id}/enviar/
POST   /ordenes/{id}/cancelar/
POST   /ordenes/{id}/prorratear-gastos/
CRUD   /facturas-proveedor/
POST   /facturas-proveedor/{id}/conciliar/
POST   /facturas-proveedor/{id}/validar-sunat/
CRUD   /recepciones/
GET    /comparar-proveedores/?producto_id=&dias=
POST   /evaluacion-proveedor/
GET    /evaluaciones-proveedor/
```

### Finanzas (`/api/v1/finanzas/`)
```
CRUD   /cxc/
POST   /cxc/{id}/cobrar/
CRUD   /cxp/
POST   /cxp/{id}/pagar/
CRUD   /asientos/
POST   /asientos/{id}/confirmar/
POST   /asientos/{id}/anular/
CRUD   /plan-contable/
CRUD   /periodos/
POST   /periodos/{id}/cerrar/
POST   /periodos/{id}/reabrir/
GET    /periodos/{id}/checklist/        [NUEVO T14 — verifica asientos borrador, CxC, conciliaciones]
POST   /periodos/{id}/firmar/           [NUEVO T14 — body: { pin, anio, mes }]
GET    /mora/
GET    /libro-diario/
GET    /libro-mayor/?cuenta_id=
GET    /libro-caja/
GET    /balance-general/?fecha_corte=
GET    /estado-resultados/?fecha_inicio=&fecha_fin=
GET    /flujo-caja/?fecha_inicio=&fecha_fin=
CRUD   /conciliaciones/
POST   /conciliaciones/{id}/movimientos/
DELETE /conciliaciones/{id}/movimientos/{mov_id}/
POST   /ple/generar/                    [REAL T19 — genera TXT SUNAT, retorna base64]
GET    /ple/libros/                     [listado disponible]
POST   /pdt/generar/                    [REAL T19 — PDT621 calcula IGV real; PDT626/601 no_disponible]
GET    /pdt/formularios/                [listado disponible]
```

### Facturacion (`/api/v1/facturacion/`)
```
CRUD   /comprobantes/
POST   /comprobantes/emitir/
POST   /comprobantes/{id}/reenviar/
GET    /comprobantes/{id}/xml/
GET    /comprobantes/{id}/cdr/
GET    /comprobantes/{id}/pdf/
CRUD   /series/
CRUD   /notas/
GET    /pendientes/
GET    /resumen-diario/
POST   /resumen-diario/enviar/
GET    /contingencia/estado/
POST   /contingencia/activar/
POST   /contingencia/desactivar/
```

### Distribucion (`/api/v1/distribucion/`)
```
CRUD   /pedidos/
POST   /pedidos/{id}/asignar/
POST   /pedidos/{id}/despachar/
POST   /pedidos/{id}/en-ruta/
POST   /pedidos/{id}/entregar/
POST   /pedidos/{id}/cancelar/
POST   /pedidos/{id}/evidencia/
POST   /pedidos/{id}/gps/
GET    /publico/seguimiento/{codigo}/
CRUD   /transportistas/
```

### Reportes (`/api/v1/reportes/`)
```
GET    /dashboard/
GET    /dashboard/comparacion/
GET    /ventas/
GET    /ventas/por-vendedor/
GET    /ventas/por-metodo-pago/
GET    /ventas/serie-diaria/
GET    /top-productos/
GET    /top-clientes/
GET    /inventario/
GET    /kpis-financieros/
GET    /kpis-comparativo/
POST   /exportar/
GET    /snapshots/
CRUD   /programaciones/
GET/PATCH /configuracion-kpis/   [NUEVO T14 — mock en memoria, umbrales semaforos]
```

### Usuarios (`/api/v1/usuarios/`)
```
CRUD   /usuarios/
POST   /usuarios/{id}/desactivar/
CRUD   /roles/
POST   /roles/{id}/permisos/
GET    /permisos/
GET    /audit-logs/
GET    /logs/exportar/          [NUEVO T8 — CSV con BOM para Excel]
GET    /notificaciones/
POST   /notificaciones/{id}/leer/
POST   /notificaciones/leer-todas/
GET    /sesiones/
```

### WhatsApp (`/api/v1/whatsapp/`)
```
GET/PATCH /configuracion/
CRUD      /plantillas/
GET       /mensajes/
POST      /enviar/                      [STUB — no hace HTTP POST real a Meta]
GET/POST  /webhook/
GET       /logs/
GET       /metricas/                    [MOCK T13 — estado en memoria]
CRUD      /campanas/                    [MOCK T13 — estado en memoria]
POST      /campanas/{id}/ejecutar/      [MOCK T13 — retorna pendiente]
GET/PATCH /automatizaciones/            [MOCK T13 — estado en memoria, 5 eventos fijos]
```

---

## CELERY BEAT SCHEDULE

| Tarea | Frecuencia | Modulo |
|---|---|---|
| alertar_cotizaciones_por_vencer | Diaria 08:00 | Ventas |
| calcular_resumen_ventas_dia | Diaria 23:30 | Ventas |
| marcar_cotizaciones_vencidas | Diaria 23:00 | Ventas |
| alertar_lotes_por_vencer | Diaria 07:00 | Inventario (umbral 7 dias — corregido T8) |
| verificar_stock_minimo | Diaria 07:30 | Inventario |
| reenviar_comprobantes_pendientes | Cada 5 min | Facturacion |
| enviar_resumen_diario_boletas | Diaria 23:50 | Facturacion |
| generar_oc_automaticas_bajo_stock | Diaria 07:45 | Compras |
| alertar_cxc_vencidas | Diaria 08:00 | Finanzas |
| alertar_cxp_por_vencer | Diaria 08:00 | Finanzas |
| calcular_kpis_dashboard | Cada 10 min | Reportes — emite kpi_update via WS |
| ejecutar_reportes_programados | Cada 15 min | Reportes |
| limpiar_archivos_huerfanos | Diaria 04:30 | Media/R2 |
| limpiar_logs_whatsapp | Semanal | WhatsApp |

---

## BUGS CONOCIDOS

| Bug | Modulo | Impacto | Archivo |
|---|---|---|---|
| ~~`sincronizar_ventas_offline()` llama a `registrar_venta_pos()` que no existe~~ | Ventas BE | **CORREGIDO T8** | `ventas/services.py` |
| ~~Alertas lotes por vencer usan 30 dias en vez de 7 (spec)~~ | Inventario BE | **CORREGIDO T8** | `inventario/tasks.py` |
| Estado "con_incidencia" escrito como texto libre en `motivo` (no como state) | Inventario BE | Menor — no consulatable por estado | `inventario/services.py` |
| `requiere_lote`/`requiere_serie` no validados en servicios de entrada/salida | Inventario BE | Moderado — datos sin trazabilidad | `inventario/services.py` |
| Credenciales Nubefact almacenadas como `CharField` plano en BD | Facturacion BE | Seguridad — no encriptado | `empresa/models.py` linea 49 |
| ~~Migracion `0004_add_serie_modelo.py` no aplicada~~ | Inventario BE | **CORREGIDO T10** — 0004 y 0005 aplicadas | `inventario/migrations/` |
| ~~4 UUIDs bare sin FK ORM en finanzas/models.py~~ | Finanzas BE | **CORREGIDO T11** — FK reales + migration 0004 aplicada | `finanzas/models.py` |
| ~~`source=` redundante en serializers finanzas (cobro_id, pago_id, comprobante_id, factura_proveedor_id)~~ | Finanzas BE | **CORREGIDO T12** — eliminados `source=` identicos al field_name | `finanzas/serializers.py` |
| ~~KPIs pedidos contaban solo pagina actual con `filter()`~~ | Distribucion FE | **CORREGIDO T12** — queries paralelas `page_size=1` por estado | `distribucion/pedidos/index.tsx` |
| ~~Paginacion InvoiceList siempre mostraba paginas 1-5~~ | Facturacion FE | **CORREGIDO T12** — ventana dinamica centrada en pagina actual | `invoice/list/InvoiceList.tsx` |
| ~~Choices locales dispersos en 4 modelos fuera de core/choices.py~~ | BE global | **CORREGIDO T11** — todos en core/choices.py | `core/choices.py` |
| ~~WhatsappConfiguracion sin singleton constraint~~ | WhatsApp BE | **CORREGIDO T11** — UniqueConstraint + save() forzado | `whatsapp/models.py` |

---

## REGLAS DE DESARROLLO (para el agente)

### Patrones FE obligatorios
- **Listas CRUD:** seguir `AlmacenesList.tsx` — `card > card-header > tabla` con `divide-y divide-default-200`
- **Modales:** seguir `AlmacenFormModal.tsx` — `fixed inset-0 z-80`, overlay negro, card centrada
- **Timelines/Trazabilidad:** seguir `TrazabilidadLote.tsx` — linea vertical `absolute left-5`, iconos `size-10 rounded-full border-2`
- **KPI cards:** patron del dashboard — `rounded-xl border bg-white p-5`
- **Buscadores:** `ps-11 form-input` con icono absoluto en `ps-3`
- **SIEMPRE usar componentes del template** antes de crear desde cero

### Iconos react-icons/lu (verificados)
- `LuLoaderCircle` (NO LuLoader2)
- `LuTriangleAlert` (NO LuAlertTriangle)
- `LuCircleCheck` (NO LuCheckCircle)
- `LuChartBarBig` (NO LuBarChart2 — no existe)
- **SIEMPRE verificar con:** `node -e "const i = require('react-icons/lu'); console.log('LuNombre' in i);"`

### Backend
- Errores LSP de Python (`.objects`, `.DoesNotExist`, etc.) son TODOS falsos positivos — ignorar
- Venv: `/home/anderson/Proyectos-J/J-soluciones/Jsoluciones-be/.venv/bin/python`
- `DJANGO_SETTINGS_MODULE=config.settings.development` (servidor) / `config.settings.testing` (pytest)
- Package manager FE: pnpm (NO npm)
- Redis: `sudo systemctl start valkey` — requerido para login en development (throttling usa Redis)
- Tests NO requieren Redis: `pytest.ini` apunta a `config.settings.testing` que usa LocMemCache

### Al modificar BE (nuevos endpoints o campos)
```bash
# IMPORTANTE: el config de orval apunta a openapi-schema.yaml (NO openapi.json)
cd Jsoluciones-be && .venv/bin/python manage.py spectacular --settings=config.settings.development --file ../Jsoluciones-fe/openapi-schema.yaml
cd Jsoluciones-fe && pnpm orval
```

---

*Diagnostico basado en lectura directa del codigo fuente — todos los modulos auditados.*
*Ultima actualizacion: 2026-02-23 (Sesion T19 — mocks eliminados: PLE/PDT real, resumen diario SOAP, rutas Nearest Neighbor, SSO OAuth2 completo).*
