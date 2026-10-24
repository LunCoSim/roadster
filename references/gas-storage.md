# Storage of 250 kg of air

## Baseline calculation

The user supplied **250 kg available air mass**. Mass alone does not determine
both pressure and volume: gas composition and temperature are also required.
The study uses dry air at **20°C**, with **600 L total internal volume** as an
explicit Rocket baseline from S05: 200 L rear plus 400 L cabin. The reproduced
reveal statement identifies about 250 kg **total**, not per vessel; the source
conflict is documented in [the spec audit](spec-audit.md). Modelica exposes both
volumes and the common-state inventory split (83.333 + 166.667 kg initially).
This is gas volume, excluding tank walls,
valves, mounting and clearance. It is not a verified Tesla operating point.

The reusable [CompressedAir.mo](../models/CompressedAir.mo) calculates:

| Quantity | Result |
|---|---:|
| Density, mass / volume | 416.6667 kg/m³ |
| Real-gas pressure | **437.023 bar absolute / 43.7023 MPa** |
| Ideal-gas pressure | 350.619 bar absolute |
| Compressibility factor Z | 1.24644 |
| Isochoric heat capacity | 785.328 J/(kg·K) |

Here the real-gas pressure is 24.6% above the ideal-gas estimate. A fixed ideal
gas law would materially misstate the initial pressure and stored inventory.
The model uses the Helmholtz EOS of
[Lemmon et al. (NIST, 2000)](https://www.nist.gov/publications/thermodynamic-properties-air-and-mixtures-nitrogen-argon-and-oxygen-60-2000-k-pressures),
with coefficients from [CoolProp Air](https://coolprop.org/fluid_properties/fluids/Air.html).
Coefficient attribution and license are retained in LICENSES/CoolProp.txt.

Temperature matters at fixed mass and volume: the same 250 kg in 600 L gives
about **339 bar at −20°C**, **437 bar at 20°C**, and **533 bar at 60°C**. These
are equilibrium EOS states, not a prediction of temperatures during fast filling.

## Pressure / volume tradeoff

Calculated internal volume for **250 kg at 20°C**, using CoolProp 8.0.0 real-gas
equations. All pressures are absolute, not gauge.

| Pressure | Dry air volume | Nitrogen volume |
|---|---:|---:|
| 200 bar | 1079 L | 1144 L |
| 300 bar | 774 L | 827 L |
| 350 bar | 693 L | 741 L |
| 450 bar | 589 L | 632 L |
| 500 bar | 555 L | 595 L |
| 600 bar | 503 L | 540 L |
| 689.48 bar (10000 psi) | 471 L | 505 L |
| 700 bar | 468 L | 502 L |

For exactly 600 L, nitrogen requires about **492.475 bar absolute**, versus
437.023 bar for dry air. S05 describes nitrogen, while the user's input calls
for air; the active baseline follows dry air and retains this distinction.
The nitrogen comparison uses the [reference nitrogen EOS](https://coolprop.org/fluid_properties/fluids/Nitrogen.html).

The reported 10000 psi figure is a tank rating awaiting direct transcript
inspection here. A rating is not necessarily the operating pressure. It does
not prove that 600 L, 250 kg and 10000 psi describe one thermal state. The
reported 200 L Thrust tank likewise cannot be combined with 250 kg at an
ordinary 300–700 bar room-temperature fill. The configured Thrust study uses
the requested 250 kg / 600 L baseline too, explicitly differing from its
reported hardware volume; it never substitutes an 83 kg inventory.

## Reuse in Modelica

- `pressureFromDensity(mass / volume, temperature)` returns pressure in Pa.
- `densityFromPressure(pressure, temperature)` returns kg/m³.
- `requiredVolume = mass / densityFromPressure(pressure, temperature)` sizes storage.
- `properties(density, temperature)` returns pressure, its temperature derivative
  and cv for the tank energy balance.
- `CompressedAir.StorageSizing` exposes both sizing directions, ideal pressure
  and compressibility as normal Modelica outputs. Defaults are 250 kg / 600 L.

The vehicle calls the same package during discharge. It integrates mass and
the rigid-tank adiabatic energy balance, using real-gas pressure and cv.
The nozzle still uses an ideal-expansion approximation. Gas flow stops at the
live −130 °C study guard, not a Tesla hardware limit; see
[discharge limits](discharge-limits.md). Finite tank-wall heat transfer and external thermal service are included; remaining gas need not all be immediately usable impulse.

## Numerical evidence

[gas-sizing.json](../results/gas-sizing.json) contains eight production LunCoSim
Modelica experiments over 253.15–333.15 K and 500–800 L, restricted to 70 MPa.
Pressure, inverse volume, dp/dT and cv agree with CoolProp within 1e-8 relative
tolerance (observed maximum about 9e-16). This checks transcription and solver
evaluation against the same reference EOS; it is not independent experimental
validation of Tesla hardware or nozzle performance.

Reproduce with `CoolProp==8.0.0` installed for the optional comparison script:
`python3 scripts/check_gas_sizing.py --port 4198`. CoolProp is not required to
open the Twin or run the authored Modelica equations.


### Realtime reuse

Instantiate `CompressedAir.State(density=..., temperature=...)` for continuous
simulation. Its pressure, dpdT and cv outputs use the same package coefficients
as the `properties` function and StorageSizing. The equation form allows the
solver to lower the EOS into its scalar execution graph. The verification script
compares both forms against CoolProp, including pressure, dpdT and cv.
