# .sauce, declaratively

A separate, self-contained Linux port using **NixOS + Home Manager**. The original
chezmoi setup is unchanged by this port. Nothing here installs Nix, repartitions a
disk, switches your running system, or imports configuration from outside `nix/`.

Machine roles (`workstation`, `mobile`, `server`) are independent of desktop
profiles (`kde`, `sway`, `hyprland`, `cosmic`, `lxqt`, `gnome`) and capability profiles such as `devbox`, `gaming`,
`hypervisor`, `remote`, `personal`, and `work`. Combine
the role and capabilities needed by each host. Desktop examples target
`x86_64-linux`; headless Home Manager configurations are also evaluated for
`aarch64-linux`. Individual proprietary packages may not support ARM.

## Layout

- `flake.nix`, `flake.lock`: pinned dependencies, NixOS/Home Manager outputs and checks.
- `hosts/sauce.nix`: **example** NixOS host, not your hardware configuration.
- `hosts/testvm.nix`: disposable GNOME/QEMU VM host for desktop testing.
- `hosts/home.nix`: standalone Home Manager example.
- `profiles/`: machine-role, desktop (`kde`, `sway`, `hyprland`, `cosmic`, `lxqt`, `gnome`), and capability profile defaults; combine them per host.
- `modules/`: system services, packages, shell, editor, desktop, Flatpak and Pi.
- `lib/catalog.nix`: selection names and their Nixpkgs/Flathub mappings.
- `dotfiles/`, `assets/`: independent copies of the original configuration and themes.

The copies do not automatically follow future edits to `home/` or `assets/`.

## NixOS

Requires Nix with `nix-command` and `flakes` enabled. From this directory:

1. Replace the placeholder filesystem labels and bootloader in `hosts/sauce.nix`
   with your generated `hardware-configuration.nix` and machine-specific settings.
   Do **not** use the sample disk layout to install an existing machine unchanged.
   For LUKS + ext4, configure `boot.initrd.luks.devices.<name>.device` with the
   actual LUKS UUID and set root to `/dev/mapper/<name>` with `fsType = "ext4"`.
   The host file shows this alongside a LUKS + Btrfs alternative. Keep `/boot`
   on its separate EFI partition and retain generated initrd storage modules.
   These are commented examples only; no disk UUIDs or subvolumes are guessed.
2. Change the hostname, `sauce.system.user`, home directory, locale and timezone.
   The account has **no usable password by default**. Set
   `users.users.<name>.hashedPasswordFile` to a securely provisioned runtime file,
   or configure another secure authentication method before deploying.
3. Review the selections and privileged services below. Secure Boot support is
   provided by Lanzaboote (pinned as a flake input) for the systemd-boot workflow.
   It is opt-in: after provisioning and enrolling your own Secure Boot keys with
   `sbctl` while following the Lanzaboote installation guide, configure
   `boot.lanzaboote.enable = true;` and
   `boot.lanzaboote.pkiBundle = "/var/lib/sb";` in the host module. Do not enable
   it until keys are provisioned and the firmware boot path is understood; keep
   a recovery path available. NixOS cannot automatically enroll keys in firmware.
4. Build first; switch only when you intend to deploy:

   ```sh
   cd ~/.sauce/nix
   nix flake check --no-build --all-systems "path:$PWD"
   sudo nixos-rebuild build --flake "path:$PWD#sauce"
   # After reviewing the build and fixing hardware/account settings:
   sudo nixos-rebuild switch --flake "path:$PWD#sauce"
   ```

`#sauce` is the **flake output name**, independent of `networking.hostName`.
Changing the hostname alone does not rename that output. Set `SAUCE_NIX_HOST=sauce`
if using the `sauce-rebuild` helper after choosing a different hostname.
Keep `system.stateVersion` and `homeStateVersion` at their initial deployment
versions; do not bump them as part of routine package updates.

### Disposable VM test host

The `testvm` output is separate from the example machine configuration and uses
GNOME by default. Build and launch it without switching the host system:

```sh
nixos-rebuild build-vm --flake "path:$PWD#testvm"
./result/bin/run-*-vm
```

The VM uses 4 GiB RAM and 4 CPUs, and auto-logs into its passwordless `testvm`
account. It has no host disk, LUKS, or Secure Boot configuration; do not deploy
this output to a physical machine. To try another desktop profile, change the
`profiles/gnome.nix` import in `hosts/testvm.nix` to the profile you want and
rebuild. The VM is a boot/session smoke test, not proof of physical hardware
compatibility.

To use the module in another flake, import `inputs.sauce.nixosModules.default`,
a machine-role profile, and any capability profiles (or set `sauce.enable = true`
yourself). The module includes Home Manager integration. `lib.mkSystem { system = "x86_64-linux"; modules = [ ... ]; }`
is also exported. Set `nixpkgs.config.allowUnfree = true` when constructing your
own standalone package set; the examples already allow it.

