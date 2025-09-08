#!/bin/bash
# Setup Squid Proxy på 192.168.1.11

# Stop script ved fejl
set -e

# Opdater system og installer Squid
apt update && apt install -y squid

# Backup original konfiguration
cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Opret blacklist-fil
cat <<EOF >/etc/squid/blacklist.acl
.dr.dk
.facebook.com
.youtube.com
EOF

# Skriv ny squid.conf
cat <<EOF >/etc/squid/squid.conf
# Squid proxy config
http_port 192.168.1.1:3269

# Adgangskontrol
acl localnet src 192.168.1.0/24
acl blacklist dstdomain "/etc/squid/blacklist.acl"

http_access deny blacklist
http_access allow localnet
http_access allow localhost
http_access deny all
dns_nameservers 8.8.8.8

# Logging
access_log /var/log/squid/access.log
EOF

# Sørg for korrekte rettigheder
chown proxy:proxy /etc/squid/blacklist.acl
chmod 644 /etc/squid/blacklist.acl

# Genstart og enable service
systemctl restart squid
systemctl enable squid

echo "✅ Squid proxy er sat op på 192.168.1.11:3128"
