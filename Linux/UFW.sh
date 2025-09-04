#!/bin/bash

# Stop scriptet ved fejl
set -e

echo "=== Tjekker status for UFW ==="

# Tjek om UFW er installeret
if ! command -v ufw &> /dev/null; then
    echo "UFW er ikke installeret. Installerer UFW..."
    sudo apt update -y
    sudo apt install ufw -y
fi

#OBS# Vær opmærksom på at du ikke kan etablere forbindelse via SSH eller Telnet, 
#hvis du aktiverer UFW uden at have allowed SSH eller telnet.

# Tjek om UFW er aktiv, hvis den ikke er aktiv, bliver den aktiveret.
STATUS=$(sudo ufw status | grep -i "Status:" | awk '{print $2}')

if [ "$STATUS" == "active" ]; then
    echo "UFW er allerede aktiv."
else
    echo "UFW er ikke aktiv. Aktiverer nu..."
    sudo ufw --force enable
    echo "UFW er nu aktiveret."
fi

# Vis status
echo "=== Aktuel UFW status ==="
sudo ufw status verbose