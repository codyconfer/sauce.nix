{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  alsa-lib,
  freetype,
  libglvnd,
  libjack2,
  libXScrnSaver,
  libX11,
  libXcursor,
  libXext,
  libXinerama,
  libXrandr,
}:
let
  runtimeLibraries = [
    alsa-lib
    libglvnd
    libjack2
    libXScrnSaver
    libX11
    libXcursor
    libXext
    libXinerama
    libXrandr
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "byod";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/Chowdhury-DSP/BYOD/releases/download/v${finalAttrs.version}/BYOD-Linux-x64-${finalAttrs.version}.deb";
    hash = "sha256-wYA65Xtxe6sE7yBywQKEvLfUT741LUJkUHWwxodcmus=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = runtimeLibraries ++ [
    freetype
    stdenv.cc.cc.lib
  ];
  # JUCE loads its window-system libraries dynamically, including in plugins.
  runtimeDependencies = map lib.getLib runtimeLibraries;
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r usr/. "$out/"
    mkdir -p "$out/share/applications"
    cp ${makeDesktopItem {
      name = "byod";
      desktopName = "BYOD";
      comment = "Build Your Own Distortion";
      exec = "BYOD";
      categories = [
        "AudioVideo"
        "Audio"
      ];
    }}/share/applications/* "$out/share/applications/"
    runHook postInstall
  '';
  postFixup = ''
    wrapProgram "$out/bin/BYOD" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibraries}
  '';

  meta = {
    description = "Build Your Own Distortion: modular guitar effects processor";
    homepage = "https://github.com/Chowdhury-DSP/BYOD";
    license = lib.licenses.gpl3Only;
    mainProgram = "BYOD";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
