Resumen de Contexto - JSoluciones ERP
> Fecha: 25 Feb 2026
> Versión: 1.0
> Estado: En desarrollo
---
✅ Trabajos Realizados (Esta Sesión)
1. Fix Bug - Portal Conductor No Muestra Pedidos
Problema: Los pedidos creados desde el POS no aparecían en el portal del conductor.
Causa raíz: El PortalConductorView en backend filtraba por fecha_pedido=fecha, pero este campo es NULL cuando se crea un pedido desde el POS. El campo que siempre tiene valor es fecha.
Solución aplicada:
| Archivo | Línea | Cambio |
|---------|-------|--------|
| Jsoluciones-be/apps/distribucion/views.py | 865 | .filter(fecha_pedido=fecha) → .filter(fecha=fecha) |
---
2. Estados Nuevos para Portal Conductor
Propósito: El conductor puede confirmar entregas con diferentes estados (no solo "entregado").
Backend - Serializer:
| Archivo | Línea | Descripción |
|---------|-------|-------------|
| Jsoluciones-be/apps/distribucion/serializers.py | 331-342 | Agregado campo estado con choices: entregado, reprogramado, no_entregado, cancelado |
Backend - Vista:
| Archivo | Línea | Descripción |
|---------|-------|-------------|
| Jsoluciones-be/apps/distribucion/views.py | 880-940 | PortalConfirmarEntregaView ahora maneja los 4 estados |
Base de datos - ENUM PostgreSQL:
-- Enum existente en SQL_JSOLUCIONES.sql (líneas 132-135)
CREATE TYPE enum_estado_pedido AS ENUM (
    'pendiente','confirmado','despachado','en_ruta',
    'entregado','cancelado','devuelto'
);
Valores agregados en PostgreSQL (línea de comandos):
ALTER TYPE enum_estado_pedido ADD VALUE IF NOT EXISTS 'reprogramado';
ALTER TYPE enum_estado_pedido ADD VALUE IF NOT EXISTS 'no_entregado';
---
3. Portal Conductor - 3 Gaps Implementados
Gap #1: Más estados al confirmar entrega
Ubicación: Jsoluciones-fe/src/app/(public)/portal-conductor/index.tsx
| Línea(s) | Descripción |
|----------|-------------|
| 45-54 | Nuevos iconos: LuOctagon, LuRefreshCw, LuTrash2 |
| 45-53 | Configuración de estados: no_entregado, reprogramado agregados |
| 170-190 | Botones de acción: 4 botones en grid (Entregado, Reprogramar, No Entregado, Cancelar) |
Vista previa:
- Verde → Entregado ✓
- Cyan → Reprogramar ⟳
- Naranja → No Entregado ⊘
- Rojo → Cancelar ✕
Gap #2: Auto-GPS cada 30 segundos
Ubicación: Jsoluciones-fe/src/app/(public)/portal-conductor/index.tsx
| Línea(s) | Descripción |
|----------|-------------|
| 386 | Estado autoGpsEnabled |
| 403-427 | Función sendLocation() - envía coordenadas cada 30s |
| 429-436 | useEffect para auto-actualizar GPS |
| 448-455 | Toggle button en header para activar/desactivar |
Comportamiento:
- Toggle "GPS" → Activa modo automático
- Envía ubicación cada 30 segundos
- Solo envía si el navegador tiene GPS disponible
Gap #3: Botón Waze
Ubicación: Jsoluciones-fe/src/app/(public)/portal-conductor/index.tsx
| Línea(s) | Descripción |
|----------|-------------|
| 110-128 | Función getWazeUrl() - extrae coordenadas de Google Maps |
| 173-180 | Botón Waze con color #33ccff |
Lógica de extracción de coordenadas:
// Patrones regex para extraer coordenadas
/@(-?\d+\.?\d*),(-?\d+\.?\d*)/,
/[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)/,
/[?&]ll=(-?\d+\.?\d*),(-?\d+\.?\d*)/,
// Fallback: usar dirección
---
4. OpenAPI + Regeneración de Tipos
Comandos ejecutados:
# Backend: Generar schema
cd Jsoluciones-be
source .venv/bin/activate
python manage.py spectacular --file ../Jsoluciones-fe/openapi-schema.yaml
# Frontend: Regenerar tipos
cd Jsoluciones-fe
pnpm orval --config orval.config.ts
Archivos regenerados:
- Jsoluciones-fe/openapi-schema.yaml
- Jsoluciones-fe/src/api/generated/portal-conductor/portal-conductor.ts
- Jsoluciones-fe/src/api/models/portalConfirmarEntrega.ts
- Jsoluciones-fe/src/api/models/portalConfirmarEntregaEstadoEnum.ts
---
❌ Problema IDENTIFICADO (SIN RESOLVER)
Transportista es OPCIONAL en formulario de Delivery
Ubicación del formulario:
Jsoluciones-fe/src/app/(admin)/(app)/(ventas)/pedido-pos/components/DatosEntregaForm.tsx
| Línea | Contenido | Problema |
|-------|-----------|----------|
| 198 | Transportista (opcional) | Label dice opcional |
| 259 | Puede asignarse después si aún no se decide | Texto guía |
| 251 | <option value="">Sin asignar</option> | Valor por defecto |
Backend - Serializer de validación:
| Archivo | Línea | Descripción |
|---------|-------|-------------|
| Jsoluciones-be/apps/ventas/serializers.py | 606-619 | Campos obligatorios para delivery: direccion_entrega, fecha_entrega, turno_entrega, nombre_destinatario, telefono_destinatario |
| Jsoluciones-be/apps/ventas/serializers.py | 574 | transportista_id = serializers.UUIDField(required=False, allow_null=True) ← Es opcional |
Backend - Service de creación:
| Archivo | Línea | Descripción |
|---------|-------|-------------|
| Jsoluciones-be/apps/ventas/services.py | 1014 | "transportista_id": datos.get("transportista_id"), ← No es obligatorio |
| Jsoluciones-be/apps/distribucion/services.py | 73-74 | transportista = None ← Puede ser null |
---
📋 Flujo Actual vs Flujo Esperado
Flujo ACTUAL (con bug):
1. POS → Crear venta con delivery
2. Formulario → Transportista = "Sin asignar" (opcional)
3. Crear pedido → Queda SIN transportista
4. Pedido NO aparece en portal del conductor
Flujo ESPERADO:
1. POS → Crear venta con delivery
2. Formulario → Transportista = OBLIGATORIO
3. Crear pedido → Ya tiene transportista asignado
4. Pedido APARECE en portal del conductor
---
📁 Archivos Modificados Esta Sesión
Backend
- Jsoluciones-be/apps/distribucion/views.py
- Jsoluciones-be/apps/distribucion/serializers.py
Frontend
- Jsoluciones-fe/src/app/(public)/portal-conductor/index.tsx
Base de datos
- PostgreSQL: enum_estado_pedido (agregados reprogramado, no_entregado)
---
✅ Verificaciones Realizadas
| Verificación | Resultado |
|--------------|-----------|
| python manage.py check | ✅ Sin errores |
| pnpm build (portal-conductor) | ✅ Compila |
| Enum PostgreSQL | ✅ Valores verificados |
---
⏳ Pendiente por Implementar
1. Hacer transportista obligatorio cuando es_delivery = true
   - Frontend: Editar DatosEntregaForm.tsx
   - Backend: Editar ventas/serializers.py
