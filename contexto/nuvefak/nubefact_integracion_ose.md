# Integracion Nubefact OSE - Guia Tecnica

## Resumen

Guia para enviar comprobantes electronicos (Factura, Boleta, Nota de Credito) al OSE demo de Nubefact via SOAP/XML. Probado y funcionando al 23/02/2026.

---

## 1. Credenciales Demo

| Dato | Valor |
|------|-------|
| OSE URL | `https://demo-ose.nubefact.com/ol-ti-itcpe/billService` |
| Usuario SOAP | `{RUC}MODDATOS` (ej: `20602230261MODDATOS` o `20000000001MODDATOS`) |
| Password SOAP | `MODDATOS` |
| RUC Demo (en XML) | `20000000001` (unico RUC activo en SUNAT demo) |
| Certificado PFX | `certificado_demo.pfx` (password: `12345678`) |
| Portal web | `https://operador.pe` (ingresar con RUC `20000000001`, user `MODDATOS`, pass `MODDATOS`) |

> **IMPORTANTE**: El RUC real de la empresa (20602230261) NO esta activo en la base de datos demo de SUNAT. Por eso usamos `20000000001` en los XMLs. En produccion se usa el RUC real.

---

## 2. Flujo Completo

```
1. Generar XML UBL 2.1
2. Firmar XML con certificado digital (signxml)
3. Mover firma al ext:ExtensionContent
4. Empaquetar XML firmado en ZIP
5. Codificar ZIP en Base64
6. Enviar via SOAP (sendBill) al OSE
7. Recibir CDR (Constancia de Recepcion)
```

---

## 3. Dependencias Python

```bash
pip install lxml signxml requests cryptography
```

---

## 4. Cargar Certificado PFX

```python
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.hazmat.primitives import serialization

PFX_PATH = "certificado_demo.pfx"
PFX_PASSWORD = b"12345678"

with open(PFX_PATH, "rb") as f:
    pfx_data = f.read()

private_key, certificate, _ = pkcs12.load_key_and_certificates(pfx_data, PFX_PASSWORD)

key_pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
)
cert_pem = certificate.public_bytes(serialization.Encoding.PEM)
```

---

## 5. Firmar XML

La firma debe quedar dentro de `ext:UBLExtensions > ext:UBLExtension > ext:ExtensionContent` con el atributo `Id="SignSUNAT"`.

```python
from lxml import etree
from signxml import XMLSigner, methods

NS = {"ext": "urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"}

def firmar_xml(xml_str: str) -> bytes:
    root = etree.fromstring(xml_str.encode())

    signer = XMLSigner(
        method=methods.enveloped,
        signature_algorithm="rsa-sha256",
        digest_algorithm="sha256",
        c14n_algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315",
    )

    signed_root = signer.sign(root, key=key_pem, cert=cert_pem)

    # Mover la firma al ExtensionContent (donde SUNAT la espera)
    ds_ns = "http://www.w3.org/2000/09/xmldsig#"
    sig = signed_root.find("{%s}Signature" % ds_ns)
    ext = signed_root.find(".//ext:ExtensionContent", NS)

    if sig is not None and ext is not None:
        sig.set("Id", "SignSUNAT")        # OBLIGATORIO: Id="SignSUNAT"
        signed_root.remove(sig)            # Quitar de la raiz
        ext.append(sig)                    # Insertar en ExtensionContent

    return etree.tostring(signed_root, xml_declaration=True, encoding="UTF-8")
```

### Errores comunes en la firma

| Error | Causa | Solucion |
|-------|-------|----------|
| `0306` | ExtensionContent vacio | Debe contener la firma digital completa |
| `2085` | Falta Id en Signature | Agregar `sig.set("Id", "SignSUNAT")` |
| Firma en lugar incorrecto | signxml coloca la firma al final del root | Mover al ExtensionContent manualmente |

---

## 6. Empaquetar y Enviar

