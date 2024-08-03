#!/bin/bash

function restart_if_fails(){
    until bash -c "$1"; do
        echo "$1 exited with code $?. Restarting in 1 second..."
        sleep 1
    done &
}

# Set up monitors
if [ -f "$HOME/.config/X11/xconfig.sh" ]; then
  $HOME/.config/X11/xconfig.sh
fi

~/.local/bin/daily-update

dwmblocks > $XDG_RUNTIME_DIR/dwmblocks.out 2> $XDG_RUNTIME_DIR/dwmblocks.err &

restart_if_fails "clipmenud > $XDG_RUNTIME_DIR/clipmenud.out 2> $XDG_RUNTIME_DIR/clipmenud.err"

restart_if_fails dunst
restart_if_fails "xbanish"

# Start emacs
# restart_if_fails "emacs --daemon && emacsclient -c --eval \"(delete-frame)\""

# ~/.local/bin/firefox-sync &
if [ "$ACTIVITYWATCHER" = true ] ; then
    pkill -f aw-watcher-window
    pkill -f aw-watcher-afk
    pkill -f aw-server
    aw-server &
    aw-watcher-window &
    aw-watcher-afk &
fi

if [ "$ARIA2C" = true ] ; then
  restart_if_fails "aria2c --async-dns=false --enable-rpc --rpc-secret '$ARIA2C_SECRET'"
fi

# Only run these if we are not in a VNC session
if ! xdpyinfo | grep -q VNC ; then
  redshift -x 2> /dev/null > /dev/null
  if [ $(hostnamectl hostname) = "tarnag" ]; then
    redshift -r -l "$LATLONG" -g 1.1:1.1:1.1 > /dev/null 2> /dev/null &
  else
    redshift -r -l "$LATLONG" > /dev/null 2> /dev/null &
  fi

  if [ "$SPOTIFYD" = true ] ; then
      spotifyd
  fi

  ~/.local/bin/devmon --exec-on-drive "notify-send -a '禍  drive mounted' '%l (%f) at %d '" \
      --exec-on-remove "notify-send -a '禍  drive removed' '%l (%f) from %d '" \
      --exec-on-unmount  "notify-send -a '禍  drive unmounted' '%l (%f) from %d '" \
      --no-unmount --no-gui &

  ~/.local/bin/keyboard > $XDG_RUNTIME_DIR/keyboard.out 2> $XDG_RUNTIME_DIR/keyboard.err &

  restart_if_fails "xss-lock -- slock"

  restart_if_fails "picom --no-fading-openclose"

  restart_if_fails "xfce4-power-manager"

  if [ -f "$XDG_DATA_HOME/dwm/machine_specific.sh" ]; then
    "$XDG_DATA_HOME/dwm/machine_specific.sh"
  fi
fi
