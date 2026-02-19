# PLAN DE INTEGRACIÓN — JSoluciones ERP

> Fecha: 2026-02-19
> Estado: Documentación de integraciones pendientes

---

## 1. FUNCIONALIDADES PENDIENTES

### 1.1 Intereses de Mora (Finanzas)

**Archivo:** `apps/finanzas/tasks.py:78-84`

**Qué hace ahora:**
```python
def calcular_intereses_mora(self):
    """STUB: Se implementará con reglas específicas del negocio."""
    logger.info("STUB: Cálculo de intereses de mora — pendiente de implementar.")
    return {"procesado": False, "mensaje": "stub"}
```

**Qué necesita para implementarse:**

| Requisito | Descripción |
|-----------|-------------|
| Tasa de interés | Definir tasa mensual/anual (ej: 2% mensual) |
| Días de gracia | Días después del vencimiento antes de aplicar interés |
| Tipo de cálculo | Simple o compuesto |
| Configuración | Campo en `empresa.Configuracion` o tabla separada |
| Límite legal | Verificar límites según normativa peruana |

**Pasos de implementación:**
1. Agregar campos a `empresa.Configuracion`:
   - `tasa_interes_mora_mensual` (Decimal, default 0)
   - `dias_gracia_mora` (Integer, default 0)
   - `calcular_intereses_automatico` (Boolean, default False)
2. Crear modelo `InteresMora` en finanzas:
   - `cxc` (ForeignKey a CuentaPorCobrar)
   - `monto_interes` (Decimal)
   - `dias_mora` (Integer)
   - `fecha_calculo` (Date)
3. Implementar lógica en `services.py`:
   - `calcular_interes_cxc(cxc_id)` — calcula interés de una CxC
   - `aplicar_interes_a_cxc(cxc_id)` — suma interés al monto_pendiente
4. Actualizar tarea Celery para ejecutar cálculo automático

**Dependencias:** Ninguna externa

---

### 1.2 Estado de Resultados (Finanzas)

**Archivo:** `apps/finanzas/tasks.py:124-130`

**Qué hace ahora:**
```python
def generar_estado_resultados(self):
    """STUB: Se completará con lógica contable real."""
    logger.info("STUB: Estado de resultados — pendiente de implementar.")
    return {"procesado": False, "mensaje": "stub"}
```

**Qué necesita para implementarse:**

| Requisito | Descripción |
|-----------|-------------|
| Plan contable | Usar modelo `CuentaContable` existente |
| Clasificación de cuentas | Ingresos, Gastos, Costos |
| Asientos contables | Modelo `AsientoContable` existe |
| Período contable | Mes/año a generar |

**Pasos de implementación:**
1. Verificar que `CuentaContable` tenga campo `tipo` (activo, pasivo, ingreso, gasto, capital)
2. Crear servicio en `apps/finanzas/services.py`:
   ```python
   def generar_estado_resultados(periodo_inicio, periodo_fin):
       # Sumar asientos de ingresos
       # Sumar asientos de gastos
       # Calcular utilidad bruta
       # Calcular utilidad neta
       return {
           'ingresos_totales': ...,
           'gastos_totales': ...,
           'utilidad_bruta': ...,
           'utilidad_neta': ...,
       }
   ```
3. Crear View en `apps/reportes/views.py`:
   - `EstadoResultadosView` con parámetros de fecha
4. Agregar al beat schedule (mensual)

**Dependencias:** Que los asientos contables se generen correctamente

---

### 1.3 WhatsApp (Meta API)

**Archivo:** `apps/whatsapp/services.py:31`

**Qué necesita:**

| Requisito | Descripción |
|-----------|-------------|
| Meta Business Account | Cuenta de WhatsApp Business |
| Phone Number ID | ID del número de WhatsApp |
| Access Token | Token de acceso permanente |
| Webhook Verify Token | Token para verificar webhook |

**Pasos de implementación:**
1. Crear cuenta en Meta Business Suite
2. Configurar número de WhatsApp Business
3. Crear plantillas aprobadas por Meta
4. Implementar llamada a API:
   ```python
   # apps/whatsapp/services.py
   def enviar_mensaje(numero_destino, plantilla_id, parametros):
       url = f"https://graph.facebook.com/v18.0/{PHONE_NUMBER_ID}/messages"
       headers = {"Authorization": f"Bearer {ACCESS_TOKEN}"}
       payload = {
           "messaging_product": "whatsapp",
           "to": numero_destino,
           "type": "template",
           "template": {"name": plantilla_id, "language": {"code": "es"}, "components": [...]}
       }
       response = requests.post(url, headers=headers, json=payload)
       ...
   ```
