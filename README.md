# Tesla Roadster Runner

A LunCoSim engineering study and driving challenge based on the redesigned
Roadster revealed October 15, 2026. Original procedural USD geometry, SysML v2,
Modelica physics, Rhai course policy and an editable HUD are included.

Public facts and uncalibrated engineering assumptions are recorded in the
[source register](references/README.md) and [input table](references/assumptions.md).
This is an engineering/gameplay study, not Tesla CAD or a calibrated production car.
The [specification audit](references/spec-audit.md) separates checked hardware facts
from remaining study assumptions. Rocket has ten nozzles and 250 kg total gas
across 200 L + 400 L vessels; it does not carry 250 kg in each vessel.

## Run

```sh
./scripts/start.sh roadster_skill_course --api 4198
```

Use the second form when supplying simulator options. With no arguments the
launcher opens the skill course. Set `LUNCOSIM_BIN` to a LunCoSim executable with
the shared camera-follow and semantic switch-mode changes (`b88089012`) on main. The current
development executable is `.scratch/control-target/debug/luncosim`; select it
with `LUNCOSIM_BIN` explicitly.
The launcher composes shared assets and the authored HUD locally and loads the
isolated keymap. Shared `lunco://` assets resolve from the neighboring checkout.
No shared application assets are edited.

The native **avatar following** camera is selected automatically. Its stabilized
view keeps the horizon level and shifts to the open side/below the ramp as the
car climbs. Mouse look and
zoom use the normal avatar controls. The camera picker also offers DriverCamera
and RampOverview. **Ctrl+P** pauses the entire physical simulation; use the
Editor/inspector and Modelica documents to inspect parameters while paused.

| Keys | Action |
|---|---|
| W / S | Motor forward/reverse, including in flight |
| A / D | Progressive keyboard steering, including in flight |
| Space | Forward air boost |
| Shift | Wheel brakes |
| K | All four bottom jets; short pulse to jump |
| Q / E | Left / right bottom-jet pairs (raise that side for roll) |
| R / C | Front / rear bottom-jet pairs (nose up / nose down) |
| F | Toggle fans on/off, once per press |
| Tab | Refill air instantly to the selected trim’s capacity and temperature |
| J / L | Yaw jets |
| I / P | Front-left / front-right bottom jets |
| , / . | Rear-left / rear-right bottom jets |
| V | Cycle cameras (C only controls rear jets) |
| Ctrl+P | Pause/resume; P alone remains a corner jet |

**WASD always controls the drivetrain.** It never opens thrusters. In the air,
wheel torque and steering still operate, but tires cannot generate road forces
without contact. K commands all four bottom jets with fixed geometry trim at any altitude;
there is no automatic pitch/roll/yaw correction or airborne control remapping.

Fans toggle with **F** or the HUD **ON/OFF** button and measured seal, suction and electrical power.
Four rear extractors sit behind a dark grille. The forward headlights are actual
USD spot lights, attached to the car; dusk exposure is authored on course cameras.
The HUD reports speed, physical wheel angles, air mass/percentage, absolute
pressure, gas temperature, refill target and battery charge.

## Skill course

1. Reach **60 mph** at the blue launch gate using motor acceleration and boost.
2. Cross the green waypoint: it immediately restores **250 kg** and the selected
   tank temperature, including the tank wall. No stop is required.
3. Carry **126 km/h**, switch fans off and pulse **K at the yellow line**
   (about 0.3 s). Clear three **3 m** cubes spaced 12 m apart. The whole car must
   pass; tire/body collisions and airborne clearance matter. Keep at least
   **90 km/h** through this corridor. W continues to control motors in flight.
4. Cross the second green waypoint while rolling, enable fans with **F** and
   approach the ramp near **100 km/h**.
5. Climb with wheel traction and measured fan sealing. Ease to about **23 km/h**
   on the upper return curve of the **18.9 m** study ramp, then switch fans off
   at the green crest.
6. **Q/E** rolls wheels-down; **R/C** trims pitch and **J/L** trims yaw. Keep the
   nose **away from the ramp**. Bank toward the road center, use **K** to cushion
   descent, then **Shift** to stop on contact. Completion requires four wheels,
   upright attitude, the return heading and speed below **0.2 m/s**.

**RETRY COURSE** reloads the authored starting state. The timer uses simulation
time, so pausing does not consume run time. Tests command only the same finite
actuators as a player; no course script writes pose, velocity or a stunt trajectory.

