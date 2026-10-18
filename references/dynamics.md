# Dynamics, control and fidelity

USD supplies SI geometry, wheel mounts, compound chassis/roof colliders, Earth
`g = 9.80665 m/s²`, contact materials and typed port connections. Native LunCoSim
integrates body position, tire contact, suspension and wheel shafts. Modelica
reads native motion; it does not integrate a second vehicle trajectory. Rhai
owns discrete course/input/UI policy. Rust contains no Roadster/ramp identity.

## Drive, steering and losses

Two rear motors share 1 MW and 1400 N·m, an assumed 8.4 reduction and 0.97 gear
efficiency. Measured shaft speed and slip limit torque/power. Battery energy,
motor heat and 120 W of headlight load are included in auxiliary consumption.

`SteeringDriver.mo` models a keyboard driver's gradual steering buildup,
1.8/(1+(v/20)²) normalized units/s, with 2.8 units/s return. A separate rack has
0.12 s response and 2 units/s slew. This is an explicit driver assistance
assumption, not a speed-dependent wheel-angle cap. Full 0.45 rad rack travel
remains available. Set `keyboard_steering_assistance=0` for direct analog demand.
The shared Ackermann model supplies actual left/right front wheel headings.
Native tire slip and a single Coulomb cone determine cornering/understeer.

The native parking brake apportions actual computed vehicle mass using measured
wheel loads. Fan preload increases friction capacity without inventing inertial
mass. Brakes use one friction cone. Fans-off on a vertical wall permits sliding;
wheel rays may still intersect the wall while the car falls parallel to it.

Release applies one-pedal regeneration, up to 1.8 m/s² and 120 kW, with 80%
electrical recovery through native wheel shafts. Shift brakes are separate.
Rolling loss and body-axis 3D aero oppose motion. No script zeroes velocity.
`VehicleAerodynamics.mo` rotates measured velocity into body axes, applies
quadratic drag and returns world forces. Airbrake/downforce deployment has a
0.2 s response. These are dissipative study coefficients, not a measured aero map.

## Real-gas and thermal state

