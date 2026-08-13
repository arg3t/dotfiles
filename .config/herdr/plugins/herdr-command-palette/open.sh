#!/usr/bin/env bash
# Action `jt.command-palette.open`: open the fzf command-palette overlay.
#
# This runs on the herdr server (no TTY), so it can't run fzf directly. It opens
# the `palette` overlay pane (see herdr-plugin.toml), which gets a real terminal
# and runs palette.sh.
#
# We forward the ORIGIN workspace's cwd to the overlay via `--cwd`. That matters
# because when palette.sh later runs `herdr plugin action invoke <id>`, the server
# resolves the action's context from the focused pane — which is now this overlay.
# Setting the overlay's cwd to the origin repo makes context-aware actions (e.g.
# gitlab-ci-status.open, which reads `.focused_pane_cwd`) resolve the right repo.
set -uo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"

# Resolve the repo/dir the user triggered the palette from.
repo=""
if [ -n "$ctx" ] && command -v jq >/dev/null 2>&1; then
  repo="$(printf '%s' "$ctx" | jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null || true)"
fi
[ -n "$repo" ] || repo="${HERDR_WORKSPACE_CWD:-}"

set -- plugin pane open \
  --plugin jt.command-palette \
  --entrypoint palette \
  --placement overlay \
  --focus

# Only forward --cwd when it's a real directory; otherwise the overlay falls back
# to the plugin root (the pane command uses $HERDR_PLUGIN_ROOT, so it resolves
# either way).
if [ -n "$repo" ] && [ -d "$repo" ]; then
  set -- "$@" --cwd "$repo"
fi

exec "$herdr_bin" "$@"
