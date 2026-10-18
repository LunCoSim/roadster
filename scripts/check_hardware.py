#!/usr/bin/env python3
"""Inspect the loaded Rocket's native nozzles and solved Modelica tank inventory.

Freshen the Twin first so this records the full-tank baseline, not a driven car.
Structural assertions establish the study configuration, not Tesla calibration.
"""
import argparse,json,re,time,urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--port',type=int,default=4198);args=ap.parse_args()
    def q(command,**params):
        req=urllib.request.Request(f'http://127.0.0.1:{args.port}/api/commands',data=json.dumps(dict(type='ExecuteCommand',command=command,params=params)).encode(),headers={'Content-Type':'application/json'})
        r=json.load(urllib.request.urlopen(req,timeout=30))
        if 'error' in r:raise RuntimeError(r['error'])
        return r['data']
    old=q('RunRhai',code='twin_name()')['stdout'];q('OpenTwin',path=str(ROOT))
    deadline=time.monotonic()+60
    while time.monotonic()<deadline:
        state=q('GetReadiness');current=q('RunRhai',code='twin_name()')['stdout']
        if current!=old and state['ready'] and not state['pending_count'] and not state['world_hold']:
            models=q('CosimStatus',include_values=False)['entities']
            if any(e.get('name')=='/World/Roadster' and e.get('status')=='Running' for e in models):break
        time.sleep(.1)
    else:raise RuntimeError('Fresh Rocket not running')
    car=int(q('RunRhai',code='find_path("/World/Roadster")')['stdout'])
    nozzles=[]
    for group in ['RearThrusters','PerimeterThrusters']:
        names=re.findall(r'def Cylinder "(Nozzle\d+)"',(ROOT/f'components/{group}.usda').read_text())
        for name in names:
            path=f'/World/Roadster/{group}/{name}';gid=int(q('RunRhai',code='find_path('+json.dumps(path)+')')['stdout'])
            nozzles.append(dict(path=path,native_id=gid))
    seats={name:q('QueryUsdPrim',path='/World/Roadster/Body/'+name,attrs=['visibility']) for name in ['DriverSeat','PassengerSeat']}
    visible_seats=[name for name,seat in seats.items() if seat['active'] and seat['attrs'].get('visibility','inherited')!='invisible']
    names=['gas_mass_kg','tank_volume_m3','tank_temperature_k','tank_pressure_pa','rear_tank_air_kg','cabin_tank_air_kg','vehicle_mass_kg']
    values={p['name']:p['value'] for p in q('ReadPorts',api_id=car,port_names=names)['ports'] if p['direction']=='out'}
    native=q('QueryPhysicsState',id=car);failures=[]
    if visible_seats!=['DriverSeat']:failures.append('Rocket must have one available seat')
    if len(nozzles)!=10 or any(n['native_id']<0 for n in nozzles):failures.append('Rocket must instantiate ten authored native nozzles')
    if abs(values['gas_mass_kg']-250)>.01:failures.append('Expected 250 kg TOTAL baseline')
    if abs(values['tank_volume_m3']-.6)>1e-6:failures.append('Expected 600 L total internal volume')
    if abs(values['rear_tank_air_kg']+values['cabin_tank_air_kg']-values['gas_mass_kg'])>1e-6:failures.append('Tank inventory does not sum to total')
    if abs(values['cabin_tank_air_kg']-2*values['rear_tank_air_kg'])>1e-6:failures.append('Common-state mass split does not match 200/400 L')
    if abs(native['mass_kg']-values['vehicle_mass_kg'])>.01:failures.append('Native mass did not consume solved gas inventory')
    report=dict(ok=not failures,nozzles=nozzles,available_seats=visible_seats,modelica=values,native_mass_kg=native['mass_kg'],failures=failures,
        assumptions='Two rigid volumes share uniform density/temperature; cylinder mass split is calculated, not a manufacturer mass specification.')
    (ROOT/'results/hardware.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
    return 0 if report['ok'] else 1
if __name__=='__main__':raise SystemExit(main())
