#!/bin/bash

#Installering af DHCP service.
apt-get install isc-dhcp-server -y

#Start og enable servicen dhcpp.
systemctl start isc-dhcp-server
systemctl enable isc-dhcp-server

#Konfigurer selve DHCP servicen.
# Filen vi vil ændre
FILE="/etc/default/isc-dhcp-server"
# Brug sed til at ændre INTERFACESv4=""
sed -i 's/^INTERFACESv4=".*"/INTERFACESv4="enp6s19"/' "$FILE"


#Nederst laver vi en tee for at indtaste alt nedenstående data på samme tid inkl. linjeskift i filen dhcp.conf.
tee -a /etc/dhcp/dhcpd.conf > /dev/null <<EOT
subnet 192.168.1.0 netmask 255.255.255.0 {
range 192.168.1.50 192.168.1.100;
option domain-name-servers 8.8.8.8;
option subnet-mask 255.255.255.0;
option routers 192.168.1.1;
}
EOT

#Genstarter servicen for DHCP.
systemctl restart isc-dhcp-server