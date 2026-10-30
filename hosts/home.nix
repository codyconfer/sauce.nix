# Standalone Home Manager example; change BOTH username and homeDirectory.
{
  imports = [
    ../profiles/workstation.nix
    ../profiles/sway.nix
  ];
  home = {
    username = "sauce";
    homeDirectory = "/home/sauce";
    stateVersion = "25.11";
  };
}