## Home Manager on an existing Linux distribution

This manages **user configuration only**. It cannot configure the host kernel,
GPU driver, display manager, Flatpak system integration, Docker/libvirt daemons,
portals/PAM, Ollama service, or other privileged services.

1. Change **both** `home.username` and `home.homeDirectory` in `hosts/home.nix`.
2. Import a machine role and any add-on profiles you want, for example
   `../profiles/mobile.nix` plus `../profiles/devbox.nix`. Use
   `../profiles/server.nix` for a headless server. There is no implicit
   hardware/WSL detection.
3. With Home Manager installed:

   ```sh
   cd ~/.sauce/nix
   home-manager build --flake "path:$PWD#sauce"
   # Back up existing dotfiles first. -b creates backups for conflicting files.
   home-manager switch -b before-nix --flake "path:$PWD#sauce"
   ```

Alternatively run the Home Manager CLI with `nix run github:nix-community/home-manager -- ...`.
The generated configuration itself uses the locked Home Manager input.
Do not let chezmoi and Home Manager manage the same destination files concurrently.
Use one manager per account, or explicitly exclude the overlapping files.

An external standalone configuration can import
`inputs.sauce.homeManagerModules.default`, enable `sauce`, and supply the usual
`home.username`, `home.homeDirectory`, and `home.stateVersion` options.

## Selection and overrides

Add overrides in your host module; profile lists are `mkDefault`, so ordinary
assignments replace them (use `lib.mkAfter` to append):

```nix
{ pkgs, ... }: {
  sauce = {
    enable = true;
    headless = false;
    tools = [ "go" "nvim" "nvm" "pi" "tmux" ];
    guiApps = [ "sway" "alacritty" "firefox" ];
    emulators = [ ];
    flatpaks = [ "signal" "obs-studio" ];
    media = [ "vlc" "ffmpeg" ];
    extras = true;
    netTools = true;
    extraPackages = [ pkgs.ripgrep ];
    sway = { latitude = "40.6"; longitude = "-105.1"; extraPackages = [ ]; };
  };
}
```

All selection keys are listed in `lib/catalog.nix` and validated as enums.
`headless = true` suppresses GUI/emulator/Flatpak packages and desktop files even
if lists were supplied; media is reduced to FFmpeg. The server role selects this.
Machine-role, desktop, and capability profile values are defaults, so host
assignments can replace them. Select exactly one desktop profile on NixOS:
`profiles/kde.nix` enables KDE Plasma, `profiles/sway.nix` enables Sway,
`profiles/hyprland.nix` enables Hyprland as a UWSM-managed session,
`profiles/cosmic.nix` enables COSMIC, `profiles/lxqt.nix` enables LXQt with X11,
and `profiles/gnome.nix` enables GNOME with GDM. The workstation role only
supplies workstation selections; it no longer chooses a desktop. Ly provides
session login for the example's Sway profile. The Hyprland profile enables the
compositor, UWSM session, and portals but does not generate a Hyprland user config;
manage that separately. Standalone Home Manager cannot enable host display-manager
or compositor services.
Optional language servers follow the selected language runtimes.

`gcx`, `loglit`, and Claude **desktop** have no package mapping in this snapshot.
Selecting one requires an audited package override, for example:

```nix
{ pkgs, ... }: {
  sauce.tools = [ "gcx" ];
  sauce.packageOverrides.gcx = pkgs.callPackage ./packages/gcx.nix { };
}
```

`packageOverrides` can also replace mapped packages by selection name.
For `nvim`, provide an **unwrapped** Neovim package: Home Manager wraps it with
the configured plugins. `sauce.extraPackages` accepts arbitrary additional packages.

## What is ported

- CLI/GUI/media/emulator selections, essential tools, monitoring and network tools.
- Bash/Zsh functions, banner, completion, autosuggestions, highlighting, Oh My Posh,
  local `*.dev`, `*.ops`, `*.yggdrasil`, and `*.local` shell fragments; tmux and GPG agent config.
- Neovim colors, keymaps, completion, Git/diff/log plugins, Tree-sitter and language
  servers. Plugins/parsers are pinned Nix packages, not Lazy/Mason downloads.
- Sway, Waybar/weather, terminals, mako, clipboard, monitor configuration,
  lock/power/askpass helpers, UWSM environment, GTK/wlr portals and fonts.
- NixOS NetworkManager, console font, PipeWire, optional NVIDIA/fingerprint,
  fwupd, power profiles, Tailscale, Resilio, ClamAV, k3s, Ollama, Docker,
  libvirt/virt-manager, Steam and 1Password integration.
- Custom Arch/Grafana Plymouth themes with store-correct image paths.
- Selected Flatpaks and non-secret Pi/MCP/web-search settings.

