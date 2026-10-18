#!/usr/bin/env python3
"""Compare actual native headlights on/off on the dusk course (API 4198)."""
from check_driving import q
import json

def find(path): return int(q('RunRhai',dict(code='find_path('+json.dumps(path)+')'))['stdout'])
def ports(entity,names): return q('ReadPorts',dict(api_id=entity,port_names=names))['ports']
import time
from pathlib import Path
from PIL import Image,ImageChops,ImageStat
root=Path(__file__).resolve().parents[1]
old=q('RunRhai',dict(code='twin_name()'))['stdout'];q('OpenTwin',dict(path=str(root)))
for _ in range(200):
 state=q('GetReadiness');current=q('RunRhai',dict(code='twin_name()'))['stdout']
 if current!=old and state['ready'] and not state['world_hold'] and not state['pending_count']:
  status=q('CosimStatus',dict(include_values=False))
  if any(e.get('name')=='/World/Roadster' and e.get('status')=='Running' for e in status['entities']):break
 time.sleep(.1)
else:raise RuntimeError('Fresh scene not running')
time.sleep(.4)
car=find('/World/Roadster');avatar=find('/World/Avatar')
q('ReleaseControlSource',dict(source=avatar));q('AcquireControl',dict(target=car,bind_camera=False))
def write(writes):return q('SetPorts',dict(target=car,producer_id=4198001,writes=writes))
write([['brake',1.0],['fan',1.0]])
q('SetUserCamera',dict(name='DriverCamera'));time.sleep(.3)
values={}
for label,value in [('off',0.0),('on',1.0)]:
 write([['headlights',value]]);time.sleep(.5)
 values[label]=ports(car,['headlight_intensity_lm','headlight_power_w','headlight_peak_candela'])
 (root/f'results/headlights-{label}.png').write_bytes(q('CaptureScreenshot'))
a=Image.open(root/'results/headlights-off.png').convert('RGB');b=Image.open(root/'results/headlights-on.png').convert('RGB')
w,h=a.size;roi=(w//4,h//2,3*w//4,4*h//5);diff=ImageChops.difference(a.crop(roi),b.crop(roi)).convert('L')
changed=sum(n for i,n in enumerate(diff.histogram()) if i>2)
report=dict(roi=roi,mean_pixel_difference=ImageStat.Stat(diff).mean[0],pixels_difference_over_2=changed,measured=values,ok=changed>500 and ImageStat.Stat(diff).mean[0]>1.0)
(root/'results/headlights.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
write([['headlights',1.0],['brake',0.0]])
q('AcquireControl',dict(target=car,bind_camera=True));q('ObserveAvatar');time.sleep(.5)
(root/'results/hud-fixed-controls.png').write_bytes(q('CaptureScreenshot'))

raise SystemExit(0 if report['ok'] else 1)
