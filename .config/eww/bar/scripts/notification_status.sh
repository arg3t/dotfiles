#!/usr/bin/env bash

MODES=$(makoctl mode 2>/dev/null || echo "")
LIST=$(makoctl list -j 2>/dev/null || echo '[]')
TOTAL_NOTIF=$(echo "$LIST" | jq 'if type=="array" then (if (.[0]|type)=="array" then ([.[]|length]|add) else length end) else (.data[0]|length) end' 2>/dev/null)
[ -z "$TOTAL_NOTIF" ] || [ "$TOTAL_NOTIF" = "null" ] && TOTAL_NOTIF=0

if echo "$MODES" | grep -qx "dnd"; then
  echo '{"icon": "󰂛", "class": "dnd", "count": '"$TOTAL_NOTIF"'}'
else
  if [ "$TOTAL_NOTIF" -gt 0 ]; then
    echo '{"icon": "󰂟", "class": "has-notif", "count": '"$TOTAL_NOTIF"'}'
  else
    echo '{"icon": "", "class": "empty", "count": 0}'
  fi
fi
