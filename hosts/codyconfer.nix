{
  imports = [
    ../profiles/workstation.nix
    ../profiles/sway.nix
  ];

  home = {
    username = "codyconfer";
    homeDirectory = "/home/codyconfer";
    stateVersion = "26.05";
  };
}
