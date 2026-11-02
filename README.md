# .sauce Nix configuration

This repository is a declarative Linux setup using NixOS and Home Manager. It does
not install Nix, repartition disks, or switch the running system by itself. Keep
this configuration and any live chezmoi-managed dotfiles from managing the same
files at the same time.

## Hosts and layout

- `hosts/vanir.nix`: NixOS machine host; uses LUKS and ext4.
- `hosts/testvm.nix`: disposable GNOME/QEMU test host; no physical disk, LUKS,
  or Secure Boot configuration.
- `hosts/codyconfer.nix`: standalone Home Manager configuration for the
  `codyconfer` account.
- `profiles/`: workstation/mobile/server roles, desktop sessions, and optional
  capabilities such as `devbox`, `gaming`, `hypervisor`, `remote`, `personal`,
  and `work`.
- `modules/`, `lib/catalog.nix`: NixOS/Home Manager integration and package
  selections. `dotfiles/` contains the maintained config copies.

## NixOS host

Requires Nix with `nix-command` and `flakes`. The host filesystem UUIDs are
placeholders in `hosts/vanir.nix`; replace `<LUKS-UUID>` and `<EFI-UUID>` with
local values before building. This avoids publishing device identifiers.

**Migration warning:** the root is configured as ext4 inside LUKS. Formatting
`/dev/mapper/cryptroot` destroys the existing Btrfs root, home data, and
subvolumes. Back up first and do not format unless you intend to erase them.

Build and inspect before switching:

```sh
nix flake check --no-build --all-systems "path:$PWD"
sudo nixos-rebuild build --flake "path:$PWD#vanir"
# Switch only after reviewing the build and local hardware/account settings.
sudo nixos-rebuild switch --flake "path:$PWD#vanir"
```

`vanir` imports its platform hardware module and latest kernel, plus `personal`,
`devbox`, `cosmic`, `sway`, `remote`, `workstation`, `gaming`, and `mobile` profiles.
It explicitly retains the workstation role and mobile firewall/Tailscale defaults.
Both `vanir` and `odin` offer only COSMIC, Hyprland, and Sway sessions, with COSMIC
as the default desktop. Profile
selection lists are merged, so development and personal tools are not masked by
a host-level tools override. Provision the remote credentials described below
before switching. Set the desired local timezone in its host file. The account is created
without a usable password; provision authentication before relying on login.
Lanzaboote is included but Secure Boot remains opt-in: provision and enroll your
own keys first, then set `boot.lanzaboote.enable = true;` and
`boot.lanzaboote.pkiBundle = "/var/lib/sb";`. Keep Secure Boot disabled until the
signed boot path is verified and retain a recovery path. Do not change
`system.stateVersion` or `homeStateVersion` during routine updates.

### Disposable desktop VM

```sh
nixos-rebuild build-vm --flake "path:$PWD#testvm"
./result/bin/run-*-vm
```

The VM has 4 GiB RAM, 4 CPUs, and a passwordless test account with auto-login.
It imports the workstation role and GNOME; Ly also offers the workstation's
Hyprland session. It is only a session smoke test, not hardware validation.

## Home Manager

`homeConfigurations.codyconfer` imports workstation and Sway profiles. Build or
switch it on an existing Linux system with:

```sh
home-manager build --flake "path:$PWD#codyconfer"
home-manager switch -b before-nix --flake "path:$PWD#codyconfer"
```

Back up conflicting files first. Standalone Home Manager manages user files and
packages, not host services, kernels, display managers, portals/PAM, or system
Flatpak integration.

## Desktop and selections

Machine roles (`workstation`, `mobile`, `server`) are independent of desktop
sessions. The workstation includes Hyprland under UWSM and Ly, with Hyprland as
its default session. Sway is also UWSM-managed; KDE, GNOME, COSMIC, and LXQt use
their native Ly sessions. Combine session profiles as needed. Hyprland and Sway
share Foot, Fuzzel, Waybar styling, the Mod-key/workspace/launch/lock workflows,
and power controls; Waybar uses a session-specific module config. Ly shows only
the UWSM launcher when both native and UWSM entries exist for a compositor. Location-based
weather and night-light features are disabled unless both coordinates are set in
your local host configuration.

Selection lists (`tools`, `guiApps`, `media`, `flatpaks`, `emulators`) use keys
from `lib/catalog.nix`; `extraPackages` and `packageOverrides` extend/replace
packages. The server role suppresses GUI/emulator/Flatpak selections even if set.
The workstation defaults include development tools, desktop applications, and
media. NixOS workstations also default to Plymouth's stock `bgrt` theme; other roles
default to no theme. Add capability profiles only when needed. Tailscale defaults
on for mobile and `remote` profiles; Resilio Sync defaults on for workstations.

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
  repository = "sftp:backup@backup-host:/backups/vanir";
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
nix build .#checks.x86_64-linux.nixos-vanir
nix build .#checks.x86_64-linux.nixos-testvm
```

CI checks formatting, evaluates all supported systems without modifying the
lockfile, and builds Home Manager and NixOS regression checks. The VM test checks
runtime credentials, SSH key login, code-server authentication, tailnet-only
firewall access, and encrypted backup/restore. It simulates tailnet ingress with
network namespaces; it does not test actual Tailscale enrollment/ACLs, graphical
unlocking, or physical hardware. Full host closures can be built through the
manual GitHub Actions workflow; their derivations are evaluated on every push/PR.
The VM test requires KVM. Test locking/unlocking in each real desktop session
before deployment. Vanir's placeholder UUIDs still require local configuration.

## Dotfiles and security

The port includes shell helpers, tmux, GPG-agent, Neovim, Waybar, Foot, Fuzzel,
Mako, Sway/Hyprland, clipboard, lock/power, and selected package/service
integrations. Fuzzel/cliphist replace zofi; swayr replaces exposway/swaycycle;
brightnessctl replaces lumactl/swaydim. These preserve workflows, not every
source-built tool's exact behavior.

- `nvm` is provided by fnm; old installed Node versions are not migrated.
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
