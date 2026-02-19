# JSOLUCIONES ERP — PROCESOS DE BASE DE DATOS

> Este archivo detalla cómo configurar la DB, qué tablas crea Django automáticamente,
> el diseño completo de la base de datos, y el proceso de migraciones.
>
> ⚠️ ARQUITECTURA: Instancia por cliente. Una DB PostgreSQL estándar.
> Sin django-tenants, sin multi-schema. Migraciones normales de Django.

---

## 1. SETUP DE POSTGRESQL

### 1.1 Con Docker (recomendado para desarrollo)

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:16
    container_name: jsoluciones_db
    environment:
      POSTGRES_DB: jsoluciones
      POSTGRES_USER: jsoluciones_user
      POSTGRES_PASSWORD: jsoluciones_pass_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    container_name: jsoluciones_redis
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

### 1.2 Configuración en Django settings

```python
# config/settings/base.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',  # PostgreSQL estándar
        'NAME': config('DB_NAME', default='jsoluciones'),
        'USER': config('DB_USER', default='jsoluciones_user'),
        'PASSWORD': config('DB_PASSWORD', default='jsoluciones_pass_dev'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
        'CONN_MAX_AGE': 600,  # Conexiones persistentes (10 min)
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}
```

---

## 2. TABLAS QUE DJANGO CREA AUTOMÁTICAMENTE

Django y sus dependencias crean estas tablas al ejecutar `migrate`. Son necesarias para el funcionamiento del framework y SE USAN en el proyecto:

### 2.1 Tablas de Django core

| Tabla | Creada por | Uso en JSoluciones |
|-------|-----------|-------------------|
| `django_migrations` | Django | Registro de migraciones aplicadas |
| `django_content_types` | contenttypes | Tipos de contenido (para permisos genéricos) |
| `django_admin_log` | admin | Log de acciones en el admin |
| `django_session` | sessions | Sesiones (para admin Django, no para API) |

### 2.2 Tablas de auth de Django

| Tabla | Creada por | Uso en JSoluciones |
|-------|-----------|-------------------|
| `usuarios` | apps.usuarios | **SE REEMPLAZA auth_user** con Usuario custom (AbstractUser) |
| `auth_group` | auth | **NO se usa.** El RBAC es custom (Rol + Permiso propios) |
| `auth_permission` | auth | **NO se usa directamente.** Permisos propios en tabla Permiso |
| `auth_group_permissions` | auth | **NO se usa.** |
| `auth_user_groups` | auth | **NO se usa.** |
| `auth_user_user_permissions` | auth | **NO se usa.** |

> Django crea estas tablas de auth automáticamente. No se pueden evitar,
> pero NO las usamos. Nuestro RBAC es custom con las tablas Rol y Permiso.

### 2.3 Tablas de simplejwt

| Tabla | Creada por | Uso en JSoluciones |
|-------|-----------|-------------------|
| `token_blacklist_blacklistedtoken` | simplejwt | Tokens revocados (logout) |
| `token_blacklist_outstandingtoken` | simplejwt | Tokens emitidos pendientes |

### 2.4 Configurar usuario custom

```python
# apps/usuarios/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models

class Usuario(AbstractUser):
    """
    Reemplaza al User de Django.
    Login con email, sin username.
    """
    email = models.EmailField(unique=True)
    username = None  # No usamos username, solo email

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        db_table = 'usuarios'
        verbose_name = 'Usuario'

# settings/base.py
AUTH_USER_MODEL = 'usuarios.Usuario'
```

---

## 3. TODAS LAS TABLAS DE LA BASE DE DATOS

Una sola DB PostgreSQL con schema `public`. Sin multi-schema.

