# Contact qualification

The current contact realization and numerical qualification are maintained in
[wheel contact](wheel-contact.md). Use that record for supported operating
conditions and open impact/travel/course failures. The authored production
gates remain authoritative; nominal driving does not qualify crash dynamics.

The shared engine owns collider cooking, geometric contacts and the raycast
wheel mechanism. Modelica owns motor, air, thermal and mass equations; USD owns
geometry and wheel parameters; Rhai owns mission sequencing and acceptance.
Vehicle-local transforms provide one coordinate contract for contact and render
presentation. The centered crowned mesh is bound independently of the axle.
