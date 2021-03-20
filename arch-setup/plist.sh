#!/bin/bash
pacman -Qq | grep -v "$(pacman -Qqm)" | grep -v yay > ~/.dotfiles/arch-setup/nonAUR.txt
pacman -Qqm | grep -v canon | grep -v capt | grep -v cups> ~/.dotfiles/arch-setup/AUR.txt

