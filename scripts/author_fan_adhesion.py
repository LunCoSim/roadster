#!/usr/bin/env python3
"""Keep fan clearance queries inside their reusable USD adhesion component."""
import time,urllib.error
from author_surface_probes import q,ROOT,await_doc

def main():
 before={d['doc_id'] for d in q('ListOpenDocuments')['open_documents']};q('NewDocument',kind='usd')
 doc=await_doc(lambda d:d['doc_id'] not in before)
 q('SaveAsDocument',doc_id=doc,path=str(ROOT/'components/FanAdhesion.usda'))
 ops=[]
 if q('InspectUsdDocument',doc_id=doc,path='/World')['prim']['exists']:ops.append({'RemovePrim':dict(edit_target='@root@',path='/World')})
 ops += [{'AddPrim':dict(edit_target='@root@',parent_path='/',name='FanAdhesion',type_name='Xform',reference=None,reference_prim_path=None)},
  {'SetDefaultPrim':dict(edit_target='@root@',default_prim='/FanAdhesion')},
  {'SetStageDocumentation':dict(edit_target='@root@',documentation='Internal geometry adapter for FanAdhesion.mo. Four native clearance queries; no visible sensors or force/pose controller. The physical vehicle consumes only the resulting wrench and electrical load.')}]
 for i,(x,z) in enumerate([(-.6,-1.1),(-.6,1.1),(.6,-1.1),(.6,1.1)]):
  path='/FanAdhesion/Probe'+str(i)
  ops += [{'AddPrim':dict(edit_target='@root@',parent_path='/FanAdhesion',name='Probe'+str(i),type_name='Xform',reference='SurfaceProbe.usda',reference_prim_path='/SurfaceProbe')},
   {'SetAttribute':dict(edit_target='@root@',path=path,name='xformOp:translate',type_name='double3',value=str((x,-.3,z)))},
   {'SetAttribute':dict(edit_target='@root@',path=path,name='xformOpOrder',type_name='token[]',value='["xformOp:translate"]')}]
 q('ApplyUsdOps',doc_id=doc,ops=ops);q('SaveDocument',doc_id=doc)
 assert q('InspectUsdDocument',doc_id=doc,path='/FanAdhesion/Probe3')['prim']['exists'];q('CloseDocument',doc_id=doc)
 q('OpenFile',path=str(ROOT/'vehicles/roadster.usda'));doc=await_doc(lambda d:'/vehicles/roadster.usda' in str(d))
 q('ApplyUsdOps',doc_id=doc,ops=[{'AddPrim':dict(edit_target='@root@',parent_path='/Roadster',name='Adhesion',type_name='Xform',reference='../components/FanAdhesion.usda',reference_prim_path='/FanAdhesion')}])
 # Reference composition must settle before wiring its newly introduced ports.
 for _ in range(100):
  try:
   if q('InspectUsdDocument',doc_id=doc,path='/Roadster/Adhesion/Probe3')['prim']['exists']:break
  except urllib.error.HTTPError:pass
  time.sleep(.1)
 else:raise RuntimeError('Adhesion probes did not compose')
 ops=[]
 for i in range(4):
  for field,port in [('gap','ray_distance'),('valid','ray_hit_valid'),('nx','ray_hit_normal_x'),('ny','ray_hit_normal_y'),('nz','ray_hit_normal_z')]:
   ops.append({'SetConnection':dict(edit_target='@root@',path='/Roadster',name=f'inputs:surface_{field}_{i}',type_name='float',sources=[f'/Roadster/Adhesion/Probe{i}.outputs:{port}'])})
  if q('InspectUsdDocument',doc_id=doc,path='/Roadster/Seal'+str(i))['prim']['exists']:ops.append({'RemovePrim':dict(edit_target='@root@',path='/Roadster/Seal'+str(i))})
 q('ApplyUsdOps',doc_id=doc,ops=ops);q('SaveDocument',doc_id=doc)
 assert q('InspectUsdDocument',doc_id=doc,path='/Roadster/Adhesion/Probe3')['prim']['exists'];q('CloseDocument',doc_id=doc)
 print('Saved FanAdhesion geometry adapter and rewired its internal measurements.')
if __name__=='__main__':main()