```python
import base64, zipfile, io, requests

def enviar_comprobante(filename: str, signed_xml: bytes) -> dict:
    # 1. ZIP
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(f"{filename}.xml", signed_xml)
    b64 = base64.b64encode(zip_buffer.getvalue()).decode()

    # 2. SOAP
    OSE_URL = "https://demo-ose.nubefact.com/ol-ti-itcpe/billService"
    OSE_USER = "20000000001MODDATOS"  # RUC + MODDATOS
    OSE_PASS = "MODDATOS"

    soap = f"""<?xml version="1.0" encoding="UTF-8"?>
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                      xmlns:ser="http://service.sunat.gob.pe">
       <soapenv:Header>
          <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
             <wsse:UsernameToken>
                <wsse:Username>{OSE_USER}</wsse:Username>
                <wsse:Password>{OSE_PASS}</wsse:Password>
             </wsse:UsernameToken>
          </wsse:Security>
       </soapenv:Header>
       <soapenv:Body>
          <ser:sendBill>
             <fileName>{filename}.zip</fileName>
             <contentFile>{b64}</contentFile>
          </ser:sendBill>
       </soapenv:Body>
    </soapenv:Envelope>"""

    resp = requests.post(
        OSE_URL,
        data=soap.encode("utf-8"),
        headers={
            "Content-Type": "text/xml;charset=UTF-8",
            "SOAPAction": '"urn:sendBill"',
        },
        timeout=30,
    )

    # 3. Parsear respuesta
    result = {"http": resp.status_code}
    resp_root = etree.fromstring(resp.content)

    fault = resp_root.find(".//{http://schemas.xmlsoap.org/soap/envelope/}Fault")
    if fault is not None:
        result["error"] = fault.findtext("faultstring", "")
        detail = fault.find(".//message")
        result["mensaje"] = detail.text if detail is not None else ""
    else:
        app_resp = resp_root.find(".//{http://service.sunat.gob.pe}applicationResponse")
        if app_resp is not None and app_resp.text:
            cdr_zip = base64.b64decode(app_resp.text)
            with zipfile.ZipFile(io.BytesIO(cdr_zip)) as zf:
                for name in zf.namelist():
                    cdr_xml = zf.read(name)
                    cdr_root = etree.fromstring(cdr_xml)
                    ns2 = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                    result["cdr_file"] = name
                    result["response_code"] = cdr_root.findtext(f".//{{{ns2}}}ResponseCode", "")
                    result["description"] = cdr_root.findtext(f".//{{{ns2}}}Description", "")

    return result
```

### Formato del filename

El nombre del archivo (dentro del ZIP y en el SOAP) debe seguir el formato:

```
{RUC}-{TIPO_DOC}-{SERIE}-{CORRELATIVO}
```

| Tipo | Codigo | Ejemplo |
|------|--------|---------|
| Factura | 01 | `20000000001-01-F001-00000001` |
| Boleta | 03 | `20000000001-03-B001-00000001` |
| Nota de Credito | 07 | `20000000001-07-BC01-00000001` |

> El nombre del XML dentro del ZIP DEBE coincidir con el nombre del ZIP (sin extension).

---

## 7. XMLs por Tipo de Comprobante

