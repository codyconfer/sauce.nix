# Additional COSMIC applications

`modules/home.nix` installs these packages when COSMIC is selected on a
non-server role. This only installs applications and applet desktop entries;
it does not modify panel configuration or automatically enable applets.

| Upstream repository | Local attribute | Installed executable |
| --- | --- | --- |
| mariinkys/cedilla | cedilla | cedilla |
| mariinkys/starrydex | starrydex | starrydex |
| cosmic-utils/clipboard-manager | clipboard-manager | cosmic-ext-applet-clipboard-manager |
| Ebbo/cosmic-applet-music-player | cosmic-applet-music-player | cosmic-ext-applet-music-player |
| AceMythos/cosmic-power-monitor | cosmic-power-monitor | cosmic-power-monitor |
| nalladev/cosmic-ext-applet-eyedropper | cosmic-ext-applet-eyedropper | cosmic-ext-applet-eyedropper |

The other two requested projects use `pkgs.forecast` (cosmic-utils/forecast)
and `pkgs.cosmic-ext-applet-privacy-indicator`
(D-Brox/cosmic-ext-applet-privacy-indicator) from the existing locked nixpkgs.

Sources and Cargo dependency trees are fixed by revision and SHA-256 in
`sources.json`. No additional flake inputs or Rust toolchain changes are
required. The libcosmic setup hook supplies graphics libraries and wraps
applications with their data/icon paths.

## Verification and updates

From the repository root, evaluate the package-selection assertions without
building an entire desktop closure:

```sh
nix build --no-link path:.#checks.x86_64-linux.configuration
```

To build a particular package (replace `cedilla` as appropriate):

```sh
nix build --no-link --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  in (import ./packages/cosmic { inherit pkgs; }).cedilla
'
```

For updates, inspect the selected upstream commit and its Cargo.lock, update
`rev`, `version`, and source `hash`, then recompute `cargoHash` using the Nix
fixed-output hash mismatch workflow. Never leave placeholder hashes. Build the
changed package, check the installed executable and desktop/icon/metainfo
paths, and rerun the configuration check. These are independent libcosmic
applications; a successful configuration evaluation alone does not establish
that each upstream revision compiles or works in a live COSMIC session.

Cupola and Compass were removed because their upstream tests blocked system
updates. Camera was also removed. The package set now contains six local
applications plus the two
nixpkgs packages listed above.

## Initial verification (2026-11-04)

- Configuration assertions pass, including installation of all 11 projects and
  their absence from server/mobile selections; formatting and LSP checks pass.
- All nine local package derivations evaluate for x86_64-linux and
  aarch64-linux. Source fetching and all nine Cargo vendor builds succeed.
- Each local package's asset-install phase was run against its pinned source;
  desktop entries, matching icons, and metainfo files were installed correctly.
- Full binary builds were attempted, but stopped during lengthy compilation
  (Cedilla and Power Monitor reached Rust compilation). Camera was also built
  directly with a 180-second limit after adding its libcamera/libudev build
  dependencies; it reached Rust compilation before timing out. A separate
  pkg-config check using Camera's exact build inputs passes for libcamera,
  libudev, dav1d, gstreamer-1.0, and gstreamer-app-1.0. No complete binary build
  or live COSMIC runtime test is claimed; complete build phases remain
  unverified.
- The broader `checks.x86_64-linux.nixos-configuration` check fails because it
  expects `/run/secrets/sauce-code-server.env`, while the module supplies
  `/var/lib/sauce/secrets/code-server.env`. The identical failure was reproduced
  on unchanged HEAD (`b806cdc01877ecc6748dc4d91c55c506ee8ba301`); it is unrelated
  to these additions and was left unchanged.
