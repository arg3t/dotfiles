{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

let
  sources = lib.importJSON ./sources.json;
in
stdenvNoCC.mkDerivation {
  pname = "supercmd";
  version = sources.version;

  src = fetchurl {
    url = "https://github.com/SuperCmdLabs/SuperCmd/releases/download/${sources.version}/SuperCmd-${sources.version}-arm64-mac.zip";
    hash = sources.hash;
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

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Open-source macOS launcher with Raycast-compatible extensions and clipboard history";
    homepage = "https://supercmd.sh/";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
