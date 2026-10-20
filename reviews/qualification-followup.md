# Automated qualification follow-up — 2026-10-20

This records the checks completed for `29fdb24`. See the later
[counterclockwise flip correction](counterclockwise-roll.md) for the current
roll direction and course evidence. Older reports retain their own source
fingerprints; they are not silently relabeled as runs of the later guidance.

## Battery assumptions with sources

The user requested public-information assumptions and source comments, and
excluded compatibility checks. `BatteryStudy.mo` records source URLs and A-B01
through A-B06 beside each reported value, inference and selected parameter.
The [battery note](../references/battery-study.md) explains the 120 kWh nominal
choice, 110–140 kWh sensitivity, older-cell proxies and validity limits.

The reference 1700 kg dry vehicle already includes the reference battery. Changing
capacity updates both energy and native mass/inertia through Modelica. Its mass
is not added a second time. This is a source-informed study, not manufacturer
calibration. Range and charge outputs are sizing requirements/proxies, not
validated duty-cycle, charging or thermal performance.

## Storage correction

USD local volume opinions previously overrode Thrust's variant selection. The
volume defaults now live in their variants. Thrust has 200 L rear storage, no
cabin volume, and Modelica computes its equal-density inventory from the Rocket
250 kg / 600 L reference. Rocket keeps 250 kg. This does not assert a published
Thrust gas mass. Shared state, pipe restrictions and individual vessel thermal
behavior retain the documented manifold approximation.

## Evidence

`results/qualification-followup.json` indexes the final report hashes, verifies
their source fingerprints and records the OS-input qualification boundary.

- `results/battery-study.json`: four authored cases at 110/120/140 kWh and
  Thrust storage; actual Modelica energy debit matches integrated DC power
  during the 920 W idle observation,
  complete native mass matches the model, all inertia eigenvalues change with
  capacity, and the reference pack is counted once.
- `results/jump-window.json`: 25 offsets plus a repeated nominal trial, with a
  uniform plant/observer fingerprint. The contiguous passing frame interval is
  -6..+6 (-100..+100 ms); adjacent frames fail with physical cube contact. This measures the
  three-cube jump at the authored speed; nominal full-course acceptance is separate.
- `results/os-keyboard.json`: full course through XTEST -> X11 -> winit ->
  native intents is **not currently qualified**. The latest attempt aborted
  before driving because the desktop did not retain the owned window's focus.
  An earlier version completed, but that does not qualify the final guidance.
  Normal keyboard repeat settings remain unchanged. An earlier unexplained
  mid-run D release is not attributed to the user or an unproven engine defect.
- `results/battery-operator.json`: fresh HUD autopilot with active pause,
  driving-key takeover, retry after a real service, complete course and Stop.
  The final isolated run passed 23/23 checks in 24.63 s; completion and flight
  screenshots were inspected.
- `results/battery-keyboard.json`: the final isolated native keyboard run passed
  19/19 checks, including the full course, rolling refills, finite inventory,
  clean cube clearance, road landing, four-wheel stop, pause and completion HUD.
- `results/native-hold.json`: repeated native key events retain consumed
  steering/throttle commands for three wall-clock seconds each, and release
  clears them. Live solver aliases are observed; authored input defaults are
  not mistaken for current consumed values. This does not qualify OS delivery.
- `results/dynamic-timing.json` and `results/launch-report.json`: updated source-linked
  nominal/negative mission verification and standing-start launch.

Source and executable fingerprints are in the reports. The tests use production
native physics and Modelica, with no added Rust or dependency changes.

## Steering guidance correction

A fresh retry exposed lane drift and a missed first refill. The digital pilot
was comparing the target against the current wheel heading without anticipating
the existing command smoothing and steering rack lag. `SteeringDriver.mo` now
publishes rack velocity; `CoursePilot.mo` predicts wheel heading over the sum of
those two time constants (0.05 + 0.12 s). A-C01 is a controller assumption, not a
Tesla steering calibration. Tire/contact forces and steering geometry remain
the physical plant. Two fresh HUD/operator runs completed after this correction;
the final timing sweep and mission matrix use the corrected guidance. A later
parallel-window test attempt was rejected by the input/mission guards; final
windowed qualification is run sequentially to exclude competing test windows.

## Scope remaining

Compatibility/Omniverse qualification is outside the user's requested scope.
Human manual completion is deferred at the user's request. Manufacturer-specific
cell, motor, fan, tire, geometry and thermal maps are unavailable; the explicit
assumptions and sensitivity checks bound what this study establishes.
All owned test/authoring runtimes were closed; ports 4198–4201 were released.
