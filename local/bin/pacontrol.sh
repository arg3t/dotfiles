#!/bin/sh

# pacontrol.sh
#
# This script changes the volume of the current audio source based on a set interval

usage() {
    echo "Usage: pacontrol.sh [up|down|toggle-mute]"
}

vol_interval=10
sinks=$(pactl list short sinks | cut -c 1)
latest_sink=${sinks[*]: -1}

case $1 in
    "up")
        pactl set-sink-mute $latest_sink 0
        pactl set-sink-volume $latest_sink +$vol_interval%
        ;;
    "down")
        pactl set-sink-volume $latest_sink -$vol_interval%
        ;;
    "toggle-mute") 
        pactl set-sink-mute $latest_sink toggle
        ;;
    "open-mute") 
        pactl set-sink-mute $latest_sink 1
        ;;
    *) usage ;;
esac

kill -48 $(pidof dwmblocks)
