# Recorded validation

Date: 2026-10-18. Production LunCoSim 0.6.0-dev, final binary build **22a53afc**,
Linux windowed Vulkan on NVIDIA RTX 5060 Laptop GPU. Earlier diagnosis also used
the AMD Radeon 610M. No simulator source was changed or rebuilt. API port 4198
is owned by this session, with vsync and unfocused throttling disabled.
The build directory was removed externally during the session; its running
executable was preserved locally as ignored `.scratch/luncosim` for repeat runs.

| Check | Evidence |
|---|---|
| Authored preflight | 21 USD, Rhai, Modelica, SysML and WGSL assets accepted; [preflight.txt](preflight.txt) |
| SysML requirements | 7 requirements / 8 checks passed; [launch-report.json](launch-report.json) |
| Gas EOS | Eight Modelica experiments compare both properties() and State with CoolProp 8.0.0. Pressure, inverse volume, dp/dT and cv passed 1e-8 relative tolerance; maximum error 8.9e-16; [gas-sizing.json](gas-sizing.json) |
| Startup keyboard control | I/K/J/L/U/O plus W, A and Space passed without a test-only AcquireControl repair; [controls.json](controls.json) |
| Native wheels / braking | All eight checks passed; native shaft speed, changing angle, Ackermann steering, turn-and-brake deceleration, four contacts, wet mass and HUD; [driving.json](driving.json) |
| Motor-only launch | 0–60 mph in 2.676864 simulated seconds, 1950 kg, suction enabled, no gas used; [motor-after.json](motor-after.json) |
| Gas-assisted launch | 0–60 mph in 0.512313 simulated seconds, no rollout subtraction; [telemetry](launch-telemetry.json), [trajectory](launch.csv) |
| Jet render connections | Delivered forces reached four tested shader sinks and fell below 1 N on release; [effects.json](effects.json) |
| Live physics cadence | Approximately 60 integrated physics ticks per wall second; [runtime-rate.json](runtime-rate.json) |

## Acceleration cause and numerical preservation

Startup formerly granted possession without linking the native keyboard producer.
The checks now exercise the ordinary authored startup, including fresh Twin reloads.
Suction defaults on and continues to consume its existing modeled electrical power.
Motor torque, rated power and the dry/air mass budgets were not increased.

The algorithm-form EOS cost approximately 11–23 ms per worker step during
diagnosis. Its equation-form Modelica State reduced that to below 0.5 ms in the
recorded final run. The EOS coefficients are shared with the original function,
and eight numerical comparisons include both forms. [motor-before.json](motor-before.json)
retains the original-function benchmark; the final standing-start motor timing
matches it to better than 0.1 microsecond. This is a study result, not a fit to
Tesla's claimed acceleration.

## Wheels, HUD and effects

The final rolling sample measured 8.635 m/s body speed;
the four native shaft speeds track road speed. Orange sidewall index marks make
rotation legible without changing angular speed. [wheels-0.png](wheels-0.png)
through [wheels-3.png](wheels-3.png) show separate wheel phases.

A stronger low-speed denominator regularization (8 m/s) removed the observed
turn-and-brake jitter with suction enabled. The final speed after three braking
seconds was 5.5e-13 m/s. This demonstrates this maneuver;
the uncalibrated low-speed tire law remains an approximation.

[Rear boost](jet-I-0.png), [yaw jet](jet-J-0.png) and [lift jets](jet-U-0.png)
were inspected in the production window. [Second rear phase](jet-I-1.png)
records the time-advected stream. These white streams are qualitative operator
indicators, not validated condensation geometry. They follow delivered force,
including release and gas-domain inhibition. The [fresh HUD](fresh-hud.png)
uses Modelica speed, pressure and force readouts; Rhai formats them for display.

The nozzle area, tank placement and tire calibration remain assumptions.
Dry-air EOS verification checks transcription against the reference EOS, not
independent experiments. The interview describes nitrogen. Adiabatic discharge
stops at the 200 K study boundary; stored gas below that limit is not necessarily
usable impulse. The short lift probes do not establish a safe flight envelope.

Source fingerprints are in validation-manifest.json. Shared lunco:// assets are
external dependencies. Run scripts/check_controls.py, scripts/check_driving.py,
scripts/check_effects.py, scripts/check_gas_sizing.py, scripts/run_motor_launch.py
and scripts/run_launch.py to repeat the corresponding checks. Only gas comparison
requires the optional CoolProp verification package; runtime physics is Modelica
and native contact dynamics.
