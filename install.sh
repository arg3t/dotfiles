#!/bin/bash

username=$(whoami)

mvie(){
  if [ -e "$1" ];then
    rm -rf "$2"
    mv "$1" "$2"
  fi
}

# Configuring for your username
if [ ! "$username" = "yigit" ]; then
  grep -rl "yigit" | xargs sed -i  "s/yigit/$username/g"
fi

# Don't prompt for a password for the rest of the script
sudo echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopwd

# Install packages
echo "Running update"
sudo rm -rf /etc/urlview/system.urlview
yay -S --noconfirm $(cat ~/.dotfiles/arch-setup/packages.minimal)

# Initial cleanup
echo "Backing up your previous dotfiles to ~/.dotfiles_backup"
mkdir -p ~/.dotfiles_backup

mvie ~/.profile ~/.dotfiles_backup/profile
ln -s ~/.dotfiles/profile ~/.profile

# Config
mkdir -p ~/.config
mkdir -p ~/.dotfiles_backup/config
for d in ~/.dotfiles/config/* ; do
  filename=$(echo "$d" | rev | cut -d"/" -f 1 | rev)
  mvie ~/.config/$filename ~/.dotfiles_backup/config
  ln -s $d ~/.config/
done

# Config
mkdir -p ~/.local/share
mkdir -p ~/.dotfiles_backup/local/share
mvie ~/.themes ~/.dotfiles_backup/themes
ln -s ~/.dotfiles/local/share/themes ~/.themes
mvie ~/.icons ~/.dotfiles_backup/icons
ln -s ~/.dotfiles/local/share/icons ~/.icons
~/.dotfiles/local/share/icons/Tela-Icons/install.sh

for d in ~/.dotfiles/local/share/* ; do
  filename=$(echo "$d" | rev | cut -d"/" -f 1 | rev)
  echo $filename
  mvie ~/.local/share/$filename ~/.dotfiles_backup/local/share
  ln -s $d ~/.local/share
done

mvie ~/.local/share/bin ~/.dotfiles_backup/local/share/bin
ln -s ~/.dotfiles/local/bin ~/.local/share/bin

mvie ~/.local/backgrounds ~/.dotfiles_backup/local/backgrounds
ln -s ~/.dotfiles/local/backgrounds ~/.local/backgrounds

prev=$(pwd)
cd ~/.local/share/fonts
wget https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Regular%20Nerd%20Font%20Complete.otf > /dev/null 2> /dev/null
wget https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Regular%20Nerd%20Font%20Complete%20Mono.otf > /dev/null 2> /dev/null
wget https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Bold%20Nerd%20Font%20Complete.otf > /dev/null 2> /dev/null
wget https://minio.yigitcolakoglu.com/dotfiles/Caskaydia%20Cove%20Bold%20Nerd%20Font%20Complete%20Mono.otf > /dev/null 2> /dev/null

cd ~/.local/backgrounds
wget https://minio.yigitcolakoglu.com/dotfiles/lock.jpg > /dev/null 2> /dev/null
wget https://minio.yigitcolakoglu.com/dotfiles/wallpaper-mountain.jpg > /dev/null 2> /dev/null
wget https://minio.yigitcolakoglu.com/dotfiles/wallpaper-sea.jpg > /dev/null 2> /dev/null
wget https://minio.yigitcolakoglu.com/dotfiles/wallpaper-shack.jpg > /dev/null 2> /dev/null
cd $prev

fc-cache

# Applications
mkdir -p ~/.local/share/applications
mkdir -p ~/.dotfiles_backup/local/share/applications
for d in ~/.dotfiles/local/applications/* ; do
  filename=$(echo "$d" | rev | cut -d"/" -f 1 | rev)
  mvie ~/.local/share/applications/$filename ~/.dotfiles_backup/local/share/applications
  ln -s $d ~/.local/share/applications/
done

# Suckless
yay --noconfirm -S xsel clipnotify
yay --noconfirm -S ttf-symbola
yay --noconfirm -S yajl
(cd ~/.dotfiles/suckless; ~/.dotfiles/suckless/build.sh)

if [ ! -f "/var/spool/cron/$username" ]; then
  sudo touch "/var/spool/cron/$username"
  sudo chown $username:$username "/var/spool/cron/$username"
  sudo chmod 755 "/var/spool/cron/$username"
fi

# Create necessary folders

source ~/.profile
mkdir -p "$HOME/.local/share/ncmpcpp/lyrics"
mkdir -p "$HOME/.local/share/calcurse"
mkdir -p "$CARGO_HOME"
mkdir -p "$GOPATH"
mkdir -p "$ANDROID_HOME"
mkdir -p "$FLUTTER_HOME"
mkdir -p "$LEIN_HOME"
mkdir -p "$NPM_CONFIG_USERCONFIG"
mkdir -p "$NVM_DIR"
mkdir -p "$GNUPGHOME"
mkdir -p "$WEECHAT_HOME"
mkdir -p "$JUPYTER_CONFIG_DIR"
mkdir -p "$PYLINTHOME"
touch "$_Z_DATA"

echo "*/8 * * * * /home/$username/.local/bin/mailsync" >> /var/spool/cron/$username
echo "*/15 * * * * /home/$username/.local/bin/scripts/nextcloud-sync" >> /var/spool/cron/$username
echo "*/30 * * * * calcurse-caldav" >> /var/spool/cron/$username
echo "*/30 * * * * vdirsyncer sync" >> /var/spool/cron/$username

# Root
sudo cp ~/.dotfiles/root/dwm.desktop /usr/share/xsessions
sudo cp ~/.dotfiles/root/nancyj.flf /usr/share/figlet/fonts
sudo cp ~/.dotfiles/root/quark.service /usr/lib/systemd/system
sudo cp ~/.dotfiles/root/kdialog /usr/local/bin/kdialog
sudo cp ~/.dotfiles/root/udevil.conf /etc/udevil/udevil.conf
sudo chmod +x /usr/local/bin/kdialog
sudo systemctl daemon-reload
sudo systemctl enable quark

# Config
cp ~/.dotfiles/config.env.def ~/.config.env

# Start page
prev=$(pwd)
cd ~/.dotfiles/browser/startpage
npm install
npm run build
cd $prev

if [ "$username" = "yigit" ]; then
  ~/.dotfiles/arch-setup/fetch_keys.sh # Fetch keys (For personal use, this is not for you)
fi

# Install vim and tmux plugins
mkdir -p ~/.tmux/plugins
vim +PlugInstall +qall

# Install mconnect
git clone https://github.com/theFr1nge/mconnect.git /tmp/mconnect
prev=$(pwd)
cd /tmp/mconnect
mkdir -p build
cd build
meson ..
ninja
sudo ninja install
cd $prev
mkdir -p ~/Downloads/mconnect

sudo git clone https://github.com/theFr1nge/bitwarden-dmenu.git /usr/share/bwdmenu
cd /usr/share/bwdmenu
sudo npm install
sudo npm i -g
cd $prev

# Install simcrop
sudo pacman --needed --noconfirm -S opencv
git clone https://github.com/theFr1nge/simcrop.git /tmp/simcrop
cd /tmp/simcrop
sudo make install
cd $prev

sudo rm -rf /etc/sudoers.d/nopwd
