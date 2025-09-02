#!/bin/bash

# ShareDance Mail Testing Script
# Tests the mail system configuration and functionality

set -e

VPS_HOST="148.113.197.152"
VPS_USER="root"
PROJECT_PATH="/var/www/sharedance"

echo "🧪 Testing ShareDance Mail System..."

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

# Test VPS connection
print_status "Testing VPS connection..."
if ssh -o ConnectTimeout=10 $VPS_USER@$VPS_HOST "echo 'Connection OK'" > /dev/null 2>&1; then
    print_success "VPS connection OK"
else
    print_error "Cannot connect to VPS"
    exit 1
fi

# Test Postfix service
print_status "Testing Postfix service..."
if ssh $VPS_USER@$VPS_HOST "systemctl is-active postfix" > /dev/null 2>&1; then
    print_success "Postfix is running"
else
    print_error "Postfix is not running"
    exit 1
fi

# Test OpenDKIM service
print_status "Testing OpenDKIM service..."
if ssh $VPS_USER@$VPS_HOST "systemctl is-active opendkim" > /dev/null 2>&1; then
    print_success "OpenDKIM is running"
else
    print_warning "OpenDKIM is not running - DKIM signing may not work"
fi

# Test mail queue
print_status "Checking mail queue..."
QUEUE_COUNT=$(ssh $VPS_USER@$VPS_HOST "mailq | grep -c '^[A-F0-9]' || echo '0'")
if [ "$QUEUE_COUNT" -eq 0 ]; then
    print_success "Mail queue is empty"
else
    print_warning "Mail queue has $QUEUE_COUNT messages"
fi

# Test local mail delivery
print_status "Testing local mail delivery..."
ssh $VPS_USER@$VPS_HOST "
    echo 'Test message from ShareDance mail system' | mail -s 'ShareDance Mail Test' root
    sleep 2
"
print_success "Test email sent to local root user"

# Test DNS configuration
print_status "Testing DNS configuration..."

# Test MX record
print_status "Checking MX record..."
MX_RESULT=$(dig MX sharedance.com.ar +short | head -1)
if [[ $MX_RESULT == *"mail.sharedance.com.ar"* ]]; then
    print_success "MX record configured correctly: $MX_RESULT"
else
    print_warning "MX record not found or incorrect: $MX_RESULT"
fi

# Test A record for mail subdomain
print_status "Checking mail.sharedance.com.ar A record..."
A_RESULT=$(dig A mail.sharedance.com.ar +short | head -1)
if [[ $A_RESULT == "148.113.197.152" ]]; then
    print_success "A record configured correctly: $A_RESULT"
else
    print_warning "A record not found or incorrect: $A_RESULT"
fi

# Test SPF record
print_status "Checking SPF record..."
SPF_RESULT=$(dig TXT sharedance.com.ar +short | grep "v=spf1")
if [[ ! -z $SPF_RESULT ]]; then
    print_success "SPF record found: $SPF_RESULT"
else
    print_warning "SPF record not found"
fi

# Test DKIM record
print_status "Checking DKIM record..."
DKIM_RESULT=$(dig TXT mail._domainkey.sharedance.com.ar +short | head -1)
if [[ $DKIM_RESULT == *"v=DKIM1"* ]]; then
    print_success "DKIM record found"
else
    print_warning "DKIM record not found or incorrect"
fi

# Test backend email service
print_status "Testing backend email service..."
ssh $VPS_USER@$VPS_HOST "
    cd $PROJECT_PATH/backend/server
    timeout 10s node -e \"
        process.env.NODE_ENV = 'production';
        process.env.USE_GMAIL = 'false';
        const EmailService = require('./src/services/emailService');
        const service = new EmailService();
        console.log('✅ Email service initialized successfully');
        console.log('📧 From email:', service.getFromEmail());
    \" 2>/dev/null || echo 'Backend email service test failed'
"

# Test API endpoint
print_status "Testing invitation API endpoint..."
BACKEND_URL="https://sharedance.com.ar/api"

# Check if backend is responding
if curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
    print_success "Backend API is responding"
    
    # Test invitation endpoint (dry run)
    print_status "Testing invitation endpoint..."
    curl -s -X POST "$BACKEND_URL/invitations/send" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com",
            "role": "student",
            "inviterName": "Test System",
            "customMessage": "This is a test invitation",
            "dryRun": true
        }' | jq '.' 2>/dev/null || echo "API test completed"
else
    print_warning "Backend API is not responding"
fi

# Show mail logs
print_status "Recent mail log entries..."
ssh $VPS_USER@$VPS_HOST "tail -10 /var/log/mail.log 2>/dev/null || echo 'No mail logs available'"

# Summary
echo ""
echo "==============================================="
print_status "MAIL SYSTEM TEST SUMMARY"
echo "==============================================="
echo ""

# Service status
echo "📋 Service Status:"
ssh $VPS_USER@$VPS_HOST "
    echo '  Postfix: ' \$(systemctl is-active postfix)
    echo '  OpenDKIM: ' \$(systemctl is-active opendkim 2>/dev/null || echo 'inactive')
    echo '  Backend: ' \$(pm2 list | grep sharedance-backend | awk '{print \$10}' || echo 'unknown')
"

# DNS status
echo ""
echo "🌐 DNS Status:"
echo "  MX Record: $(if [[ $MX_RESULT == *"mail.sharedance.com.ar"* ]]; then echo "✅ OK"; else echo "❌ Missing"; fi)"
echo "  A Record: $(if [[ $A_RESULT == "148.113.197.152" ]]; then echo "✅ OK"; else echo "❌ Missing"; fi)"
echo "  SPF Record: $(if [[ ! -z $SPF_RESULT ]]; then echo "✅ OK"; else echo "❌ Missing"; fi)"
echo "  DKIM Record: $(if [[ $DKIM_RESULT == *"v=DKIM1"* ]]; then echo "✅ OK"; else echo "❌ Missing"; fi)"

echo ""
print_success "Mail system test completed!"
echo ""
print_warning "If DNS records are missing, configure them before sending emails"
echo "For manual testing, you can send an email with:"
echo "ssh root@148.113.197.152 'echo \"Test\" | mail -s \"Test\" your-email@domain.com'"
