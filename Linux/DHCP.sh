#!/bin/bash

#Installering af DHCP service.
echo "Installerer DHCP servicen..."
apt-get install isc-dhcp-server -y

#Start og enable servicen dhcpp.
echo "Starter og enabler DHCP servicen."
systemctl start isc-dhcp-server
systemctl enable isc-dhcp-server

#Her konfigurer vi selve DHCP servicen.
echo "Den rigtige interface vælges til servicen."
#Vi vil ændre selve Filen.
FILE="/etc/default/isc-dhcp-server"
# Brug sed til at ændre INTERFACESv4=""
sed -i 's/^INTERFACESv4=".*"/INTERFACESv4="enp6s19"/' "$FILE"


#Nederst laver vi en tee for at indtaste alt nedenstående data på samme tid inkl. linjeskift i filen dhcp.conf.
echo "DHCP config filen bliver configureret."
tee -a /etc/dhcp/dhcpd.conf > /dev/null <<EOT
subnet 192.168.2.0 netmask 255.255.255.0 {
range 192.168.2.50 192.168.2.100;
option domain-name-servers 8.8.8.8;
option subnet-mask 255.255.255.0;
option routers 192.168.2.1;
}
EOT

#Genstarter servicen for DHCP.
echo "DHCP servicen genstarter"
systemctl restart isc-dhcp-server
echo "DHCP servicen er nu oppe og køre. God fornøjelse!"