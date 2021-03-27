#!/bin/bash

echo "Please enter the location of image file (Press enter to skip this step): "
read loc

if [ -z "$loc" ]
then
    echo "Continuing with the installation..."
    exit
fi

sudo wget -O /usr/bin/jsteg https://minio.yigitcolakoglu.com/dotfiles/jsteg-linux-amd64 > /dev/null 2> /dev/null
sudo chmod +x /usr/bin/jsteg

sudo wget -O /usr/bin/slink https://minio.yigitcolakoglu.com/dotfiles/slink-linux-amd64 > /dev/null 2> /dev/null
sudo chmod +x /usr/bin/slink

~/.local/share/scripts/jsteg reveal $loc > /tmp/out.zip.gpg

echo "Please enter your passphrase: "
gpg -d /tmp/out.zip.gpg > /tmp/out.zip

unzip /tmp/out.zip -d /tmp/keys

gpg --import /tmp/keys/gpg.key

mkdir -p ~/.ssh

cp /tmp/keys/id_* ~/.ssh



