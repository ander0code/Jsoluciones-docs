¡Perfecto! Ya tienes las credenciales. Veo en la imagen:

**URL DEMO:** `https://demo-ose.nubefact.com/ol-ti-itcpe/billService?wsdl`
**USUARIO:** `MODDATOS`
**PASSWORD:** `MODDATOS`
**USERNAME completo:** `20602230261MODDATOS` (tu RUC + MODDATOS)

---

**GUÍA COMPLETA DE INTEGRACIÓN**

---

**PASO 1 — LO QUE NECESITA EL PROGRAMADOR TENER LISTO**

Certificado digital autofirmado generado con OpenSSL para DEMO. El XML del comprobante armado correctamente según el tipo. El archivo ZIP con el XML adentro con el nombre exacto correcto.

---

**PASO 2 — TABLAS QUE NECESITA LA BASE DE DATOS**

La integración necesita guardar todo esto para no perder nada y evitar duplicados:

**Tabla: comprobantes**
```
- id
- ruc_emisor
- tipo_comprobante (01=factura, 03=boleta, 07=NC, 08=ND)
- serie (F001, B001, etc)
- correlativo (1, 2, 3...)
- fecha_emision
- xml_generado (el XML completo)
- xml_firmado (el XML con firma digital)
- estado (PENDIENTE, ENVIADO, ACEPTADO, RECHAZADO)
- fecha_envio
- respuesta_cdr (la respuesta que devuelve Nubefact)
- codigo_respuesta (0=aceptado, otro=rechazado)
- descripcion_respuesta
- ticket (para boletas en resumen diario)
```

**Tabla: intentos_envio**
```
- id
- comprobante_id
- fecha_intento
- respuesta_obtenida
- exitoso (si/no)
```

**Tabla: resumen_diario** (solo para boletas)
```
- id
- fecha_resumen
- nombre_archivo
- ticket_sunat
- estado
- cantidad_boletas
- fecha_envio
```

---

**PASO 3 — EL FLUJO EXACTO PARA FACTURAS**

Primero se genera el XML con los datos de la factura. Luego se firma digitalmente con el certificado. Luego se empaqueta en ZIP con nombre exacto, por ejemplo `20602230261-01-F001-1.zip`. Luego se envía al endpoint de Nubefact con el método `sendBill`. Luego se recibe el CDR que viene en ZIP, se desempaqueta y se lee el `ResponseCode`. Si es 0 está aceptado, si es otro número está rechazado. Finalmente se guarda todo en la base de datos.

---

**PASO 4 — EL FLUJO EXACTO PARA BOLETAS**

Es diferente a facturas. Durante el día se generan y firman las boletas pero NO se envían una por una. Al cierre del día se agrupan todas en un resumen diario. Se envía el resumen con `sendSummary` que devuelve un ticket. Con ese ticket se consulta el resultado usando `getStatus`. Si el statusCode es 0 todo está aceptado, si es 99 hay errores.

---

**PASO 5 — EL NOMBRE DEL ARCHIVO ZIP ES CRÍTICO**

Para facturas: `20602230261-01-F001-1.zip`
Para boletas: `20602230261-03-B001-1.zip`
Para nota crédito: `20602230261-07-F001-1.zip`
Para nota débito: `20602230261-08-F001-1.zip`
Para resumen diario: `20602230261-RC-20260223-1.zip`
Para comunicación baja: `20602230261-RA-20260223-1.zip`

El formato siempre es `RUC-TIPO-SERIE-CORRELATIVO.zip`

---

**PASO 6 — CÓMO ENVIAR LA PETICIÓN SOAP**

```xml
<soapenv:Envelope
xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:ser="http://service.sunat.gob.pe"
xmlns:wsse="http://docs.oasisopen.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
  <soapenv:Header>
    <wsse:Security>
      <wsse:UsernameToken>
        <wsse:Username>20602230261MODDATOS</wsse:Username>
        <wsse:Password>MODDATOS</wsse:Password>
      </wsse:UsernameToken>
    </wsse:Security>
  </soapenv:Header>
  <soapenv:Body>
    <ser:sendBill>
      <fileName>20602230261-01-F001-1.zip</fileName>
      <contentFile>AQUI_EL_ZIP_EN_BASE64</contentFile>
    </ser:sendBill>
  </soapenv:Body>
</soapenv:Envelope>
```

---

