#!/usr/bin/env python3
"""Observe native thruster keys, render sink forces and live physics cadence."""
from check_driving import q
def find(path): return int(q("RunRhai",{"code":"find_path("+json.dumps(path)+")"})["stdout"])
def ports(entity,names): return q("ReadPorts",dict(api_id=entity,port_names=names))["ports"]
from pathlib import Path
import time,json
root=Path(__file__).resolve().parents[1]
def key(k,s): q('InjectWindowInput',{'event':{'Key':dict(key=('Key'+k if len(k)==1 else k),state=s,text=None,repeat=False)}})
def fresh():
 old=q('RunRhai',{'code':'twin_name()'})['stdout'];q('OpenTwin',{'path':str(root)})
 for i in range(100):
  s=q('GetReadiness');n=q('RunRhai',{'code':'twin_name()'})['stdout']
  if n!=old and s['ready'] and not s['pending_count'] and not s['world_hold']:
   car=find('/World/Roadster')
   if any(e['name']=='/World/Roadster' and e['status']=='Running' for e in q('CosimStatus',{'include_values':False})['entities']): return car
  time.sleep(.1)
 raise RuntimeError('Fresh scene unavailable')
def main():
    results=[]
    for k,group,idx,port in [('Space','RearThrusters',0,'jet_force_z'),('J','PerimeterThrusters',5,'jet_force_x'),('L','PerimeterThrusters',4,'jet_force_x'),('K','PerimeterThrusters',0,'jet_lift_0')]:
     car=fresh();time.sleep(.3)
     jet=find('/World/Roadster/'+group+'/Jet'+str(idx))
     key(k,'Pressed');time.sleep(.10)
     held=ports(car,[port,'gas_mass_kg','tank_temperature_k','speed_mps','speed_kmh','speed_mph'])
     sink=ports(jet,['force'])
     (root/f'results/jet-{k}-0.png').write_bytes(q('CaptureScreenshot'))
     time.sleep(.1)
     if k=='Space': (root/'results/jet-Space-1.png').write_bytes(q('CaptureScreenshot'))
     key(k,'Released');time.sleep(.3)
     released=ports(jet,['force'])
     results.append(dict(key=k,delivered=held,render_sink=sink,released_sink=released))
    for row in results:
        active=next(p['value'] for p in row['render_sink'] if p['name']=='force')
        closed=next(p['value'] for p in row['released_sink'] if p['name']=='force')
        row['ok']=abs(active)>1 and abs(closed)<1
    report=dict(ok=all(row['ok'] for row in results),checks=results)
    (root/'results/effects.json').write_text(json.dumps(report,indent=2)+'\n')
    car=fresh()
    profile=q('CosimStatus',{'include_values':False})['modelica_step_profile']
    a=time.monotonic();tick0=int(q('RunRhai',{'code':'clock_snapshot().sim_tick'})['stdout']);time.sleep(5)
    tick1=int(q('RunRhai',{'code':'clock_snapshot().sim_tick'})['stdout']);wall=time.monotonic()-a
    (root/'results/runtime-rate.json').write_text(json.dumps(dict(ticks=tick1-tick0,wall_s=wall,physics_hz=(tick1-tick0)/wall,worker=profile,health=q('ReadExposures',{'surface':'engine-health'})),indent=2)+'\n')
    (root/'results/fresh-hud.png').write_bytes(q('CaptureScreenshot'))
    print('Delivered-force effects:',report['ok'])
    return 0 if report['ok'] else 1

if __name__=='__main__': raise SystemExit(main())
