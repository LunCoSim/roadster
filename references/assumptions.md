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
| Suspension spring / damper / rest length | 100000 N/m / 8000 N·s/m / 0.43 m | Passive per-wheel suspension. |
| Steering actuator | 0.12 s, 2 command units/s | Max wheel angle 0.45 rad; speed-dependent rack limit based on 0.8 g lateral acceleration. Study tuning. |
| Slip control | 0.12 target, gain 30 | Uses measured wheel and body speed; no separate wheel animation. |
| Drag area / density / rolling coefficient | 0.62 m² / 1.225 kg/m³ / 0.012 | Isotropic 3D drag and smoothed ground rolling resistance. |
| Fan suction / power | 18000 N / 30 kW | Assumed clearance-dependent seal; suction fades aloft. |
| Gas volume / starting temperature | 0.6 m³ / 293.15 K | S05 describes 600 L total for Rocket. Explicit study volume for the requested 250 kg inventory. Thrust's reported 200 L is not represented by silently scaling mass. |
| Starting pressure | **43.7023451 MPa absolute** | Modelica real-gas calculation for 250 kg dry air, 600 L and 20°C. Not an asserted Tesla operating pressure. |
| Gas thermodynamics | Lemmon dry-air Helmholtz EOS | Reusable CompressedAir package. S05 describes nitrogen; dry air follows the user's study input. Nitrogen comparison in gas-storage.md. |
| Nozzle throat / efficiency / valve response | 0.002 m² / 0.85 / 0.025 s | Uncalibrated aggregate area; ideal nozzle expansion with real-gas tank state. Side/yaw jet area is 4% of aggregate. |
| Thermal validity cutoff | 200 K | Discharge stops at the study-domain boundary. No regulator, phase-change or tank-wall calibration. |
| Gas inertia / COM | Centered 1.2 × 0.5 × 1.0 m equivalent distribution | Mass and diagonal inertia change. Actual tank placement and COM migration remain unverified. |
| Motor heat capacity / cooling | 100000 J/K / 300 W/K | Lumped estimate at 298.15 K ambient. |

Only LunCoSim integrates vehicle position, contact, suspension and wheel spin.
Modelica reads measured motion and supplies motor torques, forces and native
mass/inertia inputs. The gas system integrates mass and temperature.

No recharge, regen, active suspension, detailed fan flow, aero deployment, CFD,
airborne stabilization, stunt automation or road certification is modeled.
The ideal nozzle closure and unknown thrust calibration limit acceleration and
flight predictions. A passing model requirement does not validate Tesla's claim.
