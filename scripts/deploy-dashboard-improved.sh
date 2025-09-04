#!/bin/bash

set -e

# ========================================================================================
# 🚀 ShareDance Dashboard - Deploy Script Mejorado
# ========================================================================================

# Configuración
ENVIRONMENT=${1:-staging}
FORCE_DEPLOY=${2:-false}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuración del VPS
VPS_USER="ubuntu"
VPS_HOST="148.113.197.152"
SSH_KEY="~/.ssh/rodrigo_vps"
SSH_OPTS="-i $SSH_KEY -o ConnectTimeout=10 -o StrictHostKeyChecking=no"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables de entorno
if [ "$ENVIRONMENT" = "production" ]; then
    VPS_DOMAIN="sharedance.com.ar"
    VPS_PATH="/opt/sharedance"
    PM2_APP="sharedance-production"
    NGINX_CONFIG="nginx-sharedance-production"
    SERVER_PORT="3002"
else
    VPS_DOMAIN="staging.sharedance.com.ar"
    VPS_PATH="/opt/sharedance"
    PM2_APP="sharedance-staging"
    NGINX_CONFIG="nginx-sharedance-staging"
    SERVER_PORT="3001"
fi

# ========================================================================================
# 🔧 Funciones de Utilidad
# ========================================================================================

print_header() {
    echo -e "\n${BLUE}=====================================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}=====================================================================${NC}\n"
}

print_step() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Función para verificar dependencias
check_dependencies() {
    print_step "🔍 Verificando dependencias locales..."
    
    # Verificar Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter no está instalado"
        exit 1
    fi
    
    # Verificar rsync
    if ! command -v rsync &> /dev/null; then
        print_error "rsync no está instalado"
        exit 1
    fi
    
    # Verificar SSH key
    if [ ! -f "${SSH_KEY/#\~/$HOME}" ]; then
        print_error "SSH key no encontrada: $SSH_KEY"
        exit 1
    fi
    
    print_success "Dependencias verificadas"
}

# Función para verificar conexión SSH
check_ssh_connection() {
    print_step "🔐 Verificando conexión SSH..."
    
    if ! ssh $SSH_OPTS $VPS_USER@$VPS_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
        print_error "No se puede conectar al VPS"
        exit 1
    fi
    
    print_success "Conexión SSH exitosa"
}

# Función para verificar estado del VPS
check_vps_status() {
    print_step "📊 Verificando estado del VPS..."
    
    ssh $SSH_OPTS $VPS_USER@$VPS_HOST << 'EOF'
        echo "=== Sistema ==="
        uptime
        df -h / | tail -1
        
        echo -e "\n=== PM2 ==="
        pm2 list | grep -E "(id|sharedance)" || echo "No hay procesos PM2"
        
        echo -e "\n=== Nginx ==="
        sudo systemctl is-active nginx || echo "Nginx no activo"
        
        echo -e "\n=== Puertos ==="
        netstat -tlnp | grep -E "(3001|3002|80|443)" | head -4 || echo "Puertos no en uso"
EOF
}

# Función para build local
build_dashboard() {
    print_step "🔨 Compilando dashboard localmente..."
    
    cd "$PROJECT_ROOT"
    
    # Usar script de build existente
    if [ -f "scripts/quick-build.sh" ]; then
        ./scripts/quick-build.sh $ENVIRONMENT
    else
        print_error "Script de build no encontrado"
        exit 1
    fi
    
    # Verificar que el build existe
    if [ ! -d "apps/dashboard/build/web" ]; then
        print_error "Build falló - directorio build/web no existe"
        exit 1
    fi
    
    # Mostrar información del build
    BUILD_SIZE=$(du -sh apps/dashboard/build/web | cut -f1)
    FILES_COUNT=$(find apps/dashboard/build/web -type f | wc -l)
    print_success "Dashboard compilado - Tamaño: $BUILD_SIZE, Archivos: $FILES_COUNT"
}

# Función para crear backup
create_backup() {
    print_step "💾 Creando backup en VPS..."
    
    BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
    
    ssh $SSH_OPTS $VPS_USER@$VPS_HOST << EOF
        # Crear directorio de backups
        sudo mkdir -p /opt/backups/dashboard
        
        # Backup del dashboard actual
        if [ -d "$VPS_PATH/server/public" ]; then
            echo "Creando backup del dashboard actual..."
            sudo tar -czf /opt/backups/dashboard/dashboard_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz \
                -C $VPS_PATH/server/public . 2>/dev/null || true
            echo "Backup creado: /opt/backups/dashboard/dashboard_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz"
        else
            echo "No hay dashboard previo para hacer backup"
        fi
        
        # Limpiar backups antiguos (mantener solo los últimos 5)
        find /opt/backups/dashboard -name "dashboard_${ENVIRONMENT}_*.tar.gz" -type f | sort | head -n -5 | xargs sudo rm -f 2>/dev/null || true
EOF
    
    print_success "Backup creado: dashboard_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz"
}

