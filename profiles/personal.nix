{
  lib,
  pkgs,
  ...
}:
{
  sauce = {
    tools = lib.mkDefault [
      "bitwarden-cli"
      "wrangler"
    ];
    guiApps = lib.mkDefault (
      [
        "obsidian"
        "libreoffice"
        "bitwarden"
        "reaper"
        "ardour"
        "lmms"
        "zrythm"
        "qtractor"
        "helio"
        "gimp"
        "kdenlive"
        "shotcut"
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "affinity"
        "davinci-resolve"
      ]
    );
    photoGimp = lib.mkDefault true;
    signalKeyring = lib.mkDefault true;
    flatpaks = lib.mkDefault [
      "discord"
      "signal"
    ];
  };

}
