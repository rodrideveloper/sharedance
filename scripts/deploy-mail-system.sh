#!/bin/bash

# ShareDance Mail System Deployment Script
# Deploys the mail server configuration and updates the backend

set -e

VPS_HOST="148.113.197.152"
VPS_USER="ubuntu"
SSH_KEY="~/.ssh/rodrigo_vps"
PROJECT_PATH="/var/www/sharedance"

echo "🚀 Deploying ShareDance Mail System..."

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

# Create backup of current mail configuration
print_status "Creating backup of current configuration..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST "
    sudo mkdir -p /root/backups/mail-\$(date +%Y%m%d_%H%M%S)
    [ -f /etc/postfix/main.cf ] && sudo cp /etc/postfix/main.cf /root/backups/mail-\$(date +%Y%m%d_%H%M%S)/
    [ -f /etc/opendkim.conf ] && sudo cp /etc/opendkim.conf /root/backups/mail-\$(date +%Y%m%d_%H%M%S)/
"
print_success "Backup created"

# Upload mail server setup script
print_status "Uploading mail server setup script..."
scp -i $SSH_KEY scripts/setup-mail-server.sh $VPS_USER@$VPS_HOST:/tmp/
print_success "Setup script uploaded"

# Run mail server setup
print_status "Setting up mail server on VPS..."
ssh -i $SSH_KEY $VPS_USER@$VPS_HOST "
    chmod +x /tmp/setup-mail-server.sh
    sudo /tmp/setup-mail-server.sh
"
print_success "Mail server setup completed"

# Update backend with new email service
print_status "Updating backend email service..."

# Backup current email service
ssh $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH/backend/server/src/services
    [ -f emailService.js ] && cp emailService.js emailService_gmail_backup.js
"

# Upload new email service
scp backend/server/src/services/emailService_domain.js $VPS_USER@$VPS_HOST:$PROJECT_PATH/backend/server/src/services/emailService.js

# Upload mail environment configuration
scp backend/server/.env.mail $VPS_USER@$VPS_HOST:$PROJECT_PATH/backend/server/

# Update environment variables
ssh $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH/backend/server
    
    # Backup current .env
    [ -f .env ] && cp .env .env.backup-$(date +%Y%m%d_%H%M%S)
    
    # Merge mail configuration with existing .env
    cat .env.mail >> .env
    
    # Remove duplicate entries and clean up
    sort .env | uniq > .env.tmp && mv .env.tmp .env
"

print_success "Backend email service updated"

# Restart backend services
print_status "Restarting backend services..."
ssh $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH/backend/server
    pm2 restart sharedance-backend || pm2 start ecosystem.config.js
"
print_success "Backend services restarted"

# Test email configuration
print_status "Testing email configuration..."
ssh $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH/backend/server
    node -e \"
        const EmailService = require('./src/services/emailService');
        const service = new EmailService();
        console.log('Email service initialized successfully');
    \"
"
print_success "Email service test passed"

# Display DNS configuration instructions
print_warning "IMPORTANT: DNS Configuration Required"
echo ""
echo "🔧 Add these DNS records to your domain:"
echo ""
echo "1. MX Record:"
echo "   Name: sharedance.com.ar"
echo "   Value: 10 mail.sharedance.com.ar"
echo ""
echo "2. A Record:"
echo "   Name: mail.sharedance.com.ar"
echo "   Value: 148.113.197.152"
echo ""
echo "3. TXT Record (SPF):"
echo "   Name: sharedance.com.ar"
echo "   Value: \"v=spf1 mx a:mail.sharedance.com.ar ip4:148.113.197.152 ~all\""
echo ""
echo "4. TXT Record (DMARC):"
echo "   Name: _dmarc.sharedance.com.ar"
echo "   Value: \"v=DMARC1; p=quarantine; rua=mailto:postmaster@sharedance.com.ar\""
echo ""

# Get DKIM record from server
print_status "Getting DKIM record for DNS..."
echo "5. TXT Record (DKIM):"
echo "   Name: mail._domainkey.sharedance.com.ar"
echo "   Value:"
ssh $VPS_USER@$VPS_HOST "
    if [ -f /etc/opendkim/keys/sharedance.com.ar/mail.txt ]; then
        cat /etc/opendkim/keys/sharedance.com.ar/mail.txt | grep -v 'mail._domainkey' | tr -d '\n\t \"'
        echo
    else
        echo 'DKIM key not found - may need to be generated'
    fi
"

echo ""
print_success "Mail system deployment completed!"
echo ""
print_warning "Next steps:"
echo "1. Configure the DNS records shown above"
echo "2. Wait for DNS propagation (up to 24 hours)"
echo "3. Test email sending from dashboard"
echo "4. Monitor mail logs: ssh root@148.113.197.152 'tail -f /var/log/mail.log'"
