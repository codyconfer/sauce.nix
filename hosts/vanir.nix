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
  # Keep workstation capabilities while also applying mobile's firewall default.
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

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/<LUKS-UUID>";
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
    device = "/dev/disk/by-uuid/<EFI-UUID>";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  sauce.system = {
    user = "codyconfer";
    homeStateVersion = "26.05";
    tailscale = true;
    nvidia = false;
    clamav.daemon = true;
  };

  # Temporary bootstrap access; disable after SSH keys are provisioned.
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  hardware.bluetooth.enable = true;
  services.fail2ban.enable = true;
  security.auditd.enable = true;
}
