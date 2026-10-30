{ lib, ... }:
{
  sauce = {
    desktopEnvironments = lib.mkDefault [ "sway" ];
    guiApps = lib.mkDefault [ "sway" ];
  };
}
