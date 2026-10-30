{
  description = ".sauce — Linux NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
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
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ azureOverlay ];
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
        nixpkgs.overlays = [ azureOverlay ];
      };
      homeManagerModules.default = {
        imports = [ ./modules/home.nix ];
        nixpkgs.overlays = [ azureOverlay ];
      };
      nixosConfigurations.sauce = mkSystem { modules = [ ./hosts/sauce.nix ]; };
      nixosConfigurations.testvm = mkSystem { modules = [ ./hosts/testvm.nix ]; };
      homeConfigurations."sauce" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs "x86_64-linux";
        modules = [
          self.homeManagerModules.default
          ./hosts/home.nix
        ];
      };
      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt);
      checks = eachSystem (
        system:
        let
          pkgs = mkPkgs system;
          home =
            profile:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                ./modules/home.nix
                profile
                {
                  home.username = "sauce";
                  home.homeDirectory = "/home/sauce";
                  home.stateVersion = "25.11";
                }
              ];
            };
        in
        {
          server = (home ./profiles/server.nix).activationPackage;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          workstation = (home {
            imports = [ ./profiles/workstation.nix ./profiles/sway.nix ];
          }).activationPackage;
          hyprland = (home {
            imports = [ ./profiles/workstation.nix ./profiles/hyprland.nix ];
          }).activationPackage;
          lxqt = (home {
            imports = [ ./profiles/workstation.nix ./profiles/lxqt.nix ];
          }).activationPackage;
          gnome = (home {
            imports = [ ./profiles/workstation.nix ./profiles/gnome.nix ];
          }).activationPackage;
          mobile = (home ./profiles/mobile.nix).activationPackage;
          configuration = import ./tests/configuration.nix {
            inherit pkgs;
            workstation = home {
              imports = [ ./profiles/workstation.nix ./profiles/sway.nix ];
            };
            server = home ./profiles/server.nix;
            mobile = home ./profiles/mobile.nix;
          };
        }
      );
    };
}
