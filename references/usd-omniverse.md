# USD and Omniverse interoperability

The authoritative rigid mechanism is authored in USD. This study uses
`PhysicsRigidBodyAPI`, `PhysicsMassAPI`, `PhysicsCollisionAPI`, standard
prismatic/revolute joints, `PhysicsDriveAPI`, and physics-purpose material
bindings. Wheel colliders have their own masses, inertias and CCD settings.
The scene also enables PhysX CCD; NVIDIA requires scene and body enablement.

## Frames and ownership

Omniverse requires a transform-stack reset for a rigid body nested below
another rigid body. Every independently moving wheel, carrier and knuckle has
`!resetXformStack!`. Scene instances explicitly author their initial world
poses. After changing the root placement, call
`author_usd_physics.place_vehicle(doc)` through the live document API. This
keeps reset bodies in the intended initial position and orientation.

Both local anchors and bases are authored on every joint. The standard USD
zero-anchor defaults do not infer a wheel mount from its transform. Front
steering uses finite force-based angular drives; angular drive gains are
expressed per degree, as required by the USD schema.

The `physxVehicleWheelAttachment:tire` relationship is not repurposed as a
material selector. Each wheel directly composes `PhysxVehicleTireAPI` and leaves
that relationship empty. Rigid contact friction instead uses a `Material`
carrying `PhysicsMaterialAPI` through `material:binding:physics`. LunCoSim
projects that contact through its native solver without also adding a separate
vehicle slip-force layer.

## Verification boundary

Run `python3 scripts/check_usd_standard.py` against the owned native API on
port 4198. Its composed-stage audit checks ten independent moving parts, ten
joints, attachment endpoint exclusivity/types, physics material bindings,
Earth gravity and the initial poses across all 30 vehicle scenes. Results are
in [usd-standard.json](../results/usd-standard.json).

This is an authored-schema and placement audit. NVIDIA Omniverse/PhysX has not
been executed here. LunCoSim uses Avian for contact/joints and Modelica for
continuous air, thermal, motor and aerodynamic equations. Modelica, Rhai,
custom WGSL effects and the `lunco://` asset resolver require their runtime
integrations; they do not execute merely by opening a USD stage in Omniverse.
The asset does not apply `PhysxVehicleAPI` to invoke a second vehicle solver on
top of its explicit rigid-body suspension.

The drop, both side-recovery and finite-floor gates pass 20-second runs with
local core `d0b091908`. Boosted 0–60 mph is 0.554 s; motor-only is 3.064 s.
All four ramp approaches pass their unchanged gates with full throttle after
entry. The full keyboard landing remains open. The approved focused Parry fixes are committed locally
and have not been published.
A passing schema audit does not establish landing or driving fidelity.
See [the current review](../results/contact-physics-review.json) and
[the investigation](contact-analysis.md).

## Primary references

- [OpenUSD physics schema: bodies, joint frames, drives and materials](https://openusd.org/release/api/usd_physics_page_front.html)
- [Omniverse nested rigid-body requirement](https://docs.omniverse.nvidia.com/kit/docs/asset-requirements/latest/capabilities/physics_bodies/physics_rigid_bodies/requirements/rigid-body-no-nesting.html)
- [NVIDIA wheel attachment endpoint contract](https://docs.omniverse.nvidia.com/kit/docs/omni_usd_schema_physics/latest/physxschema/class_physx_schema_physx_vehicle_wheel_attachment_a_p_i.html)
- [Omniverse rigid-body materials and CCD](https://docs.omniverse.nvidia.com/kit/docs/omni_physics/latest/dev_guide/rigid_bodies_articulations/rigid_bodies.html)
