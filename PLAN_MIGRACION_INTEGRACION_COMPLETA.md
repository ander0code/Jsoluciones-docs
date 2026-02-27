# 📋 PLAN MAESTRO: Migración Integral de Datos + Integración de Imágenes R2

**Fecha**: 2025-02-26  
**Versión**: 1.0  
**Estado**: 🚀 Listo para Implementar  
**Responsable**: Squad Tech  

---

## 📌 VISIÓN GENERAL

Migrar datos completos desde Amatista (sistema anterior) a JSOLUCIONES ERP v4, **incluyendo imágenes de productos** en Cloudflare R2. La migración ocurrirá en paralelo para usuarios, productos, vendedores, conductores y transacciones (pedidos, facturas, etc.).

### Datos a Migrar:
- ✅ **35 Productos** con imágenes (mapeadas en `mapeo_imagenes.json`)
- ✅ **Usuarios** (clientes, vendedores, administradores, conductores)
- ✅ **Órdenes de Venta** y **Facturas Electrónicas**
- ✅ **Pedidos** (distribución) y **Evidencias de Entrega**
- ✅ **Catálogo de Categorías**

---

## 🗂️ FASE 1: PREPARACIÓN DE DATOS (Semana 1)

### 1.1 Subir Imágenes a Cloudflare R2

**Objetivo**: Migrar todas las imágenes desde `Amatista-docs/imagenes_descargadas/` a R2 bucket `j-soluciones-media`.

**Script**: `scripts/migracion_imagenes_r2.py`

```python
# Pseudocódigo
import os
import json
import boto3
from pathlib import Path
from django.core.management.base import BaseCommand
from media.models import MediaArchivo
from inventario.models import Producto

class Command(BaseCommand):
    """
    Migra imágenes de productos a Cloudflare R2
    Uso: python manage.py migracion_imagenes_r2 --ruta /path/to/imagenes_descargadas/
    """
    
    def handle(self, *args, **options):
        ruta_imagenes = Path(options['ruta'])
        
        # Cargar mapeo
        with open(ruta_imagenes / 'mapeo_imagenes.json') as f:
            mapeo = json.load(f)
        
        # Inicializar cliente R2
        s3_client = self._init_r2_client()
        
        for item in mapeo:
            archivo_local = ruta_imagenes / item['archivo_local']
            nombre_producto = item['nombre_amatista'].lower()
            
            # Buscar producto en BD (por nombre similar)
            producto = self._buscar_producto(nombre_producto)
            
            if not producto:
                self.stdout.write(f"❌ Producto no encontrado: {nombre_producto}")
                continue
            
            # Subir a R2
            r2_key = self._subir_a_r2(
                s3_client,
                archivo_local,
                producto
            )
            
            # Crear registro en media_archivos
            media = MediaArchivo.objects.create(
                entidad_tipo='producto',
                entidad_id=producto.id,
                tipo_archivo='imagen',
                nombre_original=archivo_local.name,
                r2_key=r2_key,
                url_publica=self._generar_presigned_url(r2_key),
                mime_type=self._detectar_mime(archivo_local),
                tamano_bytes=archivo_local.stat().st_size,
                es_principal=True,  # Primera imagen es principal
                alt_text=f"Imagen de {producto.nombre}"
            )
            
            # Actualizar FK en Producto (nueva columna: imagen_principal_media_id)
            producto.imagen_principal_media_id = media.id
            producto.save()
            
            self.stdout.write(
                f"✅ {producto.nombre} → {r2_key}"
            )
```

**Entrada**: 35 archivos JPG/WEBP  
**Salida**: 35 registros en `media_archivos` + URLs presigned  
**Tiempo Estimado**: 15-20 minutos  

---

### 1.2 Actualizar SQL Schema (Nuevas Columnas)

**Cambios a aplicar**:

