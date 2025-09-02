# ShareDance Node.js Server

Este servidor Node.js reemplaza completamente las Firebase Functions, proporcionando todas las funcionalidades necesarias para la aplicación ShareDance.

## Setup

1. Copiar las claves de servicio de Firebase:
```bash
# Staging environment
cp path/to/sharedance-staging-firebase-adminsdk.json config/firebase-service-account-staging.json

# Production environment
cp path/to/sharedance-production-firebase-adminsdk.json config/firebase-service-account-production.json
```

2. Instalar dependencias:
```bash
npm install
```

3. Desarrollo:
```bash
npm run dev
```

4. Producción con PM2:
```bash
npm start
```

## 📡 Endpoints Disponibles

### Autenticación
- Todos los endpoints (excepto health check) requieren autenticación Firebase
- Incluir header: `Authorization: Bearer <firebase-token>`

### Reservaciones
- `POST /api/reservations` - Crear reservación
- `PUT /api/reservations/:id` - Actualizar reservación
- `GET /api/reservations` - Obtener reservaciones del usuario
- Manejo automático de créditos y validaciones

### Reportes
- `GET /api/reports` - Obtener reportes (admin/profesor)
- `POST /api/reports/generate` - Generar reporte manual (admin)

### Notificaciones
- `GET /api/notifications` - Obtener notificaciones del usuario
- `PUT /api/notifications/:id/read` - Marcar como leída
- `POST /api/notifications` - Crear notificación (admin)

### Webhooks
- `POST /api/webhooks/payment` - Webhook de pagos
- `POST /api/webhooks/class-reminder` - Recordatorios de clase

### Health Check
- `GET /health` - Estado del servidor

## 🔄 Tareas Automatizadas (Cron Jobs)

El servidor incluye tareas automáticas que reemplazan las funciones programadas de Firebase:

### Daily Tasks (0 2 * * *) - 2:00 AM
- **Cleanup Expired Reservations**: Limpia reservaciones expiradas
- **Generate Daily Reports**: Genera reportes diarios automáticos

### Weekly Tasks (0 1 * * 0) - 1:00 AM Domingos
- **Generate Weekly Reports**: Reportes semanales por profesor
- **Database Maintenance**: Mantenimiento de base de datos

### Monthly Tasks (0 0 1 * *) - 1:00 AM del día 1
- **Generate Monthly Reports**: Reportes mensuales consolidados
- **Credit Expiration**: Manejo de expiración de créditos

## 🐳 Despliegue con Docker

### Desarrollo Local
```bash
docker-compose up -d
```

### Producción
```bash
# Construir imagen
docker build -t sharedance-server .

# Ejecutar contenedor
docker run -d \
  --name sharedance-server \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/serviceAccount-production.json:/app/serviceAccount-production.json \
  sharedance-server
```

## 🔒 Seguridad

- **Autenticación**: Validación de tokens Firebase
- **Autorización**: Control de acceso basado en roles
- **Validación**: Validación de datos con Joi
- **CORS**: Configuración restrictiva de CORS
- **Rate Limiting**: Control de límites de requests
- **Helmet**: Headers de seguridad

## 📊 Monitoreo

### Health Check
```bash
curl http://localhost:3000/health
```

### Logs
Los logs incluyen:
- Requests HTTP (Morgan)
- Errores de autenticación
- Ejecución de cron jobs
- Operaciones de base de datos

## 🔧 Solución de Problemas

### Firebase Admin Error
Si ves: "The default Firebase app does not exist"
- Verifica que el archivo de credenciales existe
- Confirma que la variable `FIREBASE_SERVICE_ACCOUNT_PATH` es correcta
- Asegúrate de que el archivo JSON tiene permisos de lectura

### Puerto en Uso
Si el puerto 3000 está ocupado:
- Cambia `PORT=3001` en el archivo `.env`
- O termina el proceso: `lsof -ti:3000 | xargs kill`

### Errores de Compilación TypeScript
```bash
npm run build --verbose
```

## 🚀 Migración desde Firebase Functions

Este servidor reemplaza completamente las Firebase Functions con:

### ✅ Funcionalidades Migradas
- [x] Autenticación y autorización
- [x] Gestión de reservaciones
- [x] Manejo de créditos
- [x] Sistema de notificaciones
- [x] Generación de reportes
- [x] Webhooks de pagos
- [x] Tareas programadas (cron jobs)
- [x] Validación de datos
- [x] Manejo de errores

### 💰 Beneficios vs Firebase Functions
- **Costo**: Sin costos por ejecución, solo hosting VPS
- **Performance**: Servidor siempre activo, sin cold starts
- **Control**: Control total sobre el entorno y dependencias
- **Escalabilidad**: Escalado horizontal manual según necesidades
- **Monitoreo**: Logs y métricas personalizadas

### 🔄 Configuración en Flutter App
Actualiza las URLs en tu app Flutter de:
```dart
// Antes (Firebase Functions)
const String baseUrl = 'https://us-central1-sharedance-staging.cloudfunctions.net';

// Después (Node.js Server)
const String baseUrl = 'https://tu-servidor.com'; // o http://localhost:3000 para desarrollo
```

## 📞 Soporte

Para problemas o dudas:
1. Revisa los logs del servidor
2. Verifica la configuración de Firebase
3. Confirma que todas las variables de entorno están configuradas
4. Verifica que el proyecto de Firebase tiene los servicios habilitados (Auth, Firestore)
