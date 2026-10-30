{
  pkgs,
  workstation,
  server,
  mobile,
}:
let
  inherit (pkgs) lib;
  swayText = workstation.config.xdg.configFile."sway/config".text;
  flatpakText = lib.concatStringsSep " " workstation.config.systemd.user.services.sauce-flatpaks.Service.ExecStart;
  serverFiles = builtins.attrNames server.config.xdg.configFile;
in
assert workstation.config.sauce.machineRole == "workstation";
assert workstation.config.sauce.desktopEnvironment == "sway";
assert lib.elem "sway" workstation.config.sauce.guiApps;
assert lib.hasInfix "swayr switch-window" swayText;
assert lib.hasInfix "grimshot copy area" swayText;
assert lib.hasInfix "sauce-power" swayText;
assert !(lib.hasInfix "$bin/zofi" swayText);
assert !(lib.hasInfix "$bin/lumactl" swayText);
assert lib.hasInfix "sauce-flatpaks" flatpakText;
assert server.config.sauce.machineRole == "server";
assert server.config.sauce.headless;
assert !(builtins.elem "sway/config" serverFiles);
assert !(builtins.hasAttr "sauce-flatpaks" server.config.systemd.user.services);
assert mobile.config.sauce.machineRole == "mobile";
assert !mobile.config.sauce.headless;
assert mobile.config.sauce.desktopEnvironment == null;
pkgs.runCommand "sauce-configuration-tests" { } ''
  touch "$out"
''
