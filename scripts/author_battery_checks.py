#!/usr/bin/env python3
"""Create battery sensitivity fixtures through the native USD document owner."""
from scene_documents import save_scene_as
from author_surface_probes import q,ROOT,await_doc

def main():
 for capacity,trim in [(110,'Rocket'),(120,'Rocket'),(140,'Rocket'),(120,'Thrust')]:
  source='roadster_launch' if trim=='Rocket' else 'roadster_thrust'
  target=f'roadster_battery_{capacity}' if trim=='Rocket' else 'roadster_thrust_storage'
  q('OpenFile',path=str(ROOT/('scenes/tests' if trim=='Rocket' else 'scenes')/f'{source}.usda'))
  doc=await_doc(lambda d:f'/{source}.usda' in str(d))
  save_scene_as(q, doc, str(ROOT/'scenes/tests'/f'{target}.usda'))
  program='/World/Scenario/Launch' if trim=='Rocket' else '/World/DriverSetup'
  ops=[{'SetAttribute':dict(edit_target='@root@',path=p,name=n,type_name=t,value=v)}
    for p,n,t,v in [('/World/Roadster','inputs:battery_capacity_kwh','float',str(capacity)),
      (program,'info:sourceAsset','asset','@twin://tesla-roadster-runner/scenarios/tests/battery_study.rhai@')]]
  q('ApplyUsdOps',doc_id=doc,ops=ops)
  q('SaveDocument',doc_id=doc);q('CloseDocument',doc_id=doc)
  print(target)
if __name__=='__main__':main()
