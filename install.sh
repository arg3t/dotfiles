#!/bin/bash

source ~/.dotfiles/profile

username=$(whoami)

mvie(){
  if [ -e "$1" ];then
    rm -rf "$2"
    mv "$1" "$2"
  fi
}

# Configuring for your username
if [ ! "$username" = "yigit" ]; then
  echo "Setting up the dotfiles according to your username"
  find . -type f -exec sed -i "s/\/home\/yigit/\/home\/$username/g" "{}" +
fi

# Don't prompt for a password for the rest of the script
sudo bash -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopwd'

# Install packages
echo -n "Would you like to install all the necessary packages, not doing so might break most of the functionality?(Y/n): "
read deps
if [ ! "$deps" = "n" ]; then
  echo "Running update"
  yay -S --needed --noconfirm $(cat ~/.dotfiles/arch-setup/packages.minimal)
fi

rm -rf ~/.dotfiles_backup
mkdir -p ~/.dotfiles_backup

# Link XDG Directories

# Config
mvie ~/.config ~/.dotfiles_backup
ln -s ~/.dotfiles/config ~/.config
for d in ~/.dotfiles_backup/config/* ; do
  mv $d ~/.config 2> /dev/null
done

#Local
mkdir -p ~/.dotfiles_backup/local
mkdir -p ~/.local

## Local/Share
mvie ~/.local/share ~/.dotfiles_backup/local/share
ln -s ~/.dotfiles/local/share ~/.local/share
for d in ~/.dotfiles_backup/local/share/* ; do
  mv $d ~/.local/share 2> /dev/null
done

## Local/Bin
mvie ~/.local/bin ~/.dotfiles_backup/local/bin
ln -s ~/.dotfiles/local/bin ~/.local/bin
for d in ~/.dotfiles_backup/local/bin/* ; do
  mv $d ~/.local/bin 2> /dev/null
done

## Local/Backgrounds
mvie ~/.local/backgrounds ~/.dotfiles_backup/local/backgrounds
ln -s ~/.dotfiles/local/backgrounds ~/.local/backgrounds
for d in ~/.dotfiles_backup/local/backgrounds/* ; do
  mv $d ~/.local/backgrounds 2> /dev/null
done

## Local/Src
mvie ~/.local/src ~/.dotfiles_backup/local/src
ln -s ~/.dotfiles/suckless ~/.local/src

## Theme and Icon Folders
mvie ~/.themes ~/.dotfiles_backup/themes
ln -s ~/.dotfiles/local/share/themes ~/.themes
mvie ~/.icons ~/.dotfiles_backup/icons
ln -s ~/.dotfiles/local/share/icons ~/.icons

# Create individual files
echo 'ZDOTDIR=$HOME/.config/zsh' > $HOME/.zshenv
chmod +x $HOME/.zshenv

mvie ~/.profile ~/.dotfiles_backup/profile
ln -s ~/.dotfiles/profile ~/.profile

cp ~/.dotfiles/config.env.def ~/.config.env

# Downloading assets
##Fonts
echo "Downloading assets"
prev=$(pwd)
cd ~/.local/share/fonts
curl -O https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Regular%20Nerd%20Font%20Complete.otf > /dev/null 2> /dev/null
curl -O https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Regular%20Nerd%20Font%20Complete%20Mono.otf > /dev/null 2> /dev/null
curl -O https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Bold%20Nerd%20Font%20Complete.otf > /dev/null 2> /dev/null
curl -O https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Bold%20Nerd%20Font%20Complete%20Mono.otf > /dev/null 2> /dev/null
fc-cache
## Backgrounds
cd ~/.local/backgrounds
curl -O https://minio.yigitcolakoglu.com/dotfiles/lock.jpg > /dev/null 2> /dev/null
curl -O https://minio.yigitcolakoglu.com/dotfiles/wallpaper-mountain.jpg > /dev/null 2> /dev/null
curl -O https://minio.yigitcolakoglu.com/dotfiles/wallpaper-sea.jpg > /dev/null 2> /dev/null
curl -O https://minio.yigitcolakoglu.com/dotfiles/wallpaper-shack.jpg > /dev/null 2> /dev/null
cd $prev

# Setup Crontab
if [ ! -f "/var/spool/cron/$username" ]; then
  sudo touch "/var/spool/cron/$username"
  sudo chown $username:$username "/var/spool/cron/$username"
  sudo chmod 755 "/var/spool/cron/$username"
  echo "*/8 * * * * /home/$username/.local/bin/mailsync" > /var/spool/cron/$username
  echo "*/15 * * * * /home/$username/.local/bin/nextcloud-sync" >> /var/spool/cron/$username
  echo "* */1 * * * /home/$username/.local/bin/check-updates" >> /var/spool/cron/$username
  echo "*/30 * * * * calcurse-caldav" >> /var/spool/cron/$username
  echo "*/30 * * * * vdirsyncer sync" >> /var/spool/cron/$username
