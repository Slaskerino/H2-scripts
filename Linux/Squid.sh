#!/bin/bash
# Setup Squid Proxy på 192.168.2.1

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
http_port 192.168.2.1:3269

# Adgangskontrol
acl localnet src 192.168.2.0/24
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

#Åbner adgang i firewall til porten.
# Tillad indgående TCP trafik på port 3269
sudo iptables -A INPUT -p tcp --dport 3269 -j ACCEPT

# Gem reglerne permanent (på Ubuntu/Debian)
sudo apt install -y iptables-persistent
sudo netfilter-persistent save


echo "En solid Squid proxy er sat op på 192.168.2.1:3269"
