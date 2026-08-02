{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation {
  pname = "supercmd";
  version = "1.0.26";

  src = fetchurl {
    url = "https://github.com/SuperCmdLabs/SuperCmd/releases/download/1.0.26/SuperCmd-1.0.26-arm64-mac.zip";
    hash = "sha256-y0LPgltSV/V2OwGS8TN4gubIt0tHjDawdU2MqU5WW8s=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R SuperCmd.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Open-source macOS launcher with Raycast-compatible extensions and clipboard history";
    homepage = "https://supercmd.sh/";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
