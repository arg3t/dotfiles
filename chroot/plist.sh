#!/bin/bash
pacman -Qqe | grep -v "$(pacman -Qqm)" > ~/.dotfiles/chroot/nonAUR.txt
pacman -Qqm > ~/.dotfiles/chroot/AUR.txt

