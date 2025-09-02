# ShareDance - Guía de Desarrollo

## 🚀 Quick Start

### 1. Clonar repositorio
```bash
git clone <repository-url>
cd sharedance
```

### 2. Configurar Flutter
```bash
flutter pub get
flutter packages pub run build_runner build
```

### 3. Ejecutar aplicación
```bash
# Staging
flutter run --flavor staging --dart-define=FLAVOR=staging

# Production
flutter run --flavor production --dart-define=FLAVOR=production
```

## 🔧 Configuración Firebase

### Archivos requeridos (NO incluidos en Git)
```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
server/serviceAccount-staging.json
server/serviceAccount-production.json
```

### Comandos Firebase
```bash
# Cambiar entre proyectos
firebase use sharedance-staging
firebase use sharedance-production

# Desplegar reglas
firebase deploy --only firestore:rules

# Desplegar functions
firebase deploy --only functions
```

## 📱 Build Commands

### Debug (Development)
```bash
flutter build apk --flavor staging --dart-define=FLAVOR=staging
```

### Release (Production)
```bash
flutter build apk --release --flavor production --dart-define=FLAVOR=production
```

## 🔍 Debugging

### Logs en tiempo real
```bash
flutter logs --device-id=<DEVICE_ID>
```

### Ver dispositivos conectados
```bash
adb devices
```

### Instalar APK manualmente
```bash
adb install -r build/app/outputs/flutter-apk/app-staging-debug.apk
```

## 🏗️ Estructura del proyecto

```
lib/
├── core/                    # Configuración base
├── features/               # Módulos por funcionalidad
│   └── auth/              # Autenticación
└── shared/                # Modelos compartidos

server/                    # Backend Node.js
functions/                 # Firebase Functions
```

## 🔐 Variables de entorno

### Firebase Projects
- **Staging**: `sharedance-staging`
- **Production**: `sharedance-production`

### Dominios
- **Staging**: `staging.sharedance.com.ar`
- **Production**: `sharedance.com.ar`

## 🤝 Workflow Git

### Branches
- `main`: Código estable para production
- `develop`: Integración y testing
- `feature/*`: Nuevas características

### Commits
- Usar emojis: 🎉 ✅ 🐛 📱 🔧
- Ser descriptivo en los mensajes
- Incluir contexto técnico

## 📋 Checklist antes de commit

- [ ] `flutter analyze` sin errores
- [ ] Tests unitarios pasando
- [ ] Aplicación compila en staging
- [ ] Firebase rules actualizadas si es necesario
- [ ] README actualizado si hay cambios importantes

## 🆘 Troubleshooting

### Error de permisos Firestore
```bash
firebase deploy --only firestore:rules
```

### Error de dependencias
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build
```

### Error de Firebase
```bash
firebase login
firebase use --add
```

---
**Autor**: Rodrigo Rodriguez (rodrigo.rodriguez@live.com.ar)
**Última actualización**: 30 de agosto de 2025
