-- ============================================================
-- MIGRACIÓN: Productos Amatista → JSoluciones ERP
-- Fuente: amatistacom_amatistacom_laravel.sql (MySQL/MariaDB)
-- Destino: JSoluciones PostgreSQL 16 (schema SQL_JSOLUCIONES.sql)
-- Fecha: 2026-02-24
-- ============================================================
--
-- NOTAS IMPORTANTES:
--   1. Ejecutar dentro de una transacción para poder hacer rollback si algo falla.
--   2. Requiere que exista al menos UN almacen con es_principal = TRUE.
--   3. Los productos se insertan con SKU auto-generado (AM-001, AM-002, ...).
--   4. El stock se inserta en la tabla `stock` (no en `productos`), ligado al almacén principal.
--   5. Los productos de Amatista NO tienen categoria → se crea una categoría "Flores y Regalos"
--      si no existe, y todos los productos quedan bajo ella.
--   6. Los precios de Amatista son precio de venta final (con IGV implícito).
--      El script calcula precio_compra estimado como 55% del precio_venta.
--   7. Amatista usa stock NULL = ilimitado. En JSoluciones se mapea como cantidad = 9999.
--   8. Solo se migran productos con activo = 1 (todos en este caso).
--   9. Se usa unidad_medida NIU (Unidad) por default.
--  10. codigo_afectacion_igv = '10' (Gravado — Operación Onerosa, 18% IGV).
-- ============================================================

BEGIN;

-- ============================================================
-- PASO 1: Crear categoría "Flores y Regalos" si no existe
-- ============================================================

