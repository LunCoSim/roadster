#!/usr/bin/env python3
"""Plot recorded native observations; no vehicle equations are solved here."""
import csv
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
ROOT=Path(__file__).resolve().parents[1]
before=list(csv.DictReader((ROOT/'results/ramp-entry-before-trace.csv').open()))
after=[r for r in csv.DictReader((ROOT/'results/ramp-entry-traces.csv').open()) if r['target_mps']=='40' and r['fan']=='1']
fig,axes=plt.subplots(2,1,figsize=(9,6),sharex=True,layout='constrained')
for rows,label,color in [(before,'Before: uncorrected triangle edges','#bb382c'),(after,'After: native internal-edge correction','#168368')]:
 rows=[r for r in rows if 4<=float(r['time_s'])<=6.2]
 t=[float(r['time_s']) for r in rows]
 axes[0].plot(t,[float(r['speed_mps']) for r in rows],label=label,color=color,lw=2)
 axes[1].plot(t,[float(r['body_normal_impulse_ns'])/1000 for r in rows],color=color,lw=2)
axes[0].set(ylabel='Vehicle speed (m/s)',ylim=(0,44))
axes[0].legend(loc='lower right',frameon=False)
axes[1].set(ylabel='Chassis normal impulse (kN s)',xlabel='Simulation time (s)',xlim=(4,6.2))
for ax in axes:ax.grid(alpha=.2);ax.spines[['right','top']].set_visible(False)
fig.suptitle('40 m/s ramp entry — same vehicle, ramp and commands',fontsize=14)
fig.savefig(ROOT/'results/ramp-entry-comparison.png',dpi=160)
