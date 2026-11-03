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
in
assert lib.hasInfix "SIGNAL_PASSWORD_STORE=gnome-libsecret" (
  personal.config.xdg.dataFile."flatpak/overrides/org.signal.Signal".text
);
assert !(builtins.hasAttr "flatpak/overrides/org.signal.Signal" workstation.config.xdg.dataFile);
assert !(builtins.hasAttr "flatpak/overrides/org.signal.Signal" server.config.xdg.dataFile);
assert workstation.config.sauce.machineRole == "workstation";
assert lib.elem "sway" workstation.config.sauce.desktopEnvironments;
assert lib.elem "kde" workstation.config.sauce.desktopEnvironments;
assert lib.elem "cosmic" workstation.config.sauce.desktopEnvironments;
assert workstation.config.xdg.configFile.cosmic.recursive;
assert
  builtins.readFile (
    workstation.config.xdg.configFile.cosmic.source + "/com.system76.CosmicPanel.Dock/v1/anchor"
  ) == "Left";
assert !(builtins.hasAttr "cosmic" server.config.xdg.configFile);
assert !(builtins.hasAttr "cosmic" mobile.config.xdg.configFile);
assert lib.elem "lxqt" workstation.config.sauce.desktopEnvironments;
assert lib.elem "gnome" workstation.config.sauce.desktopEnvironments;
assert lib.elem "alacritty" workstation.config.sauce.guiApps;
assert lib.elem pkgs.nil workstation.config.home.packages;
assert lib.elem pkgs.nixd workstation.config.home.packages;
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).lsp.nil.binary.path
  == lib.getExe pkgs.nil;
assert
  (builtins.fromJSON (
    builtins.unsafeDiscardStringContext workstation.config.xdg.configFile."zed/settings.json".text
  )).lsp.nixd.binary.path
  == lib.getExe pkgs.nixd;
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
  touch "$out"
''
