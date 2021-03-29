#!/bin/sh
extern=HDMI1

if xrandr | grep -v "$extern disconnected"; then
    xrandr --output eDP1 --mode 1920x1080 --pos 0x0 --rotate normal --output DP1 --off --output HDMI1 --primary --mode 1920x1080 --pos 1920x0 --rotate normal --output HDMI2 --off --output VIRTUAL1 --off
fi
