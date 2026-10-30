{ lib, ... }:
let
  inherit (lib) mkOption types;
  catalog = import ../lib/catalog.nix;
  selection =
    category: default:
    mkOption {
      type = types.listOf (types.enum (builtins.attrNames catalog.${category}));
      inherit default;
      description = "Selected .sauce ${category}; an empty list disables this group.";
    };
in
{
  options.sauce = {
    enable = lib.mkEnableOption ".sauce configuration";
    machineRole = mkOption {
      type = types.nullOr (types.enum [ "workstation" "mobile" "server" ]);
      default = null;
      description = "Machine role selected by a machine profile.";
    };
    desktopEnvironment = mkOption {
      type = types.nullOr (types.enum [ "kde" "sway" "hyprland" "cosmic" "lxqt" "gnome" ]);
      default = null;
      description = "Optional desktop profile; select kde, sway, hyprland, cosmic, lxqt, or gnome separately from machine role.";
    };
    headless = mkOption {
      type = types.bool;
      default = false;
      description = "Disable desktop packages and files.";
    };
    tools = selection "tools" [ ];
    guiApps = selection "guiApps" [ ];
    emulators = selection "emulators" [ ];
    flatpaks = selection "flatpaks" [ ];
    media = selection "media" [ ];
    netTools = mkOption {
      type = types.bool;
      default = true;
      description = "Install network diagnostics.";
    };
    extras = mkOption {
      type = types.bool;
      default = true;
      description = "Install monitoring tools and gh/pipx.";
    };
    packageOverrides = mkOption {
      type = types.attrsOf types.package;
      default = { };
      description = "Packages keyed by selection name, required for gcx, loglit and claude desktop.";
    };
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional user packages.";
    };
    sway = {
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Optional companion tools not shipped in nixpkgs.";
      };
      latitude = mkOption {
        type = types.str;
        default = "40.6";
        description = "Wlsunset latitude.";
      };
      longitude = mkOption {
        type = types.str;
        default = "-105.1";
        description = "Wlsunset longitude.";
      };
    };
    pi = {
      extensions = mkOption {
        type = types.listOf types.str;
        default = [
          "npm:pi-subagents"
          "npm:pi-web-access"
          "npm:pi-mcp-adapter"
        ];
        description = "Pi packages offered by the explicit sauce-pi-extensions command (not fetched during activation).";
      };
      mcp = mkOption {
        type = types.attrs;
        default = {
          mcpServers = { };
          settings = {
            toolPrefix = "server";
            idleTimeout = 10;
            showStatusIcon = true;
          };
        };
        description = "Non-secret Pi MCP settings.";
      };
      lmstudioUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:1234";
        description = "Local LM Studio endpoint.";
      };
    };
  };
}
