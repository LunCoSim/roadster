#!/usr/bin/env python3
"""Measure the native jump timing window on the fixed-physics frame grid.

Coarse samples locate boundaries, then every frame between passing samples and
its adjacent failing frame is measured. This qualifies the authored speed/plant,
not every possible speed, subframe instant, weather or human input latency.
"""
from scene_documents import save_scene_as
import argparse,hashlib,json,subprocess,sys
from pathlib import Path
from author_surface_probes import q,ROOT,await_doc


def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--binary',type=Path,default=ROOT/'.scratch/control-target/debug/luncosim')
 a=ap.parse_args();binary=a.binary.resolve();rows={};doc=None
 files=['models/BatteryStudy.mo','models/CoursePilot.mo','models/SkillCourse.mo','models/RoadsterVehicle.mo',
  'models/RoadsterPowertrain.mo','scenarios/skill_course.rhai','scenarios/tests/course_pilot.rhai','vehicles/roadster.usda']
 files=sorted(set(files)|{str(p.relative_to(ROOT)) for p in (ROOT/'models').glob('*.mo')})
 source_snapshot={f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in files}
 try:
  q('OpenFile',path=str(ROOT/'scenes/tests/roadster_course_check.usda'))
  doc=await_doc(lambda d:'/roadster_course_check.usda' in str(d))
  scene=ROOT/'scenes/tests/roadster_jump_window.usda'
  save_scene_as(q, doc, str(scene))
  def set_offset(tick):
   q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path='/World/DriverSetup',name=n,type_name=t,value=v)}
     for n,t,v in [('study:timingSweep','bool','true'),('study:jumpTimingOffset','double',str(tick/60))]])
   q('SaveDocument',doc_id=doc)
  def trial(tick,suffix=''):
   set_offset(tick)
   stem='jump-window-'+('m'+str(-tick) if tick<0 else 'p'+str(tick))+suffix
   if any(hashlib.sha256((ROOT/f).read_bytes()).hexdigest()!=h for f,h in source_snapshot.items()):
    raise RuntimeError('Plant or observer source changed during the timing sweep; restart it')
   sha=hashlib.sha256(scene.read_bytes()).hexdigest()
   cmd=[sys.executable,str(ROOT/'scripts/run_scene_check.py'),'roadster_jump_window',
     'ROADSTER_JUMP_WINDOW','--ticks','1500','--result-name',stem,'--binary',str(binary)]
   proc=subprocess.run(cmd,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
   if proc.returncode:raise RuntimeError(f'{stem}: {proc.stdout[-1800:]}')
   d=json.loads((ROOT/'results'/f'{stem}.json').read_text())
   row=dict(offset_frames=tick,offset_s=tick/60,cleared=d['cleared'],stage=d['stage'],
     failure_reason=d['final']['course_failure_reason'],collision_impulse_ns=d['peak_cube_collision_impulse_ns'],
     time_s=d['final']['course_time_s'],scene_sha256=sha,report=f'results/{stem}.json')
   print(json.dumps(row),flush=True)
   return row
  for tick in range(-18,19,3):rows[tick]=trial(tick)
  passing=sorted(k for k,v in rows.items() if v['cleared'])
  if not passing:raise RuntimeError('No coarse timing sample cleared all cubes')
  lower=max(k for k in rows if k<min(passing) and not rows[k]['cleared'])
  upper=min(k for k in rows if k>max(passing) and not rows[k]['cleared'])
  for tick in range(lower,upper+1):
   if tick not in rows:rows[tick]=trial(tick)
  repeated=trial(0,'-repeat')
  passing=sorted(k for k,v in rows.items() if v['cleared'])
  checks=dict(baseline=rows[0]['cleared'],repeat_baseline=repeated['cleared'],
    contiguous=all(rows[k]['cleared'] for k in range(min(passing),max(passing)+1)),
    early_failure=not rows[max(passing)+1]['cleared'],late_failure=not rows[min(passing)-1]['cleared'])
  summary=dict(ok=all(checks.values()),checks=checks,samples=[rows[k] for k in sorted(rows)],repeat_baseline=repeated,
    passing_offsets_frames=[min(passing),max(passing)],passing_offsets_s=[min(passing)/60,max(passing)/60],
    resolution_s=1/60,binary_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
    source_sha256=source_snapshot,
    scope='Native three-cube jump at authored guidance speed; timing offsets applied to Modelica guidance only. Full-course qualification remains separate.')
  (ROOT/'results/jump-window.json').write_text(json.dumps(summary,indent=2)+'\n')
  return 0 if summary['ok'] else 1
 finally:
  if doc is not None:
   set_offset(0);q('CloseDocument',doc_id=doc)
if __name__=='__main__':raise SystemExit(main())
