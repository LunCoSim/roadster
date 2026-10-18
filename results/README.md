# Recorded validation

Milestone date: 2026-10-18. Linux production LunCoSim, locally built runtime
`17cad2934` (including `a0a9a0324`). No push or integration into main is implied.
The launcher composes the Twin HUD and shared assets locally. Older screenshots
and reports retained by Git belong to the earlier `22a53afc` milestone and are
not current evidence for changed controls/geometry.

| Gate | Current evidence |
|---|---|
| Complete skill course | `course.json`: 47.22 s with direct jet commands; launch, two instant services, three airborne block crossings, fan climb, manual finite-jet turn and four-wheel landing. Acceptance driver uses commands, no pose/velocity writes. |
| Moving jump / fixed input meanings | `moving_jump.json`: 89 airborne samples; four driving commands exercised, zero front/rear collective imbalance and at most 0.012 N residual jet force 0.35 s after release. |
| Steering | `steering.json`: measured steady right turns at approximately 5, 15 and 30 m/s; native yaw within 2–7% of geometric turn rate. Progressive keyboard driver retains full rack travel. |
| Native controls | `controls.json`: 15 checks: Space, K, Q/E, J/L, U/O, I/P/comma/period, W, A and Shift pass native injected keys; physical mass checked in a single-frame snapshot. |
| HUD / pause | `hud-controls.json`: real native pointer clicks change fan state and temperature target; Ctrl+P freezes simulation ticks and resumes. `hud-fixed-controls.png` shows the current compact HUD and fixed key meanings. |
| Wheels / braking | `driving.json`: all eight native rotation, rolling, steering, brake, contact, mass and HUD checks pass. |
| Gas / energy EOS | `gas-sizing.json`: eight actual Modelica State/function experiments compared with CoolProp 8.0.0. Includes internal energy with the documented constant reference offset of 531917.3305791204 J/kg. |
| Earth gravity | `earth.json`: free-fall acceleration 9.7906 m/s² with drag, authored gravity 9.80665 m/s². |
| Fan adhesion | `wall.json`: ~40 kN sealed suction; fan-off car falls along wall. A valid ray intersection is not itself proof of adhesion. |
| Moving finite refill | `moving_refill.json`: no stop, finite 20 kg/s inflow, editable 303.15 K target, native mass returns to 1950 kg and inlet momentum loading is nonzero. |
| Gas-assisted launch | `launch-report.json`, `launch-telemetry.json`, `launch.csv`: seven SysML requirements/eight checks; approximately 0.515 s standing-start to 60 mph, no rollout subtraction. |
| Motor-only launch | `motor-after.json`: approximately 1.786 s with the current 40 kN fan envelope, 1950 kg and no gas use. Uncalibrated study result. |
| Jet rendering | `effects.json`: delivered forces reach four shader sinks and close on release; current keys Space/J/L/K. Streams are qualitative indicators. |

## Validation boundaries

Current correction: WASD remains drivetrain control at every altitude; the
flight-mode remapping and automatic rate controller were removed. `moving_jump.json`
exercises W/S/A/D during a moving jump: equal front/rear collective force, less
than 6 mm front/rear body-point height difference in airborne samples, continuing
motor torque and no jets beyond the modeled valve-close transient. Q/E and U/O
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
