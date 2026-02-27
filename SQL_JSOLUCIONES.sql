-- ============================================================
-- JSOLUCIONES ERP — SQL Completo v4
-- PostgreSQL 16 | UUID nativo | ENUMs nativos | 65 tablas | 130+ índices
-- Sincronizado con Django migrations: Amatista-BE v2025-02-26
-- ============================================================
-- CAMBIOS PRINCIPALES:
--   ✓ Usuarios: TOTP 2FA, sesiones_activas, notificaciones
--   ✓ Empresa: Encriptación Fernet (credenciales), WSDL SOAP, cert .pfx
--   ✓ Inventario: series (control de serialización), ubicaciones, transferencias
--   ✓ Compras: gastos_logisticos, evaluaciones_proveedor
--   ✓ Ventas: estado_produccion (kanban), cajas, comisiones_vendedor
--   ✓ Facturación: R2 keys (PDF/XML/CDR), resumen_diario_sunat
--   ✓ Finanzas: períodos_contables, conciliaciones_bancarias
--   ✓ Distribución: GPS tracking, código_seguimiento, estado_producción
--   ✓ Reportes: snapshots_kpi, programaciones_reporte
--   ✓ WhatsApp: singleton config, campañas, automatizaciones
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

-- 34. Estado de caja POS
CREATE TYPE enum_estado_caja AS ENUM ('abierta','cerrada');

-- 35. Estado de solicitud de transferencia
CREATE TYPE enum_estado_transferencia AS ENUM (
    'pendiente','aprobada','en_transito','completada','rechazada'
);

-- 36. Estado de resumen diario SUNAT
CREATE TYPE enum_estado_resumen_diario AS ENUM (
    'pendiente','enviado','aceptado','rechazado'
);


-- ************************************************************
-- 1. CONFIGURACIÓN (1 tabla)
-- ************************************************************

