#!/bin/bash

ln -sf /bin/bash /bin/sh

if [ ! -f "/install/device" ]; then
    mkdir -p /install
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
        echo -en "$boot\n$root\n$swap\n$home" > /install/device
    else
        echo -en "$boot\n$root\n$swap" > /install/device
    fi
fi

clear

boot=$(head -n 1 /install/device | tail -n 1)
root=$(head -n 2 /install/device | tail -n 1)
swap=$(head -n 3 /install/device | tail -n 1)
if [ ! "$(wc -l /install/device)" = "3" ]; then
    home=$(head -n 4 /install/device | tail -n 1)
fi

ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
hwclock --systohc
echo -e "en_US.UTF-8 UTF-8\ntr_TR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
if [ ! -f "/tmp/.blackarch" ]; then
    curl https://blackarch.org/strap.sh > /tmp/strap.sh
    chmod +x /tmp/strap.sh
    /tmp/strap.sh

    if [ -f "/install/artix" ]; then
        echo -e "\n[lib32]\nInclude = /etc/pacman.d/mirrorlist\n\n[options]\nILoveCandy\nTotalDownload\nColor" >> /etc/pacman.conf
    else
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n\n[options]\nILoveCandy\nTotalDownload\nColor" >> /etc/pacman.conf
    fi


    echo -n "Are you going to use a flexo server?(y/N): "
    read flexo

    while [ "$flexo" = "y" ]; do
        echo -n "Please enter ip address of flexo server: "
        read flexo_ip
        echo "\nServer = http://$flexo_ip:7878/\$repo/os/\$arch\n" >> /etc/pacman.d/mirrorlist
    done
    pacman -Syy

    echo -n "Did any errors occur?(y/N): "
    read errors

    if [ "$errors" = "y" ]; then
        echo "Dropping you into a shell so that you can fix them, once you quit the shell, the installation will continue from where you left off."
        bash
    fi
    touch /tmp/.blackarch
fi

clear

echo "Please enter hostname: "
read hostname
echo $hostname > /etc/hostname

echo "Set password for root: "
passwd root

echo "Please enter name for regular user:"
read username

useradd -m $username
echo "Set password for user $username: "
passwd $username
usermod -aG wheel $username


echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.0.1 $hostname.localdomain $hostname" > /etc/hosts

if [ -f "/install/encrypted" ]; then
cat << EOF > /etc/initcpio/hooks/openswap
run_hook ()
{
    x=0;
    while [ ! -b /dev/mapper/root ] && [ \$x -le 10 ]; do
       x=$((x+1))
       sleep .2
    done
    mkdir crypto_key_device
    mount /dev/mapper/root crypto_key_device
    cryptsetup open --key-file crypto_key_device/root/.keys/swap-keyfile $swap swap
    umount crypto_key_device
}
EOF

cat << EOF > /etc/initcpio/install/openswap
build ()
{
   add_runscript
}
help ()
{
cat<<HELPEOF
  This opens the swap encrypted partition $swap in /dev/mapper/swap
HELPEOF
}
EOF

if [ ! "$home" = "" ]; then
cat << EOF > /etc/initcpio/hooks/openhome
run_hook ()
{
    x=0;
    while [ ! -b /dev/mapper/root ] && [ \$x -le 10 ]; do
       x=$((x+1))
       sleep .2
    done
    mkdir crypto_key_device
    mount /dev/mapper/root crypto_key_device
    cryptsetup open --key-file crypto_key_device/root/.keys/home-keyfile $home home
    umount crypto_key_device
}
EOF
cat << EOF > /etc/initcpio/install/openhome
build ()
{
   add_runscript
}
help ()
{
cat<<HELPEOF
  This opens the swap encrypted partition $home in /dev/mapper/home
HELPEOF
}
EOF
cat << EOF > /etc/mkinitcpio.conf
MODULES=(vfat i915)
BINARIES=()
FILES=()
HOOKS=(base udev plymouth autodetect keyboard keymap consolefont modconf block plymouth-encrypt openswap openhome resume filesystems fsck)
EOF
else
cat << EOF > /etc/mkinitcpio.conf
MODULES=(vfat i915)
BINARIES=()
FILES=()
HOOKS=(base udev plymouth autodetect keyboard keymap consolefont modconf block plymouth-encrypt openswap resume filesystems fsck)
EOF
fi
else
cat << EOF > /etc/mkinitcpio.conf
MODULES=(vfat i915)
BINARIES=()
FILES=()
HOOKS=(base udev plymouth autodetect keyboard keymap consolefont modconf block plymouth resume filesystems fsck)
EOF
fi

