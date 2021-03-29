#!/bin/sh

# pacontrol.sh
#
# This script changes the volume of the current audio source based on a set interval

function send_notification {


    if [ "$2" = "yes" ]; then
        icon="婢"
        dunstify -t 1000 -r 53 -a "蓼 Volume" "$icon MUTED"
        return
    else
        if [  "$1" -lt "20" ]; then
            icon="奄"
        else
            if [ "$1" -lt "60" ]; then
                icon="奔"
            else
                icon="墳"
            fi
        fi
    fi
    bar=$(seq -s "─" $(($1/5)) | sed 's/[0-9]//g')
    empty=$(seq -s " ⁠" $((20 - $1/5)) | sed 's/[0-9]//g')
    dunstify -t 1000 -r 53 -a "蓼 Volume" "$icon $bar$empty"
}

usage() {
    echo "Usage: pacontrol.sh [up|down|toggle-mute]"
}

vol_interval=5
sinks=$(pactl list short sinks | cut -c 1)
latest_sink=${sinks[*]: -1}

SINK=$(pactl list short sinks | grep -n RUNNING | cut -d":"  -f1)
if [ "$SINK" = "" ]; then
  SINK=1
fi
NOW=$(pactl list sinks | grep '^[[:space:]]Volume:' | head -n $SINK | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,' )
MUTE=$(pactl list sinks | grep '^[[:space:]]Mute:'| head -n $SINK | tail -n 1 | awk -F ":" '{print $2}'| xargs)

case $1 in
    "up")
        pactl set-sink-mute $latest_sink 0
        if [ "$NOW" -lt "100" ]; then
            pactl set-sink-volume $latest_sink +$vol_interval%
        else
            pactl set-sink-volume $latest_sink 100%
        fi
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
    "close-mute")
        pactl set-sink-mute $latest_sink 0
        ;;
    *) usage ;;
esac
NOW=$(pactl list sinks | grep '^[[:space:]]Volume:' | head -n $SINK | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,' )
MUTE=$(pactl list sinks | grep '^[[:space:]]Mute:'| head -n $SINK | tail -n 1 | awk -F ":" '{print $2}'| xargs)

kill -48 $(pidof dwmblocks)
send_notification $NOW $MUTE
