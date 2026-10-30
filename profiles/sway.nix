{ lib, ... }:
{
  sauce = {
    desktopEnvironment = lib.mkDefault "sway";
    guiApps = lib.mkDefault [ "sway" ];
  };
}
