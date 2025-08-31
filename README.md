# sharedance

# ShareDance 💃🕺

ShareDance es una aplicación móvil para la gestión de clases de baile con sistema de reservas y créditos. Permite a los estudiantes reservar clases, a los profesores gestionar sus horarios y a los administradores controlar todo el sistema.

## 🚀 Características

### 👨‍🎓 Para Estudiantes
- 📱 Registro y login con email o Google
- 📅 Ver clases disponibles de la semana
- 🎫 Reservar clases usando créditos
- 💳 Ver créditos disponibles
- ❌ Cancelar reservas (hasta 2 horas antes)

### 👨‍🏫 Para Profesores
- 📊 Ver lista de clases que dictan
- 👥 Ver alumnos inscritos en tiempo real
- 📈 Acceso a reportes de sus clases

### 👨‍💼 Para Administradores
- 🎯 Crear y gestionar clases
- 🏢 Gestionar salones y horarios
- 💰 Crear packs de créditos
- 📊 Generar reportes mensuales de pagos
- 👥 Gestionar usuarios

## 🏗️ Arquitectura

### Frontend (Flutter)
- **Patrón**: Arquitectura Limpia (Clean Architecture)
- **Estado**: Bloc Pattern
- **Navegación**: GoRouter
- **UI**: Material 3 con design system personalizado

### Backend (Firebase)
- **Auth**: Firebase Authentication
- **Base de datos**: Cloud Firestore
- **Storage**: Firebase Storage
- **Notificaciones**: Firebase Cloud Messaging
- **Functions**: Firebase Functions (Node.js)

## 📦 Estructura del Proyecto

```
lib/
├── core/                    # Funcionalidades centrales
│   ├── constants/          # Constantes y temas
│   ├── errors/            # Manejo de errores
│   ├── network/           # Servicios de red
│   └── utils/             # Utilidades comunes
├── features/              # Características por módulos
│   ├── auth/             # Autenticación
│   ├── classes/          # Gestión de clases
│   ├── reservations/     # Sistema de reservas
│   └── admin/            # Panel administrativo
└── shared/               # Componentes compartidos
    ├── models/           # Modelos de datos
    ├── repositories/     # Repositorios compartidos
    └── widgets/          # Widgets reutilizables
```

## 🔧 Configuración del Proyecto

### Prerrequisitos
- Flutter 3.7.2+
- Dart 3.0+
- Firebase CLI
- Node.js 18+ (para Firebase Functions)

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/sharedance.git
   cd sharedance
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   ```bash
   # Instalar Firebase CLI
   npm install -g firebase-tools
   
   # Login a Firebase
   firebase login
   
   # Configurar proyectos
   flutterfire configure --project=sharedance-staging
   flutterfire configure --project=sharedance-production
   ```

4. **Generar código**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## 🎯 Flavors de Desarrollo

El proyecto está configurado con dos flavors:

### Staging (Desarrollo)
```bash
flutter run --flavor staging --dart-define=FLAVOR=staging
```

### Production (Producción)
```bash
flutter run --flavor production --dart-define=FLAVOR=production
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
