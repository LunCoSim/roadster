#!/usr/bin/env python3
"""Drive the unmodified main course through native keyboard events.

Example:
  python3 tests/python/check_keyboard_course.py --launch --binary /path/to/luncosim

The test pilot observes telemetry and presses the same digital keys as a player.
It never writes actuator ports, vehicle pose/velocity, inventory or checkpoints.
All key transitions, samples, stage screenshots and the final verdict are saved.
"""
import argparse
import hashlib
import json
import math
import os
import re
from pathlib import Path
import socket
import subprocess
import time
import traceback
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
KEYS = {'KeyW', 'KeyA', 'KeyS', 'KeyD', 'Space', 'ShiftLeft', 'KeyK',
        'KeyF', 'KeyR', 'KeyC', 'KeyQ', 'KeyE', 'KeyJ', 'KeyL', 'Tab',
        'ControlLeft', 'ControlRight', 'KeyP', 'KeyV'}
PORTS = ['course_failure_reason', 'course_time_s', 'course_stage', 'course_blocks', 'course_air_rotation_degrees',
         'position_x', 'position_y', 'position_z', 'velocity_y', 'speed_mps', 'yaw',
         'pitch_rate_deg_s', 'roll_rate_deg_s', 'up_alignment', 'flight_control_weight',
         'fan_requested', 'fan_seal', 'downforce', 'gas_mass_kg', 'tank_temperature_k',
         'tank_pressure_pa', 'instant_services', 'instant_air_added_kg',
         'vehicle_mass_kg', 'chassis_mass_kg', 'unlimited_air_active', 'heading_fl',
         'quat_w', 'quat_x', 'quat_y', 'quat_z', 'yaw_rate_deg_s',
         'full_lift_force_n', 'lift_net_acceleration', 'velocity_z',
         'course_landing_impact_speed', 'course_air_pitch_degrees', 'course_step', 'course_forward_speed', 'course_forward_z', 'course_air_yaw_degrees', 'course_air_roll_degrees', 'course_backward_distance_m',
         'drive_left', 'drive_right', 'jet_force_y', 'jet_force_z', 'course_autopilot_active']
PILOT_KEYS = {'forward':'KeyW','reverse':'KeyS','left':'KeyA','right':'KeyD',
              'boost':'Space','brake':'ShiftLeft','lift':'KeyK','pitch_up':'KeyR',
              'pitch_down':'KeyC','yaw_left':'KeyJ','yaw_right':'KeyL',
              'roll_left':'KeyQ','roll_right':'KeyE'}
PORTS += ['pilot_'+name for name in [*PILOT_KEYS, 'fan']]


