# Counterclockwise flip correction — 2026-10-20

The requested direction is counterclockwise **viewed from behind toward the
nose**, about the vehicle's longest axis (positive body +Z roll).

The prior quaternion controller always selected the shortest attitude rotation.
At the inverted ramp exit, a small tilt selected the clockwise half-turn.
`CoursePilot.mo` now explicitly selects `flip_roll_direction=1` while inverted
(`up_y < -0.8`), then resumes shortest-path correction for the rest of recovery.
Quaternion sign changes do not change this selection. The pilot still requests
ordinary E/Q bottom-thruster banks and counterpulses; force, gas, mass, inertia,
contact physics and manual key mappings are unchanged. The shared behavior-tree
prompt and manual instructions now name E for initiation and Q for braking.

## Evidence

- `results/dynamic-timing.json`: the complete nominal course passes in 24.93 s;
  early/late negative cases still produce physical cube collisions.
- `results/counterclockwise-roll.json`: retained native samples integrate to
  **+174.04 degrees** of signed body roll over phase 6; initial roll rates are
  positive, reversing the previous negative rates. This sampled integral checks
  direction; it is not an exact quaternion attitude decomposition.
- `results/counterclockwise-keyboard.json`: HUD-started autopilot passed all
  19 native-window checks in 24.83 s, including four-wheel landing away from the
  ramp and stopping. Its sampled signed roll is +175.82 degrees. Flight and
  completion screenshots were inspected. This uses native event injection,
  not qualified desktop OS keyboard delivery.
- The prior qualification results remain evidence of their recorded source
  snapshots. Battery sizing, launch and jump physics were not changed by this
  guidance correction. Desktop OS input remains unqualified as documented in
  the [previous follow-up](qualification-followup.md).

No Rust, USD or dependency source changes were needed.
