#!/usr/bin/env python3
"""Author speed/fan entry fixtures using the production USD document journal."""
import json,time,urllib.request,urllib.error
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def q(command,**params):
 req=urllib.request.Request('http://127.0.0.1:4198/api/commands',data=json.dumps(dict(type='ExecuteCommand',command=command,params=params)).encode(),headers={'Content-Type':'application/json'})
 r=json.load(urllib.request.urlopen(req,timeout=60))
 if 'error' in r:raise RuntimeError(r)
 return r['data']
def main():
 q('OpenFile',path=str(ROOT/'scenes/roadster_ramp.usda'))
 for _ in range(100):
  docs=q('ListOpenDocuments')['open_documents'];matches=[d for d in docs if d.get('kind')=='usd' and 'roadster_ramp.usda' in str(d)]
  if matches:
   try:q('InspectUsdDocument',doc_id=matches[-1]['doc_id'],path='/World');break
   except urllib.error.HTTPError:pass
  time.sleep(.1)
 else:raise RuntimeError(docs)
 doc=matches[-1]['doc_id']
 for speed,fan in [(11,1),(25,1),(40,1),(25,0)]:
  name=f'roadster_ramp_entry_{speed}_{fan}'
  q('SaveAsDocument',doc_id=doc,path=str(ROOT/f'scenes/{name}.usda'))
  values=[('/World/Roadster','xformOp:translate','double3','(0, 0.66, 10)'),('/World/DriverSetup','info:sourceAsset','asset','@../scenarios/tests/ramp_entry.rhai@'),('/World/DriverSetup','study:targetSpeed','double',str(speed)),('/World/DriverSetup','study:fan','double',str(fan))]
  q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path=p,name=n,type_name=t,value=v)} for p,n,t,v in values]);q('SaveDocument',doc_id=doc)
  if not q('InspectUsdDocument',doc_id=doc,path='/World/StuntRamp')['prim']['exists']:raise RuntimeError('Missing ramp after save')
  print(name)
 q('CloseDocument',doc_id=doc)

if __name__=='__main__':main()
