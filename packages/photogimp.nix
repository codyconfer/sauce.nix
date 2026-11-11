{ pkgs }:
let
  source = pkgs.fetchFromGitHub {
    owner = "Diolinux";
    repo = "PhotoGIMP";
    rev = "fc61a8f4518eaf18659b749e9464ff32b6607739";
    hash = "sha256-JjK9W59xauzjl88aN1666gCJwUbKurrddFt9rGSMONQ=";
  };
in
pkgs.writeShellApplication {
  name = "sauce-photogimp-init";
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    target="$1"
    marker="$target/.sauce-photogimp-initialized"
    if [[ -f "$marker" ]]; then
      exit 0
    fi
    if [[ -L "$target" ]]; then
      echo "PhotoGIMP: refusing to modify symlinked configuration: $target" >&2
      exit 1
    fi
    if [[ -d "$target" ]]; then
      backup=$(mktemp -d "$target.photogimp-backup.XXXXXX")
      cp -a "$target/." "$backup/"
      echo "PhotoGIMP: backed up existing settings to $backup"
    fi
    mkdir -p "$target"
    cp -R --no-preserve=mode ${source}/.config/GIMP/3.0/. "$target/"
    touch "$marker"
  '';
}