`CompressedAir.mo` shares one 19-term Lemmon dry-air Helmholtz coefficient set
between reusable functions, storage sizing and the equation-form realtime State.
At 250 kg, 600 L and 293.15 K it gives 437.023 bar absolute. Pressure, dp/dT,
cv and specific internal energy derive from the EOS; internal-energy reference
must be used consistently when accounting mass exchange. See
[CoolProp's thermodynamic identities](https://coolprop.org/fluid_properties/PurePseudoPure.html#thermodynamic-properties-of-fluid)
and [NIST's EOS publication](https://www.nist.gov/publications/thermodynamic-properties-air-and-mixtures-nitrogen-argon-and-oxygen-60-2000-k-pressures).

Between service boundary jumps:

```
rho = m/V
m_dot = mdot_in - mdot_out
m*cv*T_dot = (mdot_in-mdot_out)*T*(dp/dT)_rho/rho + Q_wall + Q_service
p = EOS(rho,T)
```

`TankHeatTransfer.mo` has finite 60 kJ/K wall capacity, 200 W/K gas-wall and
20 W/K ambient-wall conductance. Ambient is 293.15 K; initial wall follows the
editable initial gas temperature. These coefficients are assumptions.

Discharge is inhibited below a **200 K conservative model guard**. This is not
a Tesla thermal threshold, a fundamental air freezing point, or a claim that
all stored air is usable. No calibrated regulator, multiphase nozzle flow or
moisture/icing model is present. Reviewed sources do not establish Tesla's
actual tank heaters or low-temperature management. Sources describe nitrogen;
this study uses the user's specified dry air.

## Jets, flight and fans

The aggregate throat is 0.002 m², gamma 1.4, efficiency 0.85 and valve response
25 ms. `JetExpansion.mo` uses a fixed area ratio corresponding to exit Mach 3.8,
ideal isentropic expansion and momentum plus exit-pressure thrust. These are
uncalibrated closures. [NASA area–Mach relation](https://www.grc.nasa.gov/www/k-12/BGP/astar.html)
and [nozzle design](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/nozzle-design/)
provide the generic basis, not Tesla dimensions.

Rear boost, four bottom jets and two front yaw jets share finite gas/flow.
Lift mounts are X=±0.8 m, Z=−0.90/+1.85 m; the nose-side yaw arm is
1.90 m. Rear mounts are Y=−0.02 m above the assumed Y=−0.14 m COM.
`ThrusterMount.mo` includes each actual (point − COM) × force moment. The measured
quaternion rotates moments to world axes. Individual corner commands retain
separate force outputs. There are no invented reverse/downward jet banks.

W/S commands only the motors and A/D only the steering rack, on the ground and
in flight. K commands all four bottom valves with fixed geometry trim, independent of altitude;
R/C command the front/rear pairs; Q/E command the left/right pairs for roll.
I/P/comma/period command individual corner valves and J/L the yaw jets. The
paired controls are authored key aliases for those same
corner commands, with no extra controller or flight-only behavior.
There is no automatic body-rate controller or input mode switch. Releasing a
jet key closes its valve with the 25 ms actuator response; the driver must pulse
opposing jets to arrest rotation. Body rates are measurements only. Native
contact, inertia and the explicit finite forces/moments determine the motion.

The widening shader envelope begins at each exhaust mouth. Modelica publishes
radii, expansion/mixing lengths and exhaust speed; delivered force gates the
animation. A spreading coefficient of 0.08 m/m is assumed. GPU time advects
noise only. Visible streams are qualitative indicators, not validated CFD,
shock cells or a prediction of condensation.

Four rear extractors share a skirted 2 m² plenum. Four native probes measure
body-relative gap and surface alignment. Rotor dynamics, leakage, airflow,
pressure and power determine suction. Limits are 20 kPa / 40 kN / 80 kW /
15000 rpm. Typical sealed demand is much lower than the ceiling. There is no
wall attachment or pose lock. Location/count follow source S10; performance
maps, skirt dimensions and total power remain provisional study assumptions.

## Two explicit external service modes

**Manual finite service:** 20 kg/s maximum, tapering near 250 kg, and a bounded
2 MW thermal jacket. Target temperature is a live 253.15–333.15 K input.
Aftercooling cancels the modeled inflow compression term; the jacket accounts
for wall exchange and drives the target. The external compressor estimate uses
ideal isothermal work at 70% efficiency and COP=1 thermal accounting. Supplied
mass and energy are integrated separately. This is not onboard hardware.

Incoming air is initially stationary in the world. Modelica applies
`F = mdot_in*(0-v)` and the rotational momentum-loading torque while native
mass/inertia update. Relative kinetic energy is removed by accounted external
thermal processing. Driving, jets and manual refill may operate simultaneously.
The test button is available in any attitude; it is a laboratory utility.

**Green waypoint instant service:** an explicitly idealized game boundary.
Modelica calculates cumulative mass/temperature/wall-temperature ledger offsets
that restore 250 kg and the selected temperature. Rhai copies all offsets
atomically through normal inputs. Physical ledgers integrate normal equations
between these externally prescribed jumps. No Rust or script writes body pose,
velocity, mass or pressure. EOS pressure and native mass/inertia follow the new
state on the next synchronization. This route stays event-free for the realtime
fixed-RK4 solver; it does not pretend an enormous finite flow occurred.

The supplied gas is co-moving/co-rotating, preserving native velocities. The
facility supplies the corresponding momentum and mechanical energy. Modelica
tracks added air, kinetic-energy exchange and the EOS gas plus tank-wall stored
energy change. This service does not model real refill equipment or a refill
rate. The manual finite-service budgets remain separate.

## Ramp and course

The reference image motivates an original 14 m wide ramp: 50 m smooth transition
to vertical, 10 m wall, 40 m gradual return curve, and 8 m inverted exit. Height
is about 64.46 m; mesh thickness is 0.6 m. Pitch uses cubic smoothstep, with zero
endpoint curvature, and 0.2 m sampling. The exact static triangle mesh supplies
collision; colored markings and checkpoint posts are not invisible obstacles.
The longer return curve permits the four measured skirt probes to retain a seal.

Prepared suspension is 300 kN/m and 14 kN·s/m per wheel. A short approach in the
standalone practice scene avoids an unintended high-speed bottoming test.
Course entry speed is guided at 35–45 km/h. No hidden speed or attachment clamp
is used; excess speed can lose contact or hit body collision geometry.

`SkillCourse.mo` owns continuous course measurements and simulation-time/air
rotation integrals. Rhai sequences real speed/clearance/service/adhesion/landing
checks. Three 1.2 m static blocks require a timely K pulse. The green waypoints
refill immediately while moving. Finishing requires at least 170° of aerial pitch
rotation, a green-zone upright landing, four actual wheel contacts and speed
below 2 m/s for 0.5 s. The native pause freezes both physics and course time.

The acceptance pilot uses ordinary drive, brake, fan and jet commands only.
Completing this course demonstrates these maneuvers in this assumed model;
it does not establish a safe real-car stunt envelope or Tesla calibration.

See [propulsion and mounting analysis](propulsion-analysis.md) for native launch
measurements, Modelica mean-force sizing/impulse, per-bank blowdown and the fixed
rear lift valve gain of 0.486486 required by the unequal front/rear arms.
