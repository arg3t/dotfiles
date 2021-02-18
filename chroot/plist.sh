#!/bin/bash
pacman -Qqe | grep -v "$(pacman -Qqm)" > nonAUR.txt
pacman -Qqm > AUR.txt