CREATE TABLE configuracion (
    id                          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    ruc                         VARCHAR(11)   NOT NULL UNIQUE,
    razon_social                VARCHAR(200)  NOT NULL,
    nombre_comercial            VARCHAR(200)  NOT NULL DEFAULT '',
    direccion                   TEXT          NOT NULL DEFAULT '',
    ubigeo                      VARCHAR(6)    NOT NULL DEFAULT '',
    departamento                VARCHAR(50)   NOT NULL DEFAULT '',
    provincia                   VARCHAR(50)   NOT NULL DEFAULT '',
    distrito                    VARCHAR(50)   NOT NULL DEFAULT '',
    telefono                    VARCHAR(20)   NOT NULL DEFAULT '',
    email                       VARCHAR(254)  NOT NULL DEFAULT '',
    logo                        VARCHAR(200),
    logo_media_id               UUID          REFERENCES media_archivos(id) ON DELETE SET_NULL,
    -- Nubefact: Encriptado con Fernet (no almacenar en texto plano)
    nubefact_token              VARCHAR(200)  NOT NULL DEFAULT '',
    nubefact_url_password       VARCHAR(200)  NOT NULL DEFAULT '',
    nubefact_wsdl               VARCHAR(500)  NOT NULL DEFAULT 'https://api.nubefact.com/api/v1/',
    -- Certificado .pfx para firma digital (encriptado)
    cert_pfx_path               VARCHAR(500)  NOT NULL DEFAULT '',
    cert_pfx_password           VARCHAR(200)  NOT NULL DEFAULT '',
    -- Modo contingencia (emisión offline)
    modo_contingencia           BOOLEAN       NOT NULL DEFAULT FALSE,
    contingencia_activada_at    TIMESTAMPTZ,
    moneda_principal            enum_moneda   NOT NULL DEFAULT 'PEN',
    igv_porcentaje              DECIMAL(5,2)  NOT NULL DEFAULT 18.00,
    singleton                   BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(singleton)
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
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id              UUID          NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    rol_id                  UUID          NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    telefono                VARCHAR(20)   NOT NULL DEFAULT '',
    avatar                  VARCHAR(200),
    is_active               BOOLEAN       NOT NULL DEFAULT TRUE,
    password_changed_at     TIMESTAMPTZ,
    totp_secret             VARCHAR(64)   NOT NULL DEFAULT '',
    totp_enabled            BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_perfiles_usuario_rol ON perfiles_usuario(rol_id);

CREATE TABLE log_actividad (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    accion          VARCHAR(50)   NOT NULL,
    modulo          VARCHAR(30)   NOT NULL DEFAULT '',
    detalle         TEXT          NOT NULL DEFAULT '',
    ip_address      VARCHAR(45)   NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_log_actividad_usuario ON log_actividad(usuario_id);
CREATE INDEX idx_log_actividad_modulo_fecha ON log_actividad(modulo, created_at);
CREATE INDEX idx_log_actividad_fecha ON log_actividad(created_at);

-- Sesiones activas (JWT tracking)
CREATE TABLE sesiones_activas (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    jti             VARCHAR(64)   NOT NULL UNIQUE,
    ip_address      VARCHAR(45)   NOT NULL DEFAULT '',
    user_agent      VARCHAR(300)  NOT NULL DEFAULT '',
    activo          BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ   NOT NULL
);

CREATE INDEX idx_sesiones_activas_usuario_activo ON sesiones_activas(usuario_id, activo);

-- Notificaciones del sistema
CREATE TABLE notificaciones (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    tipo            VARCHAR(30)   NOT NULL,
    titulo          VARCHAR(200)  NOT NULL,
    mensaje         TEXT          NOT NULL,
    leida           BOOLEAN       NOT NULL DEFAULT FALSE,
    referencia_tipo VARCHAR(50)   NOT NULL DEFAULT '',
    referencia_id   UUID,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notificaciones_usuario_leida ON notificaciones(usuario_id, leida);
CREATE INDEX idx_notificaciones_usuario_fecha ON notificaciones(usuario_id, created_at);


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
    categoria_id          UUID          REFERENCES categorias(id) ON DELETE SET_NULL,
    unidad_medida         enum_unidad_medida NOT NULL DEFAULT 'NIU',
    precio_compra         DECIMAL(12,4) NOT NULL DEFAULT 0,
    precio_venta          DECIMAL(12,4) NOT NULL,
    codigo_afectacion_igv enum_afectacion_igv NOT NULL DEFAULT '10',
    stock_minimo          DECIMAL(12,2) NOT NULL DEFAULT 0,
    stock_maximo          DECIMAL(12,2) NOT NULL DEFAULT 0,
    requiere_lote         BOOLEAN       NOT NULL DEFAULT FALSE,
    requiere_serie        BOOLEAN       NOT NULL DEFAULT FALSE,
    is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    actualizado_por_id    UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL
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

CREATE INDEX idx_lotes_producto_almacen ON lotes(producto_id, almacen_id);
CREATE INDEX idx_lotes_fecha_vencimiento ON lotes(fecha_vencimiento);

-- Números de serie (para productos que requieren serialización)
CREATE TABLE series (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id     UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    numero_serie    VARCHAR(100)  NOT NULL,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'DISPONIBLE',
    almacen_id      UUID          REFERENCES almacenes(id) ON DELETE SET_NULL,
    referencia_tipo VARCHAR(30)   NOT NULL DEFAULT '',
    referencia_id   UUID,
    observaciones   TEXT          NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(producto_id, numero_serie)
);

CREATE INDEX idx_series_numero_serie ON series(numero_serie);
CREATE INDEX idx_series_producto_estado ON series(producto_id, estado);

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

-- Ubicaciones dentro de almacenes (zona/pasillo/estante/nivel)
CREATE TABLE ubicaciones_almacen (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    almacen_id      UUID          NOT NULL REFERENCES almacenes(id) ON DELETE CASCADE,
    codigo          VARCHAR(30)   NOT NULL,
    zona            VARCHAR(50)   NOT NULL DEFAULT '',
    pasillo         VARCHAR(20)   NOT NULL DEFAULT '',
    estante         VARCHAR(20)   NOT NULL DEFAULT '',
    nivel           VARCHAR(20)   NOT NULL DEFAULT '',
    descripcion     TEXT          NOT NULL DEFAULT '',
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(almacen_id, codigo)
);

CREATE INDEX idx_ubic_almacen_zona ON ubicaciones_almacen(almacen_id, zona);

-- Solicitudes de transferencia entre almacenes
CREATE TABLE transferencias (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero              VARCHAR(20)   NOT NULL UNIQUE,
    almacen_origen_id   UUID          NOT NULL REFERENCES almacenes(id) ON DELETE RESTRICT,
    almacen_destino_id  UUID          NOT NULL REFERENCES almacenes(id) ON DELETE RESTRICT,
    estado              enum_estado_transferencia NOT NULL DEFAULT 'pendiente',
    motivo              TEXT          NOT NULL DEFAULT '',
    fecha_solicitud     DATE          NOT NULL DEFAULT CURRENT_DATE,
    fecha_aprobacion    DATE,
    fecha_completado    DATE,
    solicitado_por_id   UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE RESTRICT,
    aprobado_por_id     UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transf_estado ON transferencias(estado);
CREATE INDEX idx_transf_origen ON transferencias(almacen_origen_id);
CREATE INDEX idx_transf_destino ON transferencias(almacen_destino_id);

-- Detalle de solicitud de transferencia
CREATE TABLE detalle_transferencia (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    transferencia_id        UUID          NOT NULL REFERENCES transferencias(id) ON DELETE CASCADE,
    producto_id             UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad_solicitada     DECIMAL(12,2) NOT NULL,
    cantidad_enviada        DECIMAL(12,2) NOT NULL DEFAULT 0,
    cantidad_recibida       DECIMAL(12,2) NOT NULL DEFAULT 0,
    lote_id                 UUID          REFERENCES lotes(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_det_transf_transferencia ON detalle_transferencia(transferencia_id);
CREATE INDEX idx_det_transf_producto ON detalle_transferencia(producto_id);


-- ************************************************************
-- 6. VENTAS (6 tablas + cajas + formas_pago)
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
    id                          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    venta_id                    UUID          NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
    producto_id                 UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    cantidad                    DECIMAL(12,2) NOT NULL,
    precio_unitario             DECIMAL(12,4) NOT NULL,
    descuento_porcentaje        DECIMAL(5,2)  NOT NULL DEFAULT 0,
    subtotal                    DECIMAL(12,2) NOT NULL,
    igv                         DECIMAL(12,2) NOT NULL,
    total                       DECIMAL(12,2) NOT NULL,
    lote_id                     UUID          REFERENCES lotes(id) ON DELETE SET_NULL,
    estado_produccion           VARCHAR(20)   NOT NULL DEFAULT 'PENDIENTE',
    produccion_iniciada_en      TIMESTAMPTZ,
    produccion_completada_en    TIMESTAMPTZ,
    created_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dv_venta_producto ON detalle_ventas(venta_id, producto_id);
CREATE INDEX idx_dv_estado_produccion ON detalle_ventas(estado_produccion);

-- Cajas POS
CREATE TABLE cajas (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre              VARCHAR(50)   NOT NULL,
    sucursal            VARCHAR(100)  NOT NULL DEFAULT '',
    estado              enum_estado_caja NOT NULL DEFAULT 'abierta',
    monto_apertura      DECIMAL(12,2) NOT NULL DEFAULT 0,
    monto_cierre        DECIMAL(12,2),
    monto_esperado      DECIMAL(12,2),
    diferencia          DECIMAL(12,2),
    fecha_apertura      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_cierre        TIMESTAMPTZ,
    abierta_por_id      UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE RESTRICT,
    cerrada_por_id      UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    observaciones       TEXT          NOT NULL DEFAULT '',
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cajas_estado ON cajas(estado);
CREATE INDEX idx_cajas_fecha_apertura ON cajas(fecha_apertura);

-- Formas de pago (multi-pago por venta)
CREATE TABLE formas_pago (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    venta_id            UUID          NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
    metodo_pago         enum_metodo_pago NOT NULL DEFAULT 'efectivo',
    monto               DECIMAL(12,2) NOT NULL,
    referencia          VARCHAR(100)  NOT NULL DEFAULT '',
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_formas_pago_venta ON formas_pago(venta_id);

-- Comisiones de vendedores
CREATE TABLE comisiones_vendedor (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    vendedor_id         UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE RESTRICT,
    periodo             VARCHAR(7)    NOT NULL,
    porcentaje          DECIMAL(5,2)  NOT NULL DEFAULT 5,
    total_ventas        DECIMAL(14,2) NOT NULL DEFAULT 0,
    monto_comision      DECIMAL(14,2) NOT NULL DEFAULT 0,
    cantidad_ventas     INTEGER       NOT NULL DEFAULT 0,
    pagado              BOOLEAN       NOT NULL DEFAULT FALSE,
    fecha_pago          DATE,
    notas               TEXT          NOT NULL DEFAULT '',
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(vendedor_id, periodo)
);


-- ************************************************************
-- 7. FACTURACIÓN ELECTRÓNICA (5 tablas + resumen_diario)
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
    pdf_r2_key          VARCHAR(500)  NOT NULL DEFAULT '',
    xml_r2_key          TEXT          NOT NULL DEFAULT '',
    cdr_r2_key          TEXT          NOT NULL DEFAULT '',
    hash_sunat          TEXT          NOT NULL DEFAULT '',
    qr_sunat            TEXT          NOT NULL DEFAULT '',
    nubefact_request    JSONB,
    nubefact_response   JSONB,
    modo_emision        enum_modo_emision NOT NULL DEFAULT 'normal',
    venta_id            UUID          REFERENCES ventas(id) ON DELETE SET_NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
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
    motivo_codigo_nc      enum_motivo_nota_credito,
    motivo_codigo_nd      enum_motivo_nota_debito,
    motivo_descripcion    TEXT          NOT NULL DEFAULT '',
    total_gravada         DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv             DECIMAL(12,2) NOT NULL DEFAULT 0,
    total                 DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_sunat          enum_estado_comprobante NOT NULL DEFAULT 'pendiente',
    pdf_r2_key            VARCHAR(500)  NOT NULL DEFAULT '',
    xml_r2_key            TEXT          NOT NULL DEFAULT '',
    cdr_r2_key            TEXT          NOT NULL DEFAULT '',
    nubefact_request      JSONB,
    nubefact_response     JSONB,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
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

-- Resumen diario de boletas para SUNAT
CREATE TABLE resumen_diario (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_generacion    DATE          NOT NULL,
    fecha_resumen       DATE          NOT NULL,
    identificador       VARCHAR(30)   NOT NULL UNIQUE,
    total_boletas       INTEGER       NOT NULL DEFAULT 0,
    total_gravada       DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_igv           DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_monto         DECIMAL(14,2) NOT NULL DEFAULT 0,
    estado              enum_estado_resumen_diario NOT NULL DEFAULT 'pendiente',
    ticket_sunat        VARCHAR(100)  NOT NULL DEFAULT '',
    nubefact_request    JSONB,
    nubefact_response   JSONB,
    generado_por_id     UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_resumen_fecha_estado ON resumen_diario(fecha_resumen, estado);


-- ************************************************************
-- 8. COMPRAS (5 tablas)
-- ************************************************************

CREATE TABLE ordenes_compra (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero                VARCHAR(20)   NOT NULL UNIQUE,
    fecha                 DATE          NOT NULL,
    fecha_estimada_entrega DATE,
    proveedor_id          UUID          NOT NULL REFERENCES proveedores(id) ON DELETE RESTRICT,
    estado                enum_estado_orden_compra NOT NULL DEFAULT 'borrador',
    almacen_destino_id    UUID          NOT NULL REFERENCES almacenes(id) ON DELETE RESTRICT,
    moneda                enum_moneda   NOT NULL DEFAULT 'PEN',
    total_base            DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_igv             DECIMAL(12,2) NOT NULL DEFAULT 0,
    gastos_logisticos     DECIMAL(12,2) NOT NULL DEFAULT 0,
    total                 DECIMAL(12,2) NOT NULL DEFAULT 0,
    notas                 TEXT          NOT NULL DEFAULT '',
    aprobado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    creado_por_id         UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL
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
    orden_compra_id     UUID          REFERENCES ordenes_compra(id) ON DELETE SET_NULL,
    estado              enum_estado_factura_proveedor NOT NULL DEFAULT 'registrada',
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(numero_factura, proveedor_id) WHERE is_active = TRUE
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
    lote_id                  UUID          REFERENCES lotes(id) ON DELETE SET_NULL,
    observaciones            TEXT          NOT NULL DEFAULT '',
    created_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Evaluaciones de desempeño de proveedores
CREATE TABLE evaluaciones_proveedor (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id            UUID          NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    periodo_inicio          DATE          NOT NULL,
    periodo_fin             DATE          NOT NULL,
    pct_entrega_a_tiempo    DECIMAL(5,2)  NOT NULL DEFAULT 0,
    pct_cantidad_completa   DECIMAL(5,2)  NOT NULL DEFAULT 0,
    pct_calidad             DECIMAL(5,2)  NOT NULL DEFAULT 100,
    total_ordenes           INTEGER       NOT NULL DEFAULT 0,
    total_recibidas         INTEGER       NOT NULL DEFAULT 0,
    puntaje_global          DECIMAL(5,2)  NOT NULL DEFAULT 0,
    notas                   TEXT          NOT NULL DEFAULT '',
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(proveedor_id, periodo_inicio, periodo_fin)
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
    descripcion         VARCHAR(500)  NOT NULL DEFAULT '',
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_asientos_fecha_estado ON asientos_contables(fecha, estado);

-- Períodos contables (mensual)
CREATE TABLE periodos_contables (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    anio            INTEGER       NOT NULL,
    mes             INTEGER       NOT NULL,
    cerrado         BOOLEAN       NOT NULL DEFAULT FALSE,
    cerrado_por_id  UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    cerrado_at      TIMESTAMPTZ,
    notas           TEXT          NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(anio, mes)
);

-- Conciliaciones bancarias
CREATE TABLE conciliaciones_bancarias (
    id                      UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_cuenta           VARCHAR(150)  NOT NULL,
    periodo                 VARCHAR(7)    NOT NULL,
    saldo_segun_banco       DECIMAL(14,2) NOT NULL,
    saldo_segun_sistema     DECIMAL(14,2) NOT NULL DEFAULT 0,
    diferencia              DECIMAL(14,2) NOT NULL DEFAULT 0,
    estado                  VARCHAR(20)   NOT NULL DEFAULT 'PENDIENTE',
    notas                   TEXT          NOT NULL DEFAULT '',
    creado_por_id           UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    created_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conciliaciones_periodo_estado ON conciliaciones_bancarias(periodo, estado);

-- Movimientos bancarios para conciliación
CREATE TABLE movimientos_bancarios (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    conciliacion_id     UUID          NOT NULL REFERENCES conciliaciones_bancarias(id) ON DELETE CASCADE,
    fecha               DATE          NOT NULL,
    descripcion         VARCHAR(300)  NOT NULL,
    tipo                VARCHAR(10)   NOT NULL DEFAULT 'INGRESO',
    monto               DECIMAL(12,2) NOT NULL,
    referencia          VARCHAR(100)  NOT NULL DEFAULT '',
    cobro_id            UUID          REFERENCES cobros(id) ON DELETE SET_NULL,
    pago_id             UUID          REFERENCES pagos(id) ON DELETE SET_NULL,
    conciliado          BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_movimientos_bancarios_conciliado ON movimientos_bancarios(conciliado);


-- ************************************************************
-- 10. DISTRIBUCIÓN (4 tablas)
-- ************************************************************

CREATE TABLE transportistas (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                VARCHAR(200)  NOT NULL,
    telefono              VARCHAR(20)   NOT NULL DEFAULT '',
    email                 VARCHAR(254)  NOT NULL DEFAULT '',
    tipo_vehiculo         VARCHAR(50)   NOT NULL DEFAULT '',
    placa                 VARCHAR(20)   NOT NULL DEFAULT '',
    limite_pedidos_diario INTEGER       NOT NULL DEFAULT 20,
    is_active             BOOLEAN       NOT NULL DEFAULT TRUE,
    token                 UUID          NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    last_lat              DECIMAL(10,8),
    last_lng              DECIMAL(10,8),
    last_location_at      TIMESTAMPTZ,
    preferencia_zona      VARCHAR(200)  NOT NULL DEFAULT '',
    tipo_transportista    VARCHAR(20)   NOT NULL DEFAULT 'propio',
    app_nombre            VARCHAR(50)   NOT NULL DEFAULT '',
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE pedidos (
    id                          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    numero                      VARCHAR(20)   NOT NULL,
    codigo_seguimiento          VARCHAR(8)    NOT NULL UNIQUE,
    fecha                       DATE          NOT NULL,
    venta_id                    UUID          REFERENCES ventas(id) ON DELETE SET NULL,
    cliente_id                  UUID          NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    direccion_entrega           TEXT,
    latitud                     DECIMAL(10,7),
    longitud                    DECIMAL(10,7),
    estado                      VARCHAR(20)   NOT NULL DEFAULT 'PENDIENTE',
    transportista_id            UUID          REFERENCES transportistas(id) ON DELETE SET NULL,
    fecha_estimada_entrega      TIMESTAMPTZ,
    fecha_entrega_real          TIMESTAMPTZ,
    notas                       TEXT          NOT NULL DEFAULT '',
    prioridad                   VARCHAR(20)   NOT NULL DEFAULT 'NORMAL',
    nombre_destinatario         VARCHAR(200)  NOT NULL DEFAULT '',
    telefono_destinatario       VARCHAR(20)   NOT NULL DEFAULT '',
    turno_entrega               VARCHAR(10),
    turno_express_rango         VARCHAR(50),
    costo_delivery              DECIMAL(10,2) NOT NULL DEFAULT 0,
    enlace_ubicacion            VARCHAR(500),
    es_urgente                  BOOLEAN       NOT NULL DEFAULT FALSE,
    fecha_pedido                DATE,
    dedicatoria                 TEXT          NOT NULL DEFAULT '',
    foto_entrega                VARCHAR(500),
    observacion_conductor       TEXT          NOT NULL DEFAULT '',
    fecha_confirmacion          TIMESTAMPTZ,
    estado_produccion           VARCHAR(20)   NOT NULL DEFAULT 'PENDIENTE',
    produccion_iniciada_en      TIMESTAMPTZ,
    produccion_completada_en    TIMESTAMPTZ,
    creado_por_id               UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    is_active                   BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pedidos_estado_fecha ON pedidos(estado, fecha);
CREATE INDEX idx_pedidos_transportista_fecha ON pedidos(transportista_id, fecha);
CREATE INDEX idx_pedidos_codigo_seguimiento ON pedidos(codigo_seguimiento);

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
    media_id        UUID          REFERENCES media_archivos(id) ON DELETE SET_NULL,
    codigo_otp      VARCHAR(6),
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_evidencias_media ON evidencias_entrega(media_id);


-- ************************************************************
-- 11. WHATSAPP (4 tablas)
-- ************************************************************

CREATE TABLE whatsapp_configuracion (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number_id     VARCHAR(50)   NOT NULL DEFAULT '',
    waba_id             VARCHAR(50)   NOT NULL DEFAULT '',
    access_token        TEXT          NOT NULL DEFAULT '',
    webhook_verify_token VARCHAR(100) NOT NULL DEFAULT '',
    activo              BOOLEAN       NOT NULL DEFAULT FALSE,
    singleton_lock      INTEGER       NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(singleton_lock)
);

CREATE TABLE whatsapp_plantillas (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre              VARCHAR(100)  NOT NULL UNIQUE,
    categoria           VARCHAR(20)   NOT NULL DEFAULT 'TRANSACCIONAL',
    idioma              VARCHAR(10)   NOT NULL DEFAULT 'es',
    contenido           TEXT          NOT NULL,
    estado_meta         VARCHAR(20)   NOT NULL DEFAULT 'EN_REVISION',
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE whatsapp_mensajes (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    plantilla_id        UUID          REFERENCES whatsapp_plantillas(id) ON DELETE SET_NULL,
    destinatario        VARCHAR(20)   NOT NULL,
    nombre_destinatario VARCHAR(200)  NOT NULL DEFAULT '',
    contenido           TEXT,
    parametros          JSONB         NOT NULL DEFAULT '{}',
    estado              VARCHAR(20)   NOT NULL DEFAULT 'EN_ESPERA',
    wa_message_id       VARCHAR(100)  NOT NULL DEFAULT '',
    referencia_tipo     VARCHAR(50)   NOT NULL DEFAULT '',
    referencia_id       UUID,
    error_detalle       TEXT          NOT NULL DEFAULT '',
    enviado_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE whatsapp_log (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    evento          VARCHAR(50)   NOT NULL,
    payload         JSONB         NOT NULL DEFAULT '{}',
    wa_message_id   VARCHAR(100)  NOT NULL DEFAULT '',
    procesado       BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Campañas de WhatsApp
CREATE TABLE whatsapp_campanas (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre              VARCHAR(200)  NOT NULL,
    plantilla_id        UUID          REFERENCES whatsapp_plantillas(id) ON DELETE SET_NULL,
    segmento            VARCHAR(100)  NOT NULL DEFAULT '',
    estado              VARCHAR(20)   NOT NULL DEFAULT 'BORRADOR',
    total_contactos     INTEGER       NOT NULL DEFAULT 0,
    mensajes_encolados  INTEGER       NOT NULL DEFAULT 0,
    programado_para     TIMESTAMPTZ,
    creado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Automatizaciones de WhatsApp (e.g., confirmación de venta, recordatorio de pago)
CREATE TABLE whatsapp_automatizaciones (
    id                  VARCHAR(50)   PRIMARY KEY,
    evento              VARCHAR(50)   NOT NULL UNIQUE,
    plantilla_id        UUID          REFERENCES whatsapp_plantillas(id) ON DELETE SET_NULL,
    activo              BOOLEAN       NOT NULL DEFAULT FALSE,
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
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
-- 13. REPORTES (3 tablas)
-- ************************************************************

-- Snapshots de KPIs (para gráficos históricos)
CREATE TABLE snapshots_kpi (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha           DATE          NOT NULL,
    hora            TIME          NOT NULL,
    datos           JSONB         NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_snapshots_kpi_fecha_hora ON snapshots_kpi(fecha, hora);

-- Programaciones de reportes (automáticos)
CREATE TABLE programaciones_reporte (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre              VARCHAR(200)  NOT NULL,
    tipo_reporte        VARCHAR(30)   NOT NULL,
    formato             VARCHAR(10)   NOT NULL DEFAULT 'excel',
    frecuencia          VARCHAR(20)   NOT NULL,
    hora_envio          TIME          NOT NULL,
    dia_semana          INTEGER,
    dia_mes             INTEGER,
    emails              JSONB         NOT NULL DEFAULT '[]',
    activo              BOOLEAN       NOT NULL DEFAULT TRUE,
    creado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET_NULL,
    ultima_ejecucion    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Configuración global de KPIs (Singleton)
CREATE TABLE configuracion_kpi (
    id                              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    ventas_diarias_umbral_verde     FLOAT         NOT NULL DEFAULT 10000.0,
    ventas_diarias_umbral_amarillo  FLOAT         NOT NULL DEFAULT 5000.0,
    stock_bajo_umbral               FLOAT         NOT NULL DEFAULT 10.0,
    singleton_lock                  INTEGER       NOT NULL DEFAULT 1,
    updated_at                      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(singleton_lock)
);


-- ************************************************************
-- CONSTRAINTS ADICIONALES DE INTEGRIDAD
-- Fuente: 16_REVISION_TECNICA.MD + validacion cruzada con docs
-- ************************************************************

-- [H1] UNIQUE: ya definidos en CREATE TABLE
--      notas_credito_debito, cotizaciones, ordenes_venta, ventas, ordenes_compra,
--      comprobantes, series_comprobante, clientes, facturas_proveedor

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

-- [H9] Singleton: configuracion, whatsapp_configuracion, configuracion_kpi
--      Ya definidos en CREATE TABLE con UNIQUE(singleton_lock)

-- [H10] UNIQUE: pedidos, facturas_proveedor
--      Ya definidos en CREATE TABLE

-- [H11] Documento único por cliente activo (permite re-registrar desactivados)
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


-- ============================================================
-- ACTUALIZACIONES POST-v3
-- Sincronizado con migrations Django — generado 2026-02-23
-- ============================================================


-- ************************************************************
-- [UPD-1] EVALUACIONES DE PROVEEDOR (nueva tabla)
-- Fuente: compras/0004_add_evaluacion_proveedor (2026-02-22)
-- ************************************************************

CREATE TABLE evaluaciones_proveedor (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id          UUID          NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    periodo_inicio        DATE          NOT NULL,
    periodo_fin           DATE          NOT NULL,
    pct_entrega_a_tiempo  DECIMAL(5,2)  NOT NULL DEFAULT 0,
    pct_cantidad_completa DECIMAL(5,2)  NOT NULL DEFAULT 0,
    pct_calidad           DECIMAL(5,2)  NOT NULL DEFAULT 100,
    total_ordenes         INTEGER       NOT NULL DEFAULT 0,
    total_recibidas       INTEGER       NOT NULL DEFAULT 0,
    puntaje_global        DECIMAL(5,2)  NOT NULL DEFAULT 0,   -- 40% entrega + 30% cantidad + 30% calidad
    notas                 TEXT          NOT NULL DEFAULT '',
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_evaluacion_proveedor_periodo UNIQUE(proveedor_id, periodo_inicio, periodo_fin)
);

CREATE INDEX idx_eval_proveedor ON evaluaciones_proveedor(proveedor_id);
CREATE INDEX idx_eval_periodo ON evaluaciones_proveedor(periodo_fin DESC);


-- ************************************************************
-- [UPD-2] GASTOS LOGÍSTICOS EN ÓRDENES DE COMPRA
-- Fuente: compras/0005_add_gastos_logisticos_oc (2026-02-22)
-- ************************************************************

ALTER TABLE ordenes_compra
    ADD COLUMN gastos_logisticos DECIMAL(12,2) NOT NULL DEFAULT 0;
-- Ayuda: flete, seguro, etc. prorrateado entre items de la OC.


-- ************************************************************
-- [UPD-3] is_active EN PEDIDOS
-- Fuente: distribucion/0003_add_is_active_pedidos
-- ************************************************************

ALTER TABLE pedidos
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;


-- ************************************************************
-- [UPD-4] CÓDIGO DE SEGUIMIENTO EN PEDIDOS
-- Fuente: distribucion/0004_add_codigo_seguimiento_to_pedido (2026-02-21)
-- ************************************************************

ALTER TABLE pedidos
    ADD COLUMN codigo_seguimiento VARCHAR(8) NOT NULL DEFAULT '';

CREATE UNIQUE INDEX idx_ped_codigo_seg ON pedidos(codigo_seguimiento);
-- Nota: el backend genera un código aleatorio de 8 chars al crear el pedido.
-- Se expone como tracking público sin autenticación.


-- ************************************************************
-- [UPD-5] LOGO MEDIA FK EN CONFIGURACIÓN
-- Fuente: empresa/0002_r2_v2_integracion (2026-02-20)
-- ************************************************************

ALTER TABLE configuracion
    ADD COLUMN logo_media_id UUID REFERENCES media_archivos(id) ON DELETE SET NULL;
-- Nota: columna `logo` (VARCHAR) queda como legacy. Usar logo_media_id en adelante.


-- ************************************************************
-- [UPD-6] MODO CONTINGENCIA EN CONFIGURACIÓN
-- Fuente: empresa/0003_add_modo_contingencia (2026-02-21)
-- ************************************************************

ALTER TABLE configuracion
    ADD COLUMN modo_contingencia       BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN contingencia_activada_at TIMESTAMPTZ;
-- Si modo_contingencia=TRUE, los comprobantes se generan sin enviar a Nubefact.


-- ************************************************************
-- [UPD-7] VALOR 'error_permanente' EN ENUM ESTADO COMPROBANTE
-- Fuente: facturacion/0005 + 0006 (2026-02-21)
-- Nota: en DB Django (VARCHAR), el choice ya existe en el modelo.
--       En DB con ENUMs nativos PostgreSQL (este SQL) se debe agregar así:
-- ************************************************************

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enum_estado_comprobante') THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_enum e
            JOIN pg_type t ON e.enumtypid = t.oid
            WHERE t.typname = 'enum_estado_comprobante'
              AND e.enumlabel = 'error_permanente'
        ) THEN
            ALTER TYPE enum_estado_comprobante ADD VALUE 'error_permanente';
        END IF;
    END IF;
END $$;


-- ************************************************************
-- [UPD-8] TABLA WHATSAPP_CONFIGURACION RECONSTRUIDA
-- Fuente: whatsapp/0002_rebuild_configuracion
-- Esquema anterior usaba (token_acceso, business_id, numero_verificado, is_active).
-- Esquema nuevo usa (phone_number_id, waba_id, access_token, webhook_verify_token, activo).
-- ************************************************************

DROP TABLE IF EXISTS whatsapp_configuracion;
CREATE TABLE whatsapp_configuracion (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number_id       VARCHAR(50)   NOT NULL DEFAULT '',
    waba_id               VARCHAR(50)   NOT NULL DEFAULT '',
    access_token          TEXT          NOT NULL DEFAULT '',
    webhook_verify_token  VARCHAR(100)  NOT NULL DEFAULT '',
    activo                BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ************************************************************
-- [UPD-9] COMISIONES DE VENDEDOR (nueva tabla)
-- Fuente: ventas/0003_add_comision_vendedor (2026-02-22)
-- ************************************************************

CREATE TABLE comisiones_vendedor (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    vendedor_id     UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE RESTRICT,
    periodo         VARCHAR(7)    NOT NULL,           -- Formato YYYY-MM, ej: 2026-02
    porcentaje      DECIMAL(5,2)  NOT NULL DEFAULT 5, -- % sobre total_venta
    total_ventas    DECIMAL(14,2) NOT NULL DEFAULT 0, -- Suma total_venta del periodo
    monto_comision  DECIMAL(14,2) NOT NULL DEFAULT 0, -- total_ventas * porcentaje / 100
    cantidad_ventas INTEGER       NOT NULL DEFAULT 0,
    pagado          BOOLEAN       NOT NULL DEFAULT FALSE,
    fecha_pago      DATE,
    notas           TEXT          NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    UNIQUE(vendedor_id, periodo)
);

CREATE INDEX idx_comisiones_vendedor ON comisiones_vendedor(vendedor_id);
CREATE INDEX idx_comisiones_periodo ON comisiones_vendedor(periodo);


-- ************************************************************
-- [UPD-10] VENTAS: cliente_id nullable
-- Fuente: ventas/0004_venta_cliente_nullable (2026-02-22)
-- Permite ventas rápidas POS sin cliente registrado.
-- ************************************************************

ALTER TABLE ventas
    ALTER COLUMN cliente_id DROP NOT NULL;


-- ************************************************************
-- [UPD-11] REPORTES: snapshots KPI y programaciones de reporte
-- Fuente: reportes/0001_add_snapshot_kpi_programacion_reporte (2026-02-22)
-- ************************************************************

CREATE TABLE snapshots_kpi (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha       DATE          NOT NULL,
    hora        TIME          NOT NULL,
    datos       JSONB         NOT NULL,  -- KPIs serializados como JSON
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_snap_fecha_hora ON snapshots_kpi(fecha DESC, hora DESC);

CREATE TABLE programaciones_reporte (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          VARCHAR(200)  NOT NULL,
    tipo_reporte    VARCHAR(30)   NOT NULL,  -- 'ventas','inventario','cxc','cxp'
    formato         VARCHAR(10)   NOT NULL DEFAULT 'excel',  -- 'excel','pdf'
    frecuencia      VARCHAR(20)   NOT NULL,  -- 'diario','semanal','mensual'
    hora_envio      TIME          NOT NULL,
    dia_semana      INTEGER,                 -- 0=Lunes..6=Domingo (solo semanal)
    dia_mes         INTEGER,                 -- 1-28 (solo mensual)
    emails          JSONB         NOT NULL DEFAULT '[]',
    activo          BOOLEAN       NOT NULL DEFAULT TRUE,
    ultima_ejecucion TIMESTAMPTZ,
    creado_por_id   UUID          REFERENCES usuarios(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);


-- ============================================================
-- ACTUALIZACIONES POST-v3 CONTINUACIÓN
-- Sincronizado con migrations Django — generado 2026-02-23 (T11)
-- ============================================================


-- ************************************************************
-- [UPD-12] SESIONES ACTIVAS JWT (nueva tabla)
-- Fuente: usuarios app — modelo SesionActiva
-- Registra tokens JWT activos con JTI para invalidación individual.
-- ************************************************************

CREATE TABLE sesiones_activas (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id  UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    jti         VARCHAR(64)   NOT NULL UNIQUE,
    ip_address  VARCHAR(45)   NOT NULL DEFAULT '',
    user_agent  VARCHAR(300)  NOT NULL DEFAULT '',
    activo      BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ   NOT NULL
);

CREATE INDEX idx_sesion_usuario_activo ON sesiones_activas(usuario_id, activo);


-- ************************************************************
-- [UPD-13] NOTIFICACIONES INTERNAS (nueva tabla)
-- Fuente: usuarios app — modelo Notificacion
-- Alimenta la campana del header via WebSocket ws/notificaciones/.
-- Tipos: stock_bajo | lote_vencer | cxc_vencida | cxp_vencer |
--        cotizacion_vencer | oc_aprobada | pedido_entregado | sistema
-- ************************************************************

CREATE TABLE notificaciones (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID          NOT NULL REFERENCES perfiles_usuario(id) ON DELETE CASCADE,
    tipo            VARCHAR(30)   NOT NULL DEFAULT 'sistema',
    titulo          VARCHAR(200)  NOT NULL,
    mensaje         TEXT          NOT NULL,
    leida           BOOLEAN       NOT NULL DEFAULT FALSE,
    referencia_tipo VARCHAR(50)   NOT NULL DEFAULT '',
    referencia_id   UUID,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notif_usuario_leida  ON notificaciones(usuario_id, leida);
CREATE INDEX idx_notif_usuario_fecha  ON notificaciones(usuario_id, created_at);


-- ************************************************************
-- [UPD-14] PERIODOS CONTABLES (nueva tabla)
-- Fuente: finanzas app — modelo PeriodoContable
-- Controla apertura/cierre mensual; bloquea operaciones en periodos cerrados.
-- ************************************************************

CREATE TABLE periodos_contables (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    anio            INTEGER       NOT NULL,
    mes             INTEGER       NOT NULL,   -- 1-12
    cerrado         BOOLEAN       NOT NULL DEFAULT FALSE,
    cerrado_por_id  UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    cerrado_at      TIMESTAMPTZ,
    notas           TEXT          NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_periodo_anio_mes UNIQUE(anio, mes)
);


-- ************************************************************
-- [UPD-15] CONCILIACIONES BANCARIAS (nueva tabla)
-- Fuente: finanzas app — modelo ConciliacionBancaria
-- Encabezado de sesión de conciliación mensual por cuenta bancaria.
-- Estados: pendiente | conciliado | diferencia
-- ************************************************************

CREATE TABLE conciliaciones_bancarias (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_cuenta       VARCHAR(150)  NOT NULL,
    periodo             VARCHAR(7)    NOT NULL,   -- Formato YYYY-MM
    saldo_segun_banco   DECIMAL(14,2) NOT NULL,
    saldo_segun_sistema DECIMAL(14,2) NOT NULL DEFAULT 0,
    diferencia          DECIMAL(14,2) NOT NULL DEFAULT 0,
    estado              VARCHAR(20)   NOT NULL DEFAULT 'pendiente',
    notas               TEXT          NOT NULL DEFAULT '',
    creado_por_id       UUID          REFERENCES perfiles_usuario(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_conc_periodo_estado ON conciliaciones_bancarias(periodo, estado);


-- ************************************************************
-- [UPD-16] MOVIMIENTOS BANCARIOS (nueva tabla)
-- Fuente: finanzas app — modelo MovimientoBancario
-- Líneas del extracto bancario. Se concilian contra cobros/pagos del sistema.
-- tipo: ingreso | egreso
-- cobro_id / pago_id: FK a cobros/pagos del sistema (SET NULL si se elimina)
-- ************************************************************

CREATE TABLE movimientos_bancarios (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    conciliacion_id  UUID          NOT NULL REFERENCES conciliaciones_bancarias(id) ON DELETE CASCADE,
    fecha            DATE          NOT NULL,
    descripcion      VARCHAR(300)  NOT NULL,
    tipo             VARCHAR(10)   NOT NULL DEFAULT 'ingreso',   -- ingreso | egreso
    monto            DECIMAL(12,2) NOT NULL,
    referencia       VARCHAR(100)  NOT NULL DEFAULT '',
    cobro_id         UUID          REFERENCES cobros(id) ON DELETE SET NULL,
    pago_id          UUID          REFERENCES pagos(id)  ON DELETE SET NULL,
    conciliado       BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_banc_conciliacion ON movimientos_bancarios(conciliacion_id);
CREATE INDEX idx_mov_banc_conciliado   ON movimientos_bancarios(conciliado);
CREATE INDEX idx_mov_banc_cobro        ON movimientos_bancarios(cobro_id);
CREATE INDEX idx_mov_banc_pago         ON movimientos_bancarios(pago_id);


-- ************************************************************
-- [UPD-17] TRAZABILIDAD POR NÚMERO DE SERIE (nueva tabla)
-- Fuente: inventario app — modelo Serie (migrations 0004 + 0005)
-- Solo aplica a productos con requiere_serie = TRUE.
-- Estados: disponible | vendido | devuelto | dado_de_baja
-- ************************************************************

CREATE TABLE series (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id     UUID          NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    numero_serie    VARCHAR(100)  NOT NULL,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'disponible',
    almacen_id      UUID          REFERENCES almacenes(id) ON DELETE SET NULL,
    referencia_tipo VARCHAR(30)   NOT NULL DEFAULT '',
    referencia_id   UUID,
    observaciones   TEXT          NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_serie_producto_numero UNIQUE(producto_id, numero_serie)
);

CREATE INDEX idx_series_numero          ON series(numero_serie);
CREATE INDEX idx_series_producto_estado ON series(producto_id, estado);
CREATE INDEX idx_series_almacen         ON series(almacen_id);


-- ************************************************************
-- [UPD-18] COLUMNA requiere_serie EN productos
-- Fuente: inventario app — campo agregado en T6
-- ************************************************************

ALTER TABLE productos
    ADD COLUMN IF NOT EXISTS requiere_serie BOOLEAN NOT NULL DEFAULT FALSE;


-- ************************************************************
-- [UPD-19] WHATSAPP_CONFIGURACION: campo singleton_lock
-- Fuente: whatsapp/0003_add_singleton_constraint (T11)
-- Garantiza que solo exista una fila en la tabla (singleton).
-- ************************************************************

ALTER TABLE whatsapp_configuracion
    ADD COLUMN IF NOT EXISTS singleton_lock INTEGER NOT NULL DEFAULT 1;

ALTER TABLE whatsapp_configuracion
    ADD CONSTRAINT uq_whatsapp_config_singleton UNIQUE(singleton_lock);


-- ************************************************************
-- [UPD-20] WHATSAPP: estructura real de whatsapp_mensajes y whatsapp_log
-- Fuente: whatsapp app — modelos WhatsappMensaje y WhatsappLog
-- El esquema original del SQL v3 difería del modelo Django real.
-- Se documenta la estructura correcta aquí como referencia.
--
-- whatsapp_mensajes columnas reales vs SQL v3:
--   SQL v3 tenía: destinatario_telefono, cliente_id, contenido_enviado,
--                 meta_message_id, codigo_respuesta_api
--   Django real:  destinatario (VARCHAR 20), nombre_destinatario (VARCHAR 200),
--                 contenido (TEXT), parametros (JSONB), wa_message_id (VARCHAR 100),
--                 error_detalle (TEXT), enviado_at (TIMESTAMPTZ nullable)
--                 — sin FK directa a clientes
--
-- whatsapp_log columnas reales vs SQL v3:
--   SQL v3 tenía: mensaje_id FK, request_json, response_json, codigo_http
--   Django real:  evento (VARCHAR 50), payload (JSONB), wa_message_id (VARCHAR 100),
--                 procesado (BOOLEAN) — sin FK a mensajes
--
-- whatsapp_plantillas: falta columna idioma VARCHAR(10) en SQL v3
-- ************************************************************

-- Corrección columnas whatsapp_mensajes
ALTER TABLE whatsapp_mensajes
    ADD COLUMN IF NOT EXISTS nombre_destinatario VARCHAR(200) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS parametros          JSONB        NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS wa_message_id       VARCHAR(100) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS error_detalle       TEXT         NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS enviado_at          TIMESTAMPTZ;

-- Nota: columnas antiguas (meta_message_id, codigo_respuesta_api, cliente_id)
-- siguen en SQL v3 por compatibilidad. El modelo Django NO las usa.

-- Corrección columnas whatsapp_plantillas
ALTER TABLE whatsapp_plantillas
    ADD COLUMN IF NOT EXISTS idioma VARCHAR(10) NOT NULL DEFAULT 'es';


-- ============================================================
-- ACTUALIZACIONES POST-v3 CONTINUACIÓN (T12 — 2026-02-24)
-- Sincronizado con modelos Django reales validados manualmente
-- ============================================================


-- ************************************************************
-- [UPD-21] PEDIDOS: columnas faltantes (campos agregados en T6-T12)
-- Fuente: distribucion/models.py — modelo Pedido
-- El SQL v3 + UPD-3/4 no incluía estos campos del modelo real.
-- ************************************************************

ALTER TABLE pedidos
    ADD COLUMN IF NOT EXISTS nombre_destinatario      VARCHAR(200) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS telefono_destinatario    VARCHAR(20)  NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS turno_entrega            VARCHAR(10)  NOT NULL DEFAULT '',
    -- Valores: '' (sin turno) | 'manana' | 'tarde'
    ADD COLUMN IF NOT EXISTS costo_delivery           DECIMAL(10,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS enlace_ubicacion         VARCHAR(500) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS es_urgente               BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS fecha_pedido             DATE,
    ADD COLUMN IF NOT EXISTS dedicatoria              TEXT         NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS foto_entrega             VARCHAR(200),          -- path del ImageField
    ADD COLUMN IF NOT EXISTS observacion_conductor    TEXT         NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS fecha_confirmacion       TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS estado_produccion        VARCHAR(20)  NOT NULL DEFAULT 'pendiente',
    -- Valores: 'pendiente' | 'en_produccion' | 'completado'
    ADD COLUMN IF NOT EXISTS produccion_iniciada_en   TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS produccion_completada_en TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS creado_por_id            UUID         REFERENCES perfiles_usuario(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_pedidos_creado_por    ON pedidos(creado_por_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_estado_prod   ON pedidos(estado_produccion);
CREATE INDEX IF NOT EXISTS idx_pedidos_fecha_pedido  ON pedidos(fecha_pedido);


-- ************************************************************
-- [UPD-22] TRANSPORTISTAS: columnas GPS y portal conductor
-- Fuente: distribucion/models.py — modelo Transportista
-- El SQL v3 no incluía campos del portal conductor (token, GPS).
-- ************************************************************

ALTER TABLE transportistas
    ADD COLUMN IF NOT EXISTS token         UUID         UNIQUE DEFAULT gen_random_uuid(),
    ADD COLUMN IF NOT EXISTS last_lat      DECIMAL(10,7),
    ADD COLUMN IF NOT EXISTS last_lng      DECIMAL(10,7),
    ADD COLUMN IF NOT EXISTS last_location_at  TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS preferencia_zona  VARCHAR(200) NOT NULL DEFAULT '';

-- Corregir ancho de placa (era VARCHAR(10), modelo usa max_length=20)
-- No se puede ALTER directamente en PostgreSQL sin reconstruir; usar:
-- ALTER TABLE transportistas ALTER COLUMN placa TYPE VARCHAR(20);
ALTER TABLE transportistas ALTER COLUMN placa TYPE VARCHAR(20);

CREATE INDEX IF NOT EXISTS idx_transportistas_token ON transportistas(token);


-- ************************************************************
-- [UPD-23] WHATSAPP: tablas campanas y automatizaciones
-- Fuente: whatsapp/models.py — WhatsappCampana, WhatsappAutomatizacion
-- No existían en el SQL v3.
-- ************************************************************

CREATE TABLE IF NOT EXISTS whatsapp_campanas (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre              VARCHAR(200)  NOT NULL,
    plantilla_id        UUID          REFERENCES whatsapp_plantillas(id) ON DELETE SET NULL,
    segmento            VARCHAR(100)  NOT NULL DEFAULT '',
    estado              VARCHAR(20)   NOT NULL DEFAULT 'borrador',
    -- Estados: borrador | programado | encolado | en_proceso | completado | cancelado
    total_contactos     INTEGER       NOT NULL DEFAULT 0,
    mensajes_encolados  INTEGER       NOT NULL DEFAULT 0,
    programado_para     TIMESTAMPTZ,
    creado_por_id       UUID          REFERENCES usuarios(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campanas_estado      ON whatsapp_campanas(estado);
CREATE INDEX IF NOT EXISTS idx_campanas_plantilla   ON whatsapp_campanas(plantilla_id);
CREATE INDEX IF NOT EXISTS idx_campanas_creado_por  ON whatsapp_campanas(creado_por_id);


CREATE TABLE IF NOT EXISTS whatsapp_automatizaciones (
    id          VARCHAR(50)   PRIMARY KEY,     -- eg. 'auto-venta-confirmada' (PK string)
    evento      VARCHAR(50)   NOT NULL UNIQUE,
    -- Valores fijos: venta_confirmada | pedido_despachado | pedido_entregado |
    --                cotizacion_por_vencer | cxc_vencida
    plantilla_id UUID         REFERENCES whatsapp_plantillas(id) ON DELETE SET NULL,
    activo      BOOLEAN       NOT NULL DEFAULT FALSE,
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Nota: se crean 5 filas fijas via migration post_migrate, una por evento.


-- ************************************************************
-- [UPD-24] CORRECCIÓN: whatsapp_log estructura real
-- Fuente: whatsapp/models.py — WhatsappLog
-- El SQL v3 tenía: mensaje_id FK, request_json, response_json, codigo_http
-- El modelo Django real NO tiene FK a mensajes — es log de webhooks entrantes.
-- ************************************************************

-- La tabla whatsapp_log del SQL v3 está incorrecta. Estructura real:
DROP TABLE IF EXISTS whatsapp_log;
CREATE TABLE whatsapp_log (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    evento      VARCHAR(50)   NOT NULL DEFAULT '',   -- tipo de evento webhook
    payload     JSONB         NOT NULL DEFAULT '{}', -- body del webhook
    wa_message_id VARCHAR(100) NOT NULL DEFAULT '',  -- ID de Meta
    procesado   BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wa_log_evento     ON whatsapp_log(evento);
CREATE INDEX IF NOT EXISTS idx_wa_log_procesado  ON whatsapp_log(procesado);
CREATE INDEX IF NOT EXISTS idx_wa_log_wa_msg_id  ON whatsapp_log(wa_message_id);