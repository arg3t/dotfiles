{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:

stdenvNoCC.mkDerivation {
  pname = "raycast";
  version = "1.104.24";

  src = fetchurl {
    name = "Raycast.dmg";
    url = "https://releases.raycast.com/releases/1.104.24/download?build=arm";
    hash = "sha256-kn9bZYSeASKj23NYiWX76OIRXCTonAbUCATyYhPdGgo=";
  };

  sourceRoot = "Raycast.app";
  nativeBuildInputs = [ undmg ];

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications/Raycast.app
    cp -R . $out/Applications/Raycast.app
    runHook postInstall
  '';

  meta = {
    description = "Control your tools with a few keystrokes";
    homepage = "https://raycast.com/";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
