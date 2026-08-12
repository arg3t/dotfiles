#!/usr/bin/env bash
# Refresh hammerspoon to the latest GitHub release: fetch the newest tag, prefetch
# the release zip, and rewrite sources.json (version + hash).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 1.1.1           # pin an explicit version
#   nix run .#hammerspoon.updateScript
set -euo pipefail

owner="Hammerspoon"
repo="hammerspoon"

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
  echo "hammerspoon: already at $version" >&2
  exit 0
fi
echo "hammerspoon: $current -> $version" >&2

url="https://github.com/$owner/$repo/releases/download/$version/Hammerspoon-$version.zip"
echo "  prefetch $url" >&2
hash="$(nix store prefetch-file --json --name "Hammerspoon-$version.zip" "$url" | jq -r .hash)"

jq -n --arg version "$version" --arg hash "$hash" \
  '{version: $version, hash: $hash}' >"$sources_json"
echo "hammerspoon: wrote $sources_json" >&2
