# Derivation adapted from DavSanchez/nix-dotfiles (pkgs/omniwm.nix). Uses bsdtar
# so the release's Developer ID signature is preserved (an `unzip` extraction
# strips it, which lets macOS delete the unsigned bundle from the store).
{
  lib,
  fetchurl,
  libarchive,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "omniwm";
  version = "0.5.9";

  src = fetchurl {
    url = "https://github.com/BarutSRB/OmniWM/releases/download/v${finalAttrs.version}/OmniWM-v${finalAttrs.version}.zip";
    hash = "sha256-oaOCTpUQFQnrzlV2OSMsVwvaDcgefUTFFkKiRMB28nQ=";
  };

  dontUnpack = true;
  strictDeps = true;
  nativeBuildInputs = [ libarchive ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications/
    bsdtar -xf $src -C $out/Applications/

    mkdir -p $out/bin
    ln -s $out/Applications/OmniWM.app/Contents/MacOS/OmniWM $out/bin/OmniWM
    ln -s $out/Applications/OmniWM.app/Contents/MacOS/omniwmctl $out/bin/omniwmctl

    runHook postInstall
  '';

  meta = {
    description = "macOS tiling window manager (Niri + Hyprland dwindle layouts)";
    homepage = "https://github.com/BarutSRB/OmniWM";
    license = lib.licenses.gpl2Only;
    mainProgram = "OmniWM";
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
