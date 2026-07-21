{
  description = "Nix flake packaging Android Studio (stable channel), auto-updated";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    # AS builds only on x86_64-linux (FHS + linux tarball) -> not eachDefaultSystem
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        android-studio = pkgs.callPackage ./pkgs/android-studio { };
      in
      {
        packages = {
          default = android-studio;
          android-studio = android-studio;
        };
        apps.default = {
          type = "app";
          program = "${android-studio}/bin/android-studio";
        };
      }
    )
    // {
      overlays.default = final: _prev: {
        android-studio = final.callPackage ./pkgs/android-studio { };
      };
    };
}
