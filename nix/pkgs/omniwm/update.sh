#!/usr/bin/env bash
# Refresh omniwm to the latest GitHub release: fetch the newest tag, prefetch
# the release zip, and rewrite sources.json (version + hash).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 0.6.1           # pin an explicit version
#   nix run .#omniwm.updateScript
set -euo pipefail

owner="arg3t"
repo="OmniWM"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sources_json="$here/sources.json"

if [ "$#" -ge 1 ]; then
  version="${1#v}"
else
  latest="$(curl -fsSL -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$owner/$repo/releases/latest")"
  version="$(printf '%s' "$latest" | jq -r .tag_name)"
  version="${version#v}"
fi

current="$(jq -r .version "$sources_json" 2>/dev/null || echo none)"
if [ "$version" = "$current" ]; then
  echo "omniwm: already at $version" >&2
  exit 0
fi
echo "omniwm: $current -> $version" >&2

url="https://github.com/$owner/$repo/releases/download/v$version/OmniWM-v$version.zip"
echo "  prefetch $url" >&2
hash="$(nix store prefetch-file --json --name "OmniWM-v$version.zip" "$url" | jq -r .hash)"

jq -n --arg version "$version" --arg hash "$hash" \
  '{version: $version, hash: $hash}' >"$sources_json"
echo "omniwm: wrote $sources_json" >&2
