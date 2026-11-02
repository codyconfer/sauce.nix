{ pkgs, configurations }:
pkgs.runCommand "sauce-ly-sessions-tests" { } ''
  printf '%s\n' cosmic.desktop hyprland-uwsm.desktop sway-uwsm.desktop > expected
  ${pkgs.lib.concatMapStringsSep "\n" (system: ''
    ls -1 ${system.config.services.displayManager.ly.settings.waylandsessions} | sort > actual
    diff -u expected actual
    # UWSM still needs the native launchers in the unfiltered session directory.
    test -e ${system.config.services.displayManager.sessionData.desktops}/share/wayland-sessions/hyprland.desktop
    test -e ${system.config.services.displayManager.sessionData.desktops}/share/wayland-sessions/sway.desktop
  '') configurations}
  touch "$out"
''
