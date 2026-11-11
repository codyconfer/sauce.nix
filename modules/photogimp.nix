{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.activation.seedPhotoGimp =
    lib.mkIf
      (
        config.sauce.enable
        && config.sauce.photoGimp
        && config.sauce.machineRole != "server"
        && lib.elem "gimp" config.sauce.guiApps
      )
      (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${
            lib.getExe (import ../packages/photogimp.nix { inherit pkgs; })
          } ${lib.escapeShellArg "${config.xdg.configHome}/GIMP/${lib.versions.majorMinor pkgs.gimp.version}"}
        ''
      );
}
