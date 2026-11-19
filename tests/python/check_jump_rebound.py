#!/usr/bin/env python3
"""Run the authored repeated/held lift regression in an owned interactive session.

This reloads the Twin, steps its real simulation, saves evidence and restores
the interactive scene. Start it with scripts/start.sh and a dedicated API port.
"""
import argparse
import json
from pathlib import Path
import time
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=4198)
    parser.add_argument('--held', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]

    def q(command, params=None):
        request = urllib.request.Request(
            f'http://127.0.0.1:{args.port}/api/commands',
            data=json.dumps(dict(type='ExecuteCommand', command=command,
                                 params=params or {})).encode(),
            headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(request, timeout=45) as response:
            result = json.load(response)
        if 'error' in result:
            raise RuntimeError(result['error'])
        return result['data']

    def rh(code):
        return q('RunRhai', {'code': code})['stdout']

    previous = q('ReadActiveTwinContract').get('twin_id')
    q('OpenTwin', {'path': str(root)})
    deadline = time.monotonic() + 120
    while True:
        ready = q('GetReadiness')
        if ready['faulted']:
            raise RuntimeError(ready['fault'])
        current = q('ReadActiveTwinContract').get('twin_id')
        if (ready['ready'] and not ready['world_hold'] and not ready['pending_count']
                and current is not None and current != previous
                and rh('is_controlled(find_path("/World/Roadster"))') == 'true'):
            break
        if time.monotonic() > deadline:
            raise RuntimeError('Fresh interactive Twin did not become ready')
        time.sleep(.05)

    q('StepSimulation', {'hold': True})
    try:
        target = int(rh('find_path("/World")'))
        asset = f'twin://{rh("twin_source_identity()")}/scenarios/tests/jump_rebound.rhai'
        q('RunScenarioAsset', {'target': target, 'source_asset': asset,
                              'params': {'held': args.held}})
        for _ in range(40):
            target_tick = int(rh('clock_snapshot().sim_tick')) + 60
            q('StepSimulation', {'steps': 60})
            deadline = time.monotonic() + 45
            while int(rh('clock_snapshot().sim_tick')) < target_tick:
                if time.monotonic() > deadline:
                    raise RuntimeError('Simulation step stalled')
                time.sleep(.02)
            report = q('ScriptInspect', {'target': target})
            if not report['status']['ok']:
                raise RuntimeError(report['status'])
            if report.get('state', {}).get('done'):
                break
        else:
            raise RuntimeError('Jump regression did not finish')
        state = report['state']
        name = 'jump-rebound-' + ('held' if args.held else 'repeated')
        (root / 'results').mkdir(exist_ok=True)
        (root / 'results' / f'{name}.json').write_text(json.dumps(report, indent=2) + '\n')
        screenshot = root / 'results' / f'{name}.png'
        previous_mtime = screenshot.stat().st_mtime_ns if screenshot.exists() else None
        q('CaptureScreenshot', {'save_to_file': True, 'path': str(screenshot)})
        deadline = time.monotonic() + 15
        while not screenshot.exists() or screenshot.stat().st_mtime_ns == previous_mtime:
            if time.monotonic() > deadline:
                raise RuntimeError('Screenshot was not written')
            time.sleep(.05)
        print(json.dumps({k: state[k] for k in
                          ['first_apex', 'later_apex', 'maximum_compression', 'failures']}, indent=2))
        return int(any(state['failures']))
    finally:
        q('StepSimulation', {'hold': False})
        q('OpenTwin', {'path': str(root)})


if __name__ == '__main__':
    raise SystemExit(main())
