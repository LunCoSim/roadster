# Recorded validation

Milestone date: 2026-10-18. Linux production LunCoSim, locally built runtime
`17cad2934` (including `a0a9a0324`). No push or integration into main is implied.
The launcher composes the Twin HUD and shared assets locally. Older screenshots
and reports retained by Git belong to the earlier `22a53afc` milestone and are
not current evidence for changed controls/geometry.

| Gate | Current evidence |
|---|---|
| Rocket hardware | `hardware.json`: ten native nozzles, composed positions/axes, ~63 mm tire clearance, matching native COM; 250 kg across 200/400 L, one available seat and 1950 kg native mass. |
| Complete skill course | `course.json`: 46.78 s with direct jet commands; launch, two instant services, three airborne block crossings, fan climb, manual finite-jet turn and four-wheel landing. Acceptance driver uses commands, no pose/velocity writes. |
| Moving jump / fixed input meanings | `moving_jump.json`: 89 airborne samples; four driving commands exercised, collective pitch moment below 1e-8 N·m and at most 0.015 N residual jet force 0.35 s after release. |
| Steering | `steering.json`: measured steady right turns at approximately 5, 15 and 30 m/s; native yaw within 2–7% of geometric turn rate. Progressive keyboard driver retains full rack travel. |
| Native controls | `controls.json`: 16 checks: F toggle/hold/release, Space, K, Q/E left/right, R/C pitch, J/L yaw, I/P/comma/period, W, A and Shift pass native injected keys; physical mass checked in a single-frame snapshot. |
| HUD / pause | `hud-controls.json`: real native pointer clicks change fan state and temperature target; Ctrl+P freezes simulation ticks and resumes. `hud-fixed-controls.png` shows the current compact HUD and fixed key meanings. |
| Wheels / braking | `driving.json`: all eight native rotation, rolling, steering, brake, contact, mass and HUD checks pass. |
| Gas / energy EOS | `gas-sizing.json`: eight actual Modelica State/function experiments compared with CoolProp 8.0.0. Includes internal energy with the documented constant reference offset of 531917.3305791204 J/kg. |
| Earth gravity | `earth.json`: free-fall acceleration 9.7906 m/s² with drag, authored gravity 9.80665 m/s². |
| Fan adhesion | `wall.json`: ~40 kN sealed suction; fan-off car falls along wall. A valid ray intersection is not itself proof of adhesion. |
| Moving finite refill | `moving_refill.json`: no stop, finite 20 kg/s inflow, editable 303.15 K target, native mass returns to 1950 kg and inlet momentum loading is nonzero. |
| Gas-assisted launch | `launch-report.json`, `launch-telemetry.json`, `launch.csv`: Rocket trim, seven SysML requirements/eight checks including one available seat; approximately 0.516 s standing-start to 60 mph, no rollout subtraction. |
| Motor-only launch | `motor-after.json`: 1.786 s at 1950 kg; `motor-performance.json`: 1.581 s at 1700 kg. Both fan-on, no gas use; uncalibrated study results. |
| Bank forces / thermal limit | `force_rear/lift/side.json`: full-command peak forces 110.2 / 84.7 / 5.16 kN; rear/lift stop at the 200 K study guard with ~136 kg still stored. Plots and sizing are in `propulsion-analysis.*`. |
| Jet rendering | `effects.json`: delivered forces reach four shader sinks and close on release; current keys Space/J/L/K. `layout-render.json` and `layout-K/Q/R.png` additionally check/capture revised lift mounts and paired banks. Streams are qualitative indicators. |

## Validation boundaries

The [hardware audit](../references/spec-audit.md) records unresolved capacity,
fill-state and calibration details, including the Thrust fixture's common storage
study envelope. Hardware counts and conservation checks do not establish a
manufacturer-calibrated vehicle.

Current correction: WASD remains drivetrain control at every altitude; the
flight-mode remapping and automatic rate controller were removed. `moving_jump.json`
exercises W/S/A/D during a moving jump: near-zero collective pitch moment with fixed fore/aft valve trim, less
than 5 mm front/rear body-point height difference in airborne samples, continuing
motor torque and no jets beyond the modeled valve-close transient. Q/E and R/C
are paired aliases of the same four native auxiliary inputs. The acceptance
pilot was updated to operate those physical valves; its feedback lives only in
the automated test driver, not in player controls.

`headlights.json` and `headlights-on/off.png` establish the focused native lamps
illuminate the road: 75,230 road-ROI pixels change by more than two brightness
levels. This is a rendering check, not measured Tesla photometry.

The finite-actuator course run establishes playability of the authored study,
not Tesla performance or safe real-car stunt behavior. No manufacturer tire,
fan, nozzle, aero or thermal calibration was obtained. Instant waypoint refill
is an explicit game service boundary and has separate accounting from finite
external test refill.

Rust checks: control-core 8/8, input-core 10/10, mobility 41 passed/1 ignored,
and two focused native pointer tests passed. The broader controller suite had
23 passes and two telemetry-edge fixture failures; it is not reported green.
The pointer regression failed first with an unset Window cursor position and
passed after restoring the native cursor owner alongside its messages.

The validation manifest fingerprints the authored milestone. Individual results
were produced during its development; source changes after a particular result
must be rerun before claiming fresh acceptance for those changes.

The earlier propulsion content change added no Rust. `ThrusterMount.mo` owns application-point
moments; `LaunchSizing.mo` owns the first-order force budget; Modelica integrates
rear impulse in the marked launch measurement window. The full source audit and
limits are in `references/propulsion-analysis.md`. The optional plot dependency
is isolated under ignored `.scratch/`; it is not needed to run the Twin.

## Ramp contact correction — 2026-10-19

The [ramp investigation](../references/ramp-contact.md) supersedes the old
short-run entry coverage. `ramp-entry-before.json` retains the reproducible
144 km/h stop and diagnostic collider ablations. `ramp-entry-matrix.json` and
`ramp-entry-traces.csv` record four passing speed/fan cases after the generic
USD mesh internal-edge correction in core **130fc4e27**. All four chassis
collision parts remain enabled, and every case reports zero chassis impulse.
The full `course.json` was rerun on this corrected runtime and still passes at
46.7833 s. `ramp-live.json` and `ramp-fixed-avatar.png` are headful, native
avatar-following evidence on the curve.

Earlier propulsion and control results above retain their original binary
provenance; they were not all rerun for this collider-only correction. The core
regression is one named Mesh/Plane test, demonstrated failing before and passing
after; this is not a fresh whole-core test-suite result.
