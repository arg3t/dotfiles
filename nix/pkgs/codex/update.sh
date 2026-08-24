#!/usr/bin/env bash
# Refresh codex to the latest GitHub release: fetch the newest tag, prefetch
# every per-platform tarball, and rewrite sources.json (version + all hashes).
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 0.146.1         # pin an explicit version
#   nix run .#codex.updateScript
set -euo pipefail

owner="openai"
repo="codex"

# codex tags are `rust-v<version>`; asset target triples per Nix system.
# Do not use Bash associative arrays, because the macOS system Bash does not support them.
platforms=(
  "x86_64-linux x86_64-unknown-linux-musl"
  "aarch64-linux aarch64-unknown-linux-musl"
  "x86_64-darwin x86_64-apple-darwin"
  "aarch64-darwin aarch64-apple-darwin"
)

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sources_json="$here/sources.json"

if [ "$#" -ge 1 ]; then
  version="${1#v}"
  version="${version#rust-v}"
else
  latest="$(curl -fsSL -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$owner/$repo/releases/latest")"
  version="$(printf '%s' "$latest" | jq -r .tag_name)"
  version="${version#rust-v}"
fi

current="$(jq -r .version "$sources_json" 2>/dev/null || echo none)"
if [ "$version" = "$current" ]; then
  echo "codex: already at $version" >&2
  exit 0
fi
echo "codex: $current -> $version" >&2

hashes="{}"
for platform in "${platforms[@]}"; do
  read -r system suffix <<<"$platform"
  url="https://github.com/$owner/$repo/releases/download/rust-v$version/codex-$suffix.tar.gz"
  echo "  prefetch $system ($suffix)" >&2
  hash="$(nix store prefetch-file --json --name "codex-$suffix.tar.gz" "$url" | jq -r .hash)"
  hashes="$(printf '%s' "$hashes" | jq --arg s "$system" --arg h "$hash" '.[$s] = $h')"
done

jq -n --arg version "$version" --argjson hashes "$hashes" \
  '{version: $version, hashes: $hashes}' >"$sources_json"
echo "codex: wrote $sources_json" >&2
