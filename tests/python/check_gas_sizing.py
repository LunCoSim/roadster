#!/usr/bin/env python3
"""Evaluate the authored Modelica EOS in LunCoSim and compare CoolProp 8.0.0.

Optional verification dependency: pip install CoolProp==8.0.0.
The Twin and runtime equations do not depend on Python/CoolProp.
"""
import argparse
import json
from pathlib import Path
import time
import urllib.error
import urllib.request
import CoolProp
import CoolProp.CoolProp as CP


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port',type=int,default=4198)
    parser.add_argument('--cold',action='store_true',help='Check the extended single-phase study range down to 143.15 K')
    args=parser.parse_args()
    root=Path(__file__).resolve().parents[2]
    def q(command,params=None):
        req=urllib.request.Request(f'http://127.0.0.1:{args.port}/api/commands',
            data=json.dumps(dict(type='ExecuteCommand',command=command,params=params or {})).encode(),
            headers={'Content-Type':'application/json'})
        try:
            response=json.load(urllib.request.urlopen(req,timeout=30))
        except urllib.error.HTTPError as error:
            raise RuntimeError(error.read().decode()) from error
        if 'error' in response: raise RuntimeError(response['error'])
        return response['data']
    # A fresh immutable source snapshot avoids an old editor compile or run.
    source=(root/'models/CompressedAir.mo').read_text().replace('package CompressedAir','package AirValidation').replace('end CompressedAir;','end AirValidation;')
    source=source.replace('    output Real density(unit="kg/m3");\n    output Real pressure(unit="Pa");',
        '    State realtime(density=density,temperature=temperature);\n    output Real statePressure = realtime.pressure;\n    output Real stateDpdT = realtime.dpdT;\n    output Real stateCv = realtime.cv;\n    output Real stateInternalEnergy = realtime.specific_internal_energy;\n    output Real density(unit="kg/m3");\n    output Real pressure(unit="Pa");')
    doc=q('CreateNewScratchModel',dict(source=source,name='Roadster air EOS verification'))
    doc_id=doc['doc_id']
    deadline=time.monotonic()+30
    while time.monotonic()<deadline:
        status=q('CompileStatus',dict(doc_id=doc_id))
        if status.get('ast_parsed'): break
        time.sleep(.1)
    else:
        raise RuntimeError(status)
    checks=[]
    temperatures=[143.15,173.15,200.0,293.15] if args.cold else [253.15,293.15,333.15]
    volumes=[.6,1.2,2.2] if args.cold else [.5,.6,.8]
    for temperature in temperatures:
        for volume in volumes:
            density=250/volume
            pressure=CP.PropsSI('P','Dmass',density,'T',temperature,'Air')
            if pressure>70e6: continue
            overrides=[dict(name=k,value=str(v)) for k,v in
                [('availableMass',250),('temperature',temperature),('volume',volume),('designPressure',pressure)]]
            run=q('RunExperiment',dict(doc_id=doc_id,**{'class':'AirValidation.StorageSizing'},
                overrides=overrides,t_start=0,t_end=.01,n_intervals=1,label=f'{temperature} K / {volume} m3'))
            run_id=run['experiment_id']
            deadline=time.monotonic()+60
            while time.monotonic()<deadline:
                status=q('RunStatus',dict(experiment_id=run_id))
                if status['state'] in ['done','failed','cancelled']: break
                time.sleep(.1)
            if status['state']!='done': raise RuntimeError(status)
            result=q('GetExperimentResult',dict(experiment_id=run_id,
                variables=['pressure','requiredVolume','dpdT','cv','compressibility','idealPressure','statePressure','stateDpdT','stateCv','stateInternalEnergy'],max_points=2))
            series={name:values[-1] for name,values in result['series'].items()}
            expected=dict(pressure=pressure,requiredVolume=volume,
                dpdT=CP.PropsSI('d(P)/d(T)|Dmass','Dmass',density,'T',temperature,'Air'),
                cv=CP.PropsSI('Cvmass','Dmass',density,'T',temperature,'Air'))
            expected.update(statePressure=pressure,stateDpdT=expected['dpdT'],stateCv=expected['cv'],stateInternalEnergy=CP.PropsSI('Umass','Dmass',density,'T',temperature,'Air')+531917.3305791204)
            errors={k:abs(series[k]-v)/abs(v) for k,v in expected.items()}
            check=dict(temperature_k=temperature,volume_m3=volume,mass_kg=250,
                experiment_id=run_id,modelica=series,reference=expected,relative_errors=errors,
                ok=max(errors.values())<1e-8)
            checks.append(check)
            print(json.dumps({k:check[k] for k in ['temperature_k','volume_m3','ok']}),flush=True)
    sweep=[]
    for fluid in ['Air','Nitrogen']:
        for bar in [200,300,350,450,500,600,689.475729,700]:
            density=CP.PropsSI('Dmass','T',293.15,'P',bar*1e5,fluid)
            sweep.append(dict(fluid=fluid,temperature_k=293.15,pressure_bar_abs=bar,
                density_kg_m3=density,volume_for_250kg_litre=250/density*1000))
    report=dict(ok=all(c['ok'] for c in checks),coolprop_version=CoolProp.__version__,
        checks=checks,pressure_sweep=sweep,internal_energy_reference_offset_j_kg=531917.3305791204)
    output=root/'results'/('gas-cold-reference.json' if args.cold else 'gas-sizing.json')
    output.write_text(json.dumps(report,indent=2)+'\n')
    return 0 if report['ok'] else 1


if __name__=='__main__':
    raise SystemExit(main())
