#!/usr/bin/env bash

SSID="$1"
SECURE="$2"

if [ "$SECURE" = "true" ]; then
  PASSWORD=""

  # rofi
  if type rofi >/dev/null 2>&1; then
    if [ -f "$HOME/.config/rofi/password.rasi" ]; then
      PASSWORD=$(rofi -dmenu -password -p "$SSID" -theme ~/.config/rofi/password.rasi)
    else
      PASSWORD=$(
        rofi -dmenu \
          -password \
          -p "$SSID"
      )
    fi

    # fuzzel fallback
  elif type fuzzel >/dev/null 2>&1; then
    PASSWORD=$(fuzzel --dmenu --password --prompt="$SSID: " --lines=0)

    # wofi fallback
  elif type wofi >/dev/null 2>&1; then
    PASSWORD=$(wofi --dmenu --password --prompt="$SSID" --lines=0 --width=300)

  else
    echo "Error: rofi, fuzzel, or wofi not found"
    if type notify-send >/dev/null 2>&1; then
      notify-send -u normal "Wi-Fi Error" "Install rofi, fuzzel, atau wofi for input password!"
    fi
    exit 1
  fi

  [ -z "$PASSWORD" ] && exit 0

  nmcli dev wifi connect "$SSID" password "$PASSWORD"
else
  nmcli dev wifi connect "$SSID"
fi

eww close wifi_popup
