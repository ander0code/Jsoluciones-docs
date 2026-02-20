# JSOLUCIONES ERP – Integración Cloudflare R2 (v2 — FINAL)
> Guía técnica basada en la documentación oficial de Cloudflare R2.
> Incluye análisis completo de la DB, mejoras requeridas, caché Redis y código de integración.
> Proyecto: **instancia única, NO multitenant. TODOS los buckets son PRIVADOS.**

---

## 1. ¿Por qué R2 para este proyecto?

| Factor | R2 (Cloudflare) | S3 (AWS) |
|---|---|---|
| **Egress (descarga hacia usuarios)** | **GRATIS** ✅ | ~$0.09/GB |
| Almacenamiento Standard | $0.015/GB-mes | ~$0.023/GB-mes |
| Class A (escrituras: upload, list) | $4.50 / millón | ~$5.00 / millón |
| Class B (lecturas: download, head) | $0.36 / millón | ~$0.40 / millón |
| API compatible con | **S3 API** ✅ | S3 nativa |
| Free tier mensual | **10 GB + 1M writes + 10M reads** | 12 meses limitado |

**Para JSOLUCIONES el egress gratis es clave**: los PDFs de comprobantes, imágenes de productos,
evidencias de entrega y firmas se descargan frecuentemente. Con S3 esto cobraría egress; con R2 es gratis.

> ⚠️ **IMPORTANTE — Buckets 100% privados:**
> JSOLUCIONES es un sistema interno de ventas/ERP. No hay ningún recurso que deba ser
> accesible públicamente sin autenticación. **Ningún bucket se hará público.**
> Todo acceso a archivos se hace mediante **Presigned URLs temporales** generadas por el backend
> y cacheadas en Redis. El frontend nunca tiene acceso directo permanente a R2.

---

## 2. ¿Por qué Redis para cachear las Presigned URLs?

### El problema sin caché

Sin Redis, cada vez que un usuario abre un PDF, ve una imagen o descarga un XML:

```
Usuario → Frontend → Django → [llamada HTTP a Cloudflare R2] → genera URL → responde al frontend
```

Esto significa **una llamada extra de red a Cloudflare por cada archivo que se muestre**, incluso si
el mismo archivo se solicita 100 veces en el mismo minuto. Es lento, ineficiente y acumula
operaciones Class B innecesarias.

### La solución con Redis

```
Primera vez:
Usuario → Frontend → Django → [miss Redis] → llama R2 → guarda URL en Redis con TTL → responde

Siguientes veces (mismo archivo, mismo período):
Usuario → Frontend → Django → [hit Redis] → responde directo ← SIN llamar a R2
```

**Redis es la opción correcta aquí por**:
- Ya está en el stack del proyecto (lo usamos para Celery y Django Channels)
- TTL nativo: Redis expira la key automáticamente, nunca sirve una URL vencida
- Latencia de lectura < 1ms vs. ~100-200ms de una llamada HTTP a Cloudflare
- Sin costo adicional de infraestructura (mismo Redis, DB 2 ya definida para caché)

### Regla de TTL: siempre menor que la expiración de la URL

```
URL firmada dura:  3600 seg (1 hora)
TTL en Redis:      3300 seg (55 min)   ← margen de 5 min para evitar servir URLs vencidas
```

---

## 3. Estructura de Buckets — 3 buckets, TODOS PRIVADOS

```
j-soluciones-media          → Imágenes de productos, logos, avatares de usuario
j-soluciones-documentos     → PDFs/XMLs/CDRs fiscales SUNAT, contratos de proveedores
j-soluciones-evidencias     → Fotos de entrega, firmas digitales, archivos temporales
```

### Justificación de separación por bucket

| Bucket | ¿Público? | Acceso | Qué contiene |
|---|---|---|---|
| `j-soluciones-media` | ❌ **PRIVADO** | Presigned URL cacheada en Redis (TTL 55 min) | Imágenes de productos, logo empresa, avatares de usuario |
| `j-soluciones-documentos` | ❌ **PRIVADO** | Presigned URL cacheada en Redis (TTL 55 min) | PDFs comprobantes, XMLs SUNAT, CDRs, PLEs, contratos PDF |
| `j-soluciones-evidencias` | ❌ **PRIVADO** | Presigned URL cacheada en Redis (TTL 10 min) | Fotos de evidencia de entrega, firmas, uploads temporales del repartidor |

---

## 4. Análisis de la DB Actual — Problemas y Mejoras

### ✅ Lo que ya está bien en la DB actual

La tabla `media_archivos` tiene una base correcta:
- `r2_key VARCHAR(500)` — almacena la key del objeto en R2
- `url_publica VARCHAR(500)` — campo presente (lo reconvertiremos)
- `entidad_tipo` + `entidad_id` — relación polimórfica correcta
- `mime_type`, `tamano_bytes`, `nombre_original` — metadata básica presente
- `es_principal`, `orden` — soporte para múltiples archivos por entidad

---

### ⚠️ Problemas identificados — con SQL de corrección

#### [R2-01] `tamano_bytes INTEGER` desborda con archivos grandes
**Urgencia: CRÍTICA**

`INTEGER` en PostgreSQL tiene máximo ~2.1 GB. Un ZIP de PLE mensual, un video de evidencia
o un backup puede superar esto sin problema. Debe ser `BIGINT`.

```sql
ALTER TABLE media_archivos
    ALTER COLUMN tamano_bytes TYPE BIGINT;
```

---

#### [R2-02] Agregar `bucket_name` — los 3 buckets son distintos
**Urgencia: ALTA**

Con 3 buckets distintos, la tabla necesita saber en cuál está cada archivo para poder
construir la key correcta al generar la presigned URL.

```sql
ALTER TABLE media_archivos
    ADD COLUMN bucket_name VARCHAR(100) NOT NULL DEFAULT 'j-soluciones-media';

-- Actualizar registros de documentos fiscales que ya existan (si los hay)
UPDATE media_archivos
    SET bucket_name = 'j-soluciones-documentos'
    WHERE entidad_tipo IN ('comprobante', 'nota_credito_debito', 'factura_proveedor', 'orden_compra');

UPDATE media_archivos
    SET bucket_name = 'j-soluciones-evidencias'
    WHERE entidad_tipo = 'evidencia_entrega';
```

