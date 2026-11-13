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
  tyr = evaluate [
    ../machines/tyr.nix
    { sauce.system.user = lib.mkForce "tester"; }
  ];
  serverSsh = evaluate [
    ../profiles/headless
    ../profiles/headless/ssh.nix
  ];
  plasma = evaluate [
    ../profiles/desktops/kde.nix
    {
      sauce = {
        enable = true;
        machineRole = "workstation";
        desktopEnvironments = lib.mkForce [ "kde" ];
      };
    }
  ];
  backup = evaluate [
    ../profiles/headless
    {
      sauce.system.backup = {
        enable = true;
        repository = "sftp:backup@example.invalid:/backups/tester";
      };
    }
  ];
  withoutMaintenance = evaluate [
    ../profiles/headless
    { sauce.system.maintenance.enable = false; }
  ];
  invalidCredentials = evaluate [
    ../profiles/headless
    ../profiles/headless/ssh.nix
    ../profiles/headless/devbox.nix
    { sauce.system.devbox.codeServerEnvironmentFile = "/nix/store/unsafe-env"; }
  ];
  invalidBackup = evaluate [
    ../profiles/headless
    {
      sauce.system.backup.enable = true;
    }
  ];
  assertSsh =
    c:
    assert c.networking.firewall.enable;
    assert c.networking.firewall.backend == "firewalld";
    assert c.services.firewalld.settings.DefaultZone == "drop";
    assert c.services.firewalld.zones.tailscale.interfaces == [ "tailscale0" ];
    assert c.services.openssh.settings.PasswordAuthentication == false;
    assert c.services.openssh.settings.KbdInteractiveAuthentication == false;
    assert c.services.openssh.settings.PermitRootLogin == "no";
    assert c.services.openssh.openFirewall == false;
    assert c.sauce.system.ssh.authorizedKeysFile == "/etc/ssh/sauce-authorized-keys/%u";
    assert lib.elem c.sauce.system.ssh.authorizedKeysFile c.services.openssh.authorizedKeysFiles;
    true;
  assertDevbox =
    c:
    assert c.services.caddy.enable;
    assert c.services.code-server.enable;
    assert c.services.code-server.auth == "password";
    assert c.services.code-server.host == "127.0.0.1";
    assert
      c.systemd.services.code-server.serviceConfig.EnvironmentFile
      == c.sauce.system.devbox.codeServerEnvironmentFile;
    true;
in
assert workstation.nixpkgs.config.allowUnfree;
assert workstation.hardware.rtl-sdr.enable;
assert lib.elem "plugdev" workstation.users.users.tester.extraGroups;
assert lib.elem workstation.hardware.rtl-sdr.package workstation.services.udev.packages;
assert lib.elem workstation.hardware.rtl-sdr.package workstation.environment.systemPackages;
assert lib.all (module: lib.elem module workstation.boot.blacklistedKernelModules) [
  "dvb_usb_rtl28xxu"
  "e4000"
  "rtl2832"
];
assert !(serverSsh.hardware.rtl-sdr.enable);
assert !(lib.elem "plugdev" serverSsh.users.users.tester.extraGroups);
assert workstation.hardware.bluetooth.enable;
assert workstation.hardware.bluetooth.powerOnBoot;
assert !(workstation.services.blueman.enable);
assert workstation.services.pipewire.enable;
assert workstation.services.pipewire.alsa.enable;
assert workstation.services.pipewire.pulse.enable;
assert !(workstation.services.pipewire.jack.enable);
assert lib.elem pkgs.pipewire.jack workstation.environment.systemPackages;
assert workstation.services.pipewire.wireplumber.enable;
assert workstation.security.rtkit.enable;
assert lib.all (module: lib.elem module workstation.boot.kernelModules) [
  "snd-seq"
  "snd-rawmidi"
];
assert
  workstation.services.pipewire.wireplumber.extraConfig."51-sauce-audio"."wireplumber.settings"."bluetooth.autoswitch-to-headset-profile";
assert
  workstation.services.pipewire.wireplumber.extraConfig."51-sauce-audio"."monitor.bluez.properties"."bluez5.enable-msbc";
assert
  workstation.services.pipewire.wireplumber.extraConfig."51-sauce-audio"."wireplumber.profiles".main."monitor.alsa-midi"
  == "required";
assert
  workstation.services.pipewire.extraConfig.jack."20-sauce-midi"."jack.properties"."jack.show-midi";
