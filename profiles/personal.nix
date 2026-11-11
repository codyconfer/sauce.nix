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
        "bitwarden"
        "reaper"
        "gimp"
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ "affinity" ]
    );
    photoGimp = lib.mkDefault true;
    signalKeyring = lib.mkDefault true;
    flatpaks = lib.mkDefault [
      "discord"
      "signal"
    ];
  };

}
