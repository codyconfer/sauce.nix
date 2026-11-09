{ lib, ... }:
{
  sauce = {
    tools = lib.mkDefault [
      "1password-cli"
      "aws"
      "azure-cli"
      "gcloud"
      "claude-code"
    ];
    guiApps = lib.mkDefault [
      "1password"
      "codex"
    ];
    flatpaks = lib.mkDefault [
      "zoom"
    ];
  };
}
