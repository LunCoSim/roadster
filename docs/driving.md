# Driving guide

The default scene, **Roadster Cinematic**, is an illuminated night version of the skill course. It uses the same vehicle, forces, and course program as the daylight scene; only its lighting and materials differ. Use **Run Autopilot** to watch the course or take control with the keyboard.

## Controls

| Keys | Action |
|---|---|
| W / S | Motor forward / reverse, including in flight |
| A / D | Progressive steering, including in flight |
| Space | Forward air boost |
| Shift | Wheel brakes |
| K | All four bottom jets; pulse to jump |
| Q / E | Left / right bottom-jet pairs (raise that side for roll) |
| R / C | Front / rear bottom-jet pairs (nose up / nose down) |
| F | Toggle fans, once per press |
| Tab | Refill air to the selected trim's capacity and temperature |
| J / L | Yaw jets |
| I / P | Front-left / front-right bottom jets |
| , / . | Rear-left / rear-right bottom jets |
| V | Cycle cameras |
| Ctrl + P | Pause / resume the physical simulation |

**WASD always controls the drivetrain.** Wheel torque and steering remain available in flight, but tires produce no road forces without contact. K is a held valve command: releasing it closes the lift valves. It applies fixed geometry trim at any altitude; it does not request a fixed-height jump or provide automatic attitude correction. A long hold can produce a high powered climb.

The native avatar-following camera is selected automatically. Its stabilized view keeps the horizon level and shifts to the open side or below the ramp as the car climbs. Mouse look and zoom use the normal avatar controls. DriverCamera and RampOverview are also available from the camera picker. **Ctrl + P** pauses the physical simulation so you can inspect the editor and Modelica documents.

## Skill course

1. Reach **60 mph** at the blue launch gate using motor acceleration and boost.
2. Cross the green waypoint. It immediately restores **250 kg** of air and the selected tank temperature, including the tank wall. No stop is required.
3. Carry **126 km/h**, switch fans off, and pulse **K at the yellow line** for about 0.3 s. Clear the three **3 m** cubes spaced 12 m apart. The whole car must pass; tire and body collisions and airborne clearance matter. Keep at least **90 km/h** through the corridor. W still controls the motors in flight.
4. Cross the second green waypoint while rolling, enable fans with **F**, and approach the ramp near **100 km/h**.
5. Climb with wheel traction and measured fan sealing. Ease to about **23 km/h** on the upper return curve of the **18.9 m** study ramp, then switch fans off at the green crest.
6. Use **Q/E** to roll wheels-down, **R/C** to trim pitch, and **J/L** to trim yaw. Keep the nose away from the ramp and bank toward the road center. Use **K** to cushion descent, then **Shift** to stop on contact. Completion requires four-wheel contact, upright attitude, the return heading, and speed below **0.2 m/s**.

**RETRY COURSE** resets the active scene runtime from its current composed source while keeping the Twin open. The timer uses simulation time, so pausing does not consume run time. Tests command only the same finite actuators available to a player; course logic does not write pose, velocity, or a stunt trajectory.

The instantaneous waypoint is a **game service boundary**, equivalent to externally conditioning and delivering co-moving gas. It is not an onboard Tesla refill process. Modelica computes the mass and temperature adjustments, equation-of-state pressure, inertia, and stored/mechanical energy exchanges. Rhai applies those boundary values together through ordinary inputs, preserves native velocity, and acknowledges the service counter. It does not wait for exact tank fullness afterward: a closing valve can consume some replenished gas during the next coupled interval.

## Temperature and refill

- `inputs:initial_gas_temperature` is a Modelica initialization parameter.
- The HUD **− / +** buttons adjust `refill_target_temperature_k` in 5 K steps from 253.15 K to 333.15 K.
- Green waypoints apply that target immediately.
- **Tab** or **REFILL AIR** restores the tank instantly, including while moving or inverted. The Modelica service boundary updates gas and wall temperature, mass, pressure, inertia, and stored/mechanical energy.
- **UNLIMITED AIR** in the Air inventory toggles an ideal test reservoir. Enabling it fills the tank; Modelica then replaces discharged air at the same state, holding gas mass and temperature steady. Switch it off to resume finite blowdown and cooling. External mass and energy use remain inspectable.
- A finite external supply remains available to engineering scripts through `scripts/control.py` (20 kg/s, bounded 2 MW jacket).

For example, from the project folder:

```sh
python3 scripts/control.py --refill-temperature 303.15 --refill 1
python3 scripts/control.py --keyboard
```

The service is test equipment, not a claim about Tesla hardware. Reviewed public sources do not establish Tesla's tank heating or cold-gas thermal-management implementation. Passive tank-wall heat exchange uses stated study coefficients. The **200 K discharge guard is a conservative model guard**, not a Tesla temperature limit or a fundamental air-freezing point.

## Tune the camera live

```sh
python3 scripts/camera.py --distance 18 --height 1 --tilt -20 --damping .9
python3 scripts/camera.py --mode stabilized   # also heading or body
python3 scripts/camera.py --reload-policy
```

Edit `scripting/policy/roadster_camera.rhai` and replace it through the Twin-owned camera tool. Settings and policy updates work while physics is paused and preserve vehicle state. The shared `camera.follow` seam exposes selected-vessel identity, orientation, motion, rig settings, and obstruction facts. Rhai chooses framing and custom easing weights; the native camera retains collision and pose ownership. Other vessels can select different policies and existing native camera rigs.
