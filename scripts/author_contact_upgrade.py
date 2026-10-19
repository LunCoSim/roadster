#!/usr/bin/env python3
"""Author native wheel bodies, limited spring sliders, and physical steering."""
from author_surface_probes import q,ROOT,await_doc
from math import sqrt
import ast

def edit(file,root,build):
 q('OpenFile',path=str(ROOT/file));doc=await_doc(lambda d:file in str(d));ops=[]
 def op(kind,**fields):ops.append({kind:dict(edit_target='@root@',**fields)})
 def attr(path,name,kind,value):op('SetAttribute',path=path,name=name,type_name=kind,value=str(value))
 def add(name,kind='Xform'):op('AddPrim',parent_path=root,name=name,type_name=kind,reference=None,reference_prim_path=None);return root+'/'+name
 def schemas(path,values):op('SetApiSchemas',path=path,schemas=values)
 def rel(path,name,targets):op('SetRelationship',path=path,name=name,targets=targets)
 def read(path,name):
  return next(a["value"] for a in q("InspectUsdDocument",doc_id=doc,path=path)["prim"]["attributes"] if a["name"]==name)
 build(attr,add,schemas,rel,op,read)
 q('ApplyUsdOps',doc_id=doc,ops=ops);q('SaveDocument',doc_id=doc);q('CloseDocument',doc_id=doc)

def vehicle(a,add,s,rel,op,read):
 root='/Roadster'
 accuracy=add('ContactAccuracy','Scope');s(accuracy,['LunCoProgramAPI'])
 a(accuracy,'info:implementationSource','token','"sourceAsset"')
 a(accuracy,'info:sourceAsset','asset','@../scenarios/physics_accuracy.rhai@')
 a(accuracy,'study:maxIterations','int',8192)
 a(accuracy,'study:positionToleranceM','double',0.0005)
 a(accuracy,'study:angularToleranceRad','double',0.0005)
 a(root,'inputs:unlimited_air','double',0)
 for n in ['unlimited_air_active','ideal_supply_flow_kg_s','ideal_supply_heat_w','ideal_supply_air_kg','ideal_supply_power_w','ideal_supply_energy_j','chassis_mass_kg','chassis_com_y','chassis_com_z','chassis_inertia_xx','chassis_inertia_yy','chassis_inertia_zz']:
  a(root,'outputs:'+n,'float',0)
 a(root,'inputs:rear_jet_y','float',-.14)
 a(root,'physics:mass','float',1572)
 for port,source in [('mass','chassis_mass_kg'),('com_y','chassis_com_y'),('com_z','chassis_com_z'),('inertia_xx','chassis_inertia_xx'),('inertia_yy','chassis_inertia_yy'),('inertia_zz','chassis_inertia_zz')]:
  op('SetConnection',path=root,name='inputs:'+port,type_name='float',sources=[root+'.outputs:'+source])
 material=add('TireMaterial','Scope')
 op('SetReferenceArcs',path=material,references=[dict(asset_path='../components/rigid_road_tire.usda',prim_path='/RigidRoadTire')],list_op='Explicit')
 for name in ['FL','FR','RL','RR']:
  wheel=root+'/Wheel_'+name
  op('SetReferenceArcs',path=wheel,references=[dict(asset_path='lunco://components/mobility/wheel.usda',prim_path='/Wheel'),dict(asset_path='lunco://components/mobility/suspensions/standard.usda',prim_path='/Suspension')],list_op='Explicit')
  rel(wheel,'physxVehicleWheelAttachment:tire',[material])
 for i,(name,x,z) in enumerate([('FL',-.86,-1.375),('FR',.86,-1.375),('RL',-.86,1.375),('RR',.86,1.375)]):
  wheel=root+'/Wheel_'+name;carrier=add('Suspension_'+name)
  s(carrier,['PhysicsRigidBodyAPI','PhysicsMassAPI'])
  a(carrier,'physics:mass','float',5);a(carrier,'physics:diagonalInertia','float3','(0.05, 0.05, 0.05)')
  a(carrier,'xformOp:translate','double3',str((x,-.21,z)));a(carrier,'xformOpOrder','token[]','["xformOp:translate"]')
  owner=root
  if i<2:
   knuckle=add('SteeringKnuckle_'+name);s(knuckle,['PhysicsRigidBodyAPI','PhysicsMassAPI'])
   a(knuckle,'physics:mass','float',6);a(knuckle,'physics:diagonalInertia','float3','(0.05, 0.05, 0.05)')
   a(knuckle,'xformOp:translate','double3',str((x,-.21,z)));a(knuckle,'xformOpOrder','token[]','["xformOp:translate"]')
   hinge=add('Steering_'+name+'_Hinge','PhysicsRevoluteJoint');rel(hinge,'physics:body0',[root]);rel(hinge,'physics:body1',[knuckle])
   a(hinge,'physics:axis','token','"Y"');a(hinge,'physics:lowerLimit','float',-30);a(hinge,'physics:upperLimit','float',30)
   op('SetConnection',path=hinge,name='inputs:angle',type_name='float',sources=[root+'.outputs:heading_'+name.lower()]);owner=knuckle
  slider=add('Suspension_'+name+'_Slider','PhysicsPrismaticJoint');s(slider,['PhysicsDriveAPI:linear'])
  rel(slider,'physics:body0',[owner]);rel(slider,'physics:body1',[carrier]);a(slider,'physics:axis','token','"Y"')
  # Explicit mechanical end stops: 65 mm bump, 55 mm droop. No visual clamp.
  for n,v in [('physics:lowerLimit',-.055),('physics:upperLimit',.065),('drive:linear:physics:targetPosition',0),('drive:linear:physics:targetVelocity',0),('drive:linear:physics:stiffness',300000),('drive:linear:physics:damping',14000),('drive:linear:physics:maxForce',150000)]:a(slider,n,'float',v)
  a(slider,'drive:linear:physics:type','token','"force"')
  hinge=add('Wheel_'+name+'_Hinge','PhysicsRevoluteJoint');rel(hinge,'physics:body0',[carrier]);rel(hinge,'physics:body1',[wheel]);a(hinge,'physics:axis','token','"X"')
  s(wheel,['PhysxVehicleWheelAttachmentAPI','PhysxVehicleWheelAPI','PhysicsRigidBodyAPI','PhysicsCollisionAPI','PhysxRigidBodyAPI'])
  a(wheel,'physxRigidBody:enableCCD','bool','true')
  a(wheel,'physics:rigidBodyEnabled','bool','true');a(wheel,'physics:collisionEnabled','bool','true')
  # Tire and body envelopes clear at the hard stop. Filter only mechanism parts.
  op('RemoveRelationship',path=wheel,name='physics:filteredPairs')

