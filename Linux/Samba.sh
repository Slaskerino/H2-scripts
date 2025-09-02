#!/bin/bash


#Automatisk installation og konfiguration af Samba på Ubuntu server
#         inkl. automatisk opsætning af to brugere med specifikke passwords


# Stop scriptet ved fejl
set -e

# Variabler
SHARE_DIR="share"
SAMBASHARE_NAME="my-samba-share"
USERS=("tom" "harry")       # Brugere til Samba
USER_PASSWORDS=("Password1" "Password1")  # Corresponding passwords
READ_USER="tom"
WRITE_USER="harry"
COMMENT="My Samba Server"

# Funktion: Installer Samba
install_samba() {
    echo "Opdaterer pakke-lister og installerer Samba..."
    apt update -y
    apt install samba -y
    clear
    echo "Samba installation færdig."
}

# Funktion: Opret mappe til deling
create_share_dir() {
    echo "Opretter delingsmappe: $SHARE_DIR..."
    cd /home/
    mkdir -p "$SHARE_DIR"
    chmod 777 "$SHARE_DIR"
    echo "Delingsmappe oprettet med fuld adgang (777)."
}

# Funktion: Opret system- og Samba-brugere automatisk
create_samba_users_auto() {
    for i in "${!USERS[@]}"; do
        user="${USERS[$i]}"
        password="${USER_PASSWORDS[$i]}"

        if ! id "$user" &>/dev/null; then
            echo "Opretter systembruger $user..."
            useradd "$user" -s /sbin/nologin
        else
            echo "Bruger $user eksisterer allerede."
        fi

        echo "Opsætter Samba password for $user..."
        # Automatiseret smbpasswd uden interaktiv input
        echo -e "$password\n$password" | sudo smbpasswd -s -a "$user"
    done
}

# Funktion: Konfigurer Samba-share og NetBIOS name
configure_samba() {
    echo "Skriver Samba-konfiguration..."

    # Backup af eksisterende konfig
    if [ -f /etc/samba/smb.conf ]; then
        sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
        echo "Backup af smb.conf oprettet."
    fi

    # Tilføj eller opdater [global] sektion med netbios name
    if grep -q "^\[global\]" /etc/samba/smb.conf; then
        # Tilføj netbios name under eksisterende [global]
        sudo sed -i "/^\[global\]/a\\
   netbios name = $NETBIOS_NAME" /etc/samba/smb.conf
    else
        # Opret [global] sektion hvis den ikke findes
        sudo bash -c "cat >> /etc/samba/smb.conf <<EOL
[global]
   netbios name = $NETBIOS_NAME
EOL"
    fi

    # Tilføj share i smb.conf
    bash -c "cat >> /etc/samba/smb.conf <<EOL

[$SAMBASHARE_NAME]
   path = $SHARE_DIR
   browseable = yes
   public = no
   read list = $READ_USER
   write list = $WRITE_USER
   comment = $COMMENT
EOL"

    # Test konfiguration
    echo "Tester Samba-konfiguration..."
    testparm -s
}

# Funktion: Start og aktiver Samba-tjenester
restart_samba() {
    echo "Starter og aktiverer Samba-tjenester..."
    systemctl restart smbd nmbd
    systemctl enable smbd nmbd
    echo "Samba-tjenester er nu kørende og aktiveret ved opstart."
}

# Hovedprogram der bruger rækkefølgen af alle ovennævnte funktions.
install_samba
create_share_dir
create_samba_users_auto
configure_samba
restart_samba

echo "Samba installation og konfiguration færdig!"
echo "Share tilgængelig på: //$HOSTNAME/$SAMBASHARE_NAME"
echo "Samba-brugere og passwords:"
for i in "${!USERS[@]}"; do
    echo "  ${USERS[$i]} : ${USER_PASSWORDS[$i]}"
done