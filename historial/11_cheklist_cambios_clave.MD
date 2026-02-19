# CHECKLIST PARA AGENTE — Validación Anti Multi-Tenant

> **Propósito:** Antes de comenzar a implementar la DB y el backend, el agente debe
> validar que TODOS los archivos de contexto (00 al 10) están limpios de referencias
> multi-tenant activas. Este documento lista exactamente qué se cambió, qué se quedó
> como negación intencional, y qué archivo aún necesita actualización.

---

## DECISIÓN ARQUITECTÓNICA

```
ANTES:  ERP SaaS multi-tenant con django-tenants (multi-schema PostgreSQL)
AHORA:  ERP por instancia — un deploy + una DB por cada empresa cliente

LO QUE SE ELIMINÓ:
  ❌ django-tenants (paquete)
  ❌ SHARED_APPS / TENANT_APPS (config de settings)
  ❌ migrate_schemas --shared / --tenant
  ❌ schema_context / connection.schema_name
  ❌ TenantSyncRouter
  ❌ Modelo Tenant, Domain, PlanSuscripcion
  ❌ Modelo UsuarioGlobal (con M2M a tenants)
  ❌ App tenants/, planes/, usuarios_global/
  ❌ Header X-Tenant-Schema en frontend
  ❌ Ruta /select-tenant en frontend
  ❌ tenant_id en tablas

LO QUE LO REEMPLAZA:
  ✅ PostgreSQL estándar (django.db.backends.postgresql)
  ✅ INSTALLED_APPS normal (sin SHARED/TENANT)
  ✅ python manage.py migrate (normal)
  ✅ Modelo Empresa (1 fila — config de la empresa)
  ✅ Modelo Usuario (AbstractUser con email login)
  ✅ App empresa/ (configuración)
  ✅ Solo JWT en header Authorization
  ✅ Login → directo a /dashboard
```

---

## ESTADO DE CADA ARCHIVO

### ✅ 00_PLAN_EJECUCION.md — LIMPIO (corregido)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Qué se cambió:** `usuarios_global/ → UsuarioGlobal` → `usuarios/ → Usuario (AbstractUser con email login)`. También los cambios anteriores: "Multi-tenancy → Crear tenant" → "Empresa + Auth → Config empresa, login JWT", `migrate_schemas` → `migrate`, `django-tenants en settings` → `PostgreSQL + DRF + JWT en settings`.
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 01_CORE_PROYECTO.md — LIMPIO (reescrito completo)
- **Refs "tenant":** 11 (todas son negaciones intencionales ✓)
- **Refs críticas:** 0
- **Negaciones presentes (correctas, NO borrar):**
  - Línea 12: "No es multi-tenant"
  - Línea 19: "si se necesita multi-tenant, se puede migrar después"
  - Línea 38-41: ~~django-tenants~~, ~~Modelo Tenant~~, ~~UsuarioGlobal~~ (tachados)
  - Línea 50: "Sin django-tenants, sin multi-schema"
  - Línea 77: "Modelo Empresa (reemplaza al Tenant)"
  - Línea 117: "simple, sin multi-tenant"
  - Línea 186/222: "sin django-tenants"
  - Línea 448: "NO usar django-tenants" (anti-patrón)
