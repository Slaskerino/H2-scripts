#Installer telnet på serveren.
apt install telnetd -y

#Giver telnet adgang igennem IPtables fra subnet 10.0.0.0/16 på port 23.

sudo iptables -A INPUT -p tcp --dport 23 -s 10.0.0.0/16 -j ACCEPT

#Den kommando tilføjer en linje til filen /etc/inetd.conf, som fortæller inetd-tjenesten, 
#at den skal starte en Telnet-server (/usr/sbin/telnetd) når nogen forbinder til port 23/tcp.
echo "telnet  stream  tcp     nowait  root    /usr/sbin/tcpd  /usr/sbin/telnetd" >> /etc/inetd.conf
sudo systemctl restart inetd



#######OBS nedenstående sletter din telnet forbindelse igen.#######
apt autoremove telnetd --purge