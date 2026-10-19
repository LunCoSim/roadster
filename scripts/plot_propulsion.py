#!/usr/bin/env python3
"""Plot measured production evidence; optional matplotlib, no replacement physics."""
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle,Circle,Polygon
from study_geometry import MOUNTS,thruster_stations

ROOT=Path(__file__).resolve().parents[1]
def load(name):return json.loads((ROOT/'results'/name).read_text())
forces={b:load('force_'+b+'.json') for b in ['rear','lift','side']}
rocket=load('motor-after.json');performance=load('motor-performance.json');boost=load('launch-telemetry.json')
colors=dict(rear='#d65a24',lift='#16769c',side='#687c2e')
plt.rcParams.update({'font.size':10,'axes.spines.top':False,'axes.spines.right':False,'figure.dpi':140})
fig,axs=plt.subplots(2,2,figsize=(12,8),constrained_layout=True)
ax=axs[0,0]
for label,v,color in [('Rocket wheels, 1950 kg',rocket,'#607782'),('Performance wheels, 1700 kg',performance,'#237966'),('Rocket wheels + rear boost',boost,'#d65a24')]:
 s=v['samples'];ax.plot([r['time_s'] for r in s],[r['speed_m_s']/0.44704 for r in s],label=label,color=color,lw=2)
ax.axhline(60,color='#333333',ls='--',lw=.8);ax.axvline(.59,color='#777777',ls=':',lw=1)
ax.set(xlim=(0,2.2),ylim=(0,115),xlabel='Time after command (s)',ylabel='Measured speed (mph)',title='Standing start: no rollout subtraction');ax.legend(fontsize=8,loc='lower right')
for bank,v in forces.items():
 s=v['samples'];t=[r['time_s'] for r in s];color=colors[bank]
 axs[0,1].plot(t,[r['force_n']/1000 for r in s],label=bank.capitalize(),color=color,lw=2)
 axs[1,0].plot(t,[r['gas_kg'] for r in s],label=bank.capitalize(),color=color,lw=2)
 axs[1,1].plot(t,[r['temperature_k'] for r in s],label=bank.capitalize(),color=color,lw=2)
axs[0,1].set(xlabel='Time after command (s)',ylabel='Delivered body-axis force (kN)',title='Separate full-command bank runs');axs[0,1].legend()
axs[1,0].set(xlabel='Time after command (s)',ylabel='Total stored gas (kg)',title='Changing mass: 250 kg initial inventory')
axs[1,1].axhline(200,color='#333333',ls='--',lw=1,label='200 K study guard')
axs[1,1].set(xlabel='Time after command (s)',ylabel='Tank temperature (K)',title='Guard stops firing before tanks are empty');axs[1,1].legend(fontsize=8)
for ax in axs.flat:ax.grid(alpha=.2)
fig.suptitle('Roadster study — native dynamics + Modelica gas/force calculations\nUncalibrated hardware assumptions; these are simulation results',fontsize=14)
for ext in ['svg','png']:fig.savefig(ROOT/f'results/propulsion-analysis.{ext}')
plt.close(fig)

rear,perimeter=thruster_stations();fig,(top,side)=plt.subplots(1,2,figsize=(12,7),constrained_layout=True)
top.add_patch(Rectangle((-.97,-2.25),1.94,4.5,fc='#eef1f2',ec='#879297'))
for x in [-.86,.86]:
 for z in [-1.375,1.375]:top.add_patch(Rectangle((x-.135,-z-.34),.27,.68,fc='#c2c8ca',ec='#555555'))
for i,(x,y,z,axis) in enumerate(perimeter):
 if i<4:
  top.plot(x,-z,'o',color=colors['lift'],ms=9);top.text(x+(.07 if x<0 else -.07),-z+.13,['FL','RL','FR','RR'][i],ha='left' if x<0 else 'right',fontsize=9)
 else:
  top.plot(x,-z,'o',color=colors['side']);top.annotate('',xy=(x+(-.38 if x<0 else .38),-z),xytext=(x,-z),arrowprops={'arrowstyle':'->','color':colors['side'],'lw':2})
