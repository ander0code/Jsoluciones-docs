# JSOLUCIONES ERP — REGLAS DEL AGENTE / DESARROLLADOR

> Este archivo es OBLIGATORIO de leer antes de ejecutar cualquier acción en el proyecto.
> Aplica a cualquier agente de IA o desarrollador que trabaje en el código.
> Estas reglas protegen la integridad del proyecto y evitan errores costosos.

---

## 1. REGLAS ABSOLUTAS (NO NEGOCIABLES)

```
AGENTE-01: NUNCA inventar funcionalidades que no estén en el documento del proyecto.
           Si no está en el PDF o no lo pidió el usuario, NO se implementa.

AGENTE-02: NUNCA cambiar el stack tecnológico definido.
           Django, DRF, PostgreSQL, React, Tailwick, Nubefact, Celery, Redis.
           Estos NO se discuten ni se cambian.

AGENTE-03: Si hay ambigüedad, PREGUNTAR al usuario antes de implementar.
           NUNCA asumir. NUNCA "interpretar" lo que el usuario quiso decir.

AGENTE-04: NUNCA tocar el frontend a menos que el usuario lo solicite explícitamente.
           Si el usuario pide algo de backend, se trabaja SOLO en backend.

AGENTE-05: NUNCA alterar la estructura de la DB existente sin autorización.
           Si se necesita un cambio, se DESCRIBE primero y se espera aprobación.

AGENTE-06: Seguir siempre la prioridad de módulos definida en 01_CORE_PROYECTO.md.
           No saltar a módulos posteriores sin completar los anteriores.

AGENTE-07: Cada cambio debe ser incremental y verificable.
           NO hacer refactors masivos sin autorización.

AGENTE-08: Documentar todo endpoint creado (docstring mínimo).

AGENTE-09: Respetar nomenclatura:
           - Español para modelos y campos de negocio
           - Inglés para métodos técnicos y variables

AGENTE-10: NUNCA asumir que algo "ya funciona". Verificar ejecutando o leyendo el código.
```

---

## 2. PROTOCOLO DE TRABAJO

### 2.1 Antes de escribir código

```
1. Leer el archivo de reglas correspondiente:
   - ¿Voy a tocar backend? → Leer 02_REGLAS_BACKEND.md
   - ¿Voy a tocar la DB?   → Leer 03_REGLAS_BASE_DATOS.md
   - ¿Voy a tocar el front? → Leer 04_REGLAS_FRONTEND.md

2. Verificar en qué prioridad/sprint está el módulo que voy a tocar.
   Si no es la prioridad actual, PREGUNTAR al usuario.

3. Verificar que no existe ya algo similar implementado.
   NUNCA duplicar lógica.
```

### 2.2 Durante el desarrollo

```
1. Trabajar en UNA cosa a la vez.
   NUNCA modificar múltiples módulos en paralelo sin autorización.

2. Si encuentro un bug o inconsistencia:
   - Informar al usuario ANTES de arreglarlo.
   - NO corregir "de paso" cosas que no se pidieron.

3. Si necesito instalar un paquete nuevo:
    - Verificar compatibilidad con el stack actual.
   - Informar al usuario qué se va a instalar y por qué.
   - NUNCA instalar sin decir.
```

### 2.3 Después de escribir código

```
1. Verificar que los archivos estén en la ubicación correcta.
2. Verificar que se respetan los patrones (services.py, no lógica en views, etc.).
3. Si se creó una migración, NO aplicarla sin informar al usuario.
4. Mostrar un resumen de lo que se hizo.
```

---

## 3. LO QUE EL AGENTE PUEDE HACER SIN PEDIR PERMISO

| Acción | Permitido |
|--------|-----------|
| Crear archivos nuevos (services.py, views.py, etc.) | ✅ Sí |
| Agregar campos con default a modelos | ✅ Sí (informar) |
| Crear migraciones | ✅ Sí (informar) |
| Instalar paquetes del requirements existente | ✅ Sí |
| Escribir tests | ✅ Sí |
| Agregar logs/documentación | ✅ Sí |
| Crear endpoints nuevos para el módulo en curso | ✅ Sí |
| Corregir errores de sintaxis obvios | ✅ Sí |

---

## 4. LO QUE EL AGENTE DEBE PEDIR PERMISO SIEMPRE

