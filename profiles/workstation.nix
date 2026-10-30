{ lib, ... }:
{
  sauce = {
    machineRole = lib.mkDefault "workstation";
    enable = lib.mkDefault true;
    headless = lib.mkDefault false;
    guiApps = lib.mkDefault [
      "firefox"
      "alacritty"
      "sourcegit"
      "vscode"
      "zed"
      "docker"
      "ghidra"
      "jetbrains-toolbox"
      "lmstudio"
      "gnuradio"
      "qdmr"
    ];
    flatpaks = lib.mkDefault [
      "easyeffects"
      "obs-studio"
      "zen"
      "chirp"
      "sonic-pi"
    ];
    media = lib.mkDefault [
      "vlc"
      "audacious"
      "quodlibet"
      "ffmpeg"
    ];
  };
}
