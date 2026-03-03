# JSoluciones ERP — Documentacion

> ERP de gestion empresarial para el mercado peruano (PYMES).
> Single-tenant. Una empresa por instalacion. Sin multi-tenancy.
> Stack: Django 4.2 + React 19 + PostgreSQL 16 + Celery + Redis + Nubefact.

---

## Estructura de Documentacion

```
Jsoluciones-docs/
├── README.md                    <- Este archivo (indice + estado del proyecto)
├── SQL_JSOLUCIONES.sql          <- Schema completo de BD (tablas, enums, indices)
├── start-services.sh            <- Script para iniciar servicios en desarrollo
│
├── context/                     <- QUE ES el proyecto
│   ├── OVERVIEW.md              <- Vision general, stack, arquitectura, repos
│   ├── MODULES.md               <- Modulos del sistema, estado % por modulo, stubs
│   ├── DATABASE.md              <- Reglas de BD, enums, choices, convenciones SQL
│   ├── DEVOPS.md                <- Redis, Celery, Channels, Docker, produccion
│   ├── FLOWS.md                 <- Flujos paso a paso por rol (10 roles, tabla de accesos)
│   └── SYNC_LOG.md              <- Mejoras ya aplicadas al template (FE + BE)
│
└── rules/                       <- COMO SE TRABAJA
    ├── AGENT.md                 <- Reglas del agente: que hacer/no hacer, protocolo
    ├── BACKEND.md               <- Reglas Django/DRF, patrones, convenciones
    ├── FRONTEND.md              <- Reglas React/TS, patrones, convenciones
    └── COMMANDS.md              <- Comandos para correr, depurar, testear
```

---

## Indice Rapido

| Tengo esta duda... | Leo este archivo |
|--------------------|-----------------|
| Que es el proyecto, para que sirve | `context/OVERVIEW.md` |
| Que modulos hay, cual es su estado, que es stub | `context/MODULES.md` |
| Reglas de la base de datos, que choices existen | `context/DATABASE.md` |
| Como funciona Redis, Celery, WebSockets, Docker | `context/DEVOPS.md` |
| Que puede hacer cada rol, flujos paso a paso | `context/FLOWS.md` |
| Que mejoras ya se aplicaron al template base | `context/SYNC_LOG.md` |
| Reglas del agente, que puedo/no puedo hacer | `rules/AGENT.md` |
| Patrones Django, como hacer un endpoint | `rules/BACKEND.md` |
| Patrones React, como hacer una pagina | `rules/FRONTEND.md` |
| Como correr el backend/frontend, como depurar | `rules/COMMANDS.md` |
| Schema de la base de datos | `SQL_JSOLUCIONES.sql` |

---

## Estado del Proyecto (Mar 2026)

| Modulo | Backend | Frontend | Promedio |
|--------|:-------:|:--------:|:-------:|
| 1. Ventas / POS | ~91% | ~78% | ~85% |
| 2. Inventario | ~91% | ~87% | ~89% |
| 3. Facturacion Electronica | ~87% | ~85% | ~86% |
| 4. Distribucion y Seguimiento | ~88% | ~86% | ~87% |
| 5. Compras y Proveedores | ~94% | ~88% | ~91% |
| 6. Gestion Financiera | ~92% | ~92% | ~92% |
| 7. WhatsApp | ~45% | ~70% | ~57% |
| 8. Dashboard y Reportes | ~96% | ~100% | ~98% |
| 9. Usuarios y Roles | ~96% | ~97% | ~96% |
| **TOTAL** | **~91%** | **~87%** | **~89%** |

Ver `context/MODULES.md` para detalle completo por modulo, stubs y pendientes.

---

## Lo que Falta (Resumen)

- **WhatsApp (~57%)**: El envio real a Meta es STUB. Requiere credenciales `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`. El frontend ya tiene todas las vistas.
- **POS offline**: El banner "sin conexion" existe pero no hay Service Worker ni IndexedDB real.
- **FIFO automatico**: `registrar_salida()` no aplica FIFO automatico. Solo consulta sugerida.
- **Mapa distribucion**: El backend tiene GPS WebSocket. El frontend no tiene mapa visual (requiere react-leaflet).
- **PDT626/PDT601**: Retornan "no_disponible" — datos de retenciones/planilla fuera del alcance.

---

## Stack

| Capa | Tecnologia |
|------|-----------|
| Backend | Django 4.2 + DRF + PostgreSQL 16 |
| Auth | simplejwt (access 60min, refresh 7d) |
| Async | Celery + Redis (3 colas) |
| WebSocket | Django Channels + Daphne ASGI |
| Storage | Cloudflare R2 (3 buckets privados) |
| Facturacion | Nubefact OSE via HTTP (demo VERIFICADO) |
| Frontend | React 19 + TypeScript 5.8 + Vite 7 + TanStack Query 5 |
| UI | Tailwind CSS 4 + Preline 3.2 |
| API client | Orval 8 (codegen desde OpenAPI) |

---

## Repositorios

| Repo | Descripcion |
|------|-------------|
| `Jsoluciones-be` | Django Backend (API REST + WebSockets + Celery) |
| `Jsoluciones-fe` | React Frontend (Vite + TanStack Query + Orval) |
| `Jsoluciones-docs` | Este repo — documentacion |

> `Amatista-be/` y `Amatista-fe/` son un proyecto DISTINTO derivado de este template. NO modificar.
