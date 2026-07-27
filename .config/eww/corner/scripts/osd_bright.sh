#!/usr/bin/env bash

EWW="eww"
LOCK_FILE="/tmp/eww_osd.pid"

update_brightness() {
  BRIGHTNESS=$(brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}')

  if [ -z "$BRIGHTNESS" ] || [ "$BRIGHTNESS" -eq 0 ]; then
    BRIGHTNESS=0
  fi

  $EWW update osd_icon="󰖨"
  $EWW update osd_type="brightness"
  $EWW update osd_value="$BRIGHTNESS"

  if [ ! -f "$LOCK_FILE" ] || ! kill -0 $(cat "$LOCK_FILE" 2>/dev/null) 2>/dev/null; then
    $EWW open window_osd
  fi

  if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    kill "$PID" 2>/dev/null
    rm -f "$LOCK_FILE"
  fi

  (
    sleep 2
    $EWW close window_osd
    rm -f "$LOCK_FILE"
  ) &

  echo $! >"$LOCK_FILE"
}

case "$1" in
bright-up) brightnessctl -e4 -n2 set +5% && update_brightness ;;
bright-down) brightnessctl -e4 -n2 set 5%- && update_brightness ;;
esac