```sql
-- Agregar FK a imágenes en tabla productos
ALTER TABLE productos ADD COLUMN imagen_principal_media_id UUID REFERENCES media_archivos(id) ON DELETE SET_NULL;

-- Agregar FK a imágenes en tabla categorias (opcional)
ALTER TABLE categorias ADD COLUMN imagen_media_id UUID REFERENCES media_archivos(id) ON DELETE SET_NULL;

-- Índice para acceso rápido
CREATE INDEX idx_productos_imagen_principal ON productos(imagen_principal_media_id);
```

**Tiempo Estimado**: 2 minutos  

---

## 📦 FASE 2: MIGRACIÓN DE DATOS MAESTROS (Semana 1)

### 2.1 Migrar Categorías

**Script**: `scripts/migracion_categorias.py`

```python
class Command(BaseCommand):
    """Migra categorías de Amatista (si existen en BD antigua)"""
    
    def handle(self, *args, **options):
        # Opciones:
        # A) Si hay tabla en Amatista vieja → copiar via query
        # B) Si está en JSON → parsear y crear
        
        categorias_base = [
            {'nombre': 'Ramos y Bouquets', 'descripcion': 'Arreglos con flores frescas'},
            {'nombre': 'Cajas y Cestas', 'descripcion': 'Presentaciones en caja o cesta'},
            {'nombre': 'Complementos', 'descripcion': 'Chocolates, globos, accesorios'},
        ]
        
        for cat_data in categorias_base:
            Categoria.objects.get_or_create(
                nombre=cat_data['nombre'],
                defaults={'descripcion': cat_data['descripcion']}
            )
```

**Entrada**: Categorías base (3-5)  
**Salida**: Registros en `categorias`  
**Dependencia**: Ninguna  

---

### 2.2 Migrar Productos (Sin Imágenes)

**Script**: `scripts/migracion_productos.py`

Mapeo de campos Amatista → JSOLUCIONES:

| Amatista | JSOLUCIONES | Notas |
|----------|-------------|-------|
| `id` | `id` (UUID) | Nueva UUID |
| `nombre` | `nombre` | Normalizar |
| `descripcion` | `descripcion` | - |
| `precio_venta` | `precio_venta` (DECIMAL 12,4) | Importante: 4 decimales |
| `precio_compra` | `precio_compra` (DECIMAL 12,4) | 0 si no existe |
| `sku` | `sku` | Generar si no existe |
| `categoria_id` | `categoria_id` (FK) | Encontrar match |
| `-` | `requiere_lote` | FALSE por defecto |
| `-` | `requiere_serie` | FALSE por defecto |
| `-` | `stock_minimo`, `stock_maximo` | 0 por defecto |
| `-` | `is_active` | TRUE por defecto |

```python
class Command(BaseCommand):
    """
    Migra 35 productos desde mapeo_imagenes.json
    """
    
    def handle(self, *args, **options):
        mapeo_path = Path('Amatista-docs/imagenes_descargadas/mapeo_imagenes.json')
        
        with open(mapeo_path) as f:
            mapeo = json.load(f)
        
        for item in mapeo:
            nombre = item['nombre_amatista']
            
            producto, created = Producto.objects.get_or_create(
                nombre__iexact=nombre,  # Case-insensitive
                defaults={
                    'sku': self._generar_sku(nombre),
                    'nombre': nombre,
                    'precio_venta': 0,  # Se actualizará manualmente
                    'precio_compra': 0,
                    'unidad_medida': 'NIU',
                    'is_active': True,
                }
            )
            
            if created:
                self.stdout.write(f"✅ Creado: {nombre}")
            else:
                self.stdout.write(f"⏭️ Existente: {nombre}")
```

**Entrada**: `mapeo_imagenes.json` (35 productos)  
**Salida**: 35 registros en `productos` con `is_active=TRUE`  
**Tiempo Estimado**: 5 minutos  
**Requisito previo**: Categorías creadas en 2.1  

---

### 2.3 Vincular Imágenes a Productos

**Script**: `scripts/vincular_imagenes_productos.py`

Este script DEPENDE de 1.1 y 2.2 (imágenes subidas + productos creados).

