{ config, lib, ... }:
let
  cfg = config.sauce;
  sys = cfg.system;
  backup = sys.backup;
  runtimePath = value: lib.hasPrefix "/" value && !(lib.hasPrefix "/nix/store/" value);
in
{
  options.sauce.system = {
    maintenance.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Weekly store cleanup, retaining generations younger than 30 days, and store optimisation.";
    };
    backup = {
      enable = lib.mkEnableOption "encrypted Restic backups (requires a repository and runtime password file)";
      repository = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Restic repository location without embedded credentials.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.str;
        default = "/run/secrets/sauce-restic-password";
        description = "Absolute runtime path to the repository password, never a Nix store path.";
      };
      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional root-readable runtime EnvironmentFile for remote repository credentials.";
      };
      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          sys.homeDirectory
          "/etc/nixos"
        ];
        description = "Paths to back up. Override if the configuration lives outside /etc/nixos.";
      };
      exclude = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "${sys.homeDirectory}/.cache" ];
        description = "Restic exclusion patterns.";
      };
      requiresMountsFor = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Mount paths required for backups; set this for local backup disks to avoid writing to the root disk.";
      };
      schedule = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 02:00:00";
        description = "Backup OnCalendar schedule, with up to one hour of random delay.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf sys.maintenance.enable {
        nix.gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          options = lib.mkDefault "--delete-older-than 30d";
        };
        nix.optimise.automatic = lib.mkDefault true;
      })
      (lib.mkIf backup.enable {
        assertions = [
          {
            assertion = backup.repository != "";
            message = "Set sauce.system.backup.repository before enabling backups.";
          }
          {
            assertion =
              runtimePath backup.passwordFile
              && (backup.environmentFile == null || runtimePath backup.environmentFile);
            message = "Restic credential files must be absolute runtime paths outside /nix/store.";
          }
          {
            assertion = backup.paths != [ ] && lib.all runtimePath backup.paths;
            message = "Set non-empty absolute runtime sauce.system.backup.paths.";
          }
        ];
        services.restic.backups.sauce = {
          inherit (backup)
            repository
            passwordFile
            environmentFile
            paths
            exclude
            ;
          initialize = true;
          timerConfig = {
            OnCalendar = backup.schedule;
            RandomizedDelaySec = "1h";
            Persistent = true;
          };
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 5"
            "--keep-monthly 12"
          ];
          runCheck = true;
          checkOpts = [ "--read-data-subset=1/10" ];
        };
        systemd.services.restic-backups-sauce.unitConfig.RequiresMountsFor = backup.requiresMountsFor;
      })
    ]
  );
}
