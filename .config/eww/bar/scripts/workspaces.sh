#!/usr/bin/env bash

if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/$(id -u)/hypr/ | head -1)
fi

generate() {
  ACTIVE=$(hyprctl monitors -j | jq '.[] | select(.focused == true) | .activeWorkspace.id' 2>/dev/null)
  ACTIVE=${ACTIVE:-0}

  OCCUPIED=$(hyprctl workspaces -j | jq -r '.[] | select(.windows > 0) | .id' 2>/dev/null | tr '\n' ' ')

  echo -n '['
  for i in {1..10}; do
    [ "$i" -gt 1 ] && echo -n ','
    if [ "$i" -eq "$ACTIVE" ]; then
      STATE="active"
    elif [[ " $OCCUPIED " =~ " $i " ]]; then
      STATE="occupied"
    else
      STATE="empty"
    fi
    echo -n "{\"id\": $i, \"state\": \"$STATE\"}"
  done
  echo ']'
}

generate

SOCKET_PATH="/run/user/$(id -u)/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ -S "$SOCKET_PATH" ]; then
  nc -U "$SOCKET_PATH" | while read -r line; do
    case ${line%>>*} in
    workspace | focusedmon | destroyworkspace | createworkspace | urgent)
      generate
      ;;
    esac
  done
else
  echo "Error: Hyprland socket not found" >&2
fi
