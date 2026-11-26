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
  cosmic-ext-applet-dynamic-island = mkApp "cosmic-ext-applet-dynamic-island" {
    buildInputs = [ pkgs.openssl pkgs.fontconfig pkgs.dbus ];
    postInstall = ''
      install -Dm644 data/io.github.DrakRosmann.CosmicExtAppletDynamicIsland.desktop.in "$out/share/applications/io.github.DrakRosmann.CosmicExtAppletDynamicIsland.desktop"
      install -Dm644 data/io.github.DrakRosmann.CosmicExtAppletDynamicIsland.metainfo.xml "$out/share/metainfo/io.github.DrakRosmann.CosmicExtAppletDynamicIsland.metainfo.xml"
      mkdir -p "$out/share/icons/hicolor/scalable"
      cp -r data/icons/scalable/apps "$out/share/icons/hicolor/scalable/"
    '';
  };
  cosmic-ext-applet-quick-settings = mkApp "cosmic-ext-applet-quick-settings" {
    buildInputs = [ pkgs.openssl pkgs.fontconfig pkgs.dbus ];
    postInstall = ''
      install -Dm644 data/io.github.DrakRosmann.CosmicExtAppletQuickSettings.desktop.in "$out/share/applications/io.github.DrakRosmann.CosmicExtAppletQuickSettings.desktop"
      install -Dm644 data/io.github.DrakRosmann.CosmicExtAppletQuickSettings.metainfo.xml "$out/share/metainfo/io.github.DrakRosmann.CosmicExtAppletQuickSettings.metainfo.xml"
      mkdir -p "$out/share/icons/hicolor/scalable"
      cp -r data/icons/scalable/apps "$out/share/icons/hicolor/scalable/"
    '';
  };
  cosmic-ext-applet-status-hub = mkApp "cosmic-ext-applet-status-hub" {
    buildInputs = [ pkgs.openssl pkgs.fontconfig pkgs.dbus ];
    postInstall = ''
      install -Dm644 resources/io.github.marcelogomes90.cosmic-ext-applet-status-hub.desktop "$out/share/applications/io.github.marcelogomes90.cosmic-ext-applet-status-hub.desktop"
      install -Dm644 resources/io.github.marcelogomes90.cosmic-ext-applet-status-hub.metainfo.xml "$out/share/metainfo/io.github.marcelogomes90.cosmic-ext-applet-status-hub.metainfo.xml"
      install -Dm644 resources/io.github.marcelogomes90.cosmic-ext-applet-status-hub.svg "$out/share/icons/hicolor/scalable/apps/io.github.marcelogomes90.cosmic-ext-applet-status-hub.svg"
    '';
  };
  cosmic-ext-applet-weather = mkApp "cosmic-ext-applet-weather" {
    buildInputs = [ pkgs.openssl pkgs.fontconfig pkgs.dbus pkgs.aws-lc ];
    env.AWS_LC_SYS_USE_SYSTEM = "0";
    postInstall = ''
      install -Dm644 data/io.github.cosmic_utils.weather-applet.desktop "$out/share/applications/io.github.cosmic_utils.weather-applet.desktop"
      install -Dm644 data/io.github.cosmic_utils.weather-applet.metainfo.xml "$out/share/metainfo/io.github.cosmic_utils.weather-applet.metainfo.xml"
      install -Dm644 data/io.github.cosmic_utils.weather-applet-symbolic.svg "$out/share/icons/hicolor/scalable/apps/io.github.cosmic_utils.weather-applet-symbolic.svg"
    '';
  };
  cosmic-ext-applet-trash = mkApp "cosmic-ext-applet-trash" {
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.dbus
    ];
    postInstall = ''
      install -Dm644 resources/io.github.marcelogomes90.cosmic-ext-applet-trash.desktop "$out/share/applications/io.github.marcelogomes90.cosmic-ext-applet-trash.desktop"
      install -Dm644 resources/io.github.marcelogomes90.cosmic-ext-applet-trash.metainfo.xml "$out/share/metainfo/io.github.marcelogomes90.cosmic-ext-applet-trash.metainfo.xml"
      install -Dm644 resources/io.github.marcelogomes90.cosmic-ext-applet-trash.svg "$out/share/icons/hicolor/scalable/apps/io.github.marcelogomes90.cosmic-ext-applet-trash.svg"
    '';
  };
  cosmic-ext-whether = mkApp "cosmic-ext-whether" {
    buildInputs = [
      pkgs.fontconfig
      pkgs.dbus
      pkgs.aws-lc
    ];
    postInstall = ''
      install -Dm644 data/com.github.nwxnw.cosmic-ext-whether.desktop "$out/share/applications/com.github.nwxnw.cosmic-ext-whether.desktop"
      install -Dm644 data/com.github.nwxnw.cosmic-ext-whether.metainfo.xml "$out/share/metainfo/com.github.nwxnw.cosmic-ext-whether.metainfo.xml"
      install -Dm644 data/com.github.nwxnw.cosmic-ext-whether-symbolic.svg "$out/share/icons/hicolor/scalable/apps/com.github.nwxnw.cosmic-ext-whether-symbolic.svg"
    '';
  };
  cosmic-ext-applet-world-clock = mkApp "cosmic-ext-applet-world-clock" {
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.dbus
    ];
    postInstall = ''
      install -Dm644 data/io.github.cosmic_utils.cosmic-ext-applet-world-clock.desktop "$out/share/applications/io.github.cosmic_utils.cosmic-ext-applet-world-clock.desktop"
      install -Dm644 data/io.github.cosmic_utils.cosmic-ext-applet-world-clock.metainfo.xml "$out/share/metainfo/io.github.cosmic_utils.cosmic-ext-applet-world-clock.metainfo.xml"
      install -Dm644 data/io.github.cosmic_utils.cosmic-ext-applet-world-clock-symbolic.svg "$out/share/icons/hicolor/scalable/apps/io.github.cosmic_utils.cosmic-ext-applet-world-clock-symbolic.svg"
    '';
  };
  caffeine-applet = mkApp "caffeine-applet" {
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.dbus
    ];
    postInstall = ''
      install -Dm644 resources/app.desktop "$out/share/applications/com.github.codevardhan.caffeine-applet.desktop"
      install -Dm644 resources/app.metainfo.xml "$out/share/metainfo/com.github.codevardhan.caffeine-applet.metainfo.xml"
      install -Dm644 resources/icons/hicolor/scalable/apps/coffee-empty.svg "$out/share/icons/hicolor/scalable/apps/com.github.codevardhan.caffeine-applet-coffee-empty.svg"
      install -Dm644 resources/icons/hicolor/scalable/apps/coffee-full.svg "$out/share/icons/hicolor/scalable/apps/com.github.codevardhan.caffeine-applet-coffee-full.svg"
      install -Dm644 resources/icons/hicolor/scalable/apps/coffee-symbolic.svg "$out/share/icons/hicolor/scalable/apps/com.github.codevardhan.caffeine-applet-coffee-symbolic.svg"
      install -Dm644 resources/icons/hicolor/scalable/apps/icon.svg "$out/share/icons/hicolor/scalable/apps/com.github.codevardhan.caffeine-applet.svg"
    '';
  };
  kdeconnect = mkApp "kdeconnect" {
    pname = "cosmic-ext-connect-applet";
    cargoBuildFlags = [
      "-p"
      "cosmic-ext-connect-applet"
    ];
    cargoTestFlags = [
      "-p"
      "cosmic-ext-connect-applet"
    ];
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.dbus
      pkgs.sqlite
      pkgs.aws-lc
      pkgs.libpulseaudio
    ];
    postInstall = ''
      install -Dm644 resources/io.github.hepp3n.kdeconnect.desktop "$out/share/applications/io.github.hepp3n.kdeconnect.desktop"
      install -Dm644 resources/io.github.hepp3n.kdeconnect.metainfo.xml "$out/share/metainfo/io.github.hepp3n.kdeconnect.metainfo.xml"
      install -Dm644 resources/io.github.hepp3n.kdeconnect.svg "$out/share/icons/hicolor/scalable/apps/io.github.hepp3n.kdeconnect.svg"
    '';
  };
  cosmic-ext-applet-privacy-indicator = mkApp "cosmic-ext-applet-privacy-indicator" {
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.dbus
      pkgs.pipewire
      pkgs.libclang.lib
    ];
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.stdenv.cc.libc.dev}/include";
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    postInstall = ''
      install -Dm644 res/dev.DBrox.CosmicPrivacyIndicator.desktop "$out/share/applications/dev.DBrox.CosmicPrivacyIndicator.desktop"
      install -Dm644 res/dev.DBrox.CosmicPrivacyIndicator.metainfo.xml "$out/share/metainfo/dev.DBrox.CosmicPrivacyIndicator.metainfo.xml"
      install -Dm644 res/dev.DBrox.CosmicPrivacyIndicator.svg "$out/share/icons/hicolor/scalable/apps/dev.DBrox.CosmicPrivacyIndicator.svg"
    '';
  };
  starrydex = mkApp "starrydex" {
    postInstall =
      resources "dev.mariinkys.StarryDex" "resources"
        "icons/hicolor/scalable/apps/icon.svg";
  };
  clipboard-manager = mkApp "clipboard-manager" {
    buildInputs = [
      pkgs.openssl
      pkgs.fontconfig
      pkgs.sqlite
    ];
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
  cosmic-ext-applet-workspace-icons = mkApp "cosmic-ext-applet-workspace-icons" {
    postInstall = ''
      install -Dm644 resources/io.github.crocodile.cosmic-ext-applet-workspace-icons.desktop "$out/share/applications/io.github.crocodile.cosmic-ext-applet-workspace-icons.desktop"
      install -Dm644 resources/io.github.crocodile.cosmic-ext-applet-workspace-icons.metainfo.xml "$out/share/metainfo/io.github.crocodile.cosmic-ext-applet-workspace-icons.metainfo.xml"
      install -Dm644 resources/io.github.crocodile.cosmic-ext-applet-workspace-icons.svg "$out/share/icons/hicolor/scalable/apps/io.github.crocodile.cosmic-ext-applet-workspace-icons.svg"
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
