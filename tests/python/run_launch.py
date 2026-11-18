#!/usr/bin/env python3
"""Run the saved SysML verification through the production LunCoSim runner.

Writes the exact runner report, decoded telemetry and a CSV trajectory.
No browser, Python physics, third-party Python packages or build are involved.
"""
import argparse
import csv
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
CHECKOUT = ROOT.parent.parent / 'luncosim-workspace/main'


def decode(value):
    if isinstance(value, list):
        return [decode(v) for v in value]
    if isinstance(value, dict):
        if set(value) == {'Map'}:
            return {k: decode(v) for k, v in value['Map'].items()}
        if set(value) == {'Array'}:
            return [decode(v) for v in value['Array']]
        if len(value) == 1 and next(iter(value)) in {'F64','I64','U64','String','Bool','Null'}:
            return next(iter(value.values()))
        return {k: decode(v) for k, v in value.items()}
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary', default=os.environ.get('LUNCOSIM_BIN'))
    args = parser.parse_args()
    binary = args.binary or shutil.which('luncosim') or (CHECKOUT/'target/debug/luncosim' if (CHECKOUT/'target/debug/luncosim').is_file() else ROOT/'.scratch/luncosim')
    if not Path(binary).is_file():
        parser.error('Set LUNCOSIM_BIN or --binary to a production luncosim executable')
    env = os.environ.copy()
    (ROOT/'.scratch').mkdir(exist_ok=True)
    env['TMPDIR'] = str(ROOT/'.scratch')
    if (CHECKOUT/'assets').is_dir():
        env.setdefault('LUNCO_ASSET_ROOT',str(CHECKOUT/'assets'))
    env.update(LUNCOSIM_EPHEMERAL_SETTINGS='1', LUNCOSIM_ISOLATED_RUN='1')
    command = [str(binary),'test','--scene',str(ROOT/'scenes/tests/roadster_launch.usda'),
               '--verification','Roadster::VerifyRunner','--max-ticks','600']
    with (ROOT/'results/launch.log').open('w') as log:
        process = subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
    lines = (ROOT/'results/launch.log').read_text().splitlines()
    reports = [json.loads(line.split('LUNCO_SCENE_TEST_REPORT ',1)[1])
               for line in lines if line.startswith('LUNCO_SCENE_TEST_REPORT ')]
    if not reports:
        print('Runner produced no report; inspect results/launch.log',file=sys.stderr)
        return process.returncode or 1
    report = reports[-1]
    (ROOT/'results/launch-report.json').write_text(json.dumps(report,indent=2)+'\n')
    observations = [decode(e['data']) for e in report.get('evidence',[])
                    if e['name']=='ROADSTER_LAUNCH_EVIDENCE']
    if observations:
        telemetry = observations[-1]
        (ROOT/'results/launch-telemetry.json').write_text(json.dumps(telemetry,indent=2)+'\n')
        samples = telemetry.pop('samples',[])
        if samples:
            with (ROOT/'results/launch.csv').open('w',newline='') as out:
                writer = csv.DictWriter(out,fieldnames=[k for k in samples[0] if k!='position']+['x_m','y_m','z_m'],lineterminator='\n')
                writer.writeheader()
                for sample in samples:
                    x,y,z = sample.pop('position')
                    writer.writerow(dict(sample,x_m=x,y_m=y,z_m=z))
        print(json.dumps(telemetry,indent=2))
    print('Roadster::VerifyRunner:',report.get('verdict'),'- exit',process.returncode)
    return process.returncode


if __name__ == '__main__':
    sys.exit(main())