| Acción | Requiere permiso |
|--------|-----------------|
| Modificar un modelo existente (agregar/quitar campos) | ⚠️ SIEMPRE pedir permiso |
| Renombrar campos o tablas | ⚠️ SIEMPRE pedir permiso |
| Eliminar código existente | ⚠️ SIEMPRE pedir permiso |
| Instalar paquetes nuevos no listados en requirements | ⚠️ SIEMPRE pedir permiso |
| Cambiar la estructura de carpetas | ⚠️ SIEMPRE pedir permiso |
| Modificar settings.py (cualquier sección) | ⚠️ SIEMPRE pedir permiso |
| Tocar el frontend cuando se pidió solo backend | ⚠️ SIEMPRE pedir permiso |
| Saltar de prioridad/sprint | ⚠️ SIEMPRE pedir permiso |
| Refactorizar código que ya funciona | ⚠️ SIEMPRE pedir permiso |
| Modificar componentes de Tailwick | ⚠️ SIEMPRE pedir permiso |

---

## 5. LO QUE EL AGENTE NUNCA DEBE HACER

| Acción | PROHIBIDO |
|--------|-----------|
| DROP TABLE, DROP COLUMN | ❌ PROHIBIDO |
| Eliminar migraciones | ❌ PROHIBIDO |
| Borrar registros contables/fiscales de la DB | ❌ PROHIBIDO |
| Cambiar el stack (Django, React, PostgreSQL, etc.) | ❌ PROHIBIDO |
| Inventar funcionalidades no solicitadas | ❌ PROHIBIDO |
| Hardcodear contraseñas, tokens o secretos | ❌ PROHIBIDO |
| Usar print() en vez de logging | ❌ PROHIBIDO |
| Poner lógica de negocio en views o serializers | ❌ PROHIBIDO |
| Usar FloatField para dinero | ❌ PROHIBIDO |
| Crear raw SQL sin justificación documentada | ❌ PROHIBIDO |
| Modificar componentes base de Tailwick | ❌ PROHIBIDO |
| Guardar access token JWT en localStorage | ❌ PROHIBIDO |

---

## 6. FORMATO DE COMUNICACIÓN CON EL USUARIO

### Cuando propongo un cambio:

```
📋 PROPUESTA DE CAMBIO
─────────────────────
Módulo: [nombre del módulo]
Archivo: [ruta del archivo]
Tipo: [nuevo archivo / modificación / migración]
Descripción: [qué se va a hacer y por qué]
Impacto: [qué otros módulos o archivos se ven afectados]
¿Requiere migración?: [Sí/No]

¿Procedo?
```

### Cuando termino una tarea:

```
✅ COMPLETADO
─────────────
Módulo: [nombre]
Archivos creados/modificados:
  - [ruta]: [descripción breve]
  - [ruta]: [descripción breve]
Endpoints nuevos:
  - [método] [url]: [descripción]
Pendiente:
  - [lo que falta, si aplica]
Notas:
  - [observaciones importantes]
```

### Cuando detecto un problema:

```
⚠️ PROBLEMA DETECTADO
────────────────────
Ubicación: [archivo y línea]
Descripción: [qué está mal]
Impacto: [qué puede pasar si no se corrige]
Propuesta: [cómo sugiero solucionarlo]
Riesgo: [bajo / medio / alto]

¿Quieres que lo corrija?
```

---

## 7. REFERENCIA RÁPIDA DE ARCHIVOS DE REGLAS

| Archivo | Contenido | Cuándo consultarlo |
|---------|-----------|-------------------|
| `01_CORE_PROYECTO.md` | Stack, arquitectura, prioridades, meta del 50% | Siempre al inicio |
| `02_REGLAS_BACKEND.md` | Django, DRF, services pattern | Al trabajar en backend |
| `03_REGLAS_BASE_DATOS.md` | Modelos, campos, migraciones, protecciones | Al tocar la DB |
| `04_REGLAS_FRONTEND.md` | React, Tailwick, responsive, PWA, servicios API | Al trabajar en frontend |
| `05_REGLAS_AGENTE.md` | Este archivo — protocolo de trabajo | Siempre |
| `06_CONSTANTES_COMPARTIDAS.md` | Choices, mixins, formato API | Al escribir código |
