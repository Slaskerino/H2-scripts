#!/bin/bash
# Aktiver Samba porte i iptables
# Tillader både TCP og UDP (137-139, 445)

# Ændr dette netværk, hvis du kun vil tillade fra dit LAN
ALLOWED_NET="0.0.0.0/0"   # Alle (skift fx til 192.168.1.0/24)

echo "[+] Tilføjer iptables regler for Samba..."

# TCP porte
iptables -A INPUT -p tcp -s $ALLOWED_NET --dport 139 -j ACCEPT
iptables -A INPUT -p tcp -s $ALLOWED_NET --dport 445 -j ACCEPT

# UDP porte
iptables -A INPUT -p udp -s $ALLOWED_NET --dport 137 -j ACCEPT
iptables -A INPUT -p udp -s $ALLOWED_NET --dport 138 -j ACCEPT

echo "[+] Regler tilføjet."

# Gem reglerne (Ubuntu/Debian)
if command -v netfilter-persistent &>/dev/null; then
    echo "[+] Gemmer regler med netfilter-persistent..."
    netfilter-persistent save
elif [ -d /etc/iptables ]; then
    echo "[+] Gemmer regler i /etc/iptables/rules.v4..."
    iptables-save > /etc/iptables/rules.v4
else
    echo "[!] Husk at gemme reglerne manuelt med: iptables-save > /etc/iptables/rules.v4"
fi

echo "[+] Samba er nu åbnet i firewall."