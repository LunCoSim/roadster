# Manual course and camera acceptance

Start `./scripts/start.sh roadster_skill_course --api 4198` with the matching main
runtime. Use a fresh course and finite air. Record the build and any failed step.

1. Wait for physics admission. Verify speed, air, fans, course and autopilot HUD.
2. Hold W once, release once. It must drive until release without repeat events.
3. Retry. Follow the HUD suggestions through launch, both instant refill gates,
   three block jumps, fan climb, crest release and a four-wheel landing.
4. During the crest trick, C must actuate rear jets without selecting another
   camera. V cycles views; choose Avatar to return. The default follow view should
   move to the side of the steep ramp and show the car beneath the return lip.
5. Ctrl+P pauses physical motion and course time. Inspect Modelica and USD.
6. While paused, tune the view with the native inspector or:
   `python3 scripts/camera.py --distance 18 --height 1 --tilt -20 --damping .9`.
   Test `--mode stabilized`, `--mode heading` and `--mode body`. Stabilized holds
   the external heading; body follows pitch/roll/yaw and may be disorienting.
7. Edit `scripting/policy/roadster_camera.rhai`, then use
   `python3 scripts/camera.py --reload-policy`. It should change the view without
   reloading the vehicle, refilling, or advancing paused physics.
8. Retry. Click RUN AUTOPILOT and let the same course tree complete. Ctrl+P must
   pause/resume it. Retry again, start autopilot, then press a driving/jet key:
   manual input must take over immediately and the HUD must show autopilot OFF.
9. Test F and the fan button, Tab/refill, temperature selection, unlimited-air
   toggle and retry. Finite-air acceptance must use only the two green services.

Automated reproduction:

```
python3 tests/python/check_keyboard_course.py --launch --manual --binary /path/to/luncosim
python3 tests/python/check_keyboard_course.py --launch --manual --autopilot --binary /path/to/luncosim
python3 tests/python/check_keyboard_course.py --launch --manual --autopilot --operator-checks --binary /path/to/luncosim
python3 tests/python/check_camera.py --port 4198
```

The camera check holds physics and leaves it held. Run it in a separate session
from a course acceptance client. `--manual` means exact native stepping between
observations, not a different physical model. These are injected native window
events; physical OS keyboard delivery still requires a human check.

## Dynamic run

Use the compact course, finite air and 293.15 K refill. The old roll/yaw/backward
checkpoint is retained in `df958b5`; the current default must land nose away.

- After the countdown, W + Space through the blue launch gate. Carry speed;
  both green gates refill mass and temperature immediately without a stop.
- Fans OFF through the cubes. Aim for 126 km/h and pulse K at the yellow line,
  about 0.3 s. Release W while airborne to avoid adding wheel-spin reaction.
  WASD still controls motors directly. The corridor minimum is 90 km/h.
- Deliberately jump early and late on separate retries. Verify physical cube
  contact or missed clearance, failure, and a fresh reset after RETRY COURSE.
- After clearing the cubes, K cushions the fast landing before the second
  refill. Then F fans ON. Carry speed onto the ramp, then ease to
  23 km/h on the upper curve. Verify sealed fan state while inverted.
- At the crest, F OFF. E initiates the counterclockwise roll when viewed from
  behind toward the nose; Q counterpulses before over-rotation.
  Keep the nose away from the ramp, use J/L and R/C to trim, and K to cushion.
  Bank inward if drifting sideways; Shift on contact until stopped.
- Completion must show four wheel contacts and nose away inside the green road
  area. Watch for wheel/body penetration, camera clipping and unexpected holds.
- Run the HUD autopilot from a fresh retry. Use the same visible checkpoints.
  Test takeover and Ctrl+P separately; both should retain the ordinary physics.

Record manual observations independently: automated native window injection is
not evidence that a human has completed these steps with OS keyboard delivery.
See [the dynamic course design](../references/dynamic-course.md) for math,
measurements and the timing matrix command.

The `--operator-checks` run uses the native HUD and keyboard path to pause an
active autopilot, verify frozen pose/inventory/time, resume without takeover,
press W to take over, and click RETRY COURSE after the first waypoint. It checks
that the same Twin mount remains open while air, mission state, and ownership
reset, then completes the full course and stops the pilot through its HUD
button. Public prim IDs remain stable across the runtime reset. The operator checks run in their own
window and port. Avoid using that window's keys during automation.

## Automated OS input

`python3 tests/python/check_keyboard_course.py --launch --manual --input-backend x11 --binary /path/to/luncosim --output results/os-keyboard.json`

This uses XTEST through the X11 window manager and winit, targeting only the
owned process/window. It requires python-xlib and XTEST, takes foreground focus,
checks focus before input, and releases its own held keys on exit. Physical
keyboard repeat settings remain unchanged. Avoid interacting with this window
during automation. It is synthetic OS input; human course completion is separate.

`python3 tests/python/check_os_hold.py --binary /path/to/luncosim`

This focused OS test holds D and W for three wall-clock seconds each while normal
key repeat stays enabled, sampling the X server key state and native steering /
throttle commands. It also checks release. Run it alone so another test window
cannot take focus; focus loss aborts the run.

For a focused native repeat regression without OS delivery, use
`python3 tests/python/check_os_hold.py --input-backend native --output results/native-hold.json --binary /path/to/luncosim`.
It injects `Pressed` events with `repeat=True`, checks the live solver's consumed
steering/throttle aliases throughout each hold, then verifies release. It does
not qualify the desktop input path. Run windowed tests sequentially.

`python3 tests/python/check_jump_window.py --binary /path/to/luncosim` uses an owned
USD-authoring API on port 4198 to measure the jump window on the native 60 Hz
frame grid. It stops after the three cubes or a measured mission miss, so its
result qualifies that jump and authored speed rather than the entire course at
every tested offset. The nominal whole-course gates remain separate.
