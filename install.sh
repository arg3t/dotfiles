#!/bin/bash

dots="git --git-dir=\$HOME/.dotfiles.git/ --work-tree=\$HOME"
username=$(whoami)
prev=$(pwd)
verbose=0

rm -rf "~/dots_backup"

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

## Theme and Icon Folders
mvie ~/.themes ~/.dotfiles_backup/themes
ln -s ~/.dotfiles/local/share/themes ~/.themes
mvie ~/.icons ~/.dotfiles_backup/icons
ln -s ~/.dotfiles/local/share/icons ~/.icons

info "Checking out dotfiles"
bash -c "$dots checkout"

# Configuring for your username
if [ ! "$username" = "yigit" ]; then
  info "Replacing the occurences of /home/yigit with /home/$username"
  echo "Setting up the dotfiles according to your username"
  bash -c "$dots ls-files | xargs -L 1 sed -i \"s/\/home\/yigit/\/home\/$username/g\""
fi

info "Setting up sudo so that you won't be prompted for a password for the next of the script"

# Don't prompt for a password for the rest of the script
sudo bash -c 'echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopwd'


eval "$(grep -h -- \
	"^\s*\(export \)\?\(CARGO_HOME\|GOPATH\|ANDROID_HOME\|FLUTTER_HOME\|LEIN_HOME\|NVM_DIR\|GNUPGHOME\|WEECHAT_HOME\|JUPYTER_CONFIG_DIR\|PYLINTHOME\|XDG_DATA_HOME\|XDG_CONFIG_HOME\|XDG_CACHE_HOME\|_Z_DATA\)=" \
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

info "Copying some necessary files that are not in ~"
IFS="
"
for i in $(cat "$HOME/.local/root/mappings"); do
  src="$(echo "$i" | sed "s/ ->.*//g")"
  dest="$(echo "$i" | sed "s/.*-> //g")"
  sudo mkdir -p "$(echo "$dest" | sed "s/\/[^\/]*$//g")"
  sudo cp "$HOME/.local/root/$src" "$dest"
done

yay -S --needed --noconfirm "$(cat ~/pkg.list)"

# Install fonts and icons
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip
unzip CascadiaCode.zip

if [ ! -d $XDG_DATA_HOME/fonts ]; then
  mkdir -p $XDG_DATA_HOME/fonts
fi

mv CascadiaCode/* $XDG_DATA_HOME/fonts
fc-cache

rm -rf CascadiaCode CascadiaCode.zip

git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/tela
p=$(pwd)
cd /tmp/tela
./install.sh
cd $p
rm -rf /tmp/tela

cp ~/.config/config.env.default ~/.config/config.env

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


sudo systemctl enable chronyd
sudo systemctl enable cronie

if [ "$username" = "yigit" ]; then
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
if [ "$(hostnamectl hostname)" = "workstation" ]; then
  export VPS=1
else
  export VPS=0
fi

info "Installing suckless utilities"
(cd ~/.local/src; ./build.sh > /dev/null 2> /dev/null)
sudo groupadd nogroup

# Do a cleanup and delete some problematic files
rm -rf ~/.fzf*
rm -rf ~/.bash_profile
rm -rf ~/.dotfiles/yarn.lock
rm -rf ~/.dotfiles/.git/hooks/*
rm -rf ~/install.sh
rm -rf ~/README.md
rm -rf ~/pkg.list
bash -c "$dots update-index --assume-unchanged {pkg.list,install.sh,README.md}"
bash -c "$dots config --local status.showUntrackedFiles no"
sudo rm -rf /etc/urlview/system.urlview
echo "I am now restarting your system so that the configurations changes apply"
sleep 5
sudo bash -c "rm -rf /etc/sudoers.d/nopwd; reboot"

