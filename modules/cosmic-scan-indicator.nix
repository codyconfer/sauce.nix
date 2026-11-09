{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  script = pkgs.writeText "sauce-cosmic-scan-indicator.py" (
    builtins.readFile ../dotfiles/cosmic/scan-indicator.py
  );
in
{
  config =
    lib.mkIf
      (cfg.enable && cfg.machineRole != "server" && builtins.elem "cosmic" cfg.desktopEnvironments)
      {
        systemd.user.services.sauce-cosmic-scan-indicator = {
          Unit = {
            Description = "Tint COSMIC panel and dock orange during scheduled ClamAV scans";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.python3}/bin/python3 ${script}";
            Environment = [ "PATH=${lib.makeBinPath [ pkgs.systemd ]}" ];
            Restart = "on-failure";
            RestartSec = 3;
            UMask = "0077";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
}
