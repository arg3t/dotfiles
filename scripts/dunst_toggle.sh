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
  notify-send "DUNST_COMMAND_PAUSE";
}
end_dnd() {
  notify-send "DUNST_COMMAND_RESUME";
  notify-send "Do Not Disturb" "Do Not Disturb mode ended. Notifications will be shown.";
}
main() {
  getargs "$@";
  [[ "$start" ]] && start_dnd;
  [[ "$end" ]] && end_dnd;
}
main "$@"
