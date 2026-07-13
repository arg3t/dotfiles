{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "podctl";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "Rockykln";
    repo = "podctl";
    rev = "v${finalAttrs.version}";
    hash = "sha256-sEq3YtO5ED/5CxJ+IccQYs+rpQVaUXOIWTFErUGxDdc=";
  };
  cargoHash = "sha256-SLOHB0/Rhgic4E8lM5rifW8qRdUwCKY03QBC+ylwxAY=";

  # podctl, podctld, podctl-tray, podctl-popup — autobins disabled in
  # Cargo.toml, so point cargo at the declared bin entry-points.
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
