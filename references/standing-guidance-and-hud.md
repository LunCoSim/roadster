# Standing demonstrations and fan status

23 October 2026. Guidance and display changes only; wheel/contact and physical
force equations are unchanged.

`course_transit_speed_mps` is a pilot request. Its default remains 35 m/s for
the course. Setting it to zero allows the existing jump/roll pilot to perform
a standing demonstration without accelerating the driven wheels. It never
sets a physical velocity or pose. The film's Rhai sequences pilot phases;
the canonical Modelica connection carries the continuous pilot commands.

Native shared-model takes v46/v47 completed a full standing roll and settled
upright. Their maximum motor throttle/drive request was zero; longitudinal
position stayed within 0.6 mm of its start. The v48 default course also
completed with the unchanged default cruise request. These are bounded
scenario results, not hardware validation. Earlier media was removed during
disk cleanup; the native receipts remain in the production log, and fresh
film sources are being captured.

`fan_requested` remains the manual switch state used by the toggle action.
The new public output `fan_commanded` reads the fan model's powered command
after course/flight/manual arbitration. Both the regular HUD and film HUD use
that value for status. The shared vehicle declares the public USD output so
the UI can read it; Modelica output existence alone does not expose it to a
presentation policy. A missing declaration displays unavailable status.

With command off, the HUD reports `FANS STOPPING` above 60 rpm and `FANS OFF`
below it. This is display precision, not a change to the continuous rotor,
pressure, suction or electrical-power states.

Production proof: marketing take `report_shared_fan_switch_v50`, 480 native
60 fps images, one completed 60 Hz coupled cycle per image. At 3 seconds the
command is 1, the rotor is about 14,963 rpm and suction is 39.8 kN; the HUD
shows on/sealed. At 5.5 seconds the command is zero with about 535 rpm; it
shows stopping. The final frame shows off with negligible rotor speed.
Raw key frames were inspected for matching text and clean loading state.
See the film's `delivery/fan_hud_review.json` for video hash and source identity.

Reload an edited Modelica source through its source-root/document lifetime.
A scene-only restart retains the loaded source root and correctly rejects a
conflicting source. Replacing the owned Twin admitted the changed source.
