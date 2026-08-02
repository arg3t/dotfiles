{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation {
  pname = "hammerspoon";
  version = "1.1.1";

  src = fetchurl {
    url = "https://github.com/Hammerspoon/hammerspoon/releases/download/1.1.1/Hammerspoon-1.1.1.zip";
    hash = "sha256-EbsckPr1Qn83x71P5+q5d0rkPh1csCDFswiNrDKEnvo=";
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

  meta = {
    description = "Staggeringly powerful macOS desktop automation with Lua";
    homepage = "https://www.hammerspoon.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
