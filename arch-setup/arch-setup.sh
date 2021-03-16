#!/bin/bash

# Disk setup
echo -n "What is the install device: "
read device
echo "Installing to $device... (Enter to continue)"
read _

# Disk wipe
echo "[INFO]: Wiping disk"
cryptsetup open --type plain -d /dev/urandom $device wipe
dd if=/dev/zero of=/dev/mapper/wipe status=progress
cryptsetup close wipe
wipefs -a -f $device

# Run cfdisk for manual partitioning
cfdisk $device

# Create the boot partition
echo "[INFO]: Formatting boot partition"
mkfs.fat -F32 "$device"1

# Create the swap partition
echo "[INFO]: Enter password for swap encryption"
cryptsetup luksFormat "$device"2
mkdir /root/.keys
sudo dd if=/dev/urandom of=/root/.keys/swap-keyfile bs=1024 count=4
sudo chmod 600 /root/.keys/swap-keyfile
echo "[INFO]: Re-Enter password for swap encryption"
sudo cryptsetup luksAddKey "$device"2 /root/.keys/swap-keyfile
echo "[INFO]: Keyfile saved to /root/.keys/swap-keyfile"
cryptsetup open --key-file="/root/.keys/swap-keyfile" "$device"2 swap
mkswap /dev/mapper/swap
swapon /dev/mapper/swap

# Create the root partition
echo "[INFO]: Enter password for root encryption"
cryptsetup luksFormat "$device"3
dd bs=512 count=4 if=/dev/random of=/root/.keys/root-keyfile iflag=fullblock
sudo chmod 600 /root/.keys/root-keyfile
echo "[INFO]: Re-Enter password for root encryption"
sudo cryptsetup luksAddKey "$device"3 /root/.keys/root-keyfile
echo "[INFO]: Keyfile saved to /root/.keys/root-keyfile"
cryptsetup open --key-file="/root/.keys/root-keyfile" "$device"3 root
mkfs.ext4 /dev/mapper/root
mkdir /mnt/sys
mount /dev/mapper/root /mnt/sys
mkdir /mnt/sys/boot
mount "$device"1 /mnt/sys/boot

pacstrap /mnt/sys base linux linux-firmware base-devel git vim
genfstab -U /mnt/sys >> /mnt/sys/etc/fstab

# Run on chrooted arch install
cp -r ./chroot /mnt/sys/install
cp -r /root/.keys /mnt/sys/root
echo -n "$device" > /mnt/sys/install/device
arch-chroot /mnt/sys /install/install.sh
