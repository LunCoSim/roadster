#!/usr/bin/env python3
"""Create the moving-jump regression fixture through the USD document API."""
import argparse,json,time,urllib.request
from pathlib import Path

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--port',type=int,default=4198);args=ap.parse_args()
    root=Path(__file__).resolve().parents[1]
    def q(command,**params):
        req=urllib.request.Request(f'http://127.0.0.1:{args.port}/api/commands',data=json.dumps(dict(type='ExecuteCommand',command=command,params=params)).encode(),headers={'Content-Type':'application/json'})
        r=json.load(urllib.request.urlopen(req,timeout=30))
        if 'error' in r:raise RuntimeError(r['error'])
        return r['data']
    for entry in q('ListOpenDocuments')['open_documents']:
        if entry.get('kind')=='usd' and any(n in str(entry.get('origin')) for n in ['roadster_rocket','roadster_moving_jump_check']):q('CloseDocument',doc_id=entry['doc_id'])
    q('OpenFile',path=str(root/'scenes/roadster_rocket.usda'))
    deadline=time.monotonic()+30
    while time.monotonic()<deadline:
        matches=[d for d in q('ListOpenDocuments')['open_documents'] if d.get('kind')=='usd' and 'roadster_rocket' in str(d.get('origin'))]
        if matches:
            try:q('InspectUsdDocument',doc_id=matches[-1]['doc_id'],path='/World');break
            except urllib.error.HTTPError:pass
        time.sleep(.1)
    else:raise RuntimeError('Rocket document did not become ready')
    doc=matches[-1]['doc_id']
    q('SaveAsDocument',doc_id=doc,path=str(root/'scenes/roadster_moving_jump_check.usda'))
    q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path='/World/DriverSetup',name='info:sourceAsset',type_name='asset',value='@../scenarios/tests/moving_jump.rhai@')}])
    q('SaveDocument',doc_id=doc)
    check=q('InspectUsdDocument',doc_id=doc,path='/World/DriverSetup')
    if not check['prim']['exists']:raise RuntimeError('Regression program did not read back')
    q('CloseDocument',doc_id=doc)
    print('Saved roadster_moving_jump_check.usda through ApplyUsdOps.')
if __name__=='__main__':main()