---

#### [R2-03] `url_publica` debe renombrarse — ya no hay URLs públicas permanentes
**Urgencia: ALTA**

El campo `url_publica VARCHAR(500)` sugiere una URL fija. En un sistema 100% privado,
no existe tal cosa. La URL real se genera dinámicamente con Redis+presigned.
El campo se reconvierte en un campo informativo vacío o se elimina en una segunda fase.

```sql
-- Por ahora: renombrar para dejar claro que no es una URL permanente
ALTER TABLE media_archivos RENAME COLUMN url_publica TO url_legacy;

-- El campo queda en NULL para nuevos registros. Las presigned URLs se generan
-- en tiempo de ejecución vía Redis. No almacenar URLs firmadas en la DB.
```

> **Nota para el agente de código:** En los serializers y vistas que retornen archivos,
> el campo `url` de la respuesta JSON **no viene de la DB**, viene del método
> `r2_service.get_presigned_url_cached()` llamado en tiempo de request.

---

#### [R2-04] `enum_entidad_media` incompleto — faltan entidades del ERP
**Urgencia: ALTA**

El enum actual solo tiene:
`'producto','configuracion','perfil_usuario','evidencia_entrega','proveedor','cliente'`

Faltan entidades que también generan archivos:

```sql
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'comprobante';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'nota_credito_debito';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'orden_compra';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'factura_proveedor';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'lote';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'whatsapp_plantilla';
```

---

#### [R2-05] `enum_tipo_archivo` incompleto para WhatsApp y videos de evidencia
**Urgencia: MEDIA**

WhatsApp Business API permite enviar imágenes, videos y audios como header de plantilla.
El enum actual solo tiene `'imagen','documento','firma'`.

```sql
ALTER TYPE enum_tipo_archivo ADD VALUE IF NOT EXISTS 'video';
ALTER TYPE enum_tipo_archivo ADD VALUE IF NOT EXISTS 'audio';
```

---

#### [R2-06] `evidencias_entrega.archivo VARCHAR(500)` suelto sin FK
**Urgencia: MEDIA**

El campo `archivo` es un string sin integridad referencial. Vincular a `media_archivos`.

```sql
ALTER TABLE evidencias_entrega
    ADD COLUMN media_id UUID REFERENCES media_archivos(id) ON DELETE SET NULL;

-- El campo 'archivo' original queda como legacy hasta migración completa
-- No eliminar aún — deprecar en código con comentario
```

---

#### [R2-07] `comprobantes` tiene URLs en columnas sueltas — renombrar a keys
**Urgencia: MEDIA**

Las columnas `pdf_url`, `xml_url`, `cdr_url` no son URLs permanentes, son keys de R2.
Renombrar para consistencia semántica:

```sql
ALTER TABLE comprobantes RENAME COLUMN pdf_url TO pdf_r2_key;
ALTER TABLE comprobantes RENAME COLUMN xml_url TO xml_r2_key;
ALTER TABLE comprobantes RENAME COLUMN cdr_url TO cdr_r2_key;

ALTER TABLE notas_credito_debito RENAME COLUMN pdf_url TO pdf_r2_key;
ALTER TABLE notas_credito_debito RENAME COLUMN xml_url TO xml_r2_key;
ALTER TABLE notas_credito_debito RENAME COLUMN cdr_url TO cdr_r2_key;
```

---

#### [R2-08] Agregar `r2_metadata JSONB` para metadata adicional de R2
**Urgencia: BAJA**

Para guardar metadatos custom de R2 (Content-Disposition, etiquetas, estado de subida async):

```sql
ALTER TABLE media_archivos ADD COLUMN r2_metadata JSONB;
```

---

#### [R2-09] `configuracion.logo VARCHAR(200)` suelto
**Urgencia: BAJA**

```sql
ALTER TABLE configuracion
    ADD COLUMN logo_media_id UUID REFERENCES media_archivos(id) ON DELETE SET NULL;
-- Mantener campo logo VARCHAR por compatibilidad hasta migrar
```

---

#### [R2-10] Índices nuevos para los campos agregados
**Urgencia: ALTA** (sin estos índices las queries son lentísimas)

```sql
-- Para queries de limpieza/lifecycle por bucket
CREATE INDEX idx_media_bucket ON media_archivos(bucket_name);

-- Para queries de archivos por entidad (ya existe idx_media_entidad, complementar con bucket)
CREATE INDEX idx_media_bucket_entidad ON media_archivos(bucket_name, entidad_tipo, entidad_id);

-- Para FK nueva en evidencias
CREATE INDEX idx_evidencias_media ON evidencias_entrega(media_id);
```

---

### Script completo de migraciones para el agente

