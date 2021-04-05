#!/bin/bash

echo "Please enter the location of image file (Press enter to skip this step): "
loc=$(fzf)

if [ -z "$loc" ]
then
    echo "Continuing with the installation..."
    exit
fi

mc cp -r fr1nge-dots/dotfiles/tools/ ~/.local/bin/
sudo chmod +x ~/.local/bin/*

~/.local/bin/jsteg reveal $loc > /tmp/out.zip.gpg

echo "Please enter your passphrase: "
gpg -d /tmp/out.zip.gpg > /tmp/out.zip

unzip /tmp/out.zip -d /tmp/keys

gpg --import /tmp/keys/gpg.key

mkdir -p ~/.ssh

chmod 700 ~/.ssh

cp /tmp/keys/id_* ~/.ssh



