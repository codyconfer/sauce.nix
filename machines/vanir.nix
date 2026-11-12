{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../profiles/devbox.nix
    ../profiles/personal.nix
    ../profiles/cosmic.nix
    ../profiles/remote.nix
    ../profiles/workstation.nix
    ../profiles/gaming.nix
    ../profiles/mobile.nix
  ];

  # Disk layout, bootloader, and installation state belong in /etc/nixos.
  networking.hostName = lib.mkForce "vanir";
  sauce.machineRole = "workstation";
  sauce.sway.terminal = "alacritty";
  networking.firewall.enable = true;
  services.firewalld.zones = {
    resilio-lan = {
      target = "DROP";
      interfaces = [ "wlp0s20f3" ];
      ports = [
        {
          port = 9000;
          protocol = "tcp";
        }
      ];
    };
    tailscale.ports = [
      {
        port = 9000;
        protocol = "tcp";
      }
    ];
  };
  services.resilio = {
    enableWebUI = true;
    httpListenAddr = "0.0.0.0";
    httpListenPort = 9000;
  };
  systemd.services.resilio = {
    serviceConfig = {
      EnvironmentFile = "/var/lib/sauce/secrets/resilio-webui.env";
      ExecStart = lib.mkForce (
        let
          start = pkgs.writeShellScriptBin "resilio-start-authenticated" ''
            set -eu
            : "''${RESILIO_WEBUI_LOGIN:?Set RESILIO_WEBUI_LOGIN in /var/lib/sauce/secrets/resilio-webui.env}"
            : "''${RESILIO_WEBUI_PASSWORD_HASH:?Set RESILIO_WEBUI_PASSWORD_HASH in /var/lib/sauce/secrets/resilio-webui.env}"
            config=/run/rslsync/config.json
            ${pkgs.jq}/bin/jq '.webui.login = env.RESILIO_WEBUI_LOGIN | .webui.password_hash = env.RESILIO_WEBUI_PASSWORD_HASH | del(.webui.password, .webui.password_hash_unified)' "$config" > "$config.authenticated"
            chmod 0400 "$config.authenticated"
            exec ${config.services.resilio.package}/bin/rslsync --nodaemon --config "$config.authenticated"
          '';
        in
        "${start}/bin/resilio-start-authenticated"
      );
    };
  };
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  # Ly delegates authentication to the login PAM stack.
  security.pam.services.login.rules.auth.fprintd.settings.timeout = 7;

  boot.kernelModules = [ "kvm-intel" ];
  hardware.bluetooth.enable = true;
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
  ];

  sauce.system = {
    user = "codyconfer";
    homeStateVersion = "26.05";
    remote.codeServerEnvironmentFile = "/var/lib/sauce/secrets/code-server.env";
    tailscale = true;
    fingerprint = true;
    nvidia = false;
    clamav.daemon = true;
  };

  systemd.tmpfiles.rules = [
    "d /srv/sync 2770 rslsync rslsync -"
    "d /srv/sync/downloads 2770 rslsync rslsync -"
  ];

  services.fail2ban.enable = true;
  security.auditd.enable = true;
}
