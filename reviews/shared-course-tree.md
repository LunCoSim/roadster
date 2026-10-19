# Shared course tree and follow camera

`scenarios/skill_course.rhai` owns the production `seq` behavior tree.
`models/CoursePilot.mo` supplies the same digital guidance to the native keyboard
client and event-driven autopilot. The standalone course acceptance script is an
observer that starts that shared pilot; it contains no driving control law.
Guidance never writes poses, velocities, forces, mass or hidden refill state.

Shared engine changes are committed on main as `b88089012` (camera) and
`af8a897ef` (native port authoring). Production acceptance:

- Native keyboard: 12 checks pass, full course in 39.9167 simulated seconds.
- HUD-started autopilot: 12 checks pass, full course in 40.0833 seconds.
- Standalone shared-tree observer: PASS at tick 2401 (40.0167 seconds).
- Live camera: 11 checks pass, including native C/V routing, atomic rejection,
  live Twin policy replacement, fault/diagnostic/recovery and unchanged held tick.

Reports and selected captures are in `results/shared-keyboard.json`,
`results/shared-autopilot.json`, `results/shared-course.json`, and
`results/camera-follow.json`. Keyboard tests use native fixed stepping between
observations, not a substitute integrator or OS-device injection. Modelica mass,
finite air, two real waypoint services and four native wheel contacts are checked.

The shared native follow mechanism exposes `camera.follow` to Rhai. The Roadster
policy selects an external-frame view that moves to the open ramp side and below
the return lip. Native code owns collision checks and interpolation. C previously
also cycled cameras; cycling now uses the configured switch-mode intent (V).
`SetCameraFollow` and `scripts/camera.py` tune the existing rig live. A Twin-owned
operator tool replaces the policy without reloading the scene or advancing physics.
The boom remains a point query, so this is not a camera-frustum sweep qualification.

## Roll/yaw checkpoint (2026-10-20)

The updated shared tree explicitly recovers upright with roll, selects yaw
according to measured lateral drift, turns through an intermediate heading, then
lands while traveling backward. The keyboard adapter passes 15/15 checks in
40.0167 course seconds: 195.1 degrees roll path, 185.5 degrees yaw path and
6.15 m of upright backward flight. `results/yaw-keyboard.json` records the
selected Avatar camera and four native contacts. `results/yaw-course.json` is
the separate passing native standalone observer run.

This checkpoint finishes with its nose toward the ramp. The next requested
course must instead finish pointing away from it, carry more speed through the
blocks and tighten the jump timing. The checkpoint's last airborne vertical
speed is -15.46 m/s: four contacts and a stopped car do not qualify a gentle or
structurally safe landing. The 64.46 m ramp is authored study geometry, not a
measured Tesla replica. The primary event video download was blocked, so this
is a requested maneuver study, not verified reproduction of the footage.

The camera core unit suite passes 18/18. New runtime sessions are owned on
explicit port 4198; course drivers close them after acceptance.

## Continuous course (2026-10-20)

The compact 18.873 m course supersedes that checkpoint as the default. It carries
35 m/s through the service/jump corridor, requires at least 25 m/s until ramp
approach, clears 3 m cubes, climbs with fans, rolls wheels-down facing away and
stops after landing. The original 64.46 m ramp was too tall for a reliable
cushioned finite-air recovery. Fourteen transverse mesh segments also avoid the
extreme triangle aspect ratios exposed by the compact geometry. No Rust or
third-party dependency source changed for this course revision.

The stricter native keyboard gate passes **18/18** in **25.267 s**, with **zero cube
contact impulse**, two rolling refills, four landing contacts and final speed
0.066 m/s. Last recorded airborne descent is 3.648 m/s; native mass agrees with
Modelica inventory. `results/dynamic-keyboard.json` retains full keys/samples,
contact and camera evidence. `results/dynamic-timing.json` records the separate
standalone nominal and timing-failure cases. +0.3 s early and -0.2 s late both
produce actual cube contact and mission failure. These samples do not establish
an exact success-window width.

The new default keeps +Z return heading through roll with yaw trim; it does not
add the earlier 180-degree yaw reversal that would point toward the ramp. The
[design and reproduction commands](../references/dynamic-course.md) describe
Modelica banking/descent guidance, native USD geometry and manual acceptance.

HUD-started autopilot independently passes 18/18 at 24.833 s with zero cube
contact, a final speed below 0.2 m/s and nose away. Its descent before touchdown is
2.677 m/s. A hidden descent gate initially left an otherwise completed car waiting;
completion now uses pose, road position, four contacts and standstill, while
acceptance separately limits landing descent to 5 m/s. Native keyboard injection
and HUD pointer delivery are qualified; human OS keyboard delivery remains a
manual check.

`results/dynamic-mesh.json` records a live USD audit: 15,030 vertices, 15,028 quad
faces, two faces per edge, consistent winding, no degenerate triangles and maximum
triangle aspect ratio 17.16. Independent Omniverse execution is untested.
