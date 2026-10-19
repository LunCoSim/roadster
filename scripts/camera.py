#!/usr/bin/env python3
"""Inspect/tune the native avatar follow rig, or replace its Twin-owned policy live."""
import argparse,json,math,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def request(port,command,**params):
    req=urllib.request.Request(f'http://127.0.0.1:{port}/api/commands',
        data=json.dumps(dict(type='ExecuteCommand',command=command,params=params)).encode(),
        headers={'Content-Type':'application/json'})
    reply=json.loads(urllib.request.urlopen(req,timeout=30).read())
    if 'error' in reply:raise RuntimeError(reply['error'])
    return reply['data']

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--port',type=int,default=4198)
    ap.add_argument('--distance',type=float,help='Boom distance, metres')
    ap.add_argument('--height',type=float,help='Focus height in surface/world up, metres')
    ap.add_argument('--tilt',type=float,help='Elevation tilt, degrees; negative looks down')
    ap.add_argument('--azimuth',type=float,help='Orbit yaw offset, degrees')
    ap.add_argument('--damping',type=float,help='Native smoothing damping in [0,1); larger is slower')
    ap.add_argument('--mode',choices=['stabilized','heading','body'])
    ap.add_argument('--reload-policy',nargs='?',const=str(ROOT/'scripting/policy/roadster_camera.rhai'),
                    help='Replace the active Twin follow policy from a Rhai source file')
    args=ap.parse_args()
    params={}
    for option,field in [('distance','distance_m'),('height','height_m'),('tilt','pitch_rad'),('azimuth','yaw_rad')]:
        value=getattr(args,option)
        if value is None:continue
        if not math.isfinite(value):ap.error(option+' must be finite')
        if option=='distance' and value<=0:ap.error('distance must be positive')
        if option=='tilt' and abs(value)>=89:ap.error('tilt must be within +/-89 degrees')
        if option in ['tilt','azimuth']:value=math.radians(value)
        params[field]=value
    if args.mode:params['mode']=args.mode
    if args.damping is not None:params['damping']=args.damping
    if params:print(request(args.port,'SetCameraFollow',**params))
    print(request(args.port,'RunRhai',code='let a=find_path("/World/Avatar");print(get(a,"SpringArmCamera"));')['stdout'].strip())
    if args.reload_policy:
        source=Path(args.reload_policy).read_text()
        print(request(args.port,'RegisterToolLibrary',name='follow_camera',source=(ROOT/'tools/follow_camera.rhai').read_text()))
        print(request(args.port,'RunRhaiToolHook',tool='follow_camera',hook='replace_policy',args={'Map':{'source':{'String':source}}}))

if __name__=='__main__':main()
