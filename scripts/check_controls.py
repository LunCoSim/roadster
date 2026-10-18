#!/usr/bin/env python3
"""Verify the actual native keymap, valve release and physical force directions.

Run against a fresh Rocket scene started with scripts/start.sh. This commands
the existing window input API and reads production ports; it simulates no physics.
"""
import argparse
import json
from pathlib import Path
import time
import urllib.request


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port',type=int,default=4198)
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[1]
    def q(command,params):
        req=urllib.request.Request(f'http://127.0.0.1:{args.port}/api/commands',
            data=json.dumps(dict(type='ExecuteCommand',command=command,params=params)).encode(),
            headers={'Content-Type':'application/json'})
        response=json.load(urllib.request.urlopen(req,timeout=15))
        if 'error' in response: raise RuntimeError(response['error'])
        return response['data']
    def key(name,state):
        q('InjectWindowInput',{'event':{'Key':dict(key='Key'+name,state=state,text=None,repeat=False)}})
    def wait_sim(seconds):
        def tick(): return int(q('RunRhai',dict(code='clock_snapshot().sim_tick'))['stdout'])
        target=tick()+round(seconds*60)
        deadline=time.monotonic()+90
        while tick()<target:
            if time.monotonic()>deadline: raise RuntimeError('Simulation clock stalled')
            time.sleep(.02)
    def ports(car):
        names=['thrust_x','thrust_y','thrust_z','jet_force_x','jet_force_y','jet_force_z','force_local_x','force_local_y',
               'force_local_z','gas_mass_kg','tank_pressure_pa','torque_left',
               'position_y','velocity_y','downforce','heading_fl','brake']
        return q('ReadPorts',dict(api_id=car,port_names=names))['ports']
    def value(records,name,direction='out'):
        return next(p['value'] for p in records if p['name']==name and p['direction']==direction)
    def await_ready():
        deadline=time.monotonic()+30
        while time.monotonic()<deadline:
            state=q('GetReadiness',{})
            if state['faulted']: raise RuntimeError(state)
            if state['ready'] and not state['world_hold'] and not state['pending_count']: return
            time.sleep(.1)
        raise RuntimeError('Scene did not become ready')
    def fresh_twin():
        previous=q('RunRhai',dict(code='twin_name()'))['stdout']
        q('OpenTwin',dict(path=str(root)))
        deadline=time.monotonic()+60
        while time.monotonic()<deadline:
            current=q('RunRhai',dict(code='twin_name()'))['stdout']
            state=q('GetReadiness',{})
            if current != previous and state['ready'] and not state['pending_count'] and not state['world_hold']:
                models=q('CosimStatus',dict(include_values=False))['entities']
                if any(e.get('name')=='/World/Roadster' and e.get('status')=='Running'
                       and e.get('has_simcomponent') and e.get('modelica_current_time',100)<3 for e in models):
                    car=int(q('RunRhai',dict(code='find_path("/World/Roadster")'))['stdout'])
                    return car
            time.sleep(.1)
        raise RuntimeError('Fresh Twin did not publish a running Roadster participant')
    await_ready()
    for name in ['ControlLeft','ControlRight','AltLeft','AltRight','ShiftLeft','ShiftRight','SuperLeft','SuperRight']:
        q('InjectWindowInput',{'event':{'Key':dict(key=name,state='Released',text=None,repeat=False)}})
    for name in 'IJKLUOWASD': key(name,'Released')
    # Remove any popup/text focus so native input reaches the controller.
    for state in ['Pressed','Released']:
        q('InjectWindowInput',{'event':{'PointerButton':dict(button='Primary',state=state,x=1100,y=150)}})
    time.sleep(.2)
    results=[]
    try:
        # All six keys pass through the persisted input map and authored control
        # bindings. U first exercises an initially full gas reservoir.
        for name,axis,sign in [('U','y',1),('O','y',0),('I','z',-1),
                               ('K','z',0),('J','x',-1),('L','x',1)]:
            # Each direction starts from the authored reservoir. Native API
            # round trips can take seconds on an unfocused window, so sharing
            # one tank would measure depletion before later key checks.
            car=fresh_twin()
            time.sleep(.1)
            before=ports(car)
            key(name,'Pressed')
            wait_sim(.20)
            held=ports(car)
            key(name,'Released')
            wait_sim(.25)
            released=ports(car)
            force=value(held,'jet_force_'+axis)
            after=value(released,'jet_force_'+axis)
            row=dict(key=name,axis=axis,expected_sign=sign,held_force_n=force,
                released_force_n=after,gas_before_kg=value(before,'gas_mass_kg'),
                gas_after_kg=value(released,'gas_mass_kg'),
                tank_pressure_pa=value(held,'tank_pressure_pa'),
                position_y_m=value(held,'position_y'))
            row['input_value']=value(held,'thrust_'+axis,'in')
            row['physical_mass_kg']=q('QueryPhysicsState',dict(id=car))['mass_kg']
            row['ok']=(sign*force>1 and row['gas_after_kg']<row['gas_before_kg'] if sign else
                       abs(force)<1 and row['input_value']==-1 and abs(row['gas_after_kg']-row['gas_before_kg'])<1e-5)
            row['ok']=row['ok'] and abs(after)<max(1.0,abs(force)*.05)
            row['ok']=row['ok'] and abs(row['physical_mass_kg']-(1700+row['gas_after_kg']))<.1
            results.append(row)
            print(json.dumps(row),flush=True)
        key('W','Pressed'); wait_sim(.25)
        drive=ports(car)
        key('W','Released'); wait_sim(.25)
        results.append(dict(key='W',torque_nm=value(drive,'torque_left'),ok=value(drive,'torque_left')>0))
        key('A','Pressed'); wait_sim(.3)
        steer=ports(car)
        key('A','Released')
        results.append(dict(key='A',heading_rad=value(steer,'heading_fl'),ok=abs(value(steer,'heading_fl'))>0))
        q('InjectWindowInput',{'event':{'Key':dict(key='Space',state='Pressed',text=None,repeat=False)}})
        wait_sim(.15)
        brake=ports(car)
        q('InjectWindowInput',{'event':{'Key':dict(key='Space',state='Released',text=None,repeat=False)}})
        results.append(dict(key='Space',brake=value(brake,'brake','in'),ok=value(brake,'brake','in')==1))
    finally:
        for name in 'IJKLUOWASD': key(name,'Released')
        q('InjectWindowInput',{'event':{'Key':dict(key='Space',state='Released',text=None,repeat=False)}})
    report=dict(ok=all(r['ok'] for r in results),checks=results)
    (root/'results/controls.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    return 0 if report['ok'] else 1


if __name__=='__main__':
    raise SystemExit(main())
