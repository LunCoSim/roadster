# Loading and wheel-contact investigation

The apparent endless load was a terminal physics failure. The captured
`GetReadiness` response had `pending_count = 0`, `world_hold = false`, and
`faulted = true`; the Roadster Modelica participant was already `Running`.

The native contact/joint closure exhausted its iteration budget and refused
pose writeback. Keeping its physics hold in the transient progress registry
then displayed “Scene loading / Native physics integration is held” indefinitely.
The core repair retires that progress entry on a terminal fault while retaining
the fault and the safety hold.

The vehicle uses collision-backed wheels and explicit spring, steering and
axle joints. A standard `Material` carrying `PhysicsMaterialAPI` is bound with
`material:binding:physics`. It owns native rigid contact; the runtime must not
also apply the vehicle slip-force layer to those same wheel contacts. The
wheel attachment retains its valid direct `PhysxVehicleTireAPI` endpoint.

Nested rigid bodies have transform-stack resets for Omniverse compatibility;
scene instances author each independent body's initial world pose. Joint
anchors and bases are explicit instead of depending on runtime inference. The
authoring audit covered USD facts; it did not certify execution in NVIDIA PhysX.

The production drop/recovery scenes measure suspension travel, actual ground
clearance, delivered thrust and gas state. Native contact-debug penetration is
an intermediate manifold observation; wheel clearance is also measured after
physics writeback. A passing authoring audit does not replace those gates.
