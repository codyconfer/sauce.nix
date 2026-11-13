{ lib, ... }:
{
  sauce = {
    guiApps = lib.mkDefault [
      "firefox"
      "sway"
      "alacritty"
      "obsidian"
      "typora"
      "libreoffice"
    ];
    flatpaks = lib.mkDefault [
      "slack"
      "easyeffects"
      "zen"
    ];
    media = lib.mkDefault [
      "vlc"
      "audacious"
      "quodlibet"
      "ffmpeg"
    ];
  };
}
