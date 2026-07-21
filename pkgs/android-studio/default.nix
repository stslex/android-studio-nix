{
  lib,
  callPackage,
  makeFontsConf,
  buildFHSEnv,
  path, # nixpkgs source == pkgs.path (auto-filled by callPackage) — intentional, do not "fix"
  # true for tiling WMs (niri/sway/hyprland): exports _JAVA_AWT_WM_NONREPARENTING=1
  tiling_wm ? true,
}:
let
  sources = lib.importJSON ./sources.json;

  # Reuse nixpkgs' FHS wrapper, swapping only version/url/hash.
  common = import "${path}/pkgs/applications/editors/android-studio/common.nix" {
    channel = "stable";
    pname = "android-studio";
    inherit (sources) version url;
    sha256Hash = sources.sha256;
  };
in
callPackage common {
  fontsConf = makeFontsConf { fontDirectories = [ ]; };
  inherit buildFHSEnv tiling_wm;
}