```python
class Command(BaseCommand):
    """
    Vincula MediaArchivos creados en 1.1 con Productos de 2.2
    """
    
    def handle(self, *args, **options):
        mapeo_path = Path('Amatista-docs/imagenes_descargadas/mapeo_imagenes.json')
        
        with open(mapeo_path) as f:
            mapeo = json.load(f)
        
        # Buscar productos SIN imagen asignada
        productos_sin_imagen = Producto.objects.filter(
            imagen_principal_media_id__isnull=True
        )
        
        for item in mapeo:
            nombre = item['nombre_amatista']
            producto = productos_sin_imagen.filter(nombre__iexact=nombre).first()
            
            if not producto:
                continue
            
            # Buscar media por r2_key
            # (r2_key fue generada en formato: productos/{uuid}/{filename})
            media = MediaArchivo.objects.filter(
                entidad_tipo='producto',
                entidad_id=producto.id,
                es_principal=True
            ).first()
            
            if media:
                producto.imagen_principal_media_id = media.id
                producto.save()
                self.stdout.write(f"✅ Vinculado: {nombre}")
```

**Entrada**: MediaArchivos + Productos  
**Salida**: Columna `producto.imagen_principal_media_id` actualizada  
**Tiempo Estimado**: 2 minutos  

---

### 2.4 Migrar Clientes

**Script**: `scripts/migracion_clientes.py`

```python
class Command(BaseCommand):
    """
    Migra clientes de Amatista (si existen en BD antigua o JSON)
    """
    
    def handle(self, *args, **options):
        # Opción 1: desde JSON/CSV
        clientes_data = self._cargar_clientes_amatista()
        
        for cliente_data in clientes_data:
            cliente, created = Cliente.objects.get_or_create(
                tipo_documento=cliente_data.get('tipo_doc', '1'),  # DNI por defecto
                numero_documento=cliente_data['numero_doc'],
                defaults={
                    'razon_social': cliente_data['nombre'],
                    'email': cliente_data.get('email', ''),
                    'telefono': cliente_data.get('telefono', ''),
                    'segmento': 'NUEVO',
                    'is_active': True,
                }
            )
            
            if created:
                self.stdout.write(f"✅ Cliente: {cliente.razon_social}")
```

**Entrada**: BD Amatista o archivo CSV  
**Salida**: Clientes en `clientes`  
**Nota**: Sin dependencias  

---

### 2.5 Migrar Usuarios (Vendedores, Conductores, Admin)

**Script**: `scripts/migracion_usuarios.py`

```python
class Command(BaseCommand):
    """
    Migra usuarios con roles diferenciados
    Roles: ADMINISTRADOR, VENDEDOR, CONDUCTOR
    """
    
    def handle(self, *args, **options):
        # Crear roles si no existen
        self._crear_roles()
        
        usuarios_data = self._cargar_usuarios_amatista()
        
        for user_data in usuarios_data:
            user, created = Usuario.objects.get_or_create(
                email=user_data['email'],
                defaults={
                    'first_name': user_data['first_name'],
                    'last_name': user_data['last_name'],
                    'is_active': True,
                }
            )
            
            # Crear perfil
            rol = self._obtener_rol(user_data['tipo_usuario'])
            perfil, _ = PerfilUsuario.objects.get_or_create(
                usuario=user,
                defaults={
                    'rol': rol,
                    'telefono': user_data.get('telefono', ''),
                    'is_active': True,
                }
            )
            
            # Si es conductor, crear registro en transportistas
            if user_data['tipo_usuario'] == 'CONDUCTOR':
                Transportista.objects.get_or_create(
                    nombre=f"{user.first_name} {user.last_name}",
                    defaults={
                        'telefono': user_data.get('telefono', ''),
                        'tipo_transportista': 'propio',
                        'is_active': True,
                    }
                )
```

**Entrada**: Usuarios Amatista (clientes, vendedores, conductores)  
**Salida**: `usuarios` + `perfiles_usuario` + `transportistas`  
**Roles a Crear**: ADMINISTRADOR, VENDEDOR, CONDUCTOR  

---

## 📊 FASE 3: MIGRACIÓN TRANSACCIONAL (Semana 2)

### 3.1 Migrar Órdenes de Venta + Detalles