```sql
-- ============================================================
-- MIGRACIÓN R2 — Aplicar en orden estricto
-- PostgreSQL 16 | JSOLUCIONES ERP
-- ============================================================

-- [R2-01] tamano_bytes a BIGINT (crítico — evita overflow en archivos > 2.1 GB)
ALTER TABLE media_archivos ALTER COLUMN tamano_bytes TYPE BIGINT;

-- [R2-02] Agregar bucket_name (identifica cuál de los 3 buckets)
ALTER TABLE media_archivos
    ADD COLUMN bucket_name VARCHAR(100) NOT NULL DEFAULT 'j-soluciones-media';

UPDATE media_archivos SET bucket_name = 'j-soluciones-documentos'
    WHERE entidad_tipo IN ('comprobante', 'nota_credito_debito', 'factura_proveedor', 'orden_compra');
UPDATE media_archivos SET bucket_name = 'j-soluciones-evidencias'
    WHERE entidad_tipo = 'evidencia_entrega';

-- [R2-03] Renombrar url_publica — no hay URLs públicas en un ERP privado
ALTER TABLE media_archivos RENAME COLUMN url_publica TO url_legacy;

-- [R2-04] Extender enum entidad_media (faltan entidades del ERP)
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'comprobante';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'nota_credito_debito';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'orden_compra';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'factura_proveedor';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'lote';
ALTER TYPE enum_entidad_media ADD VALUE IF NOT EXISTS 'whatsapp_plantilla';

-- [R2-05] Extender enum tipo_archivo
ALTER TYPE enum_tipo_archivo ADD VALUE IF NOT EXISTS 'video';
ALTER TYPE enum_tipo_archivo ADD VALUE IF NOT EXISTS 'audio';

-- [R2-06] Vincular evidencias_entrega a media_archivos
ALTER TABLE evidencias_entrega
    ADD COLUMN media_id UUID REFERENCES media_archivos(id) ON DELETE SET NULL;

-- [R2-07] Renombrar URLs de comprobantes a keys semánticas
ALTER TABLE comprobantes RENAME COLUMN pdf_url TO pdf_r2_key;
ALTER TABLE comprobantes RENAME COLUMN xml_url TO xml_r2_key;
ALTER TABLE comprobantes RENAME COLUMN cdr_url TO cdr_r2_key;
ALTER TABLE notas_credito_debito RENAME COLUMN pdf_url TO pdf_r2_key;
ALTER TABLE notas_credito_debito RENAME COLUMN xml_url TO xml_r2_key;
ALTER TABLE notas_credito_debito RENAME COLUMN cdr_url TO cdr_r2_key;

-- [R2-08] Metadata JSONB para estado de subida async y custom headers
ALTER TABLE media_archivos ADD COLUMN r2_metadata JSONB;

-- [R2-09] FK logo en configuracion
ALTER TABLE configuracion
    ADD COLUMN logo_media_id UUID REFERENCES media_archivos(id) ON DELETE SET NULL;

-- [R2-10] Índices nuevos
CREATE INDEX idx_media_bucket ON media_archivos(bucket_name);
CREATE INDEX idx_media_bucket_entidad ON media_archivos(bucket_name, entidad_tipo, entidad_id);
CREATE INDEX idx_evidencias_media ON evidencias_entrega(media_id);
```

---

## 5. Nomenclatura de Keys (r2_key)

La key en R2 es el "path" del objeto dentro del bucket. Convención adoptada:

```
# Formato general
{modulo}/{subcarpeta}/{uuid_entidad}/{nombre_descriptivo}_{uuid_corto}.{ext}

# Ejemplos reales del proyecto:
productos/imagenes/a1b2c3-uuid/foto_principal_3f9a1b2c.webp
clientes/documentos/d4e5f6-uuid/contrato_2026_8c1d2e3f.pdf
comprobantes/pdf/F01-001-00000123.pdf
comprobantes/xml/F01-001-00000123.xml
comprobantes/cdr/R-F01-001-00000123.xml
evidencias/fotos/pedido-abc123/foto_entrega_9f2a3b4c.jpg
evidencias/firmas/pedido-abc123/firma_receptor_1a2b3c4d.png
perfiles/avatares/usuario-xyz/avatar_5e6f7a8b.webp
proveedores/contratos/proveedor-abc/contrato_2026_2d3e4f5a.pdf
proveedores/documentos/proveedor-abc/ficha_ruc_6b7c8d9e.pdf
ple/2026/02/LE12345678901-140100-PLE0101010000-1-1.txt
ple/2026/02/LE12345678901-140100-PLE0101010000-1-1.zip
```

---

## 6. Configuración Django

### Variables de entorno (`.env`)

```env
# ── Cloudflare R2 ──────────────────────────────────────────
R2_ACCOUNT_ID=tu_account_id_de_cloudflare
R2_ACCESS_KEY_ID=tu_r2_access_key_id
R2_SECRET_ACCESS_KEY=tu_r2_secret_access_key

R2_BUCKET_MEDIA=j-soluciones-media
R2_BUCKET_DOCUMENTOS=j-soluciones-documentos
R2_BUCKET_EVIDENCIAS=j-soluciones-evidencias

# ── Redis (ya existente en el proyecto) ───────────────────
REDIS_HOST=redis
REDIS_PORT=6379
# DB 0 = Celery Broker
# DB 1 = Django Channels
# DB 2 = Cache general (aquí van las presigned URLs)
```

### `settings.py`

```python
# ──────────────────────────────────────────────────────────
# CLOUDFLARE R2
# ──────────────────────────────────────────────────────────
R2_ACCOUNT_ID       = env("R2_ACCOUNT_ID")
R2_ACCESS_KEY_ID    = env("R2_ACCESS_KEY_ID")
R2_SECRET_ACCESS_KEY = env("R2_SECRET_ACCESS_KEY")
R2_ENDPOINT_URL     = f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

R2_BUCKETS = {
    "media":       env("R2_BUCKET_MEDIA",       default="j-soluciones-media"),
    "documentos":  env("R2_BUCKET_DOCUMENTOS",  default="j-soluciones-documentos"),
    "evidencias":  env("R2_BUCKET_EVIDENCIAS",  default="j-soluciones-evidencias"),
}

# ──────────────────────────────────────────────────────────
# REDIS CACHÉ (DB 2 — compartido con caché general)
# Las presigned URLs se cachean aquí con prefijo "r2_url:"
# ──────────────────────────────────────────────────────────
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": f"redis://{env('REDIS_HOST', default='redis')}:6379/2",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
        "KEY_PREFIX": "jsoluciones",
        "TIMEOUT": 300,
    }
}

# TTLs de presigned URLs por tipo (en segundos)
R2_PRESIGNED_TTL = {
    "media":       3600,   # 1 hora   → imágenes, avatares
    "documentos":  3600,   # 1 hora   → PDFs SUNAT, contratos
    "evidencias":  600,    # 10 min   → fotos/firmas de entrega
}

# TTL de caché Redis = TTL de URL - margen de seguridad de 5 minutos
R2_CACHE_TTL = {
    "media":       3300,   # 55 min en Redis
    "documentos":  3300,   # 55 min en Redis
    "evidencias":  300,    # 5 min en Redis (URLs cortas de 10 min)
}
```

---

## 7. Servicio R2 con caché Redis integrado

