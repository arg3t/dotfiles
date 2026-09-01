{
  lib,
  stdenv,
  swift,
  swiftPackages,
}:

stdenv.mkDerivation {
  pname = "sony-connect";
  version = "0.1.0";
  src = ./src;

  nativeBuildInputs = [ swift swiftPackages.swiftpm ];

  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    swift build -c release --scratch-path "$TMPDIR/build"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    app="$out/Applications/SonyConnect.app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$TMPDIR/build/release/SonyConnect" "$app/Contents/MacOS/"
    cp Resources/Info.plist "$app/Contents/"
    cp Resources/AppIcon.icns "$app/Contents/Resources/"
    /usr/bin/codesign --force --sign - "$app"
    runHook postInstall
  '';

  meta = {
    description = "macOS menu-bar controls for Sony headphones";
    homepage = "https://github.com/tanat44/sony-connect-osx";
    license = lib.licenses.mit;
    mainProgram = "SonyConnect";
    platforms = lib.platforms.darwin;
  };
}
