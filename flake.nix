{
  description = ".sauce — Linux NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      lanzaboote,
      ...
    }:
    let
      # The unstable snapshot has a broken fabric/invoke dependency in Azure CLI.
      azureOverlay = final: prev: {
        azure-cli =
          (import nixpkgs-stable {
            system = final.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          }).azure-cli;
      };
      affinityOverlay =
        final: prev:
        nixpkgs.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "x86_64-linux") (
          inputs.affinity-nix.overlays.default final prev
        );
      overlays = [
        azureOverlay
        affinityOverlay
      ];
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          inherit overlays;
        };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      mkSystem =
        {
          system ? "x86_64-linux",
          modules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ self.nixosModules.default ] ++ modules;
        };
    in
    {
      lib.mkSystem = mkSystem;
      nixosModules.default = {
        imports = [
          ./modules/nixos.nix
          home-manager.nixosModules.home-manager
          lanzaboote.nixosModules.lanzaboote
        ];
        nixpkgs.overlays = overlays;
      };
      nixosModules.vanir = {
        imports = [
          self.nixosModules.default
          ./machines/vanir.nix
        ];
      };
      nixosModules.odin = {
        imports = [
          self.nixosModules.default
          ./machines/odin.nix
        ];
      };
      nixosModules.tyr = {
        imports = [
          self.nixosModules.default
          ./machines/tyr.nix
        ];
      };
      homeManagerModules.default = {
        imports = [ ./modules/home.nix ];
        nixpkgs.overlays = overlays;
      };
      nixosModules.profiles =
        builtins.listToAttrs (
          map
            (file: {
              name = nixpkgs.lib.removeSuffix ".nix" file;
              value = ./profiles + "/${file}";
            })
            (
              builtins.filter (name: nixpkgs.lib.hasSuffix ".nix" name) (
                builtins.attrNames (builtins.readDir ./profiles)
              )
            )
        )
        // {
          headless = ./profiles/headless;
          devbox = ./profiles/headless/devbox.nix;
          hypervisor = ./profiles/headless/hypervisor.nix;
          ssh = ./profiles/headless/ssh.nix;
          work = ./profiles/work.nix;
          gaming = ./profiles/workflows/gaming.nix;
          workflows = {
            default = ./profiles/workflows/default.nix;
            dev = ./profiles/workflows/dev.nix;
            radio = ./profiles/workflows/radio.nix;
            video = ./profiles/workflows/video.nix;
            music = ./profiles/workflows/music.nix;
            photo = ./profiles/workflows/photo.nix;
            gaming = ./profiles/workflows/gaming.nix;
            remote-vnc = ./profiles/workflows/remote-vnc.nix;
            client-vnc = ./profiles/workflows/client-vnc.nix;
          };
          desktops = {
            cosmic = ./profiles/desktops/cosmic.nix;
            gnome = ./profiles/desktops/gnome.nix;
            kde = ./profiles/desktops/kde.nix;
            sway = ./profiles/desktops/sway.nix;
          };
          cosmic = ./profiles/desktops/cosmic.nix;
          gnome = ./profiles/desktops/gnome.nix;
          kde = ./profiles/desktops/kde.nix;
          sway = ./profiles/desktops/sway.nix;
        };
      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt);
      checks = eachSystem (
        system:
        let
          pkgs = mkPkgs system;
          workstationDefaults = {
            sauce = {
              enable = true;
              machineRole = "workstation";
              desktopEnvironments = nixpkgs.lib.mkDefault [ "sway" ];
            };
          };
          home =
            profile:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                ./modules/home.nix
                profile
                {
                  home.username = "codyconfer";
                  home.homeDirectory = "/home/codyconfer";
                  home.stateVersion = "25.11";
                }
              ];
            };
        in
        {
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          nixos-configuration = import ./tests/nixos-configuration.nix {
            inherit pkgs mkSystem;
          };
          nixos-smoke = import ./tests/nixos-smoke.nix {
            inherit pkgs;
            sauceModule = self.nixosModules.default;
          };
          workstation =
            (home {
              imports = [
                workstationDefaults
                ./profiles/workflows/default.nix
                ./profiles/workflows/dev.nix
                ./profiles/workflows/radio.nix
                ./profiles/workflows/video.nix
                ./profiles/workflows/music.nix
                ./profiles/workflows/photo.nix
                ./profiles/desktops/sway.nix
                ./profiles/desktops/kde.nix
                ./profiles/desktops/cosmic.nix
                ./profiles/desktops/gnome.nix
              ];
            }).activationPackage;
          remote-vnc = (home ./profiles/workflows/remote-vnc.nix).activationPackage;
          client-vnc = (home ./profiles/workflows/client-vnc.nix).activationPackage;
          gnome =
            (home {
              imports = [
                workstationDefaults
                ./profiles/workflows/default.nix
                ./profiles/workflows/dev.nix
                ./profiles/workflows/radio.nix
                ./profiles/workflows/video.nix
                ./profiles/workflows/music.nix
                ./profiles/workflows/photo.nix
                ./profiles/desktops/gnome.nix
              ];
            }).activationPackage;
          configuration = import ./tests/configuration.nix {
            inherit pkgs;
            personal = home {
              imports = [
                workstationDefaults
                ./profiles/workflows/default.nix
                ./profiles/workflows/dev.nix
                ./profiles/workflows/radio.nix
                ./profiles/workflows/video.nix
                ./profiles/workflows/music.nix
                ./profiles/workflows/photo.nix
                ./profiles/personal.nix
                ./profiles/desktops/cosmic.nix
              ];
            };
            workstation = home {
              imports = [
                workstationDefaults
                ./profiles/workflows/default.nix
                ./profiles/workflows/dev.nix
                ./profiles/workflows/radio.nix
                ./profiles/workflows/video.nix
                ./profiles/workflows/music.nix
                ./profiles/workflows/photo.nix
                ./profiles/desktops/sway.nix
                ./profiles/desktops/kde.nix
                ./profiles/desktops/cosmic.nix
                ./profiles/desktops/gnome.nix
              ];
            };
            server = home {
              imports = [ ./profiles/headless ];
              sauce = {
                desktopEnvironments = [ "sway" ];
                guiApps = [ "sway" ];
                flatpaks = [ "signal" ];
                media = [
                  "vlc"
                  "ffmpeg"
                ];
              };
            };
          };
        }
      );
    };
}
