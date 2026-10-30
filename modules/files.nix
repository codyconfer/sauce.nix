{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  desktop = cfg.enable && cfg.machineRole != "server";
  sway = desktop && builtins.elem "sway" cfg.guiApps && builtins.elem "sway" cfg.desktopEnvironments;
  hyprland = desktop && cfg.machineRole == "workstation" && builtins.elem "hyprland" cfg.guiApps;
  locationConfigured = cfg.sway.latitude != null && cfg.sway.longitude != null;
  location = "${toString cfg.sway.latitude},${toString cfg.sway.longitude}";
  source = ../dotfiles/config;
  directories =
    names:
    lib.genAttrs names (name: {
      source = source + "/${name}";
      recursive = true;
    });
  swayConfig =
    lib.replaceStrings
      [
        "set $bin ~/.local/bin"
        "exec $app $bin/zofi clipd"
        "exec mkdir -p $EXPOSWAYDIR && $app $bin/exposwayd"
        "$bin/zofi launch"
        "$bin/zofi clipboard"
        "$bin/exposway"
        "$bin/swaycycle --prev"
        "$bin/swaycycle"
        "$bin/lumactl set +5%"
        "$bin/lumactl set -- -5%"
        "$bin/swaydim"
        "$bin/sway-screenshot -m output"
        "$bin/sway-screenshot -m region --clipboard-only"
        "$bin/sway-screenshot -m region"
        "$bin/sway-screenshot -m window"
        "flatpak run io.github.seadve.Kooha"
        "include sway-font-awesome/icons-wl"
        "include sway-font-awesome/icons-x11"
      ]
      [
        "set $bin ${config.home.profileDirectory}/bin"
        "exec $app wl-paste --watch cliphist store"
        "exec $app swayrd"
        "fuzzel"
        "$bin/sauce-clipboard"
        "swayr switch-window"
        "swayr prev-window all"
        "swayr next-window all"
        "brightnessctl set +5%"
        "brightnessctl set 5%-"
        "brightnessctl set 15%"
        "grimshot save output"
        "grimshot copy area"
        "grimshot save area"
        "grimshot save active"
        "kooha"
        ""
        ""
      ]
      (builtins.readFile (source + /sway/config));
  waybarSource = builtins.fromJSON (builtins.readFile (source + /waybar/config.jsonc));
  waybarConfig =
    compositor:
    let
      isHyprland = compositor == "hyprland";
      compositorSource =
        if isHyprland then
          (builtins.removeAttrs waybarSource [
            "sway/workspaces"
            "sway/mode"
            "sway/window"
          ])
          // {
            "hyprland/workspaces" = {
              "disable-scroll" = true;
              "all-outputs" = true;
              format = "{icon}";
              "format-icons" = {
                "1" = "1:󰆍";
                "2" = "2:󰖟";
                "3" = "3:󰅩";
                "4" = "4:󰉋";
                "5" = "5:󰭹";
                "6" = "6:󰝚";
                "7" = "7:󰕧";
                "8" = "8:󰍹";
                "9" = "9:󰺵";
                "10" = "10:󰀻";
                default = "󰈹";
              };
            };
            "hyprland/submap".format = "{}";
            "hyprland/window"."max-length" = 60;
          }
        else
          waybarSource;
      config = compositorSource // {
        "modules-left" =
          if isHyprland then
            [
              "hyprland/workspaces"
              "hyprland/submap"
            ]
          else
            [
              "sway/workspaces"
              "sway/mode"
            ];
        "modules-center" = [ (if isHyprland then "hyprland/window" else "sway/window") ];
        "modules-right" = [
          "tray"
        ]
        ++ lib.optional locationConfigured "custom/weather"
        ++ [
          "pulseaudio"
          "battery"
          "clock"
        ];
      };
      withWeather =
        if locationConfigured then
          config
          // {
            "custom/weather" = {
              exec = "${pkgs.wttrbar}/bin/wttrbar --nerd --mph --hide-conditions --location ${location} --custom-indicator '{ICON} {temp_C}°'";
              "return-type" = "json";
              format = "{}";
              interval = 1800;
              tooltip = true;
              "on-click" = "xdg-open https://wttr.in/${location}";
            };
          }
        else
          config;
    in
    builtins.toJSON withWeather;
  hyprlandConfig =
    builtins.readFile (source + /hypr/hyprland.conf)
    + lib.optionalString locationConfigured ''
      exec-once = uwsm app -s b -- wlsunset -l ${toString cfg.sway.latitude} -L ${toString cfg.sway.longitude}
    '';
  power = pkgs.writeShellScriptBin "sauce-power" (builtins.readFile ../dotfiles/bin/sauce-power);
  askpass = pkgs.writeShellScriptBin "sauce-askpass" (
    builtins.readFile ../dotfiles/bin/sauce-askpass
  );
  clipboard = pkgs.writeShellApplication {
    name = "sauce-clipboard";
    runtimeInputs = [
      pkgs.cliphist
      pkgs.fuzzel
      pkgs.wl-clipboard
    ];
    text = ''
      selection=$(cliphist list | fuzzel --dmenu) || exit 0
      [ -n "$selection" ] || exit 0
      printf '%s\n' "$selection" | cliphist decode | wl-copy
    '';
  };
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = (cfg.sway.latitude == null) == (cfg.sway.longitude == null);
            message = "Set both sauce.sway.latitude and sauce.sway.longitude, or neither.";
          }
        ];
        xdg.enable = true;
        xdg.configFile = lib.optionalAttrs (builtins.elem "tmux" cfg.tools) (directories [ "tmux" ]);
      }
      (lib.mkIf desktop {
        home.packages = with pkgs; [
          nerd-fonts.hack
          nerd-fonts.terminess-ttf
          font-awesome
        ];
        xdg.configFile =
          lib.optionalAttrs (builtins.elem "alacritty" cfg.guiApps) (directories [ "alacritty" ])
          // lib.optionalAttrs (builtins.elem "mpv" cfg.media || sway || hyprland) (directories [ "mpv" ]);
      })
      (lib.mkIf (sway || hyprland) {
        home.packages =
          with pkgs;
          [
            waybar
            fuzzel
            mako
            swayidle
            swaylock
            pavucontrol
            grim
            slurp
            wl-clipboard
            wl-clip-persist
            brightnessctl
            mpv
            swayimg
            waylogout
            uwsm
            libnotify
            imagemagick
            ddcutil
            cliphist
            kooha
            polkit_gnome
            pulseaudio
            procps
            util-linux
            gawk
            adwaita-icon-theme
            clipboard
            power
            askpass
          ]
          ++ lib.optionals (!(builtins.elem "foot" cfg.guiApps)) [ pkgs.foot ]
          ++ lib.optionals locationConfigured [
            pkgs.wlsunset
            pkgs.wttrbar
          ]
          ++ lib.optionals sway [
            swaybg
            waypipe
            sway-contrib.grimshot
            sway-overfocus
            way-displays
            wayshot
            swayr
          ]
          ++ lib.optionals sway cfg.sway.extraPackages;
        home.file = {
          ".local/bin/sauce-power".source = "${power}/bin/sauce-power";
          ".local/bin/sauce-askpass".source = "${askpass}/bin/sauce-askpass";
        };
        xdg.configFile =
          directories [
            "foot"
            "fuzzel"
            "mako"
            "swayimg"
            "swaylock"
            "waylogout"
          ]
          // {
            "uwsm/env".source = source + /uwsm/env;
            "waybar/style.css".source = source + /waybar/style.css;
          };
      })
      (lib.mkIf sway {
        xdg.configFile = directories [ "way-displays" ] // {
          "sway/config".text =
            swayConfig
            + lib.optionalString locationConfigured ''
              exec $app wlsunset -l ${toString cfg.sway.latitude} -L ${toString cfg.sway.longitude}
            ''
            + ''
              exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
            '';
          "waybar/config-sway.jsonc".text = waybarConfig "sway";
          "waybar/style.css".source = source + /waybar/style.css;
          "xdg-desktop-portal/sway-portals.conf".source = source + /xdg-desktop-portal/sway-portals.conf;
          "uwsm/env-sway".source = source + /uwsm/env-sway;
        };
      })
      (lib.mkIf hyprland {
        xdg.configFile = {
          "hypr/hyprland.conf".text = hyprlandConfig;
          "waybar/config-hyprland.jsonc".text = waybarConfig "hyprland";
        };
      })
    ]
  );
}