```python
# apps/core/services/r2_storage.py

import boto3
import uuid
import logging
from pathlib import Path
from botocore.exceptions import ClientError
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)


class R2StorageService:
    """
    Servicio centralizado para Cloudflare R2.
    - API S3-compatible via boto3
    - Presigned URLs cacheadas en Redis (DB 2)
    - Todos los buckets son PRIVADOS — nunca URLs permanentes
    """

    def __init__(self):
        self._client = None

    @property
    def client(self):
        """Lazy init del cliente boto3. Thread-safe en Django."""
        if self._client is None:
            self._client = boto3.client(
                "s3",
                endpoint_url=settings.R2_ENDPOINT_URL,
                aws_access_key_id=settings.R2_ACCESS_KEY_ID,
                aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
                region_name="auto",  # requerido por R2
            )
        return self._client

    # ──────────────────────────────────────────────────────
    # HELPERS INTERNOS
    # ──────────────────────────────────────────────────────

    def get_bucket_name(self, bucket_tipo: str) -> str:
        """Retorna el nombre real del bucket en R2."""
        bucket = settings.R2_BUCKETS.get(bucket_tipo)
        if not bucket:
            raise ValueError(f"Bucket tipo desconocido: '{bucket_tipo}'. "
                             f"Valores válidos: {list(settings.R2_BUCKETS.keys())}")
        return bucket

    @staticmethod
    def _cache_key_for_url(bucket_tipo: str, r2_key: str) -> str:
        """Genera la key de Redis para la presigned URL."""
        return f"r2_url:{bucket_tipo}:{r2_key}"

    # ──────────────────────────────────────────────────────
    # SUBIDA DE ARCHIVOS
    # ──────────────────────────────────────────────────────

    def upload_file(
        self,
        file_obj,
        r2_key: str,
        bucket_tipo: str = "media",
        content_type: str = None,
        metadata: dict = None,
    ) -> dict:
        """
        Sube un file-like object a R2.

        Args:
            file_obj:      Objeto de archivo (Django InMemoryUploadedFile, BytesIO, etc.)
            r2_key:        Path del objeto en R2 (ej: 'productos/imagenes/uuid/foto.webp')
            bucket_tipo:   'media' | 'documentos' | 'evidencias'
            content_type:  MIME type. Si es None, boto3 lo infiere.
            metadata:      Diccionario de metadata custom (máx 2KB en R2)

        Returns:
            dict: { r2_key, bucket_name, tamano_bytes }
        """
        bucket = self.get_bucket_name(bucket_tipo)

        extra_args = {}
        if content_type:
            extra_args["ContentType"] = content_type
        if metadata:
            extra_args["Metadata"] = {k: str(v) for k, v in metadata.items()}

        # Calcular tamaño antes de subir
        file_obj.seek(0, 2)
        tamano_bytes = file_obj.tell()
        file_obj.seek(0)

        try:
            self.client.upload_fileobj(
                Fileobj=file_obj,
                Bucket=bucket,
                Key=r2_key,
                ExtraArgs=extra_args,
            )
            logger.info(f"R2 upload OK | bucket={bucket} | key={r2_key} | {tamano_bytes} bytes")
        except ClientError as exc:
            logger.error(f"R2 upload FAILED | key={r2_key} | error={exc}")
            raise

        # Invalidar caché si existía una URL previa para esta key
        self._invalidar_cache_url(bucket_tipo, r2_key)

        return {
            "r2_key": r2_key,
            "bucket_name": bucket,
            "tamano_bytes": tamano_bytes,
        }

    def upload_bytes(
        self,
        data: bytes,
        r2_key: str,
        bucket_tipo: str = "documentos",
        content_type: str = "application/octet-stream",
    ) -> dict:
        """
        Sube bytes directos a R2.
        Uso principal: PDFs generados en memoria, XMLs SUNAT, ZIPs de PLE.
        """
        import io
        return self.upload_file(io.BytesIO(data), r2_key, bucket_tipo, content_type)

    # ──────────────────────────────────────────────────────
    # PRESIGNED URLS — con caché Redis
    # ──────────────────────────────────────────────────────

    def get_presigned_url(
        self,
        r2_key: str,
        bucket_tipo: str = "documentos",
        filename: str = None,
    ) -> str:
        """
        Genera (o retorna desde caché Redis) una presigned URL para descarga privada.

        FLUJO:
        1. Busca en Redis con key "r2_url:{bucket_tipo}:{r2_key}"
        2. Si hay HIT → retorna la URL cacheada sin llamar a R2
        3. Si hay MISS → llama a R2, genera URL, la guarda en Redis con TTL apropiado

        TTLs configurados en settings.R2_PRESIGNED_TTL y settings.R2_CACHE_TTL:
        - media:       URL válida 1 hora   | caché Redis 55 min
        - documentos:  URL válida 1 hora   | caché Redis 55 min
        - evidencias:  URL válida 10 min   | caché Redis 5 min

        Args:
            r2_key:      Path del objeto en R2
            bucket_tipo: 'media' | 'documentos' | 'evidencias'
            filename:    Si se provee, la URL fuerza descarga con ese nombre de archivo
                         (útil para PDFs de comprobantes: "F01-001-00000123.pdf")

        Returns:
            str: URL firmada temporal para acceso privado
        """
        cache_key = self._cache_key_for_url(bucket_tipo, r2_key)

        # 1. Intentar desde Redis
        url_cacheada = cache.get(cache_key)
        if url_cacheada:
            logger.debug(f"R2 presigned URL | CACHE HIT | {r2_key}")
            return url_cacheada

        # 2. No estaba en caché → generar nueva URL
        bucket = self.get_bucket_name(bucket_tipo)
        expiration = settings.R2_PRESIGNED_TTL.get(bucket_tipo, 3600)

        params = {"Bucket": bucket, "Key": r2_key}
        if filename:
            params["ResponseContentDisposition"] = f'attachment; filename="{filename}"'

        try:
            url = self.client.generate_presigned_url(
                "get_object",
                Params=params,
                ExpiresIn=expiration,
            )
        except ClientError as exc:
            logger.error(f"R2 presigned URL FAILED | key={r2_key} | error={exc}")
            raise

        # 3. Guardar en Redis con TTL = expiration - 5 min (margen de seguridad)
        redis_ttl = settings.R2_CACHE_TTL.get(bucket_tipo, expiration - 300)
        cache.set(cache_key, url, timeout=redis_ttl)
        logger.debug(f"R2 presigned URL | CACHE MISS → generada y cacheada {redis_ttl}s | {r2_key}")

        return url

    def get_presigned_upload_url(
        self,
        r2_key: str,
        bucket_tipo: str = "evidencias",
        expiration_seconds: int = 900,
        content_type: str = "image/jpeg",
        max_size_bytes: int = 10 * 1024 * 1024,
    ) -> dict:
        """
        Genera URL firmada para que el FRONTEND suba directo a R2.
        El archivo NO pasa por el servidor Django.

        Uso principal: repartidor sube foto/firma de entrega desde móvil.

        NOTA: Estas URLs de subida NO se cachean en Redis porque son de un solo uso.
              Cada solicitud de subida genera una URL nueva.

        Args:
            expiration_seconds: Tiempo de validez para subir (por defecto 15 min)
            content_type:       MIME type permitido
            max_size_bytes:     Tamaño máximo del archivo (validado por R2)

        Returns:
            dict: { url, fields, r2_key, expires_in }
            El frontend hace POST a `url` con los `fields` + el archivo.
        """
        bucket = self.get_bucket_name(bucket_tipo)

        presigned = self.client.generate_presigned_post(
            Bucket=bucket,
            Key=r2_key,
            Fields={"Content-Type": content_type},
            Conditions=[
                {"Content-Type": content_type},
                ["content-length-range", 1, max_size_bytes],
            ],
            ExpiresIn=expiration_seconds,
        )

        logger.info(f"R2 presigned upload URL generada | key={r2_key} | expires={expiration_seconds}s")

        return {
            "url": presigned["url"],
            "fields": presigned["fields"],
            "r2_key": r2_key,
            "expires_in": expiration_seconds,
        }

    # ──────────────────────────────────────────────────────
    # ELIMINACIÓN
    # ──────────────────────────────────────────────────────

    def delete_file(self, r2_key: str, bucket_tipo: str = "media") -> bool:
        """
        Elimina un objeto de R2.
        DeleteObject es GRATUITO en R2.
        También invalida la caché Redis de la URL si existía.
        """
        try:
            bucket = self.get_bucket_name(bucket_tipo)
            self.client.delete_object(Bucket=bucket, Key=r2_key)
            self._invalidar_cache_url(bucket_tipo, r2_key)
            logger.info(f"R2 delete OK | key={r2_key}")
            return True
        except ClientError as exc:
            logger.error(f"R2 delete FAILED | key={r2_key} | error={exc}")
            return False

    def delete_many(self, r2_keys: list[str], bucket_tipo: str = "media") -> dict:
        """
        Elimina múltiples objetos en una sola request a R2 (más eficiente que N deletes).
        También limpia la caché Redis de cada key eliminada.
        R2 acepta hasta 1000 keys por request.
        """
        bucket = self.get_bucket_name(bucket_tipo)
        objects = [{"Key": k} for k in r2_keys]

        response = self.client.delete_objects(
            Bucket=bucket,
            Delete={"Objects": objects, "Quiet": True},
        )

        # Invalidar caché de cada key eliminada
        for key in r2_keys:
            self._invalidar_cache_url(bucket_tipo, key)

        logger.info(f"R2 delete_many | {len(r2_keys)} objetos | bucket={bucket}")
        return response

    # ──────────────────────────────────────────────────────
    # CACHE REDIS — helpers internos
    # ──────────────────────────────────────────────────────

    def _invalidar_cache_url(self, bucket_tipo: str, r2_key: str) -> None:
        """
        Elimina la presigned URL del caché Redis cuando el archivo cambia o se elimina.
        Si no existía en caché, no hace nada (no lanza error).
        """
        cache_key = self._cache_key_for_url(bucket_tipo, r2_key)
        cache.delete(cache_key)

    def invalidar_cache_entidad(self, entidad_tipo: str, entidad_id: str) -> None:
        """
        Invalida en Redis todas las URLs de archivos de una entidad específica.
        Útil cuando se actualiza masivamente una entidad (ej: cambio de logo de empresa).

        NOTA: Requiere django-redis para usar el método keys().
              Si no está disponible, usar invalidación individual por r2_key.
        """
        try:
            from django_redis import get_redis_connection
            con = get_redis_connection("default")
            patron = f"*r2_url:*:{entidad_tipo}/{entidad_id}*"
            keys = con.keys(patron)
            if keys:
                con.delete(*keys)
                logger.info(f"Redis: {len(keys)} URLs invalidadas para {entidad_tipo}/{entidad_id}")
        except Exception as exc:
            logger.warning(f"No se pudo invalidar caché por entidad: {exc}")

    # ──────────────────────────────────────────────────────
    # UTILIDADES ESTÁTICAS
    # ──────────────────────────────────────────────────────

    @staticmethod
    def build_r2_key(
        modulo: str,
        subcarpeta: str,
        entidad_id: str,
        filename: str,
    ) -> str:
        """
        Construye el r2_key con la convención del proyecto.

        Ejemplo:
            build_r2_key("productos", "imagenes", "abc-123", "foto.webp")
            → "productos/imagenes/abc-123/foto_3f9a1b2c.webp"
        """
        ext = Path(filename).suffix.lower()
        stem = Path(filename).stem.replace(" ", "_")[:40]
        unique = uuid.uuid4().hex[:8]
        return f"{modulo}/{subcarpeta}/{entidad_id}/{stem}_{unique}{ext}"


# ── Singleton global ──────────────────────────────────────
# Importar con: from apps.core.services.r2_storage import r2_service
r2_service = R2StorageService()
```

