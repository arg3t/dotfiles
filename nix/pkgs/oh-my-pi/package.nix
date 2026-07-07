{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  versionCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "oh-my-pi";
  version = "16.3.11";

  src =
    let
      inherit (stdenv.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "oh-my-pi: unsupported system ${system}");
      suffix = selectSystem {
        x86_64-linux = "linux-x64";
        aarch64-linux = "linux-arm64";
        x86_64-darwin = "darwin-x64";
        aarch64-darwin = "darwin-arm64";
      };
      hash = selectSystem {
        x86_64-linux = "sha256-jZXU3jrhds1UtgMP3fM+KEdENzzdt4C4tP7Woa1j840=";
        aarch64-linux = "sha256-Dqq4ldYkM/AJVUTodS4UPfu673c//BaL28fhU1oo4vM=";
        x86_64-darwin = "sha256-8fWcQdJnJJd5Ul7AGWc5i5ngnxLLpznsffjaMY5limA=";
        aarch64-darwin = "sha256-oRz4w623Msk/4ka6oHwjQIfE5x2SX3psYgTz2JU7Md4=";
      };
    in
    fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${finalAttrs.version}/omp-${suffix}";
      inherit hash;
    };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/omp

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/omp";
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

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
