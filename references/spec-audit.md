# Hardware and specification audit — 2026-10-18

Scope: October 15 redesign, with the default **Rocket** study. The 2017 concept's
three-motor AWD, four seats and 200 kWh pack do not describe this configuration.
See the [source register](README.md) for retrieval limits.

## Tanks and ten thrusters

- **S05, directly retrieved Hagerty engineering-interview description:** Thrust
  has a 200 L rear nitrogen vessel and four rear nozzles. Rocket adds a 400 L
  vessel in place of the passenger seat and six nozzles: four corners and two sides.
- **S02 reveal, approximately 12:04:** the reproduced speech says two vessels,
  **600 L total and about 250 kg total gas**, feeding ten nozzles. The
  [timestamped primary recording](https://www.youtube.com/watch?v=qt5p-_tE8d0&t=724)
  is linked by two transcript mirrors: [archive](https://www.elonmuskarchive.org/video/tesla-roadster-event-2026-10-16)
  and [timestamp index](https://www.tesla-roadster.info/unveiling). Direct YouTube
  captions were unavailable here; this is transcript corroboration, not a fresh
  independent audio transcription. Original [Space.com event reporting](https://www.space.com/technology/spacex-thrusters-just-made-a-tesla-roadster-fly-and-elon-musks-car-is-still-out-there-in-space)
  independently attributes the same aggregate figures to Moravy.
- A [Tom's Guide launch article](https://www.tomsguide.com/vehicle-tech/evs/elon-musk-just-unveiled-a-flying-car-watch-the-tesla-roadsters-incredible-launch-as-it-happened)
  says **each** vessel has 600 L / 250 kg. That conflicts with S05's explicit
  unequal volumes and the reproduced reveal statement. It is not used as a model input.

**Conclusion:** retain **250 kg across 200 + 400 L**, not 2 × 250 kg.
At the study's uniform density/temperature this calculates 83.333 kg in the rear
vessel plus 166.667 kg in the cabin vessel. These individual masses are derived,
not quoted manufacturer capacities. The manifold approximation does not resolve
separate vessel temperatures, pipe restrictions or their independent emptying.

The Rocket USD instantiates **4 rear + 4 downward + 2 nose-side = 10** nozzle
objects. Four rear forces share forward boost; corners generate lift/pitch/roll;
the two nose-side jets generate yaw. Counts and functions match S05/S10; exact
coordinates, lever arms, areas and flow allocation are uncalibrated. A render
plume is not an additional thruster. No combustion or rocket fuel is modeled.

## Specification-to-model comparison

| Item | Public evidence | Current model / assessment |
|---|---|---|
| Rear-drive motors | S05: two rear motors, over 1 MW and 1400 N·m combined | Two native driven rear shafts; 1 MW / 1400 N·m lower-bound baseline, not each motor. |
| Transmission ratio | 8.4 reported in interview summaries; direct transcription unavailable | 8.4, provisional. Efficiencies and torque/slip maps are assumptions. |
| Vehicle mass | S10 firsthand interview: target 1700 kg; trim/fill unspecified | 1700 kg **dry study assumption**, plus 250 kg gas = 1950 kg. Not a confirmed Rocket curb mass. |
| Battery | S10 says substantially above 100 kWh; exact value withheld | **120 kWh study assumption**, with 110–140 kWh sensitivity. Modelica derives sizing, mass/inertia changes and energy bookkeeping; [sources and inference](battery-study.md). Exact capacity remains undisclosed. |
| Gas species | S05 names nitrogen; reveal calls it air | Active EOS is dry air, following the requested study. Nitrogen comparison is documented; the two fluids are not interchangeable. |
| Storage pressure | S10 describes vessel rating up to 10000 psi | Rating is not operating pressure. 250 kg dry air / 600 L / 293.15 K solves to 437.023 bar absolute. |
| Fans | S10: four rear extractors and a skirted underside | Four visible recessed rotors, measured seal; 40 kN / 80 kW map is provisional. |
| Suspension | S10: adjustable spool-valve dampers and track ride/stiffness changes | Fixed prepared-track spring/damper; no adaptive suspension or ride-height controller. |
| Active aero | S10 describes moving surfaces | Effective body-axis drag/lift model and airbrake, not a measured full aero map. |
| Seating / trims | S01/S05: Performance and Thrust two seats; Rocket one | Rocket hides passenger seat; 10 jets. Performance has no jets; Thrust four rear jets. |
| Thrust trim storage | S05: one 200 L vessel | Thrust now composes a 200 L rear vessel without cabin storage. Modelica derives 83.33 kg at the Rocket study density; this mass is an inference. Rocket keeps 600 L / 250 kg. |
| Acceleration | Reveal demo 0.81 s; published targets and rollout conventions differ | Strict ≤0.59 s is the user's standing-start acceptance target. The study's measured launch is documented in [propulsion analysis](propulsion-analysis.md); it does not validate a Tesla production claim. |
| Dimensions / tires / inertia | No checked manufacturer drawing or tire curves | All geometry, wheelbase, radius, masses, inertias, friction and slip curves remain assumptions in assumptions.md. |
| Thermal equipment | No directly checked tank thermal-management design | Passive wall exchange and adjustable −130 °C study guard; this is not a verified valve rating. External refill equipment is explicitly test service. See discharge-limits.md. |
| Light photometry | No checked manufacturer beam measurements | Modelica-focused 3000 lm per beam; renderer input compensates its angular attenuation. Study optics only. |
| Rotation losses | No measured rotational aerodynamic coefficients | Native constant angular damping 0.5 remains a study approximation; jet release does not automatically counterfire or level the car. |
| Range / top speed / charging | Manufacturer targets, no full duty-cycle validation | Not verified by the current acceptance suite. |

## Model ownership and verification

`RoadsterPowertrain.mo` owns the two volume parameters, total real-gas state and
calculated per-vessel inventory. `RoadsterVehicle.mo` exposes those quantities;
USD supplies editable parameters and the native mass/inertia connections.
SysML now identifies the runner as Rocket and records both storage volumes.
Launch seating inspection counts available seats, excluding the hidden passenger
mesh; its Rocket requirement is one seat. Counting all instantiated mesh names
had previously allowed a hidden passenger seat to satisfy the two-seat check.
No Tesla-specific Rust was added.

The native hardware check inspects instantiated nozzle paths, solved volumes,
individual gas inventories and vehicle mass. Separate moving-jump, input and
course checks exercise physical takeoff, injected controls and finite-actuator
completion. The source and assumption columns above limit what these checks
establish; their machine-readable run outputs are transient and ignored.

## Force and placement follow-up

The [propulsion analysis](propulsion-analysis.md) records the revised mount
positions, clearance, complete cross-product moments, fixed lift-valve trim,
per-bank forces and thermal limits. These are explicit study choices, not CAD
measurements. F now toggles fans; Q/E selects left/right lift banks and R/C pitch.
