#!/bin/bash

# Opretter RAID 5 på 3 nye diske  for Ubuntu

set -e

# Definer hvilke diske der skal bruges
DISKS=("/dev/sdb" "/dev/sdc" "/dev/sdd") # Skal ændres alt efter hvilke diske der er tilgængelige
RAID_DEVICE="/dev/md0"
MOUNT_POINT="/mnt/raid5"
FS_LABEL="RAID5DATA"

# Looper igennem diskene for at tjekke om de diske vi har defineret i DISKS variablen er tilstede.

echo "==> Sikrer at alle diske er til stede..."
MISSING=0
for DISK in "${DISKS[@]}"; do
    if [ ! -b "$DISK" ]; then
        echo "Mangler: $DISK"
        MISSING=1
    else
        echo "Fundet: $DISK"
    fi
done

# stopper script hvis der mangler en eller flere diske

if [ "$MISSING" -ne 0 ]; then
    echo "Der mangler en eller flere diske. stopper scriptet!"
    exit 1
fi

# Vis tilgængelige diske på systemet og få brugers accept til at fortsætte
echo
echo "Følgende diske vil blive brugt til at oprette vores RAID 5 array:"
for DISK in "${DISKS[@]}"; do
    echo " - $DISK"
done
echo
read -p "Er de listede diske korrekte? Tast 'ja' for at bekræfte: " CONFIRM

if [[ "$CONFIRM" != "ja" ]]; then
    echo "Stopper script..."
    exit 1
fi

echo "Fortsætter RAID konfiguration"

# Dowmloader og installere mdadm

echo "==> Installere mdadm..."
sudo apt update
sudo apt install -y mdadm

# Opretter GPT partitioner på diskene

echo "==> Opretter partitioner på diske..."
for DISK in "${DISKS[@]}"; do
    echo "Partition $DISK..."
    sudo parted -s "$DISK" mklabel gpt
    sudo parted -s "$DISK" mkpart primary 0% 100%
done

# Giver kernelen en chance for at fange de nye partitioner
echo "Venter på kernel i 5 sekunder. Fortsætter om:"

# En lille nedtælling så man kan se hvornår scriptet fortsætter og at det stadig kører.

sleep_count=5 
while [ $sleep_count -gt 0 ]; do
  echo "$sleep_count"
  sleep 1
  ((sleep_count--))
done

# Opretter et RAID5 array på de 3 diske vi har defineret

echo "==> Opretter RAID 5 array på diske..."
sudo mdadm --create --verbose "$RAID_DEVICE" --level=5 --raid-devices=3 \
    ${DISKS[0]}1 ${DISKS[1]}1 ${DISKS[2]}1

# Vent på at RAID init er startet helt op
echo "Venter på RAID init i 10 sekunder. Fortsætter om:"

# Samme nedtælling som tidligere, bare på 10 sekunder

sleep_count=10 
while [ $sleep_count -gt 0 ]; do
  echo "$sleep_count"
  sleep 1
  ((sleep_count--))
done

# Skriver konfiguration til mdadm.conf så det er persistant gennem en genstart

echo "==> Gemmer mdadm konfig..."
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf > /dev/null
sudo update-initramfs -u

# Opretter ext4 filsystem på vores nye RAID device

echo "==> Opretter filsystem..."
sudo mkfs.ext4 -L "$FS_LABEL" "$RAID_DEVICE"

# Opretter mount point

echo "==> Opretter mount point..."
sudo mkdir -p "$MOUNT_POINT"

# Opdaterer /etc/fstab så vores mount point er persistant gennem en genstart 
# samt hiver det nye data vi lige har skrevet til fstab med sudo mount -a

echo "==> Mounter RAID array..."
echo "LABEL=$FS_LABEL $MOUNT_POINT ext4 defaults,nofail 0 0" | sudo tee -a /etc/fstab
sudo mount -a

echo "Raid er konfigureret på serveren og mounted på $MOUNT_POINT"