- **Qué se cambió:** Se reescribió completo. Nueva sección 4 con arquitectura por instancia, modelo Empresa, modelo Usuario simple, settings sin django-tenants, sección 9 de despliegue por clonación.
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 02_REGLAS_BACKEND_v2.md — LIMPIO (corregido)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Qué se cambió (aplicado en esta corrección):**
  - Título: `"Django + DRF + django-tenants"` → `"Django + DRF"`
  - BACK-13: `"compatibilidad con django-tenants"` → `"compatibilidad con el stack"`
  - BACK-17: `"filtrar por tenant"` → `"filtrar (siempre aplicar permisos del usuario)"`
  - BACK-29: `"configuración del tenant"` → `"configuración de la empresa"`
  - Swagger description: `"multi-tenant"` → quitado
  - Tag `'Tenants'` → `'Empresa'`
  - Cache keys: `connection.schema_name` eliminado de cache_key y pattern
  - Docstring viewset: `"ventas del tenant actual"` → `"ventas"`
  - on_commit Celery: `connection.schema_name, venta.id` → `venta.id`
  - Tabla caché: `"Config del tenant"` → `"Config de la empresa"`
  - Rol admin: `"Control total del tenant"` → `"Control total del sistema"`
  - Seed: `"DENTRO del schema del tenant"` → `"al configurar una nueva instancia"`
  - Excepción: `TenantInactivoError` → `EmpresaInactivaError`
  - Checklist: `"schema_name a Celery"` → `"IDs necesarios a Celery"`
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 03_REGLAS_BASE_DATOS.md — LIMPIO (corregido)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Qué se cambió (aplicado en esta corrección):**
  - DB-04: `"Usar django-tenants: SHARED/TENANT"` → `"Una sola DB por instancia, schema public estándar"`
  - `"Todo modelo dentro de TENANT_APPS"` → `"Todo modelo del ERP"`
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 04_REGLAS_FRONTEND_v2.md — LIMPIO (corregido)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Qué se cambió (aplicado en esta corrección):**
  - FRONT-05: `"auth/tenant"` → `"auth/empresa"`
  - Context: `"tenant activo"` → `"empresa activa"`
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 05_REGLAS_AGENTE.md — LIMPIO (corregido)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Qué se cambió (aplicado en esta corrección):**
  - Stack: `"Django, DRF, django-tenants, PostgreSQL..."` → `"Django, DRF, PostgreSQL..."`
  - Compatibilidad: `"con django-tenants"` → `"con el stack actual"`
  - Tabla de docs: `"django-tenants, services pattern"` → `"services pattern"`
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 06_CONSTANTES_COMPARTIDAS.md — LIMPIO (sin cambios)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Nota:** Este archivo nunca tuvo refs multi-tenant. Contiene choices, mixins, validators y permisos que son agnósticos a la arquitectura.
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 07_PROCESOS_BACKEND.md — LIMPIO (reescrito completo)
- **Refs "tenant":** 4 (todas negaciones: "NO multi-tenant", "Sin django-tenants" ✓)
- **Refs críticas:** 0
- **Qué se cambió:** Reescrito completo.
  - Proceso 1: "Setup django-tenants" → "Setup Django + PostgreSQL estándar"
  - `migrate_schemas` → `migrate`
  - `create_tenant` → `setup_empresa` (management command)
  - Apps: eliminadas tenants/, planes/, usuarios_global/. Agregada empresa/
  - Requirements: sin django-tenants en el listado
  - Verificaciones: sin "crear tenant de prueba"
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 08_PROCESOS_FRONTEND.md — LIMPIO (corregido)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Qué se cambió (aplicado en esta corrección):**
  - Descripción: `"SaaS multi-tenant"` → `"ERP para empresas peruanas"`
  - Header: `"X-Tenant-Schema"` → `"solo JWT en header Authorization"`
  - Vista `/select-tenant` marcada como eliminada en Sprint 1
  - Login flow: `"si >1 tenant → select-tenant"` → `"directo a /dashboard"`
  - Topbar: `"Nombre del tenant actual"` → `"Nombre de la empresa"`
  - JSON /auth/me/: `"tenant": {schema_name}` → `"empresa": {ruc, razon_social}`
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 09_PROCESOS_DATABASE.md — LIMPIO (reescrito completo)
- **Refs "tenant":** 1 (negación: "Sin django-tenants" ✓)
- **Refs críticas:** 0
- **Qué se cambió:** Reescrito completo.
  - DB engine: `django_tenants.postgresql_backend` → `django.db.backends.postgresql`
  - Sin DATABASE_ROUTERS, sin TenantSyncRouter
  - Eliminadas secciones: "Schema public", "Schema por tenant", "Tenant creation process"
  - Todas las tablas en UN solo schema public
  - Agregado modelo Empresa con `save()` que solo permite 1 fila
  - Migraciones: `migrate` normal, no `migrate_schemas`
  - Nuevo: sección "Para clonar a una nueva empresa"
  - Nuevo: management command `setup_empresa`
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

