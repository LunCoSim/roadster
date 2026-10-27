#!/usr/bin/env python3
"""Run an authored scene gate and retain decoded production evidence."""
import argparse,json,os,subprocess
from run_launch import ROOT,CHECKOUT,decode
ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('scene');ap.add_argument('channel');ap.add_argument('--ticks',type=int,default=2400)
ap.add_argument('--verification',help='Registered SysML verification case')
ap.add_argument('--result-name',help='Evidence filename stem; defaults to the verdict channel')
ap.add_argument('--binary',default=os.environ.get('LUNCOSIM_BIN',str(ROOT/'.scratch/luncosim')))
a=ap.parse_args();key=a.result_name or a.channel.lower().replace('roadster_','')
if not key or any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789_-' for c in key):ap.error('Result name must use lowercase letters, digits, hyphens or underscores')
env=os.environ.copy();env.update(TMPDIR=str(ROOT/'.scratch'),LUNCO_ASSET_ROOT=str(CHECKOUT/'assets'),LUNCOSIM_EPHEMERAL_SETTINGS='1',LUNCOSIM_ISOLATED_RUN='1')
with (ROOT/f'results/{key}.log').open('w') as log:
 p=subprocess.run([a.binary,'test','--scene',str(ROOT/f'scenes/tests/{a.scene}.usda'),'--max-ticks',str(a.ticks),'--verdict-channel',a.channel]+(['--verification',a.verification] if a.verification else []),env=env,stdout=log,stderr=subprocess.STDOUT)
events=[];samples=[]
log_text=(ROOT/f'results/{key}.log').read_text()
if any(marker in log_text for marker in ["on_tick() failed", "on_start() failed"]):
 raise RuntimeError(f'Acceptance script failed: results/{key}.log')
for line in log_text.splitlines():
 if line.startswith('LUNCO_SCENE_TEST_EVIDENCE '):
  event=json.loads(line.split(' ',1)[1])
  if event['name']==a.channel+'_EVIDENCE':events.append(decode(event['data']))
  if event['name']==a.channel+'_SAMPLE_EVIDENCE':samples.append(decode(event['data']))
if not events:raise RuntimeError(f'No evidence: results/{key}.log')
if samples:events[-1]['samples']=samples
(ROOT/f'results/{key}.json').write_text(json.dumps(events[-1],indent=2)+'\n')
print(json.dumps({k:v for k,v in events[-1].items() if k not in ['samples','requirements']},indent=2))
raise SystemExit(p.returncode)
