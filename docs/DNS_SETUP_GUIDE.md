# Guía de Configuración DNS para ShareDance Email

## 📋 Resumen
Esta guía contiene los registros DNS necesarios para que el sistema de correo de ShareDance funcione correctamente con el dominio `sharedance.com.ar`.

## 🎯 Registros DNS Requeridos

### 1. Registro MX (Mail Exchange)
Indica dónde deben entregarse los emails para el dominio.

```
Tipo: MX
Nombre: @ (o sharedance.com.ar)
Valor: 10 mail.sharedance.com.ar
TTL: 3600
```

### 2. Registro A para el servidor de correo
Apunta el subdominio mail al servidor VPS.

```
Tipo: A
Nombre: mail
Valor: 148.113.197.152
TTL: 3600
```

### 3. Registro SPF (Sender Policy Framework)
Autoriza al servidor a enviar emails desde el dominio.

```
Tipo: TXT
Nombre: @ (o sharedance.com.ar)
Valor: "v=spf1 mx a:mail.sharedance.com.ar ip4:148.113.197.152 ~all"
TTL: 3600
```

### 4. Registro DMARC (Domain-based Message Authentication)
Política de autenticación para emails.

```
Tipo: TXT
Nombre: _dmarc
Valor: "v=DMARC1; p=quarantine; rua=mailto:postmaster@sharedance.com.ar"
TTL: 3600
```

### 5. Registro DKIM (DomainKeys Identified Mail)
**Nota**: Este registro se generará automáticamente cuando se configure DKIM en el servidor.

```
Tipo: TXT
Nombre: mail._domainkey
Valor: [Se generará automáticamente con el script DKIM]
TTL: 3600
```

## 🔧 Configuración por Proveedor DNS

### Cloudflare
1. Ir al dashboard de Cloudflare
2. Seleccionar el dominio `sharedance.com.ar`
3. Ir a la sección "DNS"
4. Agregar cada registro con los valores especificados arriba

### cPanel/WHM
1. Acceder al panel de control
2. Ir a "Zone Editor" o "DNS Management"
3. Seleccionar el dominio
4. Agregar los registros necesarios

### Otros proveedores
La mayoría de proveedores DNS tienen interfaces similares. Buscar las secciones:
- DNS Management
- Zone Editor
- DNS Records

## ✅ Verificación de Configuración

### Verificar MX Record
```bash
dig MX sharedance.com.ar
```
Debería mostrar: `10 mail.sharedance.com.ar`

### Verificar A Record
```bash
dig A mail.sharedance.com.ar
```
Debería mostrar: `148.113.197.152`

### Verificar SPF Record
```bash
dig TXT sharedance.com.ar | grep spf
```
Debería mostrar el registro SPF configurado

### Verificar DMARC Record
```bash
dig TXT _dmarc.sharedance.com.ar
```
Debería mostrar el registro DMARC

## 🚀 Pruebas de Funcionamiento

### 1. Prueba básica de envío
```bash
# Desde el VPS
echo "Test email" | mail -s "Test" -r "noreply@sharedance.com.ar" test@gmail.com
```

### 2. Verificar logs del servidor
```bash
# En el VPS
sudo tail -f /var/log/mail.log
```

### 3. Probar desde la aplicación
- Ir al dashboard de ShareDance
- Crear una nueva invitación
- Verificar que el email se envíe correctamente

## ⚠️ Consideraciones Importantes

### Tiempo de Propagación
- Los cambios DNS pueden tardar hasta 24 horas en propagarse completamente
- Verificar con diferentes herramientas online como whatsmydns.net

### Reputación del Dominio
- Los emails pueden ir a spam inicialmente
- La reputación mejora con el tiempo y uso legítimo
- Considerar "warm-up" del dominio enviando pocos emails al principio

### Monitoreo
- Revisar regularmente los logs del servidor de correo
- Monitorear la tasa de entrega y bounces
- Configurar alertas para problemas del servidor

## 🛠 Scripts de Configuración Disponibles

### Configurar servidor de correo completo
```bash
./scripts/setup-mail-server.sh
```

### Actualizar solo el backend
```bash
./scripts/update-email-backend.sh
```

### Probar configuración
```bash
./scripts/test-mail-system.sh
```

## 📞 Soporte

Si hay problemas con la configuración:
1. Verificar logs del servidor: `/var/log/mail.log`
2. Comprobar estado de servicios: `systemctl status postfix`
3. Verificar DNS con herramientas online
4. Consultar documentación del proveedor DNS

---

**Última actualización**: Septiembre 2025
**Estado**: Configuración completada - Pendiente DNS
