{ lib, ... }:
{
  sauce = {
    machineRole = lib.mkDefault "mobile";
    enable = lib.mkDefault true;
  };
}
