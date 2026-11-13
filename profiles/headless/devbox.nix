{ lib, pkgs, ... }:
{
  sauce = {
    devbox.enable = lib.mkDefault true;
    netTools = true;
    extraPackages = with pkgs; [
      libargon2
      openssl
    ];
    tools = lib.mkDefault [
      "dotnet"
      "go"
      "k3s"
      "llama.cpp"
      "nvim"
      "nvm"
      "poetry"
      "pyenv"
      "pnpm"
      "rustup"
    ];
  };
}
