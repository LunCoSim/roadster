# Recorded validation

Date: 2026-10-18. Production LunCoSim 0.6.0-dev, binary build **22a53afc**,
Linux windowed Vulkan on AMD Radeon 610M. No simulator source was changed or
rebuilt for this Twin. Native interactive checks used owned API port 4198,
with vsync and unfocused throttling disabled. Headless numerical verification
used the production scene-test runner.

| Check | Result / evidence |
|---|---|
| USD/Rhai preflight | 12 assets accepted; [preflight.txt](preflight.txt) |
| SysML source-set validation | No errors, warnings or findings; [sysml-validation.json](sysml-validation.json) |
| Reusable gas EOS | 8 Modelica experiments compared with CoolProp 8.0.0; pressure, inverse volume, dp/dT and cv within 1e-8 relative tolerance. Maximum observed error about 9e-16; [gas-sizing.json](gas-sizing.json) |
| Native keyboard path | I/K/J/L/U/O, valve closure, gas use, physical mass update, W, A and Space passed; [controls.json](controls.json) |
| Native driving | Rolling speed, changing wheel angle, steering, brake deceleration, four valid ground contacts, charged mass and visible speed HUD passed; [driving.json](driving.json) |
| Launch | 7 requirements / 8 checks passed through native SysML evaluation; [launch-report.json](launch-report.json), [telemetry](launch-telemetry.json), [trajectory](launch.csv) |

The standing-start launch reached 60 mph in approximately **0.515 s** without
rollout subtraction. This depends on the assumed nozzle area and study mass.
It is not an independent Tesla performance measurement or calibration.
The source revision is recorded at both start and end of the exact runner report.

The driving observation showed approximately 3.43 m/s body speed, with front
wheel peripheral speed matching within about 0.01 m/s and slight powered rear
slip. Steering produced distinct inner/outer front-wheel angles. Screenshots
[wheels-0.png](wheels-0.png) through [wheels-3.png](wheels-3.png) record the rear
quarter camera, visible wheels and changing speed HUD.

Brake acceptance is speed below 0.2 m/s after three simulated seconds. A small
instantaneous lateral velocity oscillation (about 0.16 m/s in the recorded run)
remains in this finite-step native tire/contact model. This is not evidence of
an exact zero-velocity parking hold. The authored low-speed slip regularization
and this limit are explicit in the input table.

Each gas-key probe starts a fresh Twin. Its 250 kg inventory is not shared with
earlier probes. U and I consumed about 41.5 kg over the short observation, and
the native physical mass fell from 1950 kg to about 1908.5 kg. K/O alone produced
no fictitious reverse/downward force or gas use. Side jets produced yaw moments
through the authored quaternion-based moment connection.

The gas EOS comparison checks transcription against the same reference EOS,
not independent experimental data. The vehicle uses dry air; the engineering
interview describes nitrogen. The adiabatic tank model inhibits discharge at
200 K. Remaining stored gas is not necessarily usable impulse without heat
transfer or a regulator model. No flight envelope or attitude stability is
validated by the keyboard lift probe.

Project source fingerprints are in validation-manifest.json. Shared lunco://
assets are external runtime dependencies. The supplied launcher and scripts
document how to repeat the checks; no build, network mesh download or Python
physics runtime is required.
