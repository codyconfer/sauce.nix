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
      type = types.nullOr (
        types.enum [
          "workstation"
          "mobile"
          "server"
        ]
      );
      default = null;
      description = "Machine role selected by a machine profile.";
    };
    remoteAccess = mkOption {
      type = types.bool;
      default = false;
      description = "Enable remote-access defaults such as Tailscale.";
    };
    desktopEnvironments = mkOption {
      type = types.listOf (
        types.enum [
          "kde"
          "sway"
          "cosmic"
          "lxqt"
          "gnome"
        ]
      );
      default = [ ];
      description = "Desktop sessions added by profiles; multiple profiles can be combined independently of machine role.";
    };
    tools = selection "tools" [ ];
    guiApps = selection "guiApps" [ ];
    emulators = selection "emulators" [ ];
    flatpaks = selection "flatpaks" [ ];
    signalKeyring = mkOption {
      type = types.bool;
      default = false;
      description = "Use Secret Service for the Signal Flatpak's local database key.";
    };
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
      description = "Custom package derivations keyed by selection name; overrides take precedence over catalog mappings.";
    };
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional user packages.";
    };
    sway = {
      terminal = mkOption {
        type = types.enum [
          "foot"
          "alacritty"
        ];
        default = "foot";
        description = "Terminal used by Sway and Fuzzel.";
      };
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Optional companion tools not shipped in nixpkgs.";
      };
      latitude = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Optional location latitude for weather and night-light tools.";
      };
      longitude = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Optional location longitude for weather and night-light tools.";
      };
    };
    pi = {
      extensions = mkOption {
        type = types.listOf types.str;
        default = [
          "npm:pi-mcp-adapter"
          "npm:billion-context"
          "npm:pi-web-access"
          "npm:pi-subagents"
          "npm:@langfuse/pi-observability-plugin"
          "npm:@juicesharp/rpiv-ask-user-question"
          "npm:pi-powerline-footer"
          "npm:pi-lens"
          "npm:pi-lmstudio"
          "npm:pi-goal-x"
          "npm:pi-mermaid"
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