---

## 8. Helper — Guardar archivo en R2 y registrar en DB

```python
# apps/core/services/media_service.py

import mimetypes
import logging
from django.db import transaction
from apps.core.models import MediaArchivo
from .r2_storage import r2_service

logger = logging.getLogger(__name__)


def guardar_archivo_en_r2(
    file_obj,
    entidad_tipo: str,
    entidad_id: str,
    modulo: str,
    subcarpeta: str,
    bucket_tipo: str = "media",
    tipo_archivo: str = "imagen",
    es_principal: bool = False,
    subido_por_id: str = None,
    alt_text: str = "",
) -> "MediaArchivo":
    """
    Sube archivo a R2 y registra el registro en media_archivos.

    IMPORTANTE: Si falla el INSERT en DB después de subir a R2, el archivo
    queda huérfano en R2. Por eso se hace rollback + delete en R2 en el except.

    Args:
        entidad_tipo:   Valor de enum_entidad_media (ej: 'producto')
        entidad_id:     UUID de la entidad propietaria como string
        modulo:         Carpeta base (ej: 'productos', 'comprobantes')
        subcarpeta:     Subcarpeta (ej: 'imagenes', 'pdf', 'contratos')
        bucket_tipo:    'media' | 'documentos' | 'evidencias'

    Returns:
        MediaArchivo: Instancia creada en DB
    """
    nombre_original = getattr(file_obj, "name", "archivo")
    mime_type = mimetypes.guess_type(nombre_original)[0] or "application/octet-stream"

    r2_key = r2_service.build_r2_key(
        modulo=modulo,
        subcarpeta=subcarpeta,
        entidad_id=str(entidad_id),
        filename=nombre_original,
    )

    # 1. Subir a R2
    resultado = r2_service.upload_file(
        file_obj=file_obj,
        r2_key=r2_key,
        bucket_tipo=bucket_tipo,
        content_type=mime_type,
    )

    # 2. Registrar en DB — si falla, eliminar de R2 para evitar huérfanos
    try:
        with transaction.atomic():
            media = MediaArchivo.objects.create(
                entidad_tipo=entidad_tipo,
                entidad_id=entidad_id,
                tipo_archivo=tipo_archivo,
                nombre_original=nombre_original,
                r2_key=resultado["r2_key"],
                url_legacy="",  # no hay URL pública permanente
                mime_type=mime_type,
                tamano_bytes=resultado["tamano_bytes"],
                bucket_name=resultado["bucket_name"],
                es_principal=es_principal,
                subido_por_id=subido_por_id,
                alt_text=alt_text,
            )
    except Exception as exc:
        # Rollback: eliminar el archivo que ya subimos a R2
        logger.error(f"DB insert falló para {r2_key} — eliminando de R2 | error={exc}")
        r2_service.delete_file(r2_key, bucket_tipo)
        raise

    return media


def get_url_archivo(media_obj: "MediaArchivo", filename: str = None) -> str:
    """
    Retorna la presigned URL cacheada en Redis para un MediaArchivo.
    Esta es la función que usan los serializers para el campo 'url'.

    Args:
        media_obj: Instancia de MediaArchivo
        filename:  Si se provee, fuerza Content-Disposition de descarga

    Returns:
        str: URL firmada temporal (desde Redis o generada al vuelo)
    """
    return r2_service.get_presigned_url(
        r2_key=media_obj.r2_key,
        bucket_tipo=_inferir_bucket_tipo(media_obj),
        filename=filename,
    )


def _inferir_bucket_tipo(media_obj) -> str:
    """Infiere el tipo de bucket desde bucket_name o entidad_tipo."""
    if media_obj.bucket_name == "j-soluciones-documentos":
        return "documentos"
    if media_obj.bucket_name == "j-soluciones-evidencias":
        return "evidencias"
    return "media"
```

