#!/usr/bin/env python3
"""Run the production shared tree and real early/late collision cases."""
import argparse,hashlib,json,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary',type=Path,default=ROOT/'.scratch/control-target/debug/luncosim')
    args=parser.parse_args();binary=args.binary.resolve();rows=[]
    for case in ['check','early','late']:
        started=time.time()
        result=subprocess.run([sys.executable,str(ROOT/'scripts/run_scene_check.py'),
            'roadster_course_'+case,'ROADSTER_COURSE','--ticks','2400',
            '--result-name','dynamic-'+case,'--binary',str(binary)]+(['--verification','Roadster::VerifySkillCourse'] if case=='check' else []),cwd=ROOT,
            stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        path=ROOT/'results'/f'dynamic-{case}.json'
        record=json.loads(path.read_text()) if path.exists() and path.stat().st_mtime>=started else {}
        rows.append(dict(case=case,ok=result.returncode==0,failures=record.get('failures'),
            course_time_s=record.get('final',{}).get('course_time_s'),
            input_offset_s=record.get('timing_offset_s',0),
            collision_impulse_ns=record.get('peak_cube_collision_impulse_ns'),report=str(path.relative_to(ROOT))))
        print(json.dumps(rows[-1]),flush=True)
        if result.returncode:print(result.stdout[-2000:],file=sys.stderr)
    files=['requirements/roadster.sysml','twin.toml','models/CoursePilot.mo','models/SkillCourse.mo','models/RoadsterVehicle.mo',
           'scenarios/skill_course.rhai','scenarios/tests/course_pilot.rhai',
           'vehicles/roadster.usda',
           'scenes/roadster_skill_course.usda','scenes/roadster_course_check.usda',
           'scenes/roadster_course_early.usda','scenes/roadster_course_late.usda']
    files=sorted(set(files)|{str(p.relative_to(ROOT)) for p in (ROOT/'models').glob('*.mo')})
    summary=dict(ok=all(row['ok'] for row in rows),cases=rows,
        binary_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
        source_sha256={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in files},
        scope='Native physics and shared in-app Modelica pilot; keyboard delivery is checked separately',
        timing_limit='Only the listed offsets are qualified; this is not a measured exact timing window')
    (ROOT/'results/dynamic-timing.json').write_text(json.dumps(summary,indent=2)+'\n')
    return 0 if summary['ok'] else 1
if __name__=='__main__':raise SystemExit(main())