### 7.1 Factura (tipo 01) - B2B con RUC

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
         xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
         xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">

    <!-- Aqui va la firma digital -->
    <ext:UBLExtensions>
        <ext:UBLExtension><ext:ExtensionContent/></ext:UBLExtension>
    </ext:UBLExtensions>

    <cbc:UBLVersionID>2.1</cbc:UBLVersionID>
    <cbc:CustomizationID>2.0</cbc:CustomizationID>
    <cbc:ID>F001-00000001</cbc:ID>
    <cbc:IssueDate>2026-02-23</cbc:IssueDate>
    <cbc:IssueTime>12:00:00</cbc:IssueTime>

    <!-- 01 = Factura -->
    <cbc:InvoiceTypeCode listAgencyName="PE:SUNAT" listName="Tipo de Documento"
        listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01"
        listID="0101"
        listSchemeURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo51">01</cbc:InvoiceTypeCode>

    <cbc:Note languageLocaleID="1000">QUINIENTOS CON 00/100 SOLES</cbc:Note>
    <cbc:DocumentCurrencyCode>PEN</cbc:DocumentCurrencyCode>

    <!-- Referencia a la firma -->
    <cac:Signature>
        <cbc:ID>IDSignKG</cbc:ID>
        <cac:SignatoryParty>
            <cac:PartyIdentification><cbc:ID>20000000001</cbc:ID></cac:PartyIdentification>
            <cac:PartyName><cbc:Name>EMPRESA DEMO SAC</cbc:Name></cac:PartyName>
        </cac:SignatoryParty>
        <cac:DigitalSignatureAttachment>
            <cac:ExternalReference><cbc:URI>#SignSUNAT</cbc:URI></cac:ExternalReference>
        </cac:DigitalSignatureAttachment>
    </cac:Signature>

    <!-- Emisor (Supplier) -->
    <cac:AccountingSupplierParty>
        <cac:Party>
            <cac:PartyIdentification>
                <cbc:ID schemeID="6">20000000001</cbc:ID>  <!-- schemeID=6 es RUC -->
            </cac:PartyIdentification>
            <cac:PartyName><cbc:Name>EMPRESA DEMO SAC</cbc:Name></cac:PartyName>
            <cac:PartyLegalEntity>
                <cbc:RegistrationName>EMPRESA DEMO SAC</cbc:RegistrationName>
                <cac:RegistrationAddress>
                    <cbc:ID>150101</cbc:ID>                <!-- Ubigeo -->
                    <cbc:AddressTypeCode>0000</cbc:AddressTypeCode>
                    <cbc:CityName>LIMA</cbc:CityName>
                    <cbc:CountrySubentity>LIMA</cbc:CountrySubentity>
                    <cbc:District>LIMA</cbc:District>
                    <cac:AddressLine><cbc:Line>AV. TEST 123</cbc:Line></cac:AddressLine>
                    <cac:Country><cbc:IdentificationCode>PE</cbc:IdentificationCode></cac:Country>
                </cac:RegistrationAddress>
            </cac:PartyLegalEntity>
        </cac:Party>
    </cac:AccountingSupplierParty>

    <!-- Receptor (Customer) - Factura requiere RUC (schemeID=6) -->
    <cac:AccountingCustomerParty>
        <cac:Party>
            <cac:PartyIdentification>
                <cbc:ID schemeID="6">20100039207</cbc:ID>
            </cac:PartyIdentification>
            <cac:PartyLegalEntity>
                <cbc:RegistrationName>CLIENTE EMPRESA SAC</cbc:RegistrationName>
            </cac:PartyLegalEntity>
        </cac:Party>
    </cac:AccountingCustomerParty>

    <!-- OBLIGATORIO para Factura: Forma de pago -->
    <cac:PaymentTerms>
        <cbc:ID>FormaPago</cbc:ID>
        <cbc:PaymentMeansID>Contado</cbc:PaymentMeansID>
    </cac:PaymentTerms>

    <!-- Totales de impuestos -->
    <cac:TaxTotal>
        <cbc:TaxAmount currencyID="PEN">76.27</cbc:TaxAmount>
        <cac:TaxSubtotal>
            <cbc:TaxableAmount currencyID="PEN">423.73</cbc:TaxableAmount>
            <cbc:TaxAmount currencyID="PEN">76.27</cbc:TaxAmount>
            <cac:TaxCategory>
                <cac:TaxScheme>
                    <cbc:ID>1000</cbc:ID>           <!-- 1000=IGV -->
                    <cbc:Name>IGV</cbc:Name>
                    <cbc:TaxTypeCode>VAT</cbc:TaxTypeCode>
                </cac:TaxScheme>
            </cac:TaxCategory>
        </cac:TaxSubtotal>
    </cac:TaxTotal>

    <!-- Totales monetarios -->
    <cac:LegalMonetaryTotal>
        <cbc:LineExtensionAmount currencyID="PEN">423.73</cbc:LineExtensionAmount>
        <cbc:TaxInclusiveAmount currencyID="PEN">500.00</cbc:TaxInclusiveAmount>
        <cbc:PayableAmount currencyID="PEN">500.00</cbc:PayableAmount>
    </cac:LegalMonetaryTotal>

    <!-- Items -->
    <cac:InvoiceLine>
        <cbc:ID>1</cbc:ID>
        <cbc:InvoicedQuantity unitCode="ZZ">1</cbc:InvoicedQuantity>
        <cbc:LineExtensionAmount currencyID="PEN">423.73</cbc:LineExtensionAmount>
        <cac:PricingReference>
            <cac:AlternativeConditionPrice>
                <cbc:PriceAmount currencyID="PEN">500.00</cbc:PriceAmount>
                <cbc:PriceTypeCode>01</cbc:PriceTypeCode>  <!-- Precio con IGV -->
            </cac:AlternativeConditionPrice>
        </cac:PricingReference>
        <cac:TaxTotal>
            <cbc:TaxAmount currencyID="PEN">76.27</cbc:TaxAmount>
            <cac:TaxSubtotal>
                <cbc:TaxableAmount currencyID="PEN">423.73</cbc:TaxableAmount>
                <cbc:TaxAmount currencyID="PEN">76.27</cbc:TaxAmount>
                <cac:TaxCategory>
                    <cbc:Percent>18</cbc:Percent>
                    <cbc:TaxExemptionReasonCode>10</cbc:TaxExemptionReasonCode>  <!-- Gravado -->
                    <cac:TaxScheme>
                        <cbc:ID>1000</cbc:ID>
                        <cbc:Name>IGV</cbc:Name>
                        <cbc:TaxTypeCode>VAT</cbc:TaxTypeCode>
                    </cac:TaxScheme>
                </cac:TaxCategory>
            </cac:TaxSubtotal>
        </cac:TaxTotal>
        <cac:Item>
            <cbc:Description>Servicio de comision por efectivizacion de tarjeta</cbc:Description>
        </cac:Item>
        <cac:Price>
            <cbc:PriceAmount currencyID="PEN">423.73</cbc:PriceAmount>  <!-- Precio sin IGV -->
        </cac:Price>
    </cac:InvoiceLine>
