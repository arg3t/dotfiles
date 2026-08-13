#!/usr/bin/env bash
# Refresh supercmd to the latest GitHub release: fetch the newest tag, prefetch
# the release DMG, and rewrite sources.json (version + hash).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 1.0.5            # pin an explicit version
#   nix run .#supercmd.updateScript
set -euo pipefail

owner="SuperCmdLabs"
repo="SuperCmd-v2-releases"

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
  echo "supercmd: already at $version" >&2
  exit 0
fi
echo "supercmd: $current -> $version" >&2

url="https://github.com/$owner/$repo/releases/download/$version/SuperCmd.dmg"
echo "  prefetch $url" >&2
hash="$(nix store prefetch-file --json --name "SuperCmd-$version.dmg" "$url" | jq -r .hash)"

jq -n --arg version "$version" --arg hash "$hash" \
  '{version: $version, hash: $hash}' >"$sources_json"
echo "supercmd: wrote $sources_json" >&2
