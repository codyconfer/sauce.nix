{ lib, ... }:
{
  sauce = {
    machineRole = lib.mkDefault "mobile";
    enable = lib.mkDefault true;
    headless = lib.mkDefault false;
    guiApps = lib.mkDefault [
      "firefox"
      "alacritty"
    ];
  };
}
