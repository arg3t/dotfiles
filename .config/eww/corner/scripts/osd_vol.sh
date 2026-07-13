#!/usr/bin/env bash

EWW="eww"
LOCK_FILE="/tmp/eww_osd.pid"

update_volume() {
  VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | tr -d '\n' | awk '{print $2 * 100}')

  if [ -z "$VOLUME" ] || [ "$VOLUME" -eq 0 ]; then
    VOLUME=0
  fi

  $EWW update osd_icon=""
  $EWW update osd_type="volume"
  $EWW update osd_value="$VOLUME"

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
vol-up) wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && update_volume ;;
vol-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && update_volume ;;
esac
