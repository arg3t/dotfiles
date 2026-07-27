#!/usr/bin/env bash

LAST_VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')
LAST_BRIGHT=$(brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}')

echo "{\"volume\": $LAST_VOL, \"brightness\": $LAST_BRIGHT}"

while true; do
  VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}')
  BRIGHT=$(brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}')

  if [[ "$VOL" != "$LAST_VOL" || "$BRIGHT" != "$LAST_BRIGHT" ]]; then
    echo "{\"volume\": $VOL, \"brightness\": $BRIGHT}"
    LAST_VOL=$VOL
    LAST_BRIGHT=$BRIGHT
  fi
  sleep 0.5
done
