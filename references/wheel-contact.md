# Wheel contact and presentation

The Roadster uses four analytical raycast wheels attached to one vehicle rigid
body. Standard PhysX wheel, tire and suspension APIs supply radius, inertia,
braking, stiffness and damping. The shared mobility engine resolves road contact;
Modelica owns motor torque, steering, stored air, aerodynamics and mass properties.
The cabin retains its convex mesh hull and all seven chassis collision parts.

Each wheel is an ordinary vehicle-local Xform. Its mechanical axle is X and its
suspension direction is local −Y. Scene placement therefore moves the complete
vehicle without independent body-placement calculations. The centered
`CrownedVisual` child has render purpose and is the only tire mesh. It rolls
around the mechanical axle and moves with the measured suspension compression.
Neither the mount nor its visual contributes a native wheel collider.

The contact radius is 0.34 m. Front width is 0.25 m and rear width is 0.30 m;
the crowned visual tapers to 0.30 m at its shoulders. These are study assumptions,
not manufacturer calibration. Standard PhysX fields retain their schema precision.
The tire WESL shader uses mesh-local position and an explicit axle direction.
`tools/crowned_tire.rhai` and `scripts/author_tire_profile.rhai` author the visual
through the document journal. The single chassis carries the complete Modelica
vehicle mass, COM and inertia, including its running gear and stored air.

## Production qualification

Regular production core `3844088aa` passes wall holding/release, steering at
5/15/30 m/s, ramp drive, all four 11/25/40 m/s fan-on and 25 m/s fan-off entry cases,
battery mass/energy balance at 120 kWh, motor-only launch and
the moving-jump gate. The complete course passes all seven SysML checks in
29.18 simulated seconds with the explicit flexible-skirt assumption and
continuous Modelica steering described in [dynamics](dynamics.md#ramp-and-course).
Steering retains its original ±25% response bound.
The five-second wall hold descends 0.37 m with four contacts and 39.999 kN suction;
fan release then produces a fall. This finite-slip tire law does not establish
exact static parking. Motor-only 0–60 mph is 1.581 s in the study model;
measured gas inventory stays constant during that launch. These observations
are not manufacturer performance claims.

Roof impact and suspension travel under drop conditions remain unqualified.
Their production gates retain their failure verdicts;
passing nominal driving does not qualify crash behavior or an unrestricted
landing envelope. Ray queries do not represent tire carcass deformation, broad
obstacle sweeping or damage. The short-skirt negative case detects loss of
fan-supported climb and pauses
the complete coupled vehicle, with a visible shared-HUD status and measured
Recent Events explanation. The linear suspension currently lacks mechanical
travel stops. Do not treat its probe length as a validated bump limit.

The graphical wheel gate passes all 14 checks, with inspected close-up views.
It separately checks four collider-free wheel mounts,
one crowned render surface per wheel, material resolution, the cabin mesh and
complete vehicle mass. Evidence is retained under the engine checkout's
`.cache/codex-evidence/physics-followup-20261021/raycast-roadster/`.
