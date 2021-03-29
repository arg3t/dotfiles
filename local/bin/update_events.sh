#!/bin/sh

echo $((($(khal list -f \"{uid}\" | wc -l) - 1))) > /home/yigit/.cache/events
