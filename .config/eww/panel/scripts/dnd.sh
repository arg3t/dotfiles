#!/usr/bin/env bash
case "$1" in
status)
  if makoctl mode 2>/dev/null | grep -qx "dnd"; then
    echo "true"
  else
    echo "false"
  fi
  ;;
toggle)
  makoctl mode -t dnd >/dev/null 2>&1
  ;;
esac
