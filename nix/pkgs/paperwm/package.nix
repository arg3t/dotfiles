{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "paperwm-spoon";
  version = "0-unstable-2026-08-04";

  src = fetchFromGitHub {
    owner = "mogenson";
    repo = "PaperWM.spoon";
    rev = "66d2e3208f2e83a2d97fce9ff9a55102110dd609";
    hash = "sha256-+EAK105r2s9iOF2LFi6SQFNAt3LxlA+fOB1d0E4dVlM=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  # The repo root is the Spoon itself (init.lua at top level). Copy it whole so
  # a symlink at ~/.hammerspoon/Spoons/PaperWM.spoon points straight at $out.
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';

  meta = {
    description = "Tiled scrollable window manager for macOS (Hammerspoon Spoon)";
    homepage = "https://github.com/mogenson/PaperWM.spoon";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
