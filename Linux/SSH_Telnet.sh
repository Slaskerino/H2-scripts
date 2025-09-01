#!/bin/bash
apt update && sudo apt upgrade
apt install openssh-server openssh-client

#Aktiver SSH genne port 22 ELLER giver SSH adgang igennem UFW igennem en subnet og port 22.
ufw allow ssh
ufw allow from 10.0.0.0/8 to any port 22

#Installer telnet på serveren.
apt install telnetd -y
apt install -y ufw

#Aktiver telnet og giver den adgang igennem UFW igennem en subnet og port 23.
ufw allow from 10.0.0.0/8 to any port 23

#Aktiverer ufw. OBS vær opmærksom på at det hele er opsat da, SSH adgang kan forsvinde hvis ikke opsat korrekt.
ufw enable

echo "telnet  stream  tcp     nowait  root    /usr/sbin/tcpd  /usr/sbin/telnetd" >> /etc/inetd.conf

#OBS nedenstående sletter din telnet forbindelse igen.
apt autoremove telnetd --purge