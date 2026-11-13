{
  lib,
  pkgs,
  ...
}:
{
  sauce = {
    guiApps = lib.mkDefault (
      [
        "kdenlive"
        "shotcut"
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ "davinci-resolve" ]
    );
    flatpaks = lib.mkDefault [ "obs-studio" ];
  };
}
