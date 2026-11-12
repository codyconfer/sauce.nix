{
  pkgs,
  workstation,
  personal,
  server,
  mobile,
}:
let
  inherit (pkgs) lib;
  swayText = workstation.config.xdg.configFile."sway/config".text;
  waybarSwayText = workstation.config.xdg.configFile."waybar/config-sway.jsonc".text;
  footText = builtins.readFile (workstation.config.xdg.configFile.foot.source + "/foot.ini");
  flatpakText = lib.concatStringsSep " " workstation.config.systemd.user.services.sauce-flatpaks.Service.ExecStart;
  serverFiles = builtins.attrNames server.config.xdg.configFile;
  cosmicPackages = builtins.attrValues (import ../packages/cosmic { inherit pkgs; }) ++ [
    pkgs.forecast
    pkgs.cosmic-ext-applet-privacy-indicator
  ];
in
assert lib.hasInfix "SIGNAL_PASSWORD_STORE=gnome-libsecret" (
  personal.config.xdg.dataFile."flatpak/overrides/org.signal.Signal".text
);
assert lib.all (app: lib.elem app personal.config.sauce.guiApps) [
  "libreoffice"
  "ardour"
  "lmms"
  "zrythm"
  "qtractor"
  "helio"
  "reaper"
  "gimp"
  "kdenlive"
  "shotcut"
  "davinci-resolve"
];
assert lib.all (package: lib.elem package personal.config.home.packages) [
  pkgs.zrythm
  pkgs.qtractor
  pkgs.helio-workstation
  pkgs.lmms
  pkgs.ardour
  pkgs.libreoffice
  pkgs.reaper
  pkgs.gimp
  pkgs.kdePackages.kdenlive
  pkgs.shotcut
  pkgs.davinci-resolve
];
assert lib.all (package: !(lib.elem package server.config.home.packages)) [
  pkgs.zrythm
  pkgs.qtractor
  pkgs.helio-workstation
  pkgs.lmms
  pkgs.ardour
  pkgs.libreoffice
  pkgs.reaper
  pkgs.gimp
  pkgs.kdePackages.kdenlive
  pkgs.shotcut
  pkgs.davinci-resolve
];
assert personal.config.home.activation ? seedPhotoGimp;
assert !(workstation.config.home.activation ? seedPhotoGimp);
assert !(server.config.home.activation ? seedPhotoGimp);
assert lib.elem "affinity" personal.config.sauce.guiApps;
assert lib.elem pkgs.affinity-v3 personal.config.home.packages;
assert !(lib.elem pkgs.affinity-v3 workstation.config.home.packages);
assert !(lib.elem pkgs.affinity-v3 server.config.home.packages);
assert personal.config.sauce.packageOverrides.bitwarden ? sauceTrayIcon;
assert lib.elem personal.config.sauce.packageOverrides.bitwarden personal.config.home.packages;
assert !(lib.elem personal.config.sauce.packageOverrides.bitwarden server.config.home.packages);
assert !(builtins.hasAttr "flatpak/overrides/org.signal.Signal" workstation.config.xdg.dataFile);
assert !(builtins.hasAttr "flatpak/overrides/org.signal.Signal" server.config.xdg.dataFile);
assert workstation.config.sauce.machineRole == "workstation";
assert lib.elem "sway" workstation.config.sauce.desktopEnvironments;
assert lib.elem "kde" workstation.config.sauce.desktopEnvironments;
assert lib.elem "cosmic" workstation.config.sauce.desktopEnvironments;
assert
  workstation.config.systemd.user.services.sauce-cosmic-scan-indicator.Install.WantedBy
  == [ "graphical-session.target" ];
