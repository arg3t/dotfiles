#!/usr/bin/env bash

scan_wifi() {
  LIST=$(
    nmcli -t -f SSID,SIGNAL,SECURITY dev wifi |
      awk -F: '
    NF && $1 != "" {
    secure = ($3 != "--") ? "true" : "false"
    icon="󰤯"
    if ($2 < 25)
    icon="󰤟"
    else if ($2 < 50)
    icon="󰤢"
    else if ($2 < 75)
    icon="󰤥"
    else
    icon="󰤥"
    printf "{\"ssid\":\"%s\",\"icon\":\"%s\",\"secure\":%s},", \
    $1, icon, secure
    }' | sed 's/,$//'
  )

  eww update wifi_list="[$LIST]"
}

toggle_wifi() {
  eww open wifi_popup
  scan_wifi &
}

case "$1" in
scan) scan_wifi ;;
toggle) toggle_wifi ;;
esac
