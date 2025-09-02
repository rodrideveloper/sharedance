#!/bin/bash

# ShareDance Firebase Setup Script
# This script sets up Firebase services for both staging and production environments

set -e

echo "🔥 ShareDance Firebase Setup"
echo "=========================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Function to setup environment
setup_environment() {
    local env=$1
    echo "🚀 Setting up $env environment..."
    
    # Switch to the environment
    firebase use sharedance-$env
    
    echo "📝 Deploying Firestore rules and indexes..."
    firebase deploy --only firestore:rules
    firebase deploy --only firestore:indexes
    
    echo "⚡ Deploying Firebase Functions..."
    firebase deploy --only functions
    
    echo "✅ $env environment setup completed!"
    echo ""
}

# Function to initialize Firestore data
init_firestore_data() {
    local env=$1
    echo "📊 Initializing Firestore data for $env..."
    
    # Check if service account key exists
    if [ ! -f "serviceAccountKey-$env.json" ]; then
        echo "⚠️  Service account key not found for $env"
        echo "Please download it from Firebase Console and save as serviceAccountKey-$env.json"
        echo "Skipping data initialization for $env..."
        return
    fi
    
    # Set environment variable and run initialization
    export GOOGLE_APPLICATION_CREDENTIALS="serviceAccountKey-$env.json"
    node scripts/init_firestore.js
    echo "✅ Firestore data initialized for $env!"
    echo ""
}

# Function to enable Firebase services via console
show_console_setup() {
    local env=$1
    echo "🌐 Manual setup required in Firebase Console for $env:"
    echo "https://console.firebase.google.com/project/sharedance-$env"
    echo ""
    echo "Please enable the following services:"
    echo "1. 🔐 Authentication"
    echo "   - Go to Authentication > Sign-in method"
    echo "   - Enable Email/Password"
    echo "   - Enable Google (optional)"
    echo ""
    echo "2. 🗄️  Firestore Database"
    echo "   - Should already be enabled after deploying rules"
    echo ""
    echo "3.  Cloud Messaging"
    echo "   - Go to Cloud Messaging"
    echo "   - No additional setup required"
    echo ""
    echo "4. ⚡ Functions"
    echo "   - Should be enabled after deploying functions"
    echo ""
}

# Main execution
echo "Select setup option:"
echo "1. Setup staging environment"
echo "2. Setup production environment"  
echo "3. Setup both environments"
echo "4. Show console setup instructions"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        setup_environment "staging"
        init_firestore_data "staging"
        show_console_setup "staging"
        ;;
    2)
        setup_environment "production"
        init_firestore_data "production"
        show_console_setup "production"
        ;;
    3)
        setup_environment "staging"
        init_firestore_data "staging"
        echo "🔄 Switching to production..."
        setup_environment "production"
        init_firestore_data "production"
        echo "📋 Console setup required for both environments:"
        show_console_setup "staging"
        show_console_setup "production"
        ;;
    4)
        show_console_setup "staging"
        show_console_setup "production"
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo "🎉 Setup completed!"
echo ""
echo "📝 Next steps:"
echo "1. Complete the manual setup in Firebase Console (if not done)"
echo "2. Download service account keys if you want to initialize sample data"
echo "3. Test your Flutter app with both environments"
echo "4. Deploy your app to app stores"
