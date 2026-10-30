{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  has = name: builtins.elem name cfg.tools;
  enabled = cfg.enable && has "nvim";
  logHighlight = pkgs.vimUtils.buildVimPlugin {
    pname = "log-highlight.nvim";
    version = "2026-10-29";
    src = pkgs.fetchFromGitHub {
      owner = "fei6409";
      repo = "log-highlight.nvim";
      rev = "b2e00cfd41ca94338265a595f3f3f423d9f9322e";
      hash = "sha256-nkExBiot2Z0JaBuzympYCWUX+493jRTFhgwJ6AZiNSo=";
    };
  };
  servers = [
    "lua_ls"
    "bashls"
    "jsonls"
    "yamlls"
    "taplo"
    "marksman"
    "clangd"
  ]
  ++ lib.optional (has "go") "gopls"
  ++ lib.optionals (has "pyenv" || has "poetry") [
    "pyright"
    "ruff"
  ]
  ++ lib.optional (has "nvm") "ts_ls"
  ++ lib.optional (has "dotnet") "omnisharp"
  ++ lib.optional (has "rustup") "rust_analyzer"
  ++ lib.optional (!cfg.headless && builtins.elem "docker" cfg.guiApps) "dockerls";
in
{
  config = lib.mkIf enabled {
    programs.neovim = {
      enable = true;
      package = cfg.packageOverrides.nvim or pkgs.neovim-unwrapped;
      defaultEditor = true;
      withPython3 = true;
      withNodeJs = true;
      withRuby = false;
      initLua = builtins.readFile ../dotfiles/config/nvim/init.lua;
      extraPackages =
        with pkgs;
        [
          lua-language-server
          bash-language-server
          vscode-langservers-extracted
          yaml-language-server
          taplo
          marksman
          clang-tools
        ]
        ++ lib.optionals (has "go") [ gopls ]
        ++ lib.optionals (has "pyenv" || has "poetry") [
          pyright
          ruff
        ]
        ++ lib.optionals (has "nvm") [ typescript-language-server ]
        ++ lib.optionals (has "dotnet") [ omnisharp-roslyn ]
        ++ lib.optionals (has "rustup") [ rust-analyzer ]
        ++ lib.optionals (!cfg.headless && builtins.elem "docker" cfg.guiApps) [
          dockerfile-language-server
        ];
      plugins = with pkgs.vimPlugins; [
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        luasnip
        cmp_luasnip
        gitsigns-nvim
        diffview-nvim
        plenary-nvim
        logHighlight
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
      ];
    };
    xdg.configFile."nvim/lua" = {
      source = ../dotfiles/config/nvim/lua;
      recursive = true;
    };
    xdg.configFile."nvim/colors" = {
      source = ../dotfiles/config/nvim/colors;
      recursive = true;
    };
    xdg.configFile."nvim/lua/sauce/generated.lua".text = ''
      return { servers = ${lib.generators.toLua { } servers}, parsers = {} }
    '';
  };
}
