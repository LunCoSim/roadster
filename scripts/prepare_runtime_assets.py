#!/usr/bin/env python3
"""Compose shared UI assets and the Twin HUD without editing the simulator checkout.

The current host admits one application UI manifest. This launcher-local asset
root composes its shared surfaces with the Twin's authored HUD. No Rust/UI build.
"""
import json,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
source=Path(os.environ.get('LUNCO_ASSET_ROOT',str(ROOT.parent.parent/'luncosim-workspace/main/assets'))).resolve()
dest=ROOT/'.scratch/runtime-assets';dest.mkdir(parents=True,exist_ok=True)
# The production asset owner rejects directory symlinks escaping its root.
# Hard links provide a local composition without copying large shared assets.
import shutil
for target in dest.iterdir():
 if target.is_symlink():target.unlink()
def link_file(src,dst):
 target=Path(dst)
 if target.is_symlink():target.unlink()
 if target.exists() and not os.path.samefile(src,dst):target.unlink()
 if not target.exists():os.link(src,dst)
 return str(target)
shutil.copytree(source,dest,copy_function=link_file,dirs_exist_ok=True)
ui=dest/'ui'
for p in (ROOT/'ui').glob('*'):
 target=ui/p.name
 if target.exists() or target.is_symlink():target.unlink()
 os.link(p,target)
# Break the shared manifest hard link before writing the composed manifest.
manifest_target=ui/'runtime_surfaces.json'
if manifest_target.exists():manifest_target.unlink()
manifest=json.loads((source/'ui/runtime_surfaces.json').read_text())
props=['rr_unlimited_label','rr_steering','rr_course_title','rr_course_hint','rr_course_metrics','rr_fill_temperature','rr_speed','rr_mph','rr_air_mass','rr_air_pressure','rr_air_fill','rr_air_width','rr_air_status','rr_air_color','rr_temperature','rr_refill_label','rr_fan_state','rr_fan_label','rr_suction','rr_fan_detail','rr_aero','rr_battery','rr_mode','rr_rates','rr_force','rr_service']
for surface in manifest['surfaces']:
 if surface['id']=='vessel-hud':
  surface.update(template='ui/roadster_hud.html',stylesheet='ui/roadster_hud.css',bindings={p:{'source':p} for p in props})
(ui/'runtime_surfaces.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(dest)
