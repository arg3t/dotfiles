#!/usr/bin/env bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

BAT_DIR=""

for d in /sys/class/power_supply/BAT* /sys/class/power_supply/battery*; do
  if [ -d "$d" ]; then
    BAT_DIR="$d"
    break
  fi
done

if [ -z "$BAT_DIR" ]; then
  echo '{"icon":"󰚥","percent":100,"status":"AC","time":"N/A"}'
  exit 0
fi

PER=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo 100)
STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")

TIME="--:--"

if [ "$STATUS" != "Full" ]; then

  CUR=$(cat "$BAT_DIR/energy_now" 2>/dev/null ||
    cat "$BAT_DIR/charge_now" 2>/dev/null ||
    echo 0)

  RATE=$(cat "$BAT_DIR/power_now" 2>/dev/null ||
    cat "$BAT_DIR/current_now" 2>/dev/null ||
    echo 0)

  if [ "$RATE" -gt 0 ]; then
    SECS=$((CUR * 3600 / RATE))

    H=$((SECS / 3600))
    M=$(((SECS % 3600) / 60))

    TIME=$(printf "%02dh %02dm" $H $M)
  fi
fi

LOCK_LOW="/tmp/eww_battery_low"
LOCK_CRIT="/tmp/eww_battery_critical"
LOCK_FULL="/tmp/eww_battery_full"

if [ "$STATUS" = "Discharging" ]; then

  rm -f "$LOCK_FULL"

  if [ "$PER" -le 15 ]; then

    if [ ! -f "$LOCK_CRIT" ]; then
      notify-send \
        -u critical \
        -i battery-caution \
        "Battery Critical" \
        "Battery left $PER% ($TIME)"

      touch "$LOCK_CRIT"
    fi

  elif [ "$PER" -le 25 ]; then

    if [ ! -f "$LOCK_LOW" ]; then
      notify-send \
        -u normal \
        -i battery-low \
        "Battery Low" \
        "Battery left $PER% ($TIME)"

      touch "$LOCK_LOW"
    fi
  fi

else

  if [ "$PER" -gt 25 ]; then
    rm -f "$LOCK_LOW"
    rm -f "$LOCK_CRIT"
  fi

  if [ "$PER" -eq 100 ] || [ "$STATUS" = "Full" ]; then

    if [ ! -f "$LOCK_FULL" ]; then
      notify-send \
        -u low \
        -i battery-full-charged \
        "Battery Full" \
        "Take it out, boss, so it doesn't explode."

      touch "$LOCK_FULL"
    fi
  fi
fi

if [ "$STATUS" = "Charging" ]; then

  ICON="󱐌"

elif [ "$STATUS" = "Full" ] || [ "$STATUS" = "AC" ]; then

  ICON="󰁹"

else

  if [ "$PER" -lt 10 ]; then
    ICON="󰁺"

  elif [ "$PER" -lt 20 ]; then
    ICON="󰁻"

  elif [ "$PER" -lt 30 ]; then
    ICON="󰁼"

  elif [ "$PER" -lt 40 ]; then
    ICON="󰁽"

  elif [ "$PER" -lt 50 ]; then
    ICON="󰁾"

  elif [ "$PER" -lt 60 ]; then
    ICON="󰁿"

  elif [ "$PER" -lt 70 ]; then
    ICON="󰂀"

  elif [ "$PER" -lt 80 ]; then
    ICON="󰂁"

  elif [ "$PER" -lt 90 ]; then
    ICON="󰂂"

  else
    ICON="󰁹"
  fi
fi

printf \
  '{"icon":"%s","percent":%d,"status":"%s","time":"%s"}\n' \
  "$ICON" \
  "$PER" \
  "$STATUS" \
  "$TIME"
