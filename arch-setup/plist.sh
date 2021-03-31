#!/bin/bash

comm -23 <(pacman -Qqt | sort) <(pacman -Qqg base 2> /dev/null | sort) > ~/.dotfiles/arch-setup/packages.full
comm -13 packages.blacklist packages.full > packages.minimal

