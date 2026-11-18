#!/usr/bin/env python3
"""Hold OS keys (or inject native repeat events) and compare command ports."""
import argparse,hashlib,json,os,socket,subprocess,time
from pathlib import Path
from types import SimpleNamespace
from check_keyboard_course import Pilot,ROOT
from x11_window_input import X11WindowInput

def main():
 ap=argparse.ArgumentParser(description=__doc__)
 ap.add_argument('--port',type=int,default=4200)
 ap.add_argument('--binary',type=Path,default=ROOT/'.scratch/control-target/debug/luncosim')
 ap.add_argument('--output',default='results/os-hold.json')
 ap.add_argument('--input-backend',choices=['x11','native'],default='x11')
 a=ap.parse_args();binary=a.binary.resolve()
 p=Pilot(SimpleNamespace(port=a.port,output=a.output,launch=True,manual=True,rate=.25))
 p.report.update(scene='scenes/roadster_rocket.usda',input_path='X11 XTEST -> owned window -> native command ports' if a.input_backend=='x11' else 'InjectWindowInput/native key and repeat events',checks={},hold_samples=[])
 files=['tests/python/x11_window_input.py','tests/python/check_os_hold.py','tests/python/check_keyboard_course.py',
   'config/input-bindings.json','vehicles/roadster.usda','scenes/roadster_rocket.usda']
 files=sorted(set(files)|{str(f.relative_to(ROOT)) for f in (ROOT/'models').glob('*.mo')})
 p.report['source_sha256']={f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in files}
 p.report['binary_sha256']=hashlib.sha256(binary.read_bytes()).hexdigest()
 process=log=None
 try:
  with socket.socket() as s:
   if s.connect_ex(('127.0.0.1',a.port))==0:raise RuntimeError('Owned OS hold port is already in use')
  env=os.environ.copy();env.update(LUNCOSIM_BIN=str(binary),WINIT_UNIX_BACKEND='x11',LUNCOSIM_ISOLATED_RUN='1')
  for n in ['WAYLAND_DISPLAY','WAYLAND_SOCKET','LUNCOSIM_EPHEMERAL_SETTINGS']:env.pop(n,None)
  log=p.out.with_suffix('.runtime.log').open('w')
  process=subprocess.Popen([str(ROOT/'scripts/start.sh'),'roadster_rocket','--api',str(a.port)],env=env,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
  deadline=time.monotonic()+120
  while time.monotonic()<deadline:
   if process.poll() is not None:raise RuntimeError('Owned hold runtime exited')
   try:p.q('GetReadiness');break
   except OSError:time.sleep(.1)
  else:raise RuntimeError('Owned hold runtime API unavailable')
  if a.input_backend=='x11':p.os_input=X11WindowInput(process.pid)
  p.setup();p.q('StepSimulation',hold=True)
  # Finish transport setup before activating the foreground input surface.
  # Once the hold begins, any subsequent focus loss aborts the run.
  if p.os_input:
   p.os_input.activate()
   control=p.os_input.display.get_keyboard_control()
   p.report['repeat_enabled']=bool(control.global_auto_repeat)
   if not p.report['repeat_enabled']:raise RuntimeError('OS auto-repeat is disabled; cannot qualify its input path')
  else:p.report['repeat_source']='Explicit native Pressed events with repeat=True; not OS delivery'
  # ReadPorts input records are authored defaults; native intents enter the
  # live solver batch. These aliases report what the physical model consumed.
  def ports():
   values=next(e['outputs'] for e in p.q('CosimStatus',include_values=True)['entities'] if e.get('name')=='/World/Roadster')
   return dict(steer=values['steering_driver.demand'],throttle=values['steering.throttle'])
  for key,port,desired in [('KeyD','steer',{'KeyD','ShiftLeft'}),('KeyW','throttle',{'KeyW'})]:
   p.keys(desired,0.0);time.sleep(.1);p.step(3)
   started=time.monotonic()
   while time.monotonic()-started<3.0:
    if p.os_input:p.os_input.ensure_focus()
    else:p.q('InjectWindowInput',event={'Key':dict(key=key,state='Pressed',text=None,repeat=True)})
    p.step(1)
    v=ports();state=p.os_input.held_state() if p.os_input else None;elapsed=time.monotonic()-started
    p.report['hold_samples'].append(dict(key=key,wall_s=elapsed,native=v,os_state=state))
    if abs(v[port])<.99 or (state is not None and not state['server_keys'].get(key)):raise RuntimeError(f'Held {key} lost: {v}, {state}')
    time.sleep(.03)
   p.report['checks'][key+'_held_through_repeat']=True
   p.keys({'ShiftLeft'},0.0);time.sleep(.1);p.step(3)
   released=ports()[port]
   p.report['checks'][key+'_release']=abs(released)<.001
  p.screenshot('complete')
  p.report['ok']=all(p.report['checks'].values())
  p.report['failures']=[k for k,v in p.report['checks'].items() if not v]
 except Exception as e:p.report['failures'].append(str(e))
 finally:
  p.release()
  if p.os_input:
   p.report['os_events']=p.os_input.events;p.os_input.close()
  if process and process.poll() is None:
   try:p.q('Exit');process.wait(timeout=15)
   except Exception:process.terminate();process.wait(timeout=15)
  if log:log.close()
  p.out.write_text(json.dumps(p.report,indent=2)+'\n')
 print(json.dumps({k:p.report[k] for k in ['ok','checks','failures']},indent=2))
 return 0 if p.report['ok'] else 1
if __name__=='__main__':raise SystemExit(main())
