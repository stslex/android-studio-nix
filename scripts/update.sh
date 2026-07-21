#!/usr/bin/env bash
# Update pkgs/android-studio/sources.json to the latest stable Android Studio,
# or to a specific version passed as $1 (e.g. ./scripts/update.sh 2026.1.2.10).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sources_file="$here/../pkgs/android-studio/sources.json"
feed="https://jb.gg/android-studio-releases-list.json"
pin="${1:-}"

releases="$(curl -fsSL "$feed")"

selected="$(jq -c --arg pin "$pin" '
  [ .content.item[]
    | select( if $pin == ""
              then (.channel == "Release" or .channel == "Patch")
              else (.version == $pin) end ) ]
  | sort_by(.version | split(".") | map(tonumber))
  | last
' <<<"$releases")"

if [[ "$selected" == "null" || -z "$selected" ]]; then
  echo "error: no release found for '${pin:-latest stable}'" >&2
  exit 1
fi

version="$(jq -r '.version' <<<"$selected")"
name="$(jq -r '.name' <<<"$selected")"
url="$(jq -r '[.download[] | select(.link | endswith("-linux.tar.gz"))][0].link' <<<"$selected")"
checksum="$(jq -r '[.download[] | select(.link | endswith("-linux.tar.gz"))][0].checksum' <<<"$selected")"

if [[ "$url" != https://edgedl.me.gvt1.com/android/studio/* ]]; then
  echo "error: unexpected download URL: $url" >&2
  exit 1
fi

sri="$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$checksum")"
current="$(jq -r '.version // ""' "$sources_file" 2>/dev/null || echo "")"

jq -n --arg v "$version" --arg n "$name" --arg u "$url" --arg s "$sri" \
  '{version:$v, name:$n, url:$u, sha256:$s}' >"$sources_file"

if [[ "$version" == "$current" ]]; then
  echo "already up to date at $version ($name)"
else
  echo "updated: ${current:-none} -> $version ($name)"
fi
