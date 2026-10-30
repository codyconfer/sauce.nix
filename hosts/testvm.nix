{ ... }:
{
  imports = [
    ../profiles/workstation.nix
    ../profiles/gnome.nix
  ];

  networking.hostName = "sauce-testvm";
  system.stateVersion = "25.11";

  sauce.system.user = "testvm";
  users.users.testvm = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # This host is for disposable local VM testing only. Auto-login is enabled
  # because the VM account intentionally has no password.
  services.displayManager.autoLogin = {
    enable = true;
    user = "testvm";
  };

  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    graphics = true;
  };
}
