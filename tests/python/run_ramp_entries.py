#!/usr/bin/env python3
"""Run native ramp entry gates and retain a compact matrix and measured traces."""
import argparse,csv,json,os,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
CASES=[(11,1),(25,1),(40,1),(25,0)]
def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--binary',default=str(ROOT/'.scratch/luncosim'))
 a=ap.parse_args();reports=[];rows=[];ok=True
 for speed,fan in CASES:
  scene=f'roadster_ramp_entry_{speed}_{fan}'
  key=f'ramp-entry-{speed}-{fan}'
  evidence=ROOT/f'results/{key}.json'
  evidence.unlink(missing_ok=True)
  result=subprocess.run([sys.executable,str(ROOT/'tests/python/run_scene_check.py'),scene,'ROADSTER_RAMP_ENTRY','--result-name',key,'--binary',a.binary,'--ticks','1800'],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
  if evidence.exists():
   report=json.loads(evidence.read_text());samples=report.pop('samples',[])
  else:
   log=ROOT/f'results/{key}.log'
   faults=[line.strip() for line in log.read_text().splitlines() if 'terminal runtime fault' in line] if log.exists() else []
   report=dict(failures=['Scene stopped without final acceptance evidence'],runtime_failure=faults[-1] if faults else result.stdout[-2000:]);samples=[]
  report['scene']=scene;report['exit_code']=result.returncode;reports.append(report)
  ok=ok and result.returncode==0 and not report['failures']
  for s in samples:
   row=dict(target_mps=speed,fan=fan,time_s=s['time_s'],x_m=s['position'][0],y_m=s['position'][1],z_m=s['position'][2],
    speed_mps=s['speed_mps'],up_y=s['up_y'],suction_n=s['suction_n'],throttle=s['throttle'],brake=s['brake'],
    body_normal_impulse_ns=s['body_contact']['normal_impulse_ns'])
   for w in s['wheels']:
    name=w['wheel_usd_prim_path'].rsplit('_',1)[-1]
    row[name+'_contact']=int(w['contact_valid']);row[name+'_compression_m']=w['suspension_compression_m'];row[name+'_normal_impulse_ns']=w['normal_impulse_ns']
   rows.append(row)
  loss=report.get('maximum_speed_drop_per_tick')
  print(f'{scene}: {"PASS" if not report["failures"] else "FAIL"}; max tick speed loss {loss if loss is not None else "unavailable"} m/s',flush=True)
  (ROOT/'results/ramp-entry-matrix.json').write_text(json.dumps(dict(ok=ok,binary=os.path.realpath(a.binary),complete=len(reports)==len(CASES),cases=reports),indent=2)+'\n')
 with (ROOT/'results/ramp-entry-traces.csv').open('w') as out:
  if rows:
   writer=csv.DictWriter(out,fieldnames=list(rows[0]),lineterminator='\n');writer.writeheader();writer.writerows(rows)
 return 0 if ok else 1
if __name__=='__main__':raise SystemExit(main())
