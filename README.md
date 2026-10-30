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

`vanir` imports its platform hardware module and latest kernel. Set the desired
local timezone in its host file. The account is created
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
and power controls; Waybar uses a session-specific module config. Location-based
weather and night-light features are disabled unless both coordinates are set in
your local host configuration.

Selection lists (`tools`, `guiApps`, `media`, `flatpaks`, `emulators`) use keys
from `lib/catalog.nix`; `extraPackages` and `packageOverrides` extend/replace
packages. The server role suppresses GUI/emulator/Flatpak selections even if set.
The workstation defaults include development tools, desktop applications, and
media. NixOS workstations also default to the NixOS Plymouth theme; other roles
default to no theme. Add capability profiles only when needed. Tailscale defaults
on for mobile and `remote` profiles; Resilio Sync defaults on for workstations.

The `remote` profile enables SSH, Firewalld, Caddy, browser-based code-server,
and XRDP. Firewalld drops inbound traffic by default and permits SSH, HTTP, and
RDP only on `tailscale0`; configure Tailscale ACLs too. Caddy binds to the
resolved Tailscale IPv4 address and proxies to code-server on loopback. Code
server authentication is disabled behind that boundary. XRDP uses Plasma X11
when KDE is selected; JetBrains Gateway starts its backend over SSH. VS Code
Tunnel is omitted because its Microsoft relay is not tailnet-only.

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
