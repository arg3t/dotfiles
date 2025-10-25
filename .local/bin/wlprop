#!/usr/bin/env sh

# wlprop
# Get window properties in Hyprland

# Dependencies
cmd_failures=''
for cmd in hyprctl jq slurp; do
  command -v "${cmd}" >/dev/null 2>&1 || cmd_failures="${cmd_failures},${cmd}"
done

if (( "${#cmd_failures}" > 0 )); then
  printf -- '%s\n' "The following dependencies are missing: ${cmd_failures/,/}" >&2
  exit 1
fi

# Get all clients and selection (point) region via slurp
TREE=$(hyprctl clients -j | jq -r '.[] | select(.hidden==false and .mapped==true)')
SELECTION=$(echo $TREE | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -r)

# Get individual coordinates
X=$(echo $SELECTION | awk -F'[, x]' '{print $1}')
Y=$(echo $SELECTION | awk -F'[, x]' '{print $2}')
W=$(echo $SELECTION | awk -F'[, x]' '{print $3}')
H=$(echo $SELECTION | awk -F'[, x]' '{print $4}')

echo $TREE | jq -r --argjson x $X --argjson y $Y --argjson w $W --argjson h $H '. | select(.at[0]==$x and .at[1]==$y and .size[0]==$w and.size[1]==$h)'
