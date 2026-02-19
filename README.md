# JSoluciones ERP - Documentación

> Repositorio de documentación completa del proyecto JSoluciones ERP.

## Estructura

- **`contexto/`** - Contexto técnico, plan de ejecución, estado actual y mapa de vistas
- **`instrucciones/`** - Reglas de desarrollo para backend, frontend y base de datos
- **`historial/`** - Documentación archivada y verificada
- **`SQL_JSOLUCIONES.sql`** - Esquema completo de base de datos (47 tablas, 33 enums)

## Repositorios del Proyecto

| Repositorio | Descripción | URL |
|------------|-------------|-----|
| **Jsoluciones-be** | Django Backend (API REST) | `J-Soluciones/Jsoluciones-be` |
| **Jsoluciones-fe** | React Frontend (Tailwick) | `J-Soluciones/Jsoluciones-fe` |
| **Jsoluciones-docs** | Documentación (este repo) | `ander0code/Jsoluciones-docs` |

## Estado del Proyecto

Ver `contexto/19_ESTADO_ACTUAL_Y_VISTAS.md` para el estado actual del 50% del proyecto.

### Progreso Actual
- ✅ **Capa 0:** Infraestructura (Docker, Django, React)
- ✅ **Capa 1:** Auth + Login (JWT, RBAC, permisos)
- ⬜ **Capa 2:** Inventario (en desarrollo)
- ⬜ **Capa 3:** Clientes + Ventas (POS)
- ⬜ **Capa 4:** Facturación Nubefact
- ⬜ **Capa 5:** Media + Proveedores

## Stack Tecnológico

- **Backend:** Django 4.x + DRF + JWT + PostgreSQL
- **Frontend:** React 19 + TypeScript + Tailwind + Vite
- **Facturación:** Nubefact API
- **Storage:** Cloudflare R2
- **Async:** Celery + Redis

## Autor

Desarrollado para J-Soluciones ERP
