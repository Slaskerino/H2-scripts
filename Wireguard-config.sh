#!/bin/bash

set -e

# ======= CONFIGURATION =======
WG_INTERFACE="wg0"
WG_PRIVATE_KEY_PATH="/etc/wireguard/private.key"  # Change if you store it elsewhere
WG_PORT=51820

# Your local WireGuard tunnel IP
WG_LOCAL_IP="10.0.0.4/24"

# GCP Endpoint Public IP and Public Key
GCP_PUBLIC_IP="34.51.169.227"        # Replace with real IP
GCP_PUBLIC_KEY="bRMyHN0/F3k5GbWzy2qxzgMQfklNA4udKW98BmzMCFU="  # Replace with real key

# Physical interface connected to the internet
PHYS_IFACE=$(ip route | grep default | awk '{print $5}')

# ======= INSTALL DEPENDENCIES =======
echo "[+] Installing WireGuard and iptables..."
apt update
apt install -y wireguard iptables

# ======= ENABLE IPV4 FORWARDING =======
echo "[+] Enabling IPv4 forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# ======= GENERATE WG KEYS (if missing) =======
if [ ! -f "$WG_PRIVATE_KEY_PATH" ]; then
    echo "[+] Generating WireGuard keys..."
    umask 077
    wg genkey | tee "$WG_PRIVATE_KEY_PATH" | wg pubkey > "${WG_PRIVATE_KEY_PATH}.pub"
fi

WG_PRIVATE_KEY=$(cat "$WG_PRIVATE_KEY_PATH")

# ======= CREATE WG CONFIG =======
WG_CONFIG_PATH="/etc/wireguard/${WG_INTERFACE}.conf"

echo "[+] Creating WireGuard config at $WG_CONFIG_PATH..."
cat > "$WG_CONFIG_PATH" <<EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_LOCAL_IP
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -A FORWARD -o $WG_INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o $WG_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -D FORWARD -o $WG_INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o $WG_INTERFACE -j MASQUERADE

[Peer]
PublicKey = $GCP_PUBLIC_KEY
Endpoint = $GCP_PUBLIC_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

chmod 600 "$WG_CONFIG_PATH"

# ======= START AND ENABLE WG =======
echo "[+] Starting WireGuard interface..."
wg-quick down $WG_INTERFACE 2>/dev/null || true
wg-quick up $WG_INTERFACE

systemctl enable wg-quick@$WG_INTERFACE

# ======= FIREWALL CONFIGURATION =======
echo "[+] Configuring firewall rules..."

# Allow traffic to/from WireGuard interface
iptables -A INPUT -i $WG_INTERFACE -j ACCEPT
iptables -A OUTPUT -o $WG_INTERFACE -j ACCEPT

# Allow incoming WG traffic on the public interface
iptables -A INPUT -i $PHYS_IFACE -p udp --dport $WG_PORT -j ACCEPT

# Allow forwarded traffic
iptables -A FORWARD -i $PHYS_IFACE -o $WG_INTERFACE -j ACCEPT
iptables -A FORWARD -i $WG_INTERFACE -o $PHYS_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

# ======= DONE =======
echo "[✓] WireGuard relay configured on $WG_INTERFACE."


