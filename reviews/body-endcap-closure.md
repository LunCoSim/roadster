# Body end-cap closure

The crowned Skin deck reaches local Y=0.332 m at the rear, while the old flat
end cap stopped at Y=0.255 m. This left a 77 mm opening under the deck. The front
cap had the same construction error. A smaller fascia applied farther aft did
not join this deck boundary.

The native USD document owner replaced only the two Skin end caps with 32
transverse strips each, matching the actual existing deck vertices. Their
normals point outward. All 25,024 non-cap points and normals are unchanged;
materials, colliders, mass, wheel setup and thruster geometry are untouched.
Both body-authoring scripts now close caps against their sampled deck profile.

Validation: native ApplyUsdOps generation 4 accepted without diagnostics, then
SaveDocument wrote the shared component. Source readback verified identical
non-cap data, complete point/normal/topology cardinality and exactly two faces
at every welded deck-to-cap edge on both ends. Python syntax and scoped diff
checks pass. A fresh production scene load on owned API port 4499 confirms the
solid rear surface. This is a cosmetic mesh check, not dynamics qualification.

The current encoded report retains its original captured mesh. Replacing its
moving sources requires new native takes after the separate lighting-cluster
artifact is diagnosed; no old take is relabelled as repaired footage.