System options live under `sauce.system` (NixOS only):

| Option | Default |
| --- | --- |
| `user`, `homeDirectory`, `homeStateVersion` | `sauce`, `/home/<user>`, `25.11` |
| `tailscale`, `rslsync`, `nvidia`, `fingerprint` | `false` |
| `fwupd`, `powerManagement`, `displayManager`, `nixLd` | `true` |
| `wifiPowerSave` | `false` |
| `consoleFont` | `ter-124n` |
| `plymouthTheme` | `none` (example host selects `arch`) |
| `clamav.enable`, `clamav.daemon` | `true`, `false` |
| `clamav.scanPaths`, `clamav.schedule` | `[ "/home" ]`, `Sun *-*-* 03:00:00` |
| `k3s.enable` | whether `k3s` is selected |

Use normal NixOS options for deeper service, hardware and security configuration.
ClamAV scans are report-only: exit status 1 means findings, not automatic deletion.
Docker group membership is effectively root-equivalent; the `devbox` profile
selects Docker and enables its NixOS daemon. The workstation role includes desktop
and media selections. Add `gaming` for Steam, Wine, Lutris, and RetroArch; add
`hypervisor` for QEMU/libvirt; add `devbox` for local SDKs, Docker, and k3s.
Selecting k3s starts a server; configure cluster details via `services.k3s` before
using it outside a local test machine. The `remote` profile intentionally enables
no inbound services.

## Deliberate differences and external state

- The `nvm` selection uses **fnm**; its shell initialization supports per-directory
  Node versions. Existing nvm-installed versions are not migrated. Nix `nodejs` is
  also present for tools such as Pi. Rustup/pyenv language versions remain user
  state; `nix-ld` helps upstream binaries on NixOS but cannot guarantee every
  downloaded runtime or native extension works. For fully pinned language
  environments, use project dev shells.
- Fuzzel/cliphist replace zofi; swayr replaces exposway/swaycycle;
  brightnessctl replaces lumactl/swaydim; grimshot replaces sway-screenshot;
  Kooha is native. Dim is a fixed 15% brightness action, not the old toggle.
  These retain the workflow, not every source-built utility's exact behavior.
- Flatpaks install/update through `sauce-flatpaks` and a user oneshot service at
  login/activation. This requires working Flatpak host integration and network.
  Synchronization is **additive**: removing a selection does not uninstall its app.
  Review/remove unused apps manually with `flatpak uninstall --user <ID>`.
  Flatpak versions are Flathub state, not pinned by `flake.lock`.
- Run `sauce-pi-extensions` explicitly to install/update selected Pi extensions;
  activation does not run `npm` or Pi installers. Extensions are external mutable
  state. `sauce.pi.extensions`, `sauce.pi.mcp`, and `sauce.pi.lmstudioUrl` configure
  this integration; Ollama/LM Studio extensions are added when those tools are selected.
- Authentication, Tailscale enrollment, fingerprints, password-manager sign-in,
  Resilio peers/shares, Fleet enrollment, cloud credentials and hardware-specific
  NVIDIA PRIME settings are not automated. Fleet enrollment is not ported; use a
  separately audited service with runtime credentials if needed.
- The imperative install/update dispatcher, package-manager setup, AUR helpers,
  driver autodetection, AC-triggered Resilio rules and machine-specific logind
  tuning are not replayed. Configure these explicitly in a host module as needed.
- Nix configuration and generated files are **public in the Nix store**. Never
  put tokens/passwords in `sauce.pi.mcp`, host modules, or any copied config.
  Use runtime environment files or a secrets manager. Existing `.pi` files may
  conflict with generated read-only files; back them up before switching.
- Azure CLI alone comes from the separately locked `nixpkgs-stable` input:
  the main snapshot's fabric/invoke dependency is broken. No blanket `allowBroken`
  or insecure-package exemption is enabled.

## Updates and checks

```sh
cd ~/.sauce/nix
nix flake update
nix flake check --no-build --all-systems "path:$PWD"
nix build "path:$PWD#checks.x86_64-linux.configuration"
# After reviewing the lock diff, build and switch as above.
```

`sauce-rebuild` switches the current system/home without updating the lock.
`SAUCE_NIX_FLAKE`, `SAUCE_NIX_HOST`, and `SAUCE_NIX_HOME` override its path/output.
The shell's update helper delegates to it rather than running imperative installers.
Use `nix fmt` for Nix formatting.

Checks evaluate workstation, mobile, and server Home Manager generations and the
example NixOS system. The lightweight `configuration` check asserts role selection,
headless exclusions, and Sway adaptations. A full `nix flake check` **builds the
selected software**, potentially many gigabytes; `--no-build` evaluates without
installing or activating anything. Evaluation is not proof of runtime correctness
on your hardware.
