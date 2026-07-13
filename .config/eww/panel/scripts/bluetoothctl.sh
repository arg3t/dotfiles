#!/usr/bin/env bash

scan_bluetooth() {
  CONNECTED_MACS=$(bluetoothctl devices Connected | awk '{print $2}')

  PAIRED=$(
    bluetoothctl devices Paired |
      awk -v connected="$CONNECTED_MACS" '
      BEGIN {
        n = split(connected, arr, "\n")
        for (i = 1; i <= n; i++) is_connected[arr[i]] = 1
      }
      {
        mac = $2
        name = $0
        sub(/^Device [^ ]+ /, "", name)
        conn = (mac in is_connected) ? "true" : "false"
        icon = (conn == "true") ? "󰂱" : "󰂯"
        printf "{\"name\":\"%s\",\"icon\":\"%s\",\"connected\":%s},", name, icon, conn
      }'
  )

  LIST=$(echo "$PAIRED" | sed 's/,$//')
  eww update bluetooth_list="[$LIST]"

  bluetoothctl --timeout 2 scan on >/dev/null 2>&1

  NEARBY=$(
    bluetoothctl devices |
      awk -v paired="$(bluetoothctl devices Paired | awk '{print $2}')" '
      BEGIN {
        n = split(paired, arr, "\n")
        for (i = 1; i <= n; i++) is_paired[arr[i]] = 1
      }
      {
        mac = $2
        name = $0
        sub(/^Device [^ ]+ /, "", name)
        if (!(mac in is_paired)) {
          printf "{\"name\":\"%s\",\"icon\":\"󰂯\",\"connected\":false},", name
        }
      }'
  )

  LIST="${PAIRED}${NEARBY}"
  LIST=$(echo "$LIST" | sed 's/,$//')
  eww update bluetooth_list="[$LIST]"
}

toggle_bluetooth() {
  scan_bluetooth &
  eww open bluetooth_popup
}

case "$1" in
scan) scan_bluetooth ;;
toggle) toggle_bluetooth ;;
esac
