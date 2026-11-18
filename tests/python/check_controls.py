#!/usr/bin/env python3
"""Verify the actual native keymap, valve release and physical force directions.

Run against the interactive Twin started with scripts/start.sh. This commands
the existing window input API and reads production ports; it simulates no physics.
"""
import argparse
import json
from pathlib import Path
import struct
import time
import urllib.request


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port',type=int,default=4198)
    parser.add_argument('--output-dir',type=Path,help='Directory for the control report and layout capture')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[2]
    output=args.output_dir or root/'results'
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
               'force_local_z','thruster_pitch_moment_nm','gas_mass_kg','tank_pressure_pa','torque_left',
               'position_y','velocity_y','downforce','heading_fl','brake','lift_fl','lift_fr','lift_rl','lift_rr','jet_lift_0','jet_lift_1','jet_lift_2','jet_lift_3','torque_x','torque_y','torque_z','angvel_x','angvel_y','angvel_z',
               'throttle','steer','fan_rpm','instant_services','speed','fan_requested',
               'refill_target_k','thermal_guard_temperature_c','unlimited_air_active','course_autopilot_active']
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
        previous=q('RunRhai',dict(code='twin_authority()'))['stdout']
        q('OpenTwin',dict(path=str(root)))
        deadline=time.monotonic()+60
        last_models=[]
        while time.monotonic()<deadline:
            current=q('RunRhai',dict(code='twin_authority()'))['stdout']
            state=q('GetReadiness',{})
            if state['faulted']: raise RuntimeError(state)
            if current != previous and state['ready'] and not state['pending_count'] and not state['world_hold']:
                models=q('CosimStatus',dict(include_values=True))['entities']
                last_models=[{k:e.get(k) for k in ['name','status','model','modelica_current_time']}
                             for e in models if e.get('has_simcomponent')]
                if any(e.get('name')=='/World/Roadster' and e.get('status')=='Running'
                       and e.get('has_simcomponent') and isinstance(e.get('model'),str)
                       and e['model'].startswith(f'twin://{current}/') for e in models):
                    car=int(q('RunRhai',dict(code='find_path("/World/Roadster")'))['stdout'])
                    if q('RunRhai',dict(code=f'is_controlled({car})'))['stdout']=='true':
                        return car
            time.sleep(.1)
        raise RuntimeError('Fresh Twin did not publish its running, controlled Roadster: '
                           +json.dumps(dict(twin=current,readiness=state,models=last_models)))
    await_ready()
    for name in ['ControlLeft','ControlRight','AltLeft','AltRight','ShiftLeft','ShiftRight','SuperLeft','SuperRight']:
        q('InjectWindowInput',{'event':{'Key':dict(key=name,state='Released',text=None,repeat=False)}})
    for name in ['I','J','K','L','P','O','Q','E','R','C','F','W','A','S','D','Space','Comma','Period','ShiftLeft']: key(name,'Released')
    # Remove any popup/text focus so native input reaches the controller.
    for state in ['Pressed','Released']:
        q('InjectWindowInput',{'event':{'PointerButton':dict(button='Primary',state=state,x=1100,y=150)}})
    time.sleep(.2)
    results=[]
    try:
        # Each key passes through the native input map and authored bindings.
        for name,axis,sign,corner in [('K','y',1,None),('Space','z',-1,None),
                ('J','x',-1,None),('L','x',1,None),('I','y',1,0),('P','y',1,2),('Comma','y',1,1),('Period','y',1,3),('Q','y',1,[0,1]),('E','y',1,[2,3]),('R','y',1,[0,2]),('C','y',1,[1,3])]:
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
            input_name={'I':'lift_fl','P':'lift_fr','Comma':'lift_rl','Period':'lift_rr','Q':'lift_fl','E':'lift_fr','R':'lift_fl','C':'lift_rl'}.get(name,'thrust_'+axis)
            row['input_value']=value(held,input_name,'in')
            if corner is not None:
                jets=[value(held,'jet_lift_'+str(i)) for i in range(4)]
                row.update(corner_forces_n=jets,torque_x_nm=value(held,'torque_x'),torque_z_nm=value(held,'torque_z'))
                selected=corner if isinstance(corner,list) else [corner]
                row['corner_ok']=all(jets[i]>100 for i in selected) and all(abs(f)<1 for i,f in enumerate(jets) if i not in selected)
                if name in ['R','C']: row['corner_ok']=row['corner_ok'] and abs(jets[selected[0]]-jets[selected[1]])<.01
                if name in ['Q','E']:
                    row['body_pitch_moment_nm']=value(held,'thruster_pitch_moment_nm')
                    row['corner_ok']=row['corner_ok'] and abs(row['body_pitch_moment_nm'])<.01
            snapshot=json.loads(q('RunRhai',dict(code=f'let ph=query("QueryPhysicsState",#{{id:{car}}}); let ps=query("ReadPorts",#{{api_id:{car},port_names:["gas_mass_kg"]}}); let gas=0.0; for p in ps.ports {{if p.direction=="out" {{gas=p.value;}}}} [ph.mass_kg,gas]'))['stdout'])
            row['physical_mass_kg'],row['mass_snapshot_gas_kg']=snapshot
            row['ok']=(sign*force>1 and row['gas_after_kg']<row['gas_before_kg'] if sign else
                       abs(force)<1 and row['input_value']==-1 and abs(row['gas_after_kg']-row['gas_before_kg'])<1e-5)
            if corner is not None:
                # Raw valves close on release. No automatic counter-jet firing.
                row['ok']=row['ok'] and value(released,input_name,'in')==0 and abs(after)<max(1.0,abs(force)*.05)
            else:
                row['ok']=row['ok'] and abs(after)<max(1.0,abs(force)*.05)
            if sign:
                expected_input=-1.0 if name=='J' else 1.0
                row['ok']=row['ok'] and row['input_value']==expected_input
            row['ok']=row['ok'] and abs(row['physical_mass_kg']-(1700+row['mass_snapshot_gas_kg']))<.1
            row['ok']=row['ok'] and row.get('corner_ok',True)
            results.append(row)
            print(json.dumps(row),flush=True)
        car=fresh_twin()
        def fan_state():
            ps=q('ReadPorts',dict(api_id=car,port_names=['fan_requested']))['ports']
            return value(ps,'fan_requested')
        initial=fan_state();key('F','Pressed');wait_sim(.15);toggled=fan_state()
        wait_sim(.4);held=fan_state();key('F','Released');wait_sim(.1);released=fan_state()
        spinning=value(ports(car),'fan_rpm')
        key('F','Pressed');wait_sim(.15);restored=fan_state();key('F','Released')
        results.append(dict(key='F',initial=initial,pressed=toggled,held=held,released=released,
            second_press=restored,fan_rpm=spinning,
            ok=toggled==1-initial and held==toggled and released==toggled and restored==initial
            and (toggled==0 or spinning>100)))
        for name,sign in [('W',1),('S',-1)]:
            car=fresh_twin()
            key(name,'Pressed');wait_sim(.6);drive=ports(car)
            key(name,'Released');wait_sim(.15);released=ports(car)
            results.append(dict(key=name,torque_nm=value(drive,'torque_left'),speed_mps=value(drive,'speed'),
                ok=sign*value(drive,'torque_left')>0 and value(drive,'throttle','in')==sign
                and value(drive,'speed')>.2 and value(released,'throttle','in')==0))
        for name,sign in [('A',1),('D',-1)]:
            car=fresh_twin()
            key(name,'Pressed');wait_sim(.3);steer=ports(car)
            key(name,'Released');wait_sim(.15);released=ports(car)
            results.append(dict(key=name,heading_rad=value(steer,'heading_fl'),
                ok=sign*value(steer,'heading_fl')>0 and value(released,'steer','in')==0))
        for name in ['ShiftLeft','ShiftRight']:
            car=fresh_twin()
            key('W','Pressed');wait_sim(.5);key('W','Released');moving=value(ports(car),'speed')
            key(name,'Pressed');wait_sim(1.5);brake=ports(car)
            key(name,'Released');wait_sim(.15);released=ports(car)
            results.append(dict(key=name,brake=value(brake,'brake','in'),before_speed=moving,
                stopped_speed=value(brake,'speed'),ok=value(brake,'brake','in')==1
                and moving>.2 and value(brake,'speed')<.2 and value(released,'brake','in')==0))
        car=fresh_twin()
        key('K','Pressed');wait_sim(.2);key('K','Released');wait_sim(.3)
        depleted=ports(car)
        key('Tab','Pressed');wait_sim(.15);refilled=ports(car)
        wait_sim(.3);held=ports(car);key('Tab','Released')
        results.append(dict(key='Tab',before_kg=value(depleted,'gas_mass_kg'),after_kg=value(refilled,'gas_mass_kg'),
            ok=value(refilled,'gas_mass_kg')>value(depleted,'gas_mass_kg')+1
            and value(refilled,'instant_services')==value(depleted,'instant_services')+1
            and value(held,'instant_services')==value(refilled,'instant_services')))
        def tick():return int(q('RunRhai',dict(code='clock_snapshot().sim_tick'))['stdout'])
        for modifier in ['ControlLeft','ControlRight']:
            key(modifier,'Pressed');time.sleep(.05);key('P','Pressed');time.sleep(.1)
            key('P','Released');key(modifier,'Released');time.sleep(.1)
            paused=tick();time.sleep(.25);still=tick()
            key(modifier,'Pressed');time.sleep(.05);key('P','Pressed');time.sleep(.1)
            key('P','Released');key(modifier,'Released');time.sleep(.1)
            resumed=tick()
            results.append(dict(key=modifier+'+P',paused_tick=paused,held_tick=still,resumed_tick=resumed,
                ok=paused==still and resumed>still))
        def camera():
            return next(c['entity'] for c in q('SceneCameraAudit',{})['candidates']
                        if c['camera_active'] and c['render_target']=='window')
        before=camera();key('V','Pressed');time.sleep(.15);key('V','Released');after=camera()
        results.append(dict(key='V',before=before,after=after,ok=before!=after))
        q('ObserveAvatar',{})

        # Click the rendered HTML controls through native pointer events. This
        # catches a missing HUI picking feature, which leaves decorative buttons
        # visible while installing neither Button nor the press observer.
        car=fresh_twin()
        output.mkdir(parents=True,exist_ok=True)
        screenshot=output/'controls-layout.png'
        previous_mtime=screenshot.stat().st_mtime_ns if screenshot.exists() else None
        q('CaptureScreenshot',dict(save_to_file=True,path=str(screenshot)))
        deadline=time.monotonic()+15
        while not screenshot.exists() or screenshot.stat().st_mtime_ns==previous_mtime:
            if time.monotonic()>deadline:raise RuntimeError('Control layout capture was not written')
            time.sleep(.05)
        width,height=struct.unpack('>II',screenshot.read_bytes()[16:24])
        def click(x,y):
            q('InjectWindowInput',{'event':{'PointerMove':dict(x=x,y=y)}})
            time.sleep(.08)
            for state in ['Pressed','Released']:
                q('InjectWindowInput',{'event':{'PointerButton':dict(button='Primary',state=state,x=x,y=y)}})
                time.sleep(.08)
            wait_sim(.15)
        def out(name):return value(ports(car),name)
        click(302,height-79);enabled=out('fan_requested')
        click(302,height-79);disabled=out('fan_requested')
        results.append(dict(key='HUD fans',ok=enabled==1 and disabled==0))
        for label,y,port in [('fill temperature',height-160,'refill_target_k'),
                             ('discharge cutoff',height-227,'thermal_guard_temperature_c')]:
            initial=out(port);click(width-47,y);raised=out(port)
            click(width-240,y);restored=out(port)
            results.append(dict(key='HUD '+label,initial=initial,raised=raised,restored=restored,
                ok=abs(raised-initial-5)<.001 and abs(restored-initial)<.001))
        click(width-143,height-122);enabled=out('unlimited_air_active')
        click(width-143,height-122);disabled=out('unlimited_air_active')
        results.append(dict(key='HUD unlimited air',ok=enabled==1 and disabled==0))
        key('K','Pressed');wait_sim(.2);key('K','Released');wait_sim(.3)
        depleted=ports(car);click(width-143,height-79);refilled=ports(car)
        results.append(dict(key='HUD refill',ok=value(refilled,'gas_mass_kg')>value(depleted,'gas_mass_kg')+1
            and value(refilled,'instant_services')==value(depleted,'instant_services')+1))
        car=fresh_twin();click(343,78);autopilot=out('course_autopilot_active')
        key('W','Pressed');wait_sim(.2);key('W','Released');manual=out('course_autopilot_active')
        results.append(dict(key='HUD autopilot and manual takeover',ok=autopilot==1 and manual==0))
        previous=q('RunRhai',dict(code='twin_authority()'))['stdout'];click(215,78)
        deadline=time.monotonic()+60
        while time.monotonic()<deadline:
            state=q('GetReadiness',{})
            if q('RunRhai',dict(code='twin_authority()'))['stdout']!=previous and state['ready'] and not state['world_hold'] and not state['pending_count']:
                if q('RunRhai',dict(code='is_controlled(find_path("/World/Roadster"))'))['stdout']=='true':break
            time.sleep(.05)
        else:raise RuntimeError('HUD retry did not restore a ready, controlled Twin')
        results.append(dict(key='HUD retry',ok=True))
        status=q('ScriptInspect',dict(target=int(q('RunRhai',dict(code='find_path("/World")'))['stdout'])))
        results.append(dict(key='driver event health',status=status['status'],ok=status['status']['ok']))
    finally:
        for name in ['I','J','K','L','P','O','Q','E','R','C','F','W','A','S','D','Space','Comma','Period','ShiftLeft','ShiftRight','Tab','V','ControlLeft','ControlRight']: key(name,'Released')
        q('InjectWindowInput',{'event':{'Key':dict(key='ShiftLeft',state='Released',text=None,repeat=False)}})
    report=dict(ok=all(r['ok'] for r in results),checks=results)
    output.mkdir(parents=True,exist_ok=True)
    (output/'controls.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    return 0 if report['ok'] else 1


if __name__=='__main__':
    raise SystemExit(main())
