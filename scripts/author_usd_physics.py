#!/usr/bin/env python3
"""Author portable USD rigid-body frames, materials and explicit joint anchors.

All USD mutations use the production document journal. Nested bodies reset their
transform stack as Omniverse requires; scene instances therefore author their
initial world poses explicitly. Call place_vehicle after changing a scene pose.
"""
import ast
import math
import time
import urllib.error
from author_surface_probes import q, ROOT, await_doc

CORNERS = [('FL', -.86, -1.375), ('FR', .86, -1.375),
           ('RL', -.86, 1.375), ('RR', .86, 1.375)]
BODIES = {kind+'_'+name: (x, -.21, z)
          for name, x, z in CORNERS
          for kind in (['Wheel', 'Suspension', 'SteeringKnuckle'] if name[0]=='F'
                       else ['Wheel', 'Suspension'])}

def op(kind, **fields):
    return {kind: dict(edit_target='@root@', **fields)}

def attr(path, name, kind, value):
    return op('SetAttribute', path=path, name=name, type_name=kind, value=value)

def attributes(doc, path, command=q):
    return {a['name']: a['value'] for a in
            command('InspectUsdDocument', doc_id=doc, path=path)['prim']['attributes']}

def apply(doc, ops, command=q):
    command('ApplyUsdOps', doc_id=doc, ops=ops)
    command('SaveDocument', doc_id=doc)

def rotate_xyz(vector, angles):
    # USD rotateXYZ applies X, then Y, then Z to a column vector.
    x, y, z = vector
    ax, ay, az = map(math.radians, angles)
    y, z = math.cos(ax)*y-math.sin(ax)*z, math.sin(ax)*y+math.cos(ax)*z
    x, z = math.cos(ay)*x+math.sin(ay)*z, -math.sin(ay)*x+math.cos(ay)*z
    return (math.cos(az)*x-math.sin(az)*y, math.sin(az)*x+math.cos(az)*y, z)

def place_vehicle(doc, root='/World/Roadster', command=q):
    """Expand the scene's initial root placement onto the independent bodies."""
    values = attributes(doc, root, command)
    translate = ast.literal_eval(values['xformOp:translate'])
    order = ast.literal_eval(values['xformOpOrder'])
    if any(token not in ['xformOp:translate', 'xformOp:rotateXYZ'] for token in order):
        raise ValueError('Placement recipe requires a translate/rotateXYZ root: '+str(order))
    angles = ast.literal_eval(values['xformOp:rotateXYZ']) if 'xformOp:rotateXYZ' in order else (0,0,0)
    ops=[]
    for name, local in BODIES.items():
        path=root+'/'+name
        rotated=rotate_xyz(local, angles)
        world=tuple(a+b for a,b in zip(translate, rotated))
        ops += [attr(path,'xformOp:translate','double3',str(world)),
                attr(path,'xformOp:rotateXYZ','double3',str(tuple(angles))),
                attr(path,'xformOpOrder','token[]','["!resetXformStack!", "xformOp:translate", "xformOp:rotateXYZ"]')]
    apply(doc, ops, command)

def material():
    file='components/rigid_road_tire.usda'
    q('OpenFile',path=str(ROOT/file));doc=await_doc(lambda d:file in str(d))
    ops=[op('RemovePrim',path='/RigidRoadTire'),
         op('AddPrim',parent_path='/',name='RigidRoadTire',type_name='Material',reference=None,reference_prim_path=None),
         op('SetApiSchemas',path='/RigidRoadTire',schemas=['PhysicsMaterialAPI'])]
    for name,value in [('staticFriction',1.4),('dynamicFriction',1.4),('restitution',0)]:
        ops.append(attr('/RigidRoadTire','physics:'+name,'float',str(value)))
    apply(doc,ops);q('CloseDocument',doc_id=doc)

