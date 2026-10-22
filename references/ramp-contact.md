# Ramp contact qualification

The current Roadster uses raycast wheels with all seven native chassis collision
parts enabled. The ramp drive and all four entry gates pass on regular production core
`3844088aa`: 11/25/40 m/s with fans and 25 m/s without fans. Entry retains the 0.75 m/s per-tick speed-loss bound,
1000 N s chassis-impulse bound and required transition climb. The compact full-course gate separately passes all seven SysML checks with
continuous Modelica steering and the explicit flexible-skirt assumption
described in [dynamics](dynamics.md#ramp-and-course).

The entry fixture controls approach speed, then holds full throttle on the
transition. It observes published wheel contact, shaft speed, normal force and
visual hub compression. Chassis impulses come from native Avian contact pairs.
These are distinct measurements; query-wheel support is a force, not a native
wheel collision impulse. Exact triangle meshes use the engine's maintained
internal-edge correction.

Use `scripts/author_ramp_entry_checks.py` through an owned live document API to
regenerate fixtures and `scripts/run_ramp_entries.py --binary /path/to/luncosim`
to execute the production matrix. See [wheel contact](wheel-contact.md) for the
current realization and unresolved operating boundaries.
