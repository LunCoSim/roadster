# Known presentation issue

## Night-course clustered lighting

The last recorded native investigation found rectangular dark steps in the lit
ground outside the cinematic runway, present in the source render rather than
introduced by video export. Normal clustered rendering reproduced them; so did
an isolated light and CPU rendering. A CPU single-cluster diagnostic removed
the steps, which points to spatial cluster assignment or lookup. The exact
faulty bound/index calculation was not isolated. Temporary diagnostic switches
were removed; no workaround is shipped, and the issue was not confirmed fixed.
Do not treat an exported video or a different lighting path as proof of a
production repair.

## Jet plume clipping

`tools/air_jet_occlusion.rhai` authors one native `SurfaceProbe` per jet. Each probe measures along the jet mesh's local +Y axis; the owning body is excluded. The plume shader stops at the nearest measured solid, while a missed query retains the authored plume length. This is a visibility effect, not CFD or a force calculation.