```
BASE DE DATOS: jsoluciones
SCHEMA: public (el default de PostgreSQL)
│
├── DJANGO (automáticas)
│   ├── django_migrations
│   ├── django_content_types
│   ├── django_admin_log
│   ├── django_session
│   ├── auth_group (no se usa, pero Django la crea)
│   ├── auth_permission (no se usa)
│   └── auth_group_permissions (no se usa)
│
├── JWT
│   ├── token_blacklist_blacklistedtoken
│   └── token_blacklist_outstandingtoken
│
├── EMPRESA
│   └── empresa                     → Config de la empresa (1 fila)
│
├── USUARIOS Y RBAC
│   ├── usuarios                    → Usuarios del sistema (AbstractUser custom)
│   ├── usuarios_perfilusuario      → Perfil extendido del usuario
│   ├── usuarios_rol                → Roles (admin, gerente, vendedor, etc.)
│   ├── usuarios_permiso            → Permisos individuales (ventas.crear, etc.)
│   ├── usuarios_rol_permisos       → M2M rol ↔ permiso
│   └── usuarios_logactividad       → Log de acciones del usuario
│
├── CLIENTES
│   └── clientes_cliente
│
├── PROVEEDORES
│   └── proveedores_proveedor
│
├── INVENTARIO
│   ├── inventario_categoria
│   ├── inventario_producto
│   ├── inventario_almacen
│   ├── inventario_stock            → Stock por producto/almacén
│   ├── inventario_movimientostock
│   └── inventario_lote
│
├── VENTAS
│   ├── ventas_cotizacion
│   ├── ventas_detallecotizacion
│   ├── ventas_ordenventa
│   ├── ventas_detalleordenventa
│   ├── ventas_venta
│   └── ventas_detalleventa
│
├── FACTURACIÓN
│   ├── facturacion_seriecomprobante
│   ├── facturacion_comprobante
│   ├── facturacion_detallecomprobante
│   ├── facturacion_notacreditodebito
│   └── facturacion_logenvionubefact
│
├── COMPRAS
│   ├── compras_ordencompra
│   ├── compras_detalleordencompra
│   ├── compras_facturaproveedor
│   └── compras_recepcion
│
├── FINANZAS
│   ├── finanzas_cuentaporcobrar
│   ├── finanzas_cuentaporpagar
│   ├── finanzas_pago
│   ├── finanzas_cobro
│   ├── finanzas_cuentacontable
│   ├── finanzas_asientocontable
│   └── finanzas_detalleasiento
│
├── DISTRIBUCIÓN
│   ├── distribucion_pedido
│   ├── distribucion_transportista
│   ├── distribucion_seguimientopedido
│   └── distribucion_evidenciaentrega
│
└── WHATSAPP
    ├── whatsapp_configuracion
    ├── whatsapp_plantilla
    ├── whatsapp_mensaje
    └── whatsapp_logwhatsapp
```

---

## 4. MODELO EMPRESA (Configuración)

```python
# apps/empresa/models.py
from django.db import models

class Empresa(models.Model):
    """
    Configuración de la empresa que usa esta instancia.
    Solo debe existir UNA fila en esta tabla.
    """
    ruc = models.CharField(max_length=11, unique=True)
    razon_social = models.CharField(max_length=200)
    nombre_comercial = models.CharField(max_length=200, blank=True, default='')
    direccion = models.TextField(blank=True, default='')
    ubigeo = models.CharField(max_length=6, blank=True, default='')
    departamento = models.CharField(max_length=50, blank=True, default='')
    provincia = models.CharField(max_length=50, blank=True, default='')
    distrito = models.CharField(max_length=50, blank=True, default='')
    telefono = models.CharField(max_length=20, blank=True, default='')
    email = models.EmailField(blank=True, default='')
    logo = models.ImageField(upload_to='empresa/', null=True, blank=True)

    # Nubefact
    nubefact_token = models.CharField(max_length=200, blank=True, default='')
    nubefact_url = models.URLField(
        blank=True,
        default='https://api.nubefact.com/api/v1/'
    )

    # WhatsApp: credenciales WA viven en whatsapp_configuracion (tabla dedicada)

    # Configuración fiscal
    moneda_principal = models.CharField(max_length=3, default='PEN')
    igv_porcentaje = models.DecimalField(max_digits=5, decimal_places=2, default=18.00)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'empresa'

    def save(self, *args, **kwargs):
        # Solo puede existir una empresa por instancia
        if not self.pk and Empresa.objects.exists():
            raise ValueError("Solo puede existir una configuración de empresa.")
        super().save(*args, **kwargs)

    def __str__(self):
        return self.razon_social
```

