#!/bin/bash

# Nginx Setup Script for ShareDance
# Usage: ./setup-nginx.sh [domain] [VPS_IP] [VPS_USER]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN=${1:-"api.yourdomain.com"}
VPS_IP=${2:-"YOUR_VPS_IP"}
VPS_USER=${3:-"root"}
SSH_KEY=${4:-"~/.ssh/rodrigo_vps"}

echo -e "${BLUE}🌐 Nginx Setup for ShareDance${NC}"

# Check if VPS IP is provided
if [[ "$VPS_IP" == "YOUR_VPS_IP" ]]; then
    echo -e "${RED}❌ Error: Please provide VPS IP address${NC}"
    echo -e "${YELLOW}Usage: ./setup-nginx.sh [domain] [VPS_IP] [VPS_USER]${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 Setting up Nginx on VPS...${NC}"

# Create Nginx configuration
NGINX_CONFIG=$(cat << 'EOF'
server {
    listen 80;
    server_name DOMAIN_PLACEHOLDER;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;

    # Proxy to Node.js application
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health check endpoint (bypass rate limiting)
    location /health {
        limit_req off;
        proxy_pass http://127.0.0.1:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API routes with enhanced logging
    location /api/ {
        access_log /var/log/nginx/sharedance_api.log;
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Block common attack patterns
    location ~* \.(php|asp|aspx|jsp)$ {
        return 404;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
)

# Replace domain placeholder
NGINX_CONFIG=${NGINX_CONFIG//DOMAIN_PLACEHOLDER/$DOMAIN}

# Upload and configure Nginx
ssh -i ${SSH_KEY} ${VPS_USER}@${VPS_IP} bash << ENDSSH
# Install Nginx if not present
if ! command -v nginx &> /dev/null; then
    echo "📥 Installing Nginx..."
    apt update
    apt install -y nginx
fi

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Create ShareDance site configuration
echo "📝 Creating Nginx configuration..."
cat > /etc/nginx/sites-available/sharedance << 'EOFNGINX'
$NGINX_CONFIG
EOFNGINX

# Enable site
ln -sf /etc/nginx/sites-available/sharedance /etc/nginx/sites-enabled/

# Test configuration
echo "🧪 Testing Nginx configuration..."
nginx -t

# Create log directory
mkdir -p /var/log/nginx

# Restart Nginx
echo "🔄 Restarting Nginx..."
systemctl restart nginx
systemctl enable nginx

# Configure firewall
echo "🔥 Configuring firewall..."
ufw allow 22
ufw allow 80
ufw allow 443
echo "y" | ufw enable || true

echo "✅ Nginx setup completed"
ENDSSH

echo -e "${GREEN}✅ Nginx configured successfully!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "${YELLOW}1. Point your domain '$DOMAIN' to VPS IP: $VPS_IP${NC}"
echo -e "${YELLOW}2. Install SSL certificate with Certbot${NC}"
echo -e "${YELLOW}3. Start your Node.js application${NC}"

echo -e "${BLUE}🔗 SSL Setup command:${NC}"
echo -e "${YELLOW}ssh $VPS_USER@$VPS_IP 'apt install -y certbot python3-certbot-nginx && certbot --nginx -d $DOMAIN'${NC}"
