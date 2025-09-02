#!/bin/bash

# ShareDance Server Setup Script
echo "🚀 ShareDance Server Setup"
echo "=========================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js $(node -v) found"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "✅ .env file created. Please configure your Firebase settings."
else
    echo "✅ .env file already exists"
fi

# Build TypeScript
echo "🔨 Building TypeScript..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Failed to build TypeScript"
    exit 1
fi

echo "✅ TypeScript compiled successfully"

# Check for Firebase service account files
echo "🔍 Checking Firebase configuration..."

if [ ! -f "serviceAccount-staging.json" ] && [ ! -f "serviceAccount-production.json" ]; then
    echo "⚠️  Firebase service account files not found!"
    echo "📋 Next steps:"
    echo "   1. Download service account JSON from Firebase Console"
    echo "   2. Rename to 'serviceAccount-staging.json' or 'serviceAccount-production.json'"
    echo "   3. Update .env file with your Firebase project ID"
    echo "   4. Run 'npm start' to start the server"
else
    echo "✅ Firebase service account files found"
    
    # Test server startup (but don't keep it running)
    echo "🧪 Testing server startup..."
    timeout 10s npm start > /dev/null 2>&1
    
    if [ $? -eq 124 ]; then
        echo "✅ Server starts successfully!"
        echo "🎉 Setup complete! Run 'npm start' to start the server."
    else
        echo "⚠️  Server might have configuration issues. Check Firebase credentials."
    fi
fi

echo ""
echo "📖 Documentation: README.md"
echo "🔧 Configuration: .env"
echo "🚀 Start server: npm start"
echo "🛠️  Development: npm run dev"
