# EXAMPLE ONLY: replace disk labels, hardware and account credentials before installing.
{ lib, ... }:
{
  imports = [
    ../profiles/workstation.nix
    ../profiles/sway.nix
  ];
  networking.hostName = "sauce";
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  system.stateVersion = "25.11";

  # This host uses systemd-boot by default. To enable Secure Boot, provision
  # Lanzaboote keys first (see README), then set boot.lanzaboote.enable = true.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS + ext4 option: uncomment and replace the UUID with the LUKS UUID
  # from blkid. This assumes the ext4 root filesystem is inside the LUKS
  # container; keep /boot on its separate unencrypted EFI partition.
  # boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/<LUKS-UUID>";
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  # To use the LUKS + ext4 option above, replace the sample root filesystem:
  # fileSystems."/" = {
  #   device = "/dev/mapper/cryptroot";
  #   fsType = "ext4";
  # };
  # For encrypted Btrfs instead, use its actual subvolume and mount options:
  # fileSystems."/" = {
  #   device = "/dev/mapper/cryptroot";
  #   fsType = "btrfs";
  #   options = [ "subvol=@" "compress=zstd" ];
  # };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
  };

  sauce.system = {
    user = "sauce";
    tailscale = false;
    rslsync = false;
    fingerprint = false;
    nvidia = false;
    plymouthTheme = "arch";
  };
  # The user is intentionally locked until you set a password/hash through a safe channel.
  # users.users.sauce.hashedPasswordFile = "/run/secrets/sauce-password";
}
