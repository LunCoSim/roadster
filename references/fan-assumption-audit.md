# Roadster fan and assumption audit — 24 October 2026

Status: engineering review. The fan baseline is an uncalibrated study, not a
recovered Tesla specification. The proposed automatic change to a full-body
9 m² plenum was withdrawn. No fan equation or default has been changed by this
audit. The short-course/right-camera takes retain their exact source snapshots.

## What the sources establish

- [Tesla's current Roadster page](https://www.tesla.com/roadster?redirect=no)
  describes a fan/ground-sealing system capable of a stationary upside-down
  hold. That is a manufacturer claim, not an independently measured force.
- [MotorTrend's firsthand engineering walkaround](https://www.motortrend.com/news/first-look-2028-tesla-roadster-performance-thrust-rocket)
  describes four rear extractors and a shroud around the battery-pack edges.
  It does not supply the sealed outline, pressure distribution or fan map.
- [NASA's pressure-force explanation](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/aerodynamic-forces/)
  gives the surface-pressure integral. `F = Δp A` is the uniform-pressure
  approximation over a specified sealed area, not an instruction to multiply
  by the exterior bounding rectangle.
- [AMCA Standard 99-25](https://www.amca.org/assets/resources/public/resources/ansi-amca-99-25-standards-handbook.pdf),
  definitions on printed page 19, distinguishes air power, input power,
  efficiency and performance at an operating point. Air power depends on
  pressure and volume flow, with a compressibility coefficient. A motor's
  maximum power alone does not define its fan curve.
- [McMurtry's own production description](https://mcmurtry.com/mcmurtry-speirling-production-form/)
  provides an independent example of sealed-underbody suction and a published
  zero-speed downforce claim. It establishes that the mechanism is practical;
  its ratings cannot calibrate Tesla's fans.

The AMCA PDF was downloaded from its official URL and its printed page 19
definitions checked with `pdftotext`. Exact Tesla fan power and the
reported 4,700 kg display figure remain leads awaiting primary-video inspection.
They are not used as verified calibration data here.

## Area: three different geometric quantities

1. The native authored `/World/Roadster/Body/Skin` mesh has 25,032 vertices.
   `QueryUsdPrim` readback gives 4.5 m length and 1.9900000095 m width, so its
   **bounding rectangle is 8.955000043 m²**. These are our procedural geometry,
   not a checked Tesla dimension drawing. The tapered shell does not fill that
   whole rectangle.
2. Clearance probes span 2.2 × 1.2 m = **2.64 m²**. They observe road clearance;
   their rectangle is not a measurement of a continuous skirt boundary.
3. `BatteryStudy` uses a 2.5 × 1.5 m = **3.75 m²** mass-distribution proxy.
   Its comments explicitly say this is not a manufacturer drawing. It cannot
   be promoted to a measured plenum area either.

Thus the user's approximately 9 m² footprint calculation is consistent with
our exterior mesh. It does **not** establish the evacuated floor area. Neither
2 m² nor the full rectangle has been independently established for Tesla.

## Parameter-by-parameter review

| Parameter in the present model | Rationale that can be defended | What is missing / disposition |
| --- | --- | --- |
| Plenum area, 2 m² | A hypothetical local sealed region can be smaller than the exterior footprint. | No checked sealed outline supports this particular value. Retain only as an explicitly unverified comparison baseline; test alternatives. |
| Skirt perimeter, 6 m | Consistent with a hypothetical 2 × 1 m rectangle. | That rectangle was not measured. It is not a retrospective proof of the chosen area. Area and perimeter must eventually come from the same authored sealed outline. |
| Pressure limit, 20 kPa | Pressure difference produces force; 20 kPa × 2 m² gives 40 kN with a perfect seal. | No verified Tesla pressure map supports 20 kPa. Treat it as a fan-map input, not a discovered value. |
| 80 kW maximum / 4 kW idle | A finite electrical limit and losses are necessary. | The exact ratings lack checked primary calibration here. Reported 20 kW-per-fan coverage is a research lead, not sufficient evidence. |
| 0.65 air efficiency / 0.9 rotor efficiency | Both are dimensionless efficiencies below one; the power balance includes losses. | They are assumed constants, not measured efficiency maps. Off-design and compressibility effects need qualification. |
| 0.003 m² closed leak area | Represents residual leakage when the skirt is nominally closed. At 6 m perimeter it is equivalent to a uniform 0.5 mm slit. | No measured seal gap or discharge coefficient supports it. It strongly controls closed-state flow and power. |
| 0.40 m vehicle skirt reach | Used by the current course's geometric contact envelope. | No checked Roadster skirt-extension measurement supports it. It was selected for this authored ramp and is not a hardware dimension. |
| 0.04 m seal transition | Smooths degradation when clearance exceeds reach. | The Gaussian seal curve is a heuristic. It is not a measured seal response. |
| `suction_force = Δp A seal` | Reduces force when the geometry observations indicate a lost seal. | `seal` also changes the leak area, hence pressure. Multiplying force again may double-count loss unless it independently represents covered area. This closure requires validation. Do not present its near-zero open result as an independently predicted Tesla property. |
| 15,000 rpm / 0.04 kg m² / 0.15 s rotor response | Finite spin-up and power-limited rotor acceleration are physically motivated. | No measured rotor dimensions, inertia or speed response supports the exact numbers. |
| 1.225 kg/m³ air / 101325 Pa ambient | Standard near-sea-level reference conditions. | They are not observed event weather; 1.225 kg/m³ corresponds approximately to 15 °C, not the tank's 20 °C starting condition. |
| Four-corner minimum seal and fixed force centre | A reduced common-plenum approximation can use corner clearance observations. | It cannot resolve distributed pressure, local leaks, changing centre of pressure or detailed curtain contact. |

At 20 kPa the footprint substitution alone would predict approximately
179 kN, versus 40 kN for 2 m². That change must not be made solely to agree
with a footprint calculation or to improve a stunt.

## What the upside-down claim can constrain

For a stationary car with jets off, suction must at least balance weight.
At the study's assumed 1,950 kg operating mass, this is about **19.1 kN**.
That constrains the pressure-area product, not area and pressure separately:

- If the sealed area were 2 m², the minimum uniform difference is about 9.6 kPa.
- If it were 8.955 m², the corresponding minimum is about 2.14 kPa.

These are conditional calculations, not measured fan operating points. No
centripetal load, safety margin or structural qualification is inferred.
A fit to the upside-down stunt alone cannot identify the real fan design.

## Native sensitivity runs

Four `RunExperiment` runs used the same `RoadsterFanSealBench` source and native
solver, from 0 to 9 s with 0.01 s output and 1e-6 tolerance. Each completed with
903 recorded samples. The Twin's read-only `fan_seal_report` selected the 4 s
sealed state and 8 s open state without interpolation. Parameter overrides are
frozen in each experiment definition; the source CID is shared:
`bafkreie5okbvj3nlukwfqqv2tztaascf4jhgwgv63hehh4vs4pd74lyu4u`.

| Illustrative configuration | Area / perimeter | Pressure limit | Sealed suction | Sealed electrical power | Open electrical power |
| --- | --- | ---: | ---: | ---: | ---: |
| Existing baseline | 2 m² / 6 m | 20 kPa | 40.00 kN | 20.68 kW | 80 kW |
| Battery mass-distribution proxy | 3.75 m² / 8 m | 20 kPa | 75.00 kN | 20.68 kW | 80 kW |
| Exterior bounding rectangle | 8.955 m² / 12.98 m | 20 kPa | 179.10 kN | 20.68 kW | 80 kW |
| Same-force counterexample | 8.955 m² / 12.98 m | 4.4668 kPa | 40.00 kN | 5.76 kW | 80 kW |

These are hypothetical configurations, not a probability range for Tesla.
They demonstrate non-uniqueness: matching suction force does not identify the
area, pressure, electrical demand or actual hardware. Closed electrical demand
is identical in the first three because the model holds the same closed leak
area and pressure; that modelling choice needs its own evidence.

The original open/closed power ratio of 3.87 becomes 13.88 in the fourth case.
Thus “power quadruples” is not a general result; it depends on the selected map.
The baseline open pressure is still 1.18 kPa, which gives 2.36 kN before the
additional seal multiplier. Its final approximately zero suction therefore
depends strongly on that heuristic, not just the pressure/flow equations.

Exact run IDs, in table order:

- `4c269dfb-fff7-4fdc-8aa2-26ffa1268229`
- `d46df94a-8323-4156-a49b-4a21988347d7`
- `69cdbf77-6f07-47bd-b334-284fae9f8398`
- `8b429874-8795-4166-af31-f6a0c79bd079`

The campaign retains acknowledgements, complete run status, parameter definitions
and native report output in `renders/fan_area_audit_runs.json`. No source default
was changed for these sweeps. They are standalone fan tests, not qualification
of those alternative configurations on the coupled car.

## Other assumptions that affect the report

| Item | Current evidence and rationale | Presentation consequence |
| --- | --- | --- |
| 1,700 kg dry + 250 kg gas | 1,700 kg is a reported vehicle mass target with unspecified trim/fill. Treating it as dry and adding all gas is our assumption; it may double-count inventory if the target already includes it. | Say "our two-tonne car"; label 1950 kg assumed. Do not call it a confirmed Rocket curb mass. |
| 600 L gas space | The firsthand walkaround describes a 200 L vessel plus a second twice as large. | Supported architecture/volume report; not independent inspection of usable internal volume. |
| 250 kg inventory | User input plus reproduced reveal reporting; no freshly checked primary audio in this audit. | A study initial condition until the primary statement is inspected. |
| Dry air | The firsthand engineering article names nitrogen. | Air is a modelling choice, not a verified propellant specification. A nitrogen sensitivity check is needed before presenting exact Tesla performance predictions. |
| 120 kWh battery | The firsthand source only establishes substantially above 100 kWh. | 120 kWh and the 110–140 kWh study range remain assumptions, not a uniquely inferred secret specification. |
| 0.59 s launch | A reported target used to size this study; the reveal demonstration and rollout conventions are distinct. | Label target and measured model time separately. Matching a target is a fit, not complete validation. |
| Nozzle throat / efficiency / valve lag | 20 cm², 0.85 and 25 ms are uncalibrated inputs. | Net force can be constrained conditionally on mass and acceleration; these hardware quantities cannot be uniquely recovered from one launch time. |
| Tire, suspension, inertia and aero maps | Study geometry and plausible reduced laws; no measured tire curves, inertia tensor or aerodynamic map. | Motion is computed by the model; reproducing a stunt does not establish all handling or hardware loads. Wheel/contact acceptance remains with optimization. |
| Gas thermal exchange / discharge guard | Lumped wall/heat-transfer assumptions and an adjustable −130 °C guard; no certified component-temperature rating. | Do not describe the guard as a known hardware limit or universal usable-air fraction. Qualify the low-temperature gas calculation against its verified range. |
| Two-burst result | Native experiment gives 56% mass / 26% pressure after pulse one and 35% second impulse, conditional on the chosen gas plant and thermal model. | A result of this model; not a measured Tesla repeated-stunt limit. |

## Required disposition

Keep the established baseline and its provenance while doing native parameter
sweeps. Do not replace one unsupported point estimate with another. The video
can explain the fan mechanism and seal sensitivity, but exact numerical fan
performance must be identified as an illustrative configuration until calibrated.
Before promoting a new parameter set, retain its source/derivation, test the
fan operating point and then verify its coupled vehicle behaviour. A stronger
fan value is not a reason to retune suspension or change physics to make a shot pass.