else
  echo -n "An existing cron file is detected, would you like to overwrite it?(Y/n): "
  read cron
  if [ ! "$cron" = "n" ]; then
    cp /var/spool/cron/$username ~/.dotfiles_backup/crontab
    echo "*/8 * * * * /home/$username/.local/bin/mailsync" > /var/spool/cron/$username
    echo "*/15 * * * * /home/$username/.local/bin/nextcloud-sync" >> /var/spool/cron/$username
    echo "* */1 * * * /home/$username/.local/bin/check-updates" >> /var/spool/cron/$username
    echo "*/30 * * * * calcurse-caldav" >> /var/spool/cron/$username
    echo "*/30 * * * * vdirsyncer sync" >> /var/spool/cron/$username
  fi
fi

# Create necessary folders
mkdir -p "$HOME/.local/share/ncmpcpp/lyrics"
mkdir -p "$HOME/.local/share/calcurse"
mkdir -p "$CARGO_HOME"
mkdir -p "$GOPATH"
mkdir -p "$ANDROID_HOME"
mkdir -p "$FLUTTER_HOME"
mkdir -p "$LEIN_HOME"
mkdir -p "$NVM_DIR"
mkdir -p "$GNUPGHOME"
mkdir -p "$WEECHAT_HOME"
mkdir -p "$JUPYTER_CONFIG_DIR"
mkdir -p "$PYLINTHOME"
mkdir -p "$HOME/.local/share/zsh"
mkdir -p "$XDG_DATA_DIR/mail"
mkdir -p "$XDG_CONFIG_DIR/git"
mkdir -p "$XDG_CACHE_DIR/surf"

chmod 700 "$GNUPGHOME"
touch "$XDG_CONFIG_DIR/git/config"
touch "$_Z_DATA"

# Root Files and Directories
sudo mkdir -p /usr/share/xsessions
sudo cp ~/.dotfiles/root/dwm.desktop /usr/share/xsessions
sudo cp ~/.dotfiles/root/nancyj.flf /usr/share/figlet/fonts
sudo cp ~/.dotfiles/root/quark.service /usr/lib/systemd/system
sudo cp ~/.dotfiles/root/kdialog /usr/local/bin/kdialog
sudo cp ~/.dotfiles/root/udevil.conf /etc/udevil/udevil.conf
sudo chmod +x /usr/local/bin/kdialog
sudo systemctl daemon-reload
sudo groupadd nogroup
sudo systemctl enable quark

if [ "$username" = "yigit" ]; then
  ~/.dotfiles/arch-setup/fetch_keys.sh # Fetch keys (For personal use, this is not for you)
  mkdir -p "$XDG_DATA_DIR/mail/yigitcolakoglu@hotmail.com"
  git config --global user.email "yigitcolakoglu@hotmail.com"
  git config --global user.name "Yigit Colakoglu"
fi

# Build and Install Everything
## Suckless utilities
echo "Installing suckless utilities"
(cd ~/.dotfiles/suckless; ~/.dotfiles/suckless/build.sh > /dev/null 2> /dev/null)

## Tela Icons
echo "Installing Icons"
~/.dotfiles/local/share/icons/Tela-Icons/install.sh > /dev/null 2> /dev/null

## Start page
echo "Setting up start page"
prev=$(pwd)
cd ~/.dotfiles/browser/startpage
npm install > /dev/null 2> /dev/null
npm run build > /dev/null 2> /dev/null
cd $prev


# Vim and tmux plugins
mkdir -p ~/.tmux/plugins
vim +PlugInstall +qall
cd ~/.config/coc/extensions
yarn
cd $prev

# Install mconnect
echo "Installing mconnect"
git clone https://github.com/theFr1nge/mconnect.git /tmp/mconnect.git > /dev/null 2> /dev/null
cd /tmp/mconnect.git
mkdir -p build
cd build
meson .. > /dev/null 2> /dev/null
ninja > /dev/null 2> /dev/null
sudo ninja install > /dev/null 2> /dev/null
cd $prev
mkdir -p ~/Downloads/mconnect

## Bitwarden Dmenu
echo "Installing bitwardedn-dmenu"
sudo git clone https://github.com/theFr1nge/bitwarden-dmenu.git /usr/share/bwdmenu > /dev/null 2> /dev/null
cd /usr/share/bwdmenu
sudo npm install > /dev/null 2> /dev/null
sudo npm i -g > /dev/null 2> /dev/null
cd $prev

## Simcrop
echo "Installing simcrop"
git clone https://github.com/theFr1nge/simcrop.git /tmp/simcrop > /dev/null 2> /dev/null
cd /tmp/simcrop
sudo make install > /dev/null 2> /dev/null
cd $prev

# Do a cleanup and delete some problematic files
mv ~/.fzf ~/.local/share/fzf
rm -rf ~/.fzf*
rm -rf ~/.bash_profile
sudo rm -rf /etc/urlview/system.urlview


sudo rm -rf /etc/sudoers.d/nopwd
