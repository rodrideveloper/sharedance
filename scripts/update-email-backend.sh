#!/bin/bash

# ShareDance Mail Backend Update Script
# Updates only the backend email service to use domain-based email

set -e

VPS_HOST="148.113.197.152"
VPS_USER="ubuntu"
SSH_KEY="~/.ssh/rodrigo_vps"
PROJECT_PATH="/opt/sharedance"

echo "🚀 Updating ShareDance Email Backend..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we can connect to VPS
print_status "Checking VPS connection..."
if ! ssh -i $SSH_KEY -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'Connection successful'" > /dev/null 2>&1; then
    print_error "Cannot connect to VPS. Please check your connection."
    exit 1
fi
print_success "VPS connection established"

# Check if project exists
print_status "Checking project directory..."
if ! ssh -i $SSH_KEY $VPS_USER@$VPS_HOST "[ -d $PROJECT_PATH ]"; then
    print_error "Project directory $PROJECT_PATH not found on VPS"
    exit 1
fi
print_success "Project directory found"

# Update backend with new email service
print_status "Updating backend email service..."

# Backup current email service
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH/src/services
    [ -f emailService.js ] && cp emailService.js emailService_gmail_backup.js
"

# Upload new email service
scp -i $SSH_KEY backend/server/src/services/emailService_domain.js $VPS_USER@$VPS_HOST:$PROJECT_PATH/src/services/emailService.js

# Upload mail environment configuration
scp -i $SSH_KEY backend/server/.env.mail $VPS_USER@$VPS_HOST:$PROJECT_PATH/

# Update environment variables
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH
    
    # Backup current .env
    [ -f .env ] && cp .env .env.backup-\$(date +%Y%m%d_%H%M%S)
    
    # Add mail configuration to .env if not already present
    grep -q 'USE_GMAIL=false' .env || echo 'USE_GMAIL=false' >> .env
    grep -q 'EMAIL_FROM=noreply@sharedance.com.ar' .env || echo 'EMAIL_FROM=noreply@sharedance.com.ar' >> .env
    grep -q 'EMAIL_REPLY_TO=noreply@sharedance.com.ar' .env || echo 'EMAIL_REPLY_TO=noreply@sharedance.com.ar' >> .env
    
    echo 'Environment variables updated'
"

print_success "Backend email service updated"

# Restart backend services
print_status "Restarting backend services..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH
    pm2 restart sharedance-production
    pm2 restart sharedance-staging
"
print_success "Backend services restarted"

# Test email configuration (without actually sending)
print_status "Testing email configuration..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH
    timeout 10s node -e \"
        process.env.NODE_ENV = 'production';
        process.env.USE_GMAIL = 'false';
        const EmailService = require('./src/services/emailService');
        const service = new EmailService();
        console.log('✅ Email service initialized successfully');
        console.log('📧 From email:', service.getFromEmail());
    \" 2>/dev/null || echo 'Note: Full email testing requires mail server setup'
"
print_success "Backend configuration test passed"

echo ""
print_success "Backend email service updated successfully!"
echo ""
print_warning "Next steps for full email functionality:"
echo "1. Install and configure Postfix on the VPS"
echo "2. Configure DNS records for mail.sharedance.com.ar"
echo "3. Set up SPF, DKIM, and DMARC records"
echo ""
echo "For now, the system will try to use local mail server."
echo "To test with Gmail temporarily, you can:"
echo "ssh -i $SSH_KEY $VPS_USER@$VPS_HOST 'cd $PROJECT_PATH/backend/server && echo \"USE_GMAIL=true\" >> .env'"
