# COMANDOS CLAVE — JSoluciones ERP

> Guía rápida de comandos para compilar, ejecutar y depurar el proyecto.

---

## BACKEND (Django)

### Ubicación
```bash
cd /Users/joshsaune/Proyectos-J/J-soluciones/Jsoluciones-be
```

### Activar entorno virtual
```bash
source .venv/bin/activate
```

### Servidor de desarrollo
```bash
python manage.py runserver
# Servidor corre en: http://127.0.0.1:8000
```

### Verificar integridad del código
```bash
# Check general de Django
python manage.py check

# Verificar migraciones pendientes
python manage.py showmigrations

# Crear migraciones
python manage.py makemigrations

# Crear migraciones para app específica
python manage.py makemigrations <app_name>

# Aplicar migraciones
python manage.py migrate

# Aplicar migraciones de app específica
python manage.py migrate <app_name>
```

### Generar OpenAPI Schema (para Orval)
```bash
python manage.py spectacular --file ../Jsoluciones-fe/openapi-schema.yaml
```

### Shell interactiva
```bash
# Shell de Django
python manage.py shell

# Shell con IPython (si está instalado)
python manage.py shell_plus
```

### Crear superusuario
```bash
python manage.py createsuperuser
```

### Tests
```bash
# Correr todos los tests
python manage.py test

# Correr tests de una app
python manage.py test apps.ventas

# Correr con coverage
coverage run --source='.' manage.py test
coverage report
```

### Celery (tareas asíncronas)
```bash
# Iniciar worker
celery -A config worker -l info

# Iniciar beat (scheduler)
celery -A config beat -l info

# Iniciar ambos
celery -A config worker -B -l info
```

### Linting y formateo
```bash
# Ruff (linter)
ruff check .

# Ruff formatear
ruff format .

# Verificar sin cambiar
ruff check . --diff
```

### Base de datos
```bash
# Entrar a PostgreSQL
psql -U postgres -d jsoluciones

# Dump de base de datos
pg_dump -U postgres jsoluciones > backup.sql

# Restaurar
psql -U postgres jsoluciones < backup.sql
```

### Limpiar cache
```bash
# Limpiar archivos .pyc
find . -type d -name "__pycache__" -exec rm -r {} +

# Limpiar migraciones (cuidado!)
# python manage.py migrate --fake <app> zero
```

---

## FRONTEND (React + Vite)

### Ubicación
```bash
cd /Users/joshsaune/Proyectos-J/J-soluciones/Jsoluciones-fe
```

### Instalar dependencias
```bash
pnpm install
```

### Servidor de desarrollo
```bash
pnpm dev
# Servidor corre en: http://localhost:5173
```

### Compilar para producción
```bash
pnpm build
```

### Preview de producción
```bash
pnpm preview
```

### Generar tipos desde OpenAPI (Orval)
```bash
pnpm orval --config orval.config.ts
```

### Linting
```bash
# Verificar errores
pnpm lint

# Arreglar automáticamente
pnpm lint --fix
```

### Formatear código
```bash
# Prettier
pnpm format

# Verificar sin cambiar
pnpm format:check
```

### Type checking
```bash
# TypeScript
pnpm typecheck

# O con tsc directamente
npx tsc --noEmit
```

### Limpiar
```bash
# Eliminar node_modules
rm -rf node_modules

# Eliminar build
rm -rf dist

# Reinstalar todo
rm -rf node_modules && pnpm install
```

---

## FLUJO COMPLETO: Backend → Frontend

### 1. Hacer cambios en el backend
```bash
# En Jsoluciones-be/
source .venv/bin/activate
python manage.py makemigrations
python manage.py migrate
python manage.py check
```

### 2. Regenerar OpenAPI Schema
```bash
# En Jsoluciones-be/
python manage.py spectacular --file ../Jsoluciones-fe/openapi-schema.yaml
```

### 3. Generar tipos TypeScript
```bash
# En Jsoluciones-fe/
pnpm orval --config orval.config.ts
```

### 4. Verificar frontend
```bash
# En Jsoluciones-fe/
pnpm typecheck
pnpm lint
pnpm build
```

### 5. Probar en desarrollo
```bash
# Terminal 1 - Backend
cd Jsoluciones-be && source .venv/bin/activate && python manage.py runserver

# Terminal 2 - Frontend
cd Jsoluciones-fe && pnpm dev
```

---

## URLs IMPORTANTES

| Servicio | URL |
|----------|-----|
| Backend API | http://127.0.0.1:8000/api/v1/ |
| Admin Django | http://127.0.0.1:8000/admin/ |
| OpenAPI Schema | http://127.0.0.1:8000/api/schema/ |
| Swagger UI | http://127.0.0.1:8000/api/docs/ |
| Frontend Dev | http://localhost:5173/ |

---

## COMANDOS RÁPIDOS

### Verificar todo el backend
```bash
source .venv/bin/activate && python manage.py check && python manage.py test
```

### Verificar todo el frontend
```bash
pnpm typecheck && pnpm lint && pnpm build
```

### Regenerar y compilar todo
```bash
# Backend
cd Jsoluciones-be
source .venv/bin/activate
python manage.py spectacular --file ../Jsoluciones-fe/openapi-schema.yaml

# Frontend
cd ../Jsoluciones-fe
pnpm orval --config orval.config.ts
pnpm build
```

---

## DEPURACIÓN

### Backend - Ver logs
```bash
# Logs en consola (desarrollo)
python manage.py runserver --verbosity=2

# Ver consultas SQL
python manage.py shell
>>> from django.db import connection
>>> connection.queries
```

### Backend - Debug con pdb
```python
# En el código
import pdb; pdb.set_trace()

# O con ipdb (más cómodo)
import ipdb; ipdb.set_trace()
```

### Frontend - React DevTools
Instalar extensión React Developer Tools en el navegador.

### Frontend - Ver errores de compilación
```bash
pnpm build 2>&1 | head -50
```

---

## PROBLEMAS COMUNES

### "Module not found"
```bash
# Backend
source .venv/bin/activate
uv pip install <paquete>

# Frontend
pnpm add <paquete>
```

### "Migration conflict"
```bash
python manage.py showmigrations
python manage.py migrate --fake <app> <migration_number>
python manage.py migrate
```

### "Port already in use"
```bash
# Backend
lsof -i :8000
kill -9 <PID>

# Frontend
lsof -i :5173
kill -9 <PID>
```

### "Node modules corrupt"
```bash
rm -rf node_modules pnpm-lock.yaml
pnpm install
```