---

## 9. Tareas Celery para R2

```python
# apps/core/tasks/r2_tasks.py

from celery import shared_task
from django.core.cache import cache
import logging

logger = logging.getLogger(__name__)


@shared_task(
    bind=True,
    max_retries=3,
    queue="default",
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_backoff_max=300,
)
def upload_archivo_r2_async(
    self,
    file_path: str,
    r2_key: str,
    bucket_tipo: str,
    media_id: str,
    content_type: str,
):
    """
    Sube archivos pesados a R2 de forma asíncrona (PLEs, ZIPs, reportes grandes).
    El archivo se guarda temporalmente en disco y esta tarea lo sube.
    """
    from apps.core.services.r2_storage import r2_service
    from apps.core.models import MediaArchivo

    try:
        with open(file_path, "rb") as f:
            r2_service.upload_file(f, r2_key, bucket_tipo, content_type)

        MediaArchivo.objects.filter(id=media_id).update(
            r2_metadata={"estado": "subido", "subido_por": "celery_async"}
        )
        logger.info(f"R2 async upload OK | key={r2_key}")

    except FileNotFoundError:
        logger.error(f"Archivo temporal no encontrado: {file_path}")
        raise
    except Exception as exc:
        logger.error(f"R2 async upload FAILED | key={r2_key} | {exc}")
        raise self.retry(exc=exc)


@shared_task(queue="default")
def eliminar_archivo_r2(r2_key: str, bucket_tipo: str, media_id: str = None):
    """
    Elimina archivo de R2, invalida su caché Redis y hace soft-delete en DB.
    DeleteObject en R2 es GRATUITO.
    """
    from apps.core.services.r2_storage import r2_service
    from apps.core.models import MediaArchivo

    r2_service.delete_file(r2_key, bucket_tipo)  # también invalida Redis

    if media_id:
        MediaArchivo.objects.filter(id=media_id).update(is_active=False)
        logger.info(f"R2 delete OK + soft-delete DB | key={r2_key}")


@shared_task(queue="reports")
def limpiar_archivos_huerfanos():
    """
    Purga archivos marcados is_active=False hace más de 7 días.
    Corre junto al Beat schedule de 'limpiar_archivos_temporales' (4:30 AM Lima).
    """
    from django.utils import timezone
    from datetime import timedelta
    from apps.core.services.r2_storage import r2_service
    from apps.core.models import MediaArchivo

    limite = timezone.now() - timedelta(days=7)
    huerfanos = MediaArchivo.objects.filter(is_active=False, updated_at__lt=limite)
    total = 0

    for archivo in huerfanos:
        bucket_tipo = _infer_bucket_tipo_str(archivo.bucket_name)
        r2_service.delete_file(archivo.r2_key, bucket_tipo)
        archivo.delete()
        total += 1

    logger.info(f"Limpieza R2: {total} archivos huérfanos eliminados")


@shared_task(queue="default")
def precalentar_cache_presigned_urls(media_ids: list[str]):
    """
    Pre-genera y cachea presigned URLs en Redis para una lista de media_ids.
    Útil para precalentar el caché cuando se sabe que el usuario va a descargar
    varios documentos (ej: al abrir la ficha de un comprobante con PDF+XML+CDR).
    """
    from apps.core.services.r2_storage import r2_service
    from apps.core.models import MediaArchivo

    archivos = MediaArchivo.objects.filter(id__in=media_ids, is_active=True)
    for archivo in archivos:
        bucket_tipo = _infer_bucket_tipo_str(archivo.bucket_name)
        r2_service.get_presigned_url(archivo.r2_key, bucket_tipo)

    logger.info(f"Cache presigned URLs precalentado | {len(archivos)} archivos")


def _infer_bucket_tipo_str(bucket_name: str) -> str:
    if bucket_name == "j-soluciones-documentos":
        return "documentos"
    if bucket_name == "j-soluciones-evidencias":
        return "evidencias"
    return "media"
```

