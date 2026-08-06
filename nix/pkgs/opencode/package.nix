{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
}:

let
  sources = lib.importJSON ./sources.json;

  owner = "sst";
  repo = "opencode";

  # Nix system -> release asset suffix. Linux ships glibc tarballs (dynamically
  # linked, patched by autoPatchelfHook); macOS ships zips. Single source of
  # truth shared by the derivation and the update script.
  suffixes = {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-darwin = "darwin-arm64";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = sources.version;

  src =
    let
      inherit (stdenv.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "opencode: unsupported system ${system}");
      suffix = selectSystem suffixes;
      hash = selectSystem sources.hashes;
      ext = if stdenv.hostPlatform.isDarwin then "zip" else "tar.gz";
    in
    fetchurl {
      url = "https://github.com/${owner}/${repo}/releases/download/v${finalAttrs.version}/opencode-${suffix}.${ext}";
      inherit hash;
    };

  # Each archive holds a single `opencode` binary at its root.
  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs =
    lib.optionals stdenv.hostPlatform.isDarwin [ unzip ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    ${if stdenv.hostPlatform.isDarwin then "unzip -q $src" else "tar xf $src"}
    install -Dm755 opencode $out/bin/opencode

    runHook postInstall
  '';

  # opencode is a Bun binary that writes a cache under $HOME on startup; the
  # build sandbox's HOME=/var/empty is unwritable, so `--version` aborts with
  # EPERM under versionCheckHook (which fixes HOME after preVersionCheck). Run
  # the check by hand with a writable HOME instead.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    export HOME="$(mktemp -d)"
    export TMPDIR="$HOME/tmp"
    mkdir -p "$TMPDIR"
    echo "opencode check: HOME=$HOME TMPDIR=$TMPDIR"
    cd "$HOME"
    set +e
    v="$("$out/bin/opencode" --version 2>&1)"
    rc=$?
    set -e
    echo "opencode --version (rc=$rc) -> [$v]"
    case "$v" in
      *${finalAttrs.version}*) ;;
      *) echo "opencode: expected version ${finalAttrs.version} in output" >&2; exit 1 ;;
    esac

    runHook postInstallCheck
  '';

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://github.com/sst/opencode";
    changelog = "https://github.com/sst/opencode/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "opencode";
  };
})
