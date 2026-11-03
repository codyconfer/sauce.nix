{ pkgs, ... }:
{
  imports = [
    ../profiles/personal.nix
    ../profiles/devbox.nix
    ../profiles/cosmic.nix
    ../profiles/kde.nix
    ../profiles/remote.nix
    ../profiles/workstation.nix
    ../profiles/gaming.nix
    ../profiles/mobile.nix
  ];

  # Disk layout, bootloader, and installation state belong in /etc/nixos.
  networking.hostName = "vanir";
  sauce.machineRole = "workstation";
  networking.firewall.enable = true;
  services.displayManager.defaultSession = "cosmic";
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "kvm-intel" ];
  hardware.bluetooth.enable = true;

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
