#!/bin/bash

# Vars for some bugs and applications
export QT_QPA_PLATFORMTHEME="qt5ct"
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT=MToolkit

# Environment variables
export SHELL=/bin/zsh
export TERMINAL=/usr/local/bin/st
export BROWSER=firefox
export EDITOR=nvim
export OPENER=xdg-open
export DEFAULT_RECIPIENT="yigitcolakoglu@hotmail.com"

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
export GOPATH="$XDG_DATA_HOME"/go
export ANDROID_HOME="$XDG_DATA_HOME"/Sdk
export FLUTTER_HOME="$XDG_DATA_HOME"/flutter
export LEIN_HOME="$XDG_DATA_HOME"/lein
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NVM_DIR="$XDG_DATA_HOME"/nvm
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export MBSYNCRC="$XDG_CONFIG_HOME"/isync/mbsyncrc
export IMAPFILTER_CONFIG="$XDG_CONFIG_HOME/imapfilter/config.lua"
export VIMINIT="set nocp | source ${XDG_CONFIG_HOME:-$HOME/.config}/vim/vimrc"
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
export GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
export RANDFILE="$XDG_DATA_HOME"/openssl/rnd
export _Z_DATA="$XDG_DATA_HOME/z"
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export WAKATIME_HOME="$XDG_CONFIG_HOME/wakatime"
export XSERVERRC="$XDG_CONFIG_HOME"/X11/xserverrc
export XINITRC="$XDG_CONFIG_HOME"/X11/xinitrc
export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc
export PASSWORD_STORE_DIR="$XDG_DATA_HOME"/pass
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc

# Setup PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$FLUTTER_HOME/bin:$PATH
export PATH="$PATH:/usr/lib/w3m:$HOME/.local/bin:$HOME/.gem/ruby/2.7.0/bin:$GOPATH/bin:$GOPATH/binexport"
export CPATH=/usr/include/opencv4

# Setup LF Icons (Doing this everytime lf start might cause some overhead)
LF_ICONS=$(sed ~/.config/lf/diricons \
            -e '/^[ \t]*#/d'       \
            -e '/^[ \t]*$/d'       \
            -e 's/[ \t]\+/=/g'     \
            -e 's/$/ /')
LF_ICONS=${LF_ICONS//$'\n'/:}

export LF_ICONS

# Setup dbus
case "$(readlink -f /sbin/init)" in
	*systemd*) export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus ;;
esac

# Setup SSH
if [ ! "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent | head -n 2)"
  grep -slR "PRIVATE" ~/.ssh/ | xargs ssh-add > /dev/null 2> /dev/null
fi

# Start xinit if logged in from tty1
if [ "$DISPLAY" = "" ] && [ "$(tty)" = /dev/tty1 ]; then
  if [ "$DBUS_SESSION_BUS_ADDRESS" = "" ] && [ ! $(command -v dbus-run-session)  = "" ]; then
    # exec dbus-run-session xinit 2> $XDG_RUNTIME_DIR/xinit.err > $XDG_RUNTIME_DIR/xinit
    exec xinit 2> $XDG_RUNTIME_DIR/xinit.err > $XDG_RUNTIME_DIR/xinit
  else
    exec xinit 2> $XDG_RUNTIME_DIR/xinit.err > $XDG_RUNTIME_DIR/xinit
  fi
  exit
fi
