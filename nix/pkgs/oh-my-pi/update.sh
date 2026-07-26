#!/usr/bin/env bash
# Refresh oh-my-pi to the latest GitHub release: fetch the newest tag, prefetch
# every per-platform binary, and rewrite sources.json (version + all hashes).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 17.1.0          # pin an explicit version
#   nix run .#oh-my-pi.updateScript
set -euo pipefail

owner="can1357"
repo="oh-my-pi"

# Nix system -> release asset suffix.
declare -A suffixes=(
  [x86_64-linux]=linux-x64
  [aarch64-linux]=linux-arm64
  [x86_64-darwin]=darwin-x64
  [aarch64-darwin]=darwin-arm64
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

current="$(jq -r .version "$sources_json")"
if [ "$version" = "$current" ]; then
  echo "oh-my-pi: already at $version" >&2
  exit 0
fi
echo "oh-my-pi: $current -> $version" >&2

hashes="{}"
for system in "${!suffixes[@]}"; do
  suffix="${suffixes[$system]}"
  url="https://github.com/$owner/$repo/releases/download/v$version/omp-$suffix"
  echo "  prefetch $system ($suffix)" >&2
  hash="$(nix store prefetch-file --json --name "omp-$suffix" "$url" | jq -r .hash)"
  hashes="$(printf '%s' "$hashes" | jq --arg s "$system" --arg h "$hash" '.[$s] = $h')"
done

jq -n --arg version "$version" --argjson hashes "$hashes" \
  '{version: $version, hashes: $hashes}' >"$sources_json"
echo "oh-my-pi: wrote $sources_json" >&2
