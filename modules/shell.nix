{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  cfg = config.sauce;
  has = name: builtins.elem name cfg.tools;
  nvmSource = pkgs.fetchFromGitHub {
    owner = "nvm-sh";
    repo = "nvm";
    rev = "v0.40.3";
    hash = "sha256-s36EQojnNKm4x410nllC3nbnzzwcLZCKSP3DkJPpjjo=";
  };
  nvmInit = lib.optionalString (has "nvm") ''
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"
    source ${nvmSource}/nvm.sh
  '';
  common = ''
    source "$HOME/.config/sauce/functions.sh"
    _sauce_print_header
  '';
  rebuild = pkgs.writeShellApplication {
    name = "sauce-rebuild";
    runtimeInputs = [ pkgs.nix ] ++ lib.optionals (osConfig == null) [ pkgs.home-manager ];
    text =
      if osConfig != null then
        ''
          exec sudo nixos-rebuild switch --flake "''${SAUCE_NIX_FLAKE:-/etc/nixos}#''${SAUCE_NIX_HOST:-${osConfig.networking.hostName}}" "$@"
        ''
      else
        ''
          exec home-manager switch --flake "''${SAUCE_NIX_FLAKE:-$HOME/.config/home-manager}#''${SAUCE_NIX_HOME:-${config.home.username}}" "$@"
        '';
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ rebuild ];
    xdg.configFile = {
      "sauce/functions.sh".source = ../dotfiles/shell/functions.sh;
      "sauce/styles.sh".source = ../dotfiles/shell/styles.sh;
      "oh-my-posh/sauce.toml".source = ../dotfiles/config/oh-my-posh/sauce.toml;
    };
    programs.bash = {
      enable = true;
      historySize = 500;
      historyFileSize = 500;
      shellAliases = lib.optionalAttrs (has "nvim") {
        vi = "nvim";
        vim = "nvim";
      };
      initExtra =
        common
        + nvmInit
        + lib.optionalString (has "pyenv") ''
          eval "$(pyenv init - bash)"
        ''
        + ''
          eval "$(oh-my-posh init bash --config "$HOME/.config/oh-my-posh/sauce.toml")"
          for _rc in "$HOME/.bashrc.dev" "$HOME/.bashrc.ops" "$HOME/.bashrc.yggdrasil" "$HOME/.bashrc.local"; do
            [ ! -r "$_rc" ] || source "$_rc"
          done
          unset _rc
        '';
    };
    programs.zsh = {
      enable = true;
      dotDir = config.home.homeDirectory;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 5000;
        save = 5000;
        share = true;
        ignoreAllDups = true;
        ignoreSpace = true;
      };
      shellAliases = lib.optionalAttrs (has "nvim") {
        vi = "nvim";
        vim = "nvim";
      };
      initContent =
        common
        + ''
          setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END
          zstyle ':completion:*' menu select
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
          zstyle ':completion:*' group-name ""
          zstyle ':completion:*:descriptions' format '%B%F{blue}%d%f%b'
        ''
        + nvmInit
        + lib.optionalString (has "pyenv") ''
          eval "$(pyenv init - zsh)"
        ''
        + ''
          eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/sauce.toml")"
          for _rc in "$HOME/.zshrc.dev" "$HOME/.zshrc.ops" "$HOME/.zshrc.yggdrasil" "$HOME/.zshrc.local"; do
            [ ! -r "$_rc" ] || source "$_rc"
          done
          unset _rc
        '';
    };
  };
}
