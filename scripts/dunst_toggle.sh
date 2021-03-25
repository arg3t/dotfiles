#!/bin/zsh
getargs() {
  while getopts "se" opt
  do
    case $opt in
      s) start="true";;
      e) end="true";;
    esac
  done
}
start_dnd() {
  echo "off" > ~/.cache/dunst
  dunstctl set-paused false
}
end_dnd() {
  echo "on" > ~/.cache/dunst
  dunstctl set-paused true
  notify-send "Do Not Disturb" "Do Not Disturb mode ended. Notifications will be shown.";
}
main() {
  getargs "$@";
  [[ "$start" ]] && start_dnd;
  [[ "$end" ]] && end_dnd;
  kill -52 $(pidof dwmblocks)
}
main "$@"
