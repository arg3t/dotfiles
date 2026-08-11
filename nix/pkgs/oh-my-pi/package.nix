{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  versionCheckHook,
}:

let
  sources = lib.importJSON ./sources.json;

  owner = "can1357";
  repo = "oh-my-pi";

  # Nix system -> release asset suffix. Single source of truth shared by the
  # derivation and the update script.
  suffixes = {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-darwin = "darwin-arm64";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "oh-my-pi";
  version = sources.version;

  src =
    let
      inherit (stdenv.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "oh-my-pi: unsupported system ${system}");
      suffix = selectSystem suffixes;
      hash = selectSystem sources.hashes;
    in
    fetchurl {
      url = "https://github.com/${owner}/${repo}/releases/download/v${finalAttrs.version}/omp-${suffix}";
      inherit hash;
    };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/omp

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/omp";
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "AI coding agent for the terminal with hash-anchored edits, LSP, DAP, and subagents";
    homepage = "https://github.com/can1357/oh-my-pi";
    changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "omp";
  };
})
