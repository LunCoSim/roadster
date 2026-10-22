# USD and Omniverse interoperability

The chassis uses standard USD rigid-body, mass, collision and material schemas.
Its cabin is a convex mesh hull. The four wheel attachments use standard PhysX
wheel, tire and suspension properties plus the registered LunCo coupling fields.
They are query wheels under one rigid body; their centered render children are
ordinary descendants. Their local mounts inherit the vehicle placement.

Modelica owns continuous motor, air, thermal and aerodynamic equations. Rhai owns
mission sequencing and controls. An inert USD stage does not execute either
runtime. This asset does not apply `PhysxVehicleAPI` to install a second vehicle
solver. NVIDIA Omniverse execution has not been qualified; schema reuse alone
does not establish equivalent behavior in another simulator.

Run the production lint and authored scene gates through LunCoSim. The graphical
`scenarios/tests/wheel_visual_contract.rhai` verifies render/contact ownership.
See [wheel contact](wheel-contact.md) for the current realization, measured
qualification and remaining boundaries. Native mesh wheel colliders remain
available in the engine but are linted as potentially unstable; the Roadster's
four wheels do not use that realization.

## Primary references

- [OpenUSD physics schemas](https://openusd.org/release/api/usd_physics_page_front.html)
- [NVIDIA vehicle wheel attachment](https://docs.omniverse.nvidia.com/kit/docs/omni_usd_schema_physics/latest/physxschema/class_physx_schema_physx_vehicle_wheel_attachment_a_p_i.html)
- [NVIDIA vehicle simulation](https://docs.omniverse.nvidia.com/kit/docs/omni_physics/latest/dev_guide/vehicles/vehicles.html)
