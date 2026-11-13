{ lib, ... }:
{
  sauce = {
    desktopEnvironments = lib.mkDefault [ "sway" ];
    guiApps = lib.mkDefault [ "sway" ];
    sway.terminal = "alacritty";
  };
}
