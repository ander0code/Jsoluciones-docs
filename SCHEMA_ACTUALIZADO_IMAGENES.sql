-- ============================================================
-- ACTUALIZACIÓN DE SCHEMA: INTEGRACIÓN DE IMÁGENES R2
-- JSOLUCIONES ERP v4
-- ============================================================
--
-- Este script actualiza el schema SQL para vincular productos
-- con sus imágenes en Cloudflare R2 via tabla media_archivos
--
-- Cambios:
--   1. Nueva columna: producto.imagen_principal_media_id
--   2. Índice para acceso rápido
--   3. Nueva columna: categoria.imagen_media_id (opcional)
--   4. Queries de validación
--
-- Dependencias:
--   - Tabla media_archivos ya debe existir (v4)
--   - Tabla productos ya debe existir
--
-- ============================================================

-- ============================================================
-- PASO 1: Agregar FK a imágenes en tabla productos
-- ============================================================

ALTER TABLE productos ADD COLUMN imagen_principal_media_id UUID REFERENCES media_archivos(id) ON DELETE SET_NULL;

-- ============================================================
-- PASO 2: Crear índice para acceso rápido
-- ============================================================

CREATE INDEX idx_productos_imagen_principal ON productos(imagen_principal_media_id);

-- ============================================================
-- PASO 3: Agregar FK a imágenes en tabla categorias (opcional)
-- ============================================================

ALTER TABLE categorias ADD COLUMN imagen_media_id UUID REFERENCES media_archivos(id) ON DELETE SET_NULL;

CREATE INDEX idx_categorias_imagen ON categorias(imagen_media_id);

-- ============================================================
-- PASO 4: VALIDACIÓN - Verificar integridad
-- ============================================================

-- Contar productos sin imagen asignada (después de migración)
SELECT COUNT(*) as productos_sin_imagen
FROM productos
WHERE imagen_principal_media_id IS NULL AND is_active = TRUE;

-- Listar productos con sus imágenes
SELECT 
    p.id,
    p.nombre,
    p.sku,
    ma.nombre_original as imagen_nombre,
    ma.url_publica as imagen_url,
    ma.tamano_bytes
FROM productos p
LEFT JOIN media_archivos ma ON p.imagen_principal_media_id = ma.id
WHERE p.is_active = TRUE
ORDER BY p.nombre;

-- Verificar media_archivos orfanas (sin producto asociado)
SELECT COUNT(*) as media_orfanas
FROM media_archivos ma
WHERE ma.entidad_tipo = 'producto'
  AND NOT EXISTS (
    SELECT 1 FROM productos p WHERE p.imagen_principal_media_id = ma.id
  );

-- ============================================================
-- PASO 5: VIEW PARA CATÁLOGO CON IMÁGENES
-- ============================================================

CREATE OR REPLACE VIEW v_productos_catalogo AS
SELECT 
    p.id,
    p.sku,
    p.nombre,
    p.descripcion,
    p.precio_venta,
    p.precio_compra,
    p.unidad_medida,
    c.nombre as categoria_nombre,
    ma.id as imagen_id,
    ma.url_publica as imagen_url,
    ma.alt_text as imagen_alt,
    ma.tamano_bytes as imagen_tamano,
    p.is_active,
    p.created_at
FROM productos p
LEFT JOIN categorias c ON p.categoria_id = c.id
LEFT JOIN media_archivos ma ON p.imagen_principal_media_id = ma.id
WHERE p.is_active = TRUE
ORDER BY p.nombre;

-- ============================================================
-- PASO 6: ACTUALIZACIÓN DE CONSTRAINT
-- ============================================================

-- Asegurar que media_archivos.entidad_tipo sea válido
-- (ya está en enum enum_entidad_media)

-- Si necesitas agregar una restricción adicional:
ALTER TABLE productos ADD CONSTRAINT chk_imagen_entidad CHECK (
    (imagen_principal_media_id IS NULL) OR
    (imagen_principal_media_id IS NOT NULL)
);

