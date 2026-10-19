#!/usr/bin/env python3
"""Check live camera tuning/policies and native C/V routing in a loaded Roadster.

Run in a loaded course. Physics is held before any camera edits;
this does not write physical state or run a second vehicle controller.
"""
import argparse,json,math,time
from pathlib import Path
from types import SimpleNamespace
from check_keyboard_course import Pilot,ROOT

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--port',type=int,default=4198)
    ap.add_argument('--output',default='results/camera-follow.json')
    args=ap.parse_args();p=Pilot(SimpleNamespace(port=args.port,output=args.output))
    report={'ok':False,'checks':{},'failures':[]}
    def script(code):return p.q('RunRhai',code=code)['stdout'].strip()
    def check(name,value):
        report['checks'][name]=bool(value)
        if not value:raise RuntimeError(name)
    def tick():return int(script('print(clock_snapshot().sim_tick);'))
    def active():return [c for c in p.q('SceneCameraAudit')['candidates'] if c['camera_active'] and c['render_target']=='window'][0]
    def rig():return script('print(get(find_path("/World/Avatar"),"SpringArmCamera"));')
    def replace(source):
        r=p.q('RunRhaiToolHook',tool='follow_camera',hook='replace_policy',args={'Map':{'source':{'String':source}}})
        if '"ok": true' not in r.get('stdout',''):raise RuntimeError(str(r))
        time.sleep(.3)
    original=(ROOT/'scripting/policy/roadster_camera.rhai').read_text()
    try:
        p.q('StepSimulation',hold=True)
        p.q('ObserveAvatar');time.sleep(.2)
        before=tick()
        p.q('SetCameraFollow',distance_m=15.0,height_m=.9,pitch_rad=-.3,yaw_rad=.25,mode='stabilized',damping=.8)
        values=json.loads(script('let a=find_path("/World/Avatar");print([get(a,"SpringArmCamera.distance"),get(a,"SpringArmCamera.vertical_offset"),get(a,"SpringArmCamera.pitch"),get(a,"SpringArmCamera.yaw"),get(a,"SpringArmCamera.track_heading")]);'))
        check('live_settings',all(abs(a-b)<1e-6 for a,b in zip(values[:4],[15,.9,-.3,.25])) and values[4]==False)
        previous=rig()
        try:p.q('SetCameraFollow',distance_m=99,pitch_rad=4.0)
        except RuntimeError:pass
        check('invalid_batch_is_atomic',rig()==previous)
        camera=active()['entity']
        p.keys({'KeyC'},0);time.sleep(.12);p.keys(set(),0);time.sleep(.12)
        check('rear_jet_C_keeps_camera',active()['entity']==camera)
        p.keys({'KeyV'},0);time.sleep(.12);p.keys(set(),0);time.sleep(.12)
        check('semantic_V_cycles_camera',active()['entity']!=camera)
        p.q('ObserveAvatar');time.sleep(.2)
        p.q('SetCameraFollow',mode='body');check('body_mode', 'FullAttitude' in rig())
        p.q('SetCameraFollow',mode='heading');check('heading_mode','"track_heading": true' in rig())
        p.q('SetCameraFollow',mode='stabilized')
        p.q('RegisterToolLibrary',name='follow_camera',source=(ROOT/'tools/follow_camera.rhai').read_text())
        replace('fn follow_camera(ctx) { #{distance:22.0,attitude:"world",yaw:0.0,pitch:-0.2,rotation_alpha:1.0,position_alpha:1.0} }')
        xyz=json.loads(script('let a=find_path("/World/Avatar");let c=find_path("/World/Roadster");print([get(a,"Transform.translation.x"),get(a,"Transform.translation.z"),get(c,"Transform.translation.x"),get(c,"Transform.translation.z")]);'))
        check('live_policy_realized',abs(math.hypot(xyz[0]-xyz[2],xyz[1]-xyz[3])-22*math.cos(.2))<.02)
        report['policy_camera_xz']=xyz
        replace('fn follow_camera(ctx) { #{distance:-1.0} }')
        diagnostics=p.q('RuntimeDiagnostics')
        check('invalid_policy_visible','camera-follow' in json.dumps(diagnostics) and 'distance' in json.dumps(diagnostics))
        report['rejected_policy_diagnostics']=diagnostics
        check('policy_error_does_not_fault_physics',not p.q('GetReadiness')['faulted'])
        replace(original)
        check('policy_recovers','camera-follow' not in json.dumps(p.q('RuntimeDiagnostics')))
        check('editing_does_not_advance_physics',tick()==before)
        p.q('SetCameraFollow',distance_m=14,height_m=.8,pitch_rad=-.24,yaw_rad=0,mode='stabilized',damping=.92)
        time.sleep(.3);p.screenshot('stable')
        report['ok']=True
    except Exception as e:report['failures'].append(str(e))
    finally:
        p.release()
        try:replace(original)
        except Exception as e:report['failures'].append('Policy restore: '+str(e));report['ok']=False
        p.out.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    return 0 if report['ok'] else 1
if __name__=='__main__':raise SystemExit(main())