def vehicle():
    file='vehicles/roadster.usda'
    q('OpenFile',path=str(ROOT/file));doc=await_doc(lambda d:file in str(d))
    ops=[]
    # A material is a UsdShadeMaterial, independently bound for physics purpose.
    ops.append(op('RemovePrim',path='/Roadster/TireMaterial'))
    ops.append(op('AddPrim',parent_path='/Roadster',name='TireMaterial',type_name='Material',reference=None,reference_prim_path=None))
    ops.append(op('SetReferenceArcs',path='/Roadster/TireMaterial',references=[dict(asset_path='../components/rigid_road_tire.usda',prim_path='/RigidRoadTire')],list_op='Explicit'))
    for name, x, z in CORNERS:
        wheel='/Roadster/Wheel_'+name
        # The road variant already directly applies PhysxVehicleTireAPI.
        # An attachment cannot both apply it and target another tire endpoint.
        ops.append(op('RemoveRelationship',path=wheel,name='physxVehicleWheelAttachment:tire'))
        ops.append(op('SetRelationship',path=wheel,name='material:binding:physics',targets=['/Roadster/TireMaterial']))
        ops += [op('SetApiSchemas',path=wheel,schemas=['PhysxVehicleWheelAttachmentAPI','PhysxVehicleWheelAPI','PhysicsRigidBodyAPI','PhysicsCollisionAPI','PhysicsMassAPI','PhysxRigidBodyAPI']),
                attr(wheel,'physics:mass','float','24'),
                attr(wheel,'physics:diagonalInertia','float3',str((1.4, .8186 if name[0]=='F' else .8736, .8186 if name[0]=='F' else .8736))),
                attr(wheel,'physics:centerOfMass','point3f','(0, 0, 0)')]
        # Standard schema defaults are zero anchors, not inferred mount poses.
        joints=[('Wheel_'+name+'_Hinge',(0,0,0))]
        if name[0]=='F':
            joints += [('Steering_'+name+'_Hinge',(x,-.21,z)),('Suspension_'+name+'_Slider',(0,0,0))]
        else:
            joints += [('Suspension_'+name+'_Slider',(x,-.21,z))]
        for joint, anchor in joints:
            path='/Roadster/'+joint
            ops += [attr(path,'physics:localPos0','point3f',str(anchor)),
                    attr(path,'physics:localPos1','point3f','(0, 0, 0)'),
                    attr(path,'physics:localRot0','quatf','(1, 0, 0, 0)'),
                    attr(path,'physics:localRot1','quatf','(1, 0, 0, 0)')]
        if name[0]=='F':
            path='/Roadster/Steering_'+name+'_Hinge'
            ops.append(op('SetApiSchemas',path=path,schemas=['PhysicsDriveAPI:angular']))
            for key,value in [('stiffness',700),('damping',70),('maxForce',20000),('targetPosition',0),('targetVelocity',0)]:
                ops.append(attr(path,'drive:angular:physics:'+key,'float',str(value)))
            ops.append(attr(path,'drive:angular:physics:type','token','"force"'))
    for name, xyz in BODIES.items():
        path='/Roadster/'+name
        ops += [attr(path,'xformOp:translate','double3',str(xyz)),
                attr(path,'xformOp:rotateXYZ','double3','(0, 0, 0)'),
                attr(path,'xformOpOrder','token[]','["!resetXformStack!", "xformOp:translate", "xformOp:rotateXYZ"]')]
    apply(doc,ops)
    # Read back the composed schema contract after save.
    for name,_,_ in CORNERS:
        for attempt in range(50):
            try:
                r=q('QueryUsdPrim',doc_id=doc,path='/Roadster/Wheel_'+name,schemas=True,relationships=True,attrs=['xformOpOrder','physics:mass'])
                break
            except urllib.error.HTTPError:
                if attempt==49: raise
                time.sleep(.1)
        assert 'PhysxVehicleTireAPI' in r['api_schemas'],r
        assert not r['relationships'].get('physxVehicleWheelAttachment:tire'),r
        assert r['relationships']['material:binding:physics']==['/Roadster/TireMaterial'],r
    q('CloseDocument',doc_id=doc)

def scenes():
    for file in sorted((ROOT/'scenes').glob('roadster_*.usda')):
        q('OpenFile',path=str(file));doc=await_doc(lambda d:str(file) in str(d))
        if q('InspectUsdDocument',doc_id=doc,path='/World/Roadster')['prim']['exists']:
            place_vehicle(doc)
            apply(doc,[op('SetApiSchemas',path='/World/PhysicsScene',schemas=['PhysxSceneAPI']),
                       attr('/World/PhysicsScene','physxScene:enableCCD','bool','true')])
            print(file.name,flush=True)
        q('CloseDocument',doc_id=doc)

if __name__=='__main__':
    material()
    vehicle()
    scenes()
