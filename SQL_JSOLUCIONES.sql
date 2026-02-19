-- ============================================================
-- JSOLUCIONES ERP — SQL Completo v3
-- PostgreSQL 16 | UUID nativo | ENUMs nativos | 47 tablas | 104 índices
-- ============================================================
--
-- REGLAS APLICADAS (03_REGLAS_BASE_DATOS.md):
--   DB-03: id (UUID PK), created_at (TIMESTAMPTZ), updated_at (TIMESTAMPTZ)
--   DB-05: Toda FK con ON DELETE explícito (RESTRICT, CASCADE, SET NULL)
--   DB-06: Índices compuestos en tablas de alto volumen
--   DB-08: Dinero → DECIMAL(12,2)
--   DB-09: Precio unitario → DECIMAL(12,4)
--   DB-10: Soft delete (is_active), nunca DELETE en tablas fiscales
--   DB-14: Texto largo → TEXT, texto corto → VARCHAR(n)
--   DB-15: Cero FLOAT. Todo DECIMAL.
--
-- UUID: gen_random_uuid() nativo de PostgreSQL 13+
-- ENUMs: CREATE TYPE nativo, validación a nivel de DB
-- Fuente de enums: 06_CONSTANTES_COMPARTIDAS.md
-- ============================================================


-- ************************************************************
-- EXTENSIÓN
-- ************************************************************

CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ************************************************************
-- ENUMS (33 tipos) — Fuente: 06_CONSTANTES_COMPARTIDAS.md + 17_INTEGRACION_CLOUDFARE.MD
-- ************************************************************

-- 1. Documentos de identidad (SUNAT)
CREATE TYPE enum_tipo_documento AS ENUM ('1','6','4','7','0');

-- 2. Segmento de cliente
CREATE TYPE enum_segmento_cliente AS ENUM (
    'nuevo','frecuente','vip','credito','corporativo'
);

-- 3. Tipo de comprobante (SUNAT)
CREATE TYPE enum_tipo_comprobante AS ENUM ('01','03','07','08');

-- 4. Estado de comprobante ante SUNAT
CREATE TYPE enum_estado_comprobante AS ENUM (
    'pendiente','aceptado','rechazado','observado',
    'anulado','error','pendiente_reenvio'
);

-- 5. Afectación IGV (SUNAT)
CREATE TYPE enum_afectacion_igv AS ENUM ('10','20','30','21');

-- 6. Motivo de nota de crédito (SUNAT)
CREATE TYPE enum_motivo_nota_credito AS ENUM ('01','02','03','06');

-- 7. Motivo de nota de débito (SUNAT)
CREATE TYPE enum_motivo_nota_debito AS ENUM ('01','02','03');

-- 8. Tipo de nota crédito/débito
CREATE TYPE enum_tipo_nota AS ENUM ('07','08');

-- 9. Método de pago
CREATE TYPE enum_metodo_pago AS ENUM (
    'efectivo','tarjeta','transferencia','yape_plin','credito'
);

-- 10. Tipo de movimiento de stock
CREATE TYPE enum_tipo_movimiento AS ENUM (
    'entrada','salida','transferencia','ajuste','devolucion'
);

-- 11. Referencia origen de movimiento
CREATE TYPE enum_referencia_movimiento AS ENUM (
    'venta','compra','ajuste_manual','transferencia','devolucion'
);

-- 12. Unidad de medida (SUNAT)
CREATE TYPE enum_unidad_medida AS ENUM (
    'NIU','KGM','LTR','MTR','BX','DZN','PK','ZZ'
);

-- 13. Moneda
CREATE TYPE enum_moneda AS ENUM ('PEN','USD');

-- 14. Modo de emisión
CREATE TYPE enum_modo_emision AS ENUM ('normal','contingencia');

-- 15. Estado de cotización
CREATE TYPE enum_estado_cotizacion AS ENUM (
    'borrador','vigente','aceptada','vencida','rechazada'
);

-- 16. Estado de orden de venta
CREATE TYPE enum_estado_orden_venta AS ENUM (
    'pendiente','confirmada','parcial','completada','cancelada'
);

-- 17. Estado de venta
CREATE TYPE enum_estado_venta AS ENUM ('completada','anulada');

-- 18. Tipo de venta
CREATE TYPE enum_tipo_venta AS ENUM ('directa','online','campo');

-- 19. Estado de orden de compra
CREATE TYPE enum_estado_orden_compra AS ENUM (
    'borrador','pendiente_aprobacion','aprobada','enviada',
    'recibida_parcial','recibida','cerrada','cancelada'
);

-- 20. Estado de factura de proveedor
CREATE TYPE enum_estado_factura_proveedor AS ENUM (
    'registrada','conciliada','pagada','anulada'
);

-- 21. Tipo de recepción
CREATE TYPE enum_tipo_recepcion AS ENUM ('total','parcial');

-- 22. Estado de cuenta (CxC / CxP)
CREATE TYPE enum_estado_cuenta AS ENUM (
    'pendiente','vencido','pagado','refinanciado'
);

-- 23. Estado de asiento contable
CREATE TYPE enum_estado_asiento AS ENUM ('borrador','confirmado','anulado');

-- 24. Tipo de cuenta contable
CREATE TYPE enum_tipo_cuenta_contable AS ENUM (
    'activo','pasivo','patrimonio','ingreso','gasto'
);

-- 25. Estado de pedido (distribución)
CREATE TYPE enum_estado_pedido AS ENUM (
    'pendiente','confirmado','despachado','en_ruta',
    'entregado','cancelado','devuelto'
);

-- 26. Prioridad de pedido
CREATE TYPE enum_prioridad_pedido AS ENUM ('normal','express');

-- 27. Tipo de evidencia de entrega
CREATE TYPE enum_tipo_evidencia AS ENUM ('foto','firma','otp');

-- 28. Estado de envío Nubefact
CREATE TYPE enum_estado_envio_nubefact AS ENUM ('enviado','error','pendiente');

-- 29. WhatsApp: estado de mensaje
CREATE TYPE enum_estado_mensaje_wa AS ENUM (
    'enviado','entregado','leido','fallido','en_espera'
);

-- 30. WhatsApp: categoría de plantilla
CREATE TYPE enum_categoria_plantilla_wa AS ENUM (
    'transaccional','marketing','alerta'
);

-- 31. WhatsApp: estado de aprobación Meta
CREATE TYPE enum_estado_plantilla_meta AS ENUM (
    'en_revision','aprobada','rechazada'
);

