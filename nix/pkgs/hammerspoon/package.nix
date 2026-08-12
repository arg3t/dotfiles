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
  pname = "hammerspoon";
  version = sources.version;

  src = fetchurl {
    url = "https://github.com/Hammerspoon/hammerspoon/releases/download/${sources.version}/Hammerspoon-${sources.version}.zip";
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
    cp -R Hammerspoon.app $out/Applications/
    runHook postInstall
  '';

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Staggeringly powerful macOS desktop automation with Lua";
    homepage = "https://www.hammerspoon.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