</Invoice>
```

### 7.2 Boleta (tipo 03) - B2C con DNI

Igual que Factura pero con estas diferencias:

```xml
<!-- InvoiceTypeCode = 03 (Boleta) -->
<cbc:InvoiceTypeCode listID="0101">03</cbc:InvoiceTypeCode>

<!-- Cliente con DNI (schemeID=1) en vez de RUC -->
<cbc:ID schemeID="1">12345678</cbc:ID>

<!-- NO requiere PaymentTerms (a diferencia de Factura) -->

<!-- Serie empieza con B: B001-00000001 -->
```

### 7.3 Nota de Credito (tipo 07)

Usa `<CreditNote>` en vez de `<Invoice>` y agrega referencia al documento original:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CreditNote xmlns="urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2"
            xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
            xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
            xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
            xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">

    <!-- ... UBLExtensions, UBLVersionID, CustomizationID, ID, IssueDate ... -->

    <!-- Motivo de la nota de credito -->
    <cac:DiscrepancyResponse>
        <cbc:ReferenceID>B001-00000001</cbc:ReferenceID>      <!-- Doc original -->
        <cbc:ResponseCode>01</cbc:ResponseCode>                <!-- 01=Anulacion -->
        <cbc:Description>Anulacion de la operacion</cbc:Description>
    </cac:DiscrepancyResponse>

    <!-- Referencia al documento que se modifica -->
    <cac:BillingReference>
        <cac:InvoiceDocumentReference>
            <cbc:ID>B001-00000001</cbc:ID>
            <cbc:DocumentTypeCode>03</cbc:DocumentTypeCode>    <!-- 03=Boleta -->
        </cac:InvoiceDocumentReference>
    </cac:BillingReference>

    <!-- ... Signature, Supplier, Customer, TaxTotal, LegalMonetaryTotal ... -->

    <!-- Usa CreditNoteLine en vez de InvoiceLine -->
    <cac:CreditNoteLine>
        <cbc:ID>1</cbc:ID>
        <cbc:CreditedQuantity unitCode="ZZ">1</cbc:CreditedQuantity>
        <!-- ... resto igual que InvoiceLine ... -->
    </cac:CreditNoteLine>
</CreditNote>
```

**Diferencias clave de Nota de Credito:**
- Namespace raiz: `CreditNote-2` (no `Invoice-2`)
- Elemento raiz: `<CreditNote>` (no `<Invoice>`)
- Tiene `DiscrepancyResponse` y `BillingReference` apuntando al doc original
- Items en `<CreditNoteLine>` con `<CreditedQuantity>` (no `InvoiceLine`/`InvoicedQuantity`)
- Serie empieza con BC (si anula Boleta) o FC (si anula Factura)
- Filename: `{RUC}-07-{SERIE}-{CORRELATIVO}`

---

## 8. Codigos de Referencia

### Tipos de documento del cliente (schemeID)

| schemeID | Documento |
|----------|-----------|
| 1 | DNI |
| 6 | RUC |
| 4 | Carnet de extranjeria |
| 7 | Pasaporte |

### Tipos de comprobante

| Codigo | Tipo |
|--------|------|
| 01 | Factura |
| 03 | Boleta de Venta |
| 07 | Nota de Credito |
| 08 | Nota de Debito |

### Codigos de respuesta CDR

| ResponseCode | Significado |
|--------------|-------------|
| 0 | Aceptado |
| Otros | Ver catalogo SUNAT |

---

## 9. Errores Comunes y Soluciones

