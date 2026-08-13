{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  sources = lib.importJSON ./sources.json;

  owner = "fullerzz";
  repo = "herdr-plugin-sesh";

  # Nix system -> release asset suffix.
  suffixes = {
    x86_64-linux = "linux_amd64";
    aarch64-linux = "linux_arm64";
    x86_64-darwin = "darwin_amd64";
    aarch64-darwin = "darwin_arm64";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-plugin-sesh";
  version = sources.version;

  src =
    let
      inherit (stdenv.hostPlatform) system;
      selectSystem = attrs: attrs.${system} or (throw "herdr-plugin-sesh: unsupported system ${system}");
      suffix = selectSystem suffixes;
      hash = selectSystem sources.hashes;
    in
    fetchurl {
      url = "https://github.com/${owner}/${repo}/releases/download/v${finalAttrs.version}/herdr-sesh_${finalAttrs.version}_${suffix}.tar.gz";
      inherit hash;
    };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  installPhase = ''
    runHook preInstall

    # The tarball extracts to herdr-sesh_<version>_<suffix>/ with
    # bin/herdr-sesh and herdr-plugin.toml at the root. Install both into
    # the same plugin root so relative paths in the manifest resolve.
    extracted=$(ls -d herdr-sesh_*)

    mkdir -p $out/share/herdr-plugin-sesh/bin
    install -Dm755 "$extracted/bin/herdr-sesh" $out/share/herdr-plugin-sesh/bin/herdr-sesh
    install -Dm644 "$extracted/herdr-plugin.toml" $out/share/herdr-plugin-sesh/herdr-plugin.toml

    runHook postInstall
  '';

  passthru = {
    pluginRoot = "${placeholder "out"}/share/herdr-plugin-sesh";
    updateScript = [ ./update.sh ];
  };

  meta = {
    description = "Sesh-style smart workspace/session manager for Herdr";
    homepage = "https://github.com/fullerzz/herdr-plugin-sesh";
    changelog = "https://github.com/fullerzz/herdr-plugin-sesh/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "herdr-sesh";
  };
})