---

## 10. Casos de uso por módulo

### SUNAT — PDFs, XMLs y CDRs

```python
# apps/facturacion/services.py
from apps.core.services.r2_storage import r2_service

def guardar_documentos_sunat(comprobante, pdf_bytes: bytes, xml_bytes: bytes, cdr_bytes: bytes):
    """Guarda los 3 archivos SUNAT en R2 y actualiza las keys en el comprobante."""
    nombre = f"{comprobante.tipo_comprobante}-{comprobante.serie}-{str(comprobante.numero).zfill(8)}"

    r2_service.upload_bytes(pdf_bytes, f"comprobantes/pdf/{nombre}.pdf",    "documentos", "application/pdf")
    r2_service.upload_bytes(xml_bytes, f"comprobantes/xml/{nombre}.xml",    "documentos", "application/xml")
    r2_service.upload_bytes(cdr_bytes, f"comprobantes/cdr/R-{nombre}.xml",  "documentos", "application/xml")

    comprobante.pdf_r2_key = f"comprobantes/pdf/{nombre}.pdf"
    comprobante.xml_r2_key = f"comprobantes/xml/{nombre}.xml"
    comprobante.cdr_r2_key = f"comprobantes/cdr/R-{nombre}.xml"
    comprobante.save(update_fields=["pdf_r2_key", "xml_r2_key", "cdr_r2_key", "updated_at"])


def get_pdf_url_comprobante(comprobante, para_descarga: bool = False) -> str:
    """Retorna presigned URL del PDF (cacheada en Redis). Para WhatsApp usar para_descarga=False."""
    filename = f"{comprobante.serie}-{str(comprobante.numero).zfill(8)}.pdf" if para_descarga else None
    return r2_service.get_presigned_url(
        r2_key=comprobante.pdf_r2_key,
        bucket_tipo="documentos",
        filename=filename,
    )
```

### Distribución — Upload de evidencia directo desde móvil

```python
# apps/distribucion/views.py
import uuid
from apps.core.services.r2_storage import r2_service

def solicitar_url_subida_evidencia(request, pedido_id: str, tipo_evidencia: str):
    """
    El repartidor solicita esta URL antes de subir la foto/firma.
    Django genera la presigned POST URL → el móvil sube directo a R2.
    """
    r2_key = f"evidencias/{tipo_evidencia}/{pedido_id}/{uuid.uuid4().hex}.jpg"

    upload_data = r2_service.get_presigned_upload_url(
        r2_key=r2_key,
        bucket_tipo="evidencias",
        expiration_seconds=900,
        content_type="image/jpeg",
        max_size_bytes=5 * 1024 * 1024,  # 5 MB máximo por foto
    )
    return upload_data  # frontend hace POST a upload_data["url"]


def confirmar_evidencia_subida(request, pedido_id: str, r2_key: str, tipo_evidencia: str):
    """
    Después de que el frontend confirma que subió el archivo a R2,
    se registra en evidencias_entrega y en media_archivos.
    """
    from apps.core.models import MediaArchivo, EvidenciaEntrega

    with transaction.atomic():
        media = MediaArchivo.objects.create(
            entidad_tipo="evidencia_entrega",
            entidad_id=pedido_id,
            tipo_archivo="imagen",
            nombre_original=f"evidencia_{tipo_evidencia}.jpg",
            r2_key=r2_key,
            url_legacy="",
            mime_type="image/jpeg",
            tamano_bytes=0,  # se puede actualizar con HeadObject si se requiere
            bucket_name="j-soluciones-evidencias",
        )
        EvidenciaEntrega.objects.create(
            pedido_id=pedido_id,
            tipo=tipo_evidencia,
            media_id=media.id,
        )
```

### Productos — Imagen principal

```python
from apps.core.services.media_service import guardar_archivo_en_r2, get_url_archivo

def subir_imagen_producto(request, producto_id: str):
    imagen = request.FILES["imagen"]
    media = guardar_archivo_en_r2(
        file_obj=imagen,
        entidad_tipo="producto",
        entidad_id=producto_id,
        modulo="productos",
        subcarpeta="imagenes",
        bucket_tipo="media",
        tipo_archivo="imagen",
        es_principal=True,
        subido_por_id=str(request.user.perfil.id),
    )
    # La URL siempre se obtiene del servicio, nunca de la DB directamente
    return {"media_id": str(media.id), "url": get_url_archivo(media)}
```

---

## 11. Patrón en Serializers DRF — campo `url` siempre desde Redis

```python
# apps/core/serializers.py
from rest_framework import serializers
from apps.core.models import MediaArchivo
from apps.core.services.media_service import get_url_archivo


class MediaArchivoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = MediaArchivo
        fields = ["id", "nombre_original", "tipo_archivo", "mime_type",
                  "tamano_bytes", "es_principal", "url", "created_at"]

    def get_url(self, obj) -> str:
        """
        El campo 'url' NUNCA viene de la DB.
        Siempre viene de Redis (o R2 si Redis miss).
        """
        return get_url_archivo(obj)
```

---

## 12. CORS — Solo para `j-soluciones-evidencias`

Solo el bucket de evidencias necesita CORS porque el repartidor sube directo desde el móvil.
Los otros 2 buckets no necesitan CORS porque las subidas van a través del servidor Django.

