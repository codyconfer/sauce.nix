{ config, lib, ... }:
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

  # Signal's Flatpak defaults to a plaintext database key unless opted in.
  xdg.dataFile."flatpak/overrides/org.signal.Signal" = lib.mkIf (
    config.sauce.enable
    && config.sauce.machineRole != "server"
    && builtins.elem "signal" config.sauce.flatpaks
  ) {
    text = ''
      [Environment]
      SIGNAL_PASSWORD_STORE=gnome-libsecret
    '';
  };
}
