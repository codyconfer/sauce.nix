{ lib, ... }:
{
  sauce = {
    netTools = true;
    tools = lib.mkDefault [
      "adb"
      "dotnet"
      "go"
      "k3s"
      "k9s"
      "kubectl"
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
