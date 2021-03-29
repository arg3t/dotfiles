#!/bin/bash

# Environment variables
export QT_QPA_PLATFORMTHEME="qt5ct"
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT=MToolkit
export SHELL=/bin/zsh
export TERMINAL=/usr/local/bin/st
export TMUX_PLUGIN_MANAGER_PATH=~/.tmux/plugins
export BORG_KEYS_DIR=~/.keys/borg
export BROWSER="/home/yigit/.local/bin/brave-start"
export EDITOR=vim
export ANDROID_HOME=/home/yigit/Android
export DEFAULT_RECIPIENT="yigitcolakoglu@hotmail.com"

# Setup PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$FLUTTER_HOME/bin:$PATH
export PATH="$PATH:/home/yigit/.local/bin:/home/yigit/.gem/ruby/2.7.0/bin:$GOPATH/bin:$GOPATH/binexport:/home/yigit/.local/bin"
export CPATH=/usr/include/opencv4

# Set XDG Directories
export XDG_DATA_HOME="$HOME"/.local/share
export XDG_CONFIG_HOME="$HOME"/.config
export XDG_CACHE_HOME="$HOME"/.cache
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS="/etc/xdg"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
export XDG_RUNTIME_DIR="/run/user/1000"

# LF Icons
LF_ICONS=$(sed ~/.config/lf/diricons \
            -e '/^[ \t]*#/d'       \
            -e '/^[ \t]*$/d'       \
            -e 's/[ \t]\+/=/g'     \
            -e 's/$/ /')
LF_ICONS=${LF_ICONS//$'\n'/:}

export LF_ICONS

# Cleanup Home Directory
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export GOPATH="$XDG_DATA_HOME"/go
export ANDROID_HOME="$XDG_DATA_HOME"/Sdk
export FLUTTER_HOME="$XDG_DATA_HOME"/flutter
export LEIN_HOME="$XDG_DATA_HOME"/lein
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NVM_DIR="$XDG_DATA_HOME"/nvm
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export MBSYNCRC="$XDG_CONFIG_HOME"/isync/mbsyncrc
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
