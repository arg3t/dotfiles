#!/bin/bash

if [ ! -f "/install/device" ]; then
    echo -n "What is the install device: "
    read device
    echo "Installing to $device... (Enter to continue)"
    read _
    mkdir -p /install
    echo $device > /install/device
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
    touch /tmp/.blackarch
fi
echo "Please enter hostname: "
read hostname
echo $hostname > /etc/hostname

echo "Please enter name for regular user:"
read username

useradd -m $username
usermod -aG wheel yigit

systemctl enable fstrim.timer

echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.0.1 $hostname.localdomain $hostname" > /etc/hosts
cat << EOF > /etc/mkinitcpio.conf
MODULES=(vfat i915)
BINARIES=()
FILES=()
HOOKS=(base udev plymouth autodetect keyboard keymap consolefont modconf block plymouth-encrypt openswap resume filesystems fsck)
EOF

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
    cryptsetup open --key-file crypto_key_device/root/.keys/swap-keyfile $(cat /install/device)2 swap
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
  This opens the swap encrypted partition $(cat /install/device)2 in /dev/mapper/swap
HELPEOF
}
EOF

pacman --noconfirm -R vim
pacman -S --needed --noconfirm $(cat /install/nonAUR.txt)

line=1

blkid | while IFS= read -r i; do
    echo "$line: $i"
    ((line=line+1))
done

echo "Please select the device you will save the LUKS key to:"
read keydev

uuid=$(blkid | sed -n 's/.*UUID=\"\([^\"]*\)\".*/\1/p'  | sed -n "$keydev"p)
cat << EOF > /boot/refind_linux.conf
"Boot with encryption"  "root=/dev/mapper/root resume=/dev/mapper/swap cryptdevice=UUID=$(blkid -s UUID -o value $(cat /install/device)3):root:allow-discards cryptkey=UUID=$uuid:vfat:key.yeet rw loglevel=3 quiet splash"
EOF

mkdir -p /etc/sudoers.d
echo "$username $hostname =NOPASSWD: /usr/bin/systemctl poweroff,/usr/bin/systemctl halt,/usr/bin/systemctl reboot,/usr/bin/systemctl hibernate" >> /etc/sudoers.d/wheel
echo "Defaults env_reset,pwfeedback" >> /etc/sudoers.d/wheel
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/nopwd

echo "Set password for user $username: "
passwd $username

sudo -u $username bash -c "git clone https://aur.archlinux.org/yay.git /tmp/yay"
sudo -u $username bash -c "(cd /tmp/yay; makepkg --noconfirm -si)"
sudo -u $username bash -c "yay --noconfirm -S plymouth"

refind-install


sudo -u $username bash -c "git clone --recurse-submodules https://github.com/theFr1nge/dotfiles.git ~/.dotfiles"
sudo -u $username bash -c "(cd ~/.dotfiles; ./install.sh)"

git clone https://github.com/adi1090x/plymouth-themes.git /tmp/pthemes

cat << EOF > /etc/plymouth/plymouthd.conf
[Daemon]
Theme=sphere
ShowDelay=0
DeviceTimeout=8
EOF
cp -r /tmp/pthemes/pack_4/sphere /usr/share/plymouth/themes

echo -e "/boot/EFI/refind\n2\n2" | sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/bobafetthotmail/refind-theme-regular/master/install.sh)"

systemctl enable NetworkManager
systemctl enable ly
systemctl enable cronie

mkinitcpio -P

vim /etc/fstab
pacman -R nano # uninstall nano, eww

rm -rf /etc/sudoers.d/nopwd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers.d/wheel

rm -rf /bin/sh
ln -sf /bin/dash /bin/sh

echo "SETUP COMPLETE"
bash
