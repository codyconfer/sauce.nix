{ lib, ... }:
{
  sauce.desktopEnvironments = lib.mkDefault [ "gnome" ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
