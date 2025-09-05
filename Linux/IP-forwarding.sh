#!/bin/bash

#Her tjekker den om der er blevet aktiveret ip forwarding i sysctl.conf filen, hvis den ikke er der skriver den det ind.
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

#Aktiver ændringen.
echo "Aktiverer ændringen."
sysctl -p

#Installation af IP tables.
echo "Installerer IP-tables"
apt install iptables-persistent -y


#Her konfigureres package forwaring fra LAN til WAN.
echo "Sætter iptables regler op..."
iptables -A FORWARD -i enp6s19 -o enp6s18 -j ACCEPT
iptables -A FORWARD -i enp6s18 -o enp6s19 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -o enp6s18 -j MASQUERADE


# Gem reglerne
echo "Gemmer regler permanent..."
iptables-save > /etc/iptables/rules.v4