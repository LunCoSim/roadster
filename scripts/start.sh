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
if [[ -z "$roadster_bin" && -x "$roadster_root/.scratch/luncosim" ]]; then
    roadster_bin="$roadster_root/.scratch/luncosim"
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
if [[ -z "${LUNCO_ASSET_ROOT:-}" && -d "$roadster_checkout/assets" ]]; then
    export LUNCO_ASSET_ROOT="$roadster_checkout/assets"
fi
export LUNCO_ASSET_ROOT="$(python3 "$roadster_root/scripts/prepare_runtime_assets.py")"
roadster_scene="${1:-roadster_skill_course}"
if (($#)); then shift; fi
case "$roadster_scene" in
    roadster_track|roadster_thrust|roadster_rocket|roadster_launch|roadster_motor_launch|roadster_wall|roadster_wall_check|roadster_coast_check|roadster_ramp|roadster_skill_course|roadster_ramp_check|roadster_refill_check|roadster_earth_check) ;;
    *) echo 'Scene must be roadster_track, roadster_thrust, roadster_rocket, roadster_launch roadster_motor_launch, roadster_wall or roadster_wall_check.' >&2; exit 1 ;;
esac
exec "$roadster_bin" --no-vsync --no-throttle --scene "$roadster_root/scenes/$roadster_scene.usda" "$@"