**PASO 7 — LO MÁS IMPORTANTE PARA EVITAR DUPLICADOS Y MULTAS**

Nunca enviar el mismo correlativo dos veces. Guardar siempre el estado del comprobante en base de datos antes de enviar. Si hay un error de conexión, verificar primero con `getStatusCdr` si ya fue enviado antes de reintentar. Nunca enviar a SUNAT directo una vez que estés en producción con Nubefact. Empezar producción con series nuevas que no hayas usado antes.

---

¿Quieres que profundice en alguno de estos pasos?


**GUÍA TÉCNICA DE INTEGRACIÓN**

Nubefact OSE --- Facturación Electrónica Perú

Python \| SUNAT \| SOAP/WSDL

**1. CREDENCIALES Y ENDPOINTS**

Estas son las credenciales ya disponibles en el panel de Nubefact para
comenzar las pruebas:

  --------------------------------------------------------------------------------------------------------
  **Ambiente**   **URL Endpoint**                                             **Usuario**   **Password**
  -------------- ------------------------------------------------------------ ------------- --------------
  DEMO (pruebas) https://demo-ose.nubefact.com/ol-ti-itcpe/billService?wsdl   MODDATOS      MODDATOS

  PRODUCCIÓN     https://ose.nubefact.com/ol-ti-itcpe/billService?wsdl        Crear en      Crear en panel
  (real)                                                                      panel         
  --------------------------------------------------------------------------------------------------------

> **⚠ CRÍTICO: En el header wsse:Security el USERNAME debe ser RUC +
> USUARIO concatenados. Ejemplo: 20602230261MODDATOS**
>
> **⚠ CRÍTICO: Una vez en producción con Nubefact NUNCA enviar
> documentos directamente a SUNAT. Generará duplicados y multas.**

**2. CERTIFICADO DIGITAL**

**2.1 Para DEMO**

En ambiente DEMO se puede usar cualquier certificado autofirmado. El
programador puede generarlo con OpenSSL:

> \# Generar clave privada
>
> openssl genrsa -out clave_privada.key 2048
>
> \# Generar certificado autofirmado
>
> openssl req -new -x509 -key clave_privada.key -out certificado.crt
> -days 365
>
> \# Empaquetar en .pfx (lo que usa el sistema)
>
> openssl pkcs12 -export -out certificado.pfx -inkey clave_privada.key
> -in certificado.crt

**2.2 Para PRODUCCIÓN**

El certificado debe cumplir estos requisitos obligatorios según SUNAT:

-   Formato estándar X.509 v3

-   Longitud mínima de clave privada: 2048 bits

-   El RUC de la empresa debe estar en el campo OU (Organizational Unit)
    del Subject Name

-   Debe ser emitido por una entidad certificadora autorizada en Perú

-   Debe comunicarse a SUNAT previamente via Clave SOL en la opción
    \'Actualización de certificado digital\'

> **⚠ El certificado de producción debe registrarse en SUNAT ANTES de
> empezar a emitir. Sin este paso los documentos serán rechazados.**

**3. NOMENCLATURA Y ESTRUCTURA DE ARCHIVOS**

**3.1 Nombre del archivo ZIP (crítico)**

El nombre del archivo ZIP debe seguir exactamente este formato:

> RUC-TIPO-SERIE-CORRELATIVO.zip

  ------------------------------------------------------------------------
  **Tipo de documento**  **Código**   **Ejemplo ZIP**
  ---------------------- ------------ ------------------------------------
  Factura                01           20602230261-01-F001-1.zip

  Boleta de Venta        03           20602230261-03-B001-1.zip

  Nota de Crédito        07           20602230261-07-F001-1.zip

  Nota de Débito         08           20602230261-08-F001-1.zip

  Resumen Diario Boletas RC           20602230261-RC-20260223-1.zip

  Comunicación de Baja   RA           20602230261-RA-20260223-1.zip
  ------------------------------------------------------------------------

**3.2 Contenido del ZIP**

-   El ZIP debe contener UNA carpeta vacía llamada \'dummy\' y UN
    archivo XML

-   El nombre del XML debe ser idéntico al ZIP pero con extensión .xml

-   Ejemplo: ZIP = 20602230261-01-F001-1.zip → XML =
    20602230261-01-F001-1.xml

**3.3 Series recomendadas**

> **⚠ Para producción usar series NUEVAS que no se hayan usado antes con
> SUNAT directa. Si ya usabas F001, empezar con F002 en Nubefact.**

