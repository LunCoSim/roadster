# Ramp entry contact repair — 2026-10-19

## Reproduction and cause

The previous short practice check approached from only 10 m away. It passed
without covering faster course-like entry. New native actuator-only fixtures
start 80 m before the ramp and approach at 11, 25 and 40 m/s with fans on,
plus 25 m/s with fans off. They retain the authored mass, tire law, suspension,
compound body colliders, ramp profile and contact materials.

At 40 m/s, the old runtime (`17cad2934`) lost **26.0314 m/s in one 1/60 s tick**.
The contact diagnostics recorded a **76.245 kN s** chassis normal impulse with
zero reported penetration. Disabling only the battery-floor collider eliminated
the stop; disabling the nose did not. These were diagnostic ablations, not the
shipped vehicle configuration. [Before evidence](../results/ramp-entry-before.json).

The exact USD triangle-mesh cooking path omitted the edge correction already
used by streamed terrain. The correction uses Avian's maintained
[`TrimeshFlags::FIX_INTERNAL_EDGES`](https://docs.rs/avian3d/0.7.0/avian3d/collision/collider/struct.TrimeshFlags.html):
shared tessellation edges do not represent physical road obstacles.
The shared `lunco-usd-avian-reader` now supplies that flag for exact Mesh and
finite Plane geometry. Native geometry failures retain their typed errors.
There is no new vehicle-specific Rust, contact bypass, pose writer, motor boost,
ride-height adjustment or ramp speed clamp.

## Production results

Core fix: **`130fc4e27`**, branch `roadster-aux-controls` (local, not integrated
into main or pushed). The Mesh/Plane regression failed before the correction
and passed afterward. All four body collision parts remain enabled in every
accepted driving case.

| Approach | Fans | Maximum speed loss in one tick | Chassis normal impulse |
|---|---|---:|---:|
| 11 m/s / 39.6 km/h | On | 0.01336 m/s | 0 N s |
| 25 m/s / 90 km/h | On | 0.03701 m/s | 0 N s |
| 40 m/s / 144 km/h | On | 0.06589 m/s | 0 N s |
| 25 m/s / 90 km/h | Off | 0.09583 m/s | 0 N s |

Each case drives to at least 30 m height. The gates reject a per-tick speed loss
above 0.75 m/s, transition speed below half the measured approach speed, missing
body colliders, or an unexpected chassis impact above 1000 N s.
[Matrix](../results/ramp-entry-matrix.json),
[traces](../results/ramp-entry-traces.csv),
[comparison](../results/ramp-entry-comparison.png).

The existing full-course finite-actuator pilot still completes the launch,
instant refill, timed block jump, fan climb, return lip, flip and four-wheel
landing in **46.7833 simulated seconds**. It reaches stage 7 with no failures.
This checks the whole ramp traversal at the intended lower course speed.

A headful avatar-following capture at **38.4 m/s**, **10.3 m height** shows the
car on the curve, with all four native wheel contacts hitting `/World/StuntRamp`.
[Viewport](../results/ramp-fixed-avatar.png), [live state](../results/ramp-live.json).

The checks establish the sampled study behavior. They do not calibrate Tesla's
suspension or establish an unlimited safe ramp entry speed. The runtime still
allows physical contact and bottoming if the actual geometry/loads require it.

## Reproduce

Use a runtime containing `130fc4e27` and the earlier auxiliary-control changes.
The local launcher prefers `.scratch/luncosim` when available; `LUNCOSIM_BIN`
explicitly selects another build.

```sh
# Regenerate fixtures through the document API when ramp geometry changes:
python3 scripts/author_ramp_entry_checks.py
python3 scripts/run_ramp_entries.py --binary .scratch/luncosim
python3 scripts/run_scene_check.py roadster_course_check ROADSTER_COURSE --ticks 10000
# Optional plot from recorded observations only:
PYTHONPATH=$PWD/.scratch/plot-deps python3 scripts/plot_ramp_entry.py
```

The local development build uses `.scratch/luncosim-assets`, a companion link
to the same source checkout's `assets/`. This keeps the shared UI manifest
compatible with the binary. `LUNCO_ASSET_ROOT` explicitly overrides that source.
The final native launch was checked with the speed/air/fan HUD visible.
