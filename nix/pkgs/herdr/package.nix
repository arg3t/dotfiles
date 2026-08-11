{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  versionCheckHook,
}:

let
  sources = lib.importJSON ./sources.json;

  owner = "herdrdev";
  repo = "herdr";

  # Nix system -> release asset suffix. Single source of truth shared by the
  # derivation and the update script.
  suffixes = {
    x86_64-linux = "linux-x86_64";
    aarch64-linux = "linux-aarch64";
    x86_64-darwin = "macos-x86_64";
    aarch64-darwin = "macos-aarch64";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr";
  version = sources.version;

  src =
    let
      inherit (stdenv.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "herdr: unsupported system ${system}");
      suffix = selectSystem suffixes;
      hash = selectSystem sources.hashes;
    in
    fetchurl {
      url = "https://github.com/${owner}/${repo}/releases/download/v${finalAttrs.version}/herdr-${suffix}";
      inherit hash;
    };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/herdr

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/herdr";
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://herdr.dev";
    changelog = "https://github.com/herdrdev/herdr/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "herdr";
  };
})
