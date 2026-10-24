# Shared Roadster body, 24 October 2026

The canonical `components/body.usda` now uses the reference's automotive
cross-section profile: shaped sill, shoulder, beltline, roof rail and fastback.
It is a procedural visual study, not Tesla CAD. The MIT notice and source
revision are retained under `references/licenses/` and `references/body-style.md`.

The recipe is `tools/reveal_body.rhai`; `scenarios/author_body.rhai` is its
explicit native authoring program. The two superseded Python body generators
are removed. Existing native paint, carbon and glass materials are used.
Material boundaries and wheel openings are geometry, with dark inner liners;
there is no added custom body shader. The red tail emission is increased and
the lamp/deck lip fitted to the new surface.

## Verification

Native document readback after saving and reloading the cinematic assembly:

- 727 visual meshes, 47,208 vertices and 44,164 triangles in the shell.
- Zero invalid normal vectors, reversed triangles or degenerate triangles.
- Four bindings: White, Carbon, Glass and SideGlass.
- Shell bounds: X ±0.9937663 m, Y −0.3607284…0.6319535 m, Z ±2.25 m.
- Every shell mesh has collision disabled.
- All seven pre-existing chassis collider blocks are unchanged, including the
  CabinCollider vertex data. Wheel mounts, masses, inertia and force stations
  are outside this edit.
- Production preflight passed for the body component and both Rhai sources.
- Native front, side and rear views were inspected in the cinematic assembly;
  the back is closed and the window boundaries are clean. Captures and numeric
  receipts are in ignored `.scratch/rear-and-lighting-review/` and
  `.scratch/body-native-geometry-check.json`.

The nose is concave: a cap from the mean vertex position inverted eight tiny
triangles. The cap now uses an interior point computed from the cross-section's
visibility kernel. The final native readback contains no reversed triangles.

A memory-pressure kill interrupted the authoring session after the sections
were complete. Their exact retained Editor specs were recovered through typed
`RestorePrim` operations from the native workspace autosave. No geometry was
recomputed for that recovery and no USD file was written outside SaveDocument.
The two rear cap sections were then completed through the native recipe.

This is a visual acceptance. New driving, ramp-width acceptance and v15 capture
remain separate work. This change does not qualify an old recording against a
new engine or claim complete path-tracer compatibility for the vehicle/stage.
