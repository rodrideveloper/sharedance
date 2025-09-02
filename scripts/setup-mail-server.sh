#!/bin/bash

# ShareDance Mail Server Setup Script
# Configures Postfix for sending emails from sharedance.com.ar domain

set -e

echo "🚀 Setting up ShareDance mail server..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install Postfix and related packages
echo "📧 Installing Postfix and mail utilities..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    postfix \
    mailutils \
    opendkim \
    opendkim-tools \
    dnsutils

# Configure Postfix main settings
echo "⚙️ Configuring Postfix..."
cat > /etc/postfix/main.cf << 'EOF'
# ShareDance Postfix Configuration
smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# Network configuration
myhostname = mail.sharedance.com.ar
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = sharedance.com.ar
mydestination = $myhostname, sharedance.com.ar, localhost.sharedance.com.ar, localhost
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

# DKIM configuration
milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891

# Security settings
smtpd_helo_required = yes
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    reject_invalid_hostname,
    reject_non_fqdn_hostname,
    reject_non_fqdn_sender,
    reject_non_fqdn_recipient,
    reject_unknown_sender_domain,
    reject_unknown_recipient_domain

# Rate limiting
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 100
EOF

# Configure OpenDKIM
echo "🔐 Configuring DKIM..."
mkdir -p /etc/opendkim/keys/sharedance.com.ar

cat > /etc/opendkim.conf << 'EOF'
# ShareDance OpenDKIM Configuration
AutoRestart             Yes
AutoRestartRate         10/1h
LogWhy                  Yes
Syslog                  Yes
SyslogSuccess           Yes
Mode                    sv
Canonicalization        relaxed/simple
ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable
Socket                  inet:8891@localhost
PidFile                 /var/run/opendkim/opendkim.pid
UMask                   022
UserID                  opendkim:opendkim
TemporaryDirectory      /var/tmp
EOF

# Create DKIM key
echo "🗝️ Generating DKIM key..."
opendkim-genkey -t -s mail -d sharedance.com.ar -D /etc/opendkim/keys/sharedance.com.ar/

# Set permissions
chown opendkim:opendkim /etc/opendkim/keys/sharedance.com.ar/mail.private
chmod 600 /etc/opendkim/keys/sharedance.com.ar/mail.private

# Configure DKIM tables
cat > /etc/opendkim/TrustedHosts << 'EOF'
127.0.0.1
localhost
192.168.0.1/24
*.sharedance.com.ar
EOF

cat > /etc/opendkim/KeyTable << 'EOF'
mail._domainkey.sharedance.com.ar sharedance.com.ar:mail:/etc/opendkim/keys/sharedance.com.ar/mail.private
EOF

cat > /etc/opendkim/SigningTable << 'EOF'
*@sharedance.com.ar mail._domainkey.sharedance.com.ar
EOF

# Configure aliases for system emails
echo "📮 Configuring email aliases..."
cat >> /etc/aliases << 'EOF'
# ShareDance aliases
postmaster: root
webmaster: root
abuse: root
noreply: root
admin: root
EOF

newaliases

# Create systemd service for better management
echo "🔧 Creating systemd service..."
systemctl enable postfix
systemctl enable opendkim

# Start services
echo "🚦 Starting mail services..."
systemctl restart opendkim
systemctl restart postfix

# Test configuration
echo "🧪 Testing mail configuration..."
echo "Mail server setup completed" | mail -s "ShareDance Mail Test" root

# Display DKIM public key for DNS configuration
echo ""
echo "==================================="
echo "📋 DKIM PUBLIC KEY FOR DNS:"
echo "==================================="
echo "Add this TXT record to your DNS:"
echo "Name: mail._domainkey.sharedance.com.ar"
echo "Value:"
cat /etc/opendkim/keys/sharedance.com.ar/mail.txt | grep -v "mail._domainkey" | tr -d '\n\t "'
echo ""
echo "==================================="
echo ""

# Show DNS recommendations
cat << 'EOF'
📋 RECOMMENDED DNS RECORDS:

1. MX Record:
   Name: sharedance.com.ar
   Value: 10 mail.sharedance.com.ar

2. A Record:
   Name: mail.sharedance.com.ar
   Value: 148.113.197.152

3. TXT Record (SPF):
   Name: sharedance.com.ar
   Value: "v=spf1 mx a:mail.sharedance.com.ar ip4:148.113.197.152 ~all"

4. TXT Record (DMARC):
   Name: _dmarc.sharedance.com.ar
   Value: "v=DMARC1; p=quarantine; rua=mailto:postmaster@sharedance.com.ar"

5. DKIM Record (shown above)

EOF

echo "✅ Mail server setup completed!"
echo "⚠️  Remember to configure DNS records before sending emails"
