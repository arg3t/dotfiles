#!/usr/bin/env bash
# Pane `jt.command-palette.palette`: the interactive fzf picker.
#
# Runs inside an overlay pane (real TTY). Lists every action from every installed
# plugin, lets the user fuzzy-pick one, and invokes it. When this script exits the
# overlay closes on its own.
set -uo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
self_plugin="${HERDR_PLUGIN_ID:-jt.command-palette}"

# Brief pause + message helper so failures don't vanish when the overlay closes.
die() {
  printf '%s\n' "$*" >&2
  printf 'Press any key to close…' >&2
  read -r -n1 _ 2>/dev/null || sleep 2
  exit 1
}

command -v fzf >/dev/null 2>&1 || die "command-palette: fzf is not installed or not on PATH."
command -v jq  >/dev/null 2>&1 || die "command-palette: jq is not installed or not on PATH."

# Each line: "<plugin_id>.<action_id>\t<plugin_id>.<action_id> <title>"
# Field 1 is the fully-qualified id we invoke; field 2 is what fzf displays.
# We hide our own plugin's actions (opening the palette from the palette is noise).
lines="$(
  "$herdr_bin" plugin action list 2>/dev/null \
    | jq -r --arg self "$self_plugin" '
        .result.actions[]
        | select(.plugin_id != $self)
        | (.plugin_id + "." + .action_id) as $qid
        | [ $qid, ($qid + " " + .title) ]
        | @tsv
      ' 2>/dev/null \
    | sort -t$'\t' -k2,2
)"

[ -n "$lines" ] || die "command-palette: no plugin actions available."

# fzf: display only field 2, but match against the whole line (so typing a plugin
# id works too). Esc/Ctrl-C abort → empty selection → silent close.
choice="$(
  printf '%s\n' "$lines" \
    | fzf --delimiter=$'\t' \
          --with-nth=2 \
          --prompt='herdr action ▸ ' \
          --header='↑↓ select · enter run · esc cancel' \
          --reverse \
          --cycle \
          --no-multi \
          --no-sort
)" || true

[ -n "$choice" ] || exit 0

action_id="${choice%%$'\t'*}"

# Invoke the action. `herdr plugin action invoke` is fire-and-forget: it returns
# as soon as the action is DISPATCHED, so a zero exit only means "accepted" — the
# action's command can still fail afterwards (e.g. a moved/missing script exits
# 127). The response carries the dispatched run's log_id; we poll the plugin log
# until it reaches a terminal state so a failed action surfaces its error instead
# of the overlay vanishing on a silent no-op.
resp="$("$herdr_bin" plugin action invoke "$action_id" 2>&1)"
if [ $? -ne 0 ]; then
  die "command-palette: failed to invoke ${action_id}
${resp}"
fi

# Pull the run's log_id and owning plugin straight from the invoke response (the
# plugin_id is taken from the response rather than split off the action_id, which
# can itself contain dots, e.g. jt.command-palette). If the response isn't the
# shape we expect (older herdr), skip polling and exit cleanly — never make a
# working invoke look broken.
log_id="$(printf '%s' "$resp" | jq -r '.result.log.log_id // empty' 2>/dev/null)"
plugin_id="$(printf '%s' "$resp" | jq -r '.result.log.plugin_id // empty' 2>/dev/null)"
[ -n "$log_id" ] && [ -n "$plugin_id" ] || exit 0

# Poll that run's log entry until it finishes (or we hit the deadline). Most
# actions complete in well under a second; one still "running" at the deadline is
# assumed to be a healthy long-running action and left alone.
i=0
while [ "$i" -lt 25 ]; do  # ~5s at 0.2s/iteration
  i=$((i + 1))
  entry="$(
    "$herdr_bin" plugin log list --plugin "$plugin_id" --limit 20 2>/dev/null \
      | jq -c --arg id "$log_id" '.result.logs[]? | select(.log_id == $id)' 2>/dev/null
  )"
  case "$(printf '%s' "$entry" | jq -r '.status // empty' 2>/dev/null)" in
    succeeded) exit 0 ;;
    failed)
      code="$(printf '%s' "$entry" | jq -r '.exit_code // "?"' 2>/dev/null)"
      err="$(printf '%s' "$entry" | jq -r '.stderr // empty' 2>/dev/null)"
      die "command-palette: ${action_id} failed (exit ${code})
${err}"
      ;;
  esac
  sleep 0.2
done