-- ============================================================
-- PASO 7: ROLLBACK (en caso de necesidad)
-- ============================================================

-- Para revertir cambios:
-- DROP INDEX IF EXISTS idx_productos_imagen_principal;
-- DROP INDEX IF EXISTS idx_categorias_imagen;
-- DROP VIEW IF EXISTS v_productos_catalogo;
-- ALTER TABLE productos DROP COLUMN imagen_principal_media_id;
-- ALTER TABLE categorias DROP COLUMN imagen_media_id;

-- ============================================================
-- PASO 8: SCRIPTS DE LIMPIEZA POST-MIGRACIÓN
-- ============================================================

-- Verificar que todas las imágenes estén en R2 (no vacías)
SELECT COUNT(*) as imagenes_vacia
FROM media_archivos
WHERE entidad_tipo = 'producto'
  AND (url_publica IS NULL OR url_publica = '');

-- Recalcular total_bytes por producto
SELECT 
    p.id,
    p.nombre,
    SUM(ma.tamano_bytes) as total_bytes
FROM productos p
LEFT JOIN media_archivos ma ON p.imagen_principal_media_id = ma.id
GROUP BY p.id, p.nombre;

-- ============================================================
-- PASO 9: QUERIES ÚTILES PARA VALIDACIÓN
-- ============================================================

-- 1. Productos con imagen asignada
SELECT COUNT(*) as productos_con_imagen
FROM productos
WHERE imagen_principal_media_id IS NOT NULL;

-- 2. Categorías con imagen (para plantilla de tienda)
SELECT 
    c.nombre,
    c.id,
    ma.url_publica,
    COUNT(p.id) as total_productos
FROM categorias c
LEFT JOIN media_archivos ma ON c.imagen_media_id = ma.id
LEFT JOIN productos p ON p.categoria_id = c.id AND p.is_active = TRUE
GROUP BY c.id, c.nombre, ma.url_publica
ORDER BY c.nombre;

-- 3. Verifica integridad referencial
SELECT 
    ma.id,
    ma.nombre_original,
    ma.entidad_tipo,
    ma.entidad_id,
    CASE 
        WHEN ma.entidad_tipo = 'producto' THEN (
            SELECT nombre FROM productos WHERE id = ma.entidad_id
        )
        WHEN ma.entidad_tipo = 'categoria' THEN (
            SELECT nombre FROM categorias WHERE id = ma.entidad_id
        )
        ELSE 'N/A'
    END as entidad_nombre
FROM media_archivos ma
WHERE ma.entidad_tipo IN ('producto', 'categoria')
ORDER BY ma.entidad_tipo, ma.entidad_id;

-- ============================================================
-- MONITOREO POST-MIGRACIÓN (queries útiles)
-- ============================================================

-- Productos sin imágenes (candidatos a completar)
SELECT p.* 
FROM productos p
WHERE imagen_principal_media_id IS NULL 
  AND is_active = TRUE
LIMIT 10;

-- Imágenes sin usar (huérfanas)
SELECT ma.*
FROM media_archivos ma
WHERE ma.entidad_tipo = 'producto'
  AND ma.entidad_id NOT IN (SELECT id FROM productos)
LIMIT 10;

-- Estadísticas de imágenes
SELECT 
    COUNT(*) as total_imagenes,
    COUNT(DISTINCT entidad_id) as entidades_con_imagenes,
    ROUND(AVG(tamano_bytes) / 1024.0 / 1024.0, 2) as tamaño_promedio_mb,
    ROUND(MAX(tamano_bytes) / 1024.0 / 1024.0, 2) as tamaño_maximo_mb,
    ROUND(SUM(tamano_bytes) / 1024.0 / 1024.0 / 1024.0, 2) as tamaño_total_gb
FROM media_archivos
WHERE entidad_tipo = 'producto';

-- ============================================================
-- FIN DE SCRIPT
-- ============================================================
