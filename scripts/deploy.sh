#!/bin/bash

# ShareDance Complete Deployment Script
set -e

# Configuration
ENVIRONMENT=${1:-staging}
VPS_USER="ubuntu"
V    # API routes
    location /api {
        proxy_pass http://localhost:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }.113.197.152"
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

# 4. Update Nginx configuration (only if needed)
echo "🔧 Step 4: Checking Nginx configuration..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST << EOF
    # Check if nginx config exists and has the correct structure
    if [ "$ENVIRONMENT" = "production" ]; then
        CONFIG_FILE="/etc/nginx/sites-available/sharedance"
    else
        CONFIG_FILE="/etc/nginx/sites-available/sharedance-staging"
    fi
    
    # Only update if config doesn't exist or doesn't have health endpoint
    if [ ! -f "\\\$CONFIG_FILE" ] || ! grep -q "location /health" "\\\$CONFIG_FILE"; then
        echo "⚠️  Nginx config needs update, but manual configuration detected."
        echo "📋 Please ensure your nginx config includes:"
        echo "   - Landing page served from /opt/sharedance/landing"
        echo "   - /health endpoint proxied to backend"
        echo "   - /api endpoints proxied to localhost:$API_PORT"
        echo "   - /dashboard served from /opt/sharedance/dashboard/$ENVIRONMENT"
    else
        echo "✅ Nginx configuration already correct!"
    fi
    
    # Test nginx config
    sudo nginx -t
EOF

# Clean up
rm sharedance-backend-$ENVIRONMENT.tar.gz

echo ""
echo "🎉 Deployment completed successfully!"
echo "🌐 Dashboard: https://$DOMAIN/dashboard"
echo "🔗 API: https://$DOMAIN/api"
echo "🏠 Landing: https://$DOMAIN"
echo "🔍 Health: https://$DOMAIN/health"
echo ""
echo "🔍 To check status:"
echo "   ssh -i $SSH_KEY $VPS_USER@$VPS_HOST 'pm2 status'"
