#!/usr/bin/env bash
set -euo pipefail
roadster_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
roadster_checkout="$roadster_root/../../luncosim-workspace/main"
roadster_bin="${LUNCOSIM_BIN:-}"
# Reuse the locally validated development runtime when present. An explicit
# LUNCOSIM_BIN remains authoritative; portable bundles can use an installed app.
if [[ -z "$roadster_bin" && -x "$roadster_root/.scratch/control-target/debug/luncosim" ]]; then
    roadster_bin="$roadster_root/.scratch/control-target/debug/luncosim"
fi
if [[ -z "$roadster_bin" && -x "$roadster_root/.scratch/luncosim" ]]; then
    roadster_bin="$roadster_root/.scratch/luncosim"
fi
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
if [[ -z "${LUNCOSIM_CONFIG:-}" ]]; then
    export LUNCOSIM_CONFIG="$roadster_root/.scratch/session-config"
    mkdir -p "$LUNCOSIM_CONFIG"
    cp "$roadster_root/config/input-bindings.json" "$LUNCOSIM_CONFIG/settings.json"
fi
# A local development binary can carry a matching shared-asset companion.
# Mixing an older runtime with a newer checkout's UI manifest is rejected.
if [[ -z "${LUNCO_ASSET_ROOT:-}" && "$roadster_bin" -ef "$roadster_root/.scratch/luncosim" && -d "$roadster_root/.scratch/luncosim-assets" ]]; then
    export LUNCO_ASSET_ROOT="$roadster_root/.scratch/luncosim-assets"
elif [[ -z "${LUNCO_ASSET_ROOT:-}" && -d "$roadster_checkout/assets" ]]; then
    export LUNCO_ASSET_ROOT="$roadster_checkout/assets"
fi
export LUNCO_ASSET_ROOT="$(python3 "$roadster_root/scripts/prepare_runtime_assets.py")"
roadster_scene="${1:-roadster_skill_course}"
if (($#)); then shift; fi
if [[ ! "$roadster_scene" =~ ^roadster_[a-z0-9_]+$ || ! -f "$roadster_root/scenes/$roadster_scene.usda" ]]; then
    echo 'Choose an existing roadster_*.usda scene under scenes/ (without the extension).' >&2
    exit 1
fi
exec "$roadster_bin" --no-vsync --no-throttle --scene "$roadster_root/scenes/$roadster_scene.usda" "$@"
