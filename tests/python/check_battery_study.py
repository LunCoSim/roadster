#!/usr/bin/env python3
"""Run authored battery energy/mass sensitivity and Thrust storage gates."""
import argparse,hashlib,json,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--binary',type=Path,default=ROOT/'.scratch/control-target/debug/luncosim')
 args=ap.parse_args();binary=args.binary.resolve();rows=[]
 for scene,name in [('roadster_battery_110','battery-110'),('roadster_battery_120','battery-120'),('roadster_battery_140','battery-140'),('roadster_thrust_storage','thrust-storage')]:
  p=subprocess.run([sys.executable,str(ROOT/'tests/python/run_scene_check.py'),scene,'ROADSTER_BATTERY',
    '--ticks','500','--result-name',name,'--binary',str(binary)],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
  if p.returncode:raise RuntimeError(p.stdout[-3000:])
  r=json.loads((ROOT/f'results/{name}.json').read_text());v=r['final']
  row=dict(case=name,capacity_kwh=v['battery_nominal_energy_kwh'],total_mass_kg=r['total_native_mass_kg'],
    native_inertia=r['native_inertia'],air_kg=v['gas_mass_kg'],volume_m3=v['tank_volume_m3'],
    cabin_air_kg=v['cabin_tank_air_kg'],energy_balance_error_j=r['energy_balance_error_j'],
    report=f'results/{name}.json');rows.append(row);print(json.dumps(row),flush=True)
 checks=dict(mass_increases=rows[0]['total_mass_kg']<rows[1]['total_mass_kg']<rows[2]['total_mass_kg'],
  all_inertias_increase=all(rows[0]['native_inertia'][i]<rows[1]['native_inertia'][i]<rows[2]['native_inertia'][i] for i in range(3)),
  reference_mass_preserved=abs(rows[1]['total_mass_kg']-1950)<.05,
  thrust_200l=abs(rows[3]['volume_m3']-.2)<1e-6,thrust_no_cabin_air=rows[3]['cabin_air_kg']<1e-6,
  equal_initial_storage_density=abs(rows[3]['air_kg']/rows[3]['volume_m3']-rows[1]['air_kg']/rows[1]['volume_m3'])<1e-4)
 files=['models/BatteryStudy.mo','models/RoadsterPowertrain.mo','models/RoadsterVehicle.mo',
  'vehicles/roadster.usda','scenarios/tests/battery_study.rhai']
 files=sorted(set(files)|{str(p.relative_to(ROOT)) for p in (ROOT/'models').glob('*.mo')})
 report=dict(ok=all(checks.values()),checks=checks,cases=rows,
  binary_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
  source_sha256={f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in files},
  scope='Source-informed battery assumptions, actual Modelica energy ledger and native mass/inertia. No cell-level or manufacturer calibration claim.')
 (ROOT/'results/battery-study.json').write_text(json.dumps(report,indent=2)+'\n')
 return 0 if report['ok'] else 1
if __name__=='__main__':raise SystemExit(main())
