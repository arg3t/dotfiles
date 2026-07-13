#!/usr/bin/env bash
case "$1" in
p-shutdown) systemctl poweroff ;;
p-reboot) systemctl reboot ;;
p-suspend)
  (sleep 0.5 && systemctl suspend) &
  hyprlock --immediate-render
  ;;
p-logout) hyprctl dispatch exit ;;
esac
