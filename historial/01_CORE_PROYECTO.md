# JSOLUCIONES ERP — CORE DEL PROYECTO

> Este archivo define QUÉ es el proyecto, el stack tecnológico fijo, la arquitectura
> por instancia y qué debe estar listo al alcanzar el 50% del desarrollo.

---

## 1. DEFINICIÓN DEL PROYECTO

Una plataforma ERP orientada al mercado peruano. Permite a una empresa gestionar ventas, inventario, facturación electrónica, distribución, compras, finanzas, comunicación con clientes y reportes desde una aplicación web.

**Modelo de negocio:** Template por instancia — se desarrolla UNA vez y se clona/despliega por separado para cada empresa cliente. Cada cliente tiene su propia instancia del sistema (su propio servidor, su propia base de datos). No es multi-tenant.

**Ventajas de este modelo:**
- Aislamiento total entre clientes (cada uno tiene su DB separada)
- Personalización por cliente sin afectar a otros
- Despliegue independiente (si un cliente se cae, los demás no se afectan)
- Más simple de desarrollar y mantener
- Futuro: si se necesita multi-tenant, se puede migrar después

---

## 2. STACK TECNOLÓGICO (FIJO — NO SE CAMBIA)

| Capa | Tecnología | Notas |
|------|-----------|-------|
| **Backend** | Django 4.x + Django REST Framework | API REST |
| **Base de datos** | PostgreSQL | Schema único, una DB por instancia |
| **Tareas asíncronas** | Celery + Redis | Colas, tareas programadas |
| **WebSockets** | Django Channels + Redis | Notificaciones en tiempo real |
| **Frontend** | React 19 + TypeScript + Tailwick | Template comprado, se adapta |
| **Facturación electrónica** | NUBEFACT (API externa) | NO se conecta directo a SUNAT |
| **WhatsApp** | Cloud API de Meta | API oficial |
| **Autenticación** | JWT (simplejwt) + 2FA opcional | RBAC por módulo |
| **Despliegue** | Docker + CI/CD | GitHub Actions o similar |

**LO QUE NO SE USA:**
- ~~django-tenants~~ → No se necesita, cada cliente es una instancia separada
- ~~Multi-schema PostgreSQL~~ → Un schema `public` normal por instancia
- ~~Modelo Tenant / Domain~~ → Reemplazado por modelo `Empresa` (config de la empresa)
- ~~UsuarioGlobal con M2M a tenants~~ → Usuario simple con Django AbstractUser

---

## 3. DECISIONES TÉCNICAS YA TOMADAS

| Decisión | Detalle | Implicación |
|----------|---------|-------------|
| **Facturación = NUBEFACT** | Se usa API de Nubefact para emisión de comprobantes | NO se genera XML UBL 2.1 propio, NO se conecta directo a SUNAT. Se envía JSON a Nubefact y ellos resuelven XML, firma, envío y CDR |
| **DB = Instancia separada** | PostgreSQL estándar, una DB por empresa | Sin django-tenants, sin multi-schema. Migraciones normales de Django |
| **Template = Tailwick (React 19 + TS)** | Template comprado, se adapta | NO se rediseña UI desde cero. TypeScript obligatorio |
| **WhatsApp = Cloud API Meta** | API oficial | Se necesita Business Manager verificado |

---

## 4. ARQUITECTURA POR INSTANCIA

### 4.1 Cómo funciona

```
EMPRESA A (instancia 1):
  ├── Servidor/Container propio
  ├── DB PostgreSQL propia: jsoluciones_empresa_a
  ├── Redis propio (o compartido)
  └── Frontend desplegado con config de Empresa A

EMPRESA B (instancia 2):
  ├── Servidor/Container propio
  ├── DB PostgreSQL propia: jsoluciones_empresa_b
  ├── Redis propio (o compartido)
  └── Frontend desplegado con config de Empresa B

EL CÓDIGO ES EL MISMO.
Solo cambia: .env (DB, tokens Nubefact, WhatsApp) y datos de la empresa.
```

### 4.2 Modelo Empresa (reemplaza al Tenant)

Cada instancia tiene UNA fila en la tabla `empresa` con la configuración:

