# Battery study assumption — 2026-10-20

## Evidence and selected value

Use **120 kWh nominal energy**, with **110–140 kWh** as an engineering sensitivity
bracket. This bracket is selected for study; it is not a manufacturer tolerance.
The 2017 concept's 200 kWh specification does not apply to the redesigned car.

The [firsthand engineer interview](https://www.motortrend.com/news/first-look-2028-tesla-roadster-performance-thrust-rocket)
reports a 4680-based pack above 100 kWh, withholding exact energy; it also reports
a range target above 300 miles and a 1 MW combined rear drive unit. These are
prototype claims. Exact chemistry, cell count and pack maps remain unpublished.

The inference is explicit: 300 miles × 1.609344 km/mile × 220 Wh/km ÷ 0.90 usable
range fraction = **118.019 kWh**. Round to 120 kWh. The consumption and usable
fraction are study assumptions. Their combination is consistent with the
existing 3D aerodynamic/rolling plant at road speeds plus driving/auxiliary
allowances; it does not establish a regulatory drive-cycle range.

## Mass, volume and power plausibility

A [2025 primary teardown study](https://doi.org/10.1016/j.xcrp.2025.102453)
measured an earlier Tesla 4680 at 241.01 Wh/kg and 643.3 Wh/L. Use these as
conservative cell proxies, with assumed cell/pack mass fraction 0.80 and volume
fraction 0.75. They yield about **622 kg** and **249 L** for the 120 kWh pack.
Those fractions and the equivalent box are study inputs; new Roadster cells may
differ. [Tesla describes](https://www.tesla.com/learn/engineering-tesla-vehicle-batteries-safety-durability-longevity)
its high-energy 4680 chemistry and temperature management, without supplying
Roadster pack calibration.

The **1700 kg reference dry car already includes this pack**. The model retains
that mass at 120 kWh and changes mass by Δcapacity / assumed pack-specific energy
when capacity is edited. Four wheels and six mechanism bodies remain separately
accounted. An equivalent 1.5 × 0.12 × 2.5 m incremental mass distribution at the
reference vehicle COM changes all three inertias. This is a sensitivity model,
not a prediction of the actual pack's dimensions or COM migration.

At 1 MW shaft power, 93% conversion efficiency, an 80 kW fan budget and 920 W
other auxiliaries, the sizing proxy requires about **1.156 MW DC**, or **9.63 C**
energy-normalized discharge. This is a short-pulse power demand, not a validated
cell current limit. The plant's actual battery power and SOC integrate actual
motor, fan and auxiliary loads; the sizing proxy does not inject extra forces.

The reported 10–80% charge target of 10–12 minutes would require 84 kWh and
420–504 kW average pack charging power under this assumption. Modelica publishes
these energy/power requirements. No unmeasured charger, taper or thermal curve is
inferred from them.

## Model ownership

`BatteryStudy.mo` owns the inference, mass/volume estimates and power/charge
proxies. `RoadsterPowertrain.mo` integrates energy and SOC. USD exposes the
editable preparation parameter `inputs:battery_capacity_kwh` and read-only
battery outputs. The native chassis mass/inertia connections consume the
resulting vehicle quantities. The study does not claim cell-level electrical,
aging, thermal, range, or charging qualification.