**Script**: `scripts/migracion_ordenes_venta.py`

```python
class Command(BaseCommand):
    """
    Migra órdenes de venta con detalles
    """
    
    def handle(self, *args, **options):
        ordenes_amatista = self._cargar_ordenes()
        
        for ov_data in ordenes_amatista:
            cliente = Cliente.objects.get(numero_documento=ov_data['cliente_doc'])
            vendedor = PerfilUsuario.objects.get(usuario__email=ov_data['vendedor_email'])
            
            orden = OrdenVenta.objects.create(
                numero=ov_data['numero'],
                fecha=ov_data['fecha'],
                cliente=cliente,
                vendedor=vendedor,
                estado='PENDIENTE',
                total_gravada=ov_data['total_gravada'],
                total_igv=ov_data['total_igv'],
                total_venta=ov_data['total_venta'],
            )
            
            # Detalles
            for detalle_data in ov_data['detalles']:
                producto = Producto.objects.get(nombre__iexact=detalle_data['nombre_producto'])
                DetalleOrdenVenta.objects.create(
                    orden_venta=orden,
                    producto=producto,
                    cantidad=detalle_data['cantidad'],
                    precio_unitario=detalle_data['precio_unitario'],
                    subtotal=detalle_data['subtotal'],
                    igv=detalle_data['igv'],
                    total=detalle_data['total'],
                )
```

**Entrada**: Órdenes + detalles Amatista  
**Salida**: `ordenes_venta` + `detalle_ordenes_venta`  
**Dependencias**: Clientes, Vendedores, Productos  

---

### 3.2 Migrar Ventas + Detalles

**Script**: `scripts/migracion_ventas.py`

Similar a 3.1, pero crea registros en `ventas` + `detalle_ventas`.

**Nota**: Si una venta tiene asociado un comprobante electrónico (factura/boleta), migrar separadamente en 3.4.

---

### 3.3 Migrar Pedidos (Distribución) + Seguimiento

**Script**: `scripts/migracion_pedidos.py`

```python
class Command(BaseCommand):
    """
    Migra pedidos con código de seguimiento público
    """
    
    def handle(self, *args, **options):
        pedidos_amatista = self._cargar_pedidos()
        
        for pedido_data in pedidos_amatista:
            venta = Venta.objects.get(numero=pedido_data['venta_numero'])
            cliente = venta.cliente
            
            # Generar código único de 8 caracteres
            codigo_seguimiento = self._generar_codigo_seguimiento()
            
            pedido = Pedido.objects.create(
                numero=pedido_data['numero'],
                codigo_seguimiento=codigo_seguimiento,  # Público
                fecha=pedido_data['fecha'],
                venta=venta,
                cliente=cliente,
                direccion_entrega=pedido_data['direccion'],
                latitud=pedido_data.get('lat'),
                longitud=pedido_data.get('lng'),
                estado='PENDIENTE',
                transportista=None,  # Se asignará después
                estado_produccion='PENDIENTE',
                is_active=True,
            )
            
            # Registrar seguimiento inicial
            SeguimientoPedido.objects.create(
                pedido=pedido,
                estado='PENDIENTE',
                descripcion='Pedido creado',
                fecha_evento=pedido.created_at,
            )
```

**Entrada**: Pedidos Amatista  
**Salida**: `pedidos` + `seguimiento_pedidos`  
**Nuevos Campos**: `codigo_seguimiento` (único, 8 chars), `estado_produccion`  

---

### 3.4 Migrar Comprobantes Electrónicos (Facturas/Boletas)

**Script**: `scripts/migracion_comprobantes.py`

