# Tesla Roadster Runner

A LunCoSim engineering study and driving challenge based on the redesigned
Roadster revealed October 15, 2026. Original procedural USD geometry, SysML v2,
Modelica physics, Rhai course policy and an editable HUD are included.

Public facts and uncalibrated engineering assumptions are recorded in the
[source register](references/README.md) and [input table](references/assumptions.md).
This is an engineering/gameplay study, not Tesla CAD or a calibrated production car.

## Run

```sh
./scripts/start.sh roadster_skill_course --api 4198
```

Use the second form when supplying simulator options. With no arguments the
launcher opens the skill course. Set `LUNCOSIM_BIN` to a LunCoSim executable with
commits `a0a9a0324` and `17cad2934`, or use the locally built `.scratch/luncosim`.
The launcher composes shared assets and the authored HUD locally and loads the
isolated keymap. Shared `lunco://` assets resolve from the neighboring checkout.
No shared application assets are edited.

The native **avatar following** camera is selected automatically. Mouse look and
zoom use the normal avatar controls. The camera picker also offers DriverCamera
and RampOverview. **Ctrl+P** pauses the entire physical simulation; use the
Editor/inspector and Modelica documents to inspect parameters while paused.

| Keys | Action |
|---|---|
| W / S | Motor forward/reverse; in flight, pitch |
| A / D | Progressive keyboard steering; in flight, roll |
| Space | Forward air boost |
| Shift | Wheel brakes |
| K | All four bottom jets; short pulse to jump |
| J / L | Yaw jets |
| I / P | Front-left / front-right bottom jets |
| , / . | Rear-left / rear-right bottom jets |
| O | Inhibit collective lift |
| Ctrl+P | Pause/resume; P alone remains a corner jet |

Fans have a HUD **ON/OFF** button and measured seal, suction and electrical power.
Four rear extractors sit behind a dark grille. The forward headlights are actual
USD spot lights, attached to the car; dusk exposure is authored on course cameras.
The HUD reports speed, physical wheel angles, air mass/percentage, absolute
pressure, gas temperature, refill target and battery charge.

## Skill course

1. Reach **60 mph** at the blue launch gate using motor acceleration and boost.
2. Cross the green waypoint: it immediately restores **250 kg** and the selected
   tank temperature, including the tank wall. No stop is required.
3. Build **65–85 km/h**, switch fans off, then pulse **K near the yellow line**.
   All three 1.2 m blocks must actually be crossed in the air. Going around does
   not pass the clearance checks. Release W in flight unless pitching deliberately.
4. Cross the second green waypoint, enable fans and approach the ramp at
   **35–45 km/h**.
5. Climb with wheel traction and measured fan sealing to the green upper marker.
   Follow the long return lip, then switch fans off near its end.
6. Use **W/S** to pitch through the aerial turn. Release to damp angular rates;
   **A/D** and **J/L** trim roll/yaw. Align wheels down, land in the green area and
   brake. Completion requires four wheel contacts, upright attitude and low speed.

**RETRY COURSE** reloads the authored starting state. The timer uses simulation
time, so pausing does not consume run time. Tests command only the same finite
actuators as a player; no course script writes pose, velocity or a stunt trajectory.

The instantaneous waypoint is explicitly a **game service boundary**, equivalent
to externally conditioning/delivering co-moving gas. It is not an onboard Tesla
refill process. Modelica computes the mass and temperature adjustments, EOS
pressure, inertia, and stored/mechanical energy exchanges; Rhai copies these
boundary values together through ordinary inputs. Native velocity is preserved.

## Editable temperature and finite test service

- `inputs:initial_gas_temperature` is a Modelica initialization parameter.
- HUD **− / +** changes `refill_target_temperature_k` in 5 K steps, 253.15–333.15 K.
- Green waypoints apply that target immediately.
- **REFILL AIR (TEST)** manually connects a finite external supply, including
  while moving or inverted. It delivers up to 20 kg/s with a bounded 2 MW jacket,
  accounts for compressor/thermal service energy and incoming-air momentum.
  **STOP REFILL** disconnects it; completion disconnects automatically.

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
| Modelica | Motors, real-gas EOS, air/energy balance, wall heat transfer, refill, variable mass/inertia, finite jets and moments, fan plenum/leakage, 3D aero, regeneration, steering driver/rack, flight rate assistance and course measurements |
| Rhai | Input possession, HUD formatting/buttons, checkpoint sequencing and acceptance observations |
| Shared Rust | Native integration/contact/wheel shafts, generic auxiliary actions/chords and input/pointer transport |

Initial study mass is **1700 kg dry + 250 kg air = 1950 kg**. Two rear motors
provide **1 MW and 1400 N·m combined**, with an assumed 8.4 reduction. Native
wheel shafts determine wheel rotation. Full rack travel remains available at all
speeds; keyboard steering builds more gradually at speed. Tire slip and the
Coulomb cone determine actual cornering. Steering assistance can be disabled
with the Modelica parameter `keyboard_steering_assistance=0` for analog commands.

At 600 L and 293.15 K, the reusable Modelica dry-air EOS calculates **437.023 bar
absolute** for 250 kg. No inventory is silently scaled to 83 kg. Tank placement,
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
python3 scripts/run_scene_check.py roadster_course_check ROADSTER_COURSE
python3 scripts/check_controls.py --port 4198
python3 scripts/check_driving.py
python3 scripts/check_effects.py
```

[Recorded validation](results/README.md) distinguishes current evidence from
historical results. Standing-start timing never subtracts rollout.
`CompressedAir.mo` provides reusable EOS, sizing and internal-energy calculations;
CoolProp is only an optional verification dependency.

Maintain generated vehicle assets with `scripts/build_assets.py`. Author the
ramp/course through the running USD document API with `scripts/author_ramp.py`
and `scripts/author_ramp.py --course`; those scripts save and read back typed USD
operations. Curve sampling constructs geometry, not vehicle motion.
