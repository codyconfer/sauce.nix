{ lib, pkgs, ... }:
{
  sauce = {
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
      "adb"
      "k9s"
      "pi"
      "tmux"
      "docker"
    ];
    guiApps = lib.mkDefault [
      "sourcegit"
      "vscode"
      "zed"
      "docker"
      "podman-desktop"
      "ghidra"
      "jetbrains-toolbox"
      "lmstudio"
    ];
  };
}
