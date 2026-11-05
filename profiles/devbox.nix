{ lib, pkgs, ... }:
{
  sauce = {
    netTools = true;
    extraPackages = with pkgs; [
      libargon2
      openssl
    ];
    tools = lib.mkDefault [
      "adb"
      "dotnet"
      "go"
      "k3s"
      "k9s"
      "llama.cpp"
      "nvim"
      "nvm"
      "pi"
      "poetry"
      "pyenv"
      "pnpm"
      "rustup"
      "tmux"
      "docker"
    ];
  };
}
