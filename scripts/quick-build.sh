#!/bin/bash

set -e

ENVIRONMENT=${1:-staging}

echo "🚀 Building ShareDance Dashboard for $ENVIRONMENT..."

# Navigate to dashboard directory
cd apps/dashboard

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web with base href
echo "🔨 Building for web..."
if [ "$ENVIRONMENT" = "production" ]; then
    flutter build web --release \
        --base-href "/dashboard/" \
        --dart-define=ENVIRONMENT=production \
        --dart-define=API_BASE_URL=https://sharedance.com.ar/api \
        --dart-define=FRONTEND_URL=https://sharedance.com.ar
else
    flutter build web --release \
        --base-href "/dashboard/" \
        --dart-define=ENVIRONMENT=staging \
        --dart-define=API_BASE_URL=https://staging.sharedance.com.ar/api \
        --dart-define=FRONTEND_URL=https://staging.sharedance.com.ar
fi

# Optimize assets (if tools are available)
echo "🎨 Optimizing assets..."
if command -v optipng &> /dev/null; then
    find build/web -name "*.png" -exec optipng -quiet {} \; 2>/dev/null || true
fi

echo "✅ Build completed successfully!"
echo "� Output directory: apps/dashboard/build/web/"
echo "🌐 Base href configured for: /dashboard/"
echo ""
echo "� Next steps:"
if [ "$ENVIRONMENT" = "production" ]; then
    echo "   1. Upload to VPS: rsync -avz --delete build/web/ user@vps:/var/www/sharedance/dashboard/"
    echo "   2. Test at: https://sharedance.com.ar/dashboard"
else
    echo "   1. Upload to VPS: rsync -avz --delete build/web/ user@vps:/var/www/staging-sharedance/dashboard/"
    echo "   2. Test at: https://staging.sharedance.com.ar/dashboard"
fi
echo "   3. Configure Nginx for /dashboard route"
