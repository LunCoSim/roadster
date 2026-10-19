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
python3 scripts/check_keyboard_course.py --launch --manual --binary /path/to/luncosim
python3 scripts/check_keyboard_course.py --launch --manual --autopilot --binary /path/to/luncosim
python3 scripts/check_camera.py --port 4198
```

The camera check holds physics and leaves it held. Run it in a separate session
from a course acceptance client. `--manual` means exact native stepping between
observations, not a different physical model. These are injected native window
events; physical OS keyboard delivery still requires a human check.

The demonstrated yaw-based backward turn is a separate pending maneuver. The
current passing tree recovers through pitch; do not record it as a verified
reproduction of Tesla's complete stunt choreography.
