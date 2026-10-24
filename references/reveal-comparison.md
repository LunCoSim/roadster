# Reveal comparison — 24 October 2026

This audit compares this Twin with the user-supplied
[browser simulator](https://github.com/eduardmur/tesla-roadster-simulator) at
`a0d187c08514cd15569d25f6afcace9e6da20c0c`. That project is a useful reference,
not manufacturer CAD or an independent validation of its fitted parameters.

| Quantity | Reference and evidence | This Twin / interpretation |
|---|---|---|
| Ramp height / end pitch | Reveal telemetry is reported as approximately 21 m and 170° in [event reporting](https://paultan.org/2026/10/16/tesla-roadster-revealed-flies-on-spacex-air-thrusters-0-96-km-h-in-0-81s-production-2028/). | Existing skill-course driving path measures 18.872768 m and ends horizontal, 180°. It is study geometry and must not be described as matching those reveal dimensions. |
| Radius | Browser source derives `21 / (1 - cos(170°)) = 10.5803698 m`. | This follows only from the **circular-ramp assumption**. Height and one end angle do not determine the complete profile. Our present blended-curvature ramp has no single radius. |
| Width | Browser source estimates 5 m. | Our skill-course ramp is 14 m wide. Neither width is established by a checked manufacturer drawing; the wider course is a gameplay assumption. |
| Fan load | A 4,700 kg downforce readout corresponds to 46.091 kN using standard gravity. | Our provisional fan map uses 20 kPa over 2 m², yielding 40 kN before seal/leakage losses. It is not calibrated to that readout. |
| Sealed floor | Browser source explicitly estimates 4 m². | 46.091 kN / 4 m² = 11.523 kPa pressure difference. The exterior 4.50 × 1.99 m bounding rectangle is 8.955 m², **not** a sealed area measurement. Fan pressure, leakage and power cannot all be inferred from downforce alone. |
| Storage | Browser source uses 600 L, 250 kg, 20 °C and 5,500 psi, then fits a linear compressibility correction to make them agree. | These are not four independent calibration constraints. 5,500 psi is 379.212 bar; our dry-air EOS calculates about 437 bar from 250 kg / 600 L / 20 °C. Species, gauge versus absolute pressure, temperature and reported fill state require reconciliation before changing the plant. |
| Rear thrust | Browser source calibrates nozzles to a reported 80 kN value. | A force value alone does not uniquely determine throat area without inlet state, expansion and efficiency. Our aggregate 0.002 m² throat remains a study input; do not describe it as measured hardware. |
| Landing 3.3 g | Browser source interprets the reported landing readout as jet acceleration. | A telemetry number may include specific force, gravity projection or impact. It does not uniquely identify four-nozzle thrust or a flight controller. Use the original readout and its definition before fitting it. |
| Speed / site | Browser source limits speed at a reported target above 230 mph and builds a 600 m-radius site. | A target is not a demonstrated maximum. The 600 m site is that simulator's layout choice, not a property of the real vehicle or event site. |

## Visual adaptation

The procedural body profile from `src/scene/car/body.ts`
is adapted under MIT in `tools/reveal_body.rhai`. Surface regions use native
USD meshes and the existing materials; no ported surface shader is used. The full notice is in
`licenses/tesla-roadster-simulator-MIT.txt`. No audio or photographs are copied.
The reference's +Z-forward geometry is rotated into LunCoSim's −Z-forward frame
and fitted to our existing 4.50 × 1.99 m visual envelope. Existing wheel mounts,
rigid-body/collision parameters and nozzle positions remain the physical owners.

## Production consequences

The old video is not evidence for a new ramp, new fan calibration or the new
visual shell. Changing the ramp requires matching course measurement gates,
checking the real support surface for the final landing, and recording fresh
takes. The current film must not call the existing ramp a measured 21 m / 170°
replica. Reported targets, model assumptions and simulation results remain
separate in narration and figure labels.
