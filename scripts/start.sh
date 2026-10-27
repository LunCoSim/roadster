#!/usr/bin/env bash
set -euo pipefail
roadster_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
roadster_checkout="$roadster_root/../../luncosim-workspace/main"
roadster_bin="${LUNCOSIM_BIN:-}"
if [[ -z "$roadster_bin" ]]; then
    roadster_bin="$(command -v luncosim || true)"
fi
if [[ -z "$roadster_bin" && -x "$roadster_checkout/target/debug/luncosim" ]]; then
    roadster_bin="$roadster_checkout/target/debug/luncosim"
fi
if [[ -z "$roadster_bin" ]]; then
    echo 'Set LUNCOSIM_BIN to your production luncosim executable.' >&2
    exit 1
fi
mkdir -p "$roadster_root/.scratch"
export TMPDIR="$roadster_root/.scratch"
if [[ -z "${LUNCO_ASSET_ROOT:-}" && -d "$roadster_checkout/assets" ]]; then
    export LUNCO_ASSET_ROOT="$roadster_checkout/assets"
fi
roadster_scene="roadster_cinematic"
if (($#)) && [[ "$1" != --* ]]; then roadster_scene="$1"; shift; fi
roadster_api=(--api 4198)
for roadster_arg in "$@"; do
    if [[ "$roadster_arg" == --api ]]; then roadster_api=(); break; fi
done
if [[ ! "$roadster_scene" =~ ^roadster_[a-z0-9_]+$ || ! -f "$roadster_root/scenes/$roadster_scene.usda" ]]; then
    echo 'Choose an existing roadster_*.usda scene under scenes/ (without the extension).' >&2
    exit 1
fi
exec "$roadster_bin" --no-vsync --no-throttle "${roadster_api[@]}" --scene "$roadster_root/scenes/$roadster_scene.usda" "$@"
