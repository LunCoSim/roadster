# Reproducing the Roadster gas report

`models/RoadsterColdGasBench.mo` reuses `RoadsterPowertrain` with fixed mechanical
observations. It does not integrate driving, collisions or airborne motion.
Initial fill is 250 kg dry air in 600 L at 20 °C, with no external service.
Identical one-second rear requests start at 0.5 s and 3 s. Inventory, fluid,
nozzle and heat-transfer choices are model assumptions, not identified Tesla
hardware parameters. The adjustable −130 °C study guard is not a hardware
rating, and neither pulse in this experiment reaches it.

Run the bench with native `RunExperiment`: class `RoadsterColdGasBench`,
`t_start:0`, `t_end:5`, `dt:0.01`, `tolerance:1e-6`, solver selection `auto`.
On 22 October 2026, experiment `69903f27-f243-4741-a204-eef9943fe5db` produced
505 native samples including event times. Source CID:
`bafkreifj3gvfgaqo42sr6obdgk6l2p4mci7imw3bi7hfyb43gcnw5vewii`.

| Model output | Result |
| --- | ---: |
| Initial absolute pressure | 437.02345 bar |
| Gas at 2.5 s | 140.23497 kg (56.09%) |
| Absolute pressure at 2.5 s | 111.58477 bar (25.53%) |
| Gas temperature at 2.5 s | −69.94929 °C |
| First rear impulse | 62.85866 kN·s |
| Second rear impulse | 21.80943 kN·s (34.70% of first) |

After a fresh run, call `roadster_report::gas_bench_report(experiment_id,2.5)`.
The read-only Rhai tool queries the completed native result and integrates
recorded thrust by the trapezoidal rule, including valve tails. It refuses
missing/downsampled trajectories. The native experiment remains the numerical
owner; this tool neither steps nor modifies the plant.

The bench has four native `PlotNode` scopes and a dynamic powertrain icon.
Report perspectives are authored under `scripting/policy/report_views.rhai`;
the engine supplies the registered plot/diagram hosts. Graph labels describe
quantities and units. When a historical bench curve accompanies a paused car,
label it as a gas bench: it is not that car's current telemetry.

These measurements show pressure/thrust fade with substantial gas remaining.
They do not prove an inevitable second-boost crash. A no-refill driving take
needs its own course qualification and measured failure cause.
