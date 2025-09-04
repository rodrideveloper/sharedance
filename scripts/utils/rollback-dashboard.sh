#!/bin/bash

set -e

# ========================================================================================
# 🔄 ShareDance Dashboard - Rollback Script
# ========================================================================================

ENVIRONMENT=${1:-staging}
BACKUP_FILE=${2}

# Configuración del VPS
VPS_USER="ubuntu"
VPS_HOST="148.113.197.152"
SSH_KEY="~/.ssh/rodrigo_vps"
SSH_OPTS="-i $SSH_KEY -o ConnectTimeout=10"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}❌ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_step() { echo -e "${YELLOW}$1${NC}"; }

# Variables según environment
if [ "$ENVIRONMENT" = "production" ]; then
    VPS_DOMAIN="sharedance.com.ar"
    VPS_PATH="/opt/sharedance"
    PM2_APP="sharedance-production"
else
    VPS_DOMAIN="staging.sharedance.com.ar"
    VPS_PATH="/opt/sharedance"
    PM2_APP="sharedance-staging"
fi

echo -e "${YELLOW}🔄 ShareDance Dashboard Rollback - $ENVIRONMENT${NC}"

# Verificar conexión
if ! ssh $SSH_OPTS $VPS_USER@$VPS_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
    print_error "No se puede conectar al VPS"
    exit 1
fi

# Listar backups disponibles si no se especificó uno
if [ -z "$BACKUP_FILE" ]; then
    print_step "📋 Backups disponibles:"
    ssh $SSH_OPTS $VPS_USER@$VPS_HOST << EOF
        ls -la /opt/backups/dashboard/dashboard_${ENVIRONMENT}_*.tar.gz 2>/dev/null | tail -10 || echo "No hay backups disponibles"
EOF
    echo ""
    echo "Uso: $0 $ENVIRONMENT <backup_file>"
    echo "Ejemplo: $0 $ENVIRONMENT dashboard_${ENVIRONMENT}_20250903_143022.tar.gz"
    exit 1
fi

# Confirmar rollback
echo ""
print_step "⚠️  ¿Estás seguro de hacer rollback a $BACKUP_FILE? (y/N)"
read -r CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    print_error "Rollback cancelado"
    exit 0
fi

# Ejecutar rollback
print_step "🔄 Ejecutando rollback..."

ssh $SSH_OPTS $VPS_USER@$VPS_HOST << EOF
    # Verificar que el backup existe
    if [ ! -f "/opt/backups/dashboard/$BACKUP_FILE" ]; then
        echo "❌ Backup no encontrado: $BACKUP_FILE"
        exit 1
    fi
    
    # Crear backup del estado actual antes del rollback
    CURRENT_BACKUP="dashboard_${ENVIRONMENT}_rollback_\$(date +%Y%m%d_%H%M%S).tar.gz"
    if [ -d "$VPS_PATH/server/public" ]; then
        sudo tar -czf "/opt/backups/dashboard/\$CURRENT_BACKUP" -C "$VPS_PATH/server/public" . 2>/dev/null || true
        echo "📦 Estado actual guardado como: \$CURRENT_BACKUP"
    fi
    
    # Limpiar directorio actual
    sudo rm -rf $VPS_PATH/server/public/*
    
    # Restaurar desde backup
    sudo tar -xzf "/opt/backups/dashboard/$BACKUP_FILE" -C "$VPS_PATH/server/public"
    
    # Configurar permisos
    sudo chown -R www-data:www-data $VPS_PATH/server/public
    sudo chmod -R 755 $VPS_PATH/server/public
    
    echo "✅ Rollback completado"
    
    # Reiniciar servicios
    echo "🔄 Reiniciando servicios..."
    pm2 restart $PM2_APP
    sudo systemctl reload nginx
    
    echo "✅ Servicios reiniciados"
    ls -la $VPS_PATH/server/public/ | head -5
EOF

print_success "🎉 Rollback completado exitosamente"
print_success "🌐 Dashboard disponible en: https://$VPS_DOMAIN/dashboard/"
