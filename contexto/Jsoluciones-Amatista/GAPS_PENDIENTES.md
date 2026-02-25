# GAPS PENDIENTES — JSoluciones vs Amatista

> Fecha: 2026-02-25
> Fuente: Análisis exhaustivo de todo el código de Laravel-Amatista
> Objetivo: Lista priorizada de qué implementar en JSoluciones para paridad operativa con Amatista

---

## PRIORIDAD CRÍTICA (bloqueantes para el negocio)

### 1. Export Excel de Pedidos/Ventas
**¿Por qué?** El equipo lo usa diariamente para planificar entregas, hacer seguimiento por conductor, y reportar a dirección. Es la funcionalidad más pedida del día a día.

**Lo que hace Amatista:**
- `GET /exportar-excel?fecha=YYYY-MM-DD&periodo=semana|mes`
- Genera `.xlsx` con 20 columnas (ver EXPORTS_Y_PDF.md)
- Header estilizado (negrita, color fucsia, fondo rosado)
- Anchos de columna individuales
- Nombre de archivo: `pedidos_semana_01-02_07-02-2026.xlsx` o `pedidos_febrero_2026.xlsx`

**JSoluciones actual:** Solo existe un stub/task sin lógica real

**Qué implementar:**
```
Backend Django (apps/ventas/views.py o apps/distribucion/views.py):
  - Endpoint: GET /api/v1/ventas/export/?fecha_desde=&fecha_hasta=&periodo=semana|mes
  - Librería: openpyxl (instalar en requirements.txt)
  - Columnas JSoluciones: # | N° Venta | Fecha | Cliente | Documento | Vendedor |
    Tipo Venta | Método Pago | Subtotal | IGV | Descuento | Total | Estado |
    Caja | Productos (texto) | Comprobante | Creado
  - StreamingHttpResponse con Content-Type: application/vnd.openxmlformats...

Frontend (nueva opción en la UI):
  - Botón "Exportar Excel" con dropdown semana/mes en la lista de ventas/pedidos
```

**Dependencias a instalar:**
```
openpyxl>=3.1.0
```

**Dificultad:** Baja — solo Python, no requiere dependencias de sistema

---

### 2. PDF de Entrega (para meter en el paquete físico)
**¿Por qué?** Se imprime y mete físicamente en cada paquete de flores/regalo. El cliente lo recibe con su pedido.

**Lo que hace Amatista:**
- `GET /{id}/pdf` → descarga `entrega_{id}.pdf`
- Tamaño: **15.5cm × 21cm** (más pequeño que A4, cabe en caja de flores)
- Contenido: Nombre empresa + N° pedido grande + datos entrega + dedicatoria + productos con imagen
- Imágenes de productos: se descargan de DigitalOcean Spaces → base64 embebido

**JSoluciones actual:** No existe nada — solo PDFs de Nubefact (comprobantes SUNAT)

**Qué implementar:**
```
Backend (apps/distribucion/views.py o apps/ventas/views.py):
  - GET /api/v1/distribucion/pedidos/{id}/pdf-entrega/
  - Librería: WeasyPrint o reportlab
  - Template HTML con CSS inline
  - Imágenes: presigned URL de R2 → requests.get() → base64.b64encode()
  - Response: application/pdf con Content-Disposition: attachment

Tamaño papel: 439pt × 595pt (15.5cm × 21cm en puntos)
```

**Dependencias a instalar:**
```
weasyprint>=60.0
# O alternativamente:
# reportlab>=4.0
```

**Dificultad:** Media — WeasyPrint requiere libcairo en el servidor

---

### 3. PDF Interno (documento administrativo A4)
**¿Por qué?** Uso interno de la empresa — queda archivado, sirve para reconciliar con conductores y para disputas.

