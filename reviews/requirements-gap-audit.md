# Roadster gap audit — 2026-10-20

## Closed gaps

- Corrected the default track's SysML height from the historical 64.46 m ramp to
  18.872767558 m. The separate original practice ramp remains unchanged.
- Registered `Roadster::VerifySkillCourse`, with seven source-linked SysML
  requirements for continuous motion, clean cube clearance, rolling services,
  fan-supported climbing, the return-road landing, descent severity and finite
  inventory/native mass. The observer binds measured values to formal criteria;
  unavailable measurements remain unavailable. Fan height, seal and suction are
  sampled together and their limits are evaluated in SysML.
- Made actual cube impacts fail the production mission tree. Native contact
  queries are filtered by cube and by chassis/wheel body; tire-ground contact
  does not count. The same pair evidence is used in both acceptance clients.
- Added latched failure reasons: Modelica owns continuous health classification,
  Rhai owns discrete task/native collision failure, and the HUD names the cause.
- Added active-autopilot pause, W takeover and real HUD retry coverage after the
  first service. Retry must keep the same Twin mount, clear an existing service
  record, restore air and restart the course clock through scene runtime reset.
  Public prim IDs remain stable. The client admits the first fixed cycles of a ready, held Idle model
  before waiting for Running; it does not alter vehicle state.
- Fixed the completed autopilot's STOP button guard. Starting a new pilot after
  completion still requires retry; stopping the active completed pilot works.
- Added a final HUD completion check and screenshot after presentation catches
  up with physics. Native pointer/key transitions, telemetry and fingerprints
  are retained in the operator report.

All production edits are inside this Twin: SysML, Modelica, Rhai and two USD
port declarations authored through OpenFile/ApplyUsdOps/SaveDocument. No Rust,
engine or dependency source was changed. No force law, collision geometry or
plant calibration was adjusted in this audit.

## Acceptance evidence

See `results/dynamic-timing.json` for the source/binary fingerprints and nominal,
early and late headless runs. The nominal formal report is embedded in
`results/dynamic-check.json`; `results/gap-keyboard.json` and
`results/gap-operator.json` retain native-window course checks. The selected
collision HUD was also observed through ReadExposures and rendered with vehicle
possession (`results/gap-failure-hud.json` and its screenshot).

| Check | Result |
|---|---|
| Registered course verification | 7/7 source-linked requirements pass; current follow-up complete in 24.65 s |
| Early +0.3 s / late -0.2 s guidance | Both fail with code 6 and current cube impulses 24,234 / 133,355 N s |
| Native keyboard course | 19/19 pass; full route, zero cube impact, four-wheel stop |
| HUD autopilot + operator sequence | 23/23 pass, including pause, takeover, service reset and completed-pilot Stop |
| Registered launch verification | Pass; current standing-start 0–60 mph 0.559312 s |
| Collision HUD | Correct failure text observed and rendered |
| Python syntax / git diff whitespace | Pass |

Commands:

```sh
python3 scripts/check_course_timing.py --binary /path/to/luncosim
python3 scripts/check_keyboard_course.py --launch --manual --binary /path/to/luncosim
python3 scripts/check_keyboard_course.py --launch --manual --autopilot --operator-checks --binary /path/to/luncosim
python3 scripts/run_launch.py --binary /path/to/luncosim
```

Run windowed clients sequentially on owned ports and avoid typing in their windows.
All clients use native physics. Manual stepping controls admission, without
changing the physical timestep or actuator model.

## Follow-up status

See [the automated qualification follow-up](qualification-followup.md) for the
source-commented battery assumptions, corrected Thrust storage, measured timing
window and OS input checks. Compatibility work is outside scope at the user's
request, and human completion is deferred. Manufacturer calibration remains an
external-data boundary; explicit study assumptions are used instead.
