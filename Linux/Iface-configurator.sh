#!/bin/bash

set -e
declare -A INTERFACE_IPS


echo "==> Multi Iface opdator (Netplan)"

# Find alle ikke-loopback interfaces
AVAILABLE_INTERFACES=($(ls /sys/class/net | grep -v lo))



if [ "${#AVAILABLE_INTERFACES[@]}" -eq 0 ]; then
    echo "Ingen interfaces blev fundet. stopper script"
    exit 1
fi

# Lokaliser netplan konfig fil
NETPLAN_FILE=$(find /etc/netplan -name "*.yaml" | head -n 1)

if [ -z "$NETPLAN_FILE" ]; then
    echo "Ingen Netplan-fil blev fundet. Opretter en ny under /etc/netplan/00-config.yaml..."
    NETPLAN_FILE="/etc/netplan/00-config.yaml"
    sudo touch "$NETPLAN_FILE"
fi

NETPLAN_BACKUP_FILE="${NETPLAN_FILE}.bak.$(date +%F-%T)"

echo "==> Backup af eksisterende Netplan konfig: $NETPLAN_FILE"
sudo cp "$NETPLAN_FILE" "$NETPLAN_BACKUP_FILE"

CONFIG=$(cat <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
EOF
)

USED_INTERFACES=()

while true; do
    echo
    echo "Tilgængelige interfaces:"
    for i in "${!AVAILABLE_INTERFACES[@]}"; do
        IFACE_NAME="${AVAILABLE_INTERFACES[$i]}"
        CONFIGURED=false
        for used in "${USED_INTERFACES[@]}"; do
            if [[ "$used" == "$IFACE_NAME" ]]; then
                CONFIGURED=true
                break
            fi
        done

        if $CONFIGURED; then
            IP="${INTERFACE_IPS[$IFACE_NAME]}"
            echo "$((i+1)). $IFACE_NAME - Konfigureret - IP: ($IP)"
        else
            IP=$(ip -4 addr show "$IFACE_NAME" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' || true)
            echo "$((i+1)). $IFACE_NAME - Ikke konfigureret - IP: ($IP)"
        fi
    done


    if [ "${#USED_INTERFACES[@]}" -eq 0 ]; then
        read -p "Vælg et interface ud fra nummer eller tryk ENTER for at forlade scriptet: " CHOICE
    else
        read -p "Vælg et andet interface, eller tryk ENTER for at afslutte konfigurationen: " CHOICE
    fi


    if [[ -z "$CHOICE" ]]; then
        break
    fi

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#AVAILABLE_INTERFACES[@]} )); then
        echo "Forkert data, prøv igen."
        continue
    fi

    IFACE="${AVAILABLE_INTERFACES[$((CHOICE-1))]}"



    # Undgå at konfigurere det samme interface 2 gange
    if [[ " ${USED_INTERFACES[*]} " == *" $IFACE "* ]]; then
        echo "Interface $IFACE har allerede en konfiguration. Den kan opdateres manuelt under $NETPLAN_FILE. Vælg et andet interface eller forlad scriptet og køre det igen."
        continue
    fi

    USED_INTERFACES+=("$IFACE")
    INTERFACE_IPS["$IFACE"]="(ukendt)"


    read -p "Brug DHCP på $IFACE? (ja/nej): " USE_DHCP
    if [[ "$USE_DHCP" =~ ^[Jj] ]]; then
        INTERFACE_IPS["$IFACE"]="DHCP"
        CONFIG+="
    $IFACE:
      dhcp4: true"
    else
        read -p "Indtast en statisk IP for $IFACE, efterfuldt af prefix. (f.eks: 192.168.2.50/24): " STATIC_IP
        read -p "Indtast gateway for $IFACE (Eller efterlad den tom for ingen): " GATEWAY
        read -p "Indtast DNS servere opdelt med kommaer (8.8.8.8, 9.9.9.9): " DNS
        INTERFACE_IPS["$IFACE"]="$STATIC_IP"
        CONFIG+="
    $IFACE:
      dhcp4: no
      addresses:
        - $STATIC_IP"

        if [[ -n "$GATEWAY" ]]; then
            CONFIG+="
      routes:
        -   to: default
            via: $GATEWAY"
        fi

        if [[ -n "$DNS" ]]; then
            CONFIG+="
      nameservers:
        addresses: [${DNS//,/ }]"
        fi
    fi
done

# Hvis der ikke er valgt et interface
if [ "${#USED_INTERFACES[@]}" -eq 0 ]; then
    echo "Ingen interfaces valgt. Forlader script."
    exit 1
fi

# Skriv ny config til fil
echo "==> Skriver ny konfiguraqtion til $NETPLAN_FILE..."
echo "$CONFIG" | sudo tee "$NETPLAN_FILE" > /dev/null

# commit konfigurationen til netplan
echo
read -p "Vil du tilføje konfigurationen nu? (ja/nej): " APPLY_NOW
if [[ "$APPLY_NOW" =~ ^[Jj] ]]; then
    echo "==> Tilføjer ny netplan konfig..."
    sudo netplan apply
    echo "Netplan konfiguration tilføjet."
else
    echo "Netplan konfiguration blev ikke tilføjet. Brug 'sudo netplan apply' for manuelt at tilføje ændringerne."
    exit 1
fi

read -p "Vil du slette backup filen af netplanen? (ja/nej): " RM_BACKUP
if [[ "$RM_BACKUP" =~ ^[Jj] ]]; then
    echo "Sletter backup af netplanen"
    sudo rm "$NETPLAN_BACKUP_FILE"
else
    echo "Beholder backup"
    exit 1
fi