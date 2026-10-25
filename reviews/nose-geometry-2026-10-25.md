# Nose geometry review — 2026-10-25

The shared `components/body.usda` now has a profile-matched inset fascia,
separate wrapped splitter, flat hood, faceted corners and triangular light
recesses. The visible light seam continues from the nose into the corner recesses.
The old rectangular splitter and overlapping `FrontMask` are removed.

## Evidence

- Production debug executable rebuilt in the requested `tutorials` worktree.
- Native `ApplyUsdOps` authored the exact Body document; `SaveDocument` saved it.
- The bounded `scenarios/author_front_nose.rhai` program completed all 13 meshes.
  Repeating it and saving produced the identical SHA-256:
  `b277137547f2f57596e6ad195f4a56a70b234aeb5e119595432afbf88078718f`.
- Native readback confirms all 13 new meshes have collision disabled.
- The four main collider snapshots match exactly. All seven collision-enabled
  body source blocks are byte-identical, including both rocker colliders and
  the front crash bar. Vehicle and Modelica files were unchanged by this edit.
- Sampling every fascia/splitter polygon edge at 101 points found a minimum
  24 mm inset from the canonical station half-width. This is a model envelope
  check, not a dimension measured from the reference photographs.
- Native Editor front, overhead and low-quarter screenshots were inspected.
  The complete vehicle preview was also inspected with its wheels attached.
- The integrated full-body authoring recipe compiles. Its nose stage uses the
  same tested part functions; the whole 220-section body rebuild was not rerun.

Local screenshots are under `~/.cache/roadster-v15/`:
`nose-front-final.png`, `nose-top-final.png`, `nose-low-final.png`,
`nose-assembly-final.png`. They are generated evidence, not tracked assets.
The marketing episode's ignored `renders/nose_review/` retains native plans,
collider snapshots, contour results and physical-source hashes.

The runtime closed during the initial review. Its unsaved native document
journal was recovered on reopening; the saved body and the reproducible Rhai
recipe now hold the accepted result. No physical calibration was changed and
no new narrated video master is claimed by this geometry review.

## Production-light follow-up

The rendered night scene exposed an unnecessary narrow shoulder strip. The
side return now runs directly from the retained lower shell to the faceted edge.
Fascia and splitter widths also follow that actual faceted edge, retaining the
24 mm inset. Native authoring saved the revised meshes. All seven
collision-enabled source blocks still match commit `99b3f90` exactly.

The fresh front and wheel-side takes were inspected in the production lighting.
The faceted finish still has sharp highlights; it is not a smooth CAD replica.
Current body SHA-256: `9d4d7d4cdccd32a51319ecc26fb59044c7692e4e97ecbb9e8361c80299a020f3`.
