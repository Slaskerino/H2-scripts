#!/bin/bash

#Vi starter med at installere Samba pakken på vores server.
apt install samba -y

#Først laver vi en mappe som vi deler. Denne mappe får read&write(777) for alle brugere.
cd /home/
mkdir -p share
chmod 777 share

#Nederst laver vi en tee for at indtaste alt nedenstående data på samme tid inkl. linjeskift i filen smb.conf.
tee -a /etc/samba/smb.conf > /dev/null <<EOT
[my-samba-share] {
            Path = /share;
            Public = no;
            valid users = tom, harry;
            read list = tom;
            write list = harry;
            browseable = yes;
            comment “my samba server”;
}
EOT