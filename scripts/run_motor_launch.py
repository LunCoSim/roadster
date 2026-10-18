#!/usr/bin/env python3
"""Observe motor-only acceleration with the production scene runner."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
from run_launch import ROOT,CHECKOUT,decode

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary',default=os.environ.get('LUNCOSIM_BIN'))
    args=parser.parse_args()
    binary=args.binary or shutil.which('luncosim') or (CHECKOUT/'target/debug/luncosim' if (CHECKOUT/'target/debug/luncosim').is_file() else ROOT/'.scratch/luncosim')
    env=os.environ.copy()
    env.update(TMPDIR=str(ROOT/'.scratch'),LUNCO_ASSET_ROOT=env.get('LUNCO_ASSET_ROOT',str(CHECKOUT/'assets')),
        LUNCOSIM_EPHEMERAL_SETTINGS='1',LUNCOSIM_ISOLATED_RUN='1')
    with (ROOT/'results/motor-after.log').open('w') as log:
        process=subprocess.run([str(binary),'test','--scene',str(ROOT/'scenes/roadster_motor_launch.usda'),
            '--max-ticks','650','--verdict-channel','ROADSTER_MOTOR'],cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
    evidence=[]
    for line in (ROOT/'results/motor-after.log').read_text().splitlines():
        if line.startswith('LUNCO_SCENE_TEST_EVIDENCE '):
            event=json.loads(line.split(' ',1)[1])
            if event['name']=='ROADSTER_MOTOR_EVIDENCE': evidence.append(decode(event['data']))
    if not evidence: raise RuntimeError('No motor launch evidence; see results/motor-after.log')
    (ROOT/'results/motor-after.json').write_text(json.dumps(evidence[-1],indent=2)+'\n')
    print(json.dumps({k:v for k,v in evidence[-1].items() if k!='samples'},indent=2))
    return process.returncode
if __name__=='__main__': raise SystemExit(main())