| Error | Codigo | Causa | Solucion |
|-------|--------|-------|----------|
| Contribuyente no activo | 2010 | RUC no existe en SUNAT (demo) | Usar RUC `20000000001` en demo |
| Comprobante registrado previamente | 1033 | Mismo serie-correlativo ya enviado | Cambiar el correlativo |
| Falta PaymentTerms | 3244 | Factura sin forma de pago | Agregar `cac:PaymentTerms` con FormaPago/Contado |
| Firma invalida | 0306 | ExtensionContent vacio o firma mal ubicada | Mover firma completa al ExtensionContent |
| Falta Id en Signature | 2085 | ds:Signature sin atributo Id | Agregar `Id="SignSUNAT"` al elemento Signature |
| Filename no coincide | 0161 | Nombre XML != nombre ZIP | El XML dentro del ZIP debe llamarse igual que el ZIP |

---

## 10. Archivos del Proyecto

```
altoke/
  certificado_demo.pfx        # Certificado de prueba (password: 12345678)
  key_demo.pem                 # Llave privada PEM
  cert_demo.pem                # Certificado publico PEM
  send_boleta_demo.py          # Script simple: envia 1 boleta
  test_ose_completo.py         # Script completo: envia Factura + Boleta + NC
  test_nubefact_json.py        # Script REST/JSON (necesita ruta+token reales)
```

---

## 11. Generar Certificado de Prueba (opcional)

Si necesitas regenerar el certificado de prueba:

```bash
# Generar llave privada + certificado autofirmado
openssl req -x509 -newkey rsa:2048 -keyout key_demo.pem -out cert_demo.pem \
  -days 365 -nodes -subj "//O=EMPRESA DEMO/CN=DEMO"

# Empaquetar en PFX
openssl pkcs12 -export -out certificado_demo.pfx \
  -inkey key_demo.pem -in cert_demo.pem -passout pass:12345678
```

> En Windows (Git Bash) usar `//O=` con doble barra para evitar conversion de paths.

---

## 12. Diferencias Demo vs Produccion

| Aspecto | Demo | Produccion |
|---------|------|------------|
| OSE URL | `demo-ose.nubefact.com/ol-ti-itcpe/billService` | URL de produccion de Nubefact |
| Usuario SOAP | `{RUC}MODDATOS` | `{RUC}{USUARIO_REAL}` |
| Password | `MODDATOS` | Password real |
| RUC en XML | `20000000001` | RUC real de la empresa |
| Certificado | Self-signed (cualquiera) | Certificado digital real (SUNAT/RENIEC) |
| Validez legal | Ninguna | Comprobante electronico valido |
| Portal | operador.pe (demo) | operador.pe (produccion) |

---

## 13. API REST/JSON (Alternativa mas simple)

Nubefact tambien ofrece una API REST donde envias un JSON y ellos hacen todo (XML, firma, envio a SUNAT). Requiere obtener RUTA y TOKEN desde tu cuenta en nubefact.com seccion "Api-Integracion".

```python
import requests

RUTA = "https://api.nubefact.com/api/v1/{tu-url-token}"
TOKEN = "{tu-api-token}"

boleta = {
    "operacion": "generar_comprobante",
    "tipo_de_comprobante": 2,
    "serie": "B001",
    "numero": 1,
    "sunat_transaction": 1,
    "cliente_tipo_de_documento": 1,
    "cliente_numero_de_documento": "12345678",
    "cliente_denominacion": "JUAN PEREZ GARCIA",
    "fecha_de_emision": "2026-02-23",
    "moneda": 1,
    "porcentaje_de_igv": 18.00,
    "total_gravada": 200.00,
    "total_igv": 36.00,
    "total": 236.00,
    "enviar_automaticamente_a_la_sunat": True,
    "enviar_automaticamente_al_cliente": False,
    "items": [{
        "unidad_de_medida": "ZZ",
        "descripcion": "Servicio de comision por efectivizacion",
        "cantidad": 1,
        "valor_unitario": 200.00,
        "precio_unitario": 236.00,
        "subtotal": 200.00,
        "tipo_de_igv": 1,
        "igv": 36.00,
        "total": 236.00,
    }]
}

resp = requests.post(RUTA, json=boleta, headers={"Authorization": f"Bearer {TOKEN}"})
# Respuesta incluye: enlace_del_pdf, enlace_del_xml, enlace_del_cdr, cadena_para_codigo_qr
```

**Ventaja**: No necesitas generar XML, firmar, ni empaquetar. Solo envias JSON.
**Requisito**: Obtener RUTA y TOKEN desde el panel de Nubefact.