---

## 5. SETUP INICIAL DE UNA NUEVA INSTANCIA

```bash
# 1. Crear la base de datos
createdb jsoluciones
# O con Docker: ya se crea al levantar docker-compose

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con los datos de la empresa

# 3. Ejecutar migraciones
python manage.py migrate

# 4. Crear roles y permisos base
python manage.py seed_permissions

# 5. Crear empresa y usuario administrador
python manage.py setup_empresa
# Interactivo: pide RUC, razón social, email admin, contraseña

# 6. Verificar
python manage.py runserver
# Acceder a /api/docs/ para ver Swagger
```

### Management command: setup_empresa

```python
# core/management/commands/setup_empresa.py
from django.core.management.base import BaseCommand
from apps.empresa.models import Empresa
from apps.usuarios.models import Usuario
from apps.usuarios.services import UsuarioService

class Command(BaseCommand):
    help = 'Configuración inicial: empresa + usuario administrador'

    def handle(self, *args, **options):
        if Empresa.objects.exists():
            self.stdout.write(self.style.WARNING('La empresa ya está configurada.'))
            return

        self.stdout.write('=== Setup Inicial de JSoluciones ERP ===\n')

        ruc = input('RUC de la empresa: ')
        razon_social = input('Razón social: ')
        email_admin = input('Email del administrador: ')
        password = input('Contraseña del administrador: ')

        # Crear empresa
        empresa = Empresa.objects.create(
            ruc=ruc,
            razon_social=razon_social,
        )

        # Crear usuario admin
        usuario = UsuarioService.crear_usuario_admin(
            email=email_admin,
            password=password,
            first_name='Administrador',
            last_name=razon_social[:50],
        )

        self.stdout.write(self.style.SUCCESS(
            f'Empresa "{razon_social}" creada con admin: {email_admin}'
        ))
```

---

## 6. COMANDOS DE MIGRACIÓN (Django estándar)

```bash
# Después de cambiar un modelo:
python manage.py makemigrations inventario  # Genera migración
python manage.py migrate                     # Aplica a la DB

# Generar migraciones de varias apps a la vez:
python manage.py makemigrations ventas facturacion

# Ver migraciones pendientes:
python manage.py showmigrations

# Ver SQL que generaría una migración (sin aplicar):
python manage.py sqlmigrate inventario 0003

# Revertir una migración específica:
python manage.py migrate inventario 0002  # Vuelve a la migración 0002
```

---

## 7. REGLAS CRÍTICAS DE MIGRACIONES

```
MIG-01: NUNCA borrar migraciones existentes.
MIG-02: NUNCA editar una migración que ya fue aplicada.
MIG-03: Siempre probar migraciones en dev ANTES de producción.
MIG-04: Al agregar campo obligatorio sin default: SIEMPRE dar default o hacerlo nullable primero.
MIG-05: NUNCA hacer RunPython con delete/drop sin autorización.
MIG-06: Documentar migraciones complejas con comentario en el archivo.
MIG-07: Al renombrar campo/tabla: usar RenameField/RenameModel, NO delete+create.
MIG-08: Al cambiar tipo de campo: verificar compatibilidad de datos existentes.
MIG-09: En producción: hacer backup ANTES de cada migración.
MIG-10: Las migraciones se versionan en Git (NUNCA en .gitignore).
```

---

## 8. BACKUPS Y MANTENIMIENTO