pacman -Syu --noconfirm $(cat /install/packages.base | xargs)
pacman --noconfirm -R vim

refind-install

if [ -f "/install/encrypted" ]; then
line=1

blkid | while IFS= read -r i; do
    echo "$line: $i"
    ((line=line+1))
done

echo -n "Please select the device you will save the LUKS key to: "
read keydev

uuid=$(blkid | sed -n 's/.*UUID=\"\([^\"]*\)\".*/\1/p'  | sed -n "$keydev"p)
cat << EOF > /boot/refind_linux.conf
"Boot with encryption"  "root=/dev/mapper/root resume=/dev/mapper/swap cryptdevice=UUID=$(blkid -s UUID -o value $root):root:allow-discards cryptkey=UUID=$uuid:vfat:key.yeet rw loglevel=3 quiet splash"
EOF
clear
else
cat << EOF > /boot/refind_linux.conf
"Boot with encryption"  "root=UUID=$(blkid -s UUID -o value $root) resume=UUID=$(blkid -s UUID -o value $swap) rw loglevel=3 quiet splash"
EOF
fi

mkdir -p /etc/sudoers.d
echo "Defaults env_reset,pwfeedback" >> /etc/sudoers.d/wheel
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopwd
echo "$username $hostname =NOPASSWD: /sbin/shutdown ,/sbin/halt,/sbin/reboot,/sbin/hibernate, /bin/pacman -Syyuw --noconfirm" > /etc/sudoers.d/wheel


sudo -u $username bash -c "git clone https://aur.archlinux.org/yay.git /tmp/yay"
sudo -u $username bash -c "(cd /tmp/yay; makepkg --noconfirm -si)"
sudo -u $username bash -c "yay --noconfirm -S plymouth"

clear

echo -n "Would you like to automatically install my dotfiles?(y/N): "
read dotfiles

if [ "$dotfiles" = "y" ]; then
    pacman -R --noconfirm vim
    sudo -u $username bash -c "git clone --recurse-submodules https://github.com/theFr1nge/dotfiles.git ~/.dotfiles"
    sudo -u $username bash -c "(cd ~/.dotfiles; ./install.sh)"
    clear
    git clone https://github.com/adi1090x/plymouth-themes.git /tmp/pthemes
cat << EOF > /etc/plymouth/plymouthd.conf
[Daemon]
Theme=sphere
ShowDelay=0
DeviceTimeout=8
EOF
    cp -r /tmp/pthemes/pack_4/sphere /usr/share/plymouth/themes
    clear
fi



echo -e "/boot/EFI/refind\n2\n2" | sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/bobafetthotmail/refind-theme-regular/master/install.sh)"

if [ -f "/install/artix" ]; then
    echo "Manually enable services, not implemented"
else
    systemctl enable NetworkManager
    systemctl enable ly
    systemctl enable fstrim.timer
    systemctl enable cronie
    systemctl enable bluetooth
fi

clear

mkinitcpio -P

if [ -f "/install/encrypted" ]; then
    vim /etc/fstab
fi
pacman --noconfirm -R nano # uninstall nano, eww

clear

rm -rf /etc/sudoers.d/nopwd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers.d/wheel

ln -sf /bin/dash /bin/sh

clear

echo "SETUP COMPLETE"
bash
rm -rf /install
