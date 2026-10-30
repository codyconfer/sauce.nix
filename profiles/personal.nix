{ lib, ... }:
{
  sauce = {
    tools = lib.mkDefault [
      "bitwarden-cli"
      "wrangler"
    ];
    guiApps = lib.mkDefault [
      "obsidian"
      "bitwarden"
    ];
    flatpaks = lib.mkDefault [
      "discord"
      "signal"
    ];
  };
}
