#!/bin/bash

pkill -f aw-watcher-window 
pkill -f aw-watcher-afk
pkill -f aw-server 
pkill -f clipmenud 
pkill -f "bash /sbin/clipmenud" 
pkill -f "/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh"
pkill -f "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

clipmenud > /tmp/clipmenud.out 2> /tmp/clipmenud.err &
eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK
rm -f ~/.surf/tabbed-surf.xid
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
feh --bg-fill /home/yigit/Pictures/Wallpapers/ocean-cliff.jpg #Backgroun
xrdb  ~/.Xresources &
dwmblocks > /tmp/dwmblocks.out 2> /tmp/dwmblocks.err & 
setxkbmap us -variant altgr-intl -options caps:nocaps
nextcloud --background &
xss-lock -- betterlockscreen -l -t 'Stay the fuck out!' & 
aw-server &
aw-watcher-window &
aw-watcher-afk &
dbus-update-activation-environment --systemd DISPLAY
if [ -f ~/.xmodmap ]; then
   xmodmap ~/.xmodmap
fi
picom --no-fading-openclose &
