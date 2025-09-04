#!/bin/bash

# ShareDance Complete Deployment Script
set -e

# Configuration
ENVIRONMENT=${1:-staging}
VPS_USER="ubuntu"
VPS_HOST="148.113.197.152"
SSH_KEY="~/.ssh/rodrigo_vps"

if [ "$ENVIRONMENT" = "production" ]; then
    DOMAIN="sharedance.com.ar"
    VPS_PATH="/opt/sharedance"
    API_PORT="3002"
else
    DOMAIN="staging.sharedance.com.ar"
    VPS_PATH="/opt/sharedance"
    API_PORT="3001"
fi

echo "🚀 Deploying ShareDance to $ENVIRONMENT environment"
echo "🌐 Domain: $DOMAIN"
echo "📁 VPS Path: $VPS_PATH"

# 1. Build Dashboard
echo "📦 Step 1: Building Dashboard..."
./scripts/build-dashboard.sh $ENVIRONMENT

# 2. Prepare Backend
echo "🔧 Step 2: Preparing Backend..."
cd backend/server

# Install dependencies
npm ci --production

# Create deployment package
echo "📦 Creating deployment package..."
tar -czf ../../sharedance-backend-$ENVIRONMENT.tar.gz \
    --exclude=node_modules \
    --exclude=.git \
    --exclude=logs \
    --exclude=*.log \
    .

cd ../..

# 3. Deploy to VPS
echo "🚀 Step 3: Deploying to VPS..."

# Upload backend
echo "📤 Uploading backend..."
scp -i $SSH_KEY sharedance-backend-$ENVIRONMENT.tar.gz $VPS_USER@$VPS_HOST:/tmp/

# Upload dashboard (commented out for now as we're focusing on backend API)
echo "📤 Uploading dashboard..."
# rsync -avz --delete -e "ssh -i $SSH_KEY" apps/dashboard/build/web/ $VPS_USER@$VPS_HOST:$VPS_PATH/dashboard/

# Deploy backend on VPS
echo "🔧 Deploying backend on VPS..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Create directories
    sudo mkdir -p $VPS_PATH/server
    sudo chown -R $VPS_USER:$VPS_USER $VPS_PATH
    
    # Extract backend
    cd $VPS_PATH/server
    tar -xzf /tmp/sharedance-backend-$ENVIRONMENT.tar.gz
    
    # Install dependencies
    npm ci --production
    
    # Setup environment file
    cp .env.$ENVIRONMENT .env
    
    # Restart services
    pm2 stop sharedance-$ENVIRONMENT || true
    pm2 start ecosystem.config.json --only sharedance-$ENVIRONMENT --env $ENVIRONMENT
    pm2 save
    
    # Clean up
    rm /tmp/sharedance-backend-$ENVIRONMENT.tar.gz
    
    echo "✅ Backend deployed successfully!"
EOF

# 4. Update Nginx configuration
echo "🔧 Step 4: Updating Nginx..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << 'EOF'
    # Update Nginx config for dashboard routing
    sudo tee /etc/nginx/sites-available/sharedance << 'NGINX_CONFIG'
server {
    listen 80;
    server_name sharedance.com.ar www.sharedance.com.ar;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name sharedance.com.ar www.sharedance.com.ar;
    
    # SSL configuration (configure your SSL certificates)
    ssl_certificate /etc/ssl/certs/sharedance.crt;
    ssl_certificate_key /etc/ssl/private/sharedance.key;
    
    # Root directory for static files
    root /var/www/sharedance;
    index index.html;
    
    # Dashboard route
    location /dashboard {
        alias /var/www/sharedance/dashboard;
        try_files $uri $uri/ /dashboard/index.html;
        
        # Headers for Flutter web
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # API routes
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Landing page (root)
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_CONFIG

    # Test and reload Nginx
    sudo nginx -t && sudo systemctl reload nginx
    
    echo "✅ Nginx configuration updated!"
EOF

# Clean up
rm sharedance-backend-$ENVIRONMENT.tar.gz

echo ""
echo "🎉 Deployment completed successfully!"
echo "🌐 Dashboard: https://$DOMAIN/dashboard"
echo "🔗 API: https://$DOMAIN/api"
echo "🏠 Landing: https://$DOMAIN"
echo ""
echo "🔍 To check status:"
echo "   ssh -i $SSH_KEY $VPS_USER@$VPS_HOST 'pm2 status'"
