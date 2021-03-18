#!/bin/bash

echo "Please enter the location of image file (Press enter to skip this step): "
read loc

if [ -z "$loc" ]
then
    echo "Continuing with the installation..."
    exit
fi

~/.scripts/jsteg reveal $loc > /tmp/out.zip.gpg

echo "Please enter your passphrase: "
gpg -d /tmp/out.zip.gpg > /tmp/out.zip

unzip /tmp/out.zip -d /tmp/keys

gpg --import /tmp/keys/gpg.key

mkdir -p ~/.ssh

cp /tmp/keys/id_* ~/.ssh



