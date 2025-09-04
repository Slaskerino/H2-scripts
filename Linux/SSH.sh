#!/bin/bash
#Opdaterer og opgraderer de pakker som er installeret på systemet.
apt update && sudo apt upgrade

#Installerer pakken SSH.
apt install openssh-server openssh-client
apt install -y ufw

#Aktiver SSH gennem port 22 ELLER giver SSH adgang igennem UFW igennem en subnet og port 22.
#Dette gøres så vi ikke mister forbindelsen når UFW aktiveres.
ufw allow ssh
ufw allow from 10.0.0.0/8 to any port 22
