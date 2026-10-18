# Tesla Roadster Runner

A LunCoSim engineering study of the second-generation Roadster revealed on
October 15, 2026. Includes original procedural USD geometry, SysML v2 structure
and requirements, Modelica dynamics, references and production-run evidence.

This is **not a calibrated Tesla production model**. Manufacturer statements,
user inputs and study assumptions are separated in the
[source register](references/README.md) and [input table](references/assumptions.md).
The old 2017 red concept specifications are excluded.

## Open and drive

```sh
./scripts/start.sh roadster_rocket --api 4198
```

The launcher uses LUNCOSIM_BIN, an installed luncosim, or the neighboring checkout's
existing production binary. It loads an isolated keyboard profile and keeps the
simulation updating while unfocused. Shared wheels, tires, suspension, controls,
lighting, cameras and Ackermann equations resolve through lunco:// references.

The manual scenes possess the car and select **ChaseCamera** automatically.
Use the camera picker at the upper right for **DriverCamera** (forward hood view)
or the free/follow avatar camera. The speed HUD shows m/s, km/h and mph, plus
remaining air, pressure and battery charge.

| Keys | Function |
|---|---|
| W / S | Forward / reverse motor demand |
| A / D | Steering through a rate-limited Ackermann rack |
| Space | Wheel friction brakes |
| I | Rear forward gas boost |
| K | Inhibit forward boost; I + K cancel |
| J / L | Front side jets, yaw left / right |
| U | Corner-jet lift |
| O | Inhibit lift; U + O cancel; descend under gravity after release |

Hold to open a valve; release to close it. Rocket has forward, lift and yaw
jets. Thrust enables rear forward jets. Performance disables gas actuation.
There are no invented reverse/downward jets. All enabled jets share a finite
reservoir and available flow; the model has no airborne attitude controller.

Opening the folder in an existing application retains that application's keymap.
Use the launcher for JKLIUO, or select your own LUNCOSIM_CONFIG explicitly.

```sh
python3 scripts/control.py --camera chase
python3 scripts/control.py --camera driver
python3 scripts/control.py --throttle 0.15 --steer 0 --brake 0
python3 scripts/control.py --throttle 0 --brake 1
python3 scripts/control.py --status
```

API values persist until changed. Use one control producer at a time.
Ports include throttle/steer, brake/fan/boost/lift and thrust_x/y/z.
Fan suction can be enabled through the Ports inspector or --fan 1.

| Scene | Purpose |
|---|---|
| roadster_rocket | Default, one seat, ten nozzles, manual driving and lift/yaw |
| roadster_thrust | Two seats, rear boost only |
| roadster_track | Performance, motor driving without gas |
| roadster_launch | Automatic launch and SysML requirement evaluation |

## Physics and reusable calculations

- Two rear motors: **1 MW combined** study baseline, **1400 N·m combined**,
  provisional 8.4 reduction, 0.97 reduction efficiency.
- Explicit study mass budget: **1700 kg dry + 250 kg air = 1950 kg charged**.
  Native mass and inertia decrease as air leaves. The reported under-1700 kg
  target has unverified trim/fill conditions; 1950 kg is not a Tesla curb-mass claim.
- Native tires and suspension determine traction, rolling and wheel spin.
  Slip feedback limits excessive wheelspin. Steering has actuator response and
  a speed-dependent limit.
- Native physics alone integrates vehicle motion. Modelica reads measured
  velocity and shaft speed and supplies torque, forces and mass properties.
- Gas starts with **250 kg available air**, never 83 kg.
  At the 600 L / 20°C study point, the Modelica real-gas EOS gives
  **437.023 bar absolute**. Tank size and operating pressure are not asserted
  production specifications. See [pressure/volume analysis](references/gas-storage.md).
- [CompressedAir.mo](models/CompressedAir.mo) provides reusable pressure,
  density, heat-capacity and storage-sizing functions and a StorageSizing model.
  Both the sizing calculation and running tank use this same package.
- Finite gas mass, real-gas adiabatic tank cooling, valve response, battery
  energy, motor heat, 3D drag and ground-dependent fan sealing are modeled.
  Nozzle expansion remains an ideal approximation; discharge stops at the
  200 K study-domain boundary.

Unknown nozzle calibration, actual tank placement, dry/charged mass, tire data
and thermal behavior limit predictions. See [dynamics](references/dynamics.md).

## Artifacts

| File | Owns |
|---|---|
| [twin.toml](twin.toml) | Scenes, SysML sources and verification mapping |
| [roadster.sysml](requirements/roadster.sysml) | Parts, interfaces, trim structure, requirements, source and satisfy/verify links |
| [roadster.usda](vehicles/roadster.usda) | Rigid body, four raycast wheels, variants, cameras, HUD and native port wiring |
| [RoadsterVehicle.mo](models/RoadsterVehicle.mo) | Shared Ackermann composition, steering actuator, mass/inertia and jet moments |
| [RoadsterPowertrain.mo](models/RoadsterPowertrain.mo) | Motor envelope, slip control, energy, gas tank, drag and fan |
| [CompressedAir.mo](models/CompressedAir.mo) | Reusable real-gas thermodynamics and storage sizing |
| [launch.rhai](scenarios/tests/launch.rhai) | Physical observations and native SysML constraint evaluation |
| [roadster_ui.rhai](scenarios/roadster_ui.rhai) | Twin-scoped HUD presentation from engine facts |

## Reproduce checks

```sh
python3 scripts/run_launch.py
python3 scripts/check_controls.py --port 4198
python3 scripts/check_driving.py
```

The launch runs through production luncosim test and emits the exact runner
report and CSV trajectory. Its standing-start timing does not subtract rollout.
Passing the authored requirements is a study result, not independent confirmation
of Tesla's performance claims. [Validation evidence](results/README.md) records
the completed checks and boundaries.

Keyboard checks exercise native injected key events and reset the Twin for each
gas command. Driving checks operate the running window and observe native shaft
speed/angle, ground contact, steering, braking and the HUD. Timing uses simulation
ticks rather than wall time.

Optional EOS comparison: install CoolProp==8.0.0 and run
python3 scripts/check_gas_sizing.py --port 4198. The eight production Modelica
experiments agree with the reference within 1e-8 relative tolerance. CoolProp
is not a runtime dependency of this Twin.

Regenerate the authored geometry and wiring with python3 scripts/build_assets.py.
Maintain the generator when changing reproducible USD assets. No external car
mesh or texture is required.
