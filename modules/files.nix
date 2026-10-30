{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sauce;
  desktop = cfg.enable && !cfg.headless;
  sway = desktop && builtins.elem "sway" cfg.guiApps;
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
        "wlsunset -l 40.6 -L -105.1"
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
        "# Font Awesome icons supplied by Nix fonts"
        ""
        "wlsunset -l ${cfg.sway.latitude} -L ${cfg.sway.longitude}"
      ]
      (builtins.readFile (source + /sway/config));
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
          // lib.optionalAttrs (builtins.elem "mpv" cfg.media || sway) (directories [ "mpv" ]);
      })
      (lib.mkIf sway {
        home.packages =
          with pkgs;
          [
            alacritty
            swaybg
            swayidle
            swaylock
            waybar
            fuzzel
            foot
            mako
            pavucontrol
            grim
            slurp
            wl-clipboard
            brightnessctl
            mpv
            swayimg
            wlsunset
            waypipe
            uwsm
            libnotify
            imagemagick
            ddcutil
            sway-contrib.grimshot
            sway-overfocus
            wl-clip-persist
            wttrbar
            waylogout
            havoc
            way-displays
            wayshot
            swayr
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
          ++ cfg.sway.extraPackages;
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
            "way-displays"
            "waylogout"
            "uwsm"
          ]
          // {
            "havoc/havoc.cfg".text =
              lib.replaceStrings
                [ "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf" ]
                [ "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf" ]
                (builtins.readFile (source + /havoc/havoc.cfg));
            "sway/config".text = swayConfig + ''
              exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
            '';
            "waybar/config.jsonc".text =
              lib.replaceStrings
                [ "$HOME/.local/bin/wttrbar" "40.6,-105.1" ]
                [ "${pkgs.wttrbar}/bin/wttrbar" "${cfg.sway.latitude},${cfg.sway.longitude}" ]
                (builtins.readFile (source + /waybar/config.jsonc));
            "waybar/style.css".source = source + /waybar/style.css;
            "xdg-desktop-portal/sway-portals.conf".source = source + /xdg-desktop-portal/sway-portals.conf;
          };
      })
    ]
  );
}
