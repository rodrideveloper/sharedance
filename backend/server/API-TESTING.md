# ShareDance API Testing

Este archivo contiene ejemplos de cómo probar los endpoints de la API.

## Health Check

```bash
curl http://localhost:3000/health
```

## Autenticación

Todos los endpoints (excepto /health) requieren autenticación Firebase.
Incluir el header Authorization con un token válido:

```bash
# Obtener token desde Firebase Auth en tu app Flutter
# Luego usar en requests:
curl -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
     http://localhost:3000/api/reservations
```

## Endpoints de Reservaciones

### Crear Reservación
```bash
curl -X POST http://localhost:3000/api/reservations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "classId": "class123",
    "date": "2024-09-01T10:00:00.000Z",
    "userId": "user123"
  }'
```

### Obtener Reservaciones
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/reservations
```

### Actualizar Reservación
```bash
curl -X PUT http://localhost:3000/api/reservations/reservation123 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "status": "cancelled"
  }'
```

## Endpoints de Notificaciones

### Obtener Notificaciones
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/notifications
```

### Marcar como Leída
```bash
curl -X PUT http://localhost:3000/api/notifications/notification123/read \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Crear Notificación (Admin only)
```bash
curl -X POST http://localhost:3000/api/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -d '{
    "userId": "user123",
    "title": "Recordatorio de Clase",
    "body": "Tu clase comienza en 1 hora",
    "type": "reminder"
  }'
```

## Endpoints de Reportes

### Obtener Reportes
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/reports
```

### Generar Reporte Manual (Admin only)
```bash
curl -X POST http://localhost:3000/api/reports/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -d '{
    "month": "2024-09",
    "professorId": "prof123"
  }'
```

## Webhooks

### Webhook de Pagos
```bash
curl -X POST http://localhost:3000/api/webhooks/payment \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment.created",
    "data": {
      "id": "payment123",
      "amount": 1000,
      "currency": "ARS",
      "status": "approved"
    }
  }'
```

## Testing con curl y jq

Si tienes `jq` instalado, puedes formatear las respuestas JSON:

```bash
curl -s http://localhost:3000/health | jq .
```

## Variables de Entorno para Testing

```bash
# Archivo .env.test
NODE_ENV=test
PORT=3001
FIREBASE_PROJECT_ID=sharedance-staging
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccount-staging.json
```

## Scripts de Testing

```bash
# Ejecutar tests (cuando estén implementados)
npm test

# Ejecutar en modo watch
npm run test:watch

# Coverage
npm run test:coverage
```
