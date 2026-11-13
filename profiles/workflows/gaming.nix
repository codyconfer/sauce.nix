{ lib, ... }:
{
  sauce = {
    emulators = lib.mkDefault [
      "steam"
      "wine"
    ];
    flatpaks = lib.mkDefault [
      "lutris"
      "retroarch"
    ];
  };
}
