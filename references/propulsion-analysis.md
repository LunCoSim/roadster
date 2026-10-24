# Roadster propulsion and mounting analysis

Current configuration: the temperature trip is now the live Celsius input
`discharge_cutoff_c`, default −130 °C. The 200 K results below are retained
measurements of the prior configuration. They must not be used to claim a
half-inventory limit for the current model. See [discharge limits](discharge-limits.md)
and the native Celsius bench result described there.

2026-10-18. Results are for this engineering study, not a calibrated Tesla car.
All forces, gas states, moment arms, sizing and recorded rear impulse are computed
by Modelica. Native LunCoSim integrates body/contact/wheel motion. Python plots
saved observations only.

## Inventory: 250 kg total

The reproduced reveal statement gives two vessels, **600 L total / approximately
250 kg gas / ten nozzles**; the [engineering-interview description](https://www.youtube.com/watch?v=22rvpUecLts)
specifies 200 L behind the seats and 400 L replacing Rocket's passenger seat.
See [the source audit](spec-audit.md) for direct-retrieval limits and the conflicting
secondary claim of 250 kg per vessel. There is no basis here for a 500 kg load.

The active dry-air EOS gives 437.023 bar absolute at 293.15 K. A shared density
and temperature partitions inventory into 83.333 + 166.667 kg. Nitrogen is named
in the engineering interview; its different EOS is compared in gas-storage.md.
This is not proof of Tesla's operating pressure or actual plumbing state.

## Wheels and rear boost

The current collision-backed rig records **0.7465 s** with rear boost and does
not pass the 0.59 s requirement. Its motor-only gate also fails. These are open
contact/driveline validation failures, not new Tesla specifications.

The following standing-start measurements belong to the earlier raycast-wheel
configuration. They are retained as a comparison baseline, without subtracting
rollout. They do not validate the current collision-backed suspension:

| Fixture | Initial operating mass | Fans | Rear boost | Time |
|---|---:|---|---|---:|
| Performance study | 1700 kg | On | None | **1.581 s** |
| Rocket study | 1950 kg | On | None | **1.786 s** |
| Rocket study | 1950 kg, falling as gas leaves | On | Full command | **0.516 s** |

Both wheel-only runs use the same two rear motors: combined 1 MW / 1400 N·m,
8.4 reduction, finite shaft/contact/slip dynamics. Neither uses air thrust.
The Performance result must not be treated as an independently verified Tesla
<1.6 s specification: trim/fill mass, tire map and hardware details remain uncertain.

`LaunchSizing.mo` provides a reusable first-order mean-force budget:

- 60 mph = 26.8224 m/s; 0.59 s requires 45.4617 m/s² mean acceleration.
- At constant initial 1950 kg, this is 88.650 kN mean **net** force.
- The 1.78564 s wheel-only observation corresponds to 29.291 kN mean net force.
- Subtracting gives about **59.359 kN additional mean boost** as a sizing estimate.

This subtraction assumes the same wheel-force history and constant initial mass.
Actual load transfer, slip, drag, decreasing mass and tank blowdown are coupled;
the native launch measurement is the acceptance result. With the actual rear
mounting moment included, it passes the user's **≤0.59 s** gate at **0.515948 s**.

Modelica separately integrates rear impulse while the acceptance driver marks
the launch measurement window. It reports **80.273 kN mean rear thrust** over
**0.516667 s** (the sampled window, distinct from interpolated threshold timing).
The existing assumed 0.002 m² aggregate throat already supplies enough thrust;
no extra thrust multiplier, trajectory write or time-based speed correction was
added to hit the target. Nozzle area and expansion efficiency remain uncalibrated.

## Bottom and side force

Separate bank runs start from identical 250 kg / 293.15 K tanks, with the car
in native free flight. Valves take 25 ms to respond; pressure/temperature decline
as mass exits. All banks share one finite flow budget.

| Bank | Hypothetical fully open force at initial frozen tank state | Measured peak with valve response and blowdown |
|---|---:|---:|
| Four rear jets | 130.757 kN total | **110.217 kN total** |
| Four bottom jets, collective trim | 97.184 kN total | **84.692 kN total** |
| One of two opposed nose-side jets | 5.230 kN | **5.156 kN** |

The initial vehicle weight is 19.123 kN. The frozen-state collective envelope
is about 5.08 times that weight; approximately 19.7% of full trimmed collective
would balance weight in the ideal aligned, fan-off state. Full-command lift has
40.03 m/s² nominal net acceleration before valve lag, blowdown and aerodynamic
losses. This does not imply sustained hovering at that force.

At the initial state, a nose-side jet's 1.90 m yaw arm gives about 9.94 kN·m
and **2.80 rad/s²** nominal yaw acceleration with the configured inertia.
Its 0.04 m vertical offset from the assumed COM also creates a small real roll
moment. Opposed side nozzles select force direction; there is no invented
reverse/downward propulsion bank.

**Thermal limit:** in these full-command runs the study's 200 K guard trips at
about 1.10 s for rear boost and 1.47 s for collective lift, leaving approximately
136 kg stored. Side firing for 2.5 s leaves approximately 231.3 kg at 277 K.
The loaded 250 kg is not all immediately usable under this conservative guard.
The guard, wall heat transfer and dry-air nozzle closure are study assumptions,
not Tesla thermal-management data or a universal freezing limit.

## Placement and wrench calculation

Primary [walkaround/reveal photographs](https://www.motortrend.com/news/first-look-2028-tesla-roadster-performance-thrust-rocket/photos)
show four rear mouths below the tail lamp and above the rear extraction fans;
the flight car shows downward nozzles behind the wheels. These establish topology,
not accurate dimensions. The current locations below are explicit study coordinates.

Body coordinates: +X right, +Y up, **−Z forward**. Assumed native COM is
(0, −0.14, 0) m.

| Nozzles | Body position in metres | Exhaust | Reaction on car |
|---|---|---|---|
| Rear ×4 | X = −0.55, −0.20, 0.20, 0.55; Y = −0.14; Z = 2.30 | +Z | −Z |
| Front lift ×2 | X = ±0.80; Y = −0.32; Z = −0.90 | −Y | +Y |
| Rear lift ×2 | X = ±0.80; Y = −0.32; Z = 1.85 | −Y | +Y |
| Nose side ×2 | X = ±0.96; Y = −0.10; Z = −1.90 | Outward ±X | Opposite ±X |

The earlier lift mouths overlapped the tire swept envelopes. Moving them behind
the corresponding wheels leaves about **63 mm axial clearance** between each
assumed 72 mm radius nozzle and the 340 mm tire radius envelope. Rear mouths
were moved below the lamp; each external plume starts at its nozzle mouth. Exact Tesla
coordinates, nozzle dimensions and COM remain unavailable.

`ThrusterMount.mo` calculates **moment = (mount − COM) × force**. Previously the
rear bank's height moment and the nose jet's small roll moment were omitted.
The former rear force line was 0.12 m above COM and caused a large nose-down
moment in free flight. The study now places the rear mouths at Y = −0.14 m,
aligning the combined forward force with the nominal complete-car COM.
This is an explicit design assumption, not a newly verified Tesla dimension.
`ThrusterMount` still calculates all real moments; there is no attitude clamp,
automatic pitch stabilizer or flight-dependent control remapping. The chassis
wrench accounts for the separate suspension/wheel bodies and its shifted COM.

The lift front/rear arms are 0.90 / 1.85 m. Fixed rear valve gain
0.90/1.85 = **0.486486** balances collective pitch. K and each Q/E side bank use
that same gain at every altitude; R/C produce opposite pitch moments. This is
an explicit geometric mixer, not body-rate feedback or automatic leveling.
Advanced individual corner keys retain these configured valve gains.

`MOUNTS` in `scripts/study_geometry.py` is the single offline authoring data owner
for nozzle geometry, native COM and USD Modelica mount parameters. The resulting
USD remains inspectable/editable. `check_hardware.py` reads the composed geometry
and parameters and checks them against the authored layout and native COM;
`moving_jump.json` checks the resulting physical lift moment in motion.

## Reproduction and evidence

- `run_motor_launch.py --trim performance` / default Rocket: wheel-only fixtures.
- `run_launch.py`: SysML launch gate, timing and Modelica rear impulse.
- `author_force_checks.py --port 4198`: typed USD document operations create force
  fixtures and the Performance motor fixture.
- `run_scene_check.py roadster_force_rear ROADSTER_FORCE_REAR --ticks 250`;
  substitute `lift/LIFT` or `side/SIDE` for other banks.
- `check_hardware.py` and `check_controls.py`: native layout and key checks.
- Optional matplotlib: `plot_propulsion.py` renders the saved observations.

See `results/propulsion-analysis.json`, `force_rear/lift/side.json`, the
[force and launch plots](../results/propulsion-analysis.png), and the
[dimensioned layout](../results/thruster-layout.png).
