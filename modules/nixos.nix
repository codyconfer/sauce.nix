{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.sauce;
  sys = cfg.system;
  desktop = cfg.machineRole != "server";
  workstation = desktop && cfg.machineRole == "workstation";
  sway = desktop && builtins.elem "sway" cfg.desktopEnvironments;
  kde = desktop && builtins.elem "kde" cfg.desktopEnvironments;
  cosmic = desktop && builtins.elem "cosmic" cfg.desktopEnvironments;
  gnome = desktop && builtins.elem "gnome" cfg.desktopEnvironments;
  lxqt = desktop && builtins.elem "lxqt" cfg.desktopEnvironments;
  selected = name: desktop && builtins.elem name cfg.guiApps;
  emulator = name: desktop && builtins.elem name cfg.emulators;
  # Keep upstream launchers available to UWSM, but show each compositor once in Ly.
  lyWaylandSessions = pkgs.runCommand "sauce-ly-wayland-sessions" { } ''
    mkdir -p "$out"
    cp -a ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions/. "$out/"
    chmod u+w "$out"
    for session in "$out"/*.desktop; do
      if [ -e "''${session%.desktop}-uwsm.desktop" ]; then
        rm "$session"
      fi
    done
  '';
  themes = pkgs.runCommand "sauce-plymouth-themes" { } ''
    mkdir -p "$out/share/plymouth/themes"
    cp -r ${../assets/plymouth}/grafana "$out/share/plymouth/themes/"
    chmod -R u+w "$out"
    for theme in grafana; do
      substituteInPlace "$out/share/plymouth/themes/$theme/$theme.plymouth" \
        --replace-fail "/usr/share/plymouth/themes/$theme" "$out/share/plymouth/themes/$theme"
    done
  '';
in
{
  imports = [
    ./options.nix
    ./maintenance.nix
  ];
  options.sauce.system = {
    user = mkOption {
      type = types.str;
      default = "codyconfer";
      description = "Login user managed by .sauce.";
    };
    homeDirectory = mkOption {
      type = types.str;
      default = "/home/${sys.user}";
      description = "User home directory.";
    };
    homeStateVersion = mkOption {
      type = types.str;
      default = "25.11";
      description = "Initial Home Manager state version; do not bump on upgrades.";
    };
    tailscale = mkOption {
      type = types.bool;
      default = cfg.machineRole == "mobile" || cfg.remoteAccess;
      description = "Tailscale; enabled by default for mobile and remote-access profiles.";
    };
    rslsync = mkOption {
      type = types.bool;
      default = cfg.machineRole == "workstation";
      description = "Resilio Sync; enabled by default on workstations.";
    };
    nvidia = lib.mkEnableOption "proprietary NVIDIA driver (configure PRIME bus IDs in your host module if needed)";
    fingerprint = lib.mkEnableOption "fprintd authentication";
    fwupd = mkOption {
      type = types.bool;
      default = true;
      description = "Firmware updates through fwupd.";
    };
    powerManagement = mkOption {
      type = types.bool;
      default = true;
      description = "UPower and power-profiles-daemon.";
    };
    wifiPowerSave = mkOption {
      type = types.bool;
      default = false;
      description = "NetworkManager Wi-Fi power save (disabled like the shell setup).";
    };
    displayManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Ly as the desktop session selector.";
    };
    consoleFont = mkOption {
      type = types.str;
      default = "ter-124n";
      description = "Linux VT font.";
    };
    plymouthTheme = mkOption {
      type = types.str;
      default = if cfg.machineRole == "workstation" then "bgrt" else "none";
      description = "none, grafana, bgrt, spinner, or a separately installed theme.";
    };
    nixLd = mkOption {
      type = types.bool;
      default = true;
      description = "Compatibility loader for upstream runtime binaries (fnm/rustup).";
    };
    clamav = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Freshclam updates and report-only weekly scans.";
      };
      daemon = lib.mkEnableOption "resident clamd";
      scanPaths = mkOption {
        type = types.listOf types.str;
        default = [ "/home" ];
        description = "Paths scanned; never automatically quarantined or deleted.";
      };
      schedule = mkOption {
        type = types.str;
        default = "Sun *-*-* 03:00:00";
        description = "systemd OnCalendar expression.";
      };
    };
    remote = {
      lmstudio.enable = mkOption {
        type = types.bool;
        default = selected "lmstudio";
        description = "Proxy loopback LM Studio on port 1234 through the Tailscale IPv4 address when remote access is enabled. Start LM Studio's local server separately; restrict access with tailnet ACLs.";
      };
      sshAuthorizedKeysFile = mkOption {
        type = types.str;
        default = "/etc/ssh/sauce-authorized-keys/%u";
        description = "Runtime authorized_keys file; %u expands to the login name. Provision before enabling remote access.";
      };
      codeServerEnvironmentFile = mkOption {
        type = types.str;
        default = "/run/secrets/sauce-code-server.env";
        description = "Root-readable runtime EnvironmentFile containing HASHED_PASSWORD (preferred) or PASSWORD. Never use a Nix path literal for secrets.";
      };
    };
    k3s.enable = mkOption {
      type = types.bool;
      default = builtins.elem "k3s" cfg.tools;
      description = "Run a k3s server. Override services.k3s for cluster-specific settings.";
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = pkgs.stdenv.hostPlatform.isLinux;
            message = ".sauce supports Linux only.";
          }
        ];
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        nixpkgs.config.allowUnfree = true;
        sauce.packageOverrides.bitwarden = lib.mkDefault (
          import ../packages/bitwarden.nix { inherit pkgs; }
        );
        boot.loader.systemd-boot.configurationLimit = lib.mkForce 3;
        security.apparmor = {
          enable = true;
          packages = [ pkgs.apparmor-profiles ];
        };
        security.auditd.enable = true;
        networking.networkmanager = {
          enable = lib.mkDefault true;
          wifi.powersave = sys.wifiPowerSave;
        };
        programs.zsh.enable = true;
        programs.nix-ld.enable = sys.nixLd;
        users.users.${sys.user} = {
          isNormalUser = true;
          home = sys.homeDirectory;
          shell = pkgs.zsh;
          extraGroups = [
            "wheel"
            "networkmanager"
          ]
          ++ lib.optional sway "video"
          ++ lib.optional sway "render"
          ++ lib.optional sway "i2c"
          ++ lib.optional (builtins.elem "docker" cfg.tools) "docker"
          ++ lib.optional (emulator "qemu") "libvirtd"
          ++ lib.optional sys.rslsync "rslsync";
        };
        console = {
          font = sys.consoleFont;
          packages = [ pkgs.terminus_font ];
        };
        services.desktopManager.plasma6.enable = kde;
        services.desktopManager.cosmic.enable = cosmic;
        services.desktopManager.gnome.enable = gnome;
        services.xserver.enable = lxqt || (cfg.remoteAccess && kde);
        services.xserver.desktopManager.lxqt.enable = lxqt;
        services.displayManager.ly = {
          enable = desktop && sys.displayManager;
          settings.waylandsessions = toString lyWaylandSessions;
        };
        services.displayManager.sddm.enable = lib.mkForce false;
        services.displayManager.gdm.enable = lib.mkForce false;
        services.displayManager.cosmic-greeter.enable = lib.mkForce false;
        xdg.portal = {
          enable = desktop;
          wlr.enable = sway;
          extraPortals = lib.mkForce (
            lib.unique (
              [ pkgs.xdg-desktop-portal-gtk ]
              ++ lib.optional sway pkgs.xdg-desktop-portal-wlr
              ++ lib.optional kde pkgs.kdePackages.xdg-desktop-portal-kde
              ++ lib.optional gnome pkgs.xdg-desktop-portal-gnome
              ++ lib.optional cosmic pkgs.xdg-desktop-portal-cosmic
            )
          );
          config = {
            common.default = [ "gtk" ];
            kde.default = [
              "kde"
              "gtk"
            ];
            gnome.default = [
              "gnome"
              "gtk"
            ];
            cosmic.default = [
              "cosmic"
              "gtk"
            ];
            sway = {
              default = [ "gtk" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
            };
          };
        };
        programs.uwsm.enable = sway;
        services.tailscale.enable = sys.tailscale;
        services.resilio.enable = sys.rslsync;
        services.fwupd.enable = sys.fwupd;
        services.fprintd.enable = sys.fingerprint;
        services.upower.enable = sys.powerManagement;
        services.power-profiles-daemon.enable = sys.powerManagement;
        services.clamav.updater.enable = sys.clamav.enable;
        services.clamav.daemon.enable = sys.clamav.enable && sys.clamav.daemon;
        services.k3s.enable = sys.k3s.enable;
        virtualisation.docker.enable = builtins.elem "docker" cfg.tools;
        virtualisation.libvirtd.enable = emulator "qemu";
        programs.virt-manager.enable = emulator "qemu";
        programs.steam.enable = emulator "steam";
        services.flatpak.enable = desktop && cfg.flatpaks != [ ];
        programs._1password.enable = builtins.elem "1password-cli" cfg.tools;
        programs._1password-gui = {
          enable = selected "1password";
          polkitPolicyOwners = [ sys.user ];
        };
        boot.plymouth = {
          enable = sys.plymouthTheme != "none";
          theme = lib.mkIf (sys.plymouthTheme != "none") sys.plymouthTheme;
          themePackages = lib.optional (sys.plymouthTheme == "grafana") themes;
        };
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${sys.user} = {
            imports = [ ./home.nix ];
            services.tailscale-systray = {
              enable = desktop && sys.tailscale;
              theme = "dark:nobg";
            };
            sauce = builtins.removeAttrs cfg [ "system" ];
            home = {
              username = sys.user;
              homeDirectory = sys.homeDirectory;
              stateVersion = sys.homeStateVersion;
            };
          };
        };
      }
      (mkIf (sys.clamav.enable) {
        systemd.services.sauce-clamav-scan = {
          description = "Report-only .sauce malware scan";
          # Let the timer schedule scans; do not restart a running scan and
          # block switch-to-configuration until the entire scan completes.
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.clamav}/bin/clamscan --recursive --infected ${lib.escapeShellArgs sys.clamav.scanPaths}";
            SuccessExitStatus = [
              0
              1
            ];
            Nice = 19;
            IOSchedulingClass = "idle";
          };
        };
        systemd.timers.sauce-clamav-scan = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = sys.clamav.schedule;
            Persistent = true;
          };
        };
      })
      (mkIf (cfg.machineRole == "mobile") {
        networking.firewall.enable = true;
      })
      (mkIf cfg.remoteAccess {
        assertions = [
          {
            assertion =
              lib.hasPrefix "/" sys.remote.codeServerEnvironmentFile
              && !(lib.hasPrefix "/nix/store/" sys.remote.codeServerEnvironmentFile);
            message = "sauce.system.remote.codeServerEnvironmentFile must be an absolute runtime path outside /nix/store.";
          }
        ];
        networking.nftables.enable = true;
        networking.firewall = {
          enable = true;
          backend = "firewalld";
        };
        services.firewalld = {
          enable = true;
          settings = {
            DefaultZone = "drop";
            FirewallBackend = "nftables";
          };
          zones.tailscale = {
            target = "DROP";
            interfaces = [ "tailscale0" ];
            ports =
              map
                (port: {
                  inherit port;
                  protocol = "tcp";
                })
                [
                  22
                  80
                  3389
                ]
              ++ lib.optional sys.remote.lmstudio.enable {
                port = 1234;
                protocol = "tcp";
              };
          };
        };
        services.openssh = {
          enable = true;
          openFirewall = false;
          authorizedKeysFiles = [ sys.remote.sshAuthorizedKeysFile ];
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
          };
        };
        services.caddy = {
          enable = true;
          openFirewall = false;
          environmentFile = "/run/sauce-caddy/tailscale.env";
          virtualHosts = {
            ":80" = {
              listenAddresses = [ "{$TAILSCALE_IP}" ];
              extraConfig = ''
                reverse_proxy 127.0.0.1:8080
              '';
            };
          }
          // lib.optionalAttrs sys.remote.lmstudio.enable {
            "http://:1234" = {
              listenAddresses = [ "{$TAILSCALE_IP}" ];
              extraConfig = ''
                reverse_proxy 127.0.0.1:1234 {
                  flush_interval -1
                }
              '';
            };
          };
        };
        systemd.services.sauce-caddy-tailscale-address = {
          description = "Resolve the Tailscale address for Caddy";
          wantedBy = [ "multi-user.target" ];
          before = [ "caddy.service" ];
          onSuccess = [ "caddy.service" ];
          after = [ "tailscaled.service" ];
          requires = [ "tailscaled.service" ];
          path = [
            pkgs.coreutils
            pkgs.tailscale
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "30s";
          };
          script = ''
            attempt=0
            while [ "$attempt" -lt 30 ]; do
              address="$(tailscale ip -4 2>/dev/null || true)"
              if [ -n "$address" ]; then
                install -d -m 0755 /run/sauce-caddy
                printf 'TAILSCALE_IP=%s\n' "$address" > /run/sauce-caddy/tailscale.env
                chmod 0644 /run/sauce-caddy/tailscale.env
                exit 0
              fi
              attempt=$((attempt + 1))
              sleep 2
            done
            echo "Tailscale IPv4 address not available yet" >&2
            exit 1
          '';
        };
        systemd.services.caddy = {
          requires = [ "sauce-caddy-tailscale-address.service" ];
          after = [ "sauce-caddy-tailscale-address.service" ];
        };
        services.code-server = {
          enable = true;
          user = sys.user;
          group = "users";
          host = "127.0.0.1";
          port = 8080;
          auth = "password";
        };
        systemd.services.code-server = {
          serviceConfig.EnvironmentFile = sys.remote.codeServerEnvironmentFile;
          preStart = ''
            if [ -z "''${HASHED_PASSWORD:-}" ] && [ -z "''${PASSWORD:-}" ]; then
              echo "Provision HASHED_PASSWORD or PASSWORD in the configured runtime EnvironmentFile" >&2
              exit 1
            fi
          '';
        };
        services.xrdp = {
          enable = true;
          openFirewall = false;
          defaultWindowManager = if kde then "startplasma-x11" else "${pkgs.xterm}/bin/xterm";
        };
      })
      (mkIf sway {
        services.displayManager.defaultSession = lib.mkOverride 900 "sway";
        security.pam.services.swaylock = { };
      })
      (mkIf (selected "bitwarden") {
        security.polkit.enable = true;
        # Home Manager's package alone does not register system-wide polkit actions.
        environment.systemPackages = [ (cfg.packageOverrides.bitwarden or pkgs.bitwarden-desktop) ];
      })
      (mkIf sys.rslsync {
        systemd.tmpfiles.rules = [ "d /var/lib/resilio-sync/sync 2770 rslsync rslsync -" ];
      })
      (mkIf desktop {
        services.libinput.enable = true;
        environment.systemPackages = [ pkgs.xinput ];
        hardware.graphics.enable = true;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };
      })
      (mkIf sway {
        programs.sway = {
          enable = true;
          wrapperFeatures.gtk = true;
        };
        programs.uwsm.waylandCompositors.sway = {
          prettyName = "Sway";
          binPath = "/run/current-system/sw/bin/sway";
        };
        security.polkit.enable = true;
        hardware.i2c.enable = true;
        fonts.packages = with pkgs; [
          nerd-fonts.hack
          nerd-fonts.terminess-ttf
          nerd-fonts.fira-code
          nerd-fonts.zed-mono
          nerd-fonts.jetbrains-mono
          nerd-fonts.ubuntu-mono
          nerd-fonts.shure-tech-mono
          nerd-fonts.sauce-code-pro
          (google-fonts.override {
            fonts = [
              "Bilbo"
              "Homemade Apple"
              "Over the Rainbow"
              "Grape Nuts"
              "Permanent Marker"
              "Lavishly Yours"
              "Italianno"
              "Quantico"
              "Titillium Web"
              "Playfair Display"
              "Newsreader"
              "Instrument Serif"
              "Forum"
            ];
          })
          rubik
          roboto
          cabin
          quicksand
          lato
          paratype-pt-serif
          font-awesome
        ];
      })
      (mkIf sys.nvidia {
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
          modesetting.enable = true;
          open = lib.mkDefault false;
        };
      })
    ]
  );
}
