#!/usr/bin/env python3
"""Author free-flight/drop and left/right rollover acceptance initial states."""
from author_surface_probes import q,ROOT,await_doc
from author_usd_physics import place_vehicle

def main():
 q('OpenFile',path=str(ROOT/'scenes/roadster_rocket.usda'));doc=await_doc(lambda d:'scenes/roadster_rocket.usda' in str(d))
 for kind,y,roll in [('DROP',6,0),('LEFT',1.2,90),('RIGHT',1.2,-90)]:
  q('SaveAsDocument',doc_id=doc,path=str(ROOT/f'scenes/roadster_contact_{kind.lower()}.usda'))
  values=[('/World/DriverSetup','info:sourceAsset','asset','@../scenarios/tests/contact_recovery.rhai@'),('/World/DriverSetup','study:case','string',kind),('/World/Roadster','xformOp:translate','double3',f'(0, {y}, 0)'),('/World/Roadster','xformOp:rotateXYZ','double3',f'(0, 0, {roll})'),('/World/Roadster','xformOpOrder','token[]','["xformOp:translate", "xformOp:rotateXYZ"]')]
  q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path=p,name=n,type_name=t,value=v)} for p,n,t,v in values]);place_vehicle(doc)
 q('CloseDocument',doc_id=doc)
if __name__=='__main__':main()
