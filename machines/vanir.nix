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
  networking.firewall = {
    enable = true;
    interfaces.wlp0s20f3.allowedTCPPorts = [ 9000 ];
    interfaces.tailscale0.allowedTCPPorts = [ 9000 ];
  };
  services.resilio = {
    enableWebUI = true;
    httpListenAddr = "0.0.0.0";
    httpListenPort = 9000;
  };
  systemd.services.resilio = {
    serviceConfig = {
      EnvironmentFile = "/run/secrets/resilio-webui.env";
      ExecStart = lib.mkForce (
        let
          start = pkgs.writeShellScriptBin "resilio-start-authenticated" ''
            set -eu
            : "''${RESILIO_WEBUI_LOGIN:?Set RESILIO_WEBUI_LOGIN in /run/secrets/resilio-webui.env}"
            : "''${RESILIO_WEBUI_PASSWORD:?Set RESILIO_WEBUI_PASSWORD in /run/secrets/resilio-webui.env}"
            config=/run/rslsync/config.json
            ${pkgs.jq}/bin/jq --arg login "$RESILIO_WEBUI_LOGIN" --arg password "$RESILIO_WEBUI_PASSWORD" '.webui.login = $login | .webui.password = $password' "$config" > "$config.authenticated"
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
    tailscale = true;
    nvidia = false;
    clamav.daemon = true;
  };

  services.fail2ban.enable = true;
  security.auditd.enable = true;
}
