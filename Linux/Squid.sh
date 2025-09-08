#!/bin/bash
# Script til at installere og konfigurere Squid Proxy på Ubuntu/Debian
# inkl. firewall regler

set -e

# === Variabler ===
SQUID_CONF="/etc/squid/squid.conf"
SQUID_BACKUP="/etc/squid/squid.conf.factory"
SQUID_DENY="/etc/squid/deniedsites.squid"
LISTEN_IP="192.168.2.11"
LISTEN_PORT="3269"
LAN_NET="192.168.2.0/24"
CACHE_MEM="256 MB"
DNS_SERVER="8.8.8.8"

echo "[INFO] Installerer Squid..."
apt -y install squid

echo "[INFO] Tager backup af standard konfiguration..."
cp -v "$SQUID_CONF" "$SQUID_BACKUP"

echo "[INFO] Skriver ny konfiguration..."
cat > "$SQUID_CONF" <<EOF
# Squid Proxy server konfiguration

# Lyt på specifik IP og port
http_port $LISTEN_IP:$LISTEN_PORT

# Definer netværk der må bruge proxy
acl mylan src $LAN_NET
http_access allow mylan

# Blokerede domæner (defineres i ekstern fil)
acl deniedsites dstdomain "$SQUID_DENY"
http_access deny deniedsites

# Tillad lokal maskine
http_access allow localhost

# Afvis alt andet
http_access deny all

# Cache settings
cache_mem $CACHE_MEM

# DNS server
dns_nameservers $DNS_SERVER

# Logs
access_log /var/log/squid/access.log
EOF

echo "[INFO] Tilføjer test-domæner til deny liste..."
cat > "$SQUID_DENY" <<EOF
.facebook.com
.youtube.com
EOF

echo "[INFO] Tester konfiguration..."
/usr/sbin/squid -k parse

echo "[INFO] Aktiverer og starter Squid..."
systemctl enable squid
systemctl restart squid

echo "[INFO] Tilføjer firewall regler..."

if command -v ufw >/dev/null 2>&1; then
    echo "[INFO] UFW fundet – åbner port $LISTEN_PORT"
    ufw allow "$LISTEN_PORT/tcp"
else
    echo "[INFO] UFW ikke fundet – bruger iptables i stedet"
    iptables -A INPUT -p tcp --dport "$LISTEN_PORT" -j ACCEPT
    # Gemmer regler, hvis iptables-persistent findes
    if command -v netfilter-persistent >/dev/null 2>&1; then
        netfilter-persistent save
    fi
fi

echo "[INFO] Squid er installeret, kører og er åbnet i firewall."
systemctl status squid --no-pager
