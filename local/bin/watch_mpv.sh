#!/bin/sh
format="-f34" # leave empty for default
player="mpv --quiet --geometry=50%:50% --idx --keep-open"
tmpdir="/tmp"

url="$1"
echo $url
echo $format
mpv $url
exit 0
filepath="$tmpdir/$(youtube-dl --id --get-filename $format $url)"

youtube-dl -c -o $filepath $format $url &
echo $! > $filepath.$$.pid

while [ ! -r $filepath ] && [ ! -r $filepath.part ]; do 
    echo "Waiting for youtube-dl..."
      sleep 3
    done

    [ -r $filepath.part ] && $player $filepath.part || $player $filepath
    kill $(cat $filepath.$$.pid)
    rm $filepath.$$.pid
