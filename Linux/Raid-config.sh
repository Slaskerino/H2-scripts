#!/bin/bash

# Opretter RAID 5 på 3 nye diske  for Ubuntu

set -e

# Definer hvilke diske der skal bruges
DISKS=("/dev/sdb" "/dev/sdc" "/dev/sdd")
RAID_DEVICE="/dev/md0"
MOUNT_POINT="/mnt/raid5"
FS_LABEL="RAID5DATA"

echo "==> Sikre at alle diske er til stede..."
MISSING=0
for DISK in "${DISKS[@]}"; do
    if [ ! -b "$DISK" ]; then
        echo "Mangler: $DISK"
        MISSING=1
    else
        echo "Fundet: $DISK"
    fi
done

if [ "$MISSING" -ne 0 ]; then
    echo "Der mangler en eller flere diske. stopper scriptet!"
    exit 1
fi

# Hvis tilgængelige diske og få brugers accept
echo
echo "Følgende diske vil blive brugt til at oprette vores RAID 5 array:"
for DISK in "${DISKS[@]}"; do
    echo " - $DISK"
done
echo
read -p "Er de listede diske korrekte? Tast 'ja' for at bekræfte" CONFIRM

if [[ "$CONFIRM" != "ja" ]]; then
    echo "Stopper script..."
    exit 1
fi

echo "Fortsætter RAID konfiguration"

echo "==> Installere mdadm..."
sudo apt update
sudo apt install -y mdadm

echo "==> Opretter partitioner på diske..."
for DISK in "${DISKS[@]}"; do
    echo "Partition $DISK..."
    sudo parted -s "$DISK" mklabel gpt
    sudo parted -s "$DISK" mkpart primary 0% 100%
done

# Giver kernelen en chance for at fange de nye partitioner
echo "Venter på kernel i 5 sekunder. Fortsætter om:"

sleep_count=5 
while [ $sleep_count -gt 0 ]; do
  echo "$sleep_count"
  sleep 1
  ((sleep_count--))
done


echo "==> Creating RAID 5 array..."
sudo mdadm --create --verbose "$RAID_DEVICE" --level=5 --raid-devices=3 \
    ${DISKS[0]}1 ${DISKS[1]}1 ${DISKS[2]}1

# Vent på at RAID init er startet helt op
echo "Venter på RAID init i 10 sekunder. Fortsætter om:"

sleep_count=10 
while [ $sleep_count -gt 0 ]; do
  echo "$sleep_count"
  sleep 1
  ((sleep_count--))
done

echo "==> Gemmer mdadm konfig..."
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf > /dev/null
sudo update-initramfs -u

echo "==> Opretter filsystem..."
sudo mkfs.ext4 -L "$FS_LABEL" "$RAID_DEVICE"

echo "==> Opretter mount point..."
sudo mkdir -p "$MOUNT_POINT"

echo "==> Mounter RAID array..."
echo "LABEL=$FS_LABEL $MOUNT_POINT ext4 defaults,nofail 0 0" | sudo tee -a /etc/fstab
sudo mount -a

echo "Raid er konfigureret på serveren og mounted på $MOUNT_POINT"
