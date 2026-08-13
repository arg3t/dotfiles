{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  sources = lib.importJSON ./sources.json;
in
stdenvNoCC.mkDerivation {
  pname = "supercmd";
  version = sources.version;

  src = fetchurl {
    url = "https://github.com/SuperCmdLabs/SuperCmd-v2-releases/releases/download/${sources.version}/SuperCmd.dmg";
    hash = sources.hash;
    name = "SuperCmd-${sources.version}.dmg";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mountPoint=$(mktemp -d)
    /usr/bin/hdiutil attach -nobrowse -mountpoint "$mountPoint" "$src"
    mkdir -p $out/Applications
    cp -R "$mountPoint/SuperCmd.app" $out/Applications/
    /usr/bin/hdiutil detach "$mountPoint" -force
    runHook postInstall
  '';

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Native macOS launcher with AI agents, clipboard history, snippets, window management, and Raycast extensions";
    homepage = "https://supercmd.sh/";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
