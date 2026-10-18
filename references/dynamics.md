# Dynamics and fidelity

LunCoSim owns the rigid body, tire contacts, suspension and wheel spin. Body
forward is −Z, right +X, up +Y. Modelica consumes measured velocity and shaft
speed; it never integrates a second vehicle position.

The two-motor rear axle is limited by combined torque and power, reduction
efficiency, battery reserve and measured slip. A finite steering actuator feeds
the shared Ackermann geometry; steering authority falls with speed. Braking
and rolling wheel visuals remain native wheel mechanisms.

CompressedAir.mo contains reusable pressure/density functions, temperature
derivative, heat capacity and a StorageSizing model. Its 19-term residual
Helmholtz EOS is from Lemmon et al. (2000), using CoolProp's published
coefficients. See [storage analysis](gas-storage.md). At 250 kg, 600 L and
293.15 K it calculates 437.023 bar absolute; ideal gas gives only 350.619 bar.

For a rigid adiabatic discharge tank, the open-system energy balance is:

```
rho = m / V
dm/dt = -mass_flow
dT/dt = -mass_flow * T * (dp/dT at fixed rho) / (rho * m * cv)
p = EOS(rho, T)
```

The nozzle uses a calorically perfect compressible-flow closure with gamma 1.4:
choked mass flux above the critical pressure ratio and subsonic flow below it.
Exhaust velocity comes from the ideal isentropic enthalpy drop with assumed
efficiency. Force is mass flow × exhaust velocity, assuming ideal expansion.
See [NASA choking](https://www.grc.nasa.gov/www/k-12/BGP/mflchk.html),
[isentropic flow](https://www.grc.nasa.gov/www/k-12/airplane/isentrop.html) and
[rocket thrust](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/rocket-thrust/).
These equations do not establish Tesla nozzle calibration. Discharge is inhibited
at 200 K to stay inside the study's single-phase domain. Remaining gas is not
necessarily usable gas. impulse_remaining is a current estimate, not a second
stored budget.

Rear nozzles produce forward force. Four lower corner jets produce lift. Two
front side jets produce side force and yaw about a 1.7 m lever; the measured
quaternion rotates the moment to world coordinates. There is no invented
rearward/downward propulsion. I opens boost, J/L command yaw, U opens lift;
K/O inhibit forward/lift commands. Key release closes valves with a 25 ms
response. Commands share a finite flow budget.

Native mass receives dry mass plus remaining gas. Native diagonal inertia
follows an assumed centered gas distribution. Gravity acts on the changing
physical mass. Actual tank placement and COM migration are unknown. Performance
disables gas actuation and uses dry vehicle mass.

Fan sealing is valid * exp(-(gap/0.35 m)^4), using a native downward range query.
Rolling resistance uses the same proximity gate. Fan power remains while enabled.
Drag opposes full world velocity using an isotropic CdA.

Unknown nozzle area, real-gas nozzle expansion, heat transfer, regulator behavior,
gas composition, mass properties and tire calibration limit prediction. Launch
and flight results are study outputs, not validated vehicle performance.
