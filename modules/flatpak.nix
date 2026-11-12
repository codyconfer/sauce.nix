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
      ${lib.optionalString (builtins.elem "easyeffects" cfg.flatpaks) ''
        flatpak permission-set background background ${catalog.flatpaks.easyeffects} yes
      ''}
    '';
  };
in
{
  config = lib.mkIf enabled {
    xdg.dataFile."flatpak/overrides/org.signal.Signal" =
      lib.mkIf (cfg.signalKeyring && builtins.elem "signal" cfg.flatpaks)
        {
          text = ''
            [Environment]
            SIGNAL_PASSWORD_STORE=gnome-libsecret
          '';
        };
    home.packages = [
      sync
      pkgs.flatpak
    ];
    home.sessionPath = [
      "$HOME/.local/share/flatpak/exports/bin"
      "/var/lib/flatpak/exports/bin"
    ];
    systemd.user.startServices = lib.mkDefault "sd-switch";
    systemd.user.services.sauce-easyeffects = lib.mkIf (builtins.elem "easyeffects" cfg.flatpaks) {
      Unit = {
        Description = "EasyEffects background audio processing";
        PartOf = [ "graphical-session.target" ];
        Wants = [ "sauce-flatpaks.service" ];
        After = [
          "graphical-session.target"
          "sauce-flatpaks.service"
        ];
      };
      Service = {
        # Compatible with both GTK and Qt EasyEffects releases; starts hidden.
        ExecStart = "${pkgs.flatpak}/bin/flatpak run ${catalog.flatpaks.easyeffects} --gapplication-service";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
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
