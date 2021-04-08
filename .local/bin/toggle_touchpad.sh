#!/bin/sh
if xinput list-props "MSFT0001:00 06CB:7E7E Touchpad" | grep "Device Enabled ([0-9]*):.*1" >/dev/null
then
  xinput disable "MSFT0001:00 06CB:7E7E Touchpad"
  notify-send -u low -i mouse "Trackpad disabled"
else
  xinput enable "MSFT0001:00 06CB:7E7E Touchpad"
  notify-send -u low -i mouse "Trackpad enabled"
fi
