{ lib, pkgs, ... }:
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

  networking.hostName = "vanir";
  sauce.machineRole = "workstation";
  networking.firewall.enable = true;
  services.displayManager.defaultSession = "cosmic";
  nixpkgs.hostPlatform = "x86_64-linux";
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "26.05";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/7a1abf0d-7ffc-4fed-aadc-3eb9c8b3e9b1";
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0EE7-F6E5";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
  swapDevices =
    [ { device = "/dev/mapper/luks-2a31f243-8226-4a27-b03d-4fd6b76339a1"; }
    ];

  sauce.system = {
    user = "codyconfer";
    homeStateVersion = "26.05";
    tailscale = true;
    nvidia = false;
    clamav.daemon = true;
  };

  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  hardware.bluetooth.enable = true;
  services.fail2ban.enable = true;
  security.auditd.enable = true;
}
