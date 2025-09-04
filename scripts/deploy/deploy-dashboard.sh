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

echo -e "${GREEN}🚀 ShareDance Dashboard Deployment Script${NC}"
echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
echo -e "${YELLOW}VPS: $VPS_HOST${NC}"

# Verificar conexión SSH
echo -e "${YELLOW}🔍 Verificando conexión SSH...${NC}"
if ! ssh -i $SSH_KEY -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: No se puede conectar al VPS${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Conexión SSH exitosa${NC}"

# Configurar rutas según el entorno
if [ "$ENVIRONMENT" = "production" ]; then
    VPS_DOMAIN="sharedance.com.ar"
    VPS_PATH="/opt/sharedance/production"
    NGINX_SITE="sharedance-production"
else
    VPS_DOMAIN="staging.sharedance.com.ar"
    VPS_PATH="/opt/sharedance/staging"
    NGINX_SITE="sharedance-staging"
fi

echo -e "${YELLOW}📁 Ruta en VPS: $VPS_PATH${NC}"

# 1. Explorar estructura actual en VPS
echo -e "${YELLOW}🔍 Explorando estructura actual en VPS...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    echo "=== Estructura actual en $VPS_PATH ==="
    ls -la $VPS_PATH/ 2>/dev/null || echo "Directorio no existe"
    
    echo ""
    echo "=== Contenido de /opt/sharedance ==="
    ls -la /opt/sharedance/ 2>/dev/null || echo "Directorio /opt/sharedance no existe"
    
    echo ""
    echo "=== Procesos PM2 activos ==="
    pm2 list || echo "PM2 no disponible"
    
    echo ""
    echo "=== Configuración Nginx ==="
    ls -la /etc/nginx/sites-enabled/ | grep sharedance || echo "No hay sitios de sharedance"
EOF

# Esperar confirmación del usuario
echo ""
echo -e "${YELLOW}⚠️  ¿Deseas continuar con el deployment? (y/N)${NC}"
read -r CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelado${NC}"
    exit 0
fi

# 2. Build del dashboard local
echo -e "${YELLOW}📦 Building dashboard locally...${NC}"
cd ../../apps/dashboard
echo -e "${YELLOW}🔧 Ejecutando flutter build web para $ENVIRONMENT con base-href...${NC}"
if ! flutter build web --dart-define=FLAVOR=$ENVIRONMENT --base-href=/dashboard/; then
    echo -e "${RED}❌ Error en el build del dashboard${NC}"
    exit 1
fi
cd ../../scripts/deploy

if [ ! -d "../../apps/dashboard/build/web" ]; then
    echo -e "${RED}❌ Error: Build falló o directorio no existe${NC}"
    exit 1
fi

# 3. Crear backup en VPS
echo -e "${YELLOW}💾 Creando backup en VPS...${NC}"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Crear directorio de backups
    sudo mkdir -p /opt/backups/sharedance
    
    # Backup de la estructura actual
    if [ -d "$VPS_PATH" ]; then
        echo "Haciendo backup de $VPS_PATH"
        sudo tar -czf /opt/backups/sharedance/backup_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz -C $VPS_PATH . || true
        echo "Backup creado: /opt/backups/sharedance/backup_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz"
    else
        echo "No hay estructura previa para hacer backup"
    fi
EOF

# 4. Preparar estructura en VPS
echo -e "${YELLOW}📁 Preparando estructura en VPS...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Crear directorios necesarios
    sudo mkdir -p /opt/sharedance/dashboard/$ENVIRONMENT
    sudo chown -R $VPS_USER:$VPS_USER /opt/sharedance/dashboard
    
    # Crear directorio temporal para upload
    mkdir -p /tmp/sharedance-deploy
EOF

# 5. Subir dashboard
echo -e "${YELLOW}📤 Subiendo dashboard al VPS...${NC}"
rsync -avz --delete \
    -e "ssh -i $SSH_KEY" \
    ../../apps/dashboard/build/web/ \
    $VPS_USER@$VPS_HOST:/tmp/sharedance-deploy/

# 6. Instalar dashboard en VPS
echo -e "${YELLOW}🔧 Instalando dashboard en VPS...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Instalar dashboard
    rm -rf /opt/sharedance/dashboard/$ENVIRONMENT/*
    cp -r /tmp/sharedance-deploy/* /opt/sharedance/dashboard/$ENVIRONMENT/
    
    # Limpiar temporal
    rm -rf /tmp/sharedance-deploy
    
    # Configurar permisos
    sudo chown -R www-data:www-data /opt/sharedance/dashboard
    sudo chmod -R 755 /opt/sharedance/dashboard
    
    echo "Dashboard instalado en: /opt/sharedance/dashboard/$ENVIRONMENT"
    ls -la /opt/sharedance/dashboard/$ENVIRONMENT/
EOF

# 7. Actualizar configuraciones de Nginx existentes
echo -e "${YELLOW}🌐 Actualizando configuración de Nginx...${NC}"

# Crear backup de configuraciones actuales
echo -e "${YELLOW}📋 Creando backup de configuraciones actuales...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    BACKUP_DATE=\$(date +%Y%m%d_%H%M%S)
    sudo mkdir -p /opt/backups/nginx
    sudo cp /opt/sharedance/nginx-sharedance-staging.conf /opt/backups/nginx/nginx-staging_\${BACKUP_DATE}.conf 2>/dev/null || echo "No hay config staging"
    sudo cp /opt/sharedance/nginx-sharedance-production.conf /opt/backups/nginx/nginx-production_\${BACKUP_DATE}.conf 2>/dev/null || echo "No hay config production"
    echo "Backup de configuraciones Nginx completado"
EOF

# Actualizar configuración según el entorno
if [ "$ENVIRONMENT" = "staging" ]; then
    echo -e "${YELLOW}📝 Actualizando configuración de Nginx para staging...${NC}"
    ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << 'STAGING_EOF'
    cat > /opt/sharedance/nginx-sharedance-staging.conf << 'NGINX_STAGING'
server {
    listen 80;
    server_name staging.sharedance.com.ar;
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name staging.sharedance.com.ar;

    # SSL Configuration (using existing Let's Encrypt certificates)
    ssl_certificate /etc/letsencrypt/live/staging.sharedance.com.ar/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/staging.sharedance.com.ar/privkey.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Environment "staging";

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Landing page - Static files (PRIORITY 1)
    location = / {
        root /opt/sharedance/landing;
        try_files /index.html =404;
        expires 1h;
        add_header Cache-Control "public";
    }

    # Landing static assets (PRIORITY 2)
    location ~* ^/(script\.js|styles\.css|.*\.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot))$ {
        root /opt/sharedance/landing;
        expires 1h;
        add_header Cache-Control "public";
    }

    # Dashboard - Flutter Web (PRIORITY 3)
    location /dashboard/ {
        alias /opt/sharedance/dashboard/staging/;
        index index.html;
        try_files \$uri \$uri/ index.html;
        
        # Cache headers for dashboard assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1h;
            add_header Cache-Control "public";
        }
    }

    # Health check endpoint (PRIORITY 4)
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        access_log off;
    }

    # API endpoints (PRIORITY 5)
    location /api {
        proxy_pass http://localhost:3001/api;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Backend catch-all (LOWEST PRIORITY)
    location / {
        # Try static files first, then proxy to backend
        try_files \$uri @backend;
    }

    location @backend {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Logs
    access_log /var/log/nginx/sharedance-staging.access.log;
    error_log /var/log/nginx/sharedance-staging.error.log;
}
NGINX_STAGING
STAGING_EOF
else
    echo -e "${YELLOW}📝 Actualizando configuración de Nginx para production...${NC}"
    ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << 'PRODUCTION_EOF'
    cat > /opt/sharedance/nginx-sharedance-production.conf << 'NGINX_PRODUCTION'
server {
    listen 80;
    server_name sharedance.com.ar www.sharedance.com.ar;
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name sharedance.com.ar www.sharedance.com.ar;

    # SSL Configuration (using existing Let's Encrypt certificates)
    ssl_certificate /etc/letsencrypt/live/sharedance.com.ar/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sharedance.com.ar/privkey.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Landing page - Static files (PRIORITY 1)
    location = / {
        root /opt/sharedance/landing;
        try_files /index.html =404;
        expires 1h;
        add_header Cache-Control "public";
    }

    # Landing static assets (PRIORITY 2)
    location ~* ^/(script\.js|styles\.css|.*\.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot))$ {
        root /opt/sharedance/landing;
        expires 1h;
        add_header Cache-Control "public";
    }

    # Dashboard - Flutter Web (PRIORITY 3)
    location /dashboard/ {
        alias /opt/sharedance/dashboard/production/;
        index index.html;
        try_files \$uri \$uri/ index.html;
        
        # Cache headers for dashboard assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1h;
            add_header Cache-Control "public";
        }
    }

    # Health check endpoint (PRIORITY 4)
    location /health {
        proxy_pass http://localhost:3002/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        access_log off;
    }

    # API endpoints (PRIORITY 5)
    location /api {
        proxy_pass http://localhost:3002/api;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Backend catch-all (LOWEST PRIORITY)
    location / {
        # Try static files first, then proxy to backend
        try_files \$uri @backend;
    }

    location @backend {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Logs
    access_log /var/log/nginx/sharedance-production.access.log;
    error_log /var/log/nginx/sharedance-production.error.log;
}
NGINX_PRODUCTION
PRODUCTION_EOF
fi

# Verificar y aplicar configuración actualizada
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    echo "Copiando configuración actualizada a sites-available..."
    sudo cp /opt/sharedance/nginx-sharedance-$ENVIRONMENT.conf /etc/nginx/sites-available/nginx-sharedance-$ENVIRONMENT.conf
    
    # Crear enlace simbólico si no existe
    sudo ln -sf /etc/nginx/sites-available/nginx-sharedance-$ENVIRONMENT.conf /etc/nginx/sites-enabled/nginx-sharedance-$ENVIRONMENT.conf
    
    # Test de configuración
    echo "Probando configuración de Nginx..."
    sudo nginx -t
    
    if [ $? -eq 0 ]; then
        echo "Configuración válida. Recargando Nginx..."
        sudo systemctl reload nginx
        echo "✅ Nginx actualizado exitosamente"
    else
        echo "❌ Error en configuración de Nginx"
        exit 1
    fi
EOF

# 8. Verificar deployment
echo -e "${YELLOW}🔍 Verificando deployment...${NC}"
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    echo "=== Verificación final ==="
    echo "Dashboard files:"
    ls -la $VPS_PATH/dashboard/ | head -10
    
    echo ""
    echo "Nginx status:"
    sudo systemctl status nginx --no-pager -l | head -5
    
    echo ""
    echo "Disk usage:"
    du -sh $VPS_PATH/*
EOF

echo ""
echo -e "${GREEN}🎉 ¡Deployment completado exitosamente!${NC}"
echo -e "${GREEN}🌐 Dashboard disponible en: https://$VPS_DOMAIN/dashboard${NC}"
echo -e "${YELLOW}📋 Próximos pasos:${NC}"
echo "   1. Verificar que el dashboard carga correctamente"
echo "   2. Configurar SSL certificates si es necesario"
echo "   3. Deployar el backend cuando esté listo"
echo ""
echo -e "${YELLOW}🔄 Para rollback en caso de problemas:${NC}"
echo "   ssh -i $SSH_KEY $VPS_USER@$VPS_HOST"
echo "   sudo tar -xzf /opt/backups/sharedance/backup_${ENVIRONMENT}_${BACKUP_DATE}.tar.gz -C $VPS_PATH"
