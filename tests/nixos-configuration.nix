{
  pkgs,
  mkSystem,
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
  workstation = evaluate [
    ../machines/vanir.nix
    { sauce.system.user = lib.mkForce "tester"; }
  ];
  odin = evaluate [
    ../machines/odin.nix
    { sauce.system.user = lib.mkForce "tester"; }
  ];
  serverRemote = evaluate [
    ../profiles/server.nix
    ../profiles/remote.nix
  ];
  mobileRemote = evaluate [
    ../profiles/mobile.nix
    ../profiles/remote.nix
  ];
  plasma = evaluate [
    ../profiles/workstation.nix
    ../profiles/kde.nix
    { sauce.desktopEnvironments = lib.mkForce [ "kde" ]; }
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
assert workstation.nixpkgs.config.allowUnfree;
assert workstation.services.xserver.videoDrivers == [ "modesetting" ];
assert lib.all (name: lib.elem name (map lib.getName workstation.hardware.graphics.extraPackages)) [
  "intel-media-driver"
  "vpl-gpu-rt"
];
assert workstation.sauce.machineRole == "workstation";
assert workstation.services.displayManager.defaultSession == "sway";
assert workstation.services.desktopManager.cosmic.enable;
assert !workstation.services.desktopManager.plasma6.enable;
assert workstation.sauce.sway.terminal == "alacritty";
assert !(lib.elem "foot" workstation.sauce.guiApps);
assert !(builtins.hasAttr "foot" workstation.home-manager.users.tester.xdg.configFile);
assert lib.hasInfix "set $term alacritty"
  workstation.home-manager.users.tester.xdg.configFile."sway/config".text;
assert lib.hasInfix "terminal=alacritty -e"
  workstation.home-manager.users.tester.xdg.configFile."fuzzel/fuzzel.ini".text;
assert workstation.programs.sway.enable;
assert workstation.programs.uwsm.enable;
assert workstation.sauce.system.tailscale;
assert assertRemote workstation;
assert lib.all (name: lib.elem name workstation.sauce.tools) [
  "bitwarden-cli"
  "wrangler"
  "nvim"
  "docker"
  "rustup"
  "pi"
];
assert lib.all (name: lib.elem name workstation.sauce.guiApps) [
  "obsidian"
  "bitwarden"
  "firefox"
  "alacritty"
];
assert lib.all (name: lib.elem name workstation.sauce.flatpaks) [
  "discord"
  "signal"
  "lutris"
  "retroarch"
  "easyeffects"
];
assert workstation.programs.steam.enable;
assert odin.networking.hostName == "odin";
assert odin.sauce.machineRole == "workstation";
assert odin.time.timeZone == workstation.time.timeZone;
assert odin.sauce.desktopEnvironments == workstation.sauce.desktopEnvironments;
assert odin.services.displayManager.defaultSession == "sway";
assert odin.sauce.sway.terminal == "alacritty";
assert odin.sauce.system.nvidia;
assert odin.nixpkgs.config.allowUnfree;
assert lib.elem "nvidia" odin.services.xserver.videoDrivers;
assert lib.elem "modesetting" odin.services.xserver.videoDrivers;
assert lib.all (name: lib.elem name (map lib.getName odin.hardware.graphics.extraPackages)) [
  "intel-media-driver"
  "vpl-gpu-rt"
];
assert odin.hardware.nvidia.modesetting.enable;
assert lib.elem "--unsupported-gpu" odin.programs.sway.extraOptions;
assert assertRemote odin;
assert odin.services.openssh.enable;
assert odin.services.xrdp.enable;
assert !odin.services.xrdp.openFirewall;
assert odin.services.caddy.enable;
assert !odin.services.caddy.openFirewall;
assert odin.services.caddy.virtualHosts.":80".listenAddresses == [ "{$TAILSCALE_IP}" ];
assert lib.hasInfix "reverse_proxy 127.0.0.1:8080"
  odin.services.caddy.virtualHosts.":80".extraConfig;
assert assertRemote serverRemote;
assert assertRemote mobileRemote;
assert plasma.services.displayManager.defaultSession == "plasma";
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
    plasma
    withoutMaintenance
    backup
    workstation
    odin
  ])
  (
    pkgs.runCommand "sauce-nixos-configuration-tests" { } ''
      touch "$out"
    ''
  )
