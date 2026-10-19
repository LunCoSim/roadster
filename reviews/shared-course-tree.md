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

Remaining maneuver work: the passing controller recovers through pitch. It does
not yet reproduce the user-observed yaw turn into backward travel. That requires
an explicit yaw/roll phase and its own finite-air acceptance; accumulated pitch
alone must not be presented as validation of Tesla's complete stunt choreography.

The camera core unit suite passes 18/18. All newly created runtime sessions were
owned on explicit port 4198; course drivers close them after acceptance.
