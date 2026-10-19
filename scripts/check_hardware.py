#!/usr/bin/env python3
"""Inspect the loaded Rocket's native nozzles and solved Modelica tank inventory.

Freshen the Twin first so this records the full-tank baseline, not a driven car.
Structural assertions establish the study configuration, not Tesla calibration.
"""
import argparse,json,re,time,urllib.request
from pathlib import Path

from study_geometry import MOUNTS,thruster_stations

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
    nozzles=[];failures=[]
    rear,perimeter=thruster_stations()
    expected_stations=dict(RearThrusters=rear,PerimeterThrusters=perimeter)
    for group in ['RearThrusters','PerimeterThrusters']:
        names=re.findall(r'def Cylinder "(Nozzle\d+)"',(ROOT/f'components/{group}.usda').read_text())
        for name in names:
            path=f'/World/Roadster/{group}/{name}';gid=int(q('RunRhai',code='find_path('+json.dumps(path)+')')['stdout'])
            prim=q('QueryUsdPrim',path=path,attrs=['xformOp:translate','axis','radius'])
            position=prim['attrs']['xformOp:translate'];axis=prim['attrs']['axis']
            index=int(name.replace('Nozzle',''));expected=expected_stations[group][index]
            if any(abs(position[i]-expected[i])>1e-6 for i in range(3)):failures.append('Mount geometry differs from authoring owner: '+path)
            if axis!=('Z' if group=='RearThrusters' else expected[3]):failures.append('Incorrect nozzle axis: '+path)
            nozzles.append(dict(path=path,native_id=gid,body_position_m=position,exhaust_axis=axis))
    seats={name:q('QueryUsdPrim',path='/World/Roadster/Body/'+name,attrs=['visibility']) for name in ['DriverSeat','PassengerSeat']}
    visible_seats=[name for name,seat in seats.items() if seat['active'] and seat['attrs'].get('visibility','inherited')!='invisible']
    names=['gas_mass_kg','tank_volume_m3','tank_temperature_k','tank_pressure_pa','rear_tank_air_kg','cabin_tank_air_kg','vehicle_mass_kg','chassis_mass_kg','chassis_com_y','chassis_com_z']
    values={p['name']:p['value'] for p in q('ReadPorts',api_id=car,port_names=names)['ports'] if p['direction']=='out'}
    native=q('QueryPhysicsState',id=car)
    # Parameters are preparation-time values, not live input signals. Read
    # their composed USD owner; ReadPorts correctly returns None for them.
    attrs=q('QueryUsdPrim',path='/World/Roadster',attrs=['inputs:'+name for name in MOUNTS])['attrs']
    parameters={name:attrs['inputs:'+name] for name in MOUNTS}
    for name,expected in MOUNTS.items():
        if name not in parameters or abs(parameters[name]-expected)>1e-6:failures.append('USD Modelica mount parameter drift: '+name)
    if abs(native['center_of_mass_m'][1]-values['chassis_com_y'])>1e-6 or abs(native['center_of_mass_m'][2]-values['chassis_com_z'])>1e-6:failures.append('Modelica wrench COM differs from native COM')
    mechanism=[]
    for prefix,names_part in [('Wheel_', ['FL','FR','RL','RR']),('Suspension_', ['FL','FR','RL','RR']),('SteeringKnuckle_', ['FL','FR'])]:
        for name in names_part:
            path='/World/Roadster/'+prefix+name
            ident=int(q('RunRhai',code='find_path('+json.dumps(path)+')')['stdout'])
            state=q('QueryPhysicsState',id=ident);mechanism.append(dict(path=path,mass_kg=state['mass_kg']))
            if prefix=='Wheel_' and (not state['collider_present'] or state['body_mode']!='dynamic'):failures.append('Wheel has no dynamic collider: '+path)
    total_native_mass=native['mass_kg']+sum(p['mass_kg'] for p in mechanism)
    if abs(total_native_mass-values['vehicle_mass_kg'])>.01:failures.append('Complete native mass disagrees with inventory model')
    wheel_clearances=[]
    for index,wheel in [(0,'Wheel_FL'),(1,'Wheel_RL'),(2,'Wheel_FR'),(3,'Wheel_RR')]:
        prim=q('QueryUsdPrim',path='/World/Roadster/'+wheel,attrs=['xformOp:translate','physxVehicleWheel:radius'])
        axle_z=prim['attrs']['xformOp:translate'][2];radius=prim['attrs']['physxVehicleWheel:radius']
        # Axial clearance between the cylindrical nozzle and tire swept sphere.
        margin=perimeter[index][2]-axle_z-radius-.072
        wheel_clearances.append(dict(wheel=wheel,nozzle=index,behind_tire_clearance_m=margin))
        if margin<0:failures.append('Lift nozzle overlaps or precedes its wheel: '+wheel)
    if visible_seats!=['DriverSeat']:failures.append('Rocket must have one available seat')
    if len(nozzles)!=10 or any(n['native_id']<0 for n in nozzles):failures.append('Rocket must instantiate ten authored native nozzles')
    if abs(values['gas_mass_kg']-250)>.01:failures.append('Expected 250 kg TOTAL baseline')
    if abs(values['tank_volume_m3']-.6)>1e-6:failures.append('Expected 600 L total internal volume')
    if abs(values['rear_tank_air_kg']+values['cabin_tank_air_kg']-values['gas_mass_kg'])>1e-6:failures.append('Tank inventory does not sum to total')
    if abs(values['cabin_tank_air_kg']-2*values['rear_tank_air_kg'])>1e-6:failures.append('Common-state mass split does not match 200/400 L')
    if abs(native['mass_kg']-values['chassis_mass_kg'])>.01:failures.append('Native mass did not consume solved gas inventory')
    report=dict(ok=not failures,nozzles=nozzles,available_seats=visible_seats,mount_parameters=parameters,wheel_clearances=wheel_clearances,modelica=values,mechanism=mechanism,total_native_mass_kg=total_native_mass,native_mass_kg=native['mass_kg'],failures=failures,
        assumptions='Two rigid volumes share uniform density/temperature; cylinder mass split is calculated, not a manufacturer mass specification.')
    (ROOT/'results/hardware.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
    return 0 if report['ok'] else 1
if __name__=='__main__':raise SystemExit(main())