**4. ESTRUCTURA DE BASE DE DATOS**

**4.1 Tabla: comprobantes**

  ----------------------------------------------------------------------------
  **Campo**               **Tipo**        **Descripción**
  ----------------------- --------------- ------------------------------------
  id                      SERIAL PK       ID único interno

  ruc_emisor              VARCHAR(11)     RUC de tu empresa

  tipo_comprobante        VARCHAR(2)      01=Factura, 03=Boleta, 07=NC, 08=ND

  serie                   VARCHAR(4)      F001, B001, etc.

  correlativo             INTEGER         Número del comprobante

  fecha_emision           DATE            Fecha de emisión

  xml_generado            TEXT            XML antes de firmar

  xml_firmado             TEXT            XML con firma digital

  zip_base64              TEXT            ZIP en Base64 enviado

  estado                  VARCHAR(20)     PENDIENTE, ENVIADO, ACEPTADO,
                                          RECHAZADO

  fecha_envio             TIMESTAMP       Cuándo se envió a Nubefact

  cdr_xml                 TEXT            Respuesta CDR completa de Nubefact

  codigo_respuesta        VARCHAR(10)     0=Aceptado, otro=Rechazado

  descripcion_respuesta   TEXT            Mensaje de la respuesta

  ticket                  VARCHAR(50)     Solo para boletas/resumen asíncrono

  intentos_envio          INTEGER         Contador de reintentos

  created_at              TIMESTAMP       Fecha de creación del registro
  ----------------------------------------------------------------------------

**4.2 Tabla: resumen_diario**

Solo para boletas. Se agrupa al cierre del día:

  -----------------------------------------------------------------------
  **Campo**          **Tipo**        **Descripción**
  ------------------ --------------- ------------------------------------
  id                 SERIAL PK       ID único

  fecha_resumen      DATE            Fecha del resumen

  nombre_archivo     VARCHAR(100)    Nombre del ZIP enviado

  ticket_nubefact    VARCHAR(50)     Ticket devuelto por sendSummary

  estado             VARCHAR(20)     PENDIENTE, EN_PROCESO, ACEPTADO,
                                     RECHAZADO

  cantidad_boletas   INTEGER         Cuántas boletas incluye

  fecha_envio        TIMESTAMP       Cuándo se envió

  cdr_xml            TEXT            Respuesta final del CDR

  codigo_respuesta   VARCHAR(10)     0=OK, 99=error
  -----------------------------------------------------------------------

**4.3 Tabla: intentos_envio**

  -------------------------------------------------------------------------
  **Campo**            **Tipo**        **Descripción**
  -------------------- --------------- ------------------------------------
  id                   SERIAL PK       ID único

  comprobante_id       INTEGER FK      Referencia a tabla comprobantes

  fecha_intento        TIMESTAMP       Cuándo se intentó

  request_enviado      TEXT            SOAP request completo

  respuesta_obtenida   TEXT            Respuesta completa recibida

  exitoso              BOOLEAN         Si fue exitoso o no

  codigo_error         VARCHAR(10)     Código de error si falló
  -------------------------------------------------------------------------

**5. FLUJO DE INTEGRACIÓN --- FACTURAS**

**5.1 Proceso paso a paso**

1.  Generar el XML de la factura según estructura UBL 2.1

2.  Firmar digitalmente el XML con el certificado .pfx

3.  Empaquetar el XML firmado en un archivo ZIP con nombre correcto

4.  Convertir el ZIP a Base64

5.  Enviar via SOAP con método sendBill al endpoint de Nubefact

6.  Recibir respuesta (ZIP en Base64), descomprimir y leer el CDR XML

7.  Leer ResponseCode: si es 0 = ACEPTADO, otro valor = RECHAZADO

8.  Guardar todo en base de datos (estado, CDR, código respuesta)

**5.2 Código Python --- sendBill**