**Lo que hace Amatista:**
- `GET /{id}/pdf-interno` → descarga `pedido_{id}_interno.pdf`
- Tamaño: A4 (21cm × 29.7cm)
- Contenido adicional vs PDF de entrega: cliente, método de pago, montos desglosados (subtotal + delivery + total), quién registró, conductor asignado

**Qué implementar:**
```
GET /api/v1/distribucion/pedidos/{id}/pdf-interno/
Misma librería que PDF de entrega, template diferente
```

**Dificultad:** Baja una vez tengas WeasyPrint instalado (mismo setup)

---

## PRIORIDAD ALTA (impacto operacional importante)

### 4. PDF → Imagen PNG/JPG (para WhatsApp)
**¿Por qué?** El equipo manda el PDF de entrega al cliente por WhatsApp. Un PNG/JPG se visualiza directamente en el chat sin que el cliente tenga que abrir un PDF.

**Lo que hace Amatista:**
- `GET /{id}/imagen-entrega/{png|jpg}` y `/{id}/imagen-interno/{png|jpg}`
- Usa Ghostscript: `gs -dBATCH -dNOPAUSE -sDEVICE=png16m -r150 ...`
- 150 DPI con anti-aliasing
- Ghostscript via `subprocess` en Python (equivalente a `exec()` de PHP)

**JSoluciones actual:** No existe

**Qué implementar:**
```python
# Opción A — Ghostscript directo (igual que Amatista)
import subprocess, tempfile, os
def pdf_to_image(pdf_bytes: bytes, fmt: str = 'png') -> bytes:
    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as f:
        f.write(pdf_bytes)
        pdf_path = f.name
    img_path = pdf_path.replace('.pdf', f'.{fmt}')
    device = 'png16m' if fmt == 'png' else 'jpeg'
    subprocess.run([
        'gs', '-dBATCH', '-dNOPAUSE', '-dSAFER',
        f'-sDEVICE={device}', '-r150',
        '-dTextAlphaBits=4', '-dGraphicsAlphaBits=4',
        f'-sOutputFile={img_path}', pdf_path
    ], check=True)
    os.unlink(pdf_path)
    with open(img_path, 'rb') as f:
        data = f.read()
    os.unlink(img_path)
    return data

# Opción B — pdf2image (wrapper Pythonic de Ghostscript/Poppler)
from pdf2image import convert_from_bytes
images = convert_from_bytes(pdf_bytes, dpi=150)
# images[0].save(buffer, format='PNG')
```

**Dependencias:**
```
# Opción A: solo ghostscript instalado en el servidor (apt install ghostscript)
# Opción B:
pdf2image>=1.16.0
# + apt install poppler-utils en el servidor
```

**Dificultad:** Media — requiere dependencia de sistema (Ghostscript o Poppler)

---

### 5. Filtros avanzados en lista de pedidos/ventas
**¿Por qué?** Amatista tiene 11 filtros simultáneos. JSoluciones solo busqueda y estado.

**Filtros que faltan en JSoluciones:**
- Distrito de entrega (multi-select con "Marcar todos")
- Turno (Mañana / Tarde)
- Tipo de ubicación (Casa / Oficina)
- Método de pago
- Buscar por nombre de cliente (separado del general)
- Buscar por nombre de destinatario
- Filtrar por producto específico
- Filtrar por conductor / "Sin asignar"
- Filtrar por estado de producción

**Dificultad:** Media (backend: query params en viewset; frontend: más controles en la UI)

---

### 6. Resumen de productos con filtros activos
**¿Por qué?** Cuando el equipo de producción filtra por fecha, ve cuántas unidades de cada producto necesitan preparar.

**Lo que hace Amatista:** Cuando hay filtros activos Y hay resultados, muestra cards con imagen del producto + badge de cantidad total + progreso `listo / total`.

**Dificultad:** Media — requiere query de agregación en el backend

---

## PRIORIDAD MEDIA (mejoras de experiencia)

