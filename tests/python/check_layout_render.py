#!/usr/bin/env python3
"""Capture current fixed-bank controls in the native avatar-following view."""
from check_effects import fresh,find,ports,key,q,root
import time,json

for k in ['W','A','S','D','Q','E','R','C','F','I','P','J','K','L','Space','Comma','Period','ControlLeft','ControlRight','ShiftLeft','ShiftRight']:key(k,'Released')
rows=[]
try:
 for name,indices in [('K',[0,1,2,3]),('Q',[0,1]),('R',[0,2])]:
  car=fresh();time.sleep(3.6)
  key('F','Pressed');time.sleep(.08);key('F','Released');time.sleep(.6)
  key(name,'Pressed');time.sleep(.12)
  physics=ports(car,['gas_mass_kg','jet_force_y','thruster_pitch_moment_nm','thruster_roll_moment_nm'])
  sinks=[]
  for i in indices:
   jet=find('/World/Roadster/PerimeterThrusters/Jet'+str(i));sinks.append(dict(index=i,ports=ports(jet,['force'])))
  (root/f'results/layout-{name}.png').write_bytes(q('CaptureScreenshot'))
  key(name,'Released');time.sleep(.3)
  row=dict(key=name,modelica=physics,render_sinks=sinks)
  row['ok']=all(any(p['name']=='force' and p['value']>1 for p in item['ports']) for item in sinks)
  rows.append(row)
finally:
 for name in ['K','Q','R','F']:key(name,'Released')
 car=fresh();q('ObserveAvatar',{});time.sleep(3.6)
 (root/'results/hud-fixed-controls.png').write_bytes(q('CaptureScreenshot'))
report=dict(ok=all(row['ok'] for row in rows),checks=rows)
(root/'results/layout-render.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
raise SystemExit(0 if report['ok'] else 1)