```python
class Command(BaseCommand):
    """
    Migra facturas y boletas con hashes SUNAT y CDRs
    Formato: Tipo (01=Factura, 03=Boleta), Serie, Número
    """
    
    def handle(self, *args, **options):
        comprobantes_amatista = self._cargar_comprobantes()
        
        for comp_data in comprobantes_amatista:
            cliente = Cliente.objects.get(numero_documento=comp_data['cliente_doc'])
            venta = Venta.objects.get(numero=comp_data['venta_numero'])
            
            comprobante = Comprobante.objects.create(
                tipo_comprobante=comp_data['tipo'],  # '01' o '03'
                serie=comp_data['serie'],
                numero=comp_data['numero'],
                fecha_emision=comp_data['fecha'],
                cliente=cliente,
                moneda='PEN',
                total_gravada=comp_data['total_gravada'],
                total_igv=comp_data['total_igv'],
                total_venta=comp_data['total_venta'],
                estado_sunat='ACEPTADO',  # Si ya fue aceptado en Amatista
                hash_sunat=comp_data.get('hash_sunat', ''),
                qr_sunat=comp_data.get('qr_sunat', ''),
                venta=venta,
            )
            
            # Detalles
            for detalle_data in comp_data['detalles']:
                DetalleComprobante.objects.create(
                    comprobante=comprobante,
                    codigo_producto=detalle_data.get('codigo_producto', ''),
                    descripcion=detalle_data['descripcion'],
                    cantidad=detalle_data['cantidad'],
                    precio_unitario=detalle_data['precio_unitario'],
                    subtotal=detalle_data['subtotal'],
                    igv=detalle_data['igv'],
                    total=detalle_data['total'],
                )
```

**Entrada**: Facturas/Boletas Amatista (con hash SUNAT si disponible)  
**Salida**: `comprobantes` + `detalle_comprobantes`  
**PDFs/XMLs**: Se migran a R2 en 3.5  

---

### 3.5 Migrar PDFs, XMLs, CDRs a R2

**Script**: `scripts/migracion_documentos_comprobantes_r2.py`

```python
class Command(BaseCommand):
    """
    Sube PDFs, XMLs, CDRs de comprobantes a R2
    Estructura: j-soluciones-documentos/comprobantes/{tipo}/{serie}/{numero}/
    """
    
    def handle(self, *args, **options):
        s3_client = self._init_r2_client()
        directorio_docs = Path('Amatista-docs/documentos/')
        
        for comp in Comprobante.objects.filter(venta__isnull=False):
            # Buscar archivos locales
            pdf_path = directorio_docs / f"{comp.tipo_comprobante}-{comp.serie}-{comp.numero}.pdf"
            xml_path = directorio_docs / f"{comp.tipo_comprobante}-{comp.serie}-{comp.numero}.xml"
            
            if pdf_path.exists():
                r2_key_pdf = self._subir_a_r2(s3_client, pdf_path, tipo='pdf')
                comp.pdf_r2_key = r2_key_pdf
            
            if xml_path.exists():
                r2_key_xml = self._subir_a_r2(s3_client, xml_path, tipo='xml')
                comp.xml_r2_key = r2_key_xml
            
            comp.save()
```

**Entrada**: PDFs/XMLs locales  
**Salida**: `comprobante.pdf_r2_key`, `comprobante.xml_r2_key`  
**Bucket R2**: `j-soluciones-documentos`  

---

### 3.6 Migrar Evidencias de Entrega

**Script**: `scripts/migracion_evidencias_entrega_r2.py`

```python
class Command(BaseCommand):
    """
    Migra evidencias de entrega (fotos, firmas) a R2
    """
    
    def handle(self, *args, **options):
        s3_client = self._init_r2_client()
        directorio_evidencias = Path('Amatista-docs/evidencias/')
        
        for pedido in Pedido.objects.filter(estado='ENTREGADO'):
            evidencias_locales = directorio_evidencias.glob(f"{pedido.numero}/*")
            
            for archivo in evidencias_locales:
                # Subir a R2
                r2_key = self._subir_a_r2(s3_client, archivo, tipo='evidencia')
                
                # Crear MediaArchivo
                media = MediaArchivo.objects.create(
                    entidad_tipo='evidencia_entrega',
                    entidad_id=pedido.id,
                    tipo_archivo='imagen',
                    nombre_original=archivo.name,
                    r2_key=r2_key,
                    url_publica=self._generar_presigned_url(r2_key),
                    mime_type=self._detectar_mime(archivo),
                    tamano_bytes=archivo.stat().st_size,
                )
                
                # Crear EvidenciaEntrega
                EvidenciaEntrega.objects.create(
                    pedido=pedido,
                    tipo='FOTO',
                    media=media,
                )
```