```bash
# Backup completo:
pg_dump -U jsoluciones_user -h localhost jsoluciones > backup_$(date +%Y%m%d).sql

# Backup comprimido:
pg_dump -U jsoluciones_user -h localhost jsoluciones | gzip > backup_$(date +%Y%m%d).sql.gz

# Restaurar:
psql -U jsoluciones_user -h localhost jsoluciones < backup_20240604.sql

# Restaurar desde comprimido:
gunzip -c backup_20240604.sql.gz | psql -U jsoluciones_user -h localhost jsoluciones
```

---

## 9. ÍNDICES OBLIGATORIOS

```python
# INVENTARIO
class MovimientoStock(models.Model):
    class Meta:
        indexes = [
            models.Index(fields=['producto', 'created_at']),
            models.Index(fields=['almacen', 'tipo_movimiento']),
            models.Index(fields=['referencia_tipo', 'referencia_id']),
        ]

class Producto(models.Model):
    class Meta:
        indexes = [
            models.Index(fields=['sku']),
            models.Index(fields=['categoria', 'is_active']),
            models.Index(fields=['nombre']),
        ]

# VENTAS
class Venta(models.Model):
    class Meta:
        indexes = [
            models.Index(fields=['cliente', 'fecha']),
            models.Index(fields=['vendedor', 'fecha']),
            models.Index(fields=['estado', 'fecha']),
        ]

# FACTURACIÓN
class Comprobante(models.Model):
    class Meta:
        indexes = [
            models.Index(fields=['tipo_comprobante', 'serie', 'numero']),
            models.Index(fields=['cliente', 'fecha_emision']),
            models.Index(fields=['estado_sunat']),
        ]
        unique_together = [['tipo_comprobante', 'serie', 'numero']]

# CLIENTES
class Cliente(models.Model):
    class Meta:
        indexes = [
            models.Index(fields=['tipo_documento', 'numero_documento']),
            models.Index(fields=['razon_social']),
        ]
```

---

## 10. DIAGRAMA DE RELACIONES

```
Empresa (1 fila — config global)

Usuario ──FK──> PerfilUsuario ──FK──> Rol ──M2M──> Permiso

Venta ──FK──> Cliente
  ├── DetalleVenta ──FK──> Producto
  └── Comprobante ──FK──> Cliente
        └── DetalleComprobante

Cotizacion ──FK──> Cliente
  └── DetalleCotizacion ──FK──> Producto

OrdenVenta ──FK──> Cliente
  └── DetalleOrdenVenta ──FK──> Producto

Producto ──FK──> Categoria
  ├── Stock ──FK──> Almacen
  ├── MovimientoStock ──FK──> Almacen
  └── Lote ──FK──> Almacen

OrdenCompra ──FK──> Proveedor
  └── DetalleOrdenCompra ──FK──> Producto

CuentaPorCobrar ──FK──> Cliente, Comprobante
CuentaPorPagar ──FK──> Proveedor, FacturaProveedor

Pedido ──FK──> Venta, Cliente, Transportista
  └── SeguimientoPedido
```

---

## 11. PARA CLONAR A UNA NUEVA EMPRESA

Cuando JSoluciones cierre contrato con una nueva empresa:

```bash
# 1. Clonar el repo (mismo código, nueva instancia)
git clone jsoluciones-erp.git empresa_xyz
cd empresa_xyz

# 2. Crear .env con datos de la nueva empresa
cp .env.example .env
# Editar: DB_NAME, NUBEFACT_TOKEN, WHATSAPP_TOKEN, SECRET_KEY, etc.

# 3. Crear DB nueva
createdb jsoluciones_empresa_xyz

# 4. Migrar
python manage.py migrate

# 5. Setup inicial
python manage.py seed_permissions
python manage.py setup_empresa

# 6. Deploy
docker-compose up -d
```

Cada empresa es completamente independiente. Si se necesitan personalizaciones, se hacen en esa instancia sin afectar a las demás.
