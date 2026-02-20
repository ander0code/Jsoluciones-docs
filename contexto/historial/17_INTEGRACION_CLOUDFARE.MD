# JSOLUCIONES ERP — INTEGRACIÓN CLOUDFLARE R2 + TABLA MEDIA

> Propuesta para almacenar fotos de productos, logos, avatares y evidencias de entrega
> usando Cloudflare R2 como storage y una tabla `media_archivos` como registro centralizado.
> Todo basado en los docs del proyecto y la documentación oficial de Cloudflare R2.

---

## PARTE 1: ¿POR QUÉ CLOUDFLARE R2?

### Problema actual

El SQL tiene campos para archivos (logo, avatar, archivo en evidencias) pero:
- `productos` **NO tiene campo de imagen** — un producto necesita fotos
- No hay definido dónde se guardan los archivos físicamente
- Guardar archivos en el servidor local no escala y se pierde si el container se reinicia

### ¿Por qué R2 y no S3/GCS/local?

| Aspecto | R2 | S3 | Local (Django media/) |
|---------|:--:|:--:|:--------------------:|
| Egress (descargas) | **$0 siempre** | $0.09/GB | $0 pero consume ancho de banda del server |
| Free tier | 10 GB + 1M ops/mes | 5 GB (12 meses) | Depende del disco |
| CDN incluido | Sí (330+ datacenters) | No (necesitas CloudFront extra) | No |
| API | S3-compatible (boto3) | Nativa | Django FileField |
| Para ERP peruano | Perfecto — fotos de productos, evidencias, logos | Overkill | No escala |

### Pricing R2 (relevante para un ERP)

| Concepto | Free tier | Después |
|----------|-----------|---------|
| Storage | 10 GB/mes | $0.015/GB-mes |
| Class A (uploads) | 1M ops/mes | $4.50/1M ops |
| Class B (descargas) | 10M ops/mes | $0.36/1M ops |
| Egress | **$0 siempre** | **$0 siempre** |

Un ERP típico con 500 productos con 3 fotos c/u = ~1.5 GB. Cabe en el free tier.

---

## PARTE 2: ARQUITECTURA

### Flujo de subida

```
[Frontend React]                    [Backend Django]                 [Cloudflare R2]
     |                                    |                              |
     | 1. POST /api/media/upload          |                              |
     |   (archivo + metadata)             |                              |
     | ---------------------------------> |                              |
     |                                    | 2. Valida permisos (RBAC)    |
     |                                    | 3. Valida tipo/tamaño        |
     |                                    | 4. Genera key único (UUID)   |
     |                                    |                              |
     |                                    | 5. PUT al bucket R2          |
     |                                    | --------------------------> |
     |                                    |                              | 6. Almacena
     |                                    | <-- 200 OK                   |
     |                                    |                              |
     |                                    | 7. Guarda registro en        |
     |                                    |    tabla media_archivos      |
     |                                    |                              |
     | <-- 201 { id, url_publica }        |                              |
```

### Flujo de lectura

```
[Frontend React]                         [Cloudflare CDN + R2]
     |                                          |
     | 1. <img src="https://cdn.empresa.com/    |
     |         productos/uuid-foto.webp" />     |
     | ---------------------------------------->|
     |                                          | 2. CDN cache hit? → sirve
     |                                          |    CDN miss? → lee de R2 → cachea → sirve
     | <-- imagen                               |
```

**El backend NO sirve imágenes.** Solo genera la URL. El frontend carga directo del CDN.

---

## PARTE 3: CONFIGURACIÓN EN .env

```env
# Cloudflare R2
R2_ACCOUNT_ID=tu_account_id
R2_ACCESS_KEY_ID=tu_access_key
R2_SECRET_ACCESS_KEY=tu_secret_key
R2_BUCKET_NAME=jsoluciones-media
R2_PUBLIC_URL=https://cdn.tu-empresa.com
# Si no tienes dominio custom, usa: https://pub-xxx.r2.dev
```

### En settings.py

