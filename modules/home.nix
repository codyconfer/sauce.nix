{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  catalog = import ../lib/catalog.nix;
  cosmicApps = import ../packages/cosmic { inherit pkgs; };
  desktop = cfg.machineRole != "server";
  resolve =
    category: name:
    if builtins.hasAttr name cfg.packageOverrides then
      cfg.packageOverrides.${name}
    else
      let
        path = catalog.${category}.${name};
      in
      if path == null then
        throw "sauce: ${name} requires sauce.packageOverrides.${name}; see nix/README.md"
      else
        lib.attrByPath path
          (throw "sauce: nixpkgs has no package for ${name}; set sauce.packageOverrides.${name}")
          pkgs;
  packages = category: names: map (resolve category) names;
  auth = pkgs.writeShellApplication {
    name = "sauce-auth";
    runtimeInputs = [
      pkgs.gh
      pkgs.git
      pkgs.tailscale
      pkgs.bitwarden-cli
    ];
    text = ''
      set -euo pipefail
      echo "Logging in to GitHub..."
      gh auth login
      gh auth setup-git

      read -r -p "Git commit author name: " git_name
      read -r -p "Git commit author email: " git_email
      if [[ -z "$git_name" || -z "$git_email" ]]; then
        echo "Git name and email must not be empty." >&2
        exit 1
      fi
      git config --global user.name "$git_name"
      git config --global user.email "$git_email"

      echo "Connecting to Tailscale..."
      sudo tailscale up

      echo "Logging in to Bitwarden..."
      bw login
    '';
  };
in
{
  imports = [
    ./options.nix
    ./shell.nix
    ./files.nix
    ./editor.nix
    ./flatpak.nix
    ./pi.nix
    ./cosmic-scan-indicator.nix
  ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        sauce.packageOverrides.bitwarden = lib.mkDefault (
          import ../packages/bitwarden.nix { inherit pkgs; }
        );
        sauce.packageOverrides.loglit = lib.mkDefault (pkgs.callPackage ../packages/loglit.nix { });
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isLinux;
            message = ".sauce supports Linux only.";
          }
        ];
        home.activation.createHomeDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/repos"
          if [ ! -e "$HOME/sync" ] && [ ! -L "$HOME/sync" ]; then
            ln -s /srv/sync "$HOME/sync"
          fi
        '';
        home.packages =
          with pkgs;
          [
            git
            gnupg
            auth
            curl
            wget
            unzip
            jq
            figlet
            gcc
            gnumake
            xz
            oh-my-posh
            nodejs
          ]
          ++ lib.optionals cfg.extras [
            gh
            pipx
            htop
            btop
            iftop
            iotop
            s-tui
            wavemon
          ]
          ++ lib.optionals cfg.netTools [
            nmap
            traceroute
            mtr
            tcpdump
            whois
            socat
            net-tools
            bind
            netcat-openbsd
            iputils
            iw
          ]
          ++ packages "tools" (
            lib.filter (
              name:
              !(lib.elem name [
                "nvim"
                "nvm"
              ])
            ) cfg.tools
          )
          ++ packages "media" (lib.filter (name: desktop || name == "ffmpeg") cfg.media)
          ++ lib.optionals desktop (packages "guiApps" cfg.guiApps ++ packages "emulators" cfg.emulators)
          ++ lib.optionals (desktop && builtins.elem "qemu" cfg.emulators) [ pkgs.virt-manager ]
          ++ lib.optionals (desktop && builtins.elem "cosmic" cfg.desktopEnvironments) (
            builtins.attrValues cosmicApps
            ++ [
              pkgs.forecast
              pkgs.cosmic-ext-applet-privacy-indicator
            ]
          )
          ++ cfg.extraPackages;

        home.sessionPath = [
          "$HOME/.local/bin"
          "$HOME/go/bin"
          "$HOME/.cargo/bin"
          "$HOME/.dotnet/tools"
        ];
        home.sessionVariables =
          lib.optionalAttrs (builtins.elem "nvim" cfg.tools) {
            EDITOR = "nvim";
            VISUAL = "nvim";
          }
          // lib.optionalAttrs (builtins.elem "dotnet" cfg.tools) {
            DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
          };
        fonts.fontconfig.enable = desktop;
        home.file.".gnupg/gpg-agent.conf".text =
          builtins.readFile ../dotfiles/gnupg/gpg-agent.conf
          + "\npinentry-program ${
            if desktop then pkgs.pinentry-gnome3 else pkgs.pinentry-curses
          }/bin/pinentry\n";
        programs.home-manager.enable = true;
      }
    ]
  );
}