### ✅ 10_MAPA_TEMPLATE_TAILWICK.md — LIMPIO (corregido)
- **Refs "tenant":** 0
- **Refs críticas:** 0
- **Qué se cambió (aplicado en esta corrección):**
  - Auth modern-register: `"nuevos tenants"` → `"nuevas empresas"`
- **⚡ Acción del agente:** Ninguna. Listo para usar.

---

## ⚠️ ARCHIVO PENDIENTE DE ACTUALIZAR

### ❌ JSOLUCIONES_DB_DIAGRAM.dbml — NECESITA ACTUALIZACIÓN
- **Refs "tenant":** 15
- **Refs críticas:** Muchas (tablas Tenant, Domain, PlanSuscripcion, UsuarioGlobal, usuario_tenant, schema_name, tenant_id)
- **Qué tiene mal:**
  - Línea 3: "django-tenants (multi-schema)"
  - Tablas que NO deben existir: `planes_suscripcion`, `tenants`, `domains`, `usuario_tenant`
  - Campo `schema_name` en tabla tenants
  - Campo `tenant_id` en relaciones
  - Sección "SCHEMA TENANT" (ya no hay schemas separados)
- **⚡ Acción del agente:** ACTUALIZAR este archivo antes de implementar la DB.
  - Eliminar tablas: tenants, domains, planes_suscripcion, usuario_tenant, usuarios_global
  - Agregar tabla: empresa (config de la empresa, 1 fila)
  - Cambiar tabla de usuarios: Usuario con AbstractUser (email login, sin M2M a tenants)
  - Quitar toda referencia a schema_name y tenant_id
  - Todo en un solo schema public

---

## RESUMEN EJECUTIVO

```
ARCHIVOS 00-10:  ✅ TODOS LIMPIOS — Corregidos y listos para implementar
DBML:            ❌ PENDIENTE — Actualizar antes de crear modelos Django

ÚLTIMA CORRECCIÓN: Se aplicaron los cambios que estaban documentados pero no
ejecutados en los archivos: 00, 02, 03, 04, 05, 08, 10.

VERIFICACIÓN RÁPIDA (el agente puede correr esto):
  grep -r -i "django_tenants\|SHARED_APPS\|TENANT_APPS\|migrate_schemas\|schema_context\|TenantSyncRouter\|X-Tenant-Schema\|select-tenant\|UsuarioGlobal\|usuarios_global" /ruta/a/los/archivos/*.md
  → Resultado esperado: 0 coincidencias (solo negaciones tachadas en 01)

TÉRMINOS QUE SÍ APARECEN (negaciones intencionales, NO son errores):
  - "No es multi-tenant"
  - "Sin django-tenants"
  - "~~django-tenants~~" (tachado)
  - "NO usar django-tenants"
  - "reemplaza al Tenant"
  - "~~Selección de Tenant~~" (tachado/eliminado en 08)
```

---

## ORDEN PARA COMENZAR LA IMPLEMENTACIÓN

```
1. Actualizar JSOLUCIONES_DB_DIAGRAM.dbml (quitar multi-tenant)
2. Seguir 09_PROCESOS_DATABASE.md → Setup PostgreSQL + Docker
3. Seguir 07_PROCESOS_BACKEND.md → Proceso 1 (Django + empresa + usuario)
4. Seguir 07_PROCESOS_BACKEND.md → Proceso 2 (Auth + roles + permisos)
5. Verificar: migrate sin error, Swagger en /api/docs/, login funciona
6. Continuar con Proceso 3 (Inventario)...
```