### 7. Auto-refresh de la lista de pedidos
**Lo que hace Amatista:** Recarga la página cada 60 segundos si el usuario lleva 30+ segundos sin interactuar. Evita que el equipo tenga listas desactualizadas sin tener que hacer F5.

**Implementación en JSoluciones (frontend):**
```typescript
// En el componente de lista, useEffect con setInterval
let lastInteraction = Date.now()
const events = ['click', 'keydown', 'scroll', 'mousemove']
events.forEach(e => window.addEventListener(e, () => { lastInteraction = Date.now() }))
setInterval(() => {
  if (Date.now() - lastInteraction > 30000) {
    refetch() // React Query
  }
}, 60000)
```

**Dificultad:** Baja

---

### 8. Filtros persistidos en sesión/localStorage
**Lo que hace Amatista:** Cuando sales de la lista y vuelves, los filtros se restauran automáticamente desde la sesión.

**Implementación en JSoluciones:** Usar `localStorage` o `sessionStorage` para guardar los query params activos.

**Dificultad:** Baja

---

### 9. Cambio de estado desde la lista (sin entrar al detalle)
**Lo que hace Amatista:** Un dropdown en cada fila de la lista permite cambiar el estado del pedido directamente. Solo disponible para admin.

**Dificultad:** Media (el endpoint ya existe, falta el dropdown en la UI)

---

### 10. Botones de PDF/imagen desde la lista
**Lo que hace Amatista:** Dropdown con 6 opciones por pedido (PDF entrega, PNG entrega, JPG entrega, PDF interno, PNG interno, JPG interno) directamente en la tabla.

**Dificultad:** Baja una vez los endpoints de PDF existan

---

## PRIORIDAD BAJA (funcionalidades avanzadas)

### 11. Portal del conductor (acceso por token sin login)
**Lo que hace Amatista:**
- URL única por conductor: `/conductor/{token}`
- Ve sus entregas asignadas para el día
- Puede actualizar su ubicación GPS cada 30s
- Confirma entregas con foto (opcional) + observación + estado
- Sin login, sin JWT — solo el token UUID del conductor

**JSoluciones actual:** No existe. El modelo `EvidenciaEntrega` es más robusto pero requiere JWT.

**Implementación sugerida:**
```
GET /api/v1/conductor/portal/{token}/ — lista entregas del conductor
POST /api/v1/conductor/portal/{token}/location/ — actualiza GPS
POST /api/v1/conductor/portal/{token}/entregas/{id}/confirmar/ — confirma con foto
```
Con throttling (django-ratelimit) y sin autenticación JWT.

**Dificultad:** Alta

---

### 12. Módulo de Producción (Kanban pendiente→armando→listo)
**Lo que hace Amatista:**
- Vista Kanban con 3 columnas
- Timestamps de cuándo empezó y terminó de armarse
- Flag urgente automático (>30min o pedido temprano del día)
- Resumen de materiales necesarios (suma productos pendientes, excluye adicionales como chocolates)
- Acceso por rol `produccion` (no solo admin)

**JSoluciones actual:** No existe concepto de producción.

**Dificultad:** Alta — requiere nuevo modelo, endpoints, UI completa, y nuevo rol

---

### 13. Mapa de entregas
**Lo que hace Amatista:**
- Vista de mapa con Leaflet
- Puntos por distrito con offset aleatorio para evitar overlapping
- Muestra conductores con GPS reciente (<120 minutos)
- Filtros: fecha, estado, turno, conductor

**JSoluciones actual:** No implementado (spec lo menciona).

**Dificultad:** Alta

---

### 14. Reporte de vendedores dedicado
**Lo que hace Amatista (`/vendedores/reporte`):**
- Por día, semana o mes
- Por cada vendedor: total pedidos, monto total, desglose por estado
- Pedidos sin vendedor asignado
- Total general

**JSoluciones actual:** Solo endpoint básico sin UI dedicada.

**Dificultad:** Media

---