INSERT INTO categorias (id, nombre, descripcion, is_active, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'Flores y Regalos',
    'Productos migrados desde sistema Amatista. Arreglos florales, cajas de rosas, chocolates y complementos.',
    TRUE,
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- PASO 2: Insertar los 32 productos de Amatista
-- Adaptaciones:
--   nombre       → nombre (conservado tal cual, solo capitalización normalizada)
--   precio       → precio_venta (precio final de Amatista)
--   precio*0.55  → precio_compra (estimado, ajustar manualmente)
--   NULL/imagen  → sin imagen (se sube manualmente luego)
--   activo=1     → is_active = TRUE
--   stock NULL   → stock = 9999 (ilimitado en JSoluciones no existe, se usa valor alto)
--   stock X      → se registra en tabla stock (PASO 3)
-- ============================================================

WITH cat AS (
    SELECT id AS categoria_id FROM categorias WHERE nombre = 'Flores y Regalos' LIMIT 1
)
INSERT INTO productos (
    id,
    sku,
    nombre,
    descripcion,
    codigo_barras,
    categoria_id,
    unidad_medida,
    precio_compra,
    precio_venta,
    codigo_afectacion_igv,
    stock_minimo,
    stock_maximo,
    requiere_lote,
    is_active,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    sku,
    nombre,
    descripcion,
    '',              -- codigo_barras: vacío, agregar manualmente si se tienen
    cat.categoria_id,
    'NIU',           -- unidad de medida: Unidad (SUNAT)
    precio_compra,
    precio_venta,
    '10',            -- Gravado IGV 18%
    5,               -- stock_minimo: 5 unidades por defecto
    0,               -- stock_maximo: 0 = sin límite superior definido
    FALSE,           -- requiere_lote: no aplica para flores/regalos
    TRUE,
    created_at,
    NOW()
FROM (
    VALUES
    --  SKU          | NOMBRE                         | DESCRIPCION                             | precio_compra | precio_venta | created_at
    ('AM-001', 'Pasion Eterna',              'Arreglo floral - pasion eterna',                  164.45,  299.00, '2026-02-07 21:10:00'::timestamptz),
    ('AM-002', 'Encanto Rojo',               'Arreglo floral - encanto rojo',                   143.00,  260.00, '2026-02-07 21:10:33'::timestamptz),
    ('AM-003', 'Box 50 Rosas Premium',       'Caja con 50 rosas premium',                       164.45,  299.00, '2026-02-07 21:11:30'::timestamptz),
    ('AM-004', 'Bouquet 50 Rosas Rojas',     'Bouquet de 50 rosas rojas',                        98.45,  179.00, '2026-02-07 21:12:00'::timestamptz),
    ('AM-005', 'Bouquet Amor Supremo',       'Bouquet amor supremo',                            164.45,  299.00, '2026-02-07 21:12:15'::timestamptz),
    ('AM-006', 'Bouquet 12 Rosas Pasion',    'Bouquet 12 rosas pasión',                          54.45,   99.00, '2026-02-07 21:12:40'::timestamptz),
    ('AM-007', 'Ramo Sol Radiante',          'Ramo sol radiante',                                92.95,  169.00, '2026-02-07 21:13:37'::timestamptz),
    ('AM-008', 'Cesta Amor Infinito',        'Cesta amor infinito',                             274.45,  499.00, '2026-02-07 21:14:04'::timestamptz),
    ('AM-009', 'Box Oso Enamorado',          'Caja con oso de peluche',                         125.95,  229.00, '2026-02-07 21:14:22'::timestamptz),
    ('AM-010', 'Globo Corona de Amor',       'Globo decorativo corona de amor',                 109.45,  199.00, '2026-02-07 21:14:52'::timestamptz),
    ('AM-011', 'Box Princess',               'Caja princess con flores',                         59.95,  109.00, '2026-02-09 15:09:40'::timestamptz),
    ('AM-012', 'Box Princess Red',           'Caja princess roja con flores',                    59.95,  109.00, '2026-02-09 15:21:33'::timestamptz),
    ('AM-013', 'Lluvia de Tulipanes',        'Arreglo lluvia de tulipanes',                     153.45,  279.00, '2026-02-09 15:25:58'::timestamptz),
    ('AM-014', 'Orquidea Blanca',            'Orquídea blanca',                                 109.45,  199.00, '2026-02-09 15:37:53'::timestamptz),
    ('AM-015', 'Orquidea Lila',              'Orquídea lila',                                   109.45,  199.00, '2026-02-09 15:38:13'::timestamptz),
    ('AM-016', 'Ramo 10 Tulipanes',          'Ramo de 10 tulipanes',                             90.75,  165.00, '2026-02-09 15:39:51'::timestamptz),
    ('AM-017', 'Dulce Romance',              'Arreglo dulce romance',                           167.75,  305.00, '2026-02-09 15:41:33'::timestamptz),
    ('AM-018', 'Dulzura en Burbuja',         'Arreglo dulzura en burbuja',                       92.95,  169.00, '2026-02-09 15:42:24'::timestamptz),
    ('AM-019', 'Chocolate Ferrero Roche',    'Chocolate Ferrero Roche',                          19.80,   36.00, '2026-02-11 23:38:24'::timestamptz),
    ('AM-020', 'Chocolate Hershey Rosado',   'Chocolate Hersheys rosado',                        19.80,   36.00, '2026-02-11 23:39:09'::timestamptz),
    ('AM-021', 'Chocolate Hersheys Rojo',    'Chocolate Hersheys rojo',                          19.80,   36.00, '2026-02-11 23:39:28'::timestamptz),
    ('AM-022', 'Love in a Box Red Princess', 'Caja love in a box red princess',                  65.45,  119.00, '2026-02-12 20:08:07'::timestamptz),
    ('AM-023', 'Caja de Tulipanes',          'Caja de tulipanes',                               109.45,  199.00, '2026-02-13 00:42:27'::timestamptz),
    ('AM-024', 'Globo Burbuja',              'Globo burbuja decorativo',                         16.50,   30.00, '2026-02-13 22:05:55'::timestamptz),
    ('AM-025', 'Lleno de Amor',              'Arreglo lleno de amor',                            93.50,  170.00, '2026-02-18 19:41:31'::timestamptz),
    ('AM-026', 'Locura de Amor',             'Arreglo locura de amor',                          147.95,  269.00, '2026-02-19 14:47:15'::timestamptz),
    ('AM-027', 'Juntos y Felices',           'Arreglo juntos y felices',                        119.35,  217.00, '2026-02-20 13:25:36'::timestamptz),
    ('AM-028', 'Happy Birthday',             'Arreglo happy birthday',                          101.75,  185.00, '2026-02-20 20:36:45'::timestamptz),
    ('AM-029', 'Jardin de Emociones',        'Arreglo jardín de emociones',                     109.45,  199.00, '2026-02-21 19:09:53'::timestamptz),
    ('AM-030', 'Versos de Amor',             'Arreglo versos de amor',                           68.75,  125.00, '2026-02-21 19:11:05'::timestamptz),
    ('AM-031', 'Caja de 12 Rosas',          'Caja de 12 rosas',                                 38.50,   70.00, '2026-02-21 20:14:26'::timestamptz),
    ('AM-032', 'Arreglo Personalizado',      'Arreglo personalizado (precio variable)',          117.65,  213.92, '2026-02-21 21:28:10'::timestamptz)
) AS t(sku, nombre, descripcion, precio_compra, precio_venta, created_at)
CROSS JOIN cat
ON CONFLICT (sku) DO NOTHING;

-- ============================================================
-- PASO 3: Registrar stock en tabla `stock` (almacén principal)
-- Stock real de Amatista donde existía:
--   AM-001: 10 | AM-003: 9 | AM-004: 20 | AM-005: 9
--   AM-006: 38 | AM-016: 17 | AM-022: 6
-- El resto tenía stock NULL (ilimitado) → se pone 9999
-- ============================================================

INSERT INTO stock (id, producto_id, almacen_id, cantidad, created_at, updated_at)
SELECT
    gen_random_uuid(),
    p.id,
    a.id,
    s.cantidad,
    NOW(),
    NOW()
FROM (
    VALUES
    ('AM-001',   10::DECIMAL),
    ('AM-002', 9999::DECIMAL),  -- ilimitado → 9999
    ('AM-003',    9::DECIMAL),
    ('AM-004',   20::DECIMAL),
    ('AM-005',    9::DECIMAL),
    ('AM-006',   38::DECIMAL),
    ('AM-007', 9999::DECIMAL),
    ('AM-008', 9999::DECIMAL),
    ('AM-009', 9999::DECIMAL),
    ('AM-010', 9999::DECIMAL),
    ('AM-011', 9999::DECIMAL),
    ('AM-012', 9999::DECIMAL),
    ('AM-013', 9999::DECIMAL),
    ('AM-014', 9999::DECIMAL),
    ('AM-015', 9999::DECIMAL),
    ('AM-016',   17::DECIMAL),
    ('AM-017', 9999::DECIMAL),
    ('AM-018', 9999::DECIMAL),
    ('AM-019', 9999::DECIMAL),
    ('AM-020', 9999::DECIMAL),
    ('AM-021', 9999::DECIMAL),
    ('AM-022',    6::DECIMAL),
    ('AM-023', 9999::DECIMAL),
    ('AM-024', 9999::DECIMAL),
    ('AM-025', 9999::DECIMAL),
    ('AM-026', 9999::DECIMAL),
    ('AM-027', 9999::DECIMAL),
    ('AM-028', 9999::DECIMAL),
    ('AM-029', 9999::DECIMAL),
    ('AM-030', 9999::DECIMAL),
    ('AM-031', 9999::DECIMAL),
    ('AM-032', 9999::DECIMAL)
) AS s(sku, cantidad)
JOIN productos p ON p.sku = s.sku
CROSS JOIN (SELECT id FROM almacenes WHERE es_principal = TRUE LIMIT 1) a
ON CONFLICT (producto_id, almacen_id) DO UPDATE SET
    cantidad = EXCLUDED.cantidad,
    updated_at = NOW();

-- ============================================================
-- VERIFICACIÓN: Ver los productos insertados
-- ============================================================

SELECT
    p.sku,
    p.nombre,
    p.precio_venta,
    p.precio_compra,
    COALESCE(s.cantidad, 0) AS stock_actual,
    c.nombre AS categoria
FROM productos p
LEFT JOIN stock s ON s.producto_id = p.id
LEFT JOIN categorias c ON c.id = p.categoria_id
WHERE p.sku LIKE 'AM-%'
ORDER BY p.sku;

-- ============================================================
-- Si todo se ve bien, ejecutar: COMMIT;
-- Si hay errores, ejecutar:    ROLLBACK;
-- ============================================================

-- COMMIT;
-- ROLLBACK;
