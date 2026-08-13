#!/usr/bin/env bash
# Refresh herdr-plugin-sesh to the latest GitHub release: fetch the newest tag,
# prefetch every per-platform tarball, and rewrite sources.json (version + all hashes).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 0.7.0           # pin an explicit version
#   nix run .#herdr-plugin-sesh.updateScript
set -euo pipefail

owner="fullerzz"
repo="herdr-plugin-sesh"

# Nix system -> release asset suffix.
declare -A suffixes=(
  [x86_64-linux]=linux_amd64
  [aarch64-linux]=linux_arm64
  [x86_64-darwin]=darwin_amd64
  [aarch64-darwin]=darwin_arm64
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
  echo "herdr-plugin-sesh: already at $version" >&2
  exit 0
fi
echo "herdr-plugin-sesh: $current -> $version" >&2

hashes="{}"
for system in "${!suffixes[@]}"; do
  suffix="${suffixes[$system]}"
  url="https://github.com/$owner/$repo/releases/download/v$version/herdr-sesh_${version}_${suffix}.tar.gz"
  echo "  prefetch $system ($suffix)" >&2
  hash="$(nix store prefetch-file --json --name "herdr-sesh_${version}_${suffix}.tar.gz" "$url" | jq -r .hash)"
  hashes="$(printf '%s' "$hashes" | jq --arg s "$system" --arg h "$hash" '.[$s] = $h')"
done

jq -n --arg version "$version" --argjson hashes "$hashes" \
  '{version: $version, hashes: $hashes}' >"$sources_json"
echo "herdr-plugin-sesh: wrote $sources_json" >&2
