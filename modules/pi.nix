{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  desktop = cfg.machineRole != "server";
  enabled = cfg.enable && builtins.elem "pi" cfg.tools;
  extensions = cfg.pi.extensions;
  install = pkgs.writeShellApplication {
    name = "sauce-pi-extensions";
    runtimeInputs = [
      (cfg.packageOverrides.pi or pkgs.pi-coding-agent)
      pkgs.nodejs
    ];
    text = lib.concatMapStringsSep "\n" (
      extension: "pi install ${lib.escapeShellArg extension}"
    ) extensions;
  };
in
{
  config = lib.mkIf enabled {
    home.packages = [ install ];
    home.file = {
      ".pi/web-search.json".text = builtins.toJSON {
        workflow = "summary-review";
        githubClone = {
          enabled = true;
          maxRepoSizeMB = 350;
        };
      };
      ".pi/agent/mcp.json".text = builtins.toJSON {
        mcpServers = cfg.pi.mcp.mcpServers or { };
      };
      ".pi/agent/mcp-adapter.json".text = builtins.toJSON {
        settings = cfg.pi.mcp.settings or { };
      };
    }
    // lib.optionalAttrs (desktop && builtins.elem "lmstudio" cfg.guiApps) {
      ".pi/agent/lmstudio.json".text = builtins.toJSON {
        url = cfg.pi.lmstudioUrl;
        servers = [ ];
      };
    };
  };
}
