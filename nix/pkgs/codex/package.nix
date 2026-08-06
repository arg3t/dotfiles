{
  lib,
  stdenv,
  fetchurl,
  versionCheckHook,
}:

let
  sources = lib.importJSON ./sources.json;

  owner = "openai";
  repo = "codex";

  # Nix system -> release asset target triple. Single source of truth shared by
  # the derivation and the update script. codex ships fully static musl binaries
  # on Linux, so no autoPatchelf/wrapper is needed.
  suffixes = {
    x86_64-linux = "x86_64-unknown-linux-musl";
    aarch64-linux = "aarch64-unknown-linux-musl";
    x86_64-darwin = "x86_64-apple-darwin";
    aarch64-darwin = "aarch64-apple-darwin";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "codex";
  version = sources.version;

  src =
    let
      inherit (stdenv.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "codex: unsupported system ${system}");
      suffix = selectSystem suffixes;
      hash = selectSystem sources.hashes;
    in
    fetchurl {
      url = "https://github.com/${owner}/${repo}/releases/download/rust-v${finalAttrs.version}/codex-${suffix}.tar.gz";
      inherit hash;
    };

  # The tarball holds a single `codex-<triple>` binary at its root; unpack it in
  # installPhase to sidestep the missing-source-root check.
  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    tar xf $src
    install -Dm755 codex-* $out/bin/codex

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/codex";
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${finalAttrs.version}";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "codex";
  };
})
