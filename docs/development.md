# Other scenes and project tools

## Scenes

The LunCoSim scenario menu includes the main driving scenes. The default is **Roadster Cinematic**.

| Scene | Use |
|---|---|
| `roadster_cinematic` | Night course and default scene |
| `roadster_skill_course` | Daylight driving challenge |
| `roadster_ramp` | Practice at the stunt ramp |
| `roadster_rocket`, `roadster_thrust`, `roadster_track` | Flat-track vehicle trims |
| `roadster_wall` | Wall-driving practice |
| `tests/roadster_*_check` | Acceptance and measurement scenes |
| `tests/roadster_launch`, `tests/roadster_motor_launch` | Standing-start measurements |

The **Test Scenarios** submenu contains measurement and acceptance scenes. Other scenes can be opened by path. The curated menus are configured in `twin.toml`.

## Launch from a terminal

If the LunCoSim executable is on your `PATH`, start a scene with:

```sh
./scripts/start.sh
./scripts/start.sh roadster_skill_course --api 4198
```

The default is `roadster_cinematic`. Set `LUNCOSIM_BIN` if the executable is not on your `PATH`:

```sh
LUNCOSIM_BIN=/path/to/luncosim ./scripts/start.sh roadster_cinematic --api 4198
```

The launcher opens the selected scene and uses API port 4198 by default. Pass another port with `--api PORT`.

## Run checks

Set `LUNCOSIM_BIN` to the LunCoSim executable when a script needs one. Run scene fixtures through the production runner so both the Rhai verdict and exit code are checked; opening a fixture from the menu is useful for inspection.

The test layout is summarized in [`tests/README.md`](../tests/README.md). Host-side checks live in `tests/python/`; USD fixtures and in-simulator Rhai checks remain under `scenes/tests/` and `scenarios/tests/`.

```sh
python3 tests/python/run_launch.py --binary /path/to/luncosim
python3 tests/python/run_motor_launch.py --binary /path/to/luncosim
python3 tests/python/run_ramp_entries.py --binary /path/to/luncosim
python3 tests/python/run_scene_check.py roadster_course_check ROADSTER_COURSE --verification Roadster::VerifySkillCourse --ticks 2400
python3 tests/python/check_controls.py --port 4198
python3 tests/python/check_jump_rebound.py --port 4198
python3 tests/python/check_jump_rebound.py --port 4198 --held
python3 tests/python/check_driving.py
python3 tests/python/check_effects.py
python3 tests/python/check_keyboard_course.py --launch --manual --binary /path/to/luncosim
```

The HUD's **Run Autopilot** button uses the same behavior tree and Modelica guidance as the keyboard client. Add `--autopilot` to the keyboard-course check to exercise the HUD button. Add `--operator-checks` with `--autopilot --manual --launch` to check pause, manual takeover, retry, and course completion.

For a live session, the direct-load check is `scenarios/tests/default_loading.rhai`. Check native-key and HUD response on an owned session with:

```sh
python3 tests/python/check_controls.py --port 4198 --output-dir .scratch/control-check
```

See [manual course checks](../tests/manual-course.md), the [dynamic course design](../references/dynamic-course.md), [wheel-contact qualification](../references/wheel-contact.md), and [known issues](../references/known-issues.md). Standing-start timing does not subtract rollout.

## Edit the model

- `scripts/scene_documents.py` anchors dependencies to the active Twin’s stable source identity when saving a scene into `scenes/tests/`. Use layer-relative paths for newly authored assets within the same Twin.
- `tools/author_tire_profile.rhai` updates the raycast wheel mounts and crowned tire visuals through the live document API. Local wheel mounts inherit scene placement; one chassis carries the vehicle mass. See [wheel contact](../references/wheel-contact.md).
- `scripts/author_ramp.py` authors the ramp and course through the running USD document API. `scripts/author_dynamic_course.py` applies the compact ramp and timing corridor to the base course. These scripts save typed USD operations and inspect the composed documents; curve sampling creates geometry, not vehicle motion.
- `scripts/study_geometry.py` contains mount study data.

`CompressedAir.mo` provides reusable equation-of-state, sizing, and internal-energy calculations. CoolProp is an optional verification dependency.
