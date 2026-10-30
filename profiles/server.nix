{ lib, ... }:
{
  sauce = {
    machineRole = lib.mkDefault "server";
    enable = lib.mkDefault true;
    headless = lib.mkDefault true;
    guiApps = lib.mkDefault [ ];
    emulators = lib.mkDefault [ ];
    flatpaks = lib.mkDefault [ ];
    media = lib.mkDefault [ ];
    extras = lib.mkDefault false;
    netTools = lib.mkDefault false;
  };
}
