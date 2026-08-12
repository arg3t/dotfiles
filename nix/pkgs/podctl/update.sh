#!/usr/bin/env bash
# Refresh podctl to the latest GitHub release: fetch the newest tag, prefetch
# the source tarball and cargo dependencies, and rewrite sources.json.
#
# Usage:
#   ./update.sh                 # bump to the latest release
#   ./update.sh 0.1.1           # pin an explicit version
#   nix run .#podctl.updateScript
set -euo pipefail

owner="Rockykln"
repo="podctl"

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
  echo "podctl: already at $version" >&2
  exit 0
fi
echo "podctl: $current -> $version" >&2

# Prefetch source tarball.
url="https://github.com/$owner/$repo/archive/refs/tags/v$version.tar.gz"
echo "  prefetch source" >&2
hash="$(nix store prefetch-file --json --name "podctl-$version.tar.gz" "$url" | jq -r .hash)"

# Compute cargoHash by building with a dummy hash and extracting the real one
# from the error output.
echo "  computing cargoHash" >&2
cargo_hash="$(nix build --no-link --impure --expr "
  with import <nixpkgs> {};
  rustPlatform.buildRustPackage rec {
    pname = \"podctl\";
    version = \"$version\";
    src = fetchFromGitHub {
      owner = \"$owner\";
      repo = \"$repo\";
      rev = \"v\${version}\";
      hash = \"$hash\";
    };
    cargoHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
  }
" 2>&1 | grep -oP 'got:\s+\K\S+' || true)"

if [ -z "$cargo_hash" ]; then
  echo "  ERROR: failed to compute cargoHash" >&2
  exit 1
fi

jq -n --arg version "$version" --arg hash "$hash" --arg cargoHash "$cargo_hash" \
  '{version: $version, hash: $hash, cargoHash: $cargoHash}' >"$sources_json"
echo "podctl: wrote $sources_json" >&2
