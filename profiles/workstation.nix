{ lib, ... }:
{
  sauce = {
    machineRole = lib.mkDefault "workstation";
    enable = lib.mkDefault true;
    desktopEnvironments = lib.mkDefault [ "sway" ];
    guiApps = lib.mkDefault [
      "firefox"
      "remmina"
      "sway"
      "alacritty"
      "sourcegit"
      "vscode"
      "zed"
      "docker"
      "podman-desktop"
      "ghidra"
      "jetbrains-toolbox"
      "lmstudio"
      "gnuradio"
      "sdrpp"
      "gqrx"
      "qdmr"
    ];
    flatpaks = lib.mkDefault [
      "slack"
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
