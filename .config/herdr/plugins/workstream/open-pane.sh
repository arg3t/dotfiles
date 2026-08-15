#!/usr/bin/env bash
# Open a workstream popup pane with a real TTY.
#
# Keybound actions run on the herdr server WITHOUT a TTY, so they cannot run
# fzf or read interactive input themselves. Following the command-palette
# pattern, each action calls this script with the name of a [[panes]]
# entrypoint; we open that pane (which gets a terminal) and forward the
# origin workspace's cwd so git/gh/jira commands resolve the right repo.
#
#   open-pane.sh <entrypoint-id> [placement]
set -uo pipefail

entrypoint="${1:?usage: open-pane.sh <entrypoint> [placement]}"
placement="${2:-popup}"

herdr_bin="${HERDR_BIN_PATH:-herdr}"
ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"

repo=""
if [ -n "$ctx" ] && command -v jq >/dev/null 2>&1; then
  repo="$(printf '%s' "$ctx" | jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null || true)"
fi
[ -n "$repo" ] || repo="${HERDR_WORKSPACE_CWD:-}"

set -- plugin pane open \
  --plugin workstream \
  --entrypoint "$entrypoint" \
  --placement "$placement" \
  --focus

if [ -n "$repo" ] && [ -d "$repo" ]; then
  set -- "$@" --cwd "$repo"
fi

exec "$herdr_bin" "$@"
