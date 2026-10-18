# Engineering inputs and limits

This is an executable study, not Tesla CAD or production calibration.

| Input | Baseline | Provenance / limit |
|---|---:|---|
| Dry vehicle mass | 1700 kg | Study interpretation of the reported under-1700 kg target. Published trim and fill state are unverified. Includes wheels and empty gas hardware; no separate pressure-vessel mass estimate. |
| Available air | **250 kg** | User-specified starting inventory, used directly without scaling to 83 kg. |
| Charged Thrust / Rocket mass | **1950 kg initially** | Dry mass + air. Native mass decreases during discharge. Performance uses 1700 kg dry mass. |
| Chassis USD mass | 1604 kg | Native raycast wheels add 4 × 24 kg. Modelica supplies the complete operating mass. |
| Motor topology / combined ratings | Two rear motors, 1 MW / 1400 N·m | S05 describes rear drive, over 1 MW and 1400 N·m. The model uses a conservative 1 MW baseline, not 1 MW per motor. |
| Reduction / efficiency | 8.4 / 0.97 | Ratio reported in interview summaries, primary transcript unverified. Combined wheel limit 11407.2 N·m / 970 kW before slip control. |
| Battery / efficiency | 100 kWh / 0.93 | Assumptions; 90% initial SOC, 2% reserve. No cell or inverter map. |
| Body L/W/H | 4.50 / 1.94 / about 1.20 m | Original procedural geometry; no dimension drawing. |
| Wheelbase / track / tire radius | 2.75 / 1.72 / 0.34 m | Study geometry; front/rear tire width 0.25/0.30 m. |
| Wheel mass / rotational inertia | 24 kg / 1.4 kg·m² each | Complete rotating assembly assumption. |
| Tire friction / longitudinal stiffness | 1.4 / 30000 N·s/m | Ideal dry surface; no measured supplier curves. |
| Slip-angle speed floor | 8 m/s | Existing native tire regularization; steady-state curve is uncalibrated below this speed. Bounds its lateral force derivative at the 1/60 s step, avoiding brake/contact sign chatter with suction enabled. The final native turn-and-brake observation settled below 1e-9 m/s; low-speed cornering remains a regularized approximation. |
| Suspension spring / damper / rest length | 300000 N/m / 14000 N·s/m / 0.43 m | Prepared track setting per wheel; raised to preserve body clearance at the ramp transition. |
| Steering actuator | 0.12 s, 2 command units/s | Max wheel angle 0.45 rad, no speed angle cap. Modelica keyboard driver buildup 1.8/(1+(v/20)^2) units/s, return 2.8 units/s. Full rack travel remains available. |
| Slip control | 0.12 target, gain 30 | Uses measured wheel and body speed; no separate wheel animation. |
| Drag area / density / rolling coefficient | 0.62 m² / 1.225 kg/m³ / 0.012 | Body-axis drag: forward 0.62, side 4.5, vertical 8.0 m²; airbrake 1.1 m²; lift area 7.9 m². Dissipative 3D drag and smoothed ground rolling resistance. |
| Fan vacuum / plenum / power | 20 kPa / 2 m² / 80 kW | Four rear electric extractors (placement/count S10); rotor dynamics, four-corner seal/leakage; at most 40 kN suction. Study assumptions. |
| Gas volume / starting temperature | 0.6 m³ / 293.15 K | S05 describes 600 L total for Rocket. Explicit study volume for the requested 250 kg inventory. Thrust's reported 200 L is not represented by silently scaling mass. |
| Starting pressure | **43.7023451 MPa absolute** | Modelica real-gas calculation for 250 kg dry air, 600 L and 20°C. Not an asserted Tesla operating pressure. |
| Gas thermodynamics | Lemmon dry-air Helmholtz EOS | Reusable CompressedAir package. S05 describes nitrogen; dry air follows the user's study input. Nitrogen comparison in gas-storage.md. |
| Nozzle throat / efficiency / valve response | 0.002 m² / 0.85 / 0.025 s | Uncalibrated aggregate area; ideal nozzle expansion with real-gas tank state. Side/yaw jet area is 4% of aggregate. |
| Thermal validity cutoff | 200 K | Discharge stops at the study-domain boundary. Conservative model guard, not Tesla hardware data. No calibrated regulator or phase-change closure. Finite wall heat capacity 60 kJ/K, gas-wall 200 W/K, ambient-wall 20 W/K. |
| Gas inertia / COM | Centered 1.2 × 0.5 × 1.0 m equivalent distribution | Mass and diagonal inertia change. Actual tank placement and COM migration remain unverified. |
| Motor heat capacity / cooling | 100000 J/K / 300 W/K | Lumped estimate at 298.15 K ambient. |

Only LunCoSim integrates vehicle position, contact, suspension and wheel spin.
Modelica reads measured motion and supplies motor torques, forces and native
mass/inertia inputs. The gas system integrates mass and temperature.

One-pedal regeneration, blower/plenum flow and external test refill are now modeled.
No active suspension, calibrated aero map, CFD, automatic attitude/landing target, or road certification is modeled. Manual body-rate assistance uses finite jets and gas; it does not hold an attitude or animate a stunt.
The ideal nozzle closure and unknown thrust calibration limit acceleration and
flight predictions. A passing model requirement does not validate Tesla's claim.

## Service and course assumptions

Manual external refill is limited to 20 kg/s and a 2 MW thermal jacket. It
accounts for gas initially at rest in the world, including translational and
rotational momentum loading and external aftercooling. It is test equipment,
not an onboard compressor claim. The temperature target is editable.

Green waypoints impose an immediate game-service boundary: prescribed Modelica
mass/thermal ledger adjustments deliver co-moving gas and condition gas/wall to
the target. Native mass/inertia and EOS pressure update; velocity is preserved.
Added air, mechanical energy and stored-energy exchange are tracked separately
from the finite test facility. This is not a real instantaneous refill mechanism.

The 14 m ramp has a 50 m level-to-vertical transition, 10 m vertical section,
40 m return curve and 8 m inverted exit, sampled at 0.2 m. Height is about
64.46 m. These are study dimensions inspired by the supplied presentation image.
The longer return curve allows the four measured skirt probes to retain a seal.
Three 12 × 2.4 × 1.2 m static blocks require a timed jump. Course progression is
checked from measured position, clearance, fan seal and four-wheel landing.

Each headlight is a normalized 3000 lm USD spot, 22° cone, −2° aim, 120 m render
cutoff; electrical auxiliary load includes 120 W for the pair. These are study
photometry, not Tesla optical measurements. Fan speed limit 15000 rpm and total
80 kW budget remain provisional study values; the directly reviewed first-hand
article establishes four rear fans, not an independently measured fan map.