```python
# config/settings/base.py

# Cloudflare R2 (S3-compatible)
R2_ACCOUNT_ID = config('R2_ACCOUNT_ID', default='')
R2_ACCESS_KEY_ID = config('R2_ACCESS_KEY_ID', default='')
R2_SECRET_ACCESS_KEY = config('R2_SECRET_ACCESS_KEY', default='')
R2_BUCKET_NAME = config('R2_BUCKET_NAME', default='jsoluciones-media')
R2_PUBLIC_URL = config('R2_PUBLIC_URL', default='')
R2_ENDPOINT = f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com'

# Límites de archivos
MEDIA_MAX_FILE_SIZE_MB = 5          # Máximo 5 MB por archivo
MEDIA_ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp']
MEDIA_ALLOWED_DOC_TYPES = ['application/pdf']
```

### Dependencia Python

```
# requirements/base.txt
boto3==1.35.*    # SDK S3-compatible para R2
```

---

## PARTE 4: NUEVA TABLA — `media_archivos`

### ¿Por qué una tabla centralizada?

| Alternativa | Problema |
|-------------|----------|
| Campo `imagen_url` directo en productos | Un producto puede tener 5 fotos. No escala. |
| Tabla `fotos_productos` + `fotos_evidencias` + ... | Tablas duplicadas por cada entidad. |
| **Tabla `media_archivos` polimórfica** | **Una sola tabla para todo. Se conecta a cualquier entidad vía `entidad_tipo` + `entidad_id`.** |

Es el mismo patrón de `referencia_tipo + referencia_id` que ya usamos en `movimientos_stock` y `asientos_contables`.

### Nuevo ENUM

```sql
-- 32. Tipo de entidad que tiene archivos
CREATE TYPE enum_entidad_media AS ENUM (
    'producto', 'configuracion', 'perfil_usuario',
    'evidencia_entrega', 'proveedor', 'cliente'
);

-- 33. Tipo de archivo
CREATE TYPE enum_tipo_archivo AS ENUM (
    'imagen', 'documento', 'firma'
);
```

### SQL de la tabla

```sql
CREATE TABLE media_archivos (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Relación polimórfica (a qué pertenece)
    entidad_tipo    enum_entidad_media NOT NULL,
    entidad_id      UUID          NOT NULL,
    
    -- Datos del archivo
    tipo_archivo    enum_tipo_archivo NOT NULL DEFAULT 'imagen',
    nombre_original VARCHAR(255)  NOT NULL,         -- nombre que subió el usuario
    r2_key          VARCHAR(500)  NOT NULL UNIQUE,   -- key en el bucket R2
    url_publica     VARCHAR(500)  NOT NULL,          -- URL completa del CDN
    mime_type       VARCHAR(100)  NOT NULL,           -- image/jpeg, image/webp, application/pdf
    tamano_bytes    INTEGER       NOT NULL,           -- peso del archivo
    
    -- Metadata
    es_principal    BOOLEAN       NOT NULL DEFAULT FALSE,  -- foto principal del producto
    orden           INTEGER       NOT NULL DEFAULT 0,      -- orden de las fotos
    alt_text        VARCHAR(200)  NOT NULL DEFAULT '',      -- texto alternativo (accesibilidad)
    
    -- Auditoría
    subido_por_id   UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_tamano_positivo CHECK (tamano_bytes > 0)
);

-- Índices
CREATE INDEX idx_media_entidad ON media_archivos(entidad_tipo, entidad_id);
CREATE INDEX idx_media_principal ON media_archivos(entidad_tipo, entidad_id, es_principal)
    WHERE es_principal = TRUE;
```

### Conteo actualizado

| Dato | Antes | Después |
|------|:-----:|:-------:|
| Tablas | 46 | **47** |
| ENUMs | 31 | **33** |

---

## PARTE 5: CÓMO SE CONECTA CON CADA ENTIDAD

### Productos (múltiples fotos)

```
Producto (id=abc-123)
  └── media_archivos WHERE entidad_tipo='producto' AND entidad_id='abc-123'
       ├── foto_1.webp (es_principal=TRUE, orden=0)
       ├── foto_2.webp (es_principal=FALSE, orden=1)
       └── foto_3.webp (es_principal=FALSE, orden=2)
```