The instantaneous waypoint is explicitly a **game service boundary**, equivalent
to externally conditioning/delivering co-moving gas. It is not an onboard Tesla
refill process. Modelica computes the mass and temperature adjustments, EOS
pressure, inertia, and stored/mechanical energy exchanges; Rhai copies these
boundary values together through ordinary inputs. Native velocity is preserved.
The course acknowledges the service counter from that atomic boundary. It does
not wait for exact tank fullness afterward: a closing valve can already consume
some of the replenished gas during the next coupled interval.

## Editable temperature and refill

- `inputs:initial_gas_temperature` is a Modelica initialization parameter.
- HUD **− / +** changes `refill_target_temperature_k` in 5 K steps, 253.15–333.15 K.
- Green waypoints apply that target immediately.
- **Tab** or **REFILL AIR** restores the tank instantly, including while moving
  or inverted. The same Modelica service boundary as green waypoints updates
  gas/wall temperature, mass, pressure, inertia and stored/mechanical energy.
- **UNLIMITED AIR** in the Air inventory toggles an ideal test reservoir. Enabling
  it fills the tank; Modelica then replaces discharged air at the same state,
  holding gas mass and temperature steady. Switch it off to resume finite
  blowdown and cooling. External mass and energy use remain inspectable.
- The finite external supply remains available through `scripts/control.py`
  for engineering studies (20 kg/s, bounded 2 MW jacket).

```sh
python3 scripts/control.py --refill-temperature 303.15 --refill 1
python3 scripts/control.py --keyboard
```

The service is test equipment, not a claim about Tesla hardware. Public sources
reviewed do not establish Tesla's tank heating or cold-gas thermal-management
implementation. Passive tank-wall heat exchange is modeled with stated study
coefficients. The **200 K discharge guard is a conservative model guard**, not a
Tesla temperature limit or a fundamental air freezing point.

## Physics ownership

| Layer | Responsibility |
|---|---|
| USD | Body compound colliders, roof envelope, wheel mounts, suspension, Earth gravity, lights, ramp and obstacle collision geometry; native port wiring |
| Modelica | Motors, real-gas EOS, air/energy balance, wall heat transfer, refill, variable mass/inertia, finite jets and moments, fan plenum/leakage, 3D aero, regeneration, steering driver/rack and course measurements |
| Rhai | Input possession, HUD formatting/buttons, checkpoint sequencing and acceptance observations |
| Shared Rust | Native integration/contact/wheel shafts, generic auxiliary actions/chords and input/pointer transport |

Initial study mass is **1700 kg dry + 250 kg air = 1950 kg**. Two rear motors
provide **1 MW and 1400 N·m combined**, with an assumed 8.4 reduction. Native
wheel shafts determine wheel rotation. Full rack travel remains available at all
speeds; keyboard steering builds more gradually at speed. Tire slip and the
Coulomb cone determine actual cornering. Steering assistance can be disabled
with the Modelica parameter `keyboard_steering_assistance=0` for analog commands.

At 600 L and 293.15 K, the reusable Modelica dry-air EOS calculates **437.023 bar
absolute** for 250 kg. Rocket retains 250 kg. Thrust’s separate 200 L trim explicitly derives about 83.33 kg at the same initial density. Tank placement,
nozzles, fan maps, aero coefficients, tire curves and thermal coefficients remain
study assumptions. See [storage](references/gas-storage.md) and
[dynamics](references/dynamics.md).

## Scenes and reproduction

| Scene | Purpose |
|---|---|
| roadster_skill_course | Default driving challenge |
| roadster_ramp | Close practice start at the stunt ramp |
| roadster_rocket / thrust / track | Flat-track Rocket / rear-boost / motor-only trims |
| roadster_wall | Pre-spun wall adhesion fixture |
| roadster_*_check | Authored production acceptance scenes |
| roadster_launch / roadster_motor_launch | Standing-start measurements |

```sh
python3 scripts/run_launch.py --binary .scratch/luncosim
python3 scripts/run_motor_launch.py --binary .scratch/luncosim
python3 scripts/run_ramp_entries.py --binary .scratch/luncosim
python3 scripts/run_scene_check.py roadster_course_check ROADSTER_COURSE --verification Roadster::VerifySkillCourse --ticks 2400
python3 scripts/check_controls.py --port 4198
python3 scripts/check_driving.py
python3 scripts/check_effects.py
python3 scripts/check_keyboard_course.py --launch --manual --binary /path/to/luncosim
```

The HUD **RUN AUTOPILOT** button uses the same behavior tree and Modelica guidance
as the keyboard client. Driving or jet keys take over. Add `--autopilot` to the
keyboard test command to exercise its real HUD button. Add `--operator-checks`
with `--autopilot --manual --launch` to verify active pause, manual takeover,
HUD retry and then full course completion. The standalone course gate
observes this shared production pilot; it does not carry a separate control law.
See [manual acceptance steps](tests/manual-course.md) and the
[course review](reviews/shared-course-tree.md) and [dynamic-course design](references/dynamic-course.md).

