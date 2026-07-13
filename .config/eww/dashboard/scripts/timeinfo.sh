#!/usr/bin/env bash
BIRTH=$(stat -c %W /)
if [ "$BIRTH" -le 0 ]; then
  DAYS=0
else
  NOW=$(date +%s)
  DAYS=$(((NOW - BIRTH) / 86400))
fi

UPTIME=$(uptime -p | sed 's/up //')
HOURS=$(echo "$UPTIME" | grep -oP '\d+ hours?' | sed 's/ hours\?/ hours/')
MINUTES=$(echo "$UPTIME" | grep -oP '\d+ minutes?' | sed 's/ minutes\?/ minutes/')

echo "{\"days\": $DAYS, \"hours\": \"${HOURS:-0 h}\", \"minutes\": \"${MINUTES:-0 m}\"}"
