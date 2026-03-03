# JSOLUCIONES ERP — REGLAS DEL AGENTE / DESARROLLADOR

> Leer antes de ejecutar cualquier accion en el proyecto.
> Aplica a cualquier agente de IA o desarrollador que trabaje en el codigo.

---

## 1. REGLAS ABSOLUTAS (NO NEGOCIABLES)

```
AGENTE-01: NUNCA inventar funcionalidades que no esten en el documento del proyecto.
           Si no se pidio explicitamente, NO se implementa.

AGENTE-02: NUNCA cambiar el stack tecnologico definido.
           Django, DRF, PostgreSQL, React, Tailwind, Nubefact, Celery, Redis.
           Ver context/OVERVIEW.md para el stack completo.

AGENTE-03: Si hay ambiguedad, PREGUNTAR al usuario antes de implementar.
           NUNCA asumir. NUNCA "interpretar" lo que el usuario quiso decir.

AGENTE-04: NUNCA tocar el frontend a menos que el usuario lo solicite explicitamente.
           Si el usuario pide algo de backend, se trabaja SOLO en backend.

AGENTE-05: NUNCA alterar la estructura de la DB existente sin autorizacion.
           Si se necesita un cambio, se DESCRIBE primero y se espera aprobacion.

AGENTE-06: Cada cambio debe ser incremental y verificable.
           NO hacer refactors masivos sin autorizacion.

AGENTE-07: Documentar todo endpoint creado (docstring minimo + @extend_schema).

AGENTE-08: Respetar nomenclatura:
           - Espanol para modelos y campos de negocio
           - Ingles para metodos tecnicos y variables internas

AGENTE-09: NUNCA asumir que algo "ya funciona". Verificar ejecutando o leyendo el codigo.

AGENTE-10: NUNCA trabajar en Amatista-be/ o Amatista-fe/ — son proyectos distintos (READ ONLY).
```

---

## 2. DONDE ENCONTRAR CONTEXTO

| Duda | Archivo a leer |
|------|----------------|
| Que es el proyecto, stack, repos | `context/OVERVIEW.md` |
| Que modulos existen y su estado | `context/MODULES.md` |
| Reglas de base de datos, enums | `context/DATABASE.md` |
| Servicios, Redis, Celery, Docker | `context/DEVOPS.md` |
| Reglas de backend Django/DRF | `rules/BACKEND.md` |
| Reglas de frontend React/TS | `rules/FRONTEND.md` |
| Comandos para correr y depurar | `rules/COMMANDS.md` |

---

## 3. PROTOCOLO DE TRABAJO

### Antes de escribir codigo

```
1. Identificar que se va a tocar: backend, frontend, o ambos.
2. Leer el archivo de reglas correspondiente (rules/BACKEND.md o rules/FRONTEND.md).
3. Verificar que no existe algo similar ya implementado. NUNCA duplicar logica.
4. Si el cambio toca la DB: describir al usuario y esperar aprobacion.
```

### Durante el desarrollo

```
1. Trabajar en UNA cosa a la vez.
   NUNCA modificar multiples modulos en paralelo sin autorizacion.

2. Si encuentro un bug o inconsistencia:
   - Informar al usuario ANTES de arreglarlo.
   - NO corregir "de paso" cosas que no se pidieron.

3. Si necesito instalar un paquete nuevo:
   - Verificar compatibilidad con el stack actual.
   - Informar al usuario que se va a instalar y por que.
   - NUNCA instalar sin avisar.
```

### Despues de escribir codigo

```
1. Verificar que los archivos esten en la ubicacion correcta.
2. Verificar que se respetan los patrones (services.py, no logica en views, etc.).
3. Si se creo una migracion, NO aplicarla sin informar al usuario.
4. Mostrar un resumen de lo que se hizo.
```

---

## 4. PERMISOS SIN PEDIR AUTORIZACION

| Accion | Permitido |
|--------|-----------|
| Crear archivos nuevos (services.py, views.py, etc.) | Si |
| Agregar campos con default a modelos | Si (informar) |
| Crear migraciones (no aplicar) | Si (informar) |
| Escribir tests | Si |
| Agregar logs / docstrings | Si |
| Crear endpoints nuevos para el modulo en curso | Si |
| Corregir errores de sintaxis obvios | Si |

---

## 5. REQUIERE PERMISO SIEMPRE

| Accion | Requiere permiso |
|--------|-----------------|
| Modificar un modelo existente (campos) | SIEMPRE |
| Renombrar campos o tablas | SIEMPRE |
| Eliminar codigo existente | SIEMPRE |
| Instalar paquetes nuevos | SIEMPRE |
| Cambiar la estructura de carpetas | SIEMPRE |
| Modificar settings.py | SIEMPRE |
| Tocar frontend cuando se pidio solo backend | SIEMPRE |
| Refactorizar codigo que ya funciona | SIEMPRE |
| Aplicar migraciones | SIEMPRE (informar antes) |

---

## 6. PROHIBIDO ABSOLUTAMENTE

| Accion | PROHIBIDO |
|--------|-----------|
| DROP TABLE, DROP COLUMN | PROHIBIDO |
| Eliminar migraciones | PROHIBIDO |
| Borrar registros contables/fiscales de la DB | PROHIBIDO |
| Cambiar el stack (Django, React, PostgreSQL, etc.) | PROHIBIDO |
| Inventar funcionalidades no solicitadas | PROHIBIDO |
| Hardcodear contrasenas, tokens o secretos | PROHIBIDO |
| Usar print() en vez de logging | PROHIBIDO |
| Poner logica de negocio en views o serializers | PROHIBIDO |
| Usar FloatField para dinero | PROHIBIDO |
| Crear raw SQL sin justificacion documentada | PROHIBIDO |
| Guardar access token JWT en localStorage | PROHIBIDO |
| Tocar Amatista-be/ o Amatista-fe/ | PROHIBIDO |

---

## 7. FORMATO DE COMUNICACION

### Cuando propongo un cambio:

```
PROPUESTA DE CAMBIO
-------------------
Modulo: [nombre]
Archivo: [ruta]
Tipo: [nuevo / modificacion / migracion]
Descripcion: [que se va a hacer y por que]
Impacto: [que otros modulos se ven afectados]
Requiere migracion: [Si/No]

Procedo?
```

### Cuando termino una tarea:

```
COMPLETADO
----------
Modulo: [nombre]
Archivos creados/modificados:
  - [ruta]: [descripcion breve]
Endpoints nuevos:
  - [metodo] [url]: [descripcion]
Pendiente:
  - [lo que falta, si aplica]
```

### Cuando detecto un problema:

```
PROBLEMA DETECTADO
------------------
Ubicacion: [archivo:linea]
Descripcion: [que esta mal]
Impacto: [que puede pasar si no se corrige]
Propuesta: [como sugiero solucionarlo]
Riesgo: [bajo / medio / alto]

Quieres que lo corrija?
```
