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

The tire WESL material uses mesh-local position, an explicit axle direction and
radius for its rim and tread. Its pattern does not depend on primitive cap UVs.
`tools/crowned_tire.rhai` and `scripts/author_tire_profile.rhai` author the same
separation through the document journal.

`scenarios/tests/wheel_visual_contract.rhai` runs in the graphical production
host. Thirteen checks cover native analytic collision, hidden proxy geometry,
one crowned render surface per wheel, material resolution and the preserved
cabin hull. The regular production build at core `66d9e3ac1` passes the gate;
GPU render logs and two inspected close-up captures are retained in the engine
worktree's `.cache/codex-evidence/physics-followup-20261021/tesla-wheel-visuals-20261022/`.
This qualifies wheel presentation and collision ownership. Whole-vehicle
steering, landing, adhesion and course behavior require their separate gates.
