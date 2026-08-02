{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:

stdenvNoCC.mkDerivation {
  pname = "thunderbird";
  version = "153.0.1";

  src = fetchurl {
    name = "thunderbird.dmg";
    url = "https://archive.mozilla.org/pub/thunderbird/releases/153.0.1/mac/en-US/Thunderbird%20153.0.1.dmg";
    hash = "sha256-WkT70E9QzfbeRXsXEms33y5/1WN5t2LGW4yacWOBjTg=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Thunderbird.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Mozilla Thunderbird, a full-featured email client";
    homepage = "https://www.thunderbird.net/";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
