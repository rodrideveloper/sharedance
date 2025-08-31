# 🔥 GUÍA DETALLADA: Obtener Credenciales Firebase

## 📋 Checklist previo:
- [ ] Cuenta de Google creada
- [ ] Acceso a Firebase Console
- [ ] Proyecto Firebase creado (sharedance-staging)

## 🎯 Paso a paso con capturas:

### 1. Firebase Console Principal
```
URL: https://console.firebase.google.com/
Buscar: "sharedance-staging" en la lista de proyectos
Clic: En el proyecto sharedance-staging
```

### 2. Panel de Proyecto
```
Sidebar izquierdo → ⚙️ Configuración del proyecto
O buscar "Project settings" si está en inglés
```

### 3. Pestañas superiores
```
Pestañas: General | Usuarios y permisos | Cuentas de servicio | ...
Clic: "Cuentas de servicio" (Service accounts)
```

### 4. Sección Firebase Admin SDK
```
Verás una sección que dice:
"Firebase Admin SDK"
"Para usar el SDK Admin de Firebase..."

Botón azul: "Generar nueva clave privada"
```

### 5. Modal de confirmación
```
Título: "Generar nueva clave privada"
Texto: "Esta clave concede acceso de administrador..."
Advertencia: "Mantén esta clave privada..."

Botón: "Generar clave"
```

### 6. Descarga automática
```
El navegador descargará automáticamente:
Archivo: sharedance-staging-firebase-adminsdk-XXXXX-TIMESTAMP.json
Tamaño: ~2-3 KB
```

## 🔧 Qué hacer con el archivo descargado:

### Opción A: Desde terminal
```bash
# Ve a tu carpeta de descargas
cd ~/Downloads

# Busca el archivo descargado
ls *firebase-adminsdk*.json

# Renómbralo y muévelo
mv sharedance-staging-firebase-adminsdk-*.json /Users/usuario/development/sharedance/server/serviceAccount-staging.json
```

### Opción B: Desde Finder
```
1. Abre Finder
2. Ve a Descargas
3. Busca el archivo que empiece con "sharedance-staging-firebase-adminsdk"
4. Renómbralo a: serviceAccount-staging.json
5. Muévelo a: /Users/usuario/development/sharedance/server/
```

## ✅ Verificar que está bien:

### El archivo correcto debe tener:
```json
{
  "type": "service_account",
  "project_id": "sharedance-staging",
  "private_key_id": "abc123def456...",  // String real, no PLACEHOLDER
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0...",  // Clave muy larga (2000+ caracteres)
  "client_email": "firebase-adminsdk-abc123@sharedance-staging.iam.gserviceaccount.com",  // Email real
  "client_id": "123456789012345678",  // Número real
  // ... resto de campos con valores reales
}
```

### Diferencias clave vs template:
| Template | Archivo Real |
|----------|-------------|
| `"private_key_id": "PLACEHOLDER"` | `"private_key_id": "a1b2c3d4e5f6..."` |
| `"private_key": "PLACEHOLDER_PRIVATE_KEY"` | `"private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBAD..."` (2000+ chars) |
| `"client_email": "firebase-adminsdk-XXXXX@..."` | `"client_email": "firebase-adminsdk-a1b2c3@sharedance-staging.iam.gserviceaccount.com"` |

## 🔄 Repetir para Production:

1. Cambiar a proyecto "sharedance-production" en Firebase Console
2. Repetir pasos 3-6
3. Renombrar archivo a: `serviceAccount-production.json`
4. Colocar en la misma carpeta

## 🧪 Probar que funciona:

```bash
cd /Users/usuario/development/sharedance/server
npm run build
npm run start:staging
```

Deberías ver:
```
🔥 Firebase initialized for staging environment
📂 Project: sharedance-staging
Server running on port 3000
```

## ⚠️ Problemas comunes:

### Error: "Failed to initialize Firebase"
- Verifica que el archivo existe
- Verifica que se llama exactamente `serviceAccount-staging.json`
- Verifica que tiene contenido real (no placeholders)

### Error: "Service account key invalid"
- Re-descarga el archivo de Firebase Console
- Verifica que descargaste del proyecto correcto

### Error: "Permission denied"
- Verifica que tienes permisos de lectura en el archivo
- `chmod 644 serviceAccount-staging.json`
