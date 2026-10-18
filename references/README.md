# Roadster source register

Research date: **2026-10-18**. Scope: redesigned Roadster revealed on **2026-10-15**.
Public statements are manufacturer claims, not independently measured performance.

| ID | Source | Retrieval / use |
|---|---|---|
| S01 | [Tesla: updated Roadster](https://www.tesla.com/en_GB/roadster) | Current indexed page retrieved October 18. Primary baseline for trim architecture, seating, styling and Thrust's sub-second 0–60 mph claim. Direct HTTP requests return 403; the web reader exposes mostly footnotes, but search indexing returns the current sections. Lowercase locale and some US search results still show the old page. |
| S02 | [Tesla: Roadster Event](https://www.youtube.com/live/qt5p-_tE8d0) | Official October 15 reveal. At ~12:04, transcript mirrors reproduce two vessels / 600 L / ~250 kg total / ten nozzles. Direct audio/captions were not independently transcribed; see spec-audit.md. |
| S03 | [Tesla: configuration post](https://x.com/Tesla/status/2110905588402295283) | Primary post located through linked coverage; X returns 403. Detailed acceleration/range figures remain **reported, primary text unverified**. |
| S04 | [Tesla: rollout clarification](https://x.com/Tesla/status/2110964095696723984) | Primary post located; X returns 403. Keep standing-start time separate from rollout time. |
| S05 | [Hagerty: interview with Lars Moravy](https://www.youtube.com/watch?v=22rvpUecLts) | Public video description retrieved again directly from YouTube HTML on October 18. Confirms two rear motors, over 1 MW combined, 1400 N·m, a 200 L nitrogen tank for Thrust and another 400 L for Rocket. Full video transcript was not retrieved; pressure rating, mass target and reduction ratio remain reported rather than directly transcribed. Hagerty's article returned 403. |
| S06 | [NIST: exact unit conversions](https://www.nist.gov/pml/us-surveyfoot/revised-unit-conversion-factors) | International mile = 1609.344 m. Thus 60 mph = 26.8224 m/s; 230 mph = 102.8192 m/s; 300 mi = 482803.2 m. |
| S07 | [NASA Glenn: mass-flow choking](https://www.grc.nasa.gov/www/k-12/BGP/mflchk.html), [isentropic flow](https://www.grc.nasa.gov/www/k-12/airplane/isentrop.html), [rocket thrust](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/rocket-thrust/) | Generic compressible-flow and momentum equations used by the study gas model. No Tesla-specific dimensions or calibration are inferred from these references. |
| S08 | [NIST: Lemmon et al. dry-air EOS](https://www.nist.gov/publications/thermodynamic-properties-air-and-mixtures-nitrogen-argon-and-oxygen-60-2000-k-pressures), [CoolProp Air](https://coolprop.org/fluid_properties/fluids/Air.html) | Primary EOS publication and implementation documentation. Modelica pressure, density, heat capacity and temperature derivative checked against CoolProp 8.0.0. |
| S09 | [CoolProp nitrogen EOS](https://coolprop.org/fluid_properties/fluids/Nitrogen.html) | Reference comparison for the nitrogen described in S05. The active study uses dry air. |
| S10 | [MotorTrend first-hand walkaround](https://www.motortrend.com/news/first-look-2028-tesla-roadster-performance-thrust-rocket) and [engineering interview](https://www.youtube.com/watch?v=6D5MlPZQFOw) | Firsthand engineer walkaround, rechecked October 18: four rear extractors; 200 + 400 L Rocket storage; target 1700 kg with unspecified trim/fill; battery above 100 kWh, exact value withheld. Exact maps, geometry and photometry remain assumptions. |
| U01 | User input in this conversation | **250 kg available air mass**, not vehicle mass, not tank volume, and not 83 kg. Applied directly to the study gas inventory. |
| D01 | [Exotic Car Trends: live reveal source index](https://www.exoticcartrends.com/news/tesla-roadster-reveal-2026/) | Discovery of S02–S05 and official reveal photographs. Secondary reporting only. |
| D02 | [TeslaNorth: Moravy interview summary](https://teslanorth.com/2026/10/16/tesla-roadster-moravy-hagerty-engineering-interview/) | Secondary lead for the under-1700 kg target, 8.4 reduction and 10000 psi tank rating. These have not been directly transcribed from the primary interview here. |
| D03 | [ElectronMotion: thruster engineering summary](https://electronmotion.com/2026/10/17/tesla-roadster-thrusters/) | Secondary lead for tank configuration and nozzle arrangement. Coordinates, areas and lever arms in this model remain study assumptions. |

See the [2026-10-18 specification audit](spec-audit.md) for the ten-nozzle count,
200/400 L tank split, conflicting 2 x 250 kg report and remaining model deviations.

## Accepted current primary facts

S01 distinguishes Performance, Thrust and Rocket. Performance and Thrust seat two;
Rocket seats one. Performance uses active aero and suction fans. Thrust adds rear
cold-gas propulsion and claims 0–60 mph in less than one second. Rocket adds
perimeter thrusters for translation and rotation; Tesla excludes public-road use.
The current visual description specifies white bodywork, gold-tinted glazing,
thin wheel spokes, concealed headlights and a full-width rear lamp. The page
qualifies its displayed specifications as Thrust augment specifications.

## Reported figures awaiting primary inspection

Coverage links S03 to 0–60 targets of <1.6 s (Performance), <0.9 s (Thrust),
<0.59 s (Rocket), range >300 mi, and Rocket speed >230 mph. Coverage links S04
to a 0.81 s demonstration and 0.67 s after subtracting rollout. These are recorded
as leads, **not a verified production specification, measured model result, or
an automatic acceptance target**. Range, top speed, pricing and production date
are not validated by this Twin.

The 2017 figures (1.9 s, 620 mi, 200 kWh, four seats, three-motor AWD, 10,000 N·m)
belong to an earlier design. None supplies a parameter for the current study.
Dimensions, dry/charged mass, pack energy and force curves remain assumptions;
see [assumptions](assumptions.md).

The local `.scratch/roadster-reference.jpg` was inspected for silhouette only.
It is a Tesla reveal image hosted by D01, not redistributed as a project asset.
The delivered mesh is original procedural study geometry, not Tesla CAD.
