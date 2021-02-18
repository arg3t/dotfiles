#!/bin/bash

ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
hwclock --systohc
echo -e "en_US.UTF-8 UTF-8\ntr_TR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=trq" > /etc/vconsole.conf
echo "tatooine" > /etc/hostname
git clone https://aur.archlinux.org/yay.git /tmp/yay
(cd /tmp/yay; makepkg -si)

systemctl enable fstrim.timer

echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.0.1 tatooine.localdomain tatooine" > /etc/hosts
cat << EOF > /etc/mkinitcpio.conf
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt vfat filesystems fsck)
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
  This opens the swap encrypted partition $(cat /install/device)1 in /dev/mapper/swap
HELPEOF
}
EOF

line=1
for i in $(blkid); do
    echo "$line: $i"
    ((line=line+1))
done
echo "Please select the device you will save the LUKS key to:"
read $keydev

uuid=$(blkid | sed -n 's/.*UUID=\"\([^\"]*\)\".*/\1/p'  | sed -n "$line"p)
cat << EOF > /boot/refind_linux.conf
"Boot with encryption"  "root=/dev/mapper/root resume=/dev/mapper/swap cryptdevice=UUID=$(blkid -s UUID -o value $(cat /install/device)3):root:allow-discards cryptkey=UUID=$uuid:vfat:key.yeet rw loglevel=3 quiet"
EOF

cat /install/nonAUR.txt | xargs pacman -S --needed --noconfirm
yay -S $(cat /install/AUR.txt)
mkinitcpio -P
