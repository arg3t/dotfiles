#!/usr/bin/env bash

CURRENT=$(powerprofilesctl get | tr -d '[:space:]')

if [ "$CURRENT" = "performance" ]; then
  powerprofilesctl set power-saver 2>/dev/null
  eww update power_profile="power-saver"
elif [ "$CURRENT" = "power-saver" ]; then
  powerprofilesctl set balanced 2>/dev/null
  eww update power_profile="balanced"
else
  powerprofilesctl set performance 2>/dev/null
  eww update power_profile="performance"
fi
