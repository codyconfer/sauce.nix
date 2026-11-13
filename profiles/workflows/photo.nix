{
  lib,
  pkgs,
  ...
}:
{
  sauce = {
    guiApps = lib.mkDefault (
      [ "gimp" ] ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ "affinity" ]
    );
    photoGimp = lib.mkDefault true;
  };
}
