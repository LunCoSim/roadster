# Wheel contact and presentation

The four physical wheels use native analytic X-axis cylinders: radius 0.34 m,
front width 0.25 m and rear width 0.30 m. Their dimensions remain USD doubles.
The crowned profile is a separate visual mesh with collision disabled. These
are study dimensions, not manufacturer tire or carcass calibration.

Standard `VisibilityAPI` hides each cylinder through `proxyVisibility=invisible`.
Its `CrownedVisual` child has render purpose and `renderVisibility=visible`.
Ordinary subtree invisibility is inappropriate here because it would suppress
both representations. The physics reader retains the cylinder independently of
its render visibility. The cabin retains its convex mesh hull.
The shared wheel projector binds that centered render child after structural
admission. Its mechanical axle controls roll independently of the mesh basis;
the same presentation contract supports physical and raycast realizations.

The tire WESL material uses mesh-local position, an explicit axle direction and
radius for its rim and tread. Its pattern does not depend on primitive cap UVs.
`tools/crowned_tire.rhai` and `scripts/author_tire_profile.rhai` author the same
separation through the document journal.

`scenarios/tests/wheel_visual_contract.rhai` runs in the graphical production
host. Thirteen checks cover native analytic collision, hidden proxy geometry,
one crowned render surface per wheel, material resolution and the preserved
cabin hull. The regular production build at core `3844088aa` passes the gate;
GPU render logs and two inspected close-up captures are retained in the engine
worktree's `.cache/codex-evidence/physics-followup-20261021/wheel-render-root/main-visual/`.
This qualifies wheel presentation and collision ownership. Whole-vehicle
steering, landing, adhesion and course behavior require their separate gates.

The wall fixture starts at tire contact: its axle is 0.34 m from the wall,
matching the analytic radius, with every reset-stack body placed from the same
vehicle pose. This clears initial penetration admission. Its seven-second
production gate still fails holding and release: at five seconds all four
wheels contact the wall with 39.99 kN suction, but the vehicle has descended
from 30.0 m to 5.86 m. The later release assertion is consequently not an
isolated detachment measurement. Evidence is in the engine worktree's
`wheel-render-root/main-checkpoint/tesla-wall-contact.log` beneath the evidence
directory above. Contact placement does not qualify adhesion or braking.
