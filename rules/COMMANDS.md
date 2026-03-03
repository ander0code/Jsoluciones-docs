# COMANDOS CLAVE — JSoluciones ERP

> Guia rapida de comandos para compilar, ejecutar y depurar el proyecto.
> Paths absolutos del proyecto en desarrollo local.

---

## BACKEND (Django)

### Ubicacion y entorno

```bash
cd /Users/joshsaune/Proyectos-J/J-soluciones/Jsoluciones-be
source .venv/bin/activate
```

### Servidor de desarrollo

```bash
python manage.py runserver
# Corre en: http://127.0.0.1:8000
```

### Verificar integridad

```bash
python manage.py check
python manage.py showmigrations
```

### Migraciones

```bash
python manage.py makemigrations
python manage.py makemigrations <app_name>
python manage.py migrate
python manage.py migrate <app_name>
```

### Management commands del proyecto

```bash
python manage.py seed_permissions    # Crear 8 roles + 40+ permisos
python manage.py setup_empresa       # Crear empresa + admin (interactivo)
python manage.py reset_password      # Resetear password de usuario
python manage.py fix_perfil          # Reparar perfil de usuario
```

### Generar OpenAPI Schema (para Orval)

```bash
# Siempre desde Jsoluciones-be/
python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml
```

### Shell interactiva

```bash
python manage.py shell
python manage.py shell_plus   # Con IPython si esta instalado
```

### Tests

```bash
pytest tests/                      # Todos los tests
pytest tests/test_ventas_services.py   # Test especifico
coverage run --source='.' -m pytest tests/
coverage report
```

### Celery

```bash
celery -A config worker -l info
celery -A config beat -l info
celery -A config worker -B -l info   # Worker + Beat juntos
```

### Iniciar Redis (valkey en dev)

```bash
sudo systemctl start valkey
sudo systemctl status valkey
```

### Linting y formateo

```bash
ruff check .
ruff format .
ruff check . --diff   # Ver sin cambiar
```

### Base de datos

```bash
psql -U postgres -d jsoluciones
pg_dump -U postgres jsoluciones > backup.sql
psql -U postgres jsoluciones < backup.sql
```

---

## FRONTEND (React + Vite)

### Ubicacion

```bash
cd /Users/joshsaune/Proyectos-J/J-soluciones/Jsoluciones-fe
```

### Servidor de desarrollo

```bash
pnpm dev
# Corre en: http://localhost:5173
```

### Instalar dependencias

```bash
pnpm install
```

### Compilar para produccion

```bash
pnpm build
pnpm preview   # Preview del build
```

### Generar tipos desde OpenAPI (Orval)

```bash
pnpm orval --config orval.config.ts
# o simplemente:
pnpm orval
```

### Type checking y linting

```bash
pnpm typecheck      # tsc --noEmit
pnpm lint           # ESLint
pnpm lint --fix
pnpm format         # Prettier
pnpm format:check
```

### Tests

```bash
pnpm test
pnpm test:watch
pnpm test:coverage
```

### Limpiar

```bash
rm -rf node_modules pnpm-lock.yaml && pnpm install
rm -rf dist
```

---

## FLUJO COMPLETO: Cambio en BE -> Actualizar FE

```bash
# 1. En Jsoluciones-be/ — hacer cambios, migrar, verificar
source .venv/bin/activate
python manage.py makemigrations && python manage.py migrate
python manage.py check

# 2. Regenerar OpenAPI schema
python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml

# 3. En Jsoluciones-fe/ — regenerar hooks y tipos
pnpm orval

# 4. Verificar que el frontend compila
pnpm typecheck
pnpm build
```

---

## URLs DE DESARROLLO

| Servicio | URL |
|----------|-----|
| Backend API | http://127.0.0.1:8000/api/v1/ |
| Admin Django | http://127.0.0.1:8000/admin/ |
| OpenAPI Schema | http://127.0.0.1:8000/api/schema/ |
| Swagger UI | http://127.0.0.1:8000/api/docs/ |
| Frontend Dev | http://localhost:5173/ |
| Flower (Celery) | http://localhost:5555/ |

---

## COMANDOS RAPIDOS

```bash
# Verificar todo el backend
source .venv/bin/activate && python manage.py check && pytest tests/

# Verificar todo el frontend
pnpm typecheck && pnpm lint && pnpm build

# Regenerar todo (schema + tipos TS)
cd Jsoluciones-be && source .venv/bin/activate && python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml && cd ../Jsoluciones-fe && pnpm orval && pnpm typecheck
```

---

## DEPURACION

### Backend — ver logs

```bash
python manage.py runserver --verbosity=2

# Ver queries SQL en shell
python manage.py shell
>>> from django.db import connection
>>> connection.queries
```

### Backend — pdb

```python
import pdb; pdb.set_trace()
# o con ipdb
import ipdb; ipdb.set_trace()
```

### Frontend — errores de compilacion

```bash
pnpm build 2>&1 | head -50
```

### Frontend — React DevTools

Instalar extension React Developer Tools en el navegador.

---

## PROBLEMAS COMUNES

### "Module not found" en backend

```bash
source .venv/bin/activate
uv pip install <paquete>
```

### "Migration conflict"

```bash
python manage.py showmigrations
python manage.py migrate --fake <app> <migration_number>
python manage.py migrate
```

### "Port already in use"

```bash
lsof -i :8000 && kill -9 <PID>   # Backend
lsof -i :5173 && kill -9 <PID>   # Frontend
```

### "Orval genera tipos incorrectos"

El problema esta en el backend, no en Orval.
Corregir el serializer o el @extend_schema en el ViewSet, luego regenerar:

```bash
python manage.py spectacular --color --file ../Jsoluciones-fe/openapi-schema.yaml
cd ../Jsoluciones-fe && pnpm orval
```

### Redis no conecta en dev

```bash
sudo systemctl start valkey
# Los tests no necesitan Redis — usan config/settings/testing.py con LocMemCache
```

### Tests fallan por migraciones pendientes

```bash
python manage.py showmigrations | grep "\[ \]"
python manage.py migrate
pytest tests/
```