assert !(builtins.hasAttr "sauce-cosmic-scan-indicator" server.config.systemd.user.services);
assert !(builtins.hasAttr "sauce-cosmic-scan-indicator" mobile.config.systemd.user.services);
assert builtins.length cosmicPackages == 7;
assert lib.all (package: lib.elem package workstation.config.home.packages) cosmicPackages;
assert lib.all (package: !(lib.elem package server.config.home.packages)) cosmicPackages;
assert lib.all (package: !(lib.elem package mobile.config.home.packages)) cosmicPackages;
assert !(builtins.hasAttr "cosmic" workstation.config.xdg.configFile);
assert !(builtins.hasAttr "cosmic" server.config.xdg.configFile);
assert !(builtins.hasAttr "cosmic" mobile.config.xdg.configFile);
assert lib.elem "lxqt" workstation.config.sauce.desktopEnvironments;
assert lib.elem "gnome" workstation.config.sauce.desktopEnvironments;
assert lib.elem "alacritty" workstation.config.sauce.guiApps;
assert lib.elem "podman-desktop" workstation.config.sauce.guiApps;
assert lib.elem pkgs.podman-desktop workstation.config.home.packages;
assert lib.all (app: lib.elem app workstation.config.sauce.guiApps) [
  "sdrpp"
  "gqrx"
];
assert lib.all (package: lib.elem package workstation.config.home.packages) [
  pkgs.sdrpp
  pkgs.gqrx
];
assert lib.all (package: !(lib.elem package server.config.home.packages)) [
  pkgs.sdrpp
  pkgs.gqrx
];
assert lib.all (package: !(lib.elem package mobile.config.home.packages)) [
  pkgs.sdrpp
  pkgs.gqrx
];
assert lib.elem pkgs.nil workstation.config.home.packages;
assert lib.elem pkgs.nixd workstation.config.home.packages;
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).theme == "Tokyo Night";
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).vim_mode == true;
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).buffer_font_size == 11;
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).buffer_font_family == "Hack Nerd Font";
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).lsp.nil.binary.path == lib.getExe pkgs.nil;
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).lsp.nixd.binary.path == lib.getExe pkgs.nixd;
assert !(builtins.hasAttr "zed/settings.json" server.config.xdg.configFile);
assert !(lib.elem pkgs.nil server.config.home.packages);
assert lib.hasInfix "swayr switch-window" swayText;
assert lib.hasInfix "set $term foot" swayText;
assert lib.hasInfix "sway/workspaces" waybarSwayText;
assert lib.hasInfix "term=foot" footText;
assert !(lib.hasInfix "40.6" (swayText + waybarSwayText));
assert lib.hasInfix "grimshot copy area" swayText;
assert lib.hasInfix "sauce-power" swayText;
assert !(lib.hasInfix "$bin/zofi" swayText);
assert !(lib.hasInfix "$bin/lumactl" swayText);
assert lib.hasInfix "sauce-flatpaks" flatpakText;
assert server.config.sauce.machineRole == "server";
assert builtins.elem "sway" server.config.sauce.guiApps;
assert server.config.sauce.flatpaks == [ "signal" ];
assert !(builtins.elem "sway/config" serverFiles);
assert !(builtins.hasAttr "sauce-flatpaks" server.config.systemd.user.services);
assert !(builtins.elem pkgs.vlc server.config.home.packages);
assert builtins.elem pkgs.ffmpeg server.config.home.packages;
assert mobile.config.sauce.machineRole == "mobile";
assert mobile.config.fonts.fontconfig.enable;
assert mobile.config.sauce.desktopEnvironments == [ ];
pkgs.runCommand "sauce-configuration-tests" { } ''
  ${pkgs.python3}/bin/python3 ${./cosmic-scan-indicator.py} ${../dotfiles/cosmic/scan-indicator.py}
  init=${lib.getExe (import ../packages/photogimp.nix { inherit pkgs; })}
  target="$TMPDIR/GIMP/3.2"
  mkdir -p "$target"
  echo original > "$target/gimprc"
  "$init" "$target"
  test -f "$target/shortcutsrc"
  test -w "$target/gimprc"
  grep -qx original "$target".photogimp-backup.*/gimprc
  echo customized > "$target/gimprc"
  "$init" "$target"
  grep -qx customized "$target/gimprc"
  "$init" "$TMPDIR/fresh/GIMP/3.2"
  test -f "$TMPDIR/fresh/GIMP/3.2/.sauce-photogimp-initialized"
  ln -s "$target" "$TMPDIR/symlink"
  # A symlink without our marker must be rejected rather than overwritten.
  mkdir "$TMPDIR/untouched"
  ln -s "$TMPDIR/untouched" "$TMPDIR/unsafe"
  if "$init" "$TMPDIR/unsafe"; then
    echo "PhotoGIMP unexpectedly accepted a symlink" >&2
    exit 1
  fi
  touch "$out"
''
