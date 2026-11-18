#!/usr/bin/env python3
"""Exercise the actual HUD switch and observe Modelica's air/energy boundary."""
import json
import struct
import time

from check_effects import fresh, key, ports, q, root


def wait(seconds):
    start = int(q('RunRhai', {'code': 'clock_snapshot().sim_tick'})['stdout'])
    deadline = time.monotonic() + 60
    while int(q('RunRhai', {'code': 'clock_snapshot().sim_tick'})['stdout']) < start + round(seconds * 60):
        state = q('GetReadiness')
        if state['faulted']:
            raise RuntimeError(state['fault'])
        if time.monotonic() > deadline:
            raise RuntimeError('Simulation clock stalled')
        time.sleep(.02)


def sample(car):
    names = ['unlimited_air_active', 'gas_mass_kg', 'tank_temperature_k',
             'tank_wall_temperature_k', 'tank_pressure_pa', 'ideal_supply_air_kg',
             'ideal_supply_energy_j', 'vehicle_mass_kg', 'speed_mps', 'instant_services']
    return {p['name']: p['value'] for p in ports(car, names) if p['direction'] == 'out'}


def click_toggle():
    width, height = struct.unpack('>II', q('CaptureScreenshot')[16:24])
    x, y = width - 143, height - 122
    q('InjectWindowInput', {'event': {'PointerMove': dict(x=x, y=y)}})
    time.sleep(.08)
    for state in ['Pressed', 'Released']:
        q('InjectWindowInput', {'event': {'PointerButton': dict(button='Primary', state=state, x=x, y=y)}})
        time.sleep(.08)


def main():
    car = fresh()
    for k in ['W', 'A', 'S', 'D', 'Space', 'K', 'F', 'Tab', 'ShiftLeft']:
        key(k, 'Released')
    q('ObserveAvatar', {})
    q('SetPorts', dict(target=car, producer_id=4198001,
                      writes=[['refill_target_temperature_k', 303.15], ['fan', 0.0]]))
    time.sleep(.3)
    click_toggle()
    wait(.15)
    before = sample(car)
    try:
        key('K', 'Pressed')
        key('Space', 'Pressed')
        wait(1.2)
        held = sample(car)
        (root / 'results/unlimited-air.png').write_bytes(q('CaptureScreenshot'))
    finally:
        key('Space', 'Released')
        key('K', 'Released')
    click_toggle()
    wait(.15)
    finite_before = sample(car)
    try:
        key('Space', 'Pressed')
        wait(.25)
        finite_after = sample(car)
    finally:
        key('Space', 'Released')
    checks = dict(
        hud_enabled=before['unlimited_air_active'] > .5,
        conditioned_refill=abs(before['tank_temperature_k'] - 303.15) < .01,
        full_inventory=abs(before['gas_mass_kg'] - 250) < .001,
        mass_constant=abs(held['gas_mass_kg'] - before['gas_mass_kg']) < .001,
        temperature_constant=abs(held['tank_temperature_k'] - before['tank_temperature_k']) < .001,
        pressure_constant=abs(held['tank_pressure_pa'] - before['tank_pressure_pa']) < 1,
        source_recorded=held['ideal_supply_air_kg'] - before['ideal_supply_air_kg'] > 50,
        energy_recorded=held['ideal_supply_energy_j'] > before['ideal_supply_energy_j'],
        hud_disabled=finite_before['unlimited_air_active'] < .5,
        finite_consumes=finite_after['gas_mass_kg'] < finite_before['gas_mass_kg'] - 5,
        finite_cools=finite_after['tank_temperature_k'] < finite_before['tank_temperature_k'] - 1,
        healthy=q('GetReadiness')['ready'],
    )
    report = dict(ok=all(checks.values()), checks=checks, before=before, held=held,
                  finite_before=finite_before, finite_after=finite_after)
    (root / 'results/unlimited-air.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(checks, indent=2))
    fresh()
    q('ObserveAvatar', {})
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
