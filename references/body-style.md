# Reveal-inspired Roadster body — 2026-10-20

This original procedural mesh follows the redesigned white Roadster, rather
than the older red 2017 concept. Photo proportions are visual references, not
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

`scripts/author_body_style.py` creates the visual shell using OpenFile,
ApplyUsdOps and SaveDocument. Longitudinal deck stations define the hood and
shoulder line independently of the wheel openings. Circular apertures cut only
the side panels; their recessed dark returns give visible wheel-well depth.
The old contact-authoring step raised all six vertices in each body section to
clear a tire envelope, creating conspicuous full-width humps. It now owns only
the existing collision envelopes, leaving visual authoring separate.

The revision adds dark side windows, narrow white A-pillars and roof rails,
rear buttresses, a roof spine, a continuous front light strip, closed triangular
headlamp-door seams, a black front/rear fascia and a low rear deck lip. Surface
winding points outward. All dimensions and materials remain study choices.

The existing collider shapes, rigid-body parameters, wheel mounts, suspension,
thruster force stations and Modelica plant are retained. The new meshes have
collision disabled and introduce no rigid bodies. Existing headlight sources
continue to light the road; cosmetic lamp doors do not add photometric claims.

Before/after native renders are `results/body-before-{front,side}.png` and
`results/body-after-{front,side,rear}.png`. These show the appearance on a fresh
production scene load; no new dynamics acceptance is claimed for a visual edit.


## Shared materials and exhaust visibility

The canonical body material has a clearcoat weight of 0.8 and clearcoat
roughness of 0.08. The rear and perimeter jet meshes use a 1.6 × 2.2 × 1.6
visual scale, with denser cool-white mixing mist. The shader preserves the
near-nozzle radius while extending the visible envelope. Exhaust remains gated
by the live force; there is no plume when the jet is off.

These are shared appearance choices, used by normal scenes and film scenes.
They do not change nozzle area, mass flow, force stations or vehicle dynamics.
The plume is enhanced for visibility and is not a calibrated CFD result.
`tools/roadster_appearance.rhai` provides the native USD dry plan. The document
owner applied and saved the component changes; twelve material/transform values
were read back. A native 1,980-image, 60 fps course take from the canonical Twin
was reviewed for the enhanced jets and car finish. This is visual evidence,
not hardware validation or a new claim about Tesla's exhaust.