**API ejemplo:**
```
GET /api/productos/abc-123/imagenes/     → lista fotos
POST /api/productos/abc-123/imagenes/    → sube foto
DELETE /api/media/uuid-foto/             → elimina (soft delete)
```

### Configuración (logo)

```
Configuracion (id=config-1)
  └── media_archivos WHERE entidad_tipo='configuracion' AND entidad_id='config-1'
       └── logo.png (es_principal=TRUE)
```

El campo `logo VARCHAR(200)` en `configuracion` se puede **mantener** como cache de la URL principal, o eliminarse y siempre consultar `media_archivos`.

**Recomendación:** Mantener `logo` como cache. Cuando se sube un logo, se guarda en `media_archivos` Y se actualiza `configuracion.logo` con la URL. Así no se hace JOIN extra para mostrar el logo en el header.

### Perfil de usuario (avatar)

Mismo patrón que logo. El campo `avatar VARCHAR(200)` en `perfiles_usuario` se mantiene como cache.

### Evidencias de entrega (foto/firma)

```
Pedido (id=pedido-1)
  └── EvidenciaEntrega (id=ev-1, tipo='foto')
       └── media_archivos WHERE entidad_tipo='evidencia_entrega' AND entidad_id='ev-1'
            └── foto_entrega.jpg
```

El campo `archivo VARCHAR(500)` en `evidencias_entrega` se mantiene como cache de la URL.

---

## PARTE 6: SERVICE DJANGO

```python
# core/utils/r2_storage.py
import boto3
import uuid
from django.conf import settings


class R2Storage:
    """Cliente para Cloudflare R2 (S3-compatible)."""
    
    def __init__(self):
        self.client = boto3.client(
            's3',
            region_name='auto',
            endpoint_url=settings.R2_ENDPOINT,
            aws_access_key_id=settings.R2_ACCESS_KEY_ID,
            aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
        )
        self.bucket = settings.R2_BUCKET_NAME
        self.public_url = settings.R2_PUBLIC_URL
    
    def upload(self, file_obj, carpeta: str, content_type: str) -> dict:
        """
        Sube un archivo a R2.
        
        Args:
            file_obj: archivo (InMemoryUploadedFile de Django)
            carpeta: 'productos', 'avatares', 'evidencias', 'logos'
            content_type: 'image/jpeg', 'image/webp', etc.
        
        Returns:
            {'r2_key': str, 'url_publica': str, 'tamano_bytes': int}
        """
        extension = content_type.split('/')[-1]
        filename = f"{uuid.uuid4()}.{extension}"
        r2_key = f"{carpeta}/{filename}"
        
        self.client.upload_fileobj(
            file_obj,
            self.bucket,
            r2_key,
            ExtraArgs={
                'ContentType': content_type,
                'CacheControl': 'public, max-age=31536000',  # 1 año cache
            }
        )
        
        return {
            'r2_key': r2_key,
            'url_publica': f"{self.public_url}/{r2_key}",
            'tamano_bytes': file_obj.size,
        }
    
    def delete(self, r2_key: str):
        """Elimina un archivo de R2."""
        self.client.delete_object(Bucket=self.bucket, Key=r2_key)


# Instancia singleton
r2_storage = R2Storage()
```

### Estructura de carpetas en R2

```
jsoluciones-media/           ← bucket
├── productos/               ← fotos de productos
│   ├── uuid1.webp
│   └── uuid2.jpeg
├── avatares/                ← fotos de perfil
│   └── uuid3.webp
├── logos/                   ← logo de la empresa
│   └── uuid4.png
└── evidencias/              ← fotos/firmas de entrega
    ├── uuid5.jpeg
    └── uuid6.png
```

---

## PARTE 7: VALIDACIONES EN DJANGO

