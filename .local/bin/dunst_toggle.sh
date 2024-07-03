#!/bin/zsh
#
getargs() {
  while getopts "set" opt
  do
    case $opt in
      s) start="true";;
      e) end="true";;
      t) toggle="true";;
    esac
  done
}

start_dnd() {
  dunstify -r 52 -a "󰂚 Notifications" "Switching to do not disturb"
  sleep 0.5
  dunstctl set-paused true
}

end_dnd() {
  dunstctl set-paused false
  dunstify -r 52 -a "󰂛 Notifications" "Turning off do not disturb"
}

toggle_dnd() {
  if [ $(dunstctl is-paused) = "false" ]; then
    start_dnd
  else
    end_dnd
  fi
}

main() {
  getargs "$@";
  [[ "$start" ]] && start_dnd;
  [[ "$end" ]] && end_dnd;
  [[ "$toggle" ]] && toggle_dnd;
  kill -52 $(pidof dwmblocks)
}
main "$@"
