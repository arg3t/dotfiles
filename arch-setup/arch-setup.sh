#!/bin/bash

# Disk setup
echo -n "What is the install device: "
read device
echo "Installing to $device... (Enter to continue)"
read _

# Disk wipe
echo "[INFO]: Wiping disk"
cryptsetup open -q --type plain -d /dev/urandom $device wipe
dd if=/dev/zero of=/dev/mapper/wipe status=progress
cryptsetup -q close wipe
wipefs -a -f $device

# Run cfdisk for manual partitioning
cfdisk $device

# Create the boot partition
echo "[INFO]: Formatting boot partition"
mkfs.fat -F32 "$device"1

# Create the swap partition
echo "[INFO]: Enter password for swap encryption"
read swap_pass

echo $swap_pass | cryptsetup -q luksFormat "$device"2
mkdir /root/.keys
dd if=/dev/urandom of=/root/.keys/swap-keyfile bs=1024 count=4
chmod 600 /root/.keys/swap-keyfile
echo $swap_pass | cryptsetup luksAddKey "$device"2 /root/.keys/swap-keyfile
echo "[INFO]: Keyfile saved to /root/.keys/swap-keyfile"
cryptsetup open --key-file="/root/.keys/swap-keyfile" "$device"2 swap
mkswap /dev/mapper/swap
swapon /dev/mapper/swap

# Create the root partition
echo "[INFO]: Enter password for root encryption"
read root_pass

echo $root_pass | cryptsetup -q luksFormat "$device"3
dd bs=512 count=4 if=/dev/random of=/root/.keys/root-keyfile iflag=fullblock
chmod 600 /root/.keys/root-keyfile
echo $root_pass | cryptsetup luksAddKey "$device"3 /root/.keys/root-keyfile
echo "[INFO]: Keyfile saved to /root/.keys/root-keyfile"
cryptsetup open --key-file="/root/.keys/root-keyfile" "$device"3 root
mkfs.ext4 /dev/mapper/root
mkdir /mnt/sys
mount /dev/mapper/root /mnt/sys
mkdir /mnt/sys/boot
mount "$device"1 /mnt/sys/boot

pacstrap /mnt/sys base linux linux-firmware base-devel git nano
genfstab -U /mnt/sys >> /mnt/sys/etc/fstab

# Run on chrooted arch install
mkdir /mnt/sys/install
cp -r /root/.keys /mnt/sys/root
curl https://raw.githubusercontent.com/theFr1nge/dotfiles/main/arch-setup/AUR.txt > /mnt/sys/install/AUR.txt
curl https://raw.githubusercontent.com/theFr1nge/dotfiles/main/arch-setup/nonAUR.txt > /mnt/sys/install/nonAUR.txt
curl https://raw.githubusercontent.com/theFr1nge/dotfiles/main/arch-setup/chroot.sh > /mnt/sys/install/chroot.sh
chmod +x /mnt/sys/install/chroot.sh
echo -n "$device" > /mnt/sys/install/device
arch-chroot /mnt/sys /install/chroot.sh
