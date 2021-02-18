#!/bin/bash

# Disk setup
echo -n "What is the install device: "
read $device
echo "Installing to $device... (Enter to continue)"
read $_

# Disk wipe
echo "[INFO]: Wiping disk"
cryptsetup open --type plain -d /dev/urandom $device wipe
dd if=/dev/zero of=/dev/mapper/wipe status=progress
cryptsetup close wipe

# Cleaning device from previous LUKS setups
cryptsetup erase $device
wipefs -a device

# Set partition table
parted $device mklabel gpt

# Create the boot partition
echo "[INFO]: Creating boot partition"
parted -a optimal $device mkpart 1 primary 0% 512MB
mkfs.fat -F32 "$device"1

echo -n "Enter swap size + 512MB: "
read $swap_size
echo "Installing to $swap_size... (Enter to continue)"
read $_

# Create the swap partition
echo "[INFO]: Creating swap partition"
parted -a optimal $device mkpart 2 primary 512MB $swap_size
echo "[INFO]: Enter password for swap encryption"
cryptsetup luksFormat "$device"2
sudo dd if=/dev/urandom of=/root/.keys/swap-keyfile bs=1024 count=4
sudo chmod 600 /root/.keys/swap-keyfile
echo "[INFO]: Re-Enter password for swap encryption"
sudo cryptsetup luksAddKey "$device"2 /root/.keys/swap-keyfile
echo "[INFO]: Keyfile saved to /root/.keys/swap-keyfile"
cryptsetup open --key-file="/root/.keys/swap-keyfile" "$device"2 swap
mkswap /dev/mapper/swap
swapon /dev/mapper/swap

# Create the root partition
echo "[INFO]: Creating root partition"
parted -a optimal $device mkpart 3 primary $swap_size 100%
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
mount "$device"1 /mnt/sys
mkdir /mnt/sys/boot
mount "$device"1 /mnt/sys/boot

pacstrap /mnt/sys base linux linux-firmware base-devel git vim
genfstab -U /mnt/sys >> /mnt/sys/etc/fstab

# Run on chrooted arch install
cp -r ./chroot /mnt/sys/install
cp -r /root/.keys /mnt/sys/root
echo -n "$device" > /mnt/sys/install/device
arch-chroot /mnt/sys /install/install.sh
