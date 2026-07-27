#!/usr/bin/env bash

POPUP="$1"

if eww active-windows | grep -q "${POPUP}_popup"; then
  eww close "${POPUP}_popup"
  exit
fi

case "$POPUP" in
wifi) ~/.config/eww/panel/scripts/networkctl.sh toggle ;;
bluetooth) ~/.config/eww/panel/scripts/bluetoothctl.sh toggle ;;
esac
