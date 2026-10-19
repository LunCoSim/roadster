#!/usr/bin/env python3
"""Observe native Tab and HUD refill; all physics runs in LunCoSim/Modelica."""
import json,time,struct
from check_effects import fresh,find,key,q,ports,root
NAMES=['thrust_z','boost','refill','jet_force_z','gas_mass_kg','tank_pressure_pa','tank_temperature_k','tank_wall_temperature_k','refill_target_k','instant_services','speed_mps','vehicle_mass_kg','chassis_mass_kg','vehicle_inertia_xx','vehicle_inertia_yy','vehicle_inertia_zz','next_stored_energy_j','fan_requested','jet_force_y','surface_valid_0','surface_valid_1','surface_valid_2','surface_valid_3']
def tick():return int(q('RunRhai',{'code':'clock_snapshot().sim_tick'})['stdout'])
def wait(seconds):
 end=tick()+round(seconds*60);deadline=time.monotonic()+30
 while tick()<end:
  if time.monotonic()>deadline:raise RuntimeError('Clock stalled')
  time.sleep(.01)
def sample(car):
 ps=ports(car,NAMES);v={p['name']:p['value'] for p in ps if p['direction']=='out'}
 v['inputs']={p['name']:p['value'] for p in ps if p['direction']=='in'}
 v['tick']=tick();v['native']=q('QueryPhysicsState',{'id':car});return v
def await_service(car,count):
 start=tick()
 for _ in range(60):
  s=sample(car)
  if s['instant_services']>=count:return s,s['tick']-start
  time.sleep(.01)
 raise RuntimeError('Refill did not apply')
def check_fill(s):
 return abs(s['gas_mass_kg']-250)<.01 and abs(s['tank_temperature_k']-303.15)<.1 and abs(s['tank_wall_temperature_k']-303.15)<.1 and abs(s['native']['mass_kg']-s['chassis_mass_kg'])<.1

def main():
 car=fresh();rows={};fail=[]
 for k in ['Tab','W','Space','R','F','K','Q','E','ControlLeft','P']:key(k,'Released')
 # Focus the viewport through native input before using keyboard commands.
 for state in ['Pressed','Released']:q('InjectWindowInput',{'event':{'PointerButton':dict(button='Primary',state=state,x=900,y=300)}})
 q('SetPorts',dict(target=car,producer_id=4198001,writes=[['refill_target_temperature_k',303.15]]))
 try:
  key('W','Pressed');key('Space','Pressed');wait(.2);key('Space','Released');wait(.35)
  rows['depleted']=sample(car)
  key('Tab','Pressed');filled,latency=await_service(car,1);rows['tab']=filled;rows['tab_latency_ticks']=latency
  if not check_fill(filled):fail.append('Tab did not replace mass and gas/wall temperature immediately')
  if latency>6:fail.append('Tab refill took more than six fixed ticks to observe')
  if rows['depleted']['gas_mass_kg']>245 or rows['depleted']['speed_mps']<3:fail.append('Moving depleted-tank precondition was not reached')
  # Holding Tab must not refill continuously while boost consumes the new charge.
  key('Space','Pressed');wait(.15);rows['held_tab_boost']=sample(car);key('Space','Released');wait(.3);rows['held_tab']=sample(car)
  if rows['held_tab']['instant_services']!=1 or rows['held_tab']['gas_mass_kg']>249:fail.append('Held Tab repeated or prevented gas use')
  key('Tab','Released');wait(.1)
  # Real native HUD picking, no direct semantic UI action injection.
  width,height=struct.unpack('>II',q('CaptureScreenshot')[16:24]);x,y=width-143,height-80
  q('InjectWindowInput',{'event':{'PointerMove':dict(x=x,y=y)}});time.sleep(.08)
  for state in ['Pressed','Released']:
   q('InjectWindowInput',{'event':{'PointerButton':dict(button='Primary',state=state,x=x,y=y)}});time.sleep(.08)
  rows['hud'],rows['hud_latency_ticks']=await_service(car,2)
  if not check_fill(rows['hud']):fail.append('HUD refill did not restore the selected mass/temperature')
  if rows['hud']['speed_mps']<3:fail.append('Moving refill stopped the vehicle')
  for name in ['GroundSeal','Adhesion/Probe0','Adhesion/Probe1','Adhesion/Probe2','Adhesion/Probe3']:
   for visual in ['Model','Beam','Hit']:
    if find('/World/Roadster/'+name+'/'+visual)>=0:fail.append('Sensor visual still exists: '+name+'/'+visual)
  if any(rows['hud']['inputs']['surface_valid_'+str(i)]<.5 for i in range(4)):fail.append('Geometry probe stopped reporting ground')
  # Fan action and R front lift remain separate from refill.
  old_count=rows['hud']['instant_services'];key('F','Pressed');wait(.1);key('F','Released');wait(.3)
  rows['fans_off']=sample(car)
  if rows['fans_off']['fan_requested']>.5:fail.append('F fan toggle regressed')
  key('R','Pressed');wait(.1);rows['front_jets']=sample(car);key('R','Released')
  (root/'results/no-sensor-markers.png').write_bytes(q('CaptureScreenshot'))
  if rows['front_jets']['jet_force_y']<100 or rows['front_jets']['instant_services']!=old_count:fail.append('R no longer operates front lift separately')
 finally:
  for k in ['W','Space','Tab','R','F']:key(k,'Released')
 car=fresh();wait(.3);q('ObserveAvatar',{})
 ui=q('ReadExposures',{'surface':'vessel-hud'})['surfaces']['vessel-hud'];rows['hud_label']=ui['properties']['rr_refill_label']
 if 'TEST' in rows['hud_label'].upper() or 'TAB' not in rows['hud_label'].upper():fail.append('HUD refill label incorrect')
 (root/'results/instant-refill-ready.png').write_bytes(q('CaptureScreenshot'))
 report=dict(ok=not fail,failures=fail,observations=rows)
 (root/'results/instant-refill.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(dict(ok=not fail,failures=fail,tab_latency_ticks=latency),indent=2))
 return 0 if not fail else 1
if __name__=='__main__':raise SystemExit(main())
