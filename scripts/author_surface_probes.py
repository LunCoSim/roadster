#!/usr/bin/env python3
"""Author plain collision-geometry probes, with no instrument or debug visuals."""
import time,urllib.error
from author_ramp_entry_checks import q,ROOT

def await_doc(match):
 for _ in range(100):
  matches=[d for d in q('ListOpenDocuments')['open_documents'] if d.get('kind')=='usd' and match(d)]
  if matches:
   try:q('InspectUsdDocument',doc_id=matches[-1]['doc_id'],path='/');return matches[-1]['doc_id']
   except urllib.error.HTTPError:pass
  time.sleep(.1)
 raise RuntimeError('USD document unavailable')
def main():
 before={d['doc_id'] for d in q('ListOpenDocuments')['open_documents']}
 q('NewDocument',kind='usd');doc=await_doc(lambda d:d['doc_id'] not in before)
 q('SaveAsDocument',doc_id=doc,path=str(ROOT/'components/SurfaceProbe.usda'))
 ops=[]
 def attr(path,name,kind,value):ops.append({'SetAttribute':dict(edit_target='@root@',path=path,name=name,type_name=kind,value=value)})
 # New USD stages may contain the default World scaffold; this component owns one root.
 if q('InspectUsdDocument',doc_id=doc,path='/World')['prim']['exists']:ops.append({'RemovePrim':dict(edit_target='@root@',path='/World')})
 ops += [{'AddPrim':dict(edit_target='@root@',parent_path='/',name='SurfaceProbe',type_name='Xform',reference=None,reference_prim_path=None)},
  {'SetApiSchemas':dict(edit_target='@root@',path='/SurfaceProbe',schemas=['LunCoRaycastAPI'])},
  {'SetDefaultPrim':dict(edit_target='@root@',default_prim='/SurfaceProbe')},
  {'SetStageDocumentation':dict(edit_target='@root@',documentation='Simulation geometry query for underbody clearance and surface normal. Not physical Tesla sensor hardware. No visible mesh, measurement noise, controller or force source.')}]
 attr('/SurfaceProbe','lunco:raycast:axis','token','"-Y"');attr('/SurfaceProbe','lunco:raycast:maxDistance','float','1')
 attr('/SurfaceProbe','lunco:raycast:offset','double3','(0, 0, 0)')
 for name in ['distance','hit_valid','hit_position_x','hit_position_y','hit_position_z','hit_normal_x','hit_normal_y','hit_normal_z','sample_time','origin_body_local_x','origin_body_local_y','origin_body_local_z','direction_body_local_x','direction_body_local_y','direction_body_local_z']:
  attr('/SurfaceProbe','outputs:ray_'+name,'float','0')
 q('ApplyUsdOps',doc_id=doc,ops=ops);q('SaveDocument',doc_id=doc)
 assert q('InspectUsdDocument',doc_id=doc,path='/SurfaceProbe')['prim']['exists'];q('CloseDocument',doc_id=doc)
 q('OpenFile',path=str(ROOT/'vehicles/roadster.usda'));doc=await_doc(lambda d:'/vehicles/roadster.usda' in str(d))
 ops=[]
 for probe in ['GroundSeal']:
  path='/Roadster/'+probe
  ops.append({'SetReferenceArcs':dict(edit_target='@root@',path=path,references=[dict(asset_path='../components/SurfaceProbe.usda',prim_path='/SurfaceProbe')],list_op='Explicit')})
  for child in ['Model','Beam','Hit']:ops.append({'RemovePrim':dict(edit_target='@root@',path=path+'/'+child)})
 q('ApplyUsdOps',doc_id=doc,ops=ops);q('SaveDocument',doc_id=doc)
 assert q('InspectUsdDocument',doc_id=doc,path='/Roadster/GroundSeal')['prim']['exists'];q('CloseDocument',doc_id=doc)
 print('Saved plain SurfaceProbe and replaced the ground-clearance altimeter reference through the USD journal.')
if __name__=='__main__':main()
