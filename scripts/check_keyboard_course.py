#!/usr/bin/env python3
"""Drive the unmodified main course through native keyboard events.

Example:
  python3 scripts/check_keyboard_course.py --launch --binary /path/to/luncosim

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

ROOT = Path(__file__).resolve().parents[1]
KEYS = {'KeyW', 'KeyA', 'KeyS', 'KeyD', 'Space', 'ShiftLeft', 'KeyK',
        'KeyF', 'KeyR', 'KeyC', 'KeyQ', 'KeyE', 'KeyJ', 'KeyL', 'Tab',
        'ControlLeft', 'ControlRight', 'KeyP', 'KeyV'}
PORTS = ['course_time_s', 'course_stage', 'course_blocks', 'course_air_rotation_degrees',
         'position_x', 'position_y', 'position_z', 'velocity_y', 'speed_mps', 'yaw',
         'pitch_rate_deg_s', 'roll_rate_deg_s', 'up_alignment', 'flight_control_weight',
         'fan_requested', 'fan_seal', 'downforce', 'gas_mass_kg', 'tank_temperature_k',
         'tank_pressure_pa', 'instant_services', 'instant_air_added_kg',
         'vehicle_mass_kg', 'chassis_mass_kg', 'unlimited_air_active', 'heading_fl',
         'quat_w', 'quat_x', 'quat_y', 'quat_z', 'yaw_rate_deg_s',
         'full_lift_force_n', 'lift_net_acceleration', 'velocity_z',
         'course_step', 'course_forward_speed', 'course_forward_z', 'course_air_yaw_degrees', 'course_air_roll_degrees', 'course_backward_distance_m',
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
        if not desired <= KEYS:
            raise ValueError(desired - KEYS)
        # Release the chord's letter before its modifier, as a player can.
        releases = sorted(self.held - desired, key=lambda k: (k.startswith('Control'), k))
        presses = sorted(desired - self.held, key=lambda k: (not k.startswith('Control'), k))
        for key, state in ([(k, 'Released') for k in releases] +
                           [(k, 'Pressed') for k in presses]):
            self.q('InjectWindowInput', event={'Key': dict(
                key=key, state=state, text=None, repeat=False)})
            self.report['keys'].append(dict(time_s=t, key=key, state=state))
            if state == 'Pressed':
                self.held.add(key)
            else:
                self.held.remove(key)

    def release(self):
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
            t = float(match[3])-self.start
            if t < 0:
                continue
            transitions = [e for e in self.report['keys'] if e['key']==key]
            nearby = any(abs(e['time_s']-t)<.075 for e in transitions)
            previous = [e for e in transitions if e['time_s']<=t+.025]
            expected = previous[-1]['state'].lower() if previous else 'released'
            if not nearby and match[1] != expected:
                detail = dict(time_s=t,key=key,native_state=match[1],expected=expected)
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

    def setup(self):
        self.release()
        # --launch already opens the requested course. Reopening while its
        # initial assets are preparing retires their Twin mount mid-load.
        old = None
        if not self.args.launch:
            old = self.q('RunRhai', code='twin_name()')['stdout']
            self.q('OpenTwin', path=str(ROOT))
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            state = self.q('GetReadiness')
            if state['faulted']:
                raise RuntimeError(state['fault'])
            if state['ready'] and not state['world_hold'] and not state['pending_count']:
                current = self.q('RunRhai', code='twin_name()')['stdout']
                if old is not None and current == old:
                    time.sleep(.1)
                    continue
                models = self.q('CosimStatus', include_values=False)['entities']
                if any(e.get('name') == '/World/Roadster' and e.get('status') == 'Running'
                       for e in models):
                    break
            time.sleep(.1)
        else:
            raise RuntimeError('Fresh main course did not become ready')
        self.car = int(self.q('RunRhai', code='find_path("/World/Roadster")')['stdout'])
        self.q('SetTimeTransport', rate=self.args.rate)
        self.report['transport_rate'] = self.args.rate
        self.q('ObserveAvatar')
        for state in ['Pressed', 'Released']:
            self.q('InjectWindowInput', event={'PointerButton': dict(
                button='Primary', state=state, x=640, y=330)})
        self.keys({'ShiftLeft'}, 0.0)
        self.start = self.snapshot()['course_time_s']

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
            self.q('InjectWindowInput', event={'PointerButton': dict(
                button='Primary',state=state,x=330,y=78)})
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
                raise RuntimeError('The unchanged course policy rejected the run')
            if stage == 7:
                self.keys({'ShiftLeft'}, t)
                native = self.q('QueryPhysicsState', id=self.car)
                contacts = {}
                for corner in ['FL', 'FR', 'RL', 'RR']:
                    code = f'contact_debug(find_path("/World/Roadster/Wheel_{corner}")).touching_pair_count'
                    contacts[corner] = int(self.q('RunRhai', code=code)['stdout'])
                self.report.update(final=v, native=native, landing_contacts=contacts,
                    hud=self.q('ReadExposures', surface='vessel-hud'))
                checks = dict(course_complete=stage == 7, blocks=v['course_blocks'] == 3,
                    two_waypoint_refills=v['instant_services'] == 2,
                    refill_mass_added=v['instant_air_added_kg'] > 50,
                    finite_air=v['unlimited_air_active'] < .5,
                    air_turn=v['course_air_rotation_degrees'] > 170,
                    yaw_turn=v['course_air_yaw_degrees']>150,
                    roll_recovery=v['course_air_roll_degrees']>150,
                    backward_flight=v['course_backward_distance_m']>1.0,
                    upright=v['up_alignment'] > .95, stopped=v['speed_mps'] < 2,
                    four_wheels=all(n > 0 for n in contacts.values()),
                    native_mass=abs(native['mass_kg'] - v['chassis_mass_kg']) < .05,
                    pause=self.report.get('pause', {}).get('ok', False),
                    control_mode=(self.autopilot_started and v['course_autopilot_active']>.5)
                        if self.args.autopilot else v['course_autopilot_active']<.5)
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
            if t >= progress_at:
                print(f'{t:.1f}s stage={stage} z={v["position_z"]:.1f} speed={v["speed_mps"]:.1f} air={v["gas_mass_kg"]:.1f}', flush=True)
                progress_at = t + 2
            last = t
            if self.args.manual and paused:
                self.step(1 if stage==6 else 2)
            else:
                time.sleep(.02)
        raise RuntimeError('Course wall-time limit exceeded')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--port', type=int, default=4198)
    ap.add_argument('--launch', action='store_true')
    ap.add_argument('--keep-open', action='store_true')
    ap.add_argument('--autopilot', action='store_true',
                    help='Start the shared in-app course pilot through its HUD button')
    ap.add_argument('--manual', action='store_true',
                    help='Admit exact native fixed cycles between keyboard observations')
    ap.add_argument('--binary', default=str(ROOT / '.scratch/luncosim'))
    ap.add_argument('--output', default='results/keyboard-course.json')
    ap.add_argument('--wall-timeout', type=float, default=900)
    ap.add_argument('--sim-timeout', type=float, default=180)
    ap.add_argument('--rate', type=float, default=.25,
                    help='Wall-clock playback rate; physical timestep and course are unchanged')
    args = ap.parse_args()
    pilot = Pilot(args)
    pilot.report.update(control_mode='autopilot' if args.autopilot else 'keyboard',
                        sequence='scenarios/skill_course.rhai', guidance='models/CoursePilot.mo')
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
