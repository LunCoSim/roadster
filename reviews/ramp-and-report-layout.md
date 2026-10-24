# Narrow ramp and native report workspace

The shared course keeps its existing Y/Z driving curve and 18.872768 m driving
surface height. Its contact mesh is scaled only on X, from 14 m to 5 m. The
edge strips occupy ±2.30..2.45 m; the white centre stripe is unchanged.

`tools/ramp_display.rhai` owns the authored width and visual steelwork recipe.
The steel frame follows the back of the existing curve. It is visual geometry
with collision disabled. It stops before the upper return deck so that the
landing area remains clear. `scenarios/author_ramp_display.rhai` is an explicit
Editor operation, separate from vehicle runtime control.

Native readback and live raycasts on engine `5dfba8111` confirmed that the upper
support surface is at 19.472767 m for X=0 and ±2.4 m. At ±2.6 m the rays reach
the ground instead. Source mesh points and the Y/Z curve were preserved.

The v15 full-course capture completed all course stages and both services,
with 1800 images, 1800 completed 60 Hz physics cycles and the native experiment
verdict passing. Film evidence is retained in the marketing episode's
`renders/sources/v15_course/`; this is a course-run check, not a fresh sweep
of all ramp-entry speeds.

The Twin policy now provides `report-workspace`: viewport above, canonical
Graphs dock below and Telemetry alongside. It retains normal dock headers.
Existing floating analysis grids remain borderless. The normal cinematic scene
uses this shared policy instead of carrying an inline copy of film layout code.
The film extends the same source at its own policy authoring boundary.

Verified in an owned native window on port 4499. The policy compiled and the
runtime registered the workspace with the canonical Graphs instance in the
bottom slot. Moving-window capture is checked separately in the film package.
No vehicle plant, mass, inertia, wheel or controller was changed in this update.
