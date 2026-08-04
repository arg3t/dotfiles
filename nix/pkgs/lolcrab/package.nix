{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lolcrab";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "mazznoer";
    repo = "lolcrab";
    rev = "v${finalAttrs.version}";
    hash = "sha256-AfdCK8Xi523o45Ft9aLZPt4dZDdNLsn04QFCUVdgS5A=";
  };
  cargoHash = "sha256-xuHTh3Fo/6gNGrcPz7WArJ1nXQvWuHAopYBmVyCXUCU=";

  meta = {
    description = "Like lolcat but with noise and more colorful";
    homepage = "https://github.com/mazznoer/lolcrab";
    changelog = "https://github.com/mazznoer/lolcrab/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "lolcrab";
    platforms = lib.platforms.unix;
  };
})
