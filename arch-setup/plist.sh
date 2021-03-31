#!/bin/bash

#comm -23 <(pacman -Qqt | sort) <(pacman -Qqg base 2> /dev/null | sort) > ~/.dotfiles/arch-setup/packages.full
pacman -Q | cut -f 1 -d " " | sort > ~/.dotfiles/arch-setup/packages.full
sort -o ~/.dotfiles/arch-setup/packages.blacklist ~/.dotfiles/arch-setup/packages.blacklist
comm -13 ~/.dotfiles/arch-setup/packages.blacklist ~/.dotfiles/arch-setup/packages.full > ~/.dotfiles/arch-setup/packages.minimal

