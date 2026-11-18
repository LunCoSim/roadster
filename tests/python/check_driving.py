#!/usr/bin/env python3
"""Observe native wheel rolling, steering, braking, mass and speed HUD headfully."""
import json
from pathlib import Path
import time
import urllib.request

ROOT=Path(__file__).resolve().parents[2]
def q(command,params=None):
    req=urllib.request.Request('http://127.0.0.1:4198/api/commands',
        data=json.dumps(dict(type='ExecuteCommand',command=command,params=params or {})).encode(),
        headers={'Content-Type':'application/json'})
    raw=urllib.request.urlopen(req,timeout=30).read()
    if command=='CaptureScreenshot': return raw
    return json.loads(raw)['data']
def main():
    car=int(q('RunRhai',dict(code='find_path("/World/Roadster")'))['stdout'])
    def key(name,state):
        q('InjectWindowInput',{'event':{'Key':dict(key=name,state=state,text=None,repeat=False)}})
    def wait_sim(seconds):
        def tick(): return int(q('RunRhai',dict(code='clock_snapshot().sim_tick'))['stdout'])
        target=tick()+round(seconds*60)
        deadline=time.monotonic()+180
        while tick()<target:
            state=q('GetReadiness')
            if state['faulted']: raise RuntimeError(state['fault'])
            if time.monotonic()>deadline: raise RuntimeError('Simulation clock stalled')
            time.sleep(.02)
    def sample():
        p=q('ReadPorts',dict(api_id=car,port_names=['speed','heading_fl','heading_fr','position_y','chassis_mass_kg','vehicle_mass_kg']))['ports']
        values={r['name']:r['value'] for r in p if r['direction']=='out'}
        wheels=[]
        for n in ['FL','FR','RL','RR']:
            wid=int(q('RunRhai',dict(code='find_path("/World/Roadster/Wheel_'+n+'")'))['stdout'])
            shaft=q('ReadPorts',dict(api_id=wid,port_names=['shaft_speed']))['ports']
            speed=next(p['value'] for p in shaft if p['direction']=='out')
            rotation=json.loads(q('RunRhai',dict(code='world_rotation('+str(wid)+')'))['stdout'])
            contact_ports=q('ReadPorts',dict(api_id=wid,port_names=['contact']))['ports']
            contacts=int(next(p['value'] for p in contact_ports if p['direction']=='out')>0.5)
            wheels.append(dict(shaft_rad_s=speed,rotation=rotation,contacts=contacts))
        values['wheels']=wheels
        return values
    q('ObserveAvatar',{})
    key('ShiftLeft','Pressed')
    wait_sim(3)
    before=sample()
    try:
        key('ShiftLeft','Released')
        key('KeyW','Pressed')
        wait_sim(.6)
        key('KeyW','Released')
        wait_sim(.8)
        rolling=[]
        for i in range(4):
            rolling.append(sample())
            (ROOT/f'results/wheels-{i}.png').write_bytes(q('CaptureScreenshot'))
            wait_sim(.12)
        hud=q('ReadExposures',dict(surface='vessel-hud'))
        physics=q('QueryPhysicsState',dict(id=car))
        key('KeyA','Pressed')
        wait_sim(.7)
        turning=sample()
    finally:
        key('KeyW','Released')
        key('KeyA','Released')
        key('ShiftLeft','Pressed')
    wait_sim(3)
    stopped=sample()
    checks=dict(rolls=all(abs(abs(w['shaft_rad_s'])*.34-rolling[-1]['speed'])<1.5 for w in rolling[-1]['wheels']),
        moves=rolling[-1]['speed']>1,
        rotates=all(sum((a-b)**2 for a,b in zip(w['rotation'],b['rotation']))>.0001 for w,b in zip(rolling[-1]['wheels'],before['wheels'])),
        steers=abs(turning['heading_fl'])>.01 and abs(turning['heading_fr'])>.01,
        brakes=stopped['speed']<.2,
        ground_contacts=all(w['contacts']>0 for w in rolling[-1]['wheels']),
        mass=abs(physics['mass_kg']-rolling[-1]['chassis_mass_kg'])<1e-4 and abs(rolling[-1]['vehicle_mass_kg']-1950)<1e-4,
        hud=hud['surfaces']['vessel-hud']['state']=='ready' and hud['surfaces']['vessel-hud']['visible'])
    report=dict(ok=all(checks.values()),checks=checks,before=before,rolling=rolling,turning=turning,
        stopped=stopped,physics=physics,hud=hud)
    (ROOT/'results/driving.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(checks,indent=2))
    key('ShiftLeft','Released')
    return 0 if report['ok'] else 1
if __name__=='__main__': raise SystemExit(main())
