# android-studio-nix

A Nix flake packaging [Android Studio](https://developer.android.com/studio) (stable channel), auto-updated daily.

It reuses nixpkgs' own Android Studio FHS wrapper
(`pkgs/applications/editors/android-studio/common.nix`) and only swaps in the
`{ version, url, sha256Hash }` pinned in `pkgs/android-studio/sources.json`, so
you get upstream's exact runtime environment on the latest stable release.

## Outputs

- `packages.x86_64-linux.default` / `.android-studio`
- `apps.default` (`nix run`)
- `overlays.default` (adds `pkgs.android-studio`)

Only `x86_64-linux` is supported — Android Studio ships as a Linux tarball run
inside an FHS environment.

## Usage

### Flake input

```nix
inputs.android-studio.url = "github:stslex/android-studio-nix";
inputs.android-studio.inputs.nixpkgs.follows = "nixpkgs";
```

### NixOS (overlay)

```nix
{ inputs, pkgs, lib, ... }:
{
  nixpkgs.overlays = [ inputs.android-studio.overlays.default ];

  # Android Studio is unfree.
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "android-studio" ];

  environment.systemPackages = [ pkgs.android-studio ];
}
```

### home-manager (with `useGlobalPkgs`)

With `home-manager.useGlobalPkgs = true` the overlay above won't apply to your
home config, so consume the package output directly:

```nix
{ inputs, ... }:
{
  home.packages = [ inputs.android-studio.packages.x86_64-linux.default ];
}
```

### Ad-hoc

```sh
nix run github:stslex/android-studio-nix
```

## Updating

```sh
./scripts/update.sh            # bump to the latest stable release
./scripts/update.sh 2026.1.2.10  # pin a specific version
```

The script rewrites `pkgs/android-studio/sources.json` from JetBrains'
[release feed](https://jb.gg/android-studio-releases-list.json).

## Auto-updates

A GitHub Actions workflow (`.github/workflows/update.yml`) runs daily at
**03:00 UTC**. On a new stable release it:

1. bumps `sources.json`,
2. refreshes the `nixpkgs` input (`nix flake update nixpkgs`) to pick up wrapper
   and runtime-dep changes,
3. builds `.#android-studio` to verify, then
4. commits and pushes.

This requires **Settings → Actions → General → Workflow permissions → Read and
write**. Trigger it manually with:

```sh
gh workflow run update.yml            # latest stable
gh workflow run update.yml -f version=2026.1.2.10  # pin
```

## Passthru

The package exposes the passthru attributes from nixpkgs' `common.nix` for
further wrapping:

- `.unwrapped` — the raw, unwrapped Android Studio derivation
- `.withSdk` — `androidSdk: …` to bundle a specific Android SDK
- `.full` — Android Studio with the default `androidenv` SDK

## License

The packaging in this repository is licensed under the [MIT License](./LICENSE).

Android Studio itself is not MIT-licensed: it is distributed under the
[Android Software Development Kit License](https://developer.android.com/studio/terms)
and includes proprietary components. Installing it via this flake is subject to
that license (hence `allowUnfree`).

Thanks to the nixpkgs Android maintainers, whose `common.nix` FHS wrapper this
flake reuses wholesale.