for x,y,z in rear:
 top.plot(x,-z,'o',color=colors['rear']);top.annotate('',xy=(x,-z-.35),xytext=(x,-z),arrowprops={'arrowstyle':'->','color':colors['rear']})
top.plot(0,0,'*',ms=13,color='#ba3434');top.text(.1,.08,'COM',color='#ba3434')
top.text(0,2.52,'FRONT / forward -Z',ha='center');top.text(0,-2.93,'Rear exhaust +Z',ha='center')
top.set(aspect='equal',xlim=(-1.6,1.6),ylim=(-3.1,2.8),xlabel='Body X (m)',ylabel='- body Z (m)',title='Ten nozzle mounts: top view')
top.grid(alpha=.2)
side.add_patch(Polygon([(-2.25,-.30),(-2.25,.05),(-.8,.3),(-.2,.7),(.65,.66),(1.3,.32),(2.25,.25),(2.25,-.3)],closed=True,fc='#eef1f2',ec='#879297'))
for z in [-1.375,1.375]:side.add_patch(Circle((z,-.21),.34,fc='#c2c8ca',ec='#555555'))
side.plot(MOUNTS['mass_center_z'],MOUNTS['mass_center_y'],'*',ms=13,color='#ba3434');side.text(.04,-.12,'COM',color='#ba3434')
for z in [MOUNTS['lift_front_z'],MOUNTS['lift_rear_z']]:
 side.plot(z,MOUNTS['lift_y'],'o',color=colors['lift']);side.annotate('',xy=(z,.1),xytext=(z,MOUNTS['lift_y']),arrowprops={'arrowstyle':'->','color':colors['lift'],'lw':2})
side.plot(MOUNTS['rear_jet_z'],MOUNTS['rear_jet_y'],'o',color=colors['rear']);side.annotate('',xy=(1.7,MOUNTS['rear_jet_y']),xytext=(MOUNTS['rear_jet_z'],MOUNTS['rear_jet_y']),arrowprops={'arrowstyle':'->','color':colors['rear'],'lw':2})
side.text(-2.35,1.3,'Blue arrows: reaction forces on car\nOrange: forward reaction at rear mount\nRear line is 0.12 m above assumed COM',fontsize=10,va='top')
side.text(-2.35,-1.10,'Lift valves: front gain 1.000 / rear 0.486\nFixed arm trim makes K and Q/E pitch-neutral.\nNo rate/attitude feedback or automatic leveling.',fontsize=10)
side.set(aspect='equal',xlim=(-2.5,2.7),ylim=(-1.4,1.6),xlabel='Body Z (m; rear is positive)',ylabel='Body Y (m)',title='Side view: real moment arms');side.grid(alpha=.2)
fig.suptitle('Dimensioned study layout — topology follows reveal evidence; coordinates and COM are assumptions',fontsize=12)
for ext in ['svg','png']:fig.savefig(ROOT/f'results/thruster-layout.{ext}')
plt.close(fig)
summary=dict(wheel_only_s={'Performance_1700kg':performance['standing_start_0_60_s'],'Rocket_1950kg':rocket['standing_start_0_60_s']},
 boosted_s=boost['standing_start_0_60_s'],boost_recorded_window_s=boost['recorded_boost_window_s'],
 boost_mean_n=boost['mean_boost_to_60_n'],boost_impulse_ns=boost['boost_impulse_to_60_ns'],
 initial_modelica_analysis=forces['rear']['initial'],
 banks={b:{k:v[k] for k in ['peak_force_n','peak_mass_flow_kg_s','thermal_guard_at_s','failures']} for b,v in forces.items()},
 note='Mean force/impulse and sizing budget are Modelica outputs; trajectory and force plots use production observations. No Python dynamics solver.')
(ROOT/'results/propulsion-analysis.json').write_text(json.dumps(summary,indent=2)+'\n')
# Matplotlib leaves trailing blanks in SVG path data. Normalize generated text
# while retaining newlines as SVG whitespace separators.
for name in ['propulsion-analysis','thruster-layout']:
    path=ROOT/f'results/{name}.svg'
    path.write_text('\n'.join(line.rstrip() for line in path.read_text().splitlines())+'\n')
print('Wrote propulsion-analysis and thruster-layout figures plus summary JSON.')