```json
[
  {
    "AllowedOrigins": [
      "https://app.jsoluciones.com",
      "http://localhost:5173"
    ],
    "AllowedMethods": ["PUT", "POST"],
    "AllowedHeaders": ["Content-Type", "Content-Length"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

**Aplicar:** Dashboard Cloudflare → R2 → `j-soluciones-evidencias` → Settings → CORS Policy.

---

## 13. Pasos para crear los buckets (guía exacta)

> Veo en tu screenshot que ya tienes el formulario de creación con el nombre `j-soluciones`.
> El nombre **es permanente** — antes de crear, sigue estos pasos en orden.

### Bucket 1: `j-soluciones-media`

1. En el campo **Nombre del bucket** escribe: `j-soluciones-media`
2. **Ubicación:** ✅ Automático (ya seleccionado)
3. **Clase de almacenamiento:** ✅ Estándar (ya seleccionado)
4. Clic en **Crear bucket**
5. Después de crear → entrar al bucket → pestaña **Settings**
6. **NO activar** acceso público — dejarlo privado

### Bucket 2: `j-soluciones-documentos`

1. Volver a R2 → **Crear bucket**
2. Nombre: `j-soluciones-documentos`
3. Ubicación: Automático ✅ | Clase: Estándar ✅
4. Crear → **NO activar** acceso público

### Bucket 3: `j-soluciones-evidencias`

1. Volver a R2 → **Crear bucket**
2. Nombre: `j-soluciones-evidencias`
3. Ubicación: Automático ✅ | Clase: Estándar ✅
4. Crear → **NO activar** acceso público
5. Después de crear → Settings → **CORS Policy** → pegar el JSON del punto 12

### Generar API Token (una sola vez para los 3 buckets)

1. En el panel de R2 → botón **"Manage R2 API Tokens"** (esquina superior derecha)
2. Clic en **Create API Token**
3. **Token name:** `jsoluciones-erp-backend`
4. **Permissions:** `Object Read & Write`
5. **Bucket scope:** Seleccionar los 3 buckets creados
6. **TTL:** Sin expiración (o 1 año si prefieres rotarlo)
7. Clic en **Create API Token**
8. ⚠️ **COPIAR INMEDIATAMENTE** el `Access Key ID` y `Secret Access Key`
   — Solo se muestran una vez, después no se pueden recuperar
9. Guardarlos en tu `.env` y en tu gestor de secretos (Vault, 1Password, etc.)

---

## 14. Dependencias Python

```txt
# Agregar a requirements.txt
boto3==1.35.x
django-storages[s3]==1.14.x
django-redis==5.4.x      # si no está ya — para cache.get/set y redis directo
```

---

## 15. Precios estimados para JSOLUCIONES

Estimación con uso real típico de un ERP mediano (1 empresa, ~20 usuarios activos):

| Concepto | Volumen estimado/mes | Free tier R2 | Costo |
|---|---|---|---|
| Storage (PDFs + imágenes + evidencias) | ~5 GB/mes | 10 GB gratis | **$0.00** |
| Writes - Class A (uploads) | ~50,000 | 1,000,000 gratis | **$0.00** |
| Reads - Class B (downloads/presigned) | ~500,000 | 10,000,000 gratis | **$0.00** |
| Egress (todo el tráfico de descarga) | Sin límite | **Siempre gratis** | **$0.00** |
| **TOTAL estimado mes 1-6** | | | **$0/mes** |

> El proyecto opera completamente dentro del **free tier de R2** en sus primeros meses de operación.
> Solo empezará a tener costo cuando supere los 10 GB almacenados o 10M lecturas/mes.

---

## 16. Checklist de implementación para el agente de código

### DB (en orden estricto)
- [ ] `[R2-01]` `tamano_bytes` → BIGINT
- [ ] `[R2-02]` Agregar `bucket_name` + UPDATE de registros existentes
- [ ] `[R2-03]` Renombrar `url_publica` → `url_legacy`
- [ ] `[R2-04]` Extender `enum_entidad_media` con 6 valores nuevos
- [ ] `[R2-05]` Extender `enum_tipo_archivo` con `video` y `audio`
- [ ] `[R2-06]` Agregar `media_id` FK en `evidencias_entrega`
- [ ] `[R2-07]` Renombrar `pdf_url/xml_url/cdr_url` → `pdf_r2_key/xml_r2_key/cdr_r2_key`
- [ ] `[R2-08]` Agregar `r2_metadata JSONB`
- [ ] `[R2-09]` Agregar `logo_media_id` en `configuracion`
- [ ] `[R2-10]` Crear 3 índices nuevos

### Cloudflare Dashboard
- [ ] Crear bucket `j-soluciones-media` (privado)
- [ ] Crear bucket `j-soluciones-documentos` (privado)
- [ ] Crear bucket `j-soluciones-evidencias` (privado + CORS configurado)
- [ ] Generar API Token con permisos Read & Write en los 3 buckets
- [ ] Guardar `Access Key ID` y `Secret Access Key` en `.env`

### Código Django
- [ ] Instalar `boto3`, `django-storages[s3]`, `django-redis`
- [ ] Agregar variables R2 en `.env` y `settings.py`
- [ ] Agregar `R2_PRESIGNED_TTL` y `R2_CACHE_TTL` en `settings.py`
- [ ] Implementar `R2StorageService` en `apps/core/services/r2_storage.py`
- [ ] Implementar helpers `guardar_archivo_en_r2()` y `get_url_archivo()` en `media_service.py`
- [ ] Agregar tareas Celery: `upload_archivo_r2_async`, `eliminar_archivo_r2`, `limpiar_archivos_huerfanos`, `precalentar_cache_presigned_urls`
- [ ] Agregar `limpiar_archivos_huerfanos` al Beat schedule (junto al de 4:30 AM)
- [ ] Actualizar `MediaArchivoSerializer` con `get_url()` via Redis
- [ ] Actualizar módulo Facturación: guardar `pdf_r2_key`, `xml_r2_key`, `cdr_r2_key` al emitir comprobante
- [ ] Actualizar módulo Distribución: endpoints de upload de evidencias (presigned POST)
- [ ] Actualizar módulo Productos: subida de imágenes
- [ ] Actualizar módulo Usuarios: subida de avatar
- [ ] Actualizar módulo Proveedores: subida de contratos PDF

---

*Basado en: Cloudflare R2 Official Docs (developers.cloudflare.com/r2) + SQL_JSOLUCIONES v3*
*Proyecto: JSOLUCIONES ERP — instancia única, NO multitenant, TODOS los buckets privados*
