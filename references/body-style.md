# Reveal-inspired Roadster body — 2026-10-24

The procedural mesh follows the redesigned white Roadster. The current shell
adapts the MIT-licensed body profile from the user-supplied
[Roadster simulator](https://github.com/eduardmur/tesla-roadster-simulator),
fitted to this Twin's existing dimensions and wheel locations. It is not
manufacturer CAD, measured dimensions or a new physical calibration.

## Visual references

- [MotorTrend firsthand reveal gallery](https://www.motortrend.com/news/first-look-2028-tesla-roadster-performance-thrust-rocket/photos).
- [Front and hood photograph](https://hips.hearstapps.com/hmg-prod/images/89c48dff-929c-4672-8999-928a1ed8e43f.jpg): broad uninterrupted hood, tapered corners, thin continuous daytime-running-light strip and concealed triangular lamp doors.
- [Headlamp-door detail](https://hips.hearstapps.com/hmg-prod/images/9e3fb4dd-7383-4d31-9514-fee24532104f.jpg): narrow panel seams rather than separate protruding lamps.
- [Rear photograph](https://hips.hearstapps.com/hmg-prod/images/789ce0cb-ee5a-4b36-a006-dd56af89dd12.jpg): broad black fascia, thin red light strip and integrated deck edge.
- The earlier reveal-side image recorded in the source register is also used
  for the low wedge silhouette and swept greenhouse. Reference downloads stay
  in ignored scratch storage; photographs are not redistributed with the Twin.

## Geometry choices

`tools/reveal_body.rhai` supplies pure typed USD plans. Open the exact body
document and run `tools/author_body.rhai` on a stable application host with
`params.body_document` set to its document ID. The program applies
`setup_plan(existing_paths)`, all 220 `chunk_plan` sections, both `cap_plan` ends
and four wheelhouse liners through the document journal, then saves the complete
result. Keep a different scene rendered during authoring. The general assembly
builder serializes numeric mesh arrays at the USD boundary.

The closed loft has 220 longitudinal intervals, 100 points per section, small
fillets and shared differential normals at section boundaries. Side glass,
fastback canopy, white paint and carbon sill are separate native USD meshes
bound to the existing `UsdPreviewSurface` materials. The wheel openings are
geometric cuts with analytic circle/edge intersections, not shader discards.
Dark inner liners close the sight line through each wheelhouse. The rear light
and deck lip follow the new tail height; the red emission is increased to 8.0.
Both end caps match the exact shell rings.
Wheel openings follow our ±1.375 m axle datums, not the reference's axles.

An earlier cap sat 77 mm below the rear deck and the front had the same gap.
Both end caps were rebuilt as 32 transverse strips matched to their deck rings.
Native readback confirmed the welded edges while retaining all 25,024 non-cap
points and normals. These checks establish mesh closure, not a physical change.

The code adaptation and full MIT notice are documented in
[reveal comparison](reveal-comparison.md) and
`licenses/tesla-roadster-simulator-MIT.txt`. Photographs and audio are not copied.

The existing collider shapes, rigid-body parameters, wheel mounts, suspension,
thruster force stations and Modelica plant are retained. The new meshes have
collision disabled and introduce no rigid bodies. Existing headlight sources
continue to light the road; cosmetic lamp doors do not add photometric claims.

Native front, side and rear captures from the canonical cinematic scene are
kept in ignored `.scratch/rear-and-lighting-review/`. No new dynamics acceptance
is claimed for this visual edit. The shell uses standard materials; compatibility
of the complete vehicle and stage with the reference path tracer remains open
because other custom surfaces and point/spot lights are still present.


## Shared materials and exhaust visibility

The canonical paint has a clearcoat weight of 0.8 and clearcoat
roughness of 0.08. The rear and perimeter jet meshes use a 1.6 × 2.2 × 1.6
visual scale, with denser cool-white mixing mist. The shader preserves the
near-nozzle radius while extending the visible envelope. Exhaust remains gated
by the live force; there is no plume when the jet is off.

These are shared appearance choices, used by normal scenes and film scenes.
They do not change nozzle area, mass flow, force stations or vehicle dynamics.
The plume is enhanced for visibility and is not a calibrated CFD result.
`tools/roadster_appearance.rhai` provides the native USD dry plan. The document
owner applied and saved the component changes; twelve material/transform values
were read back. Sampled frames from a native 1,980-image, 60 fps course take from the
canonical Twin were reviewed for the enhanced jets and car finish. This is visual evidence,
not hardware validation or a new claim about Tesla's exhaust.

## Nose revision — 2026-10-25

The user-supplied front, overhead and low-angle photographs guide this cosmetic
revision. `tools/front_nose.rhai` uses `reveal_body::station` as its dimensional
boundary. The fascia and separate 18 mm splitter blade remain at least 24 mm
inside that station outline. The fascia bottom moves 75 mm rearward and 45 mm
inward; the hood overhangs its top. The splitter wraps the chamfered corners and
its chord tapers from 140 mm at the centre to 15 mm at each side.

A flat hood, crisp corner facets, recessed triangular lamps and a continuous
light seam replace the smooth front sheets. The obsolete `FrontMask` is removed
as well as the rectangular splitter. New side returns retain the existing wheel
opening, and a rear joining mesh meets the original shell cross-section.

`tools/author_body.rhai` finishes with this nose automatically. To update
only the nose, run `tools/author_front_nose.rhai` with the open canonical
`body_document` ID. It applies bounded native document
operations and leaves the preview open for inspection. Save through the document
owner after reviewing; `save: true` is available for an already-reviewed rebuild.
This is the shared body component used by the ordinary and cinematic scenes.

Native Editor screenshots were reviewed from the front, above and a low front
quarter. A dense contour-edge check found a minimum station inset of 24 mm.
All seven collision-enabled body prim blocks remained byte-identical; the four
main collider prims also matched their native before/after snapshots. Vehicle
and Modelica source hashes were unchanged during this nose edit. Every new mesh
has collision disabled. These checks establish a cosmetic revision, not a change
to physical mass, inertia, centre of mass, colliders or force stations.
