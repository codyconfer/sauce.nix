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
    signalKeyring = lib.mkDefault true;
    flatpaks = lib.mkDefault [
      "discord"
      "signal"
    ];
  };
}
