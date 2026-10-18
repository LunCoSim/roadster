#!/usr/bin/env python3
"""Observe native wheel rolling, steering, braking, mass and speed HUD headfully."""
import json
from pathlib import Path
import time
import urllib.request

ROOT=Path(__file__).resolve().parents[1]
def q(command,params=None):
    req=urllib.request.Request('http://127.0.0.1:4198/api/commands',
        data=json.dumps(dict(type='ExecuteCommand',command=command,params=params or {})).encode(),
        headers={'Content-Type':'application/json'})
    raw=urllib.request.urlopen(req,timeout=30).read()
    if command=='CaptureScreenshot': return raw
    return json.loads(raw)['data']
def main():
    car=int(q('RunRhai',dict(code='find_path("/World/Roadster")'))['stdout'])
    def write(**values):
        q('SetPorts',dict(target=car,producer_id=4198001,writes=list(values.items())))
    def wait_sim(seconds):
        def tick(): return int(q('RunRhai',dict(code='clock_snapshot().sim_tick'))['stdout'])
        target=tick()+round(seconds*60)
        deadline=time.monotonic()+180
        while tick()<target:
            if time.monotonic()>deadline: raise RuntimeError('Simulation clock stalled')
            time.sleep(.02)
    def sample():
        p=q('ReadPorts',dict(api_id=car,port_names=['speed','heading_fl','heading_fr','position_y']))['ports']
        values={r['name']:r['value'] for r in p if r['direction']=='out'}
        code='let result=[]; for n in ["FL","FR","RL","RR"] { let w=find_path("/World/Roadster/Wheel_"+n); result.push(get(w,"WheelRaycast.spin_velocity")); result.push(get(w,"WheelRaycast.spin_angle")); } result'
        values['wheel_omega_angle']=json.loads(q('RunRhai',dict(code=code))['stdout'])
        return values
    q('AcquireControl',dict(target=car,bind_camera=False))
    q('SetUserCamera',dict(name='ChaseCamera'))
    write(throttle=0,steer=0,brake=1)
    wait_sim(3)
    before=sample()
    try:
        write(throttle=.06,steer=0,brake=0,fan=0,boost=0,lift=0,thrust_x=0,thrust_y=0,thrust_z=0)
        wait_sim(3)
        rolling=[]
        for i in range(4):
            rolling.append(sample())
            (ROOT/f'results/wheels-{i}.png').write_bytes(q('CaptureScreenshot'))
            wait_sim(.12)
        hud=q('ReadExposures',dict(surface='vessel-hud'))
        physics=q('QueryPhysicsState',dict(id=car))
        write(steer=.35)
        wait_sim(.7)
        turning=sample()
    finally:
        write(throttle=0,steer=0,brake=1)
    wait_sim(3)
    stopped=sample()
    checks=dict(rolls=all(abs(w*.34-rolling[-1]['speed'])<1.5 for w in rolling[-1]['wheel_omega_angle'][::2]),
        moves=rolling[-1]['speed']>1,
        rotates=all(abs(rolling[-1]['wheel_omega_angle'][i]-before['wheel_omega_angle'][i])>.01 for i in [1,3,5,7]),
        steers=abs(turning['heading_fl'])>.01 and abs(turning['heading_fr'])>.01,
        brakes=stopped['speed']<.2,
        ground_contacts=all(w['contact_valid'] for w in physics['wheel_contacts']),
        mass=abs(physics['mass_kg']-1950)<1e-5,
        hud=hud['surfaces']['vessel-hud']['state']=='ready' and hud['surfaces']['vessel-hud']['visible'])
    report=dict(ok=all(checks.values()),checks=checks,before=before,rolling=rolling,turning=turning,
        stopped=stopped,physics=physics,hud=hud)
    (ROOT/'results/driving.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(checks,indent=2))
    return 0 if report['ok'] else 1
if __name__=='__main__': raise SystemExit(main())
