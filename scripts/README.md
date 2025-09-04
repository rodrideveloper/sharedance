# ShareDance Scripts

Scripts organizados para deployment y gestión de ShareDance.

## 🚀 Deployment Scripts

### Script Principal
- **`deploy.sh`** - Script maestro de deployment
  ```bash
  ./scripts/deploy.sh <staging|production> [dashboard|landing|all]
  ```

### Scripts Específicos (`deploy/`)
- **`deploy-dashboard.sh`** - Deploy solo del dashboard Flutter
- **`deploy-landing.sh`** - Deploy solo de la landing page
- **`deploy.sh`** - Deploy completo (duplicado para compatibilidad)

## ⚙️ Setup Scripts (`setup/`)
- **`create_admin_user.js`** - Crear usuarios administradores
- **`create_invitations_collection.js`** - Inicializar colección de invitaciones
- **`init_firestore.js`** - Inicializar todas las colecciones de Firestore

## 🛠️ Utility Scripts (`utils/`)
- **`rollback-dashboard.sh`** - Rollback del dashboard en caso de problemas

## 📧 Mail Scripts (root)
- **`deploy-mail-system.sh`** - Deploy del sistema de emails
- **`setup-mail-server.sh`** - Configuración inicial del servidor de emails
- **`test-mail-system.sh`** - Test del sistema de emails
- **`update-email-backend.sh`** - Actualizar backend de emails

## 🔧 Firebase Scripts (root)
- **`setup_firebase.sh`** - Configuración inicial de Firebase

## 📖 Uso Recomendado

### Deployment Completo
```bash
# Para staging
./scripts/deploy.sh staging all

# Para production
./scripts/deploy.sh production all
```

### Deployment de Componente Específico
```bash
# Solo dashboard
./scripts/deploy.sh production dashboard

# Solo landing
./scripts/deploy.sh production landing
```

### Configuración Inicial
```bash
# 1. Configurar Firebase
./scripts/setup_firebase.sh

# 2. Crear usuario admin
node scripts/setup/create_admin_user.js production

# 3. Crear colección de invitaciones
node scripts/setup/create_invitations_collection.js production
```

## ✅ Características del Script Maestro

1. **Configuración automática de Nginx** - Mantiene la configuración correcta
2. **Backups automáticos** - Crea backups antes de cada deployment
3. **Verificación de conectividad** - Test automático de URLs
4. **Orden de prioridad correcto** en Nginx:
   - Landing page (`/`)
   - Dashboard (`/dashboard`)
   - Health check (`/health`)
   - API (`/api`)
   - Backend (`/*`)

## 🔄 Rollback

En caso de problemas, usar:
```bash
./scripts/utils/rollback-dashboard.sh
```

O restaurar desde backup:
```bash
ssh -i ~/.ssh/rodrigo_vps ubuntu@148.113.197.152
sudo tar -xzf /opt/backups/[component]/backup_[component]_[env]_[date].tar.gz -C /opt/sharedance/[component]
```