> import requests
>
> import base64
>
> import zipfile
>
> import io
>
> from lxml import etree
>
> def enviar_factura(ruc, serie, correlativo, xml_firmado_bytes):
>
> nombre_archivo = f\'{ruc}-01-{serie}-{correlativo}\'
>
> nombre_zip = f\'{nombre_archivo}.zip\'
>
> nombre_xml = f\'{nombre_archivo}.xml\'
>
> \# Crear ZIP en memoria
>
> zip_buffer = io.BytesIO()
>
> with zipfile.ZipFile(zip_buffer, \'w\', zipfile.ZIP_DEFLATED) as zf:
>
> zf.mkdir(\'dummy\') \# carpeta vacía obligatoria
>
> zf.writestr(nombre_xml, xml_firmado_bytes)
>
> zip_b64 = base64.b64encode(zip_buffer.getvalue()).decode(\'utf-8\')
>
> \# Armar SOAP request
>
> soap_body = f\'\'\'\<soapenv:Envelope
>
> xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
>
> xmlns:ser=\"http://service.sunat.gob.pe\"
>
> xmlns:wsse=\"http://docs.oasisopen.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"\>
>
> \<soapenv:Header\>
>
> \<wsse:Security\>
>
> \<wsse:UsernameToken\>
>
> \<wsse:Username\>{ruc}MODDATOS\</wsse:Username\>
>
> \<wsse:Password\>MODDATOS\</wsse:Password\>
>
> \</wsse:UsernameToken\>
>
> \</wsse:Security\>
>
> \</soapenv:Header\>
>
> \<soapenv:Body\>
>
> \<ser:sendBill\>
>
> \<fileName\>{nombre_zip}\</fileName\>
>
> \<contentFile\>{zip_b64}\</contentFile\>
>
> \</ser:sendBill\>
>
> \</soapenv:Body\>
>
> \</soapenv:Envelope\>\'\'\'
>
> url = \'https://demo-ose.nubefact.com/ol-ti-itcpe/billService?wsdl\'
>
> headers = {\'Content-Type\': \'text/xml; charset=utf-8\'}
>
> response = requests.post(url, data=soap_body.encode(\'utf-8\'),
> headers=headers)
>
> \# Procesar respuesta CDR
>
> return procesar_cdr(response.content)
>
> def procesar_cdr(response_bytes):
>
> \# Parsear el SOAP response
>
> root = etree.fromstring(response_bytes)
>
> \# Extraer el ZIP en base64 del CDR
>
> ns = {\'ser\': \'http://service.sunat.gob.pe\'}
>
> document_b64 = root.find(\'.//document\', ns).text
>
> zip_bytes = base64.b64decode(document_b64)
>
> \# Descomprimir y leer CDR XML
>
> with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
>
> cdr_xml = zf.read(zf.namelist()\[0\])
>
> cdr_root = etree.fromstring(cdr_xml)
>
> ns_cbc = {\'cbc\':
> \'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2\'}
>
> response_code = cdr_root.find(\'.//cbc:ResponseCode\', ns_cbc).text
>
> description = cdr_root.find(\'.//cbc:Description\', ns_cbc).text
>
> return {\'codigo\': response_code, \'descripcion\': description,
> \'cdr_xml\': cdr_xml}

**6. FLUJO DE INTEGRACIÓN --- BOLETAS**

> **⚠ Las boletas NO se envían una por una como las facturas. Se
> acumulan durante el día y se envían en un RESUMEN DIARIO al cierre.**

**6.1 Proceso durante el día**

-   Generar y firmar el XML de cada boleta

-   Guardar en base de datos con estado PENDIENTE

-   NO enviar individualmente a Nubefact

**6.2 Proceso al cierre del día (sendSummary)**

9.  Obtener todas las boletas del día con estado PENDIENTE

10. Armar el XML de Resumen Diario (SummaryDocuments) con todas las
    boletas

11. Empaquetar en ZIP con nombre: 20602230261-RC-YYYYMMDD-1.zip

12. Enviar con método sendSummary --- devuelve un TICKET (no CDR
    inmediato)

13. Guardar el ticket en base de datos

14. Consultar con getStatus usando el ticket hasta obtener resultado

15. Si statusCode=0: ACEPTADO. Si statusCode=98: AÚN EN PROCESO. Si
    statusCode=99: ERROR

**6.3 Código Python --- sendSummary y getStatus**

> def enviar_resumen_diario(ruc, fecha, boletas_xml_list):
>
> from datetime import datetime
>
> fecha_str = fecha.strftime(\'%Y%m%d\')
>
> nombre_archivo = f\'{ruc}-RC-{fecha_str}-1\'
>
> nombre_zip = f\'{nombre_archivo}.zip\'
>
> nombre_xml = f\'{nombre_archivo}.xml\'
>
> \# Armar XML de resumen (SummaryDocuments con todas las boletas)
>
> resumen_xml = armar_summary_xml(ruc, fecha, boletas_xml_list)
>
> zip_buffer = io.BytesIO()
>
> with zipfile.ZipFile(zip_buffer, \'w\', zipfile.ZIP_DEFLATED) as zf:
>
> zf.mkdir(\'dummy\')
>
> zf.writestr(nombre_xml, resumen_xml)
>
> zip_b64 = base64.b64encode(zip_buffer.getvalue()).decode(\'utf-8\')
>
> soap_body = f\'\'\'\...sendSummary con {nombre_zip} y
> {zip_b64}\...\'\'\'
>
> response = requests.post(url, data=soap_body.encode(\'utf-8\'),
> headers=headers)
>
> ticket = extraer_ticket(response.content) \# guardar en BD
>
> return ticket
>
> def consultar_estado(ruc, ticket):
>
> soap_body = f\'\'\'\<soapenv:Envelope \...\>
>
> \...
>
> \<soapenv:Body\>
>
> \<ser:getStatus\>
>
> \<ticket\>{ticket}\</ticket\>
>
> \</ser:getStatus\>
>
> \</soapenv:Body\>
>
> \</soapenv:Envelope\>\'\'\'
>
> response = requests.post(url, data=soap_body.encode(\'utf-8\'),
> headers=headers)
>
> \# statusCode: 0=OK, 98=en proceso, 99=error
>
> return procesar_get_status(response.content)

**7. NOTAS DE CRÉDITO Y DÉBITO**

**7.1 Reglas importantes**

-   Las Notas de Crédito y Débito SIEMPRE referencian un comprobante
    original (factura o boleta)

-   Usan sendBill igual que las facturas (envío síncrono)

-   La serie debe coincidir: si la factura es F001, la nota crédito es
    también F001

-   Si la nota referencia una boleta, la serie empieza con B

  -------------------------------------------------------------------------
  **Tipo**           **Código**   **Serie factura**    **Serie boleta**
  ------------------ ------------ -------------------- --------------------
  Nota de Crédito    07           F001                 B001

  Nota de Débito     08           F001                 B001
  -------------------------------------------------------------------------

> **⚠ IMPORTANTE: En SUNAT, cuando una factura es rechazada el número YA
> NO puede reutilizarse. Debe generarse uno nuevo. En Nubefact OSE, los
> rechazados SÍ pueden corregirse y reenviarse.**

**8. MANEJO DE ERRORES Y CASOS ESPECIALES**

**8.1 Tipos de respuesta**

  ------------------------------------------------------------------------
  **Tipo**         **Código**   **Qué hacer**
  ---------------- ------------ ------------------------------------------
  ACEPTADO         0            Guardar CDR, marcar como ACEPTADO en BD

  ACEPTADO CON     4000+        Válido pero con advertencias. Guardar y
  OBSERVACIÓN                   registrar observación

  RECHAZADO        2000-3999    Corregir el XML y reenviar con NUEVO
                                número

  EXCEPCIÓN        0100-1999    Error grave. Corregir y reenviar mismo
                                número (no se registró)
  ------------------------------------------------------------------------

**8.2 Diferencia en excepciones OSE vs SUNAT**

El OSE de Nubefact devuelve excepciones con estructura diferente a SUNAT
directo:

**Respuesta SUNAT directa:**

> \<faultcode\>1033\</faultcode\>
>
> \<faultstring\>El comprobante fue registrado previamente con otros
> datos\</faultstring\>

**Respuesta OSE Nubefact:**

> \<faultcode\>soap-server\</faultcode\>
>
> \<faultstring\>1033\</faultstring\>
>
> \<detail\>\<message\>El comprobante fue registrado previamente con
> otros datos\</message\>\</detail\>
>
> 💡 El código de error en Nubefact OSE viene en \<faultstring\> y el
> mensaje en \<detail\>\<message\>. Asegurarse de parsear correctamente.

**8.3 Lógica anti-duplicados (crítica)**

-   Antes de reenviar un comprobante, consultar primero con getStatusCdr
    si ya existe en SUNAT

-   Guardar SIEMPRE el estado en BD antes de enviar (PENDIENTE → ENVIADO
    → ACEPTADO/RECHAZADO)

-   Si hay error de conexión/timeout, NO reintentar directamente.
    Primero consultar getStatusCdr

-   Implementar control de intentos máximos (máximo 3 intentos por
    comprobante)

-   Usar transacciones en BD para evitar estados inconsistentes

**9. CONSULTA DE CDR (getStatusCdr)**

Para verificar si un comprobante ya fue procesado antes de reenviar:

> def consultar_cdr(ruc, tipo, serie, numero):
>
> soap_body = f\'\'\'\<soapenv:Envelope \...\>
>
> \<soapenv:Body\>
>
> \<ser:getStatusCdr\>
>
> \<rucComprobante\>{ruc}\</rucComprobante\>
>
> \<tipoComprobante\>{tipo}\</tipoComprobante\> \<!\-- 01, 07, 08 \--\>
>
> \<serieComprobante\>{serie}\</serieComprobante\>
>
> \<numeroComprobante\>{numero}\</numeroComprobante\>
>
> \</ser:getStatusCdr\>
>
> \</soapenv:Body\>
>
> \</soapenv:Envelope\>\'\'\'
>
> \# Si retorna CDR existente: ya fue procesado, no reenviar
>
> \# Si retorna error \'no encontrado\': aún no procesado, puede
> enviarse

**10. CHECKLIST PARA PASAR A PRODUCCIÓN**

> **⚠ No pasar a producción sin completar TODOS estos pasos.**

  ------------------------------------------------------------------------------
  **\#**   **Paso**                               **Responsable**   **Estado**
  -------- -------------------------------------- ----------------- ------------
  1        Todas las pruebas en DEMO funcionando  Programador       \[ \]
           correctamente                                            

  2        Certificado digital X.509 v3 oficial   Empresa           \[ \]
           adquirido                                                

  3        Certificado comunicado a SUNAT via     Empresa           \[ \]
           Clave SOL                                                

  4        Alta de Nubefact como OSE ante SUNAT   Empresa           \[ \]
           completada (puede tardar 24h)                            

  5        Autorización de Nubefact para          Nubefact          \[ \]
           producción recibida                                      

  6        Series nuevas definidas (distintas a   Programador       \[ \]
           las usadas antes con SUNAT)                              

  7        Endpoint cambiado a producción:        Programador       \[ \]
           ose.nubefact.com                                         

  8        Credenciales de producción             Programador       \[ \]
           configuradas en el sistema                               

  9        Sistema SUNAT directo deshabilitado    Programador       \[ \]
           completamente                                            

  10       Primer documento de producción enviado Programador       \[ \]
           y verificado                                             
  ------------------------------------------------------------------------------

**11. SOPORTE NUBEFACT**

Para consultas técnicas sobre el servicio OSE:

**Email: soporte-ose@nubefact.com**

> 💡 El soporte de Nubefact NO incluye: revisión de código,
> interpretación de XML ni configuración de la aplicación. Solo soporte
> del servicio OSE.

**12. RECURSOS Y DOCUMENTACIÓN**

  ------------------------------------------------------------------------------------------
  **Recurso**            **URL / Referencia**
  ---------------------- -------------------------------------------------------------------
  Ejemplos XML           https://drive.google.com/uc?id=1F5Tk3Wo23bNHcskf7PuPEjyZeU8q3Kwk
  operaciones frecuentes 

  Manual del Programador https://drive.google.com/uc?id=1aeq0wavaVrx3ZLQoijM5ViTExUyjfrN4
  SUNAT                  

  Factura Electrónica    https://drive.google.com/uc?id=1UChTMzybNrxveWpJ-Qbglt_icfgawnvK
  2.1                    

  Boleta Electrónica 2.1 https://drive.google.com/uc?id=19qLq0ja38gF5T01LHwiB8UOVi_eYKSJo

  Nota de Crédito 2.1    https://drive.google.com/uc?id=1HAy48WSCTDcCzi3vIcrEKysZ1Acksyl5

  Nota de Débito 2.1     https://drive.google.com/uc?id=1agiFbEmssnLa9\_-uYwtMcKe6Ze-UewxI

  Resúmenes Diarios      https://drive.google.com/uc?id=10nlOHVB2SYVexj69i3MaaBdO7dZ7ptTO

  Comunicaciones de Baja https://drive.google.com/uc?id=1xhoI_icnz2-cd2wvdxJWwg8d_isUuoFu
  2.0                    

  Panel Nubefact         https://20602230261.panel.pe
  ------------------------------------------------------------------------------------------