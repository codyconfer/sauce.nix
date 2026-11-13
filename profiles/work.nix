{ lib, ... }:
{
  sauce = {
    tools = lib.mkDefault [
      "aws"
      "azure-cli"
      "gcloud"
      "claude-code"
    ];
    guiApps = lib.mkDefault [
      "codex"
    ];
    flatpaks = lib.mkDefault [
      "zoom"
    ];
  };
}