5. Configurar webhook para recibir respuestas

**Dependencias:** Credenciales de Meta (usuario las proveerá)

---

### 1.4 Validación SUNAT (Proveedores)

**Archivo:** `apps/compras/tasks.py:91`

**Qué necesita:**

| Requisito | Descripción |
|-----------|-------------|
| Servicio de validación | Nubefact ya tiene endpoint para validar CDR |
| Token Nubefact | Ya configurado en settings |
| RUC del proveedor | Ya existe en modelo Proveedor |

**Pasos de implementación:**
1. Usar endpoint de Nubefact para validar factura de proveedor
2. Almacenar respuesta CDR (Constancia de Recepción)
3. Marcar factura como validada/rechazada

**Dependencias:** Nubefact (ya integrado para facturación)

---

### 1.5 GPS / Rastreo (Distribución)

**Archivo:** `apps/distribucion/tasks.py:62`

**Qué necesita:**

| Requisito | Descripción |
|-----------|-------------|
| App móvil | Aplicación del repartidor |
| Endpoint de ubicación | API para recibir coordenadas |
| Google Maps API (opcional) | Para optimización de rutas |

**Pasos de implementación:**
1. Crear endpoint en backend para recibir ubicación:
   - `POST /api/v1/distribucion/pedidos/{id}/ubicacion/`
   - Recibe: latitud, longitud, timestamp
2. Actualizar campo `latitud`/`longitud` en Pedido o SeguimientoPedido
3. Para optimización de rutas:
   - Integrar con Google Routes API o similar
   - O usar librería de optimización local (OR-Tools)

**Dependencias:** App móvil del repartidor

---

### 1.6 Exportar Excel/PDF (Reportes)

**Archivo:** `apps/reportes/tasks.py:41-63`

**Qué necesita:**

| Requisito | Descripción |
|-----------|-------------|
| openpyxl | Librería para generar Excel |
| reportlab o weasyprint | Librería para generar PDF |

**Pasos de implementación:**
1. Instalar dependencias:
   ```bash
   uv pip install openpyxl reportlab weasyprint
   ```
2. Crear servicio de exportación:
   ```python
   # apps/reportes/services.py
   def exportar_ventas_excel(queryset):
       wb = openpyxl.Workbook()
       ws = wb.active
       ws.title = "Ventas"
       # Agregar headers y datos
       ...
       return wb
   
   def exportar_ventas_pdf(queryset):
       # Generar HTML y convertir a PDF
       ...
       return pdf_bytes
   ```
3. Crear endpoint que retorne archivo

**Dependencias:** Librerías Python (openpyxl, reportlab)

---

## 2. ORDEN SUGERIDO DE IMPLEMENTACIÓN

### Fase 1 — Sin dependencias externas
1. ✅ Intereses de Mora (solo lógica interna)
2. ✅ Estado de Resultados (usa datos existentes)
3. ✅ Exportar Excel/PDF (solo librerías Python)

### Fase 2 — Con configuración
4. WhatsApp (requiere cuenta Meta)
5. Validación SUNAT (usa Nubefact existente)

### Fase 3 — Con desarrollo móvil
6. GPS / Rastreo (requiere app móvil)

---

## 3. ESTADO ACTUAL DEL BACKEND

| Módulo | Modelos | Serializers | Services | Views | URLs | Tasks | Estado |
|--------|---------|-------------|----------|-------|------|-------|--------|
| empresa | ✅ | ✅ | ✅ | ✅ | ✅ | - | Completo |
| usuarios | ✅ | ✅ | ✅ | ✅ | ✅ | - | Completo |
| clientes | ✅ | ✅ | ✅ | ✅ | ✅ | - | Completo |
| proveedores | ✅ | ✅ | ✅ | ✅ | ✅ | - | Completo |
| inventario | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Completo |
| ventas | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Completo |
| facturacion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Completo |
| media | - | - | - | - | ✅ | - | Básico |
| compras | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Completo |
| finanzas | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Completo (con stubs) |
| distribucion | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Completo (con stubs) |
| whatsapp | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Completo (con stubs) |
| reportes | - | ✅ | ✅ | ✅ | ✅ | ✅ | Completo (con stubs) |

---

## 4. PRÓXIMOS PASOS INMEDIATOS

1. **Celery beat schedule** — Agregar tareas de los 5 módulos nuevos
2. **Celery task routes** — Configurar colas para los 5 módulos nuevos
3. **Implementar intereses de mora** — Fase 1
4. **Implementar estado de resultados** — Fase 1
5. **Implementar exportación Excel/PDF** — Fase 1
