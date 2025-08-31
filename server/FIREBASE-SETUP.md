# 🔑 INSTRUCCIONES: Obtener Credenciales Firebase

## Paso 1: Ir a Firebase Console
1. Ve a https://console.firebase.google.com/
2. Selecciona tu proyecto `sharedance-staging`
3. Ve a ⚙️ **Configuración del proyecto**
4. Pestaña **Cuentas de servicio**
5. Haz clic en **Generar nueva clave privada**
6. Descarga el archivo JSON

## Paso 2: Configurar el Archivo
1. Renombra el archivo descargado a: `serviceAccount-staging.json`
2. Colócalo en la carpeta `/server/`
3. ¡NO lo subas a Git! (está en .gitignore)

## Paso 3: Hacer lo mismo para Production
1. Cambia al proyecto `sharedance-production` en Firebase Console
2. Repite los pasos 1-2
3. Renombra a: `serviceAccount-production.json`

## ⚠️ IMPORTANTE:
- Necesitas las credenciales REALES de Firebase
- Cada proyecto (staging/production) tiene sus propias credenciales

## ✅ Sabrás que está bien cuando:
- El archivo real tiene una private_key muy larga (2000+ caracteres)
- El client_email tiene un ID real como: firebase-adminsdk-abc123@sharedance-staging.iam.gserviceaccount.com
