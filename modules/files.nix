{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  desktop = cfg.enable && cfg.machineRole != "server";
  sway = desktop && builtins.elem "sway" cfg.desktopEnvironments;
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
        "set $term foot"
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
        "set $term ${cfg.sway.terminal}"
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
      config = waybarSource // {
        "modules-left" = [
          "sway/workspaces"
          "sway/mode"
        ];
        "modules-center" = [ "sway/window" ];
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
        xdg.configFile =
          lib.optionalAttrs (builtins.elem "alacritty" cfg.guiApps) (directories [ "alacritty" ])
          // lib.optionalAttrs (builtins.elem "mpv" cfg.media || sway) (directories [ "mpv" ]);
      })
      (lib.mkIf (desktop && builtins.elem "zed" cfg.guiApps) {
        home.packages = [
          pkgs.nil
          pkgs.nixd
        ];
        xdg.configFile."zed/settings.json".text = builtins.toJSON {
          theme = "Tokyo Night";
          vim_mode = true;
          buffer_font_size = 11;
          buffer_font_family = "Hack Nerd Font";
          lsp.nil.binary.path = lib.getExe pkgs.nil;
          lsp.nixd.binary.path = lib.getExe pkgs.nixd;
        };
      })
      (lib.mkIf sway {
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
          ++ lib.optionals (!(builtins.elem cfg.sway.terminal cfg.guiApps)) [ pkgs.${cfg.sway.terminal} ]
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
            "mako"
            "swayimg"
            "swaylock"
            "waylogout"
          ]
          // lib.optionalAttrs (cfg.sway.terminal == "foot") (directories [ "foot" ])
          // {
            "fuzzel/fuzzel.ini".text =
              lib.replaceStrings [ "terminal=foot -e" ] [ "terminal=${cfg.sway.terminal} -e" ]
                (builtins.readFile (source + /fuzzel/fuzzel.ini));
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
    ]
  );
}
