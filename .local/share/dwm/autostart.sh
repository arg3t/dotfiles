#!/bin/bash -x

function restart_if_fails(){
    until bash -c "$1"; do
        echo "$1 exited with code $?. Restarting in 1 second..."
        sleep 1
    done &
}

~/.local/bin/daily-update

dwmblocks > $XDG_RUNTIME_DIR/dwmblocks.out 2> $XDG_RUNTIME_DIR/dwmblocks.err &

restart_if_fails "clipmenud > $XDG_RUNTIME_DIR/clipmenud.out 2> $XDG_RUNTIME_DIR/clipmenud.err"
darkhttpd $HOME/.local/share/startpage/dist --port 9999 --daemon --addr 127.0.0.1

restart_if_fails dunst
restart_if_fails "xbanish"

# Start emacs
# restart_if_fails "emacs --daemon && emacsclient -c --eval \"(delete-frame)\""

~/.local/bin/firefox-sync &
if [ "$ACTIVITYWATCHER" = true ] ; then
    pkill -f aw-watcher-window
    pkill -f aw-watcher-afk
    pkill -f aw-server
    aw-server &
    aw-watcher-window &
    aw-watcher-afk &
fi

# Only run these if we are not in a VNC session
if ! xpdyinfo | grep -q VNC ; then
  redshift -x 2> /dev/null > /dev/null
  redshift -r -l "$LATLONG" > /dev/null 2> /dev/null &

  if [ "$SPOTIFYD" = true ] ; then
      spotifyd
  fi

  ~/.local/bin/devmon --exec-on-drive "notify-send -a '禍  drive mounted' '%l (%f) at %d '" \
      --exec-on-remove "notify-send -a '禍  drive removed' '%l (%f) from %d '" \
      --exec-on-unmount  "notify-send -a '禍  drive unmounted' '%l (%f) from %d '" \
      --no-unmount --no-gui &

  ~/.local/bin/keyboard > $XDG_RUNTIME_DIR/keyboard.out 2> $XDG_RUNTIME_DIR/keyboard.err &


  touch ~/.cache/nextcloud-track
  restart_if_fails "xss-lock -- slock"

  ~/.local/bin/mailsync &

  for i in $XDG_CONFIG_HOME/goimapnotify/*; do
      m="$(echo "$i" | sed "s/.*\///g")"
      restart_if_fails "goimapnotify -conf $i > $XDG_RUNTIME_DIR/$m.watch.out 2> $XDG_RUNTIME_DIR/$m.watch.err"
  done

  if [ "$NEXTCLOUD" = true ] ; then
    nextcloud --background &
  fi

  mkdir -p ~/Downloads/neomutt
  if [ "$MCONNECT" = true ] ; then
      mkdir -p ~/Downloads/mconnect
      (cd ~/Downloads/mconnect; restart_if_fails "mconnect -d > $XDG_RUNTIME_DIR/mconnect 2> $XDG_RUNTIME_DIR/mconnect.err")
  fi

  restart_if_fails "picom --no-fading-openclose"

  mpd
  restart_if_fails mpDris2

  curl 'http://yeetclock/setcolor?R=136&G=192&B=208' &
fi
