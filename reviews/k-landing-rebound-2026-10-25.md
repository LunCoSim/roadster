# K landing rebound and interactive controls

Repeated K presses and a long hold could produce a higher unpowered rebound
than the preceding powered jump. This was a shared raycast suspension stop
defect. K itself is a held lift-valve command, not a fixed-height jump command.

The wheel query ended at suspension rest length. A fast landing could cross
the stop before the next query discovered support. The custom XPBD stop then
corrected the overlap as a displacement, which the solver converted into a
large separating velocity. On the reproduced long hold, thrust had already
stopped before the car rebounded above 280 m.

The repair is in the LunCoSim `optimization` worktree, in
`crates/lunco-mobility/src/raycast_travel.rs` and `src/lib.rs`:

- Use Avian's supported `ContactNormalPart` integration for the unilateral stop,
  including speculative impulses, native softness and velocity relaxation.
  Both the carrier and the actual support retain their mass/inertia response.
- Extend the wheel query by the hub's travel during one master step. Preserve
  the signed gap for speculative support; distant hits do not load the spring.
- Derive stop load from accumulated normal impulse divided by the master step.

No dependency sources, vehicle mass, gas model, thrust, spring/damper settings,
authored travel, or standard eight physics substeps were changed.

## Production evidence

Measurements use the normal headful production executable and an isolated API
session on port 4518. Heights below are the vehicle reference position, not
clearance above the ground. The repeated case has two 0.3 s lift commands at
1.5 s and 4.5 s. The held case holds the same valve for 10 s.

| Measurement | Before | Repaired |
| --- | ---: | ---: |
| Repeated case, first powered apex | 6.127 m | 6.127 m |
| Repeated case, later maximum height | 13.005 m | 2.821 m |
| Repeated case, maximum compression | 94.910 mm | 65.001 mm |
| Held case, first powered apex | 64.980 m | 64.980 m |
| Held case, height after touchdown | over 282 m | 0.588 m maximum |
| Held case, maximum compression | 276.265 mm | 65.004 mm |

Both authored regressions pass all three assertions: actual takeoff/touchdown,
no higher post-landing launch, and at most 65 mm compression plus 3 mm solver
tolerance. A separate native-input run completed six K presses, with Tab
refills between them; every landing settled without an escalating bounce.
Evidence is in `results/repeated-native-k.json` and the jump regression receipts.

Run the repeatable gates against an owned interactive session:

```sh
python3 scripts/check_jump_rebound.py --port 4518
python3 scripts/check_jump_rebound.py --port 4518 --held
python3 scripts/check_controls.py --port 4518
```

The engine build passed, and `cargo test -p lunco-mobility --lib raycast -j 4`
passed 11 tests, with one ignored benchmark. This qualifies the reported Roadster
landing cases and the focused wheel tests; it is not a complete moving-support
or packaged-platform qualification.

Architecture follow-up added 54 generic native-stop impact cases covering mass,
penetration, off-centre contacts, static/dynamic/kinematic supports, energy,
momentum, reported reaction and separation. Production rover driving parity,
rocker-bogie driving, paused wheel effort and static wheel contact gates passed.
The shared-owner review is
`optimization/docs/reviews/raycast-stop-energy-2026-10-25.md`.

## Other controls

The cinematic scenario delegated startup and events to `driver_setup.rhai` but
omitted its `simulation_dependencies` declaration. Modelica-origin intent
events were rejected, breaking F and Tab. The wrapper now forwards that
declaration. Driver startup explicitly subscribes to its events and reports
failed control acquisition instead of leaving an apparently controllable car.

The input regression also checks valve release, corner selection, physical
mass, driving in both directions, steering, both brake keys, fan toggle edges,
refill, both Ctrl+P combinations and camera cycling.
The complete keyboard/HUD regression passes all 31 checks; the receipt is
`results/controls.json`.

HUD buttons had a separate host integration failure: `bevy_hui` 0.8 does not
enable its `picking` feature by default. Without it, HTML buttons are decorative
nodes and their press observer is absent. The runtime UI crate now opts into
that supported feature, keeping input handling in the shared UI library.

The workbench also classified native HUD regions as egui chrome and emitted a
synthetic capture hit above their real button hits. `ScenePickGate` now records
native UI ownership separately from egui and scene ownership. Native buttons
receive their own picking events, while scene input stays blocked. Ownership
remains latched during a press/drag, and foreground egui overlays take priority.
The shared gate's 18 tests pass; the production HUD probe passes fan, temperature,
cutoff, unlimited air, refill, autopilot, manual takeover and retry checks.

## Engine version

These changes require the shared engine fixes on `optimization`: physics commit
`342520226` and native UI commit `6fdfc3410`. Updating the Twin alone cannot fix
an older executable. For this local checkout, launch the rebuilt engine with:

```sh
LUNCOSIM_BIN=/home/rod/Documents/luncosim-workspace/optimization/target/debug/luncosim \
  LUNCOSIM_ISOLATED_RUN=1 ./scripts/start.sh roadster_cinematic --api 4518
```
