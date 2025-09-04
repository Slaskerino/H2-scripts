#Installer telnet på serveren.
apt install telnetd -y

#Aktiver telnet og giver den adgang igennem UFW igennem en subnet og port 23.
ufw allow from 10.0.0.0/8 to any port 23

#Aktiverer ufw. OBS vær opmærksom på at det hele er opsat da, SSH adgang kan forsvinde hvis ikke opsat korrekt.
ufw enable

#Den kommando tilføjer en linje til filen /etc/inetd.conf, som fortæller inetd-tjenesten, 
#at den skal starte en Telnet-server (/usr/sbin/telnetd) når nogen forbinder til port 23/tcp.
echo "telnet  stream  tcp     nowait  root    /usr/sbin/tcpd  /usr/sbin/telnetd" >> /etc/inetd.conf
sudo systemctl restart inetd

#######OBS nedenstående sletter din telnet forbindelse igen.#######
apt autoremove telnetd --purge