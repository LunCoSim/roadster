# Test layout

- `python/` contains host-side checks and runners. They launch or connect to LunCoSim, inspect the native API, inject desktop input, and collect evidence.
- `../scenes/tests/` contains USD fixtures used by the Twin.
- `../scenarios/tests/` contains Rhai checks that run inside LunCoSim.
- [manual-course.md](manual-course.md) is the human acceptance procedure.

The USD and Rhai fixture paths are part of the Twin: `twin.toml`, scene source assets, and test runners refer to them. Keep these fixtures in their current folders unless migrating all those references together.

Run the host-side checks from the project root. Their generated reports and captures go to the ignored [`results/`](../results/README.md) directory.

The X11 input helper injects Linux evdev physical scancodes, so its key
positions do not depend on the active keyboard layout. `check_os_hold.py`
checks the existing `W`/`D` holds and a Twin-bound `KeyJ` control through the
real X11 → Winit → controller path.