assert lib.all (name: lib.elem name (map lib.getName workstation.environment.systemPackages)) [
  "alsa-utils"
  "qpwgraph"
];
assert !(serverSsh.services.pipewire.jack.enable);
assert !(lib.elem pkgs.pipewire.jack serverSsh.environment.systemPackages);
assert !(serverSsh.hardware.bluetooth.enable);
assert !(serverSsh.services.pipewire.wireplumber.extraConfig ? "51-sauce-audio");
assert lib.elem pkgs.fontconfig workstation.programs.nix-ld.libraries;
assert !(lib.elem pkgs.fontconfig serverSsh.programs.nix-ld.libraries);
assert workstation.systemd.services.sauce-clamav-scan.restartIfChanged == false;
assert workstation.systemd.services.sauce-clamav-scan.wantedBy == [ ];
assert workstation.systemd.timers.sauce-clamav-scan.wantedBy == [ "timers.target" ];
assert workstation.sauce.signalKeyring;
assert workstation.security.polkit.enable;
assert lib.elem workstation.sauce.packageOverrides.bitwarden workstation.environment.systemPackages;
assert lib.elem workstation.sauce.packageOverrides.bitwarden
  workstation.home-manager.users.tester.home.packages;
assert workstation.sauce.packageOverrides.bitwarden ? sauceTrayIcon;
assert lib.elem "bitwarden-desktop" (map lib.getName workstation.environment.systemPackages);
assert lib.elem "/share/polkit-1" workstation.environment.pathsToLink;
assert !(lib.elem "bitwarden-desktop" (map lib.getName serverSsh.environment.systemPackages));
assert lib.hasInfix "SIGNAL_PASSWORD_STORE=gnome-libsecret"
  workstation.home-manager.users.tester.xdg.dataFile."flatpak/overrides/org.signal.Signal".text;
assert
  !(builtins.hasAttr "flatpak/overrides/org.signal.Signal" serverSsh.home-manager.users.tester.xdg.dataFile);
assert workstation.services.libinput.enable;
assert lib.elem "xinput" (map lib.getName workstation.environment.systemPackages);
assert !(lib.elem "xinput" (map lib.getName serverSsh.environment.systemPackages));
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
assert lib.hasInfix "export NVM_DIR=\"$HOME/.nvm\""
  workstation.home-manager.users.tester.programs.bash.initExtra;
assert lib.hasInfix "/nvm.sh" workstation.home-manager.users.tester.programs.bash.initExtra;
assert lib.hasInfix "/nvm.sh" workstation.home-manager.users.tester.programs.zsh.initContent;
assert !(lib.hasInfix "fnm env" workstation.home-manager.users.tester.programs.bash.initExtra);
assert !(lib.elem "fnm" (map lib.getName workstation.home-manager.users.tester.home.packages));
assert workstation.sauce.system.tailscale;
assert workstation.home-manager.users.tester.services.tailscale-systray.enable;
assert workstation.home-manager.users.tester.services.tailscale-systray.theme == "dark:nobg";
assert lib.any (lib.hasInfix "--theme dark:nobg")
  workstation.home-manager.users.tester.systemd.user.services.tailscale-systray.Service.ExecStart;
assert assertSsh workstation;
assert !workstation.services.caddy.enable;
assert !workstation.services.code-server.enable;
assert
  workstation.sauce.system.devbox.codeServerEnvironmentFile
  == "/var/lib/sauce/secrets/code-server.env";
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
  "reaper"
  "nam"
  "guitarix"
  "ardour"
  "lmms"
  "zrythm"
  "qtractor"
  "helio"
  "byod"
  "kdenlive"
  "shotcut"
  "davinci-resolve"
  "gimp"
  "affinity"
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
assert
  odin.sauce.system.devbox.codeServerEnvironmentFile
  == workstation.sauce.system.devbox.codeServerEnvironmentFile;
assert odin.services.resilio.enable;
assert odin.services.resilio.enableWebUI;
assert odin.services.resilio.httpListenAddr == workstation.services.resilio.httpListenAddr;
assert odin.services.resilio.httpListenPort == workstation.services.resilio.httpListenPort;
assert
  odin.systemd.services.resilio.serviceConfig.EnvironmentFile
  == workstation.systemd.services.resilio.serviceConfig.EnvironmentFile;
assert
  odin.systemd.services.resilio.serviceConfig.ExecStart
  == workstation.systemd.services.resilio.serviceConfig.ExecStart;
