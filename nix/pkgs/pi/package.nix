{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  sources = lib.importJSON ./sources.json;

  owner = "earendil-works";
  repo = "pi";

  # Nix system -> release asset suffix. pi ships per-platform tarballs that each
  # unpack to a `pi/` app directory (launcher + node_modules + native modules +
  # wasm/assets), not a single binary. Single source of truth shared by the
  # derivation and the update script.
  suffixes = {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-darwin = "darwin-arm64";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "pi";
  version = sources.version;

  src =
    let
      inherit (stdenv.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "pi: unsupported system ${system}");
      suffix = selectSystem suffixes;
      hash = selectSystem sources.hashes;
    in
    fetchurl {
      url = "https://github.com/${owner}/${repo}/releases/download/v${finalAttrs.version}/pi-${suffix}.tar.gz";
      inherit hash;
    };

  # The tarball's single top-level `pi/` directory becomes the source root.
  sourceRoot = "pi";
  dontStrip = true;

  # The launcher and the bundled *.node native modules only need glibc +
  # libgcc_s on Linux (no X11/Wayland); autoPatchelfHook rewrites them all.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share" "$out/bin"
    cp -r . "$out/share/pi"
    # The launcher resolves its resources by its own real path, so a symlink on
    # PATH is enough (verified on macOS + Linux).
    ln -s "$out/share/pi/pi" "$out/bin/pi"

    runHook postInstall
  '';

  # pi reads settings under $HOME and writes scratch under $TMPDIR on startup;
  # the build sandbox's HOME=/var/empty is unwritable, so point both at temp
  # dirs for the version check.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    export HOME="$(mktemp -d)"
    export TMPDIR="$HOME/tmp"
    mkdir -p "$TMPDIR"
    cd "$HOME"
    set +e
    v="$("$out/bin/pi" --version 2>&1)"
    rc=$?
    set -e
    echo "pi --version (rc=$rc) -> [$v]"
    case "$v" in
      *${finalAttrs.version}*) ;;
      *) echo "pi: expected version ${finalAttrs.version} in output" >&2; exit 1 ;;
    esac

    runHook postInstallCheck
  '';

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Terminal-first extensible AI coding agent harness";
    homepage = "https://github.com/earendil-works/pi";
    changelog = "https://github.com/earendil-works/pi/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "pi";
  };
})
