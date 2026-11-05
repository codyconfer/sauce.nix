{ pkgs }:
let
  inherit (pkgs) lib;
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  mkApp =
    name: args:
    pkgs.rustPlatform.buildRustPackage (
      {
        pname = name;
        inherit (sources.${name}) version cargoHash;
        src = pkgs.fetchFromGitHub {
          inherit (sources.${name})
            owner
            repo
            rev
            hash
            ;
        };
        nativeBuildInputs = [ pkgs.libcosmicAppHook ];
        buildInputs = [
          pkgs.openssl
          pkgs.fontconfig
        ];
        meta = {
          homepage = "https://github.com/${sources.${name}.owner}/${sources.${name}.repo}";
          platforms = lib.platforms.linux;
        };
      }
      // args
    );
  resources = appid: dir: icon: ''
    install -Dm644 ${dir}/app.desktop "$out/share/applications/${appid}.desktop"
    install -Dm644 ${dir}/app.metainfo.xml "$out/share/metainfo/${appid}.metainfo.xml"
    install -Dm644 ${dir}/${icon} "$out/share/icons/hicolor/scalable/apps/${appid}.svg"
  '';
in
{
  cupola = mkApp "cupola" {
    nativeBuildInputs = [
      pkgs.libcosmicAppHook
      pkgs.cmake
      pkgs.nasm
    ];
    postInstall = ''
      install -Dm644 data/org.codeberg.bhh32.Cupola.desktop "$out/share/applications/org.codeberg.bhh32.Cupola.desktop"
      install -Dm644 data/org.codeberg.bhh32.Cupola.svg "$out/share/icons/hicolor/scalable/apps/org.codeberg.bhh32.Cupola.svg"
      install -Dm644 data/org.codeberg.bhh32.Cupola.meta.info.xml "$out/share/metainfo/org.codeberg.bhh32.Cupola.metainfo.xml"
    '';
  };
  cedilla = mkApp "cedilla" {
    postInstall = resources "dev.mariinkys.Cedilla" "resources" "icons/hicolor/scalable/apps/icon.svg";
  };
  starrydex = mkApp "starrydex" {
    postInstall =
      resources "dev.mariinkys.StarryDex" "resources"
        "icons/hicolor/scalable/apps/icon.svg";
  };
  cosmic-ext-camera = mkApp "cosmic-ext-camera" {
    nativeBuildInputs = [
      pkgs.libcosmicAppHook
      pkgs.cmake
      pkgs.nasm
      pkgs.rustPlatform.bindgenHook
    ];
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.dav1d
      pkgs.libcamera
      pkgs.udev
    ]
    ++ (with pkgs.gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      gst-libav
    ]);
    preFixup = ''
      libcosmicAppWrapperArgs+=(--prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0")
    '';
    postInstall = ''
      install -Dm644 resources/io.github.cosmic_utils.camera.desktop "$out/share/applications/io.github.cosmic_utils.camera.desktop"
      install -Dm644 resources/io.github.cosmic_utils.camera.metainfo.xml "$out/share/metainfo/io.github.cosmic_utils.camera.metainfo.xml"
      mkdir -p "$out/share/icons"
      cp -r resources/icons/hicolor "$out/share/icons/"
    '';
  };
  cosmic-ext-compass = mkApp "cosmic-ext-compass" {
    postInstall = ''
      install -Dm644 resources/org.cosmic_utils.compass.desktop "$out/share/applications/org.cosmic_utils.compass.desktop"
      install -Dm644 resources/org.cosmic_utils.compass.metainfo.xml "$out/share/metainfo/org.cosmic_utils.compass.metainfo.xml"
      mkdir -p "$out/share/icons"
      cp -r resources/icons/hicolor "$out/share/icons/"
    '';
  };
  clipboard-manager = mkApp "clipboard-manager" {
    env.CLIPBOARD_MANAGER_COMMIT = sources.clipboard-manager.rev;
    postInstall = ''
      install -Dm644 res/desktop_entry.desktop "$out/share/applications/io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager.desktop"
      install -Dm644 res/metainfo.xml "$out/share/metainfo/io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager.metainfo.xml"
      install -Dm644 res/app_icon.svg "$out/share/icons/hicolor/scalable/apps/io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager-symbolic.svg"
    '';
  };
  cosmic-applet-music-player = mkApp "cosmic-applet-music-player" {
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.dbus
      pkgs.libpulseaudio
    ];
    postInstall = ''
      install -Dm644 res/com.github.MusicPlayer.desktop "$out/share/applications/com.github.MusicPlayer.desktop"
      install -Dm644 res/com.github.MusicPlayer.metainfo.xml "$out/share/metainfo/com.github.MusicPlayer.metainfo.xml"
      mkdir -p "$out/share/icons"
      cp -r res/icons/hicolor "$out/share/icons/"
    '';
  };
  cosmic-power-monitor = mkApp "cosmic-power-monitor" {
    postInstall = ''
      install -Dm644 resources/io.github.AceMythos.cosmic-ext-applet-power-monitor.desktop "$out/share/applications/io.github.AceMythos.cosmic-ext-applet-power-monitor.desktop"
      install -Dm644 resources/io.github.AceMythos.cosmic-ext-applet-power-monitor.metainfo.xml "$out/share/metainfo/io.github.AceMythos.cosmic-ext-applet-power-monitor.metainfo.xml"
      install -Dm644 resources/io.github.AceMythos.cosmic-ext-applet-power-monitor.svg "$out/share/icons/hicolor/scalable/apps/io.github.AceMythos.cosmic-ext-applet-power-monitor.svg"
    '';
  };
  cosmic-ext-applet-eyedropper = mkApp "cosmic-ext-applet-eyedropper" {
    postInstall = ''
      install -Dm644 resources/app.desktop "$out/share/applications/io.github.nalladev.CosmicExtAppletEyedropper.desktop"
      install -Dm644 resources/app.metainfo.xml "$out/share/metainfo/io.github.nalladev.CosmicExtAppletEyedropper.metainfo.xml"
      install -Dm644 resources/icon.svg "$out/share/icons/hicolor/scalable/apps/io.github.nalladev.CosmicExtAppletEyedropper-symbolic.svg"
    '';
  };
}