```python
# apps/empresa/models.py
class Empresa(models.Model):
    """Configuración de la empresa que usa esta instancia."""
    ruc = models.CharField(max_length=11, unique=True)
    razon_social = models.CharField(max_length=200)
    nombre_comercial = models.CharField(max_length=200, blank=True, default='')
    direccion = models.TextField(blank=True, default='')
    ubigeo = models.CharField(max_length=6, blank=True, default='')
    telefono = models.CharField(max_length=20, blank=True, default='')
    email = models.EmailField(blank=True, default='')
    logo = models.ImageField(upload_to='empresa/', null=True, blank=True)

    # Nubefact
    nubefact_token = models.CharField(max_length=200, blank=True, default='')
    nubefact_url = models.URLField(blank=True, default='https://api.nubefact.com/api/v1/')

    # WhatsApp: credenciales WA viven en whatsapp_configuracion (tabla dedicada)

    # Moneda y configuración fiscal
    moneda_principal = models.CharField(max_length=3, default='PEN')
    igv_porcentaje = models.DecimalField(max_digits=5, decimal_places=2, default=18.00)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'empresa'
        verbose_name = 'Configuración de Empresa'

    def __str__(self):
        return self.razon_social
```

### 4.3 Modelo Usuario (simple, sin multi-tenant)

```python
# apps/usuarios/models.py
from django.contrib.auth.models import AbstractUser

class Usuario(AbstractUser):
    """Usuario del sistema. Reemplaza al User de Django."""
    email = models.EmailField(unique=True)
    username = None  # Solo email

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        db_table = 'usuarios'

# AUTH_USER_MODEL = 'usuarios.Usuario'
```

---

## 5. ESTRUCTURA DE PROYECTO DJANGO

```
jsoluciones/
├── config/
│   ├── settings/
│   │   ├── base.py          # Settings compartidos
│   │   ├── development.py   # Debug, DB local
│   │   └── production.py    # Seguridad, DB producción
│   ├── urls.py              # URLs raíz
│   ├── asgi.py              # Para Channels
│   └── wsgi.py
├── apps/
│   ├── empresa/             # Configuración de la empresa (1 fila)
│   ├── usuarios/            # Usuario, PerfilUsuario, Rol, Permiso
│   ├── clientes/            # Cliente
│   ├── proveedores/         # Proveedor
│   ├── inventario/          # Producto, Almacen, Movimiento, Lote
│   ├── ventas/              # Venta, Cotizacion, OrdenVenta
│   ├── facturacion/         # Comprobante, NotaCredito, EnvioNubefact
│   ├── compras/             # OrdenCompra, FacturaProveedor
│   ├── distribucion/        # Pedido, RutaEntrega, Seguimiento
│   ├── finanzas/            # CuentaCobrar, CuentaPagar, Asiento
│   ├── whatsapp/            # Mensaje, Plantilla, LogEnvio
│   └── reportes/            # Solo services, NO modelos propios
├── core/
│   ├── permissions.py       # Permisos RBAC reutilizables
│   ├── pagination.py        # Paginación estándar
│   ├── exceptions.py        # Excepciones custom
│   ├── exception_handler.py # Handler global de errores
│   ├── choices.py           # Constantes globales
│   ├── mixins.py            # TimestampMixin, SoftDeleteMixin, AuditMixin
│   ├── renderers.py         # Renderer para formato de respuesta estándar
│   └── utils/
│       ├── validators.py    # Validación RUC, DNI, email
│       ├── nubefact.py      # Cliente HTTP para Nubefact
│       └── whatsapp.py      # Cliente HTTP para Meta API
├── requirements/
│   ├── base.txt
│   ├── dev.txt
│   └── prod.txt
├── docker-compose.yml
├── Dockerfile
├── .env.example
└── manage.py
```

### 5.1 Configuración en settings.py (sin django-tenants)

```python
# config/settings/base.py
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third party
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'django_filters',
    'corsheaders',
    'drf_spectacular',
    'drf_spectacular_sidecar',

    # Apps del ERP
    'apps.empresa',
    'apps.usuarios',
    'apps.clientes',
    'apps.proveedores',
    'apps.inventario',
    'apps.ventas',
    'apps.facturacion',
    'apps.compras',
    'apps.distribucion',
    'apps.finanzas',
    'apps.whatsapp',
    'apps.reportes',
]

# DB estándar (sin django-tenants)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='jsoluciones'),
        'USER': config('DB_USER', default='jsoluciones_user'),
        'PASSWORD': config('DB_PASSWORD', default=''),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
        'CONN_MAX_AGE': 600,
    }
}

AUTH_USER_MODEL = 'usuarios.Usuario'
```

