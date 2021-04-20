#!/bin/sh


~/.local/bin/daily-update

redshift -x 2> /dev/null > /dev/null
redshift -r -l "$LATLONG" > /dev/null 2> /dev/null &

dwmblocks > $XDG_RUNTIME_DIR/dwmblocks.out 2> $XDG_RUNTIME_DIR/dwmblocks.err &

~/.local/bin/keyboard > $XDG_RUNTIME_DIR/keyboard.out 2> $XDG_RUNTIME_DIR/keyboard.err
~/.local/bin/mailsync &

if [ "$NEXTCLOUD" = true ] ; then
  nextcloud --background &
fi
mkdir -p ~/Downloads/neomutt
if [ "$MCONNECT" = true ] ; then
    mkdir -p ~/Downloads/mconnect
    (cd ~/Downloads/mconnect; mconnect -d > $XDG_RUNTIME_DIR/mconnect 2> $XDG_RUNTIME_DIR/mconnect.err &)
fi
if [ "$ACTIVITYWATCHER" = true ] ; then
    pkill -f aw-watcher-window
    pkill -f aw-watcher-afk
    pkill -f aw-server
    aw-server &
    aw-watcher-window &
    aw-watcher-afk &
fi
mpd
mpd-mpris &
touch ~/.cache/nextcloud-track
xss-lock -- slock &
picom --no-fading-openclose &


~/.local/bin/firefox-sync
curl 'http://yeetclock/setcolor?R=136&G=192&B=208' &

dunst &

xbanish -s &


tmux new-session -s weechat -d weechat > /dev/null 2> /dev/null


~/.local/bin/devmon --exec-on-drive "/sbin/notify-send '禍  drive mounted' '%l (%f) at %d '" \
    --exec-on-remove "/sbin/notify-send '禍  drive removed' '%l (%f) from %d '" \
    --exec-on-unmount  "/sbin/notify-send '禍  drive unmounted' '%l (%f) from %d '" \
    --no-unmount --no-gui &

clipmenud > $XDG_RUNTIME_DIR/clipmenud.out 2> $XDG_RUNTIME_DIR/clipmenud.err &
rm -f ~/.surf/tabbed-surf.xid
/bin/polkit-dumb-agent &
