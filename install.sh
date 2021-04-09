#!/bin/bash

alias dots="git --git-dir=\$HOME/.dotfiles.git/ --work-tree=\$HOME"
username=$(whoami)
prev=$(pwd)
verbose=0

while getopts "v" OPTION
do
  case $OPTION in
    v) verbose=1
       ;;
    *) echo "Only available option is -v" ;;
  esac
done

mvie(){
  if [ -e "$1" ];then
    rm -rf "$2"
    mv "$1" "$2"
  fi
}

info(){
  printf "[\e[32mINFO\e[0m]:%s\n" "$1"
}

debug(){
  if [ $verbose ]; then
    printf "[\e[33mDEBUG\e[0m]:%s\n" "$1"
  fi
}

error(){
  printf "[\e[31mERROR\e[0m]:%s\n" "$1"
}

prompt(){
  printf "[\e[35mPROMPT\e[0m]: %s" "$1"
  read -r ans
  printf "%s" "$ans"
}

echo "Running backup of old dotfiles"
IFS="
"

# Backup Previous Dots
info "Backing up your old dotfiles"
## Backup eveything in the git tree
mkdir "$HOME/dots_backup"
for i in $(dots ls-files); do
  if [ -f "$i" ]; then
    debug "$i"
    mkdir -p "$HOME/dots_backup/$(echo "$i" | sed "s/\/[^\/]*$//g")"
    mv "$i" "$HOME/dots_backup/$(echo "$i" | sed "s/\/[^\/]*$//g")"
  fi
  rm -rf "$i"
done
## Theme and Icon Folders
mvie ~/.themes ~/.dotfiles_backup/themes
ln -s ~/.dotfiles/local/share/themes ~/.themes
mvie ~/.icons ~/.dotfiles_backup/icons
ln -s ~/.dotfiles/local/share/icons ~/.icons

info "Checking out dotfiles"
dots checkout

# Configuring for your username
if [ ! "$username" = "yigit" ]; then
  info "Replacing the occurences of /home/yigit with /home/$username"
  echo "Setting up the dotfiles according to your username"
  dots ls-files | xargs -L 1 sed -i "s/\/home\/yigit/\/home\/$username/g"
fi

info "Setting up sudo so that you won't be prompted for a password for the next of the script"

# Don't prompt for a password for the rest of the script
sudo bash -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopwd'


eval "$(grep -h -- \
	"^\s*\(export \)\?\(CARGO_HOME\|GOPATH\|ANDROID_HOME\|FLUTTER_HOME\|LEIN_HOME\|NVM_DIR\|GNUPGHOME\|WEECHAT_HOME\|JUPYTER_CONFIG_DIR\|PYLINTHOME\|XDG_DATA_HOME\|XDG_CONFIG_HOME\|XDG_CACHE_HOME\|_Z_DATA)=" \
	"$HOME/.profile"  2>/dev/null)"

info "Creating relevant directories"
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
mkdir -p "$XDG_DATA_HOME/mail"
mkdir -p "$XDG_DATA_HOME/icons"
mkdir -p "$XDG_DATA_HOME/themes"
mkdir -p "$XDG_DATA_HOME/fonts"
mkdir -p "$HOME/.local/backgrounds"
mkdir -p "$XDG_CONFIG_HOME/git"
mkdir -p "$XDG_CACHE_HOME/surf"
mkdir -p "$HOME/.ssh"
chmod 700 "$GNUPGHOME"
touch "$XDG_CONFIG_HOME/git/config"
touch "$_Z_DATA"

# Install packages
deps=$(prompt -n "Would you like to install all the necessary packages, not doing so might break most of the functionality?(Y/n): ")
if [ ! "$deps" = "n" ]; then
  echo "Running update"
  yay -S --needed --noconfirm "$(cat ~/pkg.list)" && exit 1
fi

cp ~/.config/config.env.default ~/.config/config.env

# Downloading assets
##Fonts
echo "Downloading assets"

curl https://minio.yigitcolakoglu.com/dotfiles/tools/mc > "$HOME/.local/bin/mc"
chmod +x "$HOME/.local/bin/mc"
"$HOME/.local/bin/mc" alias set fr1nge https://minio.yigitcolakoglu.com "" ""
mc cp -r fr1nge/dotfiles/fonts/ ~/.local/share/fonts/
mc cp -r fr1nge/dotfiles/backgrounds/ ~/.local/backgrounds/
git clone https://github.com/material-ocean/Gtk-Theme.git "$XDG_DATA_HOME/themes/material-ocean"
git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/tela
fc-cache

# Setup Crontab
if [ ! -f "/var/spool/cron/$username" ]; then
  crontab "$HOME/.config/crontab"
else
  echo -n "An existing cron file is detected, would you like to overwrite it?(Y/n): "
  read -r cron
  if [ ! "$cron" = "n" ]; then
    crontab -l >> "$HOME/.config/crontab"
    crontab "$HOME/.config/crontab"
  fi
fi


# Root Files and Directories
if [ "$(grep artix < "$(uname -a)")" = "" ]; then
  sudo rc-update add quark
else
  sudo systemctl enable quark
  sudo systemctl daemon-reload
fi


if [ "$username" = "yigit" ]; then
  ~/.dotfiles/arch-setup/fetch_keys.sh # Fetch keys (For personal use, this is not for you)
  mkdir -p "$XDG_DATA_HOME/mail/yigitcolakoglu@hotmail.com"
  git config --global user.email "yigitcolakoglu@hotmail.com"
  git config --global user.name "Yigit Colakoglu"
fi

# Setup for pam-gnupg
cat << EOF | sudo tee -a /etc/pam.d/system-local-login
session  optional  pam_env.so user_readenv=1
auth     optional  pam_gnupg.so store-only
session  optional  pam_gnupg.so
EOF

# Build and Install Everything
## Suckless utilities
info "Installing suckless utilities"
(cd ~/.local/src; ./build.sh > /dev/null 2> /dev/null)
sudo groupadd nogroup

## Tela Icons
info "Installing Icons"
/tmp/tela/install.sh > /dev/null 2> /dev/null

## Start page
info "Setting up start page"
prev=$(pwd)
cd ~/.local/share/startpage
sudo npm install -g parcel-bundler
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
info "Installing mconnect"
git clone https://github.com/theFr1nge/mconnect.git /tmp/mconnect.git > /dev/null 2> /dev/null
cd /tmp/mconnect.git
mkdir -p build
cd build
meson .. > /dev/null 2> /dev/null
ninja > /dev/null 2> /dev/null
sudo ninja install > /dev/null 2> /dev/null
cd $prev
mkdir -p ~/Downloads/mconnect

## Simcrop
info "Installing simcrop"
git clone https://github.com/theFr1nge/simcrop.git /tmp/simcrop > /dev/null 2> /dev/null
cd /tmp/simcrop
sudo make install > /dev/null 2> /dev/null
cd $prev

# Do a cleanup and delete some problematic files
rm -rf ~/.fzf*
rm -rf ~/.bash_profile
rm -rf ~/.dotfiles/yarn.lock
rm -rf ~/.dotfiles/.git/hooks/*
rm -rf ~/install.sh
rm -rf ~/README.md
rm -rf ~/pkg.list
dots update-index --assume-unchanged {pkg.list,install.sh,README.md}
dots config --local status.showUntrackedFiles no
sudo rm -rf /etc/urlview/system.urlview
echo "I am now restarting your system so that the configurations changes apply"
sleep 5
sudo bash -c "rm -rf /etc/sudoers.d/nopwd; reboot"

