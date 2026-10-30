{ ... }:
{
  imports = [
    ../profiles/workstation.nix
    ../profiles/gnome.nix
  ];

  networking.hostName = "testvm";
  system.stateVersion = "25.11";

  sauce.system.user = "testvm";
  users.users.testvm = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

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