class Pilot:
    def __init__(self, args):
        self.args = args
        self.base = f'http://127.0.0.1:{args.port}/api/commands'
        self.os_input = None
        self.held = set()
        self.report = dict(ok=False, input_path='InjectWindowInput/native keyboard',
                           scene='scenes/roadster_skill_course.usda', keys=[], samples=[],
                           stages=[], screenshots=[], failures=[])
        self.out = ROOT / args.output
        self.out.parent.mkdir(parents=True, exist_ok=True)
        self.fan_until = self.fan_retry = 0.0
        self.autopilot_started = False
        self.native_offset = 0
        self.previous_action = None
        self.last_airborne = None

    def q(self, command, **params):
        request = urllib.request.Request(self.base, data=json.dumps(dict(
            type='ExecuteCommand', command=command, params=params)).encode(),
            headers={'Content-Type': 'application/json'})
        try:
            raw = urllib.request.urlopen(request, timeout=30).read()
        except urllib.error.HTTPError as exc:
            raise RuntimeError(f'{command}: HTTP {exc.code}: {exc.read().decode(errors="replace")}') from exc
        if command == 'CaptureScreenshot':
            return raw
        response = json.loads(raw)
        if 'error' in response:
            raise RuntimeError(f'{command}: {response["error"]}')
        return response['data']

    def keys(self, desired, t):
        if self.os_input:self.os_input.ensure_focus()
        if not desired <= KEYS:
            raise ValueError(desired - KEYS)
        # Release the chord's letter before its modifier, as a player can.
        releases = sorted(self.held - desired, key=lambda k: (k.startswith('Control'), k))
        presses = sorted(desired - self.held, key=lambda k: (not k.startswith('Control'), k))
        for key, state in ([(k, 'Released') for k in releases] +
                           [(k, 'Pressed') for k in presses]):
            if self.os_input:
                self.os_input.key(key,state)
            else:
                self.q('InjectWindowInput', event={'Key': dict(
                    key=key, state=state, text=None, repeat=False)})
            self.report['keys'].append(dict(time_s=t, key=key, state=state))
            if state == 'Pressed':
                self.held.add(key)
            else:
                self.held.remove(key)

    def pointer(self,state,x,y):
        if self.os_input:
            self.os_input.pointer(state,x,y)
        else:
            self.q('InjectWindowInput',event={'PointerButton':dict(
                button='Primary',state=state,x=x,y=y)})

    def release(self):
        if self.os_input:
            self.os_input.release()
            self.held.clear()
            return
        for key in sorted(KEYS, key=lambda k: (k.startswith('Control'), k)):
            try:
                self.q('InjectWindowInput', event={'Key': dict(
                    key=key, state='Released', text=None, repeat=False)})
            except Exception:
                pass
        self.held.clear()

    def check_native_input_edges(self):
        path = self.out.with_suffix('.runtime.log')
        if not self.args.launch or not path.exists():
            return
        meanings = {'forward':'KeyW','backward':'KeyS','left':'KeyA','right':'KeyD',
                    'thrust':'Space','speed_boost':'KeyK','brake':'ShiftLeft'}
        with path.open() as stream:
            stream.seek(self.native_offset)
            lines = stream.readlines()
            self.native_offset = stream.tell()
        for line in lines:
            if 'EVENT: name=intent.edge' not in line:
                continue
            match = re.search(r'"edge": String\("(\w+)"\), "intent": String\("(\w+)"\).*sim_secs=([\d.]+)', line)
            if not match or match[2] not in meanings:
                continue
            key = meanings[match[2]]
            t = float(match[3])-self.input_epoch
            if t < 0:
                continue
            transitions = [e for e in self.report['keys'] if e['key']==key]
            nearby = any(abs(e['time_s']-t)<.075 for e in transitions)
            previous = [e for e in transitions if e['time_s']<=t+.025]
            expected = previous[-1]['state'].lower() if previous else 'released'
            if not nearby and match[1] != expected:
                detail = dict(time_s=t,key=key,native_state=match[1],expected=expected)
                if self.os_input:
                    detail['os_state']=self.os_input.held_state()
                    detail['native_ports']=self.q('ReadPorts',api_id=self.car,port_names=['steer','throttle','program_active'])['ports']
                self.report.setdefault('unexpected_native_inputs',[]).append(detail)
                raise RuntimeError(f'Uncommanded native input: {detail}')

    def screenshot(self, label):
        path = self.out.with_name(self.out.stem + '-' + label + '.png')
        path.write_bytes(self.q('CaptureScreenshot'))
        self.report['screenshots'].append(str(path.relative_to(ROOT)))

    def snapshot(self):
        state = self.q('GetReadiness')
        if state['faulted']:
            raise RuntimeError(f'Runtime fault: {state["fault"]}')
        records = self.q('ReadPorts', api_id=self.car, port_names=PORTS)['ports']
        values = {p['name']: p['value'] for p in records if p['direction'] == 'out'}
        missing = set(PORTS) - values.keys()
        if missing:
            raise RuntimeError(f'Missing course telemetry: {sorted(missing)}')
        if not all(math.isfinite(v) for v in values.values()):
            raise RuntimeError('Non-finite course telemetry')
        return values

    def setup(self, reopen_twin=True):
        self.release()
        # --launch already opens the requested course. Reopening while its
        # initial assets are preparing retires their Twin mount mid-load.
        old = None
        if reopen_twin and not self.args.launch:
            old = self.q('RunRhai', code='twin_authority()')['stdout']
            self.q('OpenTwin', path=str(ROOT))
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            state = self.q('GetReadiness')
            if state['faulted']:
                raise RuntimeError(state['fault'])
            if state['ready'] and not state['world_hold'] and not state['pending_count']:
                current = self.q('RunRhai', code='twin_authority()')['stdout']
                if old is not None and current == old:
                    time.sleep(.1)
                    continue
                models = self.q('CosimStatus', include_values=False)['entities']
                allowed_statuses = ['Running'] if reopen_twin else ['Idle', 'Running']
                if any(e.get('name') == '/World/Roadster'
                       and e.get('status') in allowed_statuses for e in models):
                    break
            time.sleep(.1)
        else:
            raise RuntimeError('Course did not become ready')
        self.car = int(self.q('RunRhai', code='find_path("/World/Roadster")')['stdout'])
        self.q('SetTimeTransport', rate=self.args.rate)
        self.report['transport_rate'] = self.args.rate
        self.q('ObserveAvatar')
        if self.os_input:self.os_input.activate()
        for state in ['Pressed', 'Released']:
            self.pointer(state,640,330)
        self.keys({'ShiftLeft'}, 0.0)
        self.start = self.snapshot()['course_time_s']
        # Course time resets on retry; the native event clock remains global.
        self.input_epoch=float(self.q('RunRhai',code='clock_snapshot().sim_tick')['stdout'])/60.0
        self.report.setdefault('input_lifetimes',[]).append(dict(course_epoch_s=self.start,
            native_epoch_s=self.input_epoch,mount_authority=self.q('RunRhai',code='twin_authority()')['stdout']))

    def fan(self, keys, t, observed, desired):
        if t < self.fan_until:
            keys.add('KeyF')
        elif (observed > .5) != desired and t >= self.fan_retry:
            self.fan_until, self.fan_retry = t + .07, t + .35
            keys.add('KeyF')

    def commands(self, v):
        t = v['course_time_s'] - self.start
        stage = round(v['course_stage'])
        if self.args.autopilot:
            return set(), t, stage
        # The same Modelica guidance feeds the event-driven in-app autopilot.
        # This adapter translates its digital suggestions to native keys only.
        keys = {key for name,key in PILOT_KEYS.items() if v['pilot_'+name]>.5}
        self.fan(keys, t, v['fan_requested'], v['pilot_fan']>.5)
        return keys, t, stage

    def start_autopilot(self, t):
        self.keys(set(), t)
        if self.args.manual:
            self.step(2)
        for state in ['Pressed','Released']:
            self.pointer(state,330,78)
        deadline = time.monotonic()+5
        while time.monotonic()<deadline:
            if self.args.manual:
                self.step(2)
            if self.snapshot()['course_autopilot_active']>.5:
                self.autopilot_started = True
                self.report['autopilot_button'] = True
                return
            time.sleep(.02)
        raise RuntimeError('HUD autopilot button did not enable the course program')

    def check_pause(self, t):
        def tick():
            return int(self.q('RunRhai', code='clock_snapshot().sim_tick')['stdout'])
        self.keys({'ShiftLeft', 'ControlLeft', 'KeyP'}, t)
        time.sleep(.10)
        self.keys({'ShiftLeft'}, t)
        a = tick()
        time.sleep(.25)
        b = tick()
        self.keys({'ShiftLeft', 'ControlLeft', 'KeyP'}, t)
        time.sleep(.10)
        self.keys({'ShiftLeft'}, t)
        deadline = time.monotonic() + 5
        while tick() <= b and time.monotonic() < deadline:
            time.sleep(.03)
        resumed = tick()
        self.report['pause'] = dict(before=a, held=b, resumed=resumed, ok=a == b and resumed > b)
        if not self.report['pause']['ok']:
            raise RuntimeError('Ctrl+P did not pause and resume the native clock')

    def operator_checks(self):
        """Exercise real HUD/keyboard ownership, then reset the active course."""
        def tick():
            return int(self.q('RunRhai', code='clock_snapshot().sim_tick')['stdout'])
        # Pause while the pilot owns controls. Shift would itself take over.
        self.q('StepSimulation', hold=False)
        self.keys({'ControlLeft', 'KeyP'}, self.snapshot()['course_time_s']-self.start)
        time.sleep(.12)
        self.keys(set(), self.snapshot()['course_time_s']-self.start)
        a = tick()
        before = self.snapshot()
        time.sleep(.3)
        b = tick()
        held = self.snapshot()
        fields = ['course_time_s', 'position_x', 'position_y', 'position_z',
                  'gas_mass_kg', 'course_autopilot_active']
        active_pause = a == b and before['course_autopilot_active'] > .5 and all(
            before[name] == held[name] for name in fields)
        self.screenshot('active-pause')
        self.keys({'ControlLeft', 'KeyP'}, self.snapshot()['course_time_s']-self.start)
        time.sleep(.12)
        self.keys(set(), self.snapshot()['course_time_s']-self.start)
        deadline = time.monotonic()+5
        while tick() <= b and time.monotonic() < deadline:
            time.sleep(.03)
        resumed = tick()
        active_pause = active_pause and resumed > b and self.snapshot()['course_autopilot_active'] > .5
        self.q('StepSimulation', hold=True)
        self.report['active_pause'] = dict(ok=active_pause, before=a, held=b,
            resumed=resumed, frozen_fields=fields)
        if not active_pause:
            raise RuntimeError('Active pilot did not preserve state and ownership across Ctrl+P')
        # A real driving key must cancel program ownership immediately.
        self.keys({'KeyW'}, self.snapshot()['course_time_s']-self.start)
        self.step(6)
        takeover = self.snapshot()
        program = self.q('ReadPorts', api_id=self.car, port_names=['program_active'])['ports']
        manual = takeover['course_autopilot_active'] < .5 and any(
            p['name']=='program_active' and p['direction']=='in' and p['value']<.5 for p in program)
        self.keys(set(), self.snapshot()['course_time_s']-self.start)
        self.step(2)
        self.report['manual_takeover'] = dict(ok=manual, key='KeyW', telemetry=takeover,
            program_port=program)
        if not manual:
            raise RuntimeError('W did not relinquish autopilot program ownership')
        # Use the same secondary-action input as a player to create a non-default
        # Modelica service count before retry. The reset must clear it with the
        # mission clock and stage while retaining this mounted Twin authority.
        self.keys({'Tab'}, self.snapshot()['course_time_s']-self.start)
        self.step(2)
        self.keys(set(), self.snapshot()['course_time_s']-self.start)
        self.step(2)
        # Native HUD retry: no pose, inventory, checkpoint or actuator writes.
        old_car = self.car
        old_course = self.snapshot()
        if old_course['course_stage'] < 1 or old_course['course_time_s'] <= 0.5 \
                or old_course['instant_services'] < 1:
            raise RuntimeError('Retry setup did not create non-default mission and service state')
        old_authority = self.q('RunRhai',code='twin_authority()')['stdout']
        old_twin_id = int(self.q('ReadActiveTwinContract')['twin_id'])
        self.keys({'ShiftLeft'}, self.snapshot()['course_time_s']-self.start)
        for state in ['Pressed', 'Released']:
            self.pointer(state,235,78)
        self.q('StepSimulation', hold=True)
        deadline = time.monotonic()+120
        while time.monotonic() < deadline:
            current_authority = self.q('RunRhai',code='twin_authority()')['stdout']
            if current_authority != old_authority:
                raise RuntimeError(
                    f'HUD retry changed Twin mount authority: {old_authority!r} -> '
                    f'{current_authority!r}')
            current_twin_id = int(self.q('ReadActiveTwinContract')['twin_id'])
            if current_twin_id != old_twin_id:
                raise RuntimeError(
                    f'HUD retry changed workspace Twin id: {old_twin_id} -> {current_twin_id}')
            state = self.q('GetReadiness')
            if state['faulted']:
                raise RuntimeError(state['fault'])
            if state['ready'] and not state['pending_count']:
                current = int(self.q('RunRhai', code='find_path("/World/Roadster")')['stdout'])
                models = self.q('CosimStatus', include_values=False)['entities']
                if current >= 0 and any(
                        e.get('name')=='/World/Roadster'
                        and e.get('status') in ['Idle','Running'] for e in models):
                    # Public prim API ids are source identities and may stay stable across reset.
                    # An admitted held model is Idle until its first requested
                    # cycles. Step the reset scene, then inspect its state.
                    self.car = current
                    self.step(2)
                    fresh = self.snapshot()
                    if (fresh['course_stage']==0 and fresh['course_blocks']==0
                            and fresh['instant_services']==0
                            and fresh['course_autopilot_active']<.5
                            and abs(fresh['gas_mass_kg']-250)<.005
                            and fresh['course_time_s']<.1
                            and fresh['course_failure_reason']==0):
                        break
            time.sleep(.03)
        else:
            raise RuntimeError('HUD retry did not reset the active scene runtime')
        # Re-arm telemetry and input bindings without reopening the Twin.
        self.setup(reopen_twin=False)
        self.q('StepSimulation',hold=True)
        self.step(2)
        fresh = self.snapshot()
        reset = (fresh['course_stage']==0 and fresh['course_blocks']==0
                 and fresh['instant_services']==0 and fresh['course_autopilot_active']<.5
                 and abs(fresh['gas_mass_kg']-250)<.005 and fresh['course_time_s']<old_course['course_time_s']
                 and fresh['course_failure_reason']==0)
        self.report['retry_reset'] = dict(ok=reset, api_id_before=old_car, api_id_after=self.car,
            twin_id_before=old_twin_id,twin_id_after=current_twin_id,
            mount_authority_before=old_authority,
            mount_authority_after=current_authority,
            before_retry=old_course,telemetry=fresh)
        if not reset:
            raise RuntimeError('Retry did not reset the mission, air and pilot')
        self.screenshot('retry-reset')
        # Input audit for the completed course starts at the reset scene runtime.
        runtime = self.out.with_suffix('.runtime.log')
        if runtime.exists():
            self.native_offset = runtime.stat().st_size
        self.autopilot_started = False
        self.start_autopilot(0.0)
        self.report['operator_checks'] = True

    def step(self, count):
        before = int(self.q('RunRhai', code='clock_snapshot().sim_tick')['stdout'])
        self.q('StepSimulation', steps=count)
        deadline = time.monotonic()+15
        while time.monotonic()<deadline:
            readiness = self.q('GetReadiness')
            if readiness['faulted']:
                raise RuntimeError(f'Runtime fault: {readiness["fault"]}')
            tick = int(self.q('RunRhai', code='clock_snapshot().sim_tick')['stdout'])
            if tick>=before+count and not readiness['world_hold']:
                return
            time.sleep(.005)
        raise RuntimeError('Requested native fixed cycles did not complete')

    def run(self):
        self.setup()
        deadline = time.monotonic() + self.args.wall_timeout
        last = sample_at = progress_at = -1.0
        previous_stage = -1
        paused = False
        while time.monotonic() < deadline:
            v = self.snapshot()
            keys, t, stage = self.commands(v)
            if t > self.args.sim_timeout:
                raise RuntimeError('Course simulation-time limit exceeded')
            if last >= 0:
                self.report['maximum_observation_gap_s'] = max(
                    self.report.get('maximum_observation_gap_s', 0), t - last)
            self.keys(keys, t)
            self.check_native_input_edges()
            if stage in [2,3] and -132<v['position_z']<-94:
                code='let peak=0.0; for cube in 0..3 {for name in ["Roadster"] {let c=contact_debug(find_path("/World/"+name),find_path("/World/JumpBlock"+cube.to_string()));peak=max(peak,c.total_normal_impulse);}} peak'
                impulse=float(self.q('RunRhai',code=code)['stdout'])
                self.report['maximum_cube_contact_impulse_ns']=max(impulse,self.report.get('maximum_cube_contact_impulse_ns',0))
            action=round(v['course_step'])
            if action!=self.previous_action:
                self.report.setdefault('actions',[]).append(dict(action=action,stage=stage,time_s=t))
                if stage==6:
                    self.screenshot('action-'+str(action))
                    cameras=self.q('SceneCameraAudit')['candidates']
                    active=[c for c in cameras if c['camera_active'] and c['render_target']=='window']
                    if len(active)!=1 or active[0]['usd_path']!='/World/Avatar':
                        raise RuntimeError('Avatar camera was lost during the aerial maneuver')
                self.previous_action=action
            if stage==2 and v['course_blocks']==1 and not self.report.get('cube_flight_capture'):
                self.screenshot('cube-flight');self.report['cube_flight_capture']=True
            if stage==6 and v['position_y']<2 and v['flight_control_weight']>.8:
                self.last_airborne=v.copy()
            if stage==6 and v['position_y']<1 and v['flight_control_weight']<.2 and 'touchdown' not in self.report:
                self.report['touchdown']=dict(last_airborne=self.last_airborne,first_grounded=v.copy())
            if stage != previous_stage:
                self.report['stages'].append(dict(stage=stage, time_s=t,
                    position=[v['position_x'], v['position_y'], v['position_z']]))
                print(f'stage {stage} at {t:.2f}s: z={v["position_z"]:.1f}, y={v["position_y"]:.1f}', flush=True)
                self.screenshot(f'stage-{stage}')
                previous_stage = stage
            if t >= sample_at:
                self.report['samples'].append(dict(time_s=t, keys=sorted(keys), **v))
                sample_at = t + .1
                self.out.write_text(json.dumps(self.report, indent=2) + '\n')
            if stage == 8:
                raise RuntimeError('The production course tree rejected the run')
            if stage == 7:
                self.keys(set() if self.args.autopilot else {'ShiftLeft'}, t)
                native = self.q('QueryPhysicsState', id=self.car)
                contacts = {}
                for corner in ['FL', 'FR', 'RL', 'RR']:
                    code = f'import "twin://tesla-roadster-runner/tools/wheel_state" as wheels; if wheels::contact(find_path("/World/Roadster/Wheel_{corner}")) {{1}} else {{0}}'
                    contacts[corner] = int(self.q('RunRhai', code=code)['stdout'])
                self.report.update(final=v, native=native, landing_contacts=contacts,
                    hud=self.q('ReadExposures', surface='vessel-hud'))
                checks = dict(no_cube_contact=self.report.get('maximum_cube_contact_impulse_ns',float('inf'))<1.0, course_complete=stage == 7, blocks=v['course_blocks'] == 3,
                    two_waypoint_refills=v['instant_services'] == 2,
                    refill_mass_added=v['instant_air_added_kg'] > 50,
                    finite_air=v['unlimited_air_active'] < .5,
                    air_turn=v['course_air_rotation_degrees'] > 170,
                    roll_recovery=v['course_air_roll_degrees']>150,
                    heading_away=v['course_forward_z']>.94,
                    on_road=abs(v['position_x'])<6 and -295<v['position_z']<-230,
                    cushioned_landing=v['course_landing_impact_speed']<5.0 and abs(self.report['touchdown']['last_airborne']['velocity_y'])<5.0,
                    continuous_run=min(row['speed_mps'] for row in self.report['samples'] if 1<=row['course_stage']<=3)>25,
                    upright=v['up_alignment'] > .95, stopped=v['speed_mps'] < .2,
                    four_wheels=all(n > 0 for n in contacts.values()),
                    native_mass=abs(native['mass_kg'] - v['chassis_mass_kg']) < .05,
                    pause=self.report.get('pause', {}).get('ok', False),
                    control_mode=(self.autopilot_started and v['course_autopilot_active']>.5)
                        if self.args.autopilot else v['course_autopilot_active']<.5)
                if self.args.operator_checks:
                    checks.update(active_pause=self.report.get('active_pause',{}).get('ok',False),
                        manual_takeover=self.report.get('manual_takeover',{}).get('ok',False),
                        retry_reset=self.report.get('retry_reset',{}).get('ok',False))
                # Presentation is asynchronous to fixed physics. Wait for the
                # completed HUD before capturing it or clicking its stop button.
                hud_deadline = time.monotonic()+5
                while time.monotonic()<hud_deadline:
                    hud = self.q('ReadExposures',surface='vessel-hud')
                    properties = hud['surfaces']['vessel-hud']['properties']
                    if properties.get('rr_course_title')=='COURSE COMPLETE':
                        break
                    time.sleep(.05)
                checks['completion_hud'] = properties.get('rr_course_title')=='COURSE COMPLETE'
                self.report['hud'] = hud
                self.screenshot('complete')
                if self.args.operator_checks:
                    for state in ['Pressed','Released']:
                        self.pointer(state,360,78)
                    self.step(2)
                    stopped = self.snapshot()
                    checks['completed_pilot_stop'] = stopped['course_autopilot_active']<.5 and stopped['course_stage']==7
                    self.report['completed_pilot_stop'] = stopped
                self.report['checks'] = checks
                self.report['ok'] = all(checks.values())
                self.report['failures'] = [name for name, ok in checks.items() if not ok]
                return
            if not paused and stage == 0 and t > .5:
                self.check_pause(t)
                paused = True
                if self.args.manual:
                    self.q('StepSimulation', hold=True)
                    self.report['execution_mode'] = 'Native fixed cycles'
                if self.args.autopilot:
                    self.start_autopilot(t)
            if self.args.operator_checks and stage==2 and not self.report.get('operator_checks'):
                # Retry after a real waypoint: the reset must clear existing
                # service/checkpoint history and a meaningfully elapsed clock.
                self.operator_checks()
                last = sample_at = progress_at = -1.0
                previous_stage = -1
                self.previous_action = None
                self.report['samples'] = []
                self.last_airborne = None
                continue
            if t >= progress_at:
                print(f'{t:.1f}s stage={stage} z={v["position_z"]:.1f} speed={v["speed_mps"]:.1f} air={v["gas_mass_kg"]:.1f}', flush=True)
                progress_at = t + 2
            last = t
            if self.args.manual and paused:
                self.step(1 if stage==6 or (stage in [2,3] and -132<v['position_z']<-94) else 2)
            else:
                time.sleep(.02)
        raise RuntimeError('Course wall-time limit exceeded')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--port', type=int, default=4198)
    ap.add_argument('--launch', action='store_true')
    ap.add_argument('--input-backend',choices=['native','x11'],default='native',
                    help='Use native injection or real X11 OS delivery to the owned window')
    ap.add_argument('--keep-open', action='store_true')
    ap.add_argument('--autopilot', action='store_true',
                    help='Start the shared in-app course pilot through its HUD button')
    ap.add_argument('--operator-checks',action='store_true',
                    help='Check active pause, W takeover and HUD retry, then complete the course')
    ap.add_argument('--manual', action='store_true',
                    help='Admit exact native fixed cycles between keyboard observations')
    ap.add_argument('--binary', default=str(ROOT / '.scratch/control-target/debug/luncosim'))
    ap.add_argument('--output', default='results/keyboard-course.json')
    ap.add_argument('--wall-timeout', type=float, default=900)
    ap.add_argument('--sim-timeout', type=float, default=180)
    ap.add_argument('--rate', type=float, default=.25,
                    help='Wall-clock playback rate; physical timestep and course are unchanged')
    args = ap.parse_args()
    if args.operator_checks and not (args.autopilot and args.manual and args.launch):
        ap.error('--operator-checks requires --autopilot --manual --launch for an owned repeatable session')
    if args.input_backend=='x11' and not args.launch:
        ap.error('OS delivery requires --launch so the destination PID is owned')
    pilot = Pilot(args)
    pilot.report.update(control_mode='autopilot' if args.autopilot else 'keyboard',
                        sequence='scenarios/skill_course.rhai', guidance='models/CoursePilot.mo')
    sources = ['models/BatteryStudy.mo','models/RoadsterPowertrain.mo','tests/python/x11_window_input.py','models/CoursePilot.mo','models/SkillCourse.mo','models/RoadsterVehicle.mo',
               'scenarios/skill_course.rhai','scenes/roadster_skill_course.usda',
               'vehicles/roadster.usda','config/input-bindings.json',
               'scripting/policy/roadster_camera.rhai','scripting/policy/roadster_ui.rhai',
               'tests/python/check_keyboard_course.py']
    sources=sorted(set(sources)|{str(p.relative_to(ROOT)) for p in (ROOT/'models').glob('*.mo')})
    pilot.report['source_sha256'] = {name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
                                     for name in sources}
    process = log = None
    try:
        if args.launch:
            with socket.socket() as probe:
                if probe.connect_ex(('127.0.0.1', args.port)) == 0:
                    raise RuntimeError(f'Port {args.port} is already in use; choose another port')
            binary = Path(args.binary).resolve()
            pilot.report['binary_sha256'] = hashlib.file_digest(binary.open('rb'), 'sha256').hexdigest()
            log = pilot.out.with_suffix('.runtime.log').open('w')
            env = os.environ.copy()
            env.update(LUNCOSIM_BIN=str(binary), WINIT_UNIX_BACKEND='x11',
                       LUNCOSIM_ISOLATED_RUN='1')
            env.pop('LUNCOSIM_EPHEMERAL_SETTINGS', None)
            env.pop('WAYLAND_DISPLAY', None)
            env.pop('WAYLAND_SOCKET', None)
            command = [str(ROOT / 'scripts/start.sh'), 'roadster_skill_course', '--api', str(args.port)]
            process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 120
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(f'Owned runtime exited: {process.returncode}')
                try:
                    pilot.q('GetReadiness')
                    break
                except (urllib.error.URLError, TimeoutError):
                    time.sleep(.2)
            else:
                raise RuntimeError('Owned runtime API did not start')
        if args.input_backend=='x11':
            from x11_window_input import X11WindowInput
            pilot.os_input=X11WindowInput(process.pid)
            pilot.report['input_path']='X11 XTEST -> owned window -> winit -> native intents'
            pilot.report['os_window']=dict(pid=process.pid,window_id=pilot.os_input.window.id,
                display=pilot.os_input.display.get_display_name())
        pilot.run()
    except Exception as exc:
        pilot.report['failures'].append(str(exc))
        pilot.report['traceback'] = traceback.format_exc()
        try:
            pilot.screenshot('failed')
        except Exception:
            pass
    finally:
        pilot.release()
        if pilot.os_input:
            pilot.report['os_events']=pilot.os_input.events
            pilot.os_input.close()
        if process and process.poll() is None and not args.keep_open:
            try:
                pilot.q('Exit')
                process.wait(timeout=15)
            except Exception:
                process.terminate()
                process.wait(timeout=15)
        if log:
            log.close()
        pilot.out.write_text(json.dumps(pilot.report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in pilot.report.items()
                      if k in ['ok', 'checks', 'failures', 'stages']}, indent=2))
    return 0 if pilot.report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
