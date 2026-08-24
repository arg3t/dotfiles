#!/usr/bin/env bash
# Refresh herdr to the latest GitHub release: fetch the newest tag, prefetch
# every per-platform binary, and rewrite sources.json (version + all hashes).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 0.8.0           # pin an explicit version
#   nix run .#herdr.updateScript
set -euo pipefail

owner="herdrdev"
repo="herdr"

# Nix system and release asset suffix pairs.
# Do not use Bash associative arrays, because the macOS system Bash does not support them.
platforms=(
  "x86_64-linux linux-x86_64"
  "aarch64-linux linux-aarch64"
  "x86_64-darwin macos-x86_64"
  "aarch64-darwin macos-aarch64"
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
  echo "herdr: already at $version" >&2
  exit 0
fi
echo "herdr: $current -> $version" >&2

hashes="{}"
for platform in "${platforms[@]}"; do
  read -r system suffix <<<"$platform"
  url="https://github.com/$owner/$repo/releases/download/v$version/herdr-$suffix"
  echo "  prefetch $system ($suffix)" >&2
  hash="$(nix store prefetch-file --json --name "herdr-$suffix" "$url" | jq -r .hash)"
  hashes="$(printf '%s' "$hashes" | jq --arg s "$system" --arg h "$hash" '.[$s] = $h')"
done

jq -n --arg version "$version" --argjson hashes "$hashes" \
  '{version: $version, hashes: $hashes}' >"$sources_json"
echo "herdr: wrote $sources_json" >&2
