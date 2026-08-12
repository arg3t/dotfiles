{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

let
  sources = lib.importJSON ./sources.json;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lolcrab";
  version = sources.version;

  src = fetchFromGitHub {
    owner = "mazznoer";
    repo = "lolcrab";
    rev = "v${finalAttrs.version}";
    hash = sources.hash;
  };
  cargoHash = sources.cargoHash;

  passthru.updateScript = [ ./update.sh ];

  meta = {
    description = "Like lolcat but with noise and more colorful";
    homepage = "https://github.com/mazznoer/lolcrab";
    changelog = "https://github.com/mazznoer/lolcrab/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "lolcrab";
    platforms = lib.platforms.unix;
  };
})