assert lib.elem {
  port = 9000;
  protocol = "tcp";
} odin.services.firewalld.zones.tailscale.ports;
assert !(builtins.hasAttr "resilio-lan" odin.services.firewalld.zones);
assert lib.all (rule: lib.elem rule odin.systemd.tmpfiles.rules) [
  "d /srv/sync 2770 rslsync rslsync -"
  "d /srv/sync/downloads 2770 rslsync rslsync -"
];
assert odin.time.timeZone == workstation.time.timeZone;
assert odin.sauce.desktopEnvironments == workstation.sauce.desktopEnvironments;
assert odin.services.displayManager.defaultSession == "sway";
assert odin.sauce.sway.terminal == "alacritty";
assert odin.sauce.system.nvidia;
assert odin.home-manager.users.tester.services.tailscale-systray.enable;
assert odin.nixpkgs.config.allowUnfree;
assert lib.elem "nvidia" odin.services.xserver.videoDrivers;
assert lib.elem "modesetting" odin.services.xserver.videoDrivers;
assert lib.all (name: lib.elem name (map lib.getName odin.hardware.graphics.extraPackages)) [
  "intel-media-driver"
  "vpl-gpu-rt"
];
assert odin.hardware.nvidia.modesetting.enable;
assert lib.elem "--unsupported-gpu" odin.programs.sway.extraOptions;
assert assertSsh odin;
assert assertDevbox odin;
assert odin.services.openssh.enable;
assert odin.services.caddy.enable;
assert !odin.services.caddy.openFirewall;
assert odin.services.caddy.virtualHosts.":80".listenAddresses == [ "{$TAILSCALE_IP}" ];
assert lib.hasInfix "reverse_proxy 127.0.0.1:8080"
  odin.services.caddy.virtualHosts.":80".extraConfig;
assert odin.sauce.system.devbox.lmstudio.enable;
assert odin.services.caddy.virtualHosts."http://:1234".listenAddresses == [ "{$TAILSCALE_IP}" ];
assert lib.hasInfix "reverse_proxy 127.0.0.1:1234"
  odin.services.caddy.virtualHosts."http://:1234".extraConfig;
assert lib.elem {
  port = 1234;
  protocol = "tcp";
} odin.services.firewalld.zones.tailscale.ports;
assert !(serverSsh.services.caddy.virtualHosts ? "http://:1234");
assert
  !(lib.elem {
    port = 1234;
    protocol = "tcp";
  } serverSsh.services.firewalld.zones.tailscale.ports);
assert !tyr.services.caddy.enable;
assert tyr.networking.hostName == "tyr";
assert tyr.sauce.machineRole == "workstation";
assert tyr.time.timeZone == workstation.time.timeZone;
assert tyr.sauce.desktopEnvironments == workstation.sauce.desktopEnvironments;
assert tyr.services.displayManager.defaultSession == "sway";
assert tyr.sauce.sway.terminal == "alacritty";
assert tyr.sauce.system.nvidia;
assert lib.elem "nvidia" tyr.services.xserver.videoDrivers;
assert lib.elem "modesetting" tyr.services.xserver.videoDrivers;
assert tyr.hardware.nvidia.modesetting.enable;
assert lib.elem "--unsupported-gpu" tyr.programs.sway.extraOptions;
assert lib.all (name: lib.elem name (map lib.getName tyr.hardware.graphics.extraPackages)) [
  "intel-media-driver"
  "vpl-gpu-rt"
];
assert tyr.sauce.system.tailscale;
assert !tyr.services.openssh.enable;
assert !tyr.services.caddy.enable;
assert !tyr.services.code-server.enable;
assert lib.all (name: lib.elem name tyr.sauce.tools) [
  "aws"
  "azure-cli"
  "gcloud"
  "claude-code"
];
assert lib.all (name: lib.elem name tyr.sauce.guiApps) [
  "codex"
];
assert lib.all (name: lib.elem name tyr.sauce.flatpaks) [
  "slack"
  "zoom"
];
assert assertSsh serverSsh;
assert !serverSsh.services.caddy.enable;
assert !serverSsh.services.code-server.enable;
assert
  serverSsh.services.firewalld.zones.tailscale.ports == [
    {
      port = 22;
      protocol = "tcp";
    }
  ];
assert
  serverSsh.sauce.system.devbox.codeServerEnvironmentFile == "/run/secrets/sauce-code-server.env";
assert !serverSsh.home-manager.users.tester.services.tailscale-systray.enable;
assert !plasma.home-manager.users.tester.services.tailscale-systray.enable;
assert plasma.services.displayManager.defaultSession == "plasma";
assert serverSsh.nix.gc.automatic;
assert serverSsh.nix.gc.options == "--delete-older-than 30d";
assert serverSsh.nix.optimise.automatic;
assert serverSsh.services.restic.backups == { };
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
    == "sauce.system.devbox.codeServerEnvironmentFile must be an absolute runtime path outside /nix/store."
) invalidCredentials.assertions;
builtins.deepSeq
  (map (c: c.system.build.toplevel.drvPath) [
    serverSsh
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
