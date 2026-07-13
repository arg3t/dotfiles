#!/usr/bin/env bash

NAME="$1"

if [ -z "$NAME" ]; then
  exit 1
fi

MAC=$(
  bluetoothctl devices |
    awk -v name="$NAME" '
      {
        mac = $2
        $1 = ""; $2 = ""
        sub(/^  */, "")
        if ($0 == name) {
          print mac
          exit
        }
      }
    '
)

if [ -z "$MAC" ]; then
  exit 1
fi

if ! bluetoothctl info "$MAC" | grep -q "Paired: yes"; then
  bluetoothctl pair "$MAC" >/dev/null 2>&1
  bluetoothctl trust "$MAC" >/dev/null 2>&1
fi

bluetoothctl connect "$MAC"

eww close bluetooth_popup
