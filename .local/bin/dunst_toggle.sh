#!/bin/bash

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
  notify-send -r 52 -a "󰂚 Notifications" "Switching to do not disturb"
  sleep 0.5
  makoctl mode -s dnd
}

end_dnd() {
  makoctl mode -r dnd
  sleep 0.5
  notify-send -r 52 -a "󰂛 Notifications" "Turning off do not disturb"
}

toggle_dnd() {
  if [ "$(makoctl mode)" = "dnd" ]; then
    end_dnd
  else
    start_dnd
  fi
}

main() {
  getargs "$@";
  [[ "$start" ]] && start_dnd;
  [[ "$end" ]] && end_dnd;
  [[ "$toggle" ]] && toggle_dnd;
  /bin/kill -SIGRTMIN+11 $(pgrep waybar)
}
main "$@"