```python
# core/utils/media_validators.py
from django.conf import settings
from core.exceptions import ArchivoInvalidoError


def validar_archivo_imagen(file_obj):
    """Valida tipo y tamaño de imagen."""
    max_size = settings.MEDIA_MAX_FILE_SIZE_MB * 1024 * 1024  # a bytes
    
    if file_obj.content_type not in settings.MEDIA_ALLOWED_IMAGE_TYPES:
        raise ArchivoInvalidoError(
            f'Tipo no permitido: {file_obj.content_type}. '
            f'Permitidos: {", ".join(settings.MEDIA_ALLOWED_IMAGE_TYPES)}'
        )
    
    if file_obj.size > max_size:
        raise ArchivoInvalidoError(
            f'Archivo muy grande: {file_obj.size / 1024 / 1024:.1f} MB. '
            f'Máximo: {settings.MEDIA_MAX_FILE_SIZE_MB} MB.'
        )
```

---

## PARTE 8: SETUP EN CLOUDFLARE (paso a paso)

### 1. Crear cuenta y bucket

```
1. Ir a dash.cloudflare.com → R2 Object Storage
2. Crear bucket: jsoluciones-media
3. Location hint: South America (o auto)
4. Storage class: Standard
```

### 2. Crear API token

```
1. R2 → Manage R2 API Tokens → Create API token
2. Permissions: Object Read & Write
3. Specify bucket: jsoluciones-media
4. Guardar:
   - Access Key ID     → R2_ACCESS_KEY_ID en .env
   - Secret Access Key → R2_SECRET_ACCESS_KEY en .env
   - Account ID        → R2_ACCOUNT_ID en .env
```

### 3. Habilitar acceso público

```
1. Bucket → Settings → Public Access
2. Opción A: r2.dev subdomain (gratis, rápido)
   → URL: https://pub-xxx.r2.dev
3. Opción B: Custom domain (requiere dominio en Cloudflare)
   → URL: https://cdn.tu-empresa.com
```

### 4. Configurar CORS

```json
[
  {
    "AllowedOrigins": ["https://tu-empresa.com", "http://localhost:5173"],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3600
  }
]
```

---

## PARTE 9: RESUMEN DE CAMBIOS AL PROYECTO

### SQL

| Cambio | Detalle |
|--------|---------|
| +1 tabla | `media_archivos` (tabla #47) |
| +2 enums | `enum_entidad_media`, `enum_tipo_archivo` |
| Campos existentes | `logo`, `avatar`, `archivo` se **mantienen** como cache de URL |

### Archivos Django nuevos

| Archivo | Función |
|---------|---------|
| `core/utils/r2_storage.py` | Cliente R2 (boto3) |
| `core/utils/media_validators.py` | Validación de tipo/tamaño |
| `apps/media/__init__.py` | App nueva para media (o dentro de `core`) |
| `apps/media/models.py` | Modelo MediaArchivo |
| `apps/media/serializers.py` | Serialización con validación |
| `apps/media/views.py` | Endpoints de upload/delete |
| `apps/media/urls.py` | Rutas |

### .env

```env
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=jsoluciones-media
R2_PUBLIC_URL=
```

### requirements/base.txt

```
boto3==1.35.*
```

### INSTALLED_APPS

```python
# Agregar:
'apps.media',
```

---

## PARTE 10: NÚMEROS FINALES ACTUALIZADOS

| Dato | Valor |
|------|:-----:|
| Tablas | **47** |
| ENUMs | **33** |
| Constraints | 29 + 1 (chk_tamano_positivo) = **30** |
| Apps Django | 11 + 1 (media) = **12** + reportes (sin modelos) |

---

## PARA EL AGENTE DE BACKEND

1. Agregar los 2 enums y la tabla `media_archivos` al SQL
2. Crear app `apps/media/` con modelo, serializer, views
3. Implementar `core/utils/r2_storage.py` con boto3
4. Los campos `logo`, `avatar`, `archivo` existentes se mantienen como cache — cuando se sube un archivo, se guarda en `media_archivos` Y se actualiza el campo cache
5. Las URLs de Nubefact (pdf_url, xml_url, cdr_url) NO pasan por R2 — Nubefact las genera y nosotros solo guardamos la URL