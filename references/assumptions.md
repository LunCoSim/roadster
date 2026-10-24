# Engineering inputs and limits

This is an executable study, not Tesla CAD or production calibration.

A-C01: the digital course pilot predicts wheel heading over the modeled command
and rack lag (0.05 + 0.12 s). `models/SteeringDriver.mo` is the source of these
study time constants. This guidance assumption prevents delayed steering
overshoot; it is not a manufacturer controller calibration.

| Input | Baseline | Provenance / limit |
|---|---:|---|
| Dry vehicle mass | 1700 kg | Study interpretation of the reported under-1700 kg target. Published trim and fill state are unverified. Includes wheels and empty gas hardware; no separate pressure-vessel mass estimate. |
| Available air | **250 kg** | Total Rocket inventory; user input and reproduced reveal statement. Not 250 kg per tank. |
| Charged Thrust / Rocket mass | **1783.33 / 1950 kg initially** | At the 120 kWh reference: 1700 kg dry + 83.33 / 250 kg derived equal-density air. Thrust inventory is a study inference, not a published mass. |
| Chassis USD mass | 1572 kg dry | Four physical 24 kg wheels plus 32 kg carriers/knuckles are separate bodies. Modelica supplies operating chassis mass/inertia. |
| Motor topology / combined ratings | Two rear motors, 1 MW / 1400 N·m | S05 describes rear drive, over 1 MW and 1400 N·m. The model uses a conservative 1 MW baseline, not 1 MW per motor. |
| Reduction / efficiency | 8.4 / 0.97 | Ratio reported in interview summaries, primary transcript unverified. Combined wheel limit 11407.2 N·m / 970 kW before slip control. |
| Battery / efficiency | 120 kWh / 0.93 | A-B01 source-informed assumption; 110–140 kWh sensitivity. See [battery derivation](battery-study.md), inline sources in BatteryStudy.mo and energy/native-mass checks. The current vehicle starts at 100% SOC, with a 2% drive reserve. |
| Body visual envelope | 4.50 m long / 1.9875 m wide; shell local Y −0.361…0.632 m | Procedural cross-section study adapted under MIT from the referenced browser simulator, fitted to our existing wheel datums. Checked by native mesh readback on 24 October; see body-style.md. A roughly 9 m² exterior bounding rectangle is not the sealed plenum or a Tesla dimension drawing. |
| Wheelbase / track / tire radius | 2.75 / 1.72 / 0.34 m | Study geometry; front/rear tire width 0.25/0.30 m. |
| Wheel mass / rotational inertia | 24 kg / 1.4 kg·m² each | Complete rotating assembly assumption. |
| Tire friction / longitudinal stiffness | 1.4 / 30000 N·s/m | Ideal dry surface; no measured supplier curves. |
| Slip-angle speed floor | 8 m/s | Existing native tire regularization; steady-state curve is uncalibrated below this speed. Bounds its lateral force derivative at the 1/60 s step, avoiding brake/contact sign chatter with suction enabled. The final native turn-and-brake observation settled below 1e-9 m/s; low-speed cornering remains a regularized approximation. |
| Suspension spring / damper / rest length | 300000 N/m / 14000 N·s/m / 0.43 m | Prepared track setting per wheel; raised to preserve body clearance at the ramp transition. |
| Steering actuator | 0.12 s, 2 command units/s | Max wheel angle 0.45 rad, no speed angle cap. Modelica keyboard driver buildup 1.8/(1+(v/20)^2) units/s, return 2.8 units/s. Full rack travel remains available. |
| Slip control | 0.12 target, gain 30 | Uses measured wheel and body speed; no separate wheel animation. |
| Drag area / density / rolling coefficient | 0.62 m² / 1.225 kg/m³ / 0.012 | Body-axis drag: forward 0.62, side 4.5, vertical 8.0 m²; airbrake 1.1 m²; lift area 7.9 m². Dissipative 3D drag and smoothed ground rolling resistance. |
| Fan vacuum / plenum / power | 20 kPa / 2 m² / 80 kW, unverified baseline | Four rear extractors and a seal around the battery region are supported by S10. Actual sealed area, pressure, fan curve, leakage and power rating are not established. The 40 kN result is conditional on these inputs, not a measured Tesla rating. See [fan assumption audit](fan-assumption-audit.md). |
| Gas volume / starting temperature | 0.6 m³ / 293.15 K | S05 describes 200 L rear + 400 L cabin for Rocket. Modelica sums both editable volumes, assumes a shared gas state, and publishes their mass split. Thrust uses only 200 L; Modelica derives 83.33 kg at the same assumed initial density. Rocket retains 250 kg. |
| Starting pressure | **43.7023451 MPa absolute** | Modelica real-gas calculation for 250 kg dry air, 600 L and 20°C. Not an asserted Tesla operating pressure. |
| Gas thermodynamics | Lemmon dry-air Helmholtz EOS | Reusable CompressedAir package. S05 describes nitrogen; dry air follows the user's study input. Nitrogen comparison in gas-storage.md. |
| Nozzle throat / efficiency / valve response | 0.002 m² / 0.85 / 0.025 s | Uncalibrated aggregate area; ideal nozzle expansion with real-gas tank state. Side/yaw jet area is 4% of aggregate. |
| Mounts / fixed lift trim | Front lift Z −0.90 m, rear +1.85 m; X ±0.80 m; rear-boost Y −0.02 m; COM Y −0.14 m | Study placement follows observed topology and clears modeled tires. Rear lift valve gain 0.486486 balances collective moment. Full cross-product moments are in Modelica. |
| Discharge study guard | −130 °C / 143.15 K, adjustable | Current RoadsterVehicle default, not a certified valve limit or an extension of the gas implementation's verified range. The guard is above dry-air critical temperature, which alone does not establish material or low-temperature accuracy. See [discharge limits](discharge-limits.md). Finite wall heat capacity 60 kJ/K, gas-wall 200 W/K, ambient-wall 20 W/K remain uncalibrated heat-transfer inputs. |
| Gas inertia / COM | Centered 1.2 × 0.5 × 1.0 m equivalent distribution | Mass and diagonal inertia change. Actual tank placement and COM migration remain unverified. |
| Motor heat capacity / cooling | 100000 J/K / 300 W/K | Lumped estimate at 298.15 K ambient. |