### 15. Asignación masiva de pedidos a conductor
**Lo que hace Amatista:**
- Pantalla `/asignar` para admin
- Selección múltiple de pedidos (checkboxes)
- Asignar todos a un conductor
- Puede crear conductor al vuelo
- Filtra por fecha + distritos (multi-select)
- Al asignar, cambia estado a EN_RUTA automáticamente
- Devuelve URL del portal del conductor

**JSoluciones actual:** Solo asignación individual.

**Dificultad:** Media

---

## RESUMEN DE PRIORIDADES

| # | Gap | Impacto | Dificultad | Dependencias sistema |
|---|---|---|---|---|
| 1 | Export Excel | Crítico | Baja | Solo Python (openpyxl) |
| 2 | PDF de entrega | Crítico | Media | WeasyPrint + libcairo |
| 3 | PDF interno | Crítico | Baja (después del 2) | Misma que PDF entrega |
| 4 | PDF → imagen | Alto | Media | Ghostscript o Poppler |
| 5 | Filtros avanzados lista | Alto | Media | Solo código |
| 6 | Resumen productos | Medio | Media | Solo código |
| 7 | Auto-refresh lista | Medio | Baja | Solo código |
| 8 | Filtros en sesión | Bajo | Baja | Solo código |
| 9 | Cambiar estado desde lista | Medio | Media | Solo código |
| 10 | Botones PDF desde lista | Bajo | Baja | Después de PDFs |
| 11 | Portal conductor | Alto | Alta | Nuevo módulo |
| 12 | Módulo producción | Medio | Alta | Nuevo módulo |
| 13 | Mapa de entregas | Bajo | Alta | Leaflet JS |
| 14 | Reporte vendedores | Medio | Media | Solo código |
| 15 | Asignación masiva | Alto | Media | Solo código |

---

## STACK TÉCNICO RECOMENDADO PARA LOS GAPS

### Para Export Excel (Gap #1)
```python
# requirements.txt
openpyxl>=3.1.2

# Uso básico
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill
from django.http import HttpResponse

def export_excel(request):
    wb = Workbook()
    ws = wb.active
    ws.title = "Pedidos"
    # ... rellenar filas
    response = HttpResponse(
        content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
    response['Content-Disposition'] = 'attachment; filename="pedidos.xlsx"'
    wb.save(response)
    return response
```

### Para PDF (Gaps #2 y #3)
```python
# requirements.txt
weasyprint>=61.0

# Uso básico
from weasyprint import HTML
from django.http import HttpResponse
from django.template.loader import render_to_string

def pdf_entrega(request, pedido_id):
    html_string = render_to_string('pdf/entrega.html', {'pedido': pedido})
    pdf_bytes = HTML(string=html_string).write_pdf()
    response = HttpResponse(pdf_bytes, content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="entrega_{pedido_id}.pdf"'
    return response
```

### Para conversión PDF → imagen (Gap #4)
```bash
# En el servidor (Dockerfile o apt)
apt-get install -y ghostscript
```
```python
# Python
import subprocess, tempfile, os

def pdf_to_image(pdf_bytes: bytes, fmt: str = 'png', dpi: int = 150) -> bytes:
    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as f:
        f.write(pdf_bytes)
        pdf_path = f.name
    img_path = pdf_path.replace('.pdf', f'.{fmt}')
    device = 'png16m' if fmt == 'png' else 'jpeg'
    subprocess.run([
        'gs', '-dBATCH', '-dNOPAUSE', '-dSAFER',
        f'-sDEVICE={device}', f'-r{dpi}',
        '-dTextAlphaBits=4', '-dGraphicsAlphaBits=4',
        f'-sOutputFile={img_path}', pdf_path
    ], check=True, capture_output=True)
    os.unlink(pdf_path)
    with open(img_path, 'rb') as f:
        data = f.read()
    os.unlink(img_path)
    return data
```
