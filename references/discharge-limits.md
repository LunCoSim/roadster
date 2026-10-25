# Adjustable discharge-temperature limit

The current study default is **−130 °C (143.15 K)**. `RoadsterVehicle.discharge_cutoff_c`
is a live input in °C, converted once to kelvin at the powertrain boundary.
The normal HUD has ±5 °C controls; the film HUD displays the active value only.
The documented study range is −130..20 °C. The cutoff is an assumed tank-gas
operating/model boundary, not a published Tesla component rating.

## Why this default

[CoolProp's reference air EOS](https://coolprop.org/fluid_properties/fluids/Air.html)
gives dry air a critical temperature of **132.5306 K (−140.6194 °C)**.
The −130 °C default leaves a 10.62 K margin above that temperature, keeping the
tank away from liquid–gas coexistence. This is a deliberately chosen modelling
margin, not a thermodynamic event at exactly −130 °C. The fluid equations do
not suddenly lose validity at that number. The native property checks cover
143.15–293.15 K at three densities (`results/gas-cold-reference.json`), including
pressure, cv, pressure-temperature derivative and internal energy.

[Nitrogen's critical temperature](https://coolprop.org/fluid_properties/fluids/Nitrogen.html)
is about −147 °C. The active study fluid is dry air; the interview names nitrogen.
Changing fluid requires changing the EOS and repeating these calculations.

## Inventory sensitivity

Reference calculation: initially 250 kg in 600 L at 20 °C, homogeneous rigid
adiabatic tank, no wall heat. The entropy of the remaining gas stays constant
under that idealized open-system balance. CoolProp 8.0.0 evaluates the remaining
density at each temperature. This is an engineering reference calculation,
not recorded simulator output. Inputs/results: `discharge-cutoff-reference.json`.

| Tank temperature limit | Gas remaining | Discharged | Pressure, absolute |
| --- | ---: | ---: | ---: |
| −73.15 °C | 136.5 kg | 45.4% | 105.7 bar |
| −100 °C | 103.6 kg | 58.6% | 64.0 bar |
| −120 °C | 80.3 kg | 67.9% | 42.2 bar |
| **−130 °C** | **69.4 kg** | **72.3%** | **33.7 bar** |

The native transient includes valve dynamics and wall heat, so its measured
inventory will differ. Re-run the actual manoeuvre before using a number in
narration. At −130 °C the reference tank pressure is only 7.7% of its initial
437 bar. Gas still being dischargeable does not mean it can provide another
full-strength boost or support the car. Plot actual thrust beside temperature.

## Hardware and model boundaries

Cryogenic-compatible valves exist, but they are specifically designed for that
service: see [Valcor's construction discussion](https://www.valcor.com/cold-hard-facts-cryogenic-solenoid-valve-design/).
This does not establish the temperature rating of Tesla's tanks, liners,
seals, plumbing or valves. Nozzle expansion remains the documented ideal-gas
engineering closure; a single-phase tank check does not qualify condensation
or non-equilibrium flow in the nozzle. Do not present the temperature trip as
measured hardware failure, or choose it to force a desired crash.

Change while running: `python3 scripts/control.py --port 4387 --discharge-cutoff -100`.
This uses the existing native SetPorts input; it changes neither source nor
scene and does not reset temperature or inventory. Native output
`thermal_guard_temperature_c` reports the consumed value. Plots use
`tank_temperature_c` and `thermal_guard_temperature_c`, with time in seconds.

## Native transient and live-input evidence

A fresh `RoadsterColdGasBench` RunExperiment with a four-second rear-valve
request (starting at 0.5 s), fixed-RK4 and 240 Hz output intervals reaches the
−130 °C trip and finishes with **68.09 kg**, about **72.8% discharged**. Its
minimum sampled temperature is −130.031 °C; wall heating then warms it to
−129.80 °C. This is the stationary gas plant with fixed mechanical observations,
not a driving or no-refill crash result. The native result is experiment
`2c8c6d87-6bc6-4c8a-9b5d-d0589c2eaf28`, with full source identity in
`results/2c8c6d87-6bc6-4c8a-9b5d-d0589c2eaf28.json`.

On one unchanged vehicle entity, live changes −130 → 20 → −100 → −130 °C
correctly close and reopen the discharge gate without a scene reload or gas
reset. `scenarios/tests/discharge_cutoff.rhai` also exercises the normal HUD
semantic action; it is run through RunScenarioAsset against the loaded course.