Only LunCoSim integrates vehicle position, contact, suspension and wheel spin.
Modelica reads measured motion and supplies motor torques, forces and native
mass/inertia inputs. The gas system integrates mass and temperature.

One-pedal regeneration, blower/plenum flow and external test refill are now modeled.
No active suspension, calibrated aero map, CFD, automatic attitude/landing target, or road certification is modeled. Thruster keys directly command finite valves. WASD remains motor/steering control at every altitude; no automatic flight-rate controller or stunt animation is used.
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

The default 14 m wide ramp reaches 18.873 m, with an 18 m lower arc, 0.9 m
wall, 11.7 m return curve and 5.4 m lip. Three 12 × 2.4 × 3 m cubes require a
precisely timed jump. The original practice ramp retains its historical 64.46 m
geometry. See [dynamic course](dynamic-course.md) for the authored profile and
measured timing scope. None of these dimensions is a measured Tesla course.

Each headlight delivers a study 3000 lm focused beam, 22° cone, −2° aim, 120 m render
cutoff. Modelica converts this to ~133546 renderer-equivalent isotropic lumens
because the native spotlight applies angular attenuation; electrical auxiliary load includes 120 W for the pair. These are study
photometry, not Tesla optical measurements. Fan speed limit 15000 rpm and total
80 kW budget remain provisional study values; the directly reviewed first-hand
article establishes four rear fans, not an independently measured fan map.