The course pilot requests a full longitudinal kickflip over the obstacles through
the existing corner valves. `course_jump_roll_target_deg` defaults to 360; set it
to zero for an upright jump. Guidance uses measured body rates and the current
finite-air angular authority, then banks slightly to recover toward the road.
It does not write body state or forces. A recovery counter-rotation can reduce
the final roll integral after the car has already completed a revolution; inspect
the trajectory and recovered attitude together. Manual valve controls remain direct.

## Tune the following camera live

```sh
python3 scripts/camera.py --distance 18 --height 1 --tilt -20 --damping .9
python3 scripts/camera.py --mode stabilized   # also heading or body
python3 scripts/camera.py --reload-policy
```

Edit `scripting/policy/roadster_camera.rhai` and replace it through the Twin-owned
camera tool. Settings and policy updates work with physics paused and preserve the
vehicle state. The shared `camera.follow` seam exposes selected-vessel identity,
orientation, motion, rig settings and obstruction facts. Rhai chooses framing and
custom easing weights; the native camera retains collision and pose ownership.
Other vessels may select different policies and existing native camera rigs.

The keyboard pilot drives the main course with native press/release events,
including Ctrl+P. Leave its test window controls alone during acceptance;
additional physical key events reject the run. `--manual` admits exact native
fixed cycles between observations and leaves all physical equations unchanged.
Omit it to exercise realtime playback. Reports include key transitions, stage
screenshots, inventory, mass and four-wheel landing contacts.

[Recorded validation](results/README.md) distinguishes current evidence from
historical results. Standing-start timing never subtracts rollout.
`CompressedAir.mo` provides reusable EOS, sizing and internal-energy calculations;
CoolProp is only an optional verification dependency.

Maintain wheel/body mechanics with `scripts/author_contact_upgrade.py` and
standard rigid-body placement with `scripts/author_usd_physics.py`, using the
live document API. Mount study data lives in `scripts/study_geometry.py`. Author the
ramp/course through the running USD document API with `scripts/author_ramp.py`
and `scripts/author_ramp.py --course`; apply `scripts/author_dynamic_course.py`
to the base course for the new compact ramp and timing corridor. These scripts
save typed USD operations and inspect the composed documents. Curve sampling constructs geometry, not vehicle motion.

## Force and mounting analysis

[Measured launch/force results and placement assumptions](references/propulsion-analysis.md)
include the rear mounting moment, balanced collective geometry, wheel-only
Performance/Rocket baselines and finite tank blowdown. The [plots](results/propulsion-analysis.png)
and [layout](results/thruster-layout.png) are generated from recorded observations
and the authored study geometry.

## Ramp contact correction

[Ramp entry investigation and evidence](references/ramp-contact.md) records
four speed/fan checks, including smooth 144 km/h entry with all body colliders
enabled, plus full-course completion. The collision fixes are integrated into main; the approved Parry revision is
published. The launcher prefers the validated
local `.scratch/luncosim`; use `LUNCOSIM_BIN` to select another runtime explicitly.

The local development build uses `.scratch/luncosim-assets`, a companion link
to the same source checkout's `assets/`. This keeps the shared UI manifest
compatible with the binary. `LUNCO_ASSET_ROOT` explicitly overrides that source.
The final native launch was checked with the speed/air/fan HUD visible.

## Internal fan adhesion model

The fan component contains its geometry probes and seal/plenum math; the
drivetrain consumes its force and electrical demand, and the chassis receives
its moment. The assembly is flattened into one Modelica solve. These are
simulation queries, not added Tesla sensor hardware, and they have no visible
markers. See the [component boundary](references/dynamics.md#adhesion-component-boundary).

## USD interoperability

See [USD and Omniverse contracts](references/usd-omniverse.md) and the
[composed authoring audit](results/usd-standard.json). The explicit rigid-body
rig follows the standard schema contracts; Omniverse execution has not been
validated. Modelica, Rhai and custom rendering still require their runtime
integrations.

### Battery assumption

The study uses **120 kWh nominal**, inferred from reported >100 kWh energy and
>300-mile range, with explicit 220 Wh/km and 90% sizing assumptions. It is editable
as `inputs:battery_capacity_kwh`. Modelica adjusts energy, mass and inertia from
the 120 kWh / 1700 kg dry reference; the pack is counted once. See
[battery sources and derivation](references/battery-study.md). Automated sensitivity:
`python3 scripts/check_battery_study.py --binary /path/to/luncosim`.
