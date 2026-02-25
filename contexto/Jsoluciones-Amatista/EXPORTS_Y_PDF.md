# EXPORTS Y PDF — Análisis comparativo Amatista → JSoluciones

> Fecha: 2026-02-25
> Fuente: Revisión directa de Laravel-amatista/app/Exports/, app/Services/PdfService.php,
>         app/Http/Controllers/ExcelExportController.php, ReporteController.php
>         y resources/views/reportes/pdf/

---

## LO QUE TIENE AMATISTA (en producción y funcionando)

### 1. Export Excel — `ReportesExport.php` + `ExcelExportController.php`

**Librería:** `maatwebsite/excel` (PhpSpreadsheet por debajo)

**Endpoint:** `GET /excel/export?fecha=YYYY-MM-DD&periodo=semana|mes`

**Columnas exportadas (20 columnas):**
| Col | Campo |
|-----|-------|
| A | # (ID del pedido) |
| B | Cliente (nombre) |
| C | Teléfono cliente |
| D | Fecha compra |
| E | Fecha entrega |
| F | Turno (Mañana / Tarde) |
| G | Destinatario |
| H | Teléfono destinatario |
| I | Distrito |
| J | Dirección |
| K | Tipo ubicación (Casa / Oficina) |
| L | Productos (ej: `1x Bouquet Rosas, 2x Tulipanes`) |
| M | Subtotal productos |
| N | Costo delivery |
| O | Total |
| P | Método de pago |
| Q | Estado |
| R | Conductor |
| S | Registrado por (vendedor) |
| T | Creado (fecha y hora) |

**Estilos:** Fila de encabezado en negrita con color `#880E4F` (fucsia) sobre fondo `#FCE4EC`.
**Anchos de columna:** configurados individualmente (de 6 a 35 chars).
**Filtros:** por período (semana actual o mes completo) a partir de una fecha base.
**Nombre del archivo:** `pedidos_semana_01-02_07-02-2026.xlsx` o `pedidos_febrero_2026.xlsx`

---

### 2. PDF de Entrega — `PdfService::generarPdfEntrega()`

**Librería:** `barryvdh/laravel-dompdf`
**Vista:** `resources/views/reportes/pdf/entrega.blade.php`
**Tamaño:** 15.5cm × 21cm (menor que A4, pensado para meterse en el paquete)

**Contenido:**
- Header con nombre empresa + número de pedido grande (ej: `Pedido 0042`)
- Fecha de generación
- Sección "Datos de Entrega": fecha, turno, nombre, teléfono, distrito, tipo de ubicación
- Caja de dirección con fondo gris
- Sección "Dedicatoria" (condicional, solo si tiene)
- Sección "Productos" con imagen del producto (base64 embebida, 50×50px) + nombre + cantidad
- Footer con nombre de empresa

**Uso:** Se imprime y mete físicamente en el paquete de flores/regalo.

---

### 3. PDF Interno — `PdfService::generarPdfInterno()`

**Vista:** `resources/views/reportes/pdf/interno.blade.php`
**Tamaño:** A4 (21cm × 29.7cm)

**Contenido:** Igual al PDF de entrega pero con datos adicionales:
- Quién registró el pedido (creado_por)
- Método de pago
- Montos (subtotal, delivery, total)
- Datos del cliente (nombre, teléfono)
- Todos los campos de logística

**Uso:** Para uso administrativo interno, no sale del local.

---

### 4. Conversión PDF → Imagen — `PdfService::convertirPdfAImagen()`

**Herramienta:** Ghostscript (`gs` command via `exec()`)
**Formatos:** PNG o JPG
**Resolución:** 150 DPI con anti-aliasing (`dTextAlphaBits=4`, `dGraphicsAlphaBits=4`)
**Endpoints:**
- `GET /reportes/{id}/imagen-entrega/{png|jpg}` → descarga la imagen del PDF de entrega
- `GET /reportes/{id}/imagen-interno/{png|jpg}` → descarga la imagen del PDF interno

