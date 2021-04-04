#!/bin/bash

# Learn distro
echo -n "Is this an arch or artix installation?(1: Arch, 2: Artix): "
read distro

# Disk setup
echo -n "What is the install device: "
read device
echo "Installing to $device... (Enter to continue)"
read _

echo -n "Would you like to wipe and re-partition the disk $device?(Y/n): "
read wipe

if [ ! "$wipe" = "n" ]; then
    # Disk wipe
    echo -n "Should I do a secure wipe?(y/N): "
    read secure
    if [ "$secure" = "y" ]; then
        echo "[INFO]: Writing random data to disk, this might take a while if you have a large drive..."
        cryptsetup open -q --type plain -d /dev/urandom $device wipe
        dd if=/dev/zero of=/dev/mapper/wipe status=progress
        cryptsetup -q close wipe
    fi
    echo "[INFO]: Wiping the partition table..."
    wipefs -a -f $device
    sleep 1
fi

clear
# Run cfdisk for manual partitioning
cfdisk $device
[ ! $(command -v partprobe) = "" ] && partprobe

lsblk $device
echo -n "Are you satisfied with your partitions?(Y/n): "
read satisfied

while [ "$satisfied" = "n" ]; do
    cfdisk $device
    [ ! $(command -v partprobe) = "" ] && partprobe
    lsblk $device
    echo -n "Are you satisfied with your partitions?(Y/n): "
    read satisfied
done
clear


lsblk $device
echo ""
echo "Now you will specify the partitions you have created"
echo "Please enter the suffix for each partition. For Ex:"
echo "1 if boot partition is /dev/sda1 or p1 if boot is on /dev/nvme0n1p1 and the disk is /dev/nvme0n1"
echo -n "Please enter boot partition suffix: "
read boot_p
boot=$device$boot_p
echo -n "Please enter root partition suffix: "
read root_p
root=$device$root_p
echo -n "Please enter swap partition suffix: "
read swap_p
swap=$device$swap_p
echo -n "Did you create a home partition as well?(y/N): "
read home_s
if [ "$home_s" = "y" ]; then
    echo -n "Please enter home partition suffix: "
    read home_p
    home=$device$home_p
fi

clear

# Create the boot partition
echo "[INFO]: Formatting boot partition"
mkfs.fat -F32 $boot

echo -n "[INFO]: Would you like to enrypt your disks?(Y/n): "
read encryption

if [ ! "$encryption" = "n" ]; then
    # Create the swap partition
    echo "[INFO]: Enter password for swap encryption"
    read swap_pass

    echo $swap_pass | cryptsetup -q luksFormat "$swap"
    mkdir /root/.keys
    dd if=/dev/urandom of=/root/.keys/swap-keyfile bs=1024 count=4
    chmod 600 /root/.keys/swap-keyfile
    echo $swap_pass | cryptsetup luksAddKey "$swap" /root/.keys/swap-keyfile
    echo "[INFO]: Keyfile saved to /root/.keys/swap-keyfile"
    cryptsetup open --key-file="/root/.keys/swap-keyfile" "$swap" swap
    mkswap /dev/mapper/swap
    swapon /dev/mapper/swap

    # Create the root partition
    echo "[INFO]: Enter password for root encryption"
    read root_pass

    echo $root_pass | cryptsetup -q luksFormat "$root"
    dd bs=512 count=4 if=/dev/random of=/root/.keys/root-keyfile iflag=fullblock
    chmod 600 /root/.keys/root-keyfile
    echo $root_pass | cryptsetup luksAddKey "$root" /root/.keys/root-keyfile
    echo "[INFO]: Keyfile saved to /root/.keys/root-keyfile"
    cryptsetup open --key-file="/root/.keys/root-keyfile" "$root" root
    mkfs.ext4 -F /dev/mapper/root

    mkdir /mnt/sys
    mount /dev/mapper/root /mnt/sys

    if [ "$home_s" = "y" ]; then
        echo "[INFO]: Enter password for home encryption"
        read home_pass
        echo $home_pass | cryptsetup -q luksFormat "$home"
        dd bs=512 count=4 if=/dev/random of=/root/.keys/home-keyfile iflag=fullblock
        chmod 600 /root/.keys/home-keyfile
        echo $home_pass | cryptsetup luksAddKey "$home" /root/.keys/home-keyfile
        echo "[INFO]: Keyfile saved to /root/.keys/home-keyfile"
        cryptsetup open --key-file="/root/.keys/home-keyfile" "$home" home
        mkfs.ext4 -F /dev/mapper/home
        mkdir /mnt/sys/home
        mount "/dev/mapper/home" /mnt/sys/home
    fi
else
    mkswap $swap
    swapon $swap
    mkfs.ext4 -F $root
    mkdir /mnt/sys
    mount $root /mnt/sys
    if [ "$home_s" = "y" ]; then
        mkfs.ext4 -F $home
        mkdir /mnt/sys/home
        mount "$home" /mnt/sys/home
    fi
fi

mkdir /mnt/sys/boot
mount "$boot" /mnt/sys/boot

clear

if [ "$distro" = "1" ];then
    pacstrap /mnt/sys base linux linux-firmware base-devel vi nano
    genfstab -U /mnt/sys >> /mnt/sys/etc/fstab
else
    basestrap /mnt/sys base linux linux-firmware base-devel vi nano openrc
    fstabgen -U /mnt/sys >> /mnt/sys/etc/fstab
fi

echo -n "Would you like to use tmpfs (This can drastically improve performance)?(Y/n): "
read tmpfs_ok

if [ ! "$tmpfs_ok" = "n" ]; then
    echo -n "How big should the tmpfs be?(end with G or M): "
    read tmpfs_size
    echo -e "\n#tmpfs\ntmpfs   /tmp         tmpfs   rw,nodev,nosuid,size=$tmpfs_size""G          0  0\n" >> /mnt/sys/etc/fstab
fi

clear

# Run on chrooted arch install
mkdir /mnt/sys/install

curl https://raw.githubusercontent.com/theFr1nge/dotfiles/main/arch-setup/packages.minimal > /mnt/sys/install/packages.minimal
curl https://raw.githubusercontent.com/theFr1nge/dotfiles/main/arch-setup/packages.full > /mnt/sys/install/packages.full
curl https://raw.githubusercontent.com/theFr1nge/dotfiles/main/arch-setup/packages.base > /mnt/sys/install/packages.base
curl https://raw.githubusercontent.com/theFr1nge/dotfiles/main/arch-setup/chroot.sh > /mnt/sys/install/chroot.sh
chmod +x /mnt/sys/install/chroot.sh

if [ "$home_s" = "y" ]; then
    echo -en "$boot\n$root\n$swap\n$home" > /mnt/sys/install/device
else
    echo -en "$boot\n$root\n$swap" > /mnt/sys/install/device
fi


if [ ! "$encryption" = "n" ]; then
    touch /mnt/sys/install/encrypted
    cp -r /root/.keys /mnt/sys/root
fi


if [ "$distro" = "2" ];then
    touch /mnt/sys/install/artix
fi

pacman -Sy --noconfirm tmux


if [ "$distro" = "1" ];then
    tmux new-session -s "arch-setup" 'arch-chroot /mnt/sys /install/chroot.sh' || arch-chroot /mnt/sys /install/chroot.sh
else
    tmux new-session -s "artix-setup" 'artix-chroot /mnt/sys /install/chroot.sh' || artix-chroot /mnt/sys /install/chroot.sh
fi
