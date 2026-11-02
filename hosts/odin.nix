{ lib, pkgs, ... }:
{
  imports = [
    ../profiles/workstation.nix
    ../profiles/cosmic.nix
    ../profiles/sway.nix
    ../profiles/devbox.nix
    ../profiles/remote.nix
    ../profiles/gaming.nix
  ];

  networking.hostName = "odin";
  nixpkgs.hostPlatform = "x86_64-linux";
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "26.05";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/a7c0cfaf-22c0-4754-9c1e-2bb6b9125ee6";
  boot.initrd.luks.devices."cryptdata".device =
    "/dev/disk/by-uuid/8fedde26-0ddb-43f2-83e5-fb3e5738e5bc";
  boot.initrd.luks.devices."luks-497e4eb6-ceeb-4a47-a6d6-bf79214f54b5".device =
    "/dev/disk/by-uuid/497e4eb6-ceeb-4a47-a6d6-bf79214f54b5";
  swapDevices = [
    { device = "/dev/mapper/luks-497e4eb6-ceeb-4a47-a6d6-bf79214f54b5"; }
  ];
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7E5E-E9AE";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
  fileSystems."/mnt/data" = {
    device = "/dev/mapper/cryptdata";
    fsType = "ext4";
  };
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/aa9243e5-99dc-4e88-963b-30c490588319";
    fsType = "ext4";
  };

  sauce.system = {
    user = "codyconfer";
    homeStateVersion = "26.05";
    remote = {
      sshAuthorizedKeysFile = "/var/lib/sauce/ssh-authorized-keys/%u";
      codeServerEnvironmentFile = "/var/lib/sauce/secrets/code-server.env";
    };
    tailscale = true;
    nvidia = true;
    displayManager = true;
    plymouthTheme = "bgrt";
  };

  services.displayManager.defaultSession = "cosmic";

  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  networking.firewall.enable = true;
  hardware.bluetooth.enable = true;
}