**Uso:** Para compartir por WhatsApp — un PNG/JPG se puede enviar directamente en el chat sin que el cliente tenga que abrir un PDF.

---

## ESTADO EN JSOLUCIONES

| Funcionalidad | Estado | Notas |
|---|---|---|
| Export Excel pedidos | ❌ STUB | Existe la tarea en el spec pero sin lógica real |
| Export Excel ventas | ❌ No existe | No hay ningún export de ventas |
| PDF de entrega (para paquete) | ❌ No existe | Solo PDFs de Nubefact (comprobantes SUNAT) |
| PDF interno (administrativo) | ❌ No existe | |
| Conversión PDF → imagen | ❌ No existe | Requiere Ghostscript instalado en servidor |

---

## PLAN DE IMPLEMENTACIÓN PARA JSOLUCIONES

### Prioridad 1 — Export Excel de Ventas (el más pedido)

**Stack recomendado:** `openpyxl` (ya en Django ecosystem) o `xlsxwriter`

**Endpoint propuesto:** `GET /api/v1/ventas/export/?fecha_desde=YYYY-MM-DD&fecha_hasta=YYYY-MM-DD`

**Columnas a incluir (adaptado de Amatista + datos JSoluciones):**
```
# | Número Venta | Fecha | Cliente | Documento Cliente | Vendedor |
Tipo Venta | Método Pago | Subtotal | IGV | Descuento | Total |
Estado | Caja | Productos | Comprobante | Creado
```

**Implementación Django (openpyxl):**
```python
# apps/ventas/views.py — nuevo endpoint
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment

class VentasExportView(APIView):
    def get(self, request):
        # 1. Filtrar ventas por rango de fechas
        # 2. Crear workbook con openpyxl
        # 3. Escribir encabezados con estilos
        # 4. Iterar ventas con detalles
        # 5. StreamingHttpResponse con Content-Disposition
        pass
```

**Dependencias a agregar en requirements.txt:**
```
openpyxl>=3.1.0
```

---

### Prioridad 2 — PDF de Pedido de Entrega

**Stack recomendado:** `WeasyPrint` (mejor CSS support que ReportLab) o `xhtml2pdf`

**Endpoint propuesto:** `GET /api/v1/distribucion/pedidos/{id}/pdf-entrega/`

**Contenido (equivalente a Amatista):**
- Logo + número de pedido grande
- Destinatario + dirección + turno
- Dedicatoria (si existe)
- Lista de productos con imagen (presigned URL de R2 → descargar en bytes → base64)
- Tamaño: 15.5cm × 21cm

**Dependencias a agregar:**
```
weasyprint>=60.0
```
o alternativamente usar `reportlab` que ya puede estar disponible.

---

### Prioridad 3 — PDF Interno de Pedido

**Endpoint:** `GET /api/v1/distribucion/pedidos/{id}/pdf-interno/`

Mismo que PDF de entrega pero en A4 y con datos de cliente, método de pago, montos y quién registró.

---

### Prioridad 4 — Conversión a imagen (WhatsApp)

**Endpoint:** `GET /api/v1/distribucion/pedidos/{id}/imagen-entrega/?formato=png`

**Opciones de implementación:**
1. Ghostscript (igual que Amatista) — requiere `gs` instalado en servidor
2. `pdf2image` library (wrapper de Ghostscript/Poppler en Python)
3. Generar la imagen directamente con Pillow sin pasar por PDF (más simple, menos fiel)

**Dependencias:**
```
pdf2image>=1.16.0  # requiere poppler-utils en el sistema
```

---

## COLUMNAS REALES DEL EXCEL DE AMATISTA (producción)

De los 97 pedidos de febrero 2026 analizados, los campos más usados en el negocio son:

