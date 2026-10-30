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
  desktop = !cfg.headless;
  sway = desktop && cfg.desktopEnvironment == "sway" && builtins.elem "sway" cfg.guiApps;
  hyprland = desktop && cfg.desktopEnvironment == "hyprland" && builtins.elem "hyprland" cfg.guiApps;
  selected = name: desktop && builtins.elem name cfg.guiApps;
  emulator = name: desktop && builtins.elem name cfg.emulators;
  themes = pkgs.runCommand "sauce-plymouth-themes" { } ''
    mkdir -p "$out/share/plymouth/themes"
    cp -r ${../assets/plymouth}/arch ${../assets/plymouth}/grafana "$out/share/plymouth/themes/"
    chmod -R u+w "$out"
    for theme in arch grafana; do
      substituteInPlace "$out/share/plymouth/themes/$theme/$theme.plymouth" \
        --replace-fail "/usr/share/plymouth/themes/$theme" "$out/share/plymouth/themes/$theme"
    done
  '';
in
{
  imports = [ ./options.nix ];
  options.sauce.system = {
    user = mkOption {
      type = types.str;
      default = "sauce";
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
    tailscale = lib.mkEnableOption "Tailscale (authenticate manually with tailscale up)";
    rslsync = lib.mkEnableOption "Resilio Sync";
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
      description = "Enable ly for Sway desktops.";
    };
    consoleFont = mkOption {
      type = types.str;
      default = "ter-124n";
      description = "Linux VT font.";
    };
    plymouthTheme = mkOption {
      type = types.str;
      default = "none";
      description = "none, arch, grafana, bgrt, spinner, or a separately installed theme.";
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
        nixpkgs.config.allowUnfree = lib.mkDefault true;
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
          ++ lib.optional (sway || hyprland) "video"
          ++ lib.optional (sway || hyprland) "render"
          ++ lib.optional sway "i2c"
          ++ lib.optional (builtins.elem "docker" cfg.tools) "docker"
          ++ lib.optional (emulator "qemu") "libvirtd"
          ++ lib.optional sys.rslsync "rslsync";
        };
        console = {
          font = sys.consoleFont;
          packages = [ pkgs.terminus_font ];
        };
        services.desktopManager.plasma6.enable = desktop && cfg.desktopEnvironment == "kde";
        services.desktopManager.cosmic.enable = desktop && cfg.desktopEnvironment == "cosmic";
        services.desktopManager.gnome.enable = desktop && cfg.desktopEnvironment == "gnome";
        services.displayManager.gdm.enable = desktop && cfg.desktopEnvironment == "gnome";
        services.xserver.enable = desktop && cfg.desktopEnvironment == "lxqt";
        services.xserver.desktopManager.lxqt.enable = desktop && cfg.desktopEnvironment == "lxqt";
        services.displayManager.ly.enable = desktop && cfg.desktopEnvironment == "lxqt" && sys.displayManager;
        programs.hyprland.enable = hyprland;
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
        services.ollama.enable = builtins.elem "ollama" cfg.tools;
        services.flatpak.enable = desktop && cfg.flatpaks != [ ];
        programs._1password.enable = builtins.elem "1password-cli" cfg.tools;
        programs._1password-gui = {
          enable = selected "1password";
          polkitPolicyOwners = [ sys.user ];
        };
        boot.plymouth = {
          enable = sys.plymouthTheme != "none";
          theme = lib.mkIf (sys.plymouthTheme != "none") sys.plymouthTheme;
          themePackages = lib.optionals (builtins.elem sys.plymouthTheme [
            "arch"
            "grafana"
          ]) [ themes ];
        };
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${sys.user} = {
            imports = [ ./home.nix ];
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
      (mkIf sys.rslsync {
        systemd.tmpfiles.rules = [ "d /var/lib/resilio-sync/sync 2770 rslsync rslsync -" ];
      })
      (mkIf desktop {
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
        programs.uwsm = {
          enable = true;
          waylandCompositors.sway = {
            prettyName = "Sway";
            binPath = "/run/current-system/sw/bin/sway";
          };
        };
        services.displayManager.ly.enable = sys.displayManager;
        security.polkit.enable = true;
        security.pam.services.swaylock = { };
        hardware.i2c.enable = true;
        xdg.portal = {
          enable = true;
          wlr.enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          config.sway = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          };
        };
        fonts.packages = with pkgs; [
          nerd-fonts.hack
          nerd-fonts.terminess-ttf
          font-awesome
        ];
      })
      (mkIf hyprland {
        programs.uwsm = {
          enable = true;
          waylandCompositors.hyprland = {
            prettyName = "Hyprland";
            binPath = "/run/current-system/sw/bin/Hyprland";
          };
        };
        services.displayManager.ly.enable = sys.displayManager;
        security.polkit.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
          config.hyprland.default = [ "hyprland" "gtk" ];
        };
        fonts.packages = with pkgs; [
          nerd-fonts.hack
          nerd-fonts.terminess-ttf
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
