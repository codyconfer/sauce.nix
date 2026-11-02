{
  pkgs,
  mkSystem,
  vanirConfig,
}:
let
  inherit (pkgs) lib;
  base = {
    system.stateVersion = "25.11";
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    sauce.system.user = "tester";
  };
  evaluate = modules: (mkSystem { modules = [ base ] ++ modules; }).config;
  serverRemote = evaluate [
    ../profiles/server.nix
    ../profiles/remote.nix
  ];
  mobileRemote = evaluate [
    ../profiles/mobile.nix
    ../profiles/remote.nix
  ];
  hyprland = evaluate [ ../profiles/workstation.nix ];
  withoutHyprland = evaluate [
    ../profiles/workstation.nix
    ../profiles/kde.nix
    {
      sauce.guiApps = lib.mkForce [ "foot" ];
    }
  ];
  backup = evaluate [
    ../profiles/server.nix
    {
      sauce.system.backup = {
        enable = true;
        repository = "sftp:backup@example.invalid:/backups/tester";
      };
    }
  ];
  withoutMaintenance = evaluate [
    ../profiles/server.nix
    { sauce.system.maintenance.enable = false; }
  ];
  invalidCredentials = evaluate [
    ../profiles/server.nix
    ../profiles/remote.nix
    { sauce.system.remote.codeServerEnvironmentFile = "/nix/store/unsafe-env"; }
  ];
  invalidBackup = evaluate [
    ../profiles/server.nix
    {
      sauce.system.backup.enable = true;
    }
  ];
  assertRemote =
    c:
    assert c.networking.firewall.enable;
    assert c.networking.firewall.backend == "firewalld";
    assert c.services.firewalld.settings.DefaultZone == "drop";
    assert c.services.firewalld.zones.tailscale.interfaces == [ "tailscale0" ];
    assert c.services.openssh.settings.PasswordAuthentication == false;
    assert c.services.openssh.settings.KbdInteractiveAuthentication == false;
    assert c.services.openssh.settings.PermitRootLogin == "no";
    assert c.services.openssh.openFirewall == false;
    assert lib.elem "/etc/ssh/sauce-authorized-keys/%u" c.services.openssh.authorizedKeysFiles;
    assert c.services.code-server.auth == "password";
    assert c.services.code-server.host == "127.0.0.1";
    assert
      c.systemd.services.code-server.serviceConfig.EnvironmentFile
      == "/run/secrets/sauce-code-server.env";
    true;
in
assert vanirConfig.sauce.machineRole == "workstation";
assert vanirConfig.boot.plymouth.enable;
assert vanirConfig.boot.plymouth.theme == "bgrt";
assert vanirConfig.boot.plymouth.themePackages == [ ];
assert hyprland.boot.plymouth.theme == "bgrt";
assert !serverRemote.boot.plymouth.enable;
assert vanirConfig.services.displayManager.defaultSession == "cosmic";
assert vanirConfig.services.desktopManager.cosmic.enable;
assert !vanirConfig.services.desktopManager.plasma6.enable;
assert !vanirConfig.services.desktopManager.gnome.enable;
assert !vanirConfig.services.xserver.desktopManager.lxqt.enable;
assert vanirConfig.programs.hyprland.enable;
assert vanirConfig.programs.sway.enable;
assert
  lib.sort builtins.lessThan vanirConfig.sauce.desktopEnvironments == [
    "cosmic"
    "sway"
  ];
assert vanirConfig.sauce.system.tailscale;
assert assertRemote vanirConfig;
assert lib.all (name: lib.elem name vanirConfig.sauce.tools) [
  "bitwarden-cli"
  "wrangler"
  "nvim"
  "docker"
  "rustup"
  "pi"
];
assert lib.all (name: lib.elem name vanirConfig.sauce.guiApps) [
  "obsidian"
  "bitwarden"
  "firefox"
  "hyprland"
];
assert lib.all (name: lib.elem name vanirConfig.sauce.flatpaks) [
  "discord"
  "signal"
  "lutris"
  "retroarch"
  "easyeffects"
];
assert vanirConfig.programs.steam.enable;
assert assertRemote serverRemote;
assert assertRemote mobileRemote;
assert builtins.hasAttr "swaylock" hyprland.security.pam.services;
assert hyprland.programs.hyprland.enable;
assert hyprland.services.displayManager.defaultSession == "hyprland-uwsm";
assert !(withoutHyprland.programs.hyprland.enable);
assert withoutHyprland.services.displayManager.defaultSession == "plasma";
assert
  !(builtins.hasAttr "hypr/hyprland.conf" withoutHyprland.home-manager.users.tester.xdg.configFile);
assert serverRemote.nix.gc.automatic;
assert serverRemote.nix.gc.options == "--delete-older-than 30d";
assert serverRemote.nix.optimise.automatic;
assert serverRemote.services.restic.backups == { };
assert backup.services.restic.backups.sauce.runCheck;
assert backup.services.restic.backups.sauce.checkOpts == [ "--read-data-subset=1/10" ];
assert lib.elem "--keep-monthly 12" backup.services.restic.backups.sauce.pruneOpts;
assert !withoutMaintenance.nix.gc.automatic;
assert !withoutMaintenance.nix.optimise.automatic;
assert lib.any (
  a: !a.assertion && a.message == "Set sauce.system.backup.repository before enabling backups."
) invalidBackup.assertions;
assert lib.any (
  a:
  !a.assertion
  &&
    a.message
    == "sauce.system.remote.codeServerEnvironmentFile must be an absolute runtime path outside /nix/store."
) invalidCredentials.assertions;
builtins.deepSeq
  (map (c: c.system.build.toplevel.drvPath) [
    serverRemote
    mobileRemote
    hyprland
    withoutHyprland
    withoutMaintenance
    backup
    vanirConfig
  ])
  (
    pkgs.runCommand "sauce-nixos-configuration-tests" { } ''
      touch "$out"
    ''
  )
