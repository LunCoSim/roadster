# Roadster Cinematic

The named night showcase is `scenes/roadster_cinematic.usda`. It composes the
shared `roadster_skill_course` and `vehicles/roadster` assets. There is one
physical car and one course policy. Stage lights and track materials supply
the night look; the scene contains no Recorder and uses an interactive startup.

The Twin and shell launcher select this scene by default. The daylight course
remains explicitly selectable. The ordinary Twin launcher composes its own HUD
and normal control-claim policy. Recording stages use a separate runtime asset
directory, so film-only controls and HUD cannot leak into an interactive launch.

The production debug host loaded the cinematic entry on an owned API port.
Readiness reached ready with zero pending operations; normal control admission
returned true, and native startup committed the car camera/possession binding.
The native viewport was inspected with the illuminated course, corrected rear
closure and follow view. This is a scene/startup/appearance check, not a new
qualification of vehicle physics or an assertion about Tesla hardware.
