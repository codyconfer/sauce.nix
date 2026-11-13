{ lib, pkgs, ... }:
{
  imports = [
    ../profiles/desktops/sway.nix
    ../profiles/desktops/cosmic.nix
    ../profiles/workflows/default.nix
    ../profiles/workflows/dev.nix
    ../profiles/workflows/radio.nix
    ../profiles/workflows/video.nix
    ../profiles/workflows/music.nix
    ../profiles/workflows/photo.nix
    ../profiles/workflows/gaming.nix
    ../profiles/work.nix
  ];

  # Disk layout, bootloader, and installation state belong in /etc/nixos.
  networking.hostName = lib.mkForce "tyr";
  sauce.enable = true;
  sauce.machineRole = "workstation";
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

  # Sway requires an explicit opt-in for the proprietary NVIDIA driver.
  programs.sway.extraOptions = [ "--unsupported-gpu" ];

  sauce.system = {
    user = "codyconfer";
    homeStateVersion = "26.05";
    tailscale = true;
    nvidia = true;
    clamav.daemon = true;
  };

  services.fail2ban.enable = true;
  security.auditd.enable = true;
}