def body(a,add,s,rel,op,read):
 # Upper swept tire envelope at the mechanical bump stop, plus 30 mm clearance.
 points=[list(p) for p in ast.literal_eval(read('/Body/Skin','points'))]
 for offset in range(0,len(points),6):
  section=points[offset:offset+6];z=section[0][2];lower=-.30
  for axle in [-1.375,1.375]:
   distance=abs(z-axle)
   if distance<.395:lower=max(lower,-.21+.065+sqrt(.395**2-distance**2))
  section[0][1]=lower;section[5][1]=lower
  top=max(section[1][1],lower+.025);section[1][1]=top;section[4][1]=top
  section[2][1]=max(section[2][1],top+.04);section[3][1]=section[2][1]
 a('/Body/Skin','points','point3f[]',str([tuple(p) for p in points]))

 # The old boxes cut across the wheel wells. Leave tire width + native contact
 # margin clear throughout full travel; keep real side support between axles.
 for name,size in [('BatteryFloorCollider',(1.48,.18,1.85)),('NoseCollider',(1.08,.32,1.12)),('RearDeckCollider',(1.32,.4,1.15))]:
  a('/Body/'+name,'xformOp:scale','double3',str(size))
 part=add('FrontCrashBar','Cube');s(part,['PhysicsCollisionAPI'])
 a(part,'size','double',1);a(part,'xformOp:translate','double3','(0, -0.08, -2.05)')
 a(part,'xformOp:scale','double3','(1.65, 0.24, 0.30)');a(part,'xformOpOrder','token[]','["xformOp:translate", "xformOp:scale"]')
 a(part,'visibility','token','"invisible"');a(part,'physics:collisionEnabled','bool','true')
 for name,x in [('RockerLeft',-.82),('RockerRight',.82)]:
  part=add(name,'Cube');s(part,['PhysicsCollisionAPI'])
  a(part,'size','double',1);a(part,'xformOp:translate','double3',str((x,-.1,0)))
  a(part,'xformOp:scale','double3','(0.24, 0.35, 1.85)');a(part,'xformOpOrder','token[]','["xformOp:translate", "xformOp:scale"]')
  a(part,'visibility','token','"invisible"');a(part,'physics:collisionEnabled','bool','true')

def rigid_tire(a,add,s,rel,op,read):
 s('/RigidRoadTire',['PhysicsMaterialAPI'])
 for name,value in [('staticFriction',1.4),('dynamicFriction',1.4),('restitution',0.0)]:
  a('/RigidRoadTire','physics:'+name,'float',value)

def rear(a,add,s,rel,op,read):
 for i,x in enumerate([-.55,-.2,.2,.55]):
  a('/RearThrusters/Nozzle'+str(i),'xformOp:translate','double3',str((x,-.14,2.3)))
  a('/RearThrusters/Jet'+str(i),'xformOp:translate','double3',str((x,-.14,2.37)))

if __name__=='__main__':
 edit('components/rigid_road_tire.usda','/RigidRoadTire',rigid_tire)
 edit('components/body.usda','/Body',body)
 edit('components/RearThrusters.usda','/RearThrusters',rear)
 edit('vehicles/roadster.usda','/Roadster',vehicle)
 from author_usd_physics import material as standard_material, vehicle as standard_vehicle, scenes as standard_scenes
 standard_material();standard_vehicle();standard_scenes()
 print('Saved standard collision-backed wheel and suspension topology and aligned rear thrust mounts.')
