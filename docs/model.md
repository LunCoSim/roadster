# Model details

This page describes how the model works and where its values come from. Some values are assumptions; the [sources](../references/README.md), [specification audit](../references/spec-audit.md), and [input table](../references/assumptions.md) list the details.

## Physics ownership

| Layer | Responsibility |
|---|---|
| USD | Body compound colliders, roof envelope, wheel mounts, suspension, Earth gravity, lights, ramp and obstacle collision geometry, and native port wiring |
| Modelica | Motors, real-gas equation of state, air and energy balance, wall heat transfer, refill, variable mass/inertia, finite jets and moments, fan plenum/leakage, 3D aerodynamics, regeneration, steering driver/rack, and course measurements |
| Rhai | Input possession, HUD formatting/buttons, checkpoint sequencing, and acceptance observations |
| Shared Rust | Native integration/contact/wheel shafts, generic auxiliary actions/chords, and input/pointer transport |

The initial study mass is **1700 kg dry + 250 kg air = 1950 kg**. Two rear motors provide **1 MW and 1400 N·m combined**, with an assumed 8.4 reduction. Native wheel shafts determine wheel rotation. Full rack travel remains available at all speeds; keyboard steering builds more gradually at speed. Tire slip and the Coulomb cone determine actual cornering. Steering assistance can be disabled with the Modelica parameter `keyboard_steering_assistance=0` for analog commands.

The course pilot connects throttle, steering, jets, and fan requests inside the vehicle's single Modelica solve. Rhai selects ownership, sequences checkpoints, and services the native sticking brake's discrete apply/release requests using their retained producer identity. Manual takeover disables the course pilot.

At 600 L and 293.15 K, the reusable Modelica dry-air equation of state calculates **437.023 bar absolute** for 250 kg. Rocket retains 250 kg. Thrust's separate 200 L trim explicitly derives about 83.33 kg at the same initial density. Tank placement, nozzles, fan maps, aerodynamic coefficients, tire curves, and thermal coefficients remain study assumptions. See [gas storage](../references/gas-storage.md) and [dynamics](../references/dynamics.md).

## Force, mounting, and qualification

[Measured launch and force results and placement assumptions](../references/propulsion-analysis.md) include the rear mounting moment, balanced collective geometry, wheel-only Performance/Rocket baselines, and finite tank blowdown. The [plots](../results/propulsion-analysis.png) and [thruster layout](../results/thruster-layout.png) are generated from recorded observations and authored study geometry.

[Wheel contact and qualification](../references/wheel-contact.md) records the current raycast realization and its measured limits. Nominal driving, wall release, steering, ramp entry, moving jump, and all seven full-course SysML criteria have production evidence. The course uses an explicit flexible-skirt study assumption and continuous Modelica actuator coupling. It passes at 60 Hz and 10 Hz outer updates and in the graphical production host, with identical terminal physical evidence at tick 1771 (29.52 simulation seconds). Roof-overload and gentle-contact controls pass nine and four checks; suspension travel passes three. Set `LUNCOSIM_BIN` to select a production build explicitly when running the checks.

## Fans, USD, and battery

The fan component contains its geometry probes and seal/plenum calculations. The drivetrain consumes its force and electrical demand, and the chassis receives its moment. The assembly is flattened into one Modelica solve. These are simulation queries, not added Tesla sensor hardware, and have no visible markers. See the [component boundary](../references/dynamics.md#adhesion-component-boundary).

See [USD and Omniverse contracts](../references/usd-omniverse.md) for interoperability details. The chassis and wheel attachments use standard schema contracts; Omniverse execution has not been validated. Modelica, Rhai, and custom rendering still require their runtime integrations.

The study uses **120 kWh nominal**, inferred from reported energy above 100 kWh and range above 300 miles, with explicit 220 Wh/km and 90% sizing assumptions. It is editable as `inputs:battery_capacity_kwh`. Modelica adjusts energy, mass, and inertia from the 120 kWh / 1700 kg dry reference; the pack is counted once. This value is an assumption, not a manufacturer-issued specification. See [battery sources and derivation](../references/battery-study.md). An automated sensitivity check is available as `python3 scripts/check_battery_study.py --binary /path/to/luncosim`.