### 5.2 Estructura interna de cada app Django

```
apps/ventas/
├── __init__.py
├── models.py          # Modelos de datos
├── serializers.py     # Serialización/validación DRF
├── views.py           # ViewSets (solo orquestación)
├── services.py        # TODA la lógica de negocio
├── urls.py            # Rutas del módulo
├── admin.py           # Solo para debug/desarrollo
├── choices.py         # Constantes propias del módulo
├── signals.py         # Solo side-effects (logs, notificaciones)
├── tasks.py           # Tareas Celery
├── filters.py         # Filtros django-filter
├── tests/
│   ├── test_models.py
│   ├── test_services.py
│   └── test_views.py
└── migrations/
```

---

## 6. PRIORIDAD DE MÓDULOS (Orden de desarrollo)

### PRIORIDAD 1 — Fundación (Sprint 1)
**Sin esto nada funciona.**

- Setup del proyecto Django con PostgreSQL
- Modelo de Empresa (configuración de la empresa)
- Sistema de autenticación (JWT + RBAC)
- Modelo de Usuarios, Roles y Permisos
- Estructura base de apps Django
- Setup del proyecto React con Tailwick
- Conexión API básica (login)

### PRIORIDAD 2 — Inventario y Productos (Sprint 2)
**Base de todo. Sin productos y stock no hay ventas ni compras.**

- Modelo de Productos (SKU, nombre, precio, categoría, unidad_medida, is_active)
- Modelo de Categorías
- Modelo de Almacenes
- Modelo de MovimientosStock (entrada, salida, transferencia, ajuste)
- Modelo de Lotes/Series
- Stock en tiempo real
- Alertas de stock mínimo
- CRUD completo con API REST

### PRIORIDAD 3 — Clientes y Proveedores (Sprint 2-3)
**Necesarios para ventas y compras.**

- Modelo de Clientes (RUC/DNI, razón social, dirección, contacto, segmento)
- Modelo de Proveedores (RUC, razón social, condiciones comerciales)
- Validación de RUC/DNI
- CRUD completo con API REST

### PRIORIDAD 4 — Gestión de Ventas (Sprint 3-4)
**Core del negocio.**

- Modelo de Ventas (cabecera + detalle)
- Modelo de Cotizaciones (flujo: borrador → vigente → aceptada → vencida)
- Modelo de Órdenes de Venta
- Flujo completo: Cotización → Orden → Venta
- Métodos de pago (efectivo, tarjeta, transferencia, Yape/Plin, crédito)
- POS: interfaz rápida para venta directa
- Descuentos por item y globales
- Generación automática de comprobante (conecta con facturación)
- Actualización de stock al confirmar venta

### PRIORIDAD 5 — Facturación Electrónica vía Nubefact (Sprint 4-5)
**Obligatorio legalmente en Perú.**

- Integración con API Nubefact (enviar JSON → recibir PDF, XML, CDR)
- Modelo de Comprobantes: tipo, serie, número, estado_sunat, pdf_url, xml_url, cdr_url
- Tipos: Factura (01), Boleta (03), Nota Crédito (07), Nota Débito (08)
- Resumen diario de boletas
- Reenvío de comprobantes fallidos
- Modo contingencia: cola en Celery si Nubefact no responde

### PRIORIDAD 6 — Compras y Proveedores (Sprint 5)

- Órdenes de Compra (borrador → aprobada → recibida → cerrada)
- Ingreso de facturas de proveedor
- Recepción parcial/total de mercadería
- Conciliación compra ↔ inventario

### PRIORIDAD 7 — Gestión Financiera (Sprint 6)

- Cuentas por Cobrar y Pagar (auto-generadas)
- Registro de pagos y cobros
- Asientos contables automáticos
- Plan contable configurable
- Reportes: Libro Diario, Mayor, Balance

### PRIORIDAD 8 — Distribución y Seguimiento (Sprint 6-7)

- Pedidos con estados (pendiente → despachado → en_ruta → entregado)
- Asignación a transportistas
- Seguimiento público vía URL única
- Evidencia de entrega (foto, firma, OTP)

