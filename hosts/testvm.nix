{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    ../profiles/workstation.nix
    ../profiles/gnome.nix
  ];

  networking.hostName = "testvm";
  system.stateVersion = "25.11";

  sauce.system.user = "testvm";
  users.users.testvm = {
    isNormalUser = true;
    initialPassword = "";
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;
  services.displayManager.defaultSession = "gnome";
  services.displayManager.autoLogin = {
    enable = true;
    user = "testvm";
  };

  virtualisation = {
    memorySize = 4096;
    cores = 4;
    graphics = true;
  };
}
