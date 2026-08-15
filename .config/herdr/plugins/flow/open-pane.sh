#!/usr/bin/env bash
# Open a flow popup pane with a real TTY (mirrors workstream/open-pane.sh).
# Keybound actions run on the herdr server without a TTY, so interactive
# pickers open here instead.
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
  --plugin flow \
  --entrypoint "$entrypoint" \
  --placement "$placement" \
  --focus

if [ -n "$repo" ] && [ -d "$repo" ]; then
  set -- "$@" --cwd "$repo"
fi

exec "$herdr_bin" "$@"