2. Probar flujo completo:
   - Crear pedido con delivery
   - Verificar que aparece en portal del conductor

---

## 📎 Requisitos del Sistema - Generación de Imágenes

### Ghostscript (Para conversión PDF → Imagen)

**Propósito**: Convertir comprobantes PDF a imágenes PNG/JPG para mostrarlos en el portal del conductor.

**Ubicación**: `/usr/bin/gs`

**Instalación** (Linux/Arch):
```bash
sudo pacman -S ghostscript
```

**Versión verificada**: 10.06.0

**Comando usado en el código**:
```python
subprocess.run([
    'gs',
    '-dNOPAUSE',
    '-dBATCH',
    '-sDEVICE=png16m',      # PNG color
    '-r150',                # 150 DPI
    '-sOutputFile={output_path}',
    '-f', pdf_path
])
```

**Formatos soportados**:
- PNG: `-sDEVICE=png16m`
- JPG: `-sDEVICE=jpeg`

**Parámetros**:
- `-dNOPAUSE`: No pausar entre páginas
- `-dBATCH`: Terminar al finalizar
- `-r150`: Resolución 150 DPI
- `-sOutputFile`: Ruta de salida

---

## 📋 Dependencias y Versiones

### Backend (Python)
- Django REST Framework
- PostgreSQL
- Ghostscript 10.06.0 (sistema)
- openpyxl (exports Excel)
- reportlab (generación PDF)
- WeasyPrint (PDF)
- Pillow (imágenes)

### Frontend (React + Vite)
- React 19
- TypeScript
- Tailwind CSS
- TanStack Query
- React Hot Toast
- React Router
- Lucide React (iconos)

### Infraestructura
- Node.js 20+
- pnpm
- PostgreSQL 16