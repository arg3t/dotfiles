#!/usr/bin/env bash

get_bt_json() {
  BLOCKED=$(rfkill list bluetooth | grep -i "soft blocked" | awk '{print $3}')
  STATUS="disconnected"
  DEVICE="Off"
  ICON="󰂲"
  if [ "$BLOCKED" = "no" ]; then
    STATUS="not-connected"
    DEVICE="Not Connected"
    ICON="󰂯"
    CONNECTED_DEV=$(bluetoothctl devices Connected | awk '{print substr($0, index($0,$3))}')
    if [ -n "$CONNECTED_DEV" ]; then
      STATUS="connected"
      DEVICE="$CONNECTED_DEV"
      ICON="󰂱"
    fi
  fi
  printf '{"status": "%s", "device": "%s", "icon": "%s"}\n' "$STATUS" "$DEVICE" "$ICON"
}

if [ "$1" = "toggle" ]; then
  BLOCKED=$(rfkill list bluetooth | grep -i "soft blocked" | awk '{print $3}')
  if [ "$BLOCKED" = "yes" ]; then
    rfkill unblock bluetooth
  else
    rfkill block bluetooth
  fi
  exit 0
fi

get_bt_json

dbus-monitor --system \
  "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" \
  "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesAdded'" \
  "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesRemoved'" \
  2>/dev/null |
  while read -r line; do
    if echo "$line" | grep -qE "org.bluez|Powered|Connected"; then
      sleep 0.1
      get_bt_json
    fi
  done
