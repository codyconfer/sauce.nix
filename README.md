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
        sauce.nixosModules.profiles.headless
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

Start with `headless` for a machine without a desktop. For a desktop, replace it
with `workstation` and optionally add `sauce.nixosModules.profiles.gnome` (or
another desktop). Add capability profiles such as `devbox` independently. Provision
credentials below before enabling `headless/devbox` (development services)
and/or `headless/ssh` (SSH access); these configure the tailnet firewall.
Hardware-specific options and Secure Boot remain machine-local.
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
The machine imports headless SSH and devbox capabilities: provision SSH keys
and code-server credentials as described below before switching. SSH password
authentication is disabled.

### Odin selections

Use `sauce.nixosModules.odin` in place of `sauce.nixosModules.vanir` for Odin.
`machines/odin.nix` matches Vanir's profiles, Sway/COSMIC desktops, Alacritty,
`codyconfer` user, and Denver timezone, but selects hostname `odin` and enables
the proprietary NVIDIA driver (including Sway's `--unsupported-gpu` opt-in).
Both machines enable Intel modesetting, the Intel VA-API media driver, and the
oneVPL runtime, and inherit non-free package support from the shared module.
Odin retains Vanir's Intel KVM module; change that locally for an AMD CPU.
GPU-specific driver overrides and any PRIME bus IDs remain machine-local.

Odin also matches Vanir's `/srv/sync` and `/srv/sync/downloads` directories and
its authenticated Resilio web UI on port 9000. Unlike Vanir, Odin does not bind a
LAN firewall zone to Vanir's Wi-Fi interface; access to the UI is allowed only via
Tailscale. Add an explicit machine-local LAN zone if needed. Before switching,
provision root-owned mode-0600 `/var/lib/sauce/secrets/resilio-webui.env` containing
`RESILIO_WEBUI_LOGIN` and `RESILIO_WEBUI_PASSWORD_HASH` (a Resilio-compatible hash).
The service refuses to start if the file or either value is missing. Keep these
credentials outside Nix. Odin's code-server environment file also now uses the
persistent `/var/lib/sauce/secrets/code-server.env`, matching Vanir and Tyr; provision it
with the format and permissions described below rather than `/run/secrets`.

The included `headless/ssh` profile enables SSH; the `headless/devbox` profile
independently enables code-server and its Caddy proxy. Both are restricted to
Tailscale. Provision Tailscale, SSH keys, and code-server credentials as
described below before switching. Keep storage,
bootloader, authentication, and installed state versions local, as with Vanir.

### Tyr selections

Use `sauce.nixosModules.tyr` for Tyr. `machines/tyr.nix` uses Vanir's selections
as its baseline: Sway/COSMIC, Alacritty, the `codyconfer` user, Denver timezone,
Intel KVM and graphics, plus the proprietary NVIDIA driver (including Sway's
`--unsupported-gpu` opt-in). It selects hostname `tyr` and adds the
`profiles/work.nix` profile, exported as `sauce.nixosModules.profiles.work`.
The `headless/ssh` profile is not enabled; Tailscale remains enabled.
Adjust hardware selections locally if Tyr differs from this baseline.

As with Vanir, keep storage, bootloader, account authentication, and installed
state versions local.

## Home Manager

Standalone consumers can import `sauce.homeManagerModules.default` plus chosen
profiles from `sauce.nixosModules.profiles` in their own Home Manager flake.
Set `home.username`, `home.homeDirectory`, and `home.stateVersion` locally.
Back up conflicting files before activation. Standalone Home Manager manages
user files and packages, not system services or hardware.

## Desktop and selections

The COSMIC profile enables the desktop and manages three custom shortcuts:
Super+Enter opens a terminal, Super+Backspace closes the focused window, and
Super+N minimizes it. A Home Manager user service temporarily turns the standard
panel and dock backgrounds opaque orange while `sauce-clamav-scan.service` runs,
then restores their previous colors and opacity (including after a watcher restart).
It checks every two seconds, handles scan failure/cancellation, and does not track
manually launched `clamscan` processes. Backgrounds managed through symlinks are
left untouched. Other desktop preferences remain unmanaged.
For non-server roles selecting COSMIC, Home Manager also installs
StarryDex, Forecast, Clipboard Manager, Privacy Indicator,
Music Player (Ebbo), Power Monitor, and Eyedropper. Applets are
available to add manually; panel layouts and enabled applets are not changed.
Forecast and Privacy Indicator come from pinned nixpkgs; the other five use
local Rust packages in `packages/cosmic/` with pinned source and dependency
hashes in `packages/cosmic/sources.json`. Cupola and Compass were removed
because their upstream tests blocked system updates.

Machine roles (`workstation`, `server`) are independent of desktop sessions.
Built-in workstation machine configurations default to Sway under UWSM. KDE,
GNOME and COSMIC use their native Ly sessions when selected alongside Sway. Combine session profiles as needed. Sway uses its configured terminal, Fuzzel, Waybar styling, the
Mod-key/workspace/launch/lock workflows, and power controls. Location-based
weather and night-light features are disabled unless both coordinates are set in
your local host configuration.

In Bash and Zsh, `update` pulls the sauce repository (`SAUCE_REPO`, default
`~/sauce.nix`), updates the NixOS flake inputs (`SAUCE_NIX_FLAKE`, default
`/etc/nixos`), then builds and switches the selected host. `SAUCE_NIX_HOST`
defaults to the machine hostname. Each step must succeed before the next runs;
arguments are forwarded to both build and switch. The lock file is updated
locally. `sauce` only builds and switches. These defaults do not use the legacy
`~/.sauce` path.

Selection lists (`tools`, `guiApps`, `media`, `flatpaks`, `emulators`) use keys
from `lib/catalog.nix`; `extraPackages` and `packageOverrides` extend/replace
packages. The `sauce.nixosModules.profiles.workflows.default` profile supplies
Firefox, Sway, Alacritty, Obsidian, Typora, LibreOffice, Slack, Easy Effects,
Zen, and common media players/FFmpeg.
The `sauce.nixosModules.profiles.workflows.dev` profile supplies SourceGit,
VS Code, Zed, Docker, Podman Desktop, Ghidra, JetBrains Toolbox, and LM Studio.
The `sauce.nixosModules.profiles.workflows.radio` profile supplies GNU Radio,
SDR++, Gqrx, qdmr, and Chirp. The `sauce.nixosModules.profiles.workflows.video`
profile supplies OBS Studio, Kdenlive, and Shotcut, plus DaVinci Resolve on
x86_64 Linux. The `sauce.nixosModules.profiles.workflows.music` profile supplies
Sonic Pi, REAPER, Neural Amp Modeler (`nam`), Guitarix, Ardour, LMMS, Zrythm,
Qtractor, Helio, and (on x86_64 Linux) BYOD. The
`sauce.nixosModules.profiles.workflows.photo` profile supplies GIMP with
PhotoGIMP and Affinity on x86_64 Linux. The `workflows.remote-vnc` profile adds
WayVNC for VNC serving from wlroots-based Wayland compositors such as Sway; it
does not enable or configure a service. The `workflows.client-vnc` profile adds
Remmina as a Wayland-capable VNC client. Built-in workstation machines import
their standard workflows. The server
role suppresses GUI/emulator/Flatpak selections even if set. NixOS workstations
also default to the NixOS Plymouth theme; other roles default to no theme. Add
capability profiles only when needed. Tailscale defaults
on for `headless/ssh` and `headless/devbox` profiles; Resilio Sync defaults on for workstations.

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

### Affinity on Linux

The `photo` workflow installs unified Affinity v3 on x86_64 Linux through
[mrshmllow/affinity-nix](https://github.com/mrshmllow/affinity-nix), pinned in
`flake.lock`. Other architectures skip it. Select `"affinity"` in `sauce.guiApps`
to enable it elsewhere using this flake's NixOS or Home Manager module.
Run `affinity-v3` or use its desktop launcher. This is unofficial Wine support;
expect compatibility bugs and complete any required sign-in interactively.
User data lives in `$XDG_DATA_HOME/affinity-v3/` (normally
`~/.local/share/affinity-v3/`). Wine and its dependencies may require a large
first build; see upstream's binary-cache instructions if needed.

### Workstation audio, Bluetooth microphones, and MIDI

NixOS workstations enable Bluetooth with Blueman for pairing, PipeWire's
ALSA/PulseAudio/JACK interfaces, and RTKit. WirePlumber switches compatible
Bluetooth headsets to HFP/HSP microphone mode when an app starts recording;
mSBC wideband speech is enabled when supported. Pair/trust the headset using
your desktop Bluetooth settings or `blueman-manager`, then select its microphone
in the recording app. Headset mode can reduce playback quality. For low-latency
recording, prefer a wired/USB audio interface over Bluetooth.

In native Linux REAPER select **JACK** (through PipeWire) or **ALSA**, not ASIO.
Windows ASIO drivers and WineASIO are not installed. Tune the buffer in the DAW
for your interface; no globally forced low-latency buffer is imposed.
ALSA sequencer/raw MIDI modules are loaded, and WirePlumber bridges ALSA MIDI
ports into PipeWire, including JACK clients. USB class-compliant audio/MIDI
devices use Linux's built-in drivers; vendor-only Windows drivers are not
supported. Enable MIDI inputs in REAPER's preferences. `qpwgraph` provides
routing, and `aconnect -l` / `aseqdump -l` (from `alsa-utils`) list MIDI ports.
Rebuild NixOS and reboot to load the modules and restart the audio session.
Standalone Home Manager cannot configure system drivers or Bluetooth; configure
these on the host OS. Server roles do not receive these additions.

### Radio workflow and RTL-SDR

The radio workflow installs GNU Radio (`gnuradio`), SDR++ (`sdrpp`), Gqrx (`gqrx`),
and qdmr (`qdmr`); Chirp is provided as a Flatpak. NixOS workstations also enable
`hardware.rtl-sdr`: this installs the
RTL-SDR library/tools and USB udev rules, and blacklists conflicting DVB TV
kernel modules. The managed user joins `plugdev` for unprivileged device access.
Rebuild NixOS, reboot, and reconnect the dongle, then run `rtl_test` (Ctrl+C to
stop) before choosing an RTL-SDR source in SDR++ or Gqrx. Do not run receivers as
root; only one program can access the dongle at a time.

Standalone Home Manager installs the GUIs only; configure RTL-SDR permissions
and the conflicting DVB driver on the host OS. This setup dedicates compatible
dongles to SDR rather than DVB TV reception. To opt out on a NixOS workstation,
set `hardware.rtl-sdr.enable = false;`. Server roles do not enable the device
support by default.

### Personal video and image editing

The `personal` profile installs GIMP (`gimp`). DaVinci Resolve requires
compatible GPU drivers and OpenCL support.
GIMP receives the pinned [PhotoGIMP](https://github.com/Diolinux/PhotoGIMP)
Photoshop-style layout, shortcuts, splash screen, and UI adjustments.
Close GIMP before the first activation. Existing settings are backed up beside
`~/.config/GIMP/<major.minor>` in a `*.photogimp-backup.*` directory before the
patch is copied. Settings remain writable, and a
`.sauce-photogimp-initialized` marker prevents later activations from overwriting
customizations. Custom XDG config locations are respected. The patch is only
applied when the photo workflow selects GIMP on a non-server role.
To restore old settings, close GIMP, move the patched version directory aside,
and restore its backup; remove `"gimp"` from the selection first to prevent
reapplying the patch on activation.

### Bitwarden system authentication

The default Bitwarden package uses a grayscale Linux tray icon in all desktops,
including Sway and COSMIC. Its launcher and window icons stay unchanged.
`packages/bitwarden.nix` builds a separate tray asset; a custom
`sauce.packageOverrides.bitwarden` takes precedence. Rebuild and fully quit/reopen
Bitwarden to pick up the change. This source override may require a local
Bitwarden build instead of using the upstream binary cache.

On NixOS, selecting `"bitwarden"` in `sauce.guiApps` (as the `personal` profile
does) also installs the desktop package system-wide so its bundled polkit policy
is registered, and enables polkit. The configured Sway session starts a polkit
agent; KDE, GNOME, and COSMIC provide their own. Custom sessions need a
running authentication agent. No passwordless polkit authorization is added.
Standalone Home Manager users must arrange the system policy and agent themselves.

After rebuilding, follow [Bitwarden's biometric setup](https://bitwarden.com/help/biometrics/):

1. Open Bitwarden, log in, and go to **File → Settings → Security**.
2. Enable **Unlock with system authentication** and confirm the authentication prompt.
3. For browser unlock, enable **Allow browser integration** in the desktop app
   if required by your version. Keep it running and logged in, then enable
   **Settings → Account security → Unlock with biometrics** in the extension.
   Allow communication with native applications when prompted. Chromium browsers
   may also need **Allow access to file URLs** in their extension settings.

These settings are per-account and must be enabled interactively; vault state
and credentials are not managed by Nix. After an app restart, first unlock with
your master password or PIN before using system authentication. For actual
fingerprint authentication on supported hardware, set `sauce.system.fingerprint = true;`
in the machine-local NixOS configuration and enroll with `fprintd-enroll`.
Otherwise polkit uses the system's configured authentication method.

The `headless/ssh` profile enables SSH access only. The `headless/devbox` profile
independently enables Firewalld and Caddy-proxied browser-based code-server;
Firewalld drops inbound traffic by default and permits only the selected services
on `tailscale0`. Configure Tailscale ACLs too. Caddy binds to the resolved
Tailscale IPv4 address and proxies to code-server on loopback. Code-server
requires a password supplied through a runtime environment file. SSH accepts
keys only, with root login and keyboard-interactive authentication disabled.
JetBrains Gateway starts its backend over SSH. VS Code Tunnel is omitted because
its Microsoft relay is not tailnet-only.

Devbox machines with `"lmstudio"` in `sauce.guiApps` also expose
`http://<tailscale-ip>:1234` through Caddy, forwarding all API paths (including
`/v1` and `/api/v1`) to `127.0.0.1:1234` with streaming enabled. Start LM Studio's
local server on port 1234 and leave **Serve on Local Network** disabled so it
binds only to loopback. Caddy does not start LM Studio or add API authentication;
restrict port 1234 with Tailscale ACLs and enable LM Studio API authentication if
needed. Set `sauce.system.devbox.lmstudio.enable = false;` to disable the proxy,
or `true` to opt in on another devbox machine. Pi continues using the
local loopback URL by default; remote clients use `http://<tailscale-ip>:1234/v1`
for the OpenAI-compatible API. Rebuild the NixOS configuration to apply.

### Provision SSH and devbox access before switching

Enroll Tailscale and restrict SSH and HTTP with tailnet ACLs. Provision your
SSH **public** key through the console or an existing administrative session:

```sh
sudo install -d -m 0755 /etc/ssh/sauce-authorized-keys
sudo install -m 0644 /path/to/your-key.pub /etc/ssh/sauce-authorized-keys/codyconfer
```

The directory and public key must be readable by the login user, but writable only
by root. `sauce.system.ssh.authorizedKeysFile` changes this runtime location
(`%u` expands to the login name). Existing `~/.ssh/authorized_keys` and declarative
NixOS public keys remain supported. Keep console access until SSH is tested.

Provision `/run/secrets/sauce-code-server.env` with mode `0600`, owned by root,
using your secret manager. Set `HASHED_PASSWORD` to a code-server-compatible
Argon2 hash (preferred), or `PASSWORD` to a strong password, using systemd
EnvironmentFile syntax. Set only one. The file is mandatory and an empty file
fails closed. `sauce.system.devbox.codeServerEnvironmentFile` changes its path.
Never use a Nix path literal or `builtins.readFile` for credentials. `/run` is
volatile: arrange provisioning on every boot before the service starts.

Restart `code-server.service` after provisioning. Test that unauthenticated
browser access reaches the login page and that SSH is unreachable from outside
the tailnet. SSH password login remains disabled. The HTTP connection relies on WireGuard's
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
