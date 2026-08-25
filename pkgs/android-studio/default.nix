{
  lib,
  callPackage,
  makeFontsConf,
  buildFHSEnv,
  stdenv,
  path, # nixpkgs source == pkgs.path (auto-filled by callPackage) — intentional, do not "fix"
  # true for tiling WMs (niri/sway/hyprland): exports _JAVA_AWT_WM_NONREPARENTING=1
  tiling_wm ? true,
}:
let
  sources = lib.importJSON ./sources.json;

  upstream = callPackage "${path}/pkgs/applications/editors/android-studio/default.nix" {
    inherit tiling_wm;
  };

  # Reuse nixpkgs' Linux FHS wrapper, swapping only version/url/hash.
  linux = import "${path}/pkgs/applications/editors/android-studio/linux.nix" {
    channel = "stable";
    pname = "android-studio";
    inherit (sources) version;
    sources.${stdenv.hostPlatform.system} = {
      inherit (sources) url;
      sha256Hash = sources.sha256;
    };
    inherit (upstream.stable) meta;
  };
in
callPackage linux {
  fontsConf = makeFontsConf { fontDirectories = [ ]; };
  inherit buildFHSEnv tiling_wm;
}
