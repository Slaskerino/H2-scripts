#!/bin/bash
#Opdaterer og opgraderer de pakker som er installeret på systemet.
apt update && apt upgrade

#Installerer pakken SSH.
apt install openssh-server openssh-client

#Giver SSH adgang igennem IPtables fra subnet 10.0.0.0/16 på port 22.

sudo iptables -A INPUT -p tcp --dport 22 -s 10.0.0.0/16 -j ACCEPT