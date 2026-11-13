{
  lib,
  pkgs,
  ...
}:
{
  sauce = {
    guiApps = lib.mkDefault (
      [
        "reaper"
        "nam"
        "guitarix"
        "ardour"
        "lmms"
        "zrythm"
        "qtractor"
        "helio"
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ "byod" ]
    );
    flatpaks = lib.mkDefault [ "sonic-pi" ];
  };
}
