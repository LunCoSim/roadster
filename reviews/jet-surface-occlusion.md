# Shared cold-air jet surface clipping

The mist shader clips its integration at the nearest solid surface measured by
one mounted `SurfaceProbe` per jet. The probe uses the existing native raycast
owner along local +Y, matching the jet mesh axis. The owning body is excluded by
that sensor's normal contract. A miss leaves the authored plume envelope intact.

`tools/air_jet_occlusion.rhai` authors the probes first, then the connections after
sensor admission. Clearance fields must be declared on the shared Shader as well
as on each mesh override so the material adapter exposes their native input ports.
There are no additional actuators, forces, collision shapes or trajectory writes.
The brighter/wider mist remains a visibility aid, not a CFD result.

Production check: tutorials `1ff56b52c` plus the recorded UI source patch, owned
API 4499, `v15_circuit_final_r4`, 1440 native images at 60 Hz. The native landing
verdict passed. At 21.8 s both visible lift plumes terminate at the deck; at 23.5 s
the car rests upright with no plumes underneath the platform. Headlights illuminate
the deck. The final measured speed was 0.000059 m/s and up alignment approximately 1.
No clearance connection binding failures were reported by that session.
