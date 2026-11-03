{ lib, pkgs, ... }:
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
