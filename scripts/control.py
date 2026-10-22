#!/usr/bin/env python3
"""Control the loaded Roadster through the ordinary local LunCoSim API."""
import argparse
import json
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port',type=int,default=4198)
    parser.add_argument('--throttle',type=float)
    parser.add_argument('--steer',type=float)
    parser.add_argument('--brake',type=float)
    parser.add_argument('--fan',type=float)
    parser.add_argument('--headlights',type=float)
    parser.add_argument('--boost',type=float)
    parser.add_argument('--lift',type=float)
    parser.add_argument('--thrust-x',type=float)
    parser.add_argument('--thrust-y',type=float)
    parser.add_argument('--thrust-z',type=float)
    for name in ['lift-fl','lift-fr','lift-rl','lift-rr','refill']:
        parser.add_argument('--'+name,type=float)
    parser.add_argument('--refill-temperature',type=float,help='Live external refill target in K (253.15–333.15)')
    parser.add_argument('--discharge-cutoff',type=float,help='Live study temperature cutoff in °C (-130..20); no reload')
    parser.add_argument('--status',action='store_true')
    parser.add_argument('--keyboard',action='store_true',help='Return control to the native keyboard')
    parser.add_argument('--camera',choices=['chase','driver','free'])
    args = parser.parse_args()

    def call(command, params):
        payload = json.dumps(dict(type='ExecuteCommand',command=command,params=params)).encode()
        request = urllib.request.Request(f'http://127.0.0.1:{args.port}/api/commands',
                                         data=payload,headers={'Content-Type':'application/json'})
        response = json.load(urllib.request.urlopen(request,timeout=15))
        if response.get('error'):
            raise RuntimeError(response['error'])
        return response['data']

    target = int(call('RunRhai',{'code':'find_path("/World/Roadster")'})['stdout'])
    if target < 0:
        parser.error('No /World/Roadster in the current scene')
    if args.camera:
        if args.camera == 'free':
            print(json.dumps(call('ObserveAvatar',{})))
        else:
            print(json.dumps(call('SetUserCamera',{'name':{'chase':'ChaseCamera','driver':'DriverCamera'}[args.camera]})))
    writes = []
    for name in ['throttle','steer','brake','fan','headlights','boost','lift','thrust_x','thrust_y','thrust_z','lift_fl','lift_fr','lift_rl','lift_rr','refill']:
        value = getattr(args,name)
        if value is not None:
            low = -1 if name in ['throttle','steer','thrust_x','thrust_y','thrust_z','lift_fl','lift_fr','lift_rl','lift_rr','refill'] else 0
            if not low <= value <= 1:
                parser.error(f'{name} must be between {low} and 1')
            writes.append([name,value])
    control_requested=bool(writes)
    if args.discharge_cutoff is not None:
        if not -130 <= args.discharge_cutoff <= 20: parser.error('discharge-cutoff must be -130..20 °C')
        writes.append(['discharge_cutoff_c',args.discharge_cutoff])
    if args.refill_temperature is not None:
        if not 253.15 <= args.refill_temperature <= 333.15: parser.error('refill-temperature must be 253.15–333.15 K')
        writes.append(['refill_target_temperature_k',args.refill_temperature])
    if args.keyboard:
        call('SetPorts',dict(target=target,producer_id=4198001,writes=[
            [name,0.0] for name in ['throttle','steer','brake','boost','lift','thrust_x','thrust_y','thrust_z','lift_fl','lift_fr','lift_rl','lift_rr','refill']]))
        call('AcquireControl',dict(target=target,bind_camera=True))
        call('ObserveAvatar',{})
    if writes:
        if control_requested:
            avatar=int(call('RunRhai',{'code':'find_path("/World/Avatar")'})['stdout'])
            if avatar>=0: call('ReleaseControlSource',dict(source=avatar))
            call('AcquireControl',dict(target=target,bind_camera=False))
        print(json.dumps(call('SetPorts',dict(target=target,producer_id=4198001,writes=writes)),indent=2))
    if args.status or not writes:
        print(json.dumps(call('ReadPorts',dict(api_id=target,port_names=[
            'speed','position_x','position_y','position_z','yaw','soc',
            'temperature_k','impulse_remaining','thruster_force','battery_power',
            'gas_mass_kg','tank_temperature_c','thermal_guard_temperature_c','tank_pressure_pa','force_local_x','force_local_y','force_local_z'])),indent=2))


if __name__ == '__main__':
    main()
