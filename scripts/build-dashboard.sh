#!/bin/bash

# ShareDance Dashboard Build Script
echo "🏗️  Building ShareDance Dashboard..."

# Set environment
ENVIRONMENT=${1:-staging}
echo "📦 Environment: $ENVIRONMENT"

# Navigate to dashboard directory
cd "$(dirname "$0")/../apps/dashboard"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for web with environment
echo "🔨 Building Flutter web app..."
if [ "$ENVIRONMENT" = "production" ]; then
    flutter build web --release \
        --base-href="/dashboard/" \
        --dart-define=ENVIRONMENT=production \
        --dart-define=API_BASE_URL=https://sharedance.com.ar/api \
        --dart-define=FRONTEND_URL=https://sharedance.com.ar
else
    flutter build web --release \
        --base-href="/dashboard/" \
        --dart-define=ENVIRONMENT=staging \
        --dart-define=API_BASE_URL=https://staging.sharedance.com.ar/api \
        --dart-define=FRONTEND_URL=https://staging.sharedance.com.ar
fi

echo "✅ Build completed!"
echo "📁 Build files are in: build/web/"
echo ""
echo "🚀 To deploy:"
echo "   rsync -avz --delete build/web/ user@your-vps:/var/www/sharedance/dashboard/"
