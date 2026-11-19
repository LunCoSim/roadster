#!/usr/bin/env python3
"""Create three thruster blowdown fixtures through the USD document API."""
from scene_documents import save_scene_as
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
        if entry.get('kind')=='usd' and any(n in str(entry.get('origin')) for n in ['roadster_rocket','roadster_force_','roadster_track','roadster_performance_motor_launch']):q('CloseDocument',doc_id=entry['doc_id'])
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
    for bank in ['REAR','LIFT','SIDE']:
        save_scene_as(q, doc, str(root/f'scenes/tests/roadster_force_{bank.lower()}.usda'))
        fields=[('/World/DriverSetup','info:sourceAsset','asset','@../../scenarios/tests/thrust_analysis.rhai@'),
                ('/World/DriverSetup','study:bank','string',bank),
                ('/World/Roadster','xformOp:translate','double3','(0,20,0)')]
        ops=[{'SetAttribute':dict(edit_target='@root@',path=path,name=name,type_name=kind,value=value)} for path,name,kind,value in fields]
        q('ApplyUsdOps',doc_id=doc,ops=ops);q("SaveDocument",doc_id=doc)
        if not q('InspectUsdDocument',doc_id=doc,path='/World/DriverSetup')['prim']['exists']:raise RuntimeError('Program did not read back')
    q('CloseDocument',doc_id=doc)
    q('OpenFile',path=str(root/'scenes/roadster_track.usda'))
    deadline=time.monotonic()+30
    while time.monotonic()<deadline:
        matches=[d for d in q('ListOpenDocuments')['open_documents'] if d.get('kind')=='usd' and 'roadster_track' in str(d.get('origin'))]
        if matches:
            try:q('InspectUsdDocument',doc_id=matches[-1]['doc_id'],path='/World');break
            except urllib.error.HTTPError:pass
        time.sleep(.1)
    else:raise RuntimeError('Track document did not become ready')
    doc=matches[-1]['doc_id'];save_scene_as(q, doc, str(root/'scenes/tests/roadster_performance_motor_launch.usda'))
    q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path='/World/DriverSetup',name='info:sourceAsset',type_name='asset',value='@../../scenarios/tests/motor_launch.rhai@')}])
    q('SaveDocument',doc_id=doc);q('InspectUsdDocument',doc_id=doc,path='/World/DriverSetup');q('CloseDocument',doc_id=doc)
    print('Saved three force fixtures and the Performance motor fixture through ApplyUsdOps.')
if __name__=='__main__':main()