-- 32. Entidad que tiene archivos (media polimórfica)
CREATE TYPE enum_entidad_media AS ENUM (
    'producto','configuracion','perfil_usuario',
    'evidencia_entrega','proveedor','cliente'
);

-- 33. Tipo de archivo
CREATE TYPE enum_tipo_archivo AS ENUM ('imagen','documento','firma');


-- ************************************************************
-- 1. CONFIGURACIÓN (1 tabla)
-- ************************************************************

CREATE TABLE configuracion (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    ruc             VARCHAR(11)   NOT NULL UNIQUE,
    razon_social    VARCHAR(200)  NOT NULL,
    nombre_comercial VARCHAR(200) NOT NULL DEFAULT '',
    direccion       TEXT          NOT NULL DEFAULT '',
    ubigeo          VARCHAR(6)    NOT NULL DEFAULT '',
    departamento    VARCHAR(50)   NOT NULL DEFAULT '',
    provincia       VARCHAR(50)   NOT NULL DEFAULT '',
    distrito        VARCHAR(50)   NOT NULL DEFAULT '',
    telefono        VARCHAR(20)   NOT NULL DEFAULT '',
    email           VARCHAR(254)  NOT NULL DEFAULT '',
    logo            VARCHAR(200),
    nubefact_token  VARCHAR(200)  NOT NULL DEFAULT '',
    nubefact_url    VARCHAR(500)  NOT NULL DEFAULT 'https://api.nubefact.com/api/v1/',
    -- WhatsApp: credenciales viven en whatsapp_configuracion (tabla dedicada)
    moneda_principal enum_moneda  NOT NULL DEFAULT 'PEN',
    igv_porcentaje  DECIMAL(5,2)  NOT NULL DEFAULT 18.00,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 2. USUARIOS Y RBAC (6 tablas)
-- ************************************************************

CREATE TABLE usuarios (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(254)  NOT NULL UNIQUE,
    password        VARCHAR(128)  NOT NULL,
    first_name      VARCHAR(150)  NOT NULL,
    last_name       VARCHAR(150)  NOT NULL,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    is_staff        BOOLEAN       NOT NULL DEFAULT FALSE,
    is_superuser    BOOLEAN       NOT NULL DEFAULT FALSE,
    date_joined     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    last_login      TIMESTAMPTZ
);

CREATE TABLE roles (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo          VARCHAR(30)   NOT NULL UNIQUE,
    nombre          VARCHAR(100)  NOT NULL,
    descripcion     TEXT          NOT NULL DEFAULT '',
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE permisos (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo          VARCHAR(50)   NOT NULL UNIQUE,
    nombre          VARCHAR(100)  NOT NULL,
    modulo          VARCHAR(30)   NOT NULL,
    descripcion     TEXT          NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE rol_permisos (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    rol_id          UUID          NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permiso_id      UUID          NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(rol_id, permiso_id)
);

CREATE TABLE perfiles_usuario (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID          NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    rol_id          UUID          NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    telefono        VARCHAR(20)   NOT NULL DEFAULT '',
    avatar          VARCHAR(200),
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE log_actividad (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    accion          VARCHAR(50)   NOT NULL,
    modulo          VARCHAR(30)   NOT NULL DEFAULT '',
    detalle         TEXT          NOT NULL DEFAULT '',
    ip_address      VARCHAR(45)   NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 3. CLIENTES (1 tabla)
-- ************************************************************

CREATE TABLE clientes (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_documento      enum_tipo_documento NOT NULL,
    numero_documento    VARCHAR(15)   NOT NULL,
    razon_social        VARCHAR(200)  NOT NULL,
    nombre_comercial    VARCHAR(200)  NOT NULL DEFAULT '',
    direccion           TEXT          NOT NULL DEFAULT '',
    ubigeo              VARCHAR(6)    NOT NULL DEFAULT '',
    email               VARCHAR(254)  NOT NULL DEFAULT '',
    telefono            VARCHAR(20)   NOT NULL DEFAULT '',
    segmento            enum_segmento_cliente NOT NULL DEFAULT 'nuevo',
    limite_credito      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    actualizado_por_id  UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE INDEX idx_clientes_documento ON clientes(tipo_documento, numero_documento);
CREATE INDEX idx_clientes_razon_social ON clientes(razon_social);


-- ************************************************************
-- 4. PROVEEDORES (1 tabla)
-- ************************************************************

CREATE TABLE proveedores (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    ruc                 VARCHAR(11)   NOT NULL UNIQUE,
    razon_social        VARCHAR(200)  NOT NULL,
    nombre_comercial    VARCHAR(200)  NOT NULL DEFAULT '',
    direccion           TEXT          NOT NULL DEFAULT '',
    email               VARCHAR(254)  NOT NULL DEFAULT '',
    telefono            VARCHAR(20)   NOT NULL DEFAULT '',
    contacto_nombre     VARCHAR(100)  NOT NULL DEFAULT '',
    contacto_telefono   VARCHAR(20)   NOT NULL DEFAULT '',
    condicion_pago_dias INTEGER       NOT NULL DEFAULT 0,
    calificacion        INTEGER       NOT NULL DEFAULT 3,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 5. INVENTARIO (6 tablas)
-- ************************************************************

CREATE TABLE categorias (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre              VARCHAR(100)  NOT NULL,
    descripcion         TEXT          NOT NULL DEFAULT '',
    categoria_padre_id  UUID          REFERENCES categorias(id) ON DELETE SET NULL,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE productos (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    sku                   VARCHAR(50)   NOT NULL UNIQUE,
    nombre                VARCHAR(200)  NOT NULL,
    descripcion           TEXT          NOT NULL DEFAULT '',
    codigo_barras         VARCHAR(50)   NOT NULL DEFAULT '',
    categoria_id          UUID          REFERENCES categorias(id) ON DELETE SET NULL,
    unidad_medida         enum_unidad_medida NOT NULL DEFAULT 'NIU',
    precio_compra         DECIMAL(12,4) NOT NULL DEFAULT 0,
    precio_venta          DECIMAL(12,4) NOT NULL,
    codigo_afectacion_igv enum_afectacion_igv NOT NULL DEFAULT '10',
    stock_minimo          DECIMAL(12,2) NOT NULL DEFAULT 0,
    stock_maximo          DECIMAL(12,2) NOT NULL DEFAULT 0,
    requiere_lote         BOOLEAN       NOT NULL DEFAULT FALSE,
    is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    actualizado_por_id    UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE INDEX idx_productos_sku ON productos(sku);
CREATE INDEX idx_productos_categoria_activo ON productos(categoria_id, is_active);
CREATE INDEX idx_productos_nombre ON productos(nombre);

CREATE TABLE almacenes (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          VARCHAR(100)  NOT NULL,
    direccion       TEXT          NOT NULL DEFAULT '',
    sucursal        VARCHAR(100)  NOT NULL DEFAULT '',
    es_principal    BOOLEAN       NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE lotes (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id       UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    numero_lote       VARCHAR(50)   NOT NULL,
    fecha_vencimiento DATE,
    cantidad_inicial  DECIMAL(12,2) NOT NULL,
    cantidad_actual   DECIMAL(12,2) NOT NULL,
    almacen_id        UUID          NOT NULL REFERENCES almacenes(id) ON DELETE RESTRICT,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE stock (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id     UUID          NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    almacen_id      UUID          NOT NULL REFERENCES almacenes(id) ON DELETE CASCADE,
    cantidad        DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(producto_id, almacen_id)
);

CREATE TABLE movimientos_stock (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id       UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    almacen_id        UUID          NOT NULL REFERENCES almacenes(id) ON DELETE RESTRICT,
    tipo_movimiento   enum_tipo_movimiento NOT NULL,
    cantidad          DECIMAL(12,2) NOT NULL,
    almacen_destino_id UUID         REFERENCES almacenes(id) ON DELETE RESTRICT,
    referencia_tipo   enum_referencia_movimiento,
    referencia_id     UUID,
    lote_id           UUID          REFERENCES lotes(id) ON DELETE SET NULL,
    motivo            TEXT          NOT NULL DEFAULT '',
    usuario_id        UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_producto_fecha ON movimientos_stock(producto_id, created_at);
CREATE INDEX idx_mov_almacen_tipo ON movimientos_stock(almacen_id, tipo_movimiento);
CREATE INDEX idx_mov_referencia ON movimientos_stock(referencia_tipo, referencia_id);


-- ************************************************************
-- 6. VENTAS (6 tablas)
-- ************************************************************

CREATE TABLE cotizaciones (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero                  VARCHAR(20)   NOT NULL,
    fecha_emision           DATE          NOT NULL,
    fecha_validez           DATE          NOT NULL,
    cliente_id              UUID          NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    vendedor_id             UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE RESTRICT,
    estado                  enum_estado_cotizacion NOT NULL DEFAULT 'borrador',
    total_gravada           DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv               DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_venta             DECIMAL(12,2) NOT NULL DEFAULT 0,
    notas                   TEXT          NOT NULL DEFAULT '',
    condiciones_comerciales TEXT          NOT NULL DEFAULT '',
    is_active               BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id           UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE TABLE detalle_cotizaciones (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    cotizacion_id         UUID          NOT NULL REFERENCES cotizaciones(id) ON DELETE CASCADE,
    producto_id           UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad              DECIMAL(12,2) NOT NULL,
    precio_unitario       DECIMAL(12,4) NOT NULL,
    descuento_porcentaje  DECIMAL(5,2)  NOT NULL DEFAULT 0,
    subtotal              DECIMAL(12,2) NOT NULL,
    igv                   DECIMAL(12,2) NOT NULL,
    total                 DECIMAL(12,2) NOT NULL,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE ordenes_venta (
    id                   UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero               VARCHAR(20)   NOT NULL,
    fecha                DATE          NOT NULL,
    cotizacion_origen_id UUID          REFERENCES cotizaciones(id) ON DELETE SET NULL,
    cliente_id           UUID          NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    vendedor_id          UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE RESTRICT,
    estado               enum_estado_orden_venta NOT NULL DEFAULT 'pendiente',
    total_gravada        DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv            DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_venta          DECIMAL(12,2) NOT NULL DEFAULT 0,
    is_active            BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id        UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE TABLE detalle_ordenes_venta (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_venta_id        UUID          NOT NULL REFERENCES ordenes_venta(id) ON DELETE CASCADE,
    producto_id           UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad              DECIMAL(12,2) NOT NULL,
    cantidad_entregada    DECIMAL(12,2) NOT NULL DEFAULT 0,
    precio_unitario       DECIMAL(12,4) NOT NULL,
    descuento_porcentaje  DECIMAL(5,2)  NOT NULL DEFAULT 0,
    subtotal              DECIMAL(12,2) NOT NULL,
    igv                   DECIMAL(12,2) NOT NULL,
    total                 DECIMAL(12,2) NOT NULL,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE ventas (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero            VARCHAR(20)   NOT NULL,
    fecha             DATE          NOT NULL,
    hora              TIME,
    orden_origen_id   UUID          REFERENCES ordenes_venta(id) ON DELETE SET NULL,
    cliente_id        UUID          NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    vendedor_id       UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE RESTRICT,
    sucursal          VARCHAR(100)  NOT NULL DEFAULT '',
    caja              VARCHAR(50)   NOT NULL DEFAULT '',
    tipo_venta        enum_tipo_venta NOT NULL DEFAULT 'directa',
    metodo_pago       enum_metodo_pago NOT NULL DEFAULT 'efectivo',
    total_gravada     DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv         DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_descuento   DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_venta       DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado            enum_estado_venta NOT NULL DEFAULT 'completada',
    comprobante_id    UUID,
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id     UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE INDEX idx_ventas_cliente_fecha ON ventas(cliente_id, fecha);
CREATE INDEX idx_ventas_vendedor_fecha ON ventas(vendedor_id, fecha);
CREATE INDEX idx_ventas_estado_fecha ON ventas(estado, fecha);

CREATE TABLE detalle_ventas (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    venta_id              UUID          NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
    producto_id           UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad              DECIMAL(12,2) NOT NULL,
    precio_unitario       DECIMAL(12,4) NOT NULL,
    descuento_porcentaje  DECIMAL(5,2)  NOT NULL DEFAULT 0,
    subtotal              DECIMAL(12,2) NOT NULL,
    igv                   DECIMAL(12,2) NOT NULL,
    total                 DECIMAL(12,2) NOT NULL,
    lote_id               UUID          REFERENCES lotes(id) ON DELETE SET NULL,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dv_venta_producto ON detalle_ventas(venta_id, producto_id);


-- ************************************************************
-- 7. FACTURACIÓN ELECTRÓNICA (5 tablas)
-- ************************************************************

CREATE TABLE series_comprobante (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_comprobante    enum_tipo_comprobante NOT NULL,
    serie               VARCHAR(4)    NOT NULL,
    correlativo_actual  INTEGER       NOT NULL DEFAULT 0,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(tipo_comprobante, serie)
);

CREATE TABLE comprobantes (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_comprobante    enum_tipo_comprobante NOT NULL,
    serie               VARCHAR(4)    NOT NULL,
    numero              INTEGER       NOT NULL,
    fecha_emision       DATE          NOT NULL,
    hora_emision        TIME,
    cliente_id          UUID          NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    moneda              enum_moneda   NOT NULL DEFAULT 'PEN',
    total_gravada       DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_exonerada     DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_inafecta      DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv           DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_venta         DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_sunat        enum_estado_comprobante NOT NULL DEFAULT 'pendiente',
    pdf_url             VARCHAR(500)  NOT NULL DEFAULT '',
    xml_url             VARCHAR(500)  NOT NULL DEFAULT '',
    cdr_url             VARCHAR(500)  NOT NULL DEFAULT '',
    hash_sunat          TEXT          NOT NULL DEFAULT '',
    qr_sunat            TEXT          NOT NULL DEFAULT '',
    nubefact_request    JSONB,
    nubefact_response   JSONB,
    modo_emision        enum_modo_emision NOT NULL DEFAULT 'normal',
    venta_id            UUID          REFERENCES ventas(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    UNIQUE(tipo_comprobante, serie, numero)
);

CREATE INDEX idx_comprobantes_cliente_fecha ON comprobantes(cliente_id, fecha_emision);
CREATE INDEX idx_comprobantes_estado ON comprobantes(estado_sunat);

-- FK diferida: ventas.comprobante_id → comprobantes.id
ALTER TABLE ventas
    ADD CONSTRAINT fk_ventas_comprobante
    FOREIGN KEY (comprobante_id) REFERENCES comprobantes(id) ON DELETE SET NULL;

CREATE TABLE detalle_comprobantes (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    comprobante_id        UUID          NOT NULL REFERENCES comprobantes(id) ON DELETE CASCADE,
    codigo_producto       VARCHAR(50)   NOT NULL DEFAULT '',
    descripcion           VARCHAR(500)  NOT NULL,
    cantidad              DECIMAL(12,2) NOT NULL,
    unidad_medida         enum_unidad_medida NOT NULL DEFAULT 'NIU',
    precio_unitario       DECIMAL(12,4) NOT NULL,
    subtotal              DECIMAL(12,2) NOT NULL,
    igv                   DECIMAL(12,2) NOT NULL,
    total                 DECIMAL(12,2) NOT NULL,
    tipo_afectacion_igv   enum_afectacion_igv NOT NULL DEFAULT '10',
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE notas_credito_debito (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    comprobante_origen_id UUID          NOT NULL REFERENCES comprobantes(id) ON DELETE RESTRICT,
    tipo_nota             enum_tipo_nota NOT NULL,
    serie                 VARCHAR(4)    NOT NULL,
    numero                INTEGER       NOT NULL,
    fecha_emision         DATE          NOT NULL,
    motivo_codigo_nc      enum_motivo_nota_credito,  -- solo si tipo_nota = '07'
    motivo_codigo_nd      enum_motivo_nota_debito,   -- solo si tipo_nota = '08'
    motivo_descripcion    TEXT          NOT NULL DEFAULT '',
    total_gravada         DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv             DECIMAL(12,2) NOT NULL DEFAULT 0,
    total                 DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_sunat          enum_estado_comprobante NOT NULL DEFAULT 'pendiente',
    pdf_url               VARCHAR(500)  NOT NULL DEFAULT '',
    xml_url               VARCHAR(500)  NOT NULL DEFAULT '',
    cdr_url               VARCHAR(500)  NOT NULL DEFAULT '',
    nubefact_request      JSONB,
    nubefact_response     JSONB,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    -- CHECK: exactamente uno de los dos motivos debe estar presente
    CONSTRAINT chk_motivo_nota CHECK (
        (tipo_nota = '07' AND motivo_codigo_nc IS NOT NULL AND motivo_codigo_nd IS NULL)
        OR
        (tipo_nota = '08' AND motivo_codigo_nd IS NOT NULL AND motivo_codigo_nc IS NULL)
    )
);

CREATE TABLE log_envio_nubefact (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    comprobante_id      UUID          NOT NULL REFERENCES comprobantes(id) ON DELETE RESTRICT,
    tipo_documento      enum_tipo_comprobante NOT NULL,
    fecha_envio         TIMESTAMPTZ   NOT NULL,
    request_json        JSONB         NOT NULL,
    response_json       JSONB,
    codigo_respuesta    VARCHAR(20)   NOT NULL DEFAULT '',
    mensaje_respuesta   TEXT          NOT NULL DEFAULT '',
    estado              enum_estado_envio_nubefact NOT NULL DEFAULT 'enviado',
    intentos            INTEGER       NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 8. COMPRAS (5 tablas)
-- ************************************************************

CREATE TABLE ordenes_compra (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero                VARCHAR(20)   NOT NULL,
    fecha                 DATE          NOT NULL,
    fecha_estimada_entrega DATE,
    proveedor_id          UUID          NOT NULL REFERENCES proveedores(id) ON DELETE RESTRICT,
    estado                enum_estado_orden_compra NOT NULL DEFAULT 'borrador',
    almacen_destino_id    UUID          REFERENCES almacenes(id) ON DELETE SET NULL,
    moneda                enum_moneda   NOT NULL DEFAULT 'PEN',
    total_base            DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv             DECIMAL(12,2) NOT NULL DEFAULT 0,
    total                 DECIMAL(12,2) NOT NULL DEFAULT 0,
    notas                 TEXT          NOT NULL DEFAULT '',
    aprobado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE TABLE detalle_ordenes_compra (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_compra_id     UUID          NOT NULL REFERENCES ordenes_compra(id) ON DELETE CASCADE,
    producto_id         UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad            DECIMAL(12,2) NOT NULL,
    cantidad_recibida   DECIMAL(12,2) NOT NULL DEFAULT 0,
    precio_unitario     DECIMAL(12,4) NOT NULL,
    subtotal            DECIMAL(12,2) NOT NULL,
    igv                 DECIMAL(12,2) NOT NULL,
    total               DECIMAL(12,2) NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE facturas_proveedor (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id        UUID          NOT NULL REFERENCES proveedores(id) ON DELETE RESTRICT,
    numero_factura      VARCHAR(30)   NOT NULL,
    ruc_proveedor       VARCHAR(11)   NOT NULL,
    fecha_emision       DATE          NOT NULL,
    fecha_vencimiento   DATE,
    total_base          DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv           DECIMAL(12,2) NOT NULL DEFAULT 0,
    total               DECIMAL(12,2) NOT NULL DEFAULT 0,
    orden_compra_id     UUID          REFERENCES ordenes_compra(id) ON DELETE SET NULL,
    estado              enum_estado_factura_proveedor NOT NULL DEFAULT 'registrada',
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE recepciones (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_compra_id     UUID          NOT NULL REFERENCES ordenes_compra(id) ON DELETE RESTRICT,
    fecha_recepcion     DATE          NOT NULL,
    almacen_id          UUID          NOT NULL REFERENCES almacenes(id) ON DELETE RESTRICT,
    tipo                enum_tipo_recepcion NOT NULL,
    observaciones       TEXT          NOT NULL DEFAULT '',
    recibido_por_id     UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE detalle_recepciones (
    id                       UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    recepcion_id             UUID          NOT NULL REFERENCES recepciones(id) ON DELETE CASCADE,
    detalle_orden_compra_id  UUID          NOT NULL REFERENCES detalle_ordenes_compra(id) ON DELETE RESTRICT,
    producto_id              UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad_recibida        DECIMAL(12,2) NOT NULL,
    lote_id                  UUID          REFERENCES lotes(id) ON DELETE SET NULL,
    observaciones            TEXT          NOT NULL DEFAULT '',
    created_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 9. FINANZAS (7 tablas)
-- ************************************************************

CREATE TABLE cuentas_por_cobrar (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id          UUID          NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    comprobante_id      UUID          REFERENCES comprobantes(id) ON DELETE SET NULL,
    monto_original      DECIMAL(12,2) NOT NULL,
    monto_pendiente     DECIMAL(12,2) NOT NULL,
    fecha_emision       DATE          NOT NULL,
    fecha_vencimiento   DATE          NOT NULL,
    estado              enum_estado_cuenta NOT NULL DEFAULT 'pendiente',
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE cuentas_por_pagar (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id          UUID          NOT NULL REFERENCES proveedores(id) ON DELETE RESTRICT,
    factura_proveedor_id  UUID          REFERENCES facturas_proveedor(id) ON DELETE SET NULL,
    monto_original        DECIMAL(12,2) NOT NULL,
    monto_pendiente       DECIMAL(12,2) NOT NULL,
    fecha_emision         DATE          NOT NULL,
    fecha_vencimiento     DATE          NOT NULL,
    estado                enum_estado_cuenta NOT NULL DEFAULT 'pendiente',
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE cobros (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    cuenta_por_cobrar_id  UUID          NOT NULL REFERENCES cuentas_por_cobrar(id) ON DELETE RESTRICT,
    monto                 DECIMAL(12,2) NOT NULL,
    fecha                 DATE          NOT NULL,
    metodo_pago           enum_metodo_pago NOT NULL,
    referencia            VARCHAR(100)  NOT NULL DEFAULT '',
    notas                 TEXT          NOT NULL DEFAULT '',
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE TABLE pagos (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    cuenta_por_pagar_id   UUID          NOT NULL REFERENCES cuentas_por_pagar(id) ON DELETE RESTRICT,
    monto                 DECIMAL(12,2) NOT NULL,
    fecha                 DATE          NOT NULL,
    metodo_pago           enum_metodo_pago NOT NULL,
    referencia            VARCHAR(100)  NOT NULL DEFAULT '',
    notas                 TEXT          NOT NULL DEFAULT '',
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE TABLE cuentas_contables (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo          VARCHAR(20)   NOT NULL UNIQUE,
    nombre          VARCHAR(200)  NOT NULL,
    tipo            enum_tipo_cuenta_contable NOT NULL,
    nivel           INTEGER       NOT NULL,
    cuenta_padre_id UUID          REFERENCES cuentas_contables(id) ON DELETE SET NULL,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE asientos_contables (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero          VARCHAR(20)   NOT NULL,
    fecha           DATE          NOT NULL,
    descripcion     TEXT          NOT NULL,
    centro_costo    VARCHAR(100)  NOT NULL DEFAULT '',
    referencia_tipo VARCHAR(20)   NOT NULL DEFAULT '',
    referencia_id   UUID,
    estado          enum_estado_asiento NOT NULL DEFAULT 'borrador',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id   UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL
);

CREATE TABLE detalle_asientos (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    asiento_id          UUID          NOT NULL REFERENCES asientos_contables(id) ON DELETE CASCADE,
    cuenta_contable_id  UUID          NOT NULL REFERENCES cuentas_contables(id) ON DELETE RESTRICT,
    debe                DECIMAL(12,2) NOT NULL DEFAULT 0,
    haber               DECIMAL(12,2) NOT NULL DEFAULT 0,
    descripcion         VARCHAR(200)  NOT NULL DEFAULT '',
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 10. DISTRIBUCIÓN (4 tablas)
-- ************************************************************

CREATE TABLE transportistas (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                VARCHAR(200)  NOT NULL,
    telefono              VARCHAR(20)   NOT NULL,
    email                 VARCHAR(254)  NOT NULL DEFAULT '',
    tipo_vehiculo         VARCHAR(50)   NOT NULL DEFAULT '',
    placa                 VARCHAR(10)   NOT NULL DEFAULT '',
    limite_pedidos_diario INTEGER       NOT NULL DEFAULT 20,
    is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE pedidos (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero                  VARCHAR(20)   NOT NULL,
    fecha                   DATE          NOT NULL,
    venta_id                UUID          REFERENCES ventas(id) ON DELETE SET NULL,
    cliente_id              UUID          NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    direccion_entrega       TEXT          NOT NULL,
    latitud                 DECIMAL(10,7),
    longitud                DECIMAL(10,7),
    estado                  enum_estado_pedido NOT NULL DEFAULT 'pendiente',
    transportista_id        UUID          REFERENCES transportistas(id) ON DELETE SET NULL,
    fecha_estimada_entrega  DATE,
    fecha_entrega_real      DATE,
    notas                   TEXT          NOT NULL DEFAULT '',
    prioridad               enum_prioridad_pedido NOT NULL DEFAULT 'normal',
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE seguimiento_pedidos (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id       UUID          NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    estado          enum_estado_pedido NOT NULL,
    latitud         DECIMAL(10,7),
    longitud        DECIMAL(10,7),
    descripcion     TEXT          NOT NULL DEFAULT '',
    fecha_evento    TIMESTAMPTZ   NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE evidencias_entrega (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id       UUID          NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    tipo            enum_tipo_evidencia NOT NULL,
    archivo         VARCHAR(500),
    codigo_otp      VARCHAR(6),
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 11. WHATSAPP (4 tablas)
-- ************************************************************

CREATE TABLE whatsapp_configuracion (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number_id   VARCHAR(50)   NOT NULL,
    token_acceso      VARCHAR(500)  NOT NULL,
    business_id       VARCHAR(50)   NOT NULL DEFAULT '',
    numero_verificado VARCHAR(20)   NOT NULL DEFAULT '',
    is_active         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE whatsapp_plantillas (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre              VARCHAR(100)  NOT NULL,
    categoria           enum_categoria_plantilla_wa NOT NULL,
    contenido_template  TEXT          NOT NULL,
    variables_count     INTEGER       NOT NULL DEFAULT 0,
    estado_meta         enum_estado_plantilla_meta NOT NULL DEFAULT 'en_revision',
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE whatsapp_mensajes (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    plantilla_id          UUID          REFERENCES whatsapp_plantillas(id) ON DELETE SET NULL,
    destinatario_telefono VARCHAR(20)   NOT NULL,
    cliente_id            UUID          REFERENCES clientes(id) ON DELETE SET NULL,
    contenido_enviado     TEXT          NOT NULL,
    estado                enum_estado_mensaje_wa NOT NULL DEFAULT 'en_espera',
    meta_message_id       VARCHAR(100)  NOT NULL DEFAULT '',
    codigo_respuesta_api  VARCHAR(20)   NOT NULL DEFAULT '',
    referencia_tipo       VARCHAR(20)   NOT NULL DEFAULT '',
    referencia_id         UUID,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE whatsapp_log (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    mensaje_id      UUID          NOT NULL REFERENCES whatsapp_mensajes(id) ON DELETE CASCADE,
    request_json    JSONB         NOT NULL,
    response_json   JSONB,
    codigo_http     INTEGER,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- 12. MEDIA / ARCHIVOS (1 tabla) — Cloudflare R2
-- ************************************************************

CREATE TABLE media_archivos (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Relación polimórfica (a qué entidad pertenece)
    entidad_tipo    enum_entidad_media NOT NULL,
    entidad_id      UUID          NOT NULL,

    -- Datos del archivo
    tipo_archivo    enum_tipo_archivo NOT NULL DEFAULT 'imagen',
    nombre_original VARCHAR(255)  NOT NULL,
    r2_key          VARCHAR(500)  NOT NULL UNIQUE,
    url_publica     VARCHAR(500)  NOT NULL,
    mime_type       VARCHAR(100)  NOT NULL,
    tamano_bytes    INTEGER       NOT NULL,

    -- Metadata
    es_principal    BOOLEAN       NOT NULL DEFAULT FALSE,
    orden           INTEGER       NOT NULL DEFAULT 0,
    alt_text        VARCHAR(200)  NOT NULL DEFAULT '',

    -- Auditoría
    subido_por_id   UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_tamano_positivo CHECK (tamano_bytes > 0)
);

CREATE INDEX idx_media_entidad ON media_archivos(entidad_tipo, entidad_id);
CREATE INDEX idx_media_principal ON media_archivos(entidad_tipo, entidad_id, es_principal)
    WHERE es_principal = TRUE;


-- ************************************************************
-- CONSTRAINTS ADICIONALES DE INTEGRIDAD
-- Fuente: 16_REVISION_TECNICA.MD + validacion cruzada con docs
-- ************************************************************

-- [H1] UNIQUE en notas crédito/débito (SUNAT rechaza serie+numero duplicados)
ALTER TABLE notas_credito_debito
    ADD CONSTRAINT uq_notas_tipo_serie_numero UNIQUE(tipo_nota, serie, numero);

-- [H2] UNIQUE en correlativos (evita duplicados por concurrencia)
ALTER TABLE cotizaciones ADD CONSTRAINT uq_cotizaciones_numero UNIQUE(numero);
ALTER TABLE ordenes_venta ADD CONSTRAINT uq_ordenes_venta_numero UNIQUE(numero);
ALTER TABLE ventas ADD CONSTRAINT uq_ventas_numero UNIQUE(numero);
ALTER TABLE ordenes_compra ADD CONSTRAINT uq_ordenes_compra_numero UNIQUE(numero);

-- [H3] Cantidades positivas en tablas de detalle
ALTER TABLE detalle_cotizaciones ADD CONSTRAINT chk_dc_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_ordenes_venta ADD CONSTRAINT chk_dov_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_ventas ADD CONSTRAINT chk_dv_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_comprobantes ADD CONSTRAINT chk_dcomp_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_ordenes_compra ADD CONSTRAINT chk_doc_cantidad CHECK (cantidad > 0);
ALTER TABLE detalle_recepciones ADD CONSTRAINT chk_dr_cantidad CHECK (cantidad_recibida > 0);
ALTER TABLE movimientos_stock ADD CONSTRAINT chk_ms_cantidad CHECK (cantidad > 0);

-- [H4] Partida doble: debe y haber no pueden ser ambos > 0 en misma línea
--      (permite 0/0 para líneas informativas, pero no ambos positivos)
ALTER TABLE detalle_asientos ADD CONSTRAINT chk_partida_doble CHECK (
    debe >= 0 AND haber >= 0 AND NOT (debe > 0 AND haber > 0)
);

-- [H5] Stock no puede ser negativo
ALTER TABLE stock ADD CONSTRAINT chk_stock_no_negativo CHECK (cantidad >= 0);

-- [H6] Calificación de proveedores entre 1 y 5
ALTER TABLE proveedores ADD CONSTRAINT chk_calificacion CHECK (calificacion BETWEEN 1 AND 5);

-- [H7] Montos de cobros y pagos deben ser positivos
ALTER TABLE cobros ADD CONSTRAINT chk_cobro_monto CHECK (monto > 0);
ALTER TABLE pagos ADD CONSTRAINT chk_pago_monto CHECK (monto > 0);

-- [H8] Precios unitarios positivos en detalles
ALTER TABLE detalle_cotizaciones ADD CONSTRAINT chk_dc_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ordenes_venta ADD CONSTRAINT chk_dov_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ventas ADD CONSTRAINT chk_dv_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_comprobantes ADD CONSTRAINT chk_dcomp_precio CHECK (precio_unitario > 0);
ALTER TABLE detalle_ordenes_compra ADD CONSTRAINT chk_doc_precio CHECK (precio_unitario > 0);

-- [H9] Singleton: configuracion solo puede tener 1 fila
ALTER TABLE configuracion ADD COLUMN singleton BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE configuracion ADD CONSTRAINT uq_configuracion_singleton UNIQUE(singleton);
ALTER TABLE configuracion ADD CONSTRAINT chk_singleton CHECK (singleton = TRUE);

-- [H10] UNIQUE en pedidos y facturas proveedor
ALTER TABLE pedidos ADD CONSTRAINT uq_pedidos_numero UNIQUE(numero);
ALTER TABLE facturas_proveedor ADD CONSTRAINT uq_factura_prov UNIQUE(proveedor_id, numero_factura);

-- [H11] Documento único por cliente activo (permite re-registrar desactivados)
DROP INDEX IF EXISTS idx_clientes_documento;
CREATE UNIQUE INDEX idx_clientes_doc_unico
    ON clientes(tipo_documento, numero_documento)
    WHERE is_active = TRUE;


-- ************************************************************
-- INDICES ADICIONALES (88 índices)
-- PostgreSQL NO crea índices automáticos en columnas FK.
-- Sin estos índices, los JOINs, CASCADE deletes y queries
-- frecuentes hacen sequential scan en tablas grandes.
-- Organizados por módulo.
-- ************************************************************

-- ============================================================
-- USUARIOS Y RBAC
-- ============================================================

-- rol_permisos: FK indices (CASCADE deletes desde roles/permisos)
CREATE INDEX idx_rol_permisos_rol ON rol_permisos(rol_id);
CREATE INDEX idx_rol_permisos_permiso ON rol_permisos(permiso_id);

-- perfiles_usuario: FK a roles (listar usuarios por rol)
CREATE INDEX idx_perfiles_usuario_rol ON perfiles_usuario(rol_id);

-- log_actividad: FK + queries de auditoría
CREATE INDEX idx_log_actividad_usuario ON log_actividad(usuario_id);
CREATE INDEX idx_log_actividad_modulo_fecha ON log_actividad(modulo, created_at);
CREATE INDEX idx_log_actividad_fecha ON log_actividad(created_at);

-- ============================================================
-- CLIENTES
-- ============================================================

-- clientes: FK auditoría
CREATE INDEX idx_clientes_creado_por ON clientes(creado_por_id);
CREATE INDEX idx_clientes_segmento ON clientes(segmento);

-- ============================================================
-- PROVEEDORES
-- ============================================================

-- proveedores: búsqueda por razón social
CREATE INDEX idx_proveedores_razon_social ON proveedores(razon_social);

-- ============================================================
-- INVENTARIO
-- ============================================================

-- categorias: FK recursiva (listar subcategorías)
CREATE INDEX idx_categorias_padre ON categorias(categoria_padre_id);

-- productos: FK auditoría
CREATE INDEX idx_productos_creado_por ON productos(creado_por_id);

-- lotes: FK queries
CREATE INDEX idx_lotes_producto ON lotes(producto_id);
CREATE INDEX idx_lotes_almacen ON lotes(almacen_id);
CREATE INDEX idx_lotes_vencimiento ON lotes(fecha_vencimiento);

-- stock: FK queries (ya tiene UNIQUE(producto_id, almacen_id) que cubre producto_id)
CREATE INDEX idx_stock_almacen ON stock(almacen_id);

-- movimientos_stock: FK usuario
CREATE INDEX idx_mov_usuario ON movimientos_stock(usuario_id);
CREATE INDEX idx_mov_lote ON movimientos_stock(lote_id);
CREATE INDEX idx_mov_almacen_destino ON movimientos_stock(almacen_destino_id);

-- ============================================================
-- VENTAS
-- ============================================================

-- cotizaciones: FK + queries frecuentes
CREATE INDEX idx_cotizaciones_cliente ON cotizaciones(cliente_id);
CREATE INDEX idx_cotizaciones_vendedor ON cotizaciones(vendedor_id);
CREATE INDEX idx_cotizaciones_estado_fecha ON cotizaciones(estado, fecha_emision);
CREATE INDEX idx_cotizaciones_creado_por ON cotizaciones(creado_por_id);

-- detalle_cotizaciones: FK parent (CASCADE delete) + producto
CREATE INDEX idx_det_cotizaciones_cotizacion ON detalle_cotizaciones(cotizacion_id);
CREATE INDEX idx_det_cotizaciones_producto ON detalle_cotizaciones(producto_id);

-- ordenes_venta: FK + queries frecuentes
CREATE INDEX idx_ov_cliente ON ordenes_venta(cliente_id);
CREATE INDEX idx_ov_vendedor ON ordenes_venta(vendedor_id);
CREATE INDEX idx_ov_estado_fecha ON ordenes_venta(estado, fecha);
CREATE INDEX idx_ov_cotizacion_origen ON ordenes_venta(cotizacion_origen_id);
CREATE INDEX idx_ov_creado_por ON ordenes_venta(creado_por_id);

-- detalle_ordenes_venta: FK parent (CASCADE delete) + producto
CREATE INDEX idx_det_ov_orden ON detalle_ordenes_venta(orden_venta_id);
CREATE INDEX idx_det_ov_producto ON detalle_ordenes_venta(producto_id);

-- ventas: FK adicionales (cliente+fecha y vendedor+fecha ya existen)
CREATE INDEX idx_ventas_comprobante ON ventas(comprobante_id);
CREATE INDEX idx_ventas_orden_origen ON ventas(orden_origen_id);
CREATE INDEX idx_ventas_creado_por ON ventas(creado_por_id);

-- detalle_ventas: FK producto y lote (venta_id+producto_id ya existe)
CREATE INDEX idx_dv_producto ON detalle_ventas(producto_id);
CREATE INDEX idx_dv_lote ON detalle_ventas(lote_id);

-- ============================================================
-- FACTURACION ELECTRONICA
-- ============================================================

-- comprobantes: FK venta + auditoría
CREATE INDEX idx_comprobantes_venta ON comprobantes(venta_id);
CREATE INDEX idx_comprobantes_creado_por ON comprobantes(creado_por_id);
CREATE INDEX idx_comprobantes_tipo_fecha ON comprobantes(tipo_comprobante, fecha_emision);

-- detalle_comprobantes: FK parent (CASCADE delete)
CREATE INDEX idx_det_comprobantes_comprobante ON detalle_comprobantes(comprobante_id);

-- notas_credito_debito: FK + queries
CREATE INDEX idx_notas_cd_comprobante_origen ON notas_credito_debito(comprobante_origen_id);
CREATE INDEX idx_notas_cd_estado ON notas_credito_debito(estado_sunat);
CREATE INDEX idx_notas_cd_creado_por ON notas_credito_debito(creado_por_id);

-- log_envio_nubefact: FK comprobante
CREATE INDEX idx_log_nubefact_comprobante ON log_envio_nubefact(comprobante_id);
CREATE INDEX idx_log_nubefact_fecha ON log_envio_nubefact(fecha_envio);

-- ============================================================
-- COMPRAS
-- ============================================================

-- ordenes_compra: FK + queries
CREATE INDEX idx_oc_proveedor ON ordenes_compra(proveedor_id);
CREATE INDEX idx_oc_estado_fecha ON ordenes_compra(estado, fecha);
CREATE INDEX idx_oc_almacen_destino ON ordenes_compra(almacen_destino_id);
CREATE INDEX idx_oc_creado_por ON ordenes_compra(creado_por_id);

-- detalle_ordenes_compra: FK parent (CASCADE delete) + producto
CREATE INDEX idx_det_oc_orden ON detalle_ordenes_compra(orden_compra_id);
CREATE INDEX idx_det_oc_producto ON detalle_ordenes_compra(producto_id);

-- facturas_proveedor: FK + queries
CREATE INDEX idx_fp_proveedor ON facturas_proveedor(proveedor_id);
CREATE INDEX idx_fp_orden_compra ON facturas_proveedor(orden_compra_id);
CREATE INDEX idx_fp_estado ON facturas_proveedor(estado);

-- recepciones: FK
CREATE INDEX idx_recepciones_orden_compra ON recepciones(orden_compra_id);
CREATE INDEX idx_recepciones_almacen ON recepciones(almacen_id);

-- detalle_recepciones: FK parent (CASCADE delete) + FKs
CREATE INDEX idx_det_recepciones_recepcion ON detalle_recepciones(recepcion_id);
CREATE INDEX idx_det_recepciones_det_oc ON detalle_recepciones(detalle_orden_compra_id);
CREATE INDEX idx_det_recepciones_producto ON detalle_recepciones(producto_id);

-- ============================================================
-- FINANZAS
-- ============================================================

-- cuentas_por_cobrar: FK + queries de cobranza
CREATE INDEX idx_cxc_cliente ON cuentas_por_cobrar(cliente_id);
CREATE INDEX idx_cxc_estado_vencimiento ON cuentas_por_cobrar(estado, fecha_vencimiento);
CREATE INDEX idx_cxc_comprobante ON cuentas_por_cobrar(comprobante_id);

-- cuentas_por_pagar: FK + queries de pagos
CREATE INDEX idx_cxp_proveedor ON cuentas_por_pagar(proveedor_id);
CREATE INDEX idx_cxp_estado_vencimiento ON cuentas_por_pagar(estado, fecha_vencimiento);
CREATE INDEX idx_cxp_factura ON cuentas_por_pagar(factura_proveedor_id);

-- cobros: FK
CREATE INDEX idx_cobros_cxc ON cobros(cuenta_por_cobrar_id);
CREATE INDEX idx_cobros_fecha ON cobros(fecha);

-- pagos: FK
CREATE INDEX idx_pagos_cxp ON pagos(cuenta_por_pagar_id);
CREATE INDEX idx_pagos_fecha ON pagos(fecha);

-- cuentas_contables: FK recursiva
CREATE INDEX idx_cc_padre ON cuentas_contables(cuenta_padre_id);
CREATE INDEX idx_cc_tipo ON cuentas_contables(tipo);

-- asientos_contables: queries
CREATE INDEX idx_asientos_fecha ON asientos_contables(fecha);
CREATE INDEX idx_asientos_estado ON asientos_contables(estado);
CREATE INDEX idx_asientos_creado_por ON asientos_contables(creado_por_id);

-- detalle_asientos: FK (libro mayor query = la más crítica)
CREATE INDEX idx_det_asientos_asiento ON detalle_asientos(asiento_id);
CREATE INDEX idx_det_asientos_cuenta ON detalle_asientos(cuenta_contable_id);

-- ============================================================
-- DISTRIBUCION
-- ============================================================

-- pedidos: FK + queries
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_transportista ON pedidos(transportista_id);
CREATE INDEX idx_pedidos_estado_fecha ON pedidos(estado, fecha);
CREATE INDEX idx_pedidos_venta ON pedidos(venta_id);

-- seguimiento_pedidos: FK parent (CASCADE delete)
CREATE INDEX idx_seguimiento_pedido ON seguimiento_pedidos(pedido_id);

-- evidencias_entrega: FK parent (CASCADE delete)
CREATE INDEX idx_evidencias_pedido ON evidencias_entrega(pedido_id);

-- ============================================================
-- WHATSAPP
-- ============================================================

-- whatsapp_mensajes: FK + queries
CREATE INDEX idx_wa_mensajes_plantilla ON whatsapp_mensajes(plantilla_id);
CREATE INDEX idx_wa_mensajes_cliente ON whatsapp_mensajes(cliente_id);
CREATE INDEX idx_wa_mensajes_estado ON whatsapp_mensajes(estado);
CREATE INDEX idx_wa_mensajes_ref ON whatsapp_mensajes(referencia_tipo, referencia_id);

-- whatsapp_log: FK parent (CASCADE delete)
CREATE INDEX idx_wa_log_mensaje ON whatsapp_log(mensaje_id);

-- ============================================================
-- MEDIA
-- ============================================================

-- media_archivos: FK auditoría (entidad indices ya existen)
CREATE INDEX idx_media_subido_por ON media_archivos(subido_por_id);