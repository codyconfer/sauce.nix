{ lib, ... }:
{
  sauce = {
    desktopEnvironment = lib.mkDefault "hyprland";
    guiApps = lib.mkDefault [ "hyprland" ];
  };
}
