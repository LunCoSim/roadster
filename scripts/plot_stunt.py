#!/usr/bin/env python3
"""Plot recorded native course observations; no simulation or control writes."""
import argparse,json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ap=argparse.ArgumentParser(description=__doc__)
ap.add_argument('result',type=Path)
ap.add_argument('--output',type=Path,default=Path('results/yaw-stunt.png'))
args=ap.parse_args()
r=json.loads(args.result.read_text())
rows=[s for s in r['samples'] if s['stage']>=6]
if not rows:raise RuntimeError('No flight observations')
t0=rows[0]['time_s'];t=[s['time_s']-t0 for s in rows];v=[s['telemetry'] for s in rows]
def series(name):return [s[name] for s in v]
fig,axes=plt.subplots(4,1,figsize=(10,10),sharex=True,layout='constrained')
fig.suptitle('Roadster study: native flip → return-road landing',fontsize=16)
axes[0].plot(t,series('position_y'),label='Chassis height',color='#2156a5');axes[0].set_ylabel('Height (m)')
right=axes[0].twinx();right.plot(t,series('course_forward_speed'),label='Signed body-forward speed',color='#1a8464');right.set_ylabel('Forward speed (m/s)');right.axhline(0,color='gray',lw=.7)
axes[0].legend(loc='upper right');right.legend(loc='lower left')
for name,label,color in [('roll_rate_deg_s','Roll','#2156a5'),('yaw_rate_deg_s','Yaw','#d06d12'),('pitch_rate_deg_s','Pitch','#888888')]:
    axes[1].plot(t,series(name),label=label,color=color)
axes[1].set_ylabel('Body rate (deg/s)');axes[1].legend(loc='upper right',ncol=3)
axes[2].plot(t,series('gas_mass_kg'),label='Finite air inventory',color='#2156a5');axes[2].set_ylabel('Air (kg)')
right=axes[2].twinx();right.plot(t,series('tank_temperature_k'),label='Gas temperature',color='#d06d12');right.axhline(200,color='#b32c2c',ls='--',label='Study discharge guard');right.set_ylabel('Temperature (K)');axes[2].legend(loc='upper left');right.legend(loc='upper right')
axes[3].plot(t,series('course_air_roll_degrees'),label='Roll path',color='#2156a5');axes[3].plot(t,series('course_air_yaw_degrees'),label='Yaw path',color='#d06d12');axes[3].set_ylabel('Integrated rate (deg)')
right=axes[3].twinx();right.plot(t,series('position_x'),label='Lateral position',color='#1a8464');right.set_ylabel('Lateral position (m)');axes[3].legend(loc='upper left');right.legend(loc='lower right')
labels={9:'Roll upright',11:'Yaw reversal',13:'Yaw final',12:'Cushion / land',10:'Complete'}
previous=None
for x,s in zip(t,v):
    action=round(s['course_step'])
    if action!=previous:
        for ax in axes:ax.axvline(x,color='#555555',lw=.6,alpha=.6)
        if action!=10:axes[0].text(x+.03,.95,labels.get(action,str(action)),transform=axes[0].get_xaxis_transform(),va='top',fontsize=9)
        previous=action
for ax in axes:ax.grid(alpha=.2)
axes[-1].set_xlabel('Time since first flight observation (s)')
args.output.parent.mkdir(parents=True,exist_ok=True)
fig.savefig(args.output,dpi=160)
print(args.output)
