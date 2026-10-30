{ lib, ... }:
{
  sauce = {
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
      "rustup"
      "tmux"
      "yarn"
      "docker"
    ];
  };
}
