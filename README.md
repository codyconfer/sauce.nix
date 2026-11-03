# .sauce Nix configuration

This repository is a declarative Linux setup using NixOS and Home Manager. It does
not install Nix, repartition disks, or switch the running system by itself. Keep
this configuration and any live chezmoi-managed dotfiles from managing the same
files at the same time.

## Layout

- `profiles/`: reusable roles, desktops, and optional capabilities.
- `modules/`, `lib/catalog.nix`: NixOS/Home Manager integration and packages.
- `dotfiles/`: maintained user configuration copies.

`machines/vanir.nix` contains committed profile, driver, and preference selections,
exported as `nixosModules.vanir`. It uses the workstation's default Sway session.
Disk identifiers, mounts, bootloader settings, and installation state versions
remain machine-local.

## Minimal install, then profiles

Install NixOS using the official minimal ISO. Keep the generated
`/etc/nixos/configuration.nix` and `hardware-configuration.nix` on that machine:
they own disks, bootloader, hardware, hostname, accounts, and state version.
Do not copy them into this repository.

After the headless installation boots, enable `nix-command` and `flakes` and
create a machine-local `/etc/nixos/flake.nix` (replace the repository path and user):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sauce.url = "path:/absolute/path/to/sauce.nix";
    sauce.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, sauce, ... }: {
    nixosConfigurations.local = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or aarch64-linux
      modules = [
        ./configuration.nix
        sauce.nixosModules.default
        sauce.nixosModules.profiles.server
        {
          sauce.system.user = "your-user";
          sauce.system.homeStateVersion = "25.11";
        }
      ];
    };
  };
}
```

The generated configuration normally imports the local hardware configuration;
keep that import. Use your existing login user and retain its authentication.
Set the Home Manager state version on first use, then keep it unchanged; also
retain the installed system's `system.stateVersion`.

```sh
cd /etc/nixos
sudo nixos-rebuild build --flake .#local
# Review changes and keep console/recovery access before switching.
sudo nixos-rebuild switch --flake .#local
```

Start with `server` for headless use. For a desktop, replace it with
`workstation` and optionally add `sauce.nixosModules.profiles.gnome` (or another
desktop). Add capability profiles such as `devbox` independently. Provision
credentials below before enabling `remote`; it changes firewall and login
services. Hardware-specific options and Secure Boot remain machine-local.
Update the local lockfile explicitly with `nix flake update` to pick up changes.

### Vanir selections

To use the committed Vanir selections, replace `sauce.nixosModules.default`,
the individual profile entries, and the inline `sauce.system` settings in the
example above with:

```nix
sauce.nixosModules.vanir
```

Keep `./configuration.nix` in the module list. Keep its hardware import, storage,
bootloader, account authentication, and `system.stateVersion` local. Remove
conflicting preference settings from that local file (for example its old
`networking.hostName = "nixos"`); Vanir selects hostname `vanir` and Denver time.
The module includes remote access: provision the credentials below before
switching. It does not enable SSH password authentication.

### Odin selections

Use `sauce.nixosModules.odin` in place of `sauce.nixosModules.vanir` for Odin.
`machines/odin.nix` matches Vanir's profiles, Sway/COSMIC desktops, Alacritty,
`codyconfer` user, and Denver timezone, but selects hostname `odin` and enables
the proprietary NVIDIA driver (including Sway's `--unsupported-gpu` opt-in).
Both machines enable Intel modesetting, the Intel VA-API media driver, and the
oneVPL runtime, and inherit non-free package support from the shared module.
Odin retains Vanir's Intel KVM module; change that locally for an AMD CPU.
GPU-specific driver overrides and any PRIME bus IDs remain machine-local.

The included remote profile enables SSH, XRDP, and Caddy proxying code-server,
with inbound access restricted to Tailscale. Provision Tailscale, SSH keys,
code-server credentials, and a local account password as described below before
switching. XRDP opens a separate Xterm session, not the local Sway/COSMIC desktop.
Keep storage, bootloader, authentication, and installed state versions local,
as with Vanir.

## Home Manager

Standalone consumers can import `sauce.homeManagerModules.default` plus chosen
profiles from `sauce.nixosModules.profiles` in their own Home Manager flake.
Set `home.username`, `home.homeDirectory`, and `home.stateVersion` locally.
Back up conflicting files before activation. Standalone Home Manager manages
user files and packages, not system services or hardware.

## Desktop and selections

The COSMIC profile installs the captured preferences from `dotfiles/config/cosmic`
through Home Manager: left dock, top panel, dark green-accent theme, tiling,
workspaces, touchpad/keyboard preferences, shortcuts, app groups/favorites, idle
settings, and terminal appearance. No monitor identifiers or disk information
are included. Favorites refer to app IDs; they do not install those applications.
Back up `~/.config/cosmic` before first activation and move conflicting files aside
(or use Home Manager's backup mechanism). Managed files are read-only symlinks;
edit the repository copies rather than relying on Settings changes to persist.


Machine roles (`workstation`, `mobile`, `server`) are independent of desktop
sessions. The workstation profile defaults to Sway under UWSM. KDE, GNOME,
COSMIC, and LXQt use their native Ly sessions when selected alongside Sway.
Combine session profiles as needed. Sway uses Foot, Fuzzel, Waybar styling, the Mod-key/workspace/launch/lock
workflows, and power controls. Location-based
weather and night-light features are disabled unless both coordinates are set in
your local host configuration.

In Bash and Zsh, `update` refreshes Nix packages with `nix flake update`, pulls
.sauce with `git pull --ff-only`, then builds and switches via `sauce-rebuild`.
It uses `SAUCE_NIX_FLAKE` (default `~/.sauce/nix`) and forwards arguments to the
rebuild step. Each step must succeed before the next runs. The lock file remains
locally updated; if upstream changes conflict with it, resolve them and rerun.
Use `sauce` to build and switch without updating.

Selection lists (`tools`, `guiApps`, `media`, `flatpaks`, `emulators`) use keys
from `lib/catalog.nix`; `extraPackages` and `packageOverrides` extend/replace
packages. The server role suppresses GUI/emulator/Flatpak selections even if set.
The workstation defaults include development tools, desktop applications, and
media. NixOS workstations also default to the NixOS Plymouth theme; other roles
default to no theme. Add capability profiles only when needed. Tailscale defaults
on for mobile and `remote` profiles; Resilio Sync defaults on for workstations.

The `personal` profile opts Signal's Flatpak into keyring-backed local database
key storage (`SIGNAL_PASSWORD_STORE=gnome-libsecret`) using a per-app user override.
COSMIC and GNOME on NixOS already enable GNOME Keyring; other setups need an
unlocked Secret Service provider. Flathub labels encrypted backends experimental
and warns of possible data loss. Quit Signal and back up
`~/.var/app/org.signal.Signal` before activating this change. Preserve the keyring
as well: losing it can make the database unreadable. Restart Signal after activation.
If `~/.local/share/flatpak/overrides/org.signal.Signal` already exists, merge any
needed overrides into the profile and move the file aside before Home Manager
activation. This protects the database key, not all local files or an unlocked session.

The `remote` profile enables SSH, Firewalld, Caddy, browser-based code-server,
and XRDP. Firewalld drops inbound traffic by default and permits SSH, HTTP, and
RDP only on `tailscale0`; configure Tailscale ACLs too. Caddy binds to the
resolved Tailscale IPv4 address and proxies to code-server on loopback. Code-server
also requires a password supplied through a runtime environment file. SSH accepts
keys only, with root login and keyboard-interactive authentication disabled.
The firewall explicitly uses the Firewalld backend, including mobile + remote
combinations. XRDP uses Plasma X11
when KDE is selected; JetBrains Gateway starts its backend over SSH. VS Code
Tunnel is omitted because its Microsoft relay is not tailnet-only.

### Provision remote access before switching

Enroll Tailscale and restrict SSH, HTTP, and RDP with tailnet ACLs. Provision your
SSH **public** key through the console or an existing administrative session:

```sh
sudo install -d -m 0755 /etc/ssh/sauce-authorized-keys
sudo install -m 0644 /path/to/your-key.pub /etc/ssh/sauce-authorized-keys/codyconfer
```

The directory and public key must be readable by the login user, but writable only
by root. `sauce.system.remote.sshAuthorizedKeysFile` changes this runtime location
(`%u` expands to the login name). Existing `~/.ssh/authorized_keys` and declarative
NixOS public keys remain supported. Keep console access until SSH is tested.

Provision `/run/secrets/sauce-code-server.env` with mode `0600`, owned by root,
using your secret manager. Set `HASHED_PASSWORD` to a code-server-compatible
Argon2 hash (preferred), or `PASSWORD` to a strong password, using systemd
EnvironmentFile syntax. Set only one. The file is mandatory and an empty file
fails closed. `sauce.system.remote.codeServerEnvironmentFile` changes its path.
Never use a Nix path literal or `builtins.readFile` for credentials. `/run` is
volatile: arrange provisioning on every boot before the service starts.

Restart `code-server.service` after provisioning. Test that unauthenticated
browser access reaches the login page and that SSH and RDP are unreachable from
outside the tailnet. XRDP still requires a usable local account password; SSH
password login remains disabled. The HTTP connection relies on WireGuard's
encryption, so do not expose the proxy outside the tailnet.

## Maintenance and recovery

Weekly garbage collection removes unreferenced store paths and generations older
than 30 days; current profiles and their closures remain rooted. Automatic store
optimisation is also enabled. Older rollback generations may be removed: pin a
needed generation with a GC root before relying on it long term. Override
`nix.gc`/`nix.optimise`, or set `sauce.system.maintenance.enable = false` to opt out
of these defaults.

Backups are **opt-in**, not silently enabled without a destination. Configure:

```nix
sauce.system.backup = {
  enable = true;
  repository = "sftp:backup@backup-host:/backups/my-machine";
  passwordFile = "/run/secrets/sauce-restic-password";
  # Optional remote-provider credentials, provisioned at runtime:
  # environmentFile = "/run/secrets/sauce-restic.env";
  paths = [ "/home/codyconfer" "/path/to/sauce.nix" ];
  # For a local disk, declare its fileSystems mount, then require that mount:
  # repository = "/mnt/backup/restic";
  # requiresMountsFor = [ "/mnt/backup" ];
};
```

Provision the password/credential files root-owned, mode `0600`, outside the Nix
store, and preserve the repository password separately for disaster recovery.
For SFTP, provision root's SSH credentials and verified known-host entry too.
Backups run daily around 02:00 with up to one hour of jitter and catch up after
missed runs. The repository initializes on first use; retention keeps 7 daily,
5 weekly, and 12 monthly snapshots. Each run checks metadata and reads a random
10% of stored data. The default paths are the managed user's home and
`/etc/nixos`; override them to match the actual configuration location. A live
file backup is not an application-consistent database snapshot: configure
service-specific dumps/hooks if needed.

Before trusting backups, run and inspect a complete restore drill:

```sh
sudo systemctl start restic-backups-sauce.service
sudo journalctl -u restic-backups-sauce.service
sudo restic-sauce snapshots
sudo restic-sauce check --read-data
sudo restic-sauce restore latest --target /var/tmp/sauce-restore
# Inspect/compare restored files; do not restore over the live home blindly.
```

Repeat full checks and restore drills periodically. Inspect failed backup units
and arrange notifications/monitoring appropriate to your environment. Keep an
offline/off-site copy and recovery media; NixOS rollback is not a data backup.

## Validation and CI

```sh
nix fmt -- --check $(git ls-files '*.nix')
nix flake check --no-build --all-systems --no-update-lock-file
nix build .#checks.x86_64-linux.nixos-configuration
nix build -L .#checks.x86_64-linux.nixos-smoke
```

CI checks formatting, evaluates all supported systems without modifying the
lockfile, and builds Home Manager and NixOS regression checks. The VM test checks
runtime credentials, SSH key login, code-server authentication, tailnet-only
firewall access, and encrypted backup/restore. It simulates tailnet ingress with
network namespaces; it does not test actual Tailscale enrollment/ACLs, graphical
unlocking, or physical hardware. Profile combinations are evaluated without physical host definitions.
The VM test requires KVM. Test locking/unlocking in each real desktop session
before deployment.

## Dotfiles and security

The port includes shell helpers, tmux, GPG-agent, Neovim, Waybar, Foot, Fuzzel,
Mako, Sway, clipboard, lock/power, and selected package/service
integrations. Fuzzel/cliphist replace zofi; swayr replaces exposway/swaycycle;
brightnessctl replaces lumactl/swaydim. These preserve workflows, not every
source-built tool's exact behavior.

- `nvm` loads pinned upstream nvm in Bash and Zsh, with Node versions stored in
  `~/.nvm`. After switching, open a new shell and run `nvm install --lts`.
  Previously installed fnm Node versions are not migrated. On NixOS, downloaded
  Node binaries rely on `sauce.system.nixLd` (enabled by default).
- Flatpak selections install additively through `sauce-flatpaks`; removing a
  selection does not uninstall its app.
- `sauce-pi-extensions` runs explicitly; activation does not fetch extensions.
  Pi MCP settings must contain no secrets.
- ClamAV scans are report-only. Docker group membership is root-equivalent.
  Configure k3s before using it outside local testing.
- Authentication, Tailscale enrollment, Resilio peers, and other runtime
credentials are not automated. Nix store contents may be world-readable and
are not a secret store; pushed files are public. Never put keys, tokens,
passwords, or private identifiers in Nix options or committed dotfiles. Use
runtime secret files or a secret manager.