### PRIORIDAD 9 — WhatsApp API (Sprint 7)

- Integración con Cloud API de Meta
- Mensajes por eventos (venta, despacho, etc.)
- Gestión de plantillas y logs

### PRIORIDAD 10 — Dashboard y Reportes (Sprint 7-8)

- Tableros por rol
- KPIs en tiempo real
- Filtros dinámicos y exportación Excel/PDF

---

## 7. META DEL 50% — Lo que debe estar funcionando

Al alcanzar el 50% del desarrollo, el sistema debe tener **funcionando y probado**:

| # | Componente | Estado esperado |
|---|-----------|----------------|
| 1 | Empresa + Usuarios | Config empresa, login JWT, roles, permisos ✅ |
| 2 | Productos e Inventario | CRUD completo, stock en tiempo real ✅ |
| 3 | Clientes y Proveedores | CRUD con validación RUC/DNI ✅ |
| 4 | Ventas | Venta directa, cotización, orden de venta ✅ |
| 5 | Facturación Nubefact | Emitir factura/boleta, recibir respuesta ✅ |
| 6 | Frontend conectado | Login, dashboard base, vistas de ventas e inventario ✅ |

**Esto cubre las Prioridades 1 a 5.**

---

## 8. FLUJO DE FACTURACIÓN CON NUBEFACT

```
[Venta confirmada en el ERP]
        │
        ▼
[Service de Facturación genera JSON con datos de la venta]
        │
        ▼
[Se envía POST a API Nubefact]
  URL: https://api.nubefact.com/api/v1/{ruc}
  Header: Authorization: Bearer {token_nubefact}
        │
        ├── Respuesta exitosa (200):
        │   ├── Se guarda: pdf_url, xml_url, cdr_url, hash, QR
        │   ├── Estado comprobante: "aceptado"
        │   └── Se notifica al cliente (email/WhatsApp)
        │
        └── Respuesta error (4xx/5xx):
            ├── Se guarda error en logs
            ├── Estado comprobante: "error" o "pendiente_reenvio"
            └── Se encola tarea Celery para reintento
```

**Datos que se envían a Nubefact (JSON):**
- Tipo de comprobante, serie, número
- Datos del emisor (de la tabla Empresa)
- Datos del cliente (tipo doc, número doc, razón social)
- Items (descripción, cantidad, unidad, precio, IGV)
- Totales (gravada, IGV, total)

**Datos que se reciben de Nubefact:**
- URL del PDF, URL del XML firmado, URL del CDR
- Hash y código QR
- Estado SUNAT y mensaje de respuesta

> **IMPORTANTE:** El código Python de generación XML UBL 2.1 que aparece en el PDF del proyecto
> es REFERENCIAL. NO se implementa porque Nubefact resuelve todo eso. Solo se envía JSON.

---

## 9. DESPLIEGUE POR INSTANCIA

### Para cada nueva empresa cliente:

```bash
# 1. Clonar el repo
git clone jsoluciones-erp.git empresa_nueva

# 2. Configurar .env con datos de la empresa
cp .env.example .env
# Editar: DB_NAME, NUBEFACT_TOKEN, WHATSAPP_TOKEN, etc.

# 3. Crear DB
createdb jsoluciones_empresa_nueva

# 4. Migrar
python manage.py migrate

# 5. Seed de roles y permisos
python manage.py seed_permissions

# 6. Crear empresa y usuario admin
python manage.py setup_empresa

# 7. Desplegar (Docker o servidor directo)
docker-compose up -d
```

---

## 10. LO QUE NO SE DEBE HACER (ANTI-PATRONES)

- NO generar XML UBL manualmente (Nubefact lo hace)
- NO conectar directo a SUNAT (Nubefact es el intermediario)
- NO crear un diseño UI desde cero (usar Tailwick)
- NO usar SQLite (siempre PostgreSQL)
- NO usar django-tenants ni multi-schema (es por instancia)
- NO guardar archivos en filesystem del servidor (usar S3 en producción)
- NO hacer queries N+1 (usar select_related / prefetch_related)
- NO poner lógica de negocio en signals, views o serializers
- NO crear migraciones que borren datos sin backup
- NO hardcodear URLs de API en el frontend (variables de entorno)
- NO ignorar los estados y flujos definidos (cotización → orden → venta)
