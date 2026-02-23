# JSoluciones ERP — Documentacion

> Repositorio de documentacion del proyecto JSoluciones ERP.
> Single-tenant. Sin multi-tenancy. Sin eCommerce. Una empresa por instalacion.

## Estructura

```
instrucciones/        — Reglas y spec (leer siempre antes de tocar codigo)
  JSOLUCIONES_MODULOS_VERSION_FINAL.MD  — SPEC PRINCIPAL (fuente de verdad)
  05_REGLAS_AGENTE.md                   — Reglas del agente de desarrollo
  COMANDOS_CLAVE.md                     — Comandos de desarrollo (venv, pnpm, etc.)
  REGLAS_BACKEND.md                     — Patrones y convenciones backend
  REGLAS_FRONTEND.md                    — Patrones y convenciones frontend
  PROCESOS_FRONTEND.md                  — Flujos y procesos frontend

contexto/             — Estado actual y referencia tecnica
  ESTADO_ACTUAL.md                      — Estado real por modulo (actualizado)
  Jsoluciones_devops_service.md         — Arquitectura DevOps y servicios
  Jsoluciones_Logistica_Backend.md      — Spec detallada logistica backend
  Jsoluciones_roles_flujos.MD           — Roles de usuario y flujos de negocio
  10 _mapa_template_tailwick.md         — Mapa de componentes UI del template
  TEMPLATE_COMPONENTES_A_USAR.md        — Componentes UI disponibles

historial/            — Documentos obsoletos o ya ejecutados (no leer)

SQL_JSOLUCIONES.sql   — Esquema completo de BD (tablas, enums, indices)
```

## Estado del Proyecto (2026-02-22)

| Modulo | Backend | Frontend | Promedio |
|---|:---:|:---:|:---:|
| Ventas / POS | 90% | 78% | 84% |
| Inventario | 92% | 90% | 91% |
| Facturacion Electronica | 85% | 72% | 78% |
| Distribucion y Seguimiento | 88% | 85% | 86% |
| Compras y Proveedores | 92% | 88% | 90% |
| Gestion Financiera | 72% | 65% | 68% |
| WhatsApp | 15% | 0% | 7% |
| Dashboard y Reportes | 92% | 90% | 91% |
| Usuarios y Roles | 90% | 87% | 88% |
| **TOTAL** | **~83%** | **~76%** | **~80%** |

Ver `contexto/ESTADO_ACTUAL.md` para detalle completo por modulo.

## Lo que falta (resumen)

**WhatsApp (7%):** Envio real HTTP a Meta (STUB), HMAC webhook, opt-in, campanas, toda la UI.
**Facturacion FE:** Emision manual completa, vista previa PDF, resumen diario boletas.
**Finanzas:** Conciliacion bancaria, PLE/PDT SUNAT, diferencia de cambio, indicador periodo.
**Responsive/PWA:** Vista movil vendedor, vista conductor, Service Worker + IndexedDB.

## Stack

| Capa | Tecnologia |
|---|---|
| Backend | Django 4.x + DRF + PostgreSQL 16 |
| Async | Celery + Redis (3 colas) |
| WebSocket | Django Channels + Daphne ASGI |
| Storage | Cloudflare R2 |
| Facturacion | Nubefact OSE via HTTP |
| Frontend | React 19 + TypeScript + Vite + TanStack Query |
| UI | Tailwind CSS 4 + Preline (Tailwick) |
| API client | Orval (codegen desde OpenAPI) |

## Repositorios

| Repo | Descripcion |
|---|---|
| `Jsoluciones-be` | Django Backend (API REST) |
| `Jsoluciones-fe` | React Frontend |
| `Jsoluciones-docs` | Este repo — documentacion |
