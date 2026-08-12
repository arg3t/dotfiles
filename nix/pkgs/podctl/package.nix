{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

let
  sources = lib.importJSON ./sources.json;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "podctl";
  version = sources.version;

  src = fetchFromGitHub {
    owner = "Rockykln";
    repo = "podctl";
    rev = "v${finalAttrs.version}";
    hash = sources.hash;
  };
  cargoHash = sources.cargoHash;

  cargoBuildFlags = [
    "--bin"
    "podctl"
    "--bin"
    "podctld"
    "--bin"
    "podctl-tray"
    "--bin"
    "podctl-popup"
  ];
  cargoTestFlags = finalAttrs.cargoBuildFlags;

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Linux CLI to control AirPods — battery, listening mode, conversation awareness, bluetooth connect/disconnect";
    homepage = "https://github.com/Rockykln/podctl";
    changelog = "https://github.com/Rockykln/podctl/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "podctl";
    platforms = lib.platforms.linux;
  };
})
