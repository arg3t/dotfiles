#!/usr/bin/env bash
# Refresh opencode to the latest GitHub release: fetch the newest tag, prefetch
# every per-platform archive, and rewrite sources.json (version + all hashes).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 1.18.14         # pin an explicit version
#   nix run .#opencode.updateScript
set -euo pipefail

owner="sst"
repo="opencode"

# opencode tags are `v<version>`. Linux assets are .tar.gz, macOS assets .zip.
# Do not use Bash associative arrays, because the macOS system Bash does not support them.
platforms=(
  "x86_64-linux linux-x64"
  "aarch64-linux linux-arm64"
  "x86_64-darwin darwin-x64"
  "aarch64-darwin darwin-arm64"
)

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
  echo "opencode: already at $version" >&2
  exit 0
fi
echo "opencode: $current -> $version" >&2

hashes="{}"
for platform in "${platforms[@]}"; do
  read -r system suffix <<<"$platform"
  case "$system" in
    *darwin) ext=zip ;;
    *) ext=tar.gz ;;
  esac
  url="https://github.com/$owner/$repo/releases/download/v$version/opencode-$suffix.$ext"
  echo "  prefetch $system ($suffix.$ext)" >&2
  hash="$(nix store prefetch-file --json --name "opencode-$suffix.$ext" "$url" | jq -r .hash)"
  hashes="$(printf '%s' "$hashes" | jq --arg s "$system" --arg h "$hash" '.[$s] = $h')"
done

jq -n --arg version "$version" --argjson hashes "$hashes" \
  '{version: $version, hashes: $hashes}' >"$sources_json"
echo "opencode: wrote $sources_json" >&2
