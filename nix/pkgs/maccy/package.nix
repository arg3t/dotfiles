{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation {
  pname = "maccy";
  version = "2.7.0";

  src = fetchurl {
    url = "https://github.com/p0deje/Maccy/releases/download/2.7.0/Maccy.app.zip";
    hash = "sha256-ni/0OTBZpx3NzSfF0RHeMWcwgK4sGP7ES6ZcGrJkODw=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Maccy.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Lightweight clipboard manager for macOS";
    homepage = "https://maccy.app/";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
