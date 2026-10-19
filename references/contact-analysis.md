# Suspension and contact investigation — 2026-10-19

The collision correction is committed on local LunCoSim main as `d0b091908`.
[Measured results](../results/contact-physics-review.json) retain the remaining
ramp performance failures. Held-key input, the full keyboard course and the
separate intermittent HUD reload issue remain open. Nothing has been pushed.

## Corrected causes and ownership

- USD rotations narrowed before decomposition could turn a 0.34 m analytic
  wheel into a ten-sided hull with a measured 0.323359 m radial bound. Local
  commit `88793d565` preserves double-precision decomposition. Native wheel-axis
  construction now also uses double precision and unit rigid rotations.
- Thin native GJK tetrahedra could falsely classify separated shapes as
  intersecting and leave EPA without geometry. With explicit user approval,
  Parry commits `e353239` and `75b6acc` repair tetrahedron face reduction and
  certify orientation against determinant roundoff. Six recorded poses and
  6,144 nearby queries pass in both shape orders. The application now uses the
  default native dispatcher. These dependency commits remain local; publication
  is not authorized and a fresh remote checkout cannot fetch the new pin yet.
- Convergence previously measured the size of a joint correction rather than
  remaining error. It now reuses the existing geometric joint rows to measure
  actual position/angular residuals. Ordinary motors still run once per substep.
- Rolling contact needed fresh endpoint witnesses on both convex and mesh
  surfaces. Native manifold dispatch retains mesh internal-edge rules. Additional
  continuous normal reactions supply a once-consumed native Coulomb budget,
  using fresh levers/normals and the prepared collider pair's material policy.
  They do not enter an obsolete normal warm-start accumulator.
- Mounted clearance observations hit the vehicle's own compound collider.
  Local main commit `c84097bb1` excludes the attached native collider identities;
  the airborne observation regression passes in the current drop run.

`drive.rs` is unchanged. Rust contains shared solver integration; Modelica owns
vehicle mass, motors, gas, thermal and aerodynamic equations. USD owns bodies,
geometry, frames, materials and suspension. Rhai owns controls and course policy.

## Current numerical qualification

The authored profile is 60 Hz with eight substeps, 0.5 mm position tolerance
and 0.002 rad angular tolerance. The accepted suspension/ground checks retain
3 mm margins. Mass, inertia, motor power, stiffness and damping were not tuned
for the collision correction.

All four 20-second production contact runs pass: a 6 m flight/drop, left and
right side recoveries, and a finite-floor comparison. Maximum wheel-ground
penetration is 0.4944 mm; bump/droop stay within 0.5 mm of the +65 / −55 mm
stops. Analytic wheel radius and airborne self-exclusion checks pass.

Motor-only 0–60 mph is 3.064 s at full 1950 kg. Boosted launch is 0.554 s,
passing the 0.59 s requirement. These are study results, not manufacturer
calibration. Generic continuous contacts pass 12 checks and the prismatic spring
passes 26. Focused low-level checks pass 28 CCD, nine joint-projection,
60 Parry library and seven Parry query tests; the f32 library compiles.
The pre-existing degenerate-triangle test and two native automatic-mass-helper
assertions remain outside this passing subset. No full-suite pass is claimed.

## Remaining ramp acceptance

The complete four-case matrix records two passes and two failures. Both 25 m/s
fan-on/off runs pass. At 11 m/s, fresh rolling contact permits a climb past 30 m,
but speed falls below its minimum gate. At 40 m/s, maximum one-tick loss is
0.750522 m/s against the 0.75 m/s limit. All four retain native geometry without
query faults and report zero chassis contact impulse. No gate was weakened.
Further traction/control and seam investigation is required before whole-course
acceptance. The composed USD audit is separate from NVIDIA Omniverse execution,
which has not been performed.