- **Turno:** Mañana (8:00 AM - 2:00 PM) / Tarde (2:00 PM - 10:00 PM)
- **Conductores frecuentes:** Alejandro Canales, Juan Carlos Tafur, Yesenia Aguirre, fiorella sanchez, Luis Enrique, Cesar rivas, Rafael Varela (MOTO)
- **Métodos de pago reales:** Yape, Plin, Izipay, Efectivo, Tarjeta BCP, Tarjeta Interbank, Payum
- **Distritos frecuentes:** Miraflores, San Isidro, Santiago de Surco, La Molina, San Borja
- **Tipos de ubicación:** Casa, Oficina

Estos datos confirman que el export Excel es la funcionalidad **más crítica** para el equipo operativo — lo usan para planificar entregas del día y hacer seguimiento por conductor.

---

## CÓMO SE ACCEDE AL EXCEL EN AMATISTA (UI)

El botón "Exportar Excel" aparece en la lista de pedidos (`/`) **solo para admin**. Es un dropdown con dos controles:

```
[dropdown: Periodo]  → Semana | Mes
[datepicker: Fecha]  → fecha base (default: hoy)
[Botón: Descargar Excel]
```

Al hacer click genera la URL: `GET /exportar-excel?fecha=2026-02-25&periodo=semana`

El archivo se descarga directamente como `pedidos_semana_24-02_28-02-2026.xlsx`.

**En JSoluciones** esto debería aparecer como:
- Botón/dropdown en la lista de ventas o pedidos
- Admin y roles con permiso de reportes pueden descargarlo
- Endpoint: `GET /api/v1/ventas/export/?fecha_desde=2026-02-24&fecha_hasta=2026-02-28`

---

## CÓMO SE ACCEDEN LOS PDFs EN AMATISTA (UI)

En la lista de pedidos, cada fila tiene un grupo de botones:
```
[👁 Ver] [✏ Editar] [📄 PDF ▼]
                      ┌──────────────────┐
                      │  Entrega         │
                      │  ├ 📄 PDF        │
                      │  ├ 🖼 PNG        │
                      │  └ 🖼 JPG        │
                      │  ──────────────  │
                      │  Interno         │
                      │  ├ 📄 PDF        │
                      │  ├ 🖼 PNG        │
                      │  └ 🖼 JPG        │
                      └──────────────────┘
```

También están accesibles desde el detalle del pedido (`/{id}`).

**En JSoluciones** esto debería aparecer:
- En `order-overview/index.tsx` (detalle de venta) — botones "PDF Entrega" y "PDF Interno"
- En la lista de pedidos (si se implementa el dropdown de acciones rápidas)

---

## DIFERENCIA CLAVE DE ARQUITECTURA

| Aspecto | Amatista | JSoluciones |
|---|---|---|
| Generación PDF | Servidor (DomPDF en Laravel) | Debe ser servidor también (WeasyPrint/xhtml2pdf en Django) |
| Export Excel | Servidor (PhpSpreadsheet) | Servidor (openpyxl) |
| Imágenes en PDF | DigitalOcean Spaces → base64 | Cloudflare R2 presigned URL → descargar bytes → base64 |
| Conversión imagen | Ghostscript via exec() | Ghostscript o pdf2image (Python) |
| Autenticación export | Session (web) | JWT (API) — el endpoint debe verificar token |

---

## RESUMEN DE GAPS PENDIENTES

Los 3 gaps críticos para paridad con Amatista en esta área:

1. **Export Excel de pedidos/ventas** — el equipo lo usa diariamente para gestión operativa
2. **PDF de entrega** — se imprime y mete en el paquete físico del cliente
3. **PDF → Imagen** — se envía por WhatsApp al cliente como confirmación/guía

El export Excel es el más simple de implementar (solo openpyxl, sin dependencias de sistema).
Los PDFs requieren instalar WeasyPrint o xhtml2pdf en el servidor.
La conversión a imagen requiere Ghostscript o Poppler instalados.
