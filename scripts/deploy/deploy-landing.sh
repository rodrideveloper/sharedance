#!/bin/bash

set -e

# Configuración del VPS
VPS_USER="ubuntu"
VPS_HOST="148.113.197.152"
SSH_KEY="~/.ssh/rodrigo_vps"
ENVIRONMENT=${1:-staging}

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 ShareDance Landing Page Deployment Script${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}VPS: $VPS_HOST${NC}"

# Verificar conexión SSH
echo -e "${YELLOW}🔍 Verificando conexión SSH...${NC}"
if ! ssh -i $SSH_KEY -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: No se puede conectar al VPS${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Conexión SSH exitosa${NC}"

# Verificar que existan los archivos de landing
if [ ! -f "landing/index.html" ]; then
    echo -e "${RED}❌ Error: No se encuentra landing/index.html${NC}"
    exit 1
fi

echo -e "${YELLOW}📁 Archivos de landing encontrados${NC}"
ls -la landing/

# Crear backup en VPS
echo -e "${YELLOW}💾 Creando backup en VPS...${NC}"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Crear directorio de backups
    sudo mkdir -p /opt/backups/landing
    
    # Backup de la landing actual si existe
    if [ -d "/opt/sharedance/landing" ]; then
        echo "Haciendo backup de landing"
        sudo tar -czf /opt/backups/landing/backup_landing_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz -C /opt/sharedance/landing . || true
        echo "Backup creado: /opt/backups/landing/backup_landing_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz"
    else
        echo "No hay landing previa para hacer backup"
    fi
EOF

# Preparar estructura en VPS
echo -e "${YELLOW}📁 Preparando estructura en VPS...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Crear directorio para landing
    sudo mkdir -p /opt/sharedance/landing
    sudo chown -R $VPS_USER:$VPS_USER /opt/sharedance/landing
    
    # Crear directorio temporal para upload
    mkdir -p /tmp/landing-deploy
EOF

# Subir landing
echo -e "${YELLOW}📤 Subiendo landing al VPS...${NC}"
rsync -avz --delete \
    -e "ssh -i $SSH_KEY" \
    landing/ \
    $VPS_USER@$VPS_HOST:/tmp/landing-deploy/

# Instalar landing en VPS
echo -e "${YELLOW}🔧 Instalando landing en VPS...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Instalar landing
    rm -rf /opt/sharedance/landing/*
    cp -r /tmp/landing-deploy/* /opt/sharedance/landing/
    
    # Limpiar temporal
    rm -rf /tmp/landing-deploy
    
    # Configurar permisos
    sudo chown -R www-data:www-data /opt/sharedance/landing
    sudo chmod -R 755 /opt/sharedance/landing
    
    echo "Landing instalada en: /opt/sharedance/landing"
    ls -la /opt/sharedance/landing/
EOF

# Actualizar configuración de Nginx
echo -e "${YELLOW}🌐 Actualizando configuración de Nginx...${NC}"

# Crear backup de configuración actual
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    BACKUP_DATE=\$(date +%Y%m%d_%H%M%S)
    sudo mkdir -p /opt/backups/nginx
    sudo cp /opt/sharedance/nginx-sharedance-$ENVIRONMENT.conf /opt/backups/nginx/nginx-${ENVIRONMENT}_\${BACKUP_DATE}.conf 2>/dev/null || echo "No hay config previa"
    echo "Backup de configuración Nginx completado"
EOF

# Actualizar configuración de Nginx para incluir landing page
if [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${YELLOW}📝 Actualizando configuración de Nginx para production...${NC}"
    ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << 'PRODUCTION_EOF'
    # Actualizar la configuración para incluir landing page
    sed -i '/# Main location - proxy to our Node.js app (EXISTING)/i\
    # Landing page - Static files (NEW)\
    location = / {\
        root /opt/sharedance/landing;\
        try_files /index.html =404;\
        expires 1h;\
        add_header Cache-Control "public";\
    }\
\
    # Landing static assets\
    location ~* ^/(script\.js|styles\.css|.*\.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot))$ {\
        root /opt/sharedance/landing;\
        expires 1h;\
        add_header Cache-Control "public";\
    }\
' /opt/sharedance/nginx-sharedance-production.conf
PRODUCTION_EOF
else
    echo -e "${YELLOW}📝 Actualizando configuración de Nginx para staging...${NC}"
    ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << 'STAGING_EOF'
    # Actualizar la configuración para incluir landing page
    sed -i '/# Main location - proxy to our Node.js app (EXISTING)/i\
    # Landing page - Static files (NEW)\
    location = / {\
        root /opt/sharedance/landing;\
        try_files /index.html =404;\
        expires 1h;\
        add_header Cache-Control "public";\
    }\
\
    # Landing static assets\
    location ~* ^/(script\.js|styles\.css|.*\.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot))$ {\
        root /opt/sharedance/landing;\
        expires 1h;\
        add_header Cache-Control "public";\
    }\
' /opt/sharedance/nginx-sharedance-staging.conf
STAGING_EOF
fi

# Aplicar configuración actualizada
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    echo "Copiando configuración actualizada a sites-available..."
    sudo cp /opt/sharedance/nginx-sharedance-$ENVIRONMENT.conf /etc/nginx/sites-available/nginx-sharedance-$ENVIRONMENT.conf
    
    # Test de configuración
    echo "Probando configuración de Nginx..."
    sudo nginx -t
    
    if [ \$? -eq 0 ]; then
        echo "Configuración válida. Recargando Nginx..."
        sudo systemctl reload nginx
        echo "✅ Nginx actualizado exitosamente"
    else
        echo "❌ Error en configuración de Nginx"
        exit 1
    fi
EOF

# Verificar deployment
echo -e "${YELLOW}🔍 Verificando deployment...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    echo "=== Verificación final ==="
    echo "Landing files:"
    ls -la /opt/sharedance/landing/
    
    echo ""
    echo "Nginx status:"
    sudo systemctl status nginx --no-pager -l | head -5
EOF

echo ""
echo -e "${GREEN}🎉 ¡Landing Page deployment completado exitosamente!${NC}"
if [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${GREEN}🌐 Landing disponible en: https://sharedance.com.ar/${NC}"
else
    echo -e "${GREEN}🌐 Landing disponible en: https://staging.sharedance.com.ar/${NC}"
fi
echo -e "${YELLOW}📋 Próximos pasos:${NC}"
echo "   1. Verificar que la landing carga correctamente"
echo "   2. Verificar que el dashboard sigue funcionando en /dashboard"
echo ""
echo -e "${YELLOW}🔄 Para rollback en caso de problemas:${NC}"
echo "   ssh -i $SSH_KEY $VPS_USER@$VPS_HOST"
echo "   sudo tar -xzf /opt/backups/landing/backup_landing_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz -C /opt/sharedance/landing"