**Entrada**: Imágenes de evidencias locales  
**Salida**: `evidencias_entrega` + `media_archivos`  
**Bucket R2**: `j-soluciones-evidencias`  

---

## 🔗 FASE 4: VALIDACIÓN E INTEGRIDAD (Semana 2)

### 4.1 Script de Validación

```python
class Command(BaseCommand):
    """
    Valida completitud y integridad de migración
    """
    
    def handle(self, *args, **options):
        validaciones = {
            'productos': self._validar_productos(),
            'clientes': self._validar_clientes(),
            'usuarios': self._validar_usuarios(),
            'ordenes_venta': self._validar_ordenes(),
            'pedidos': self._validar_pedidos(),
            'comprobantes': self._validar_comprobantes(),
            'imagenes': self._validar_imagenes(),
        }
        
        reporte = self._generar_reporte(validaciones)
        self._guardar_reporte(reporte)
        self.stdout.write(self.style.SUCCESS(reporte))
```

---

## 📈 CRONOGRAMA EJECUTIVO

| Fase | Tarea | Duración | Inicio | Fin |
|------|-------|----------|--------|-----|
| 1.1 | Subir imágenes a R2 | 20 min | D1 | D1 |
| 1.2 | Actualizar schema SQL | 5 min | D1 | D1 |
| 2.1 | Migrar categorías | 5 min | D1 | D1 |
| 2.2 | Migrar 35 productos | 10 min | D2 | D2 |
| 2.3 | Vincular imágenes | 5 min | D2 | D2 |
| 2.4 | Migrar clientes | 15 min | D2 | D2 |
| 2.5 | Migrar usuarios | 20 min | D3 | D3 |
| 3.1 | Migrar órdenes venta | 30 min | D4 | D4 |
| 3.2 | Migrar ventas | 25 min | D5 | D5 |
| 3.3 | Migrar pedidos | 20 min | D5 | D5 |
| 3.4 | Migrar comprobantes | 30 min | D6 | D6 |
| 3.5 | Migrar docs a R2 | 25 min | D7 | D7 |
| 3.6 | Migrar evidencias | 20 min | D7 | D7 |
| 4.1 | Validación completa | 30 min | D8 | D8 |

**Total**: ~4 días de trabajo

---

## ✅ CHECKLIST PRE-MIGRACIÓN

- [ ] Backup completo de BD Amatista
- [ ] Credenciales R2 configuradas en `.env`
- [ ] Carpeta `Amatista-docs/imagenes_descargadas/` verificada (35 imágenes)
- [ ] `mapeo_imagenes.json` validado
- [ ] Schema SQL actualizado (nueva columna en productos)
- [ ] Roles Django creados (ADMINISTRADOR, VENDEDOR, CONDUCTOR)
- [ ] Scripts de migración revisados y testeados
- [ ] BD de producción con respaldo

---

## 🔐 CONSIDERACIONES DE SEGURIDAD

1. **Encriptación**: Credenciales R2 en variables de entorno, nunca en código
2. **Presigned URLs**: TTL configurable por tipo (default: 7 días)
3. **Bucket Privado**: Solo acceso via presigned URLs
4. **Auditoría**: Log de cada migración en `log_actividad`
5. **Rollback**: Script para revertir cambios si falla migración

---

## 📚 REFERENCIAS

- Mapeo de Imágenes: `Amatista-docs/imagenes_descargadas/mapeo_imagenes.json`
- Configuración R2: `Jsoluciones-be/config/settings/base.py` (líneas 360-388)
- Servicio R2: `Jsoluciones-be/core/utils/r2_storage.py`
- Modelos: `Jsoluciones-be/apps/inventario/models.py`, `media/models.py`
- SQL Schema: `Jsoluciones-docs/SQL_JSOLUCIONES.sql` (v4)

---

**Status**: 🟢 APROBADO PARA IMPLEMENTACIÓN
