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
        q('InjectWindowInput',{'event':{'Key':dict(key=('Key'+name if len(name)==1 and name.isalpha() else name),state=state,text=None,repeat=False)}})
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
               'position_y','velocity_y','downforce','heading_fl','brake','lift_fl','lift_fr','lift_rl','lift_rr','jet_lift_0','jet_lift_1','jet_lift_2','jet_lift_3','torque_x','torque_y','torque_z','angvel_x','angvel_y','angvel_z']
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
    for name in ['I','J','K','L','P','O','W','A','S','D','Space','Comma','Period','ShiftLeft']: key(name,'Released')
    # Remove any popup/text focus so native input reaches the controller.
    for state in ['Pressed','Released']:
        q('InjectWindowInput',{'event':{'PointerButton':dict(button='Primary',state=state,x=1100,y=150)}})
    time.sleep(.2)
    results=[]
    try:
        # Each key passes through the native input map and authored bindings.
        for name,axis,sign,corner in [('K','y',1,None),('O','y',0,None),('Space','z',-1,None),
                ('J','x',-1,None),('L','x',1,None),('I','y',1,0),('P','y',1,2),('Comma','y',1,1),('Period','y',1,3)]:
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
            input_name={'I':'lift_fl','P':'lift_fr','Comma':'lift_rl','Period':'lift_rr'}.get(name,'thrust_'+axis)
            row['input_value']=value(held,input_name,'in')
            if corner is not None:
                jets=[value(held,'jet_lift_'+str(i)) for i in range(4)]
                row.update(corner_forces_n=jets,torque_x_nm=value(held,'torque_x'),torque_z_nm=value(held,'torque_z'))
                row['corner_ok']=jets[corner]>100 and all(abs(f)<1 for i,f in enumerate(jets) if i!=corner)
            snapshot=json.loads(q('RunRhai',dict(code=f'let ph=query("QueryPhysicsState",#{{id:{car}}}); let ps=query("ReadPorts",#{{api_id:{car},port_names:["gas_mass_kg"]}}); let gas=0.0; for p in ps.ports {{if p.direction=="out" {{gas=p.value;}}}} [ph.mass_kg,gas]'))['stdout'])
            row['physical_mass_kg'],row['mass_snapshot_gas_kg']=snapshot
            row['ok']=(sign*force>1 and row['gas_after_kg']<row['gas_before_kg'] if sign else
                       abs(force)<1 and row['input_value']==-1 and abs(row['gas_after_kg']-row['gas_before_kg'])<1e-5)
            if corner is not None:
                # The finite-gas rate controller may fire opposing jets after
                # release to arrest rotation. It must release the raw command.
                row['damping_power_w']=sum(value(released,'torque_'+a)*value(released,'angvel_'+a) for a in 'xyz')
                row['ok']=row['ok'] and value(released,input_name,'in')==0 and row['damping_power_w']<=100.0
            else:
                row['ok']=row['ok'] and abs(after)<max(1.0,abs(force)*.05)
            row['ok']=row['ok'] and abs(row['physical_mass_kg']-(1700+row['mass_snapshot_gas_kg']))<.1
            row['ok']=row['ok'] and row.get('corner_ok',True)
            results.append(row)
            print(json.dumps(row),flush=True)
        car=fresh_twin()
        key('W','Pressed'); wait_sim(.25)
        drive=ports(car)
        key('W','Released'); wait_sim(.25)
        results.append(dict(key='W',torque_nm=value(drive,'torque_left'),ok=value(drive,'torque_left')>0))
        key('A','Pressed'); wait_sim(.3)
        steer=ports(car)
        key('A','Released')
        results.append(dict(key='A',heading_rad=value(steer,'heading_fl'),ok=abs(value(steer,'heading_fl'))>0))
        q('InjectWindowInput',{'event':{'Key':dict(key='ShiftLeft',state='Pressed',text=None,repeat=False)}})
        wait_sim(.15)
        brake=ports(car)
        q('InjectWindowInput',{'event':{'Key':dict(key='ShiftLeft',state='Released',text=None,repeat=False)}})
        results.append(dict(key='ShiftLeft',brake=value(brake,'brake','in'),ok=value(brake,'brake','in')==1))
    finally:
        for name in ['I','J','K','L','P','O','W','A','S','D','Space','Comma','Period','ShiftLeft']: key(name,'Released')
        q('InjectWindowInput',{'event':{'Key':dict(key='ShiftLeft',state='Released',text=None,repeat=False)}})
    report=dict(ok=all(r['ok'] for r in results),checks=results)
    (root/'results/controls.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    return 0 if report['ok'] else 1


if __name__=='__main__':
    raise SystemExit(main())