# Función para deploy
deploy_dashboard() {
    print_step "📤 Desplegando dashboard al VPS..."
    
    # Crear directorio temporal
    TEMP_DIR="/tmp/sharedance-dashboard-$(date +%s)"
    
    ssh $SSH_OPTS $VPS_USER@$VPS_HOST "mkdir -p $TEMP_DIR"
    
    # Subir archivos con rsync
    print_step "📁 Sincronizando archivos..."
    rsync -avz --delete --progress \
        -e "ssh $SSH_OPTS" \
        "$PROJECT_ROOT/apps/dashboard/build/web/" \
        "$VPS_USER@$VPS_HOST:$TEMP_DIR/"
    
    # Instalar en el servidor
    ssh $SSH_OPTS $VPS_USER@$VPS_HOST << EOF
        # Preparar directorio de destino
        sudo mkdir -p $VPS_PATH/server/public
        
        # Hacer backup del contenido actual
        if [ -d "$VPS_PATH/server/public" ] && [ "\$(ls -A $VPS_PATH/server/public)" ]; then
            sudo mv $VPS_PATH/server/public $VPS_PATH/server/public.backup.\$(date +%s) 2>/dev/null || true
        fi
        
        # Instalar nuevos archivos
        sudo mkdir -p $VPS_PATH/server/public
        sudo cp -r $TEMP_DIR/* $VPS_PATH/server/public/
        
        # Configurar permisos
        sudo chown -R www-data:www-data $VPS_PATH/server/public
        sudo chmod -R 755 $VPS_PATH/server/public
        
        # Limpiar temporal
        rm -rf $TEMP_DIR
        
        echo "Dashboard instalado exitosamente"
        ls -la $VPS_PATH/server/public/ | head -10
EOF
    
    print_success "Dashboard desplegado"
}

# Función para reiniciar servicios
restart_services() {
    print_step "🔄 Reiniciando servicios..."
    
    ssh $SSH_OPTS $VPS_USER@$VPS_HOST << EOF
        # Verificar y reiniciar PM2
        if pm2 list | grep -q $PM2_APP; then
            echo "Reiniciando $PM2_APP..."
            pm2 restart $PM2_APP
            pm2 status $PM2_APP
        else
            echo "⚠️  $PM2_APP no está ejecutándose en PM2"
        fi
        
        # Verificar Nginx
        echo "Verificando configuración de Nginx..."
        sudo nginx -t
        
        if [ \$? -eq 0 ]; then
            echo "Recargando Nginx..."
            sudo systemctl reload nginx
        else
            echo "❌ Error en configuración de Nginx"
            exit 1
        fi
EOF
    
    print_success "Servicios reiniciados"
}

# Función para verificar deployment
verify_deployment() {
    print_step "🔍 Verificando deployment..."
    
    # Verificar archivos en el servidor
    ssh $SSH_OPTS $VPS_USER@$VPS_HOST << EOF
        echo "=== Archivos del Dashboard ==="
        ls -la $VPS_PATH/server/public/ | head -5
        
        echo -e "\n=== Tamaño del Dashboard ==="
        du -sh $VPS_PATH/server/public/
        
        echo -e "\n=== Estado de PM2 ==="
        pm2 status $PM2_APP
        
        echo -e "\n=== Estado de Nginx ==="
        sudo systemctl status nginx --no-pager | head -3
EOF
    
    # Test HTTP
    print_step "🌐 Probando conectividad HTTP..."
    if curl -s -o /dev/null -w "%{http_code}" "https://$VPS_DOMAIN/dashboard/" | grep -q "200"; then
        print_success "Dashboard accesible en: https://$VPS_DOMAIN/dashboard/"
    else
        print_warning "Dashboard podría no estar respondiendo correctamente"
    fi
}

# ========================================================================================
# 🚀 Función Principal
# ========================================================================================

main() {
    print_header "ShareDance Dashboard Deploy - Environment: $ENVIRONMENT"
    
    # Verificaciones iniciales
    check_dependencies
    check_ssh_connection
    
    # Mostrar estado actual
    check_vps_status
    
    # Confirmación (skip si es force deploy)
    if [ "$FORCE_DEPLOY" != "true" ] && [ "$FORCE_DEPLOY" != "--force" ]; then
        echo ""
        print_warning "¿Continuar con el deploy a $ENVIRONMENT? (y/N)"
        read -r CONFIRM
        if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
            print_error "Deploy cancelado"
            exit 0
        fi
    fi
    
    # Proceso de deploy
    print_header "Iniciando Deploy"
    
    build_dashboard
    create_backup
    deploy_dashboard
    restart_services
    verify_deployment
    
    # Resultado final
    print_header "Deploy Completado Exitosamente"
    print_success "🌐 Dashboard disponible en: https://$VPS_DOMAIN/dashboard/"
    print_success "🔧 Environment: $ENVIRONMENT"
    print_success "📊 Servidor: $VPS_HOST"
    
    echo ""
    print_step "📋 Próximos pasos:"
    echo "   1. Verificar que el dashboard funciona correctamente"
    echo "   2. Probar el login y las funcionalidades principales"
    echo "   3. Monitorear logs si es necesario: ssh $VPS_USER@$VPS_HOST 'pm2 logs $PM2_APP'"
}

# ========================================================================================
# 🎯 Ejecución
# ========================================================================================

# Manejo de argumentos
case "${1:-}" in
    production|staging)
        main
        ;;
    --help|-h)
        echo "Uso: $0 [staging|production] [--force]"
        echo ""
        echo "Ejemplos:"
        echo "  $0 staging          # Deploy a staging con confirmación"
        echo "  $0 production       # Deploy a production con confirmación"
        echo "  $0 staging --force  # Deploy a staging sin confirmación"
        exit 0
        ;;
    *)
        print_error "Environment inválido. Usa: staging o production"
        echo "Ejecuta $0 --help para más información"
        exit 1
        ;;
esac
