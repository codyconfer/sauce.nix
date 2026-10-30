{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  catalog = import ../lib/catalog.nix;
  enabled = cfg.enable && cfg.machineRole != "server" && cfg.flatpaks != [ ];
  ids = map (name: catalog.flatpaks.${name}) cfg.flatpaks;
  sync = pkgs.writeShellApplication {
    name = "sauce-flatpaks";
    runtimeInputs = [ pkgs.flatpak ];
    text = ''
      flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      flatpak install --user --noninteractive --or-update flathub ${lib.escapeShellArgs ids}
    '';
  };
in
{
  config = lib.mkIf enabled {
    home.packages = [
      sync
      pkgs.flatpak
    ];
    home.sessionPath = [
      "$HOME/.local/share/flatpak/exports/bin"
      "/var/lib/flatpak/exports/bin"
    ];
    systemd.user.startServices = lib.mkDefault "sd-switch";
    systemd.user.services.sauce-flatpaks = {
      Unit = {
        Description = "Install selected .sauce Flathub applications";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${sync}/bin/sauce-flatpaks";
        RemainAfterExit = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
