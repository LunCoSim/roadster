#!/usr/bin/env python3
"""Audit the portable rigid-body contract through composed USD document queries.

This checks authored scene facts. It does not certify NVIDIA PhysX execution or
execute Modelica/Rhai in Omniverse.
"""
import json
import math
import time
import urllib.error
from author_surface_probes import q, ROOT, await_doc
from author_usd_physics import BODIES, CORNERS, rotate_xyz

SOURCES = {
 'usd_physics': 'https://openusd.org/release/api/usd_physics_page_front.html',
 'omniverse_nested_bodies': 'https://docs.omniverse.nvidia.com/kit/docs/asset-requirements/latest/capabilities/physics_bodies/physics_rigid_bodies/requirements/rigid-body-no-nesting.html',
 'wheel_attachment': 'https://docs.omniverse.nvidia.com/kit/docs/omni_usd_schema_physics/latest/physxschema/class_physx_schema_physx_vehicle_wheel_attachment_a_p_i.html',
}

def prim(doc, path, **options):
    for attempt in range(50):
        try:
            return q('QueryUsdPrim',doc_id=doc,path=path,**options)
        except urllib.error.HTTPError:
            if attempt==49: raise
            time.sleep(.1)

def require(condition, message, failures):
    if not condition: failures.append(message)

def audit_vehicle(doc):
    failures=[]; bodies=[]; joints=[]
    root='/Roadster'
    for name in BODIES:
        path=root+'/'+name
        p=prim(doc,path,schemas=True,attrs=['xformOpOrder','physics:mass','physics:diagonalInertia'])
        a=p['attrs'];apis=p['api_schemas']
        require('PhysicsRigidBodyAPI' in apis,path+': rigid body missing',failures)
        require('!resetXformStack!' in a.get('xformOpOrder',[]),path+': nested body has no reset',failures)
        require(a.get('physics:mass',0)>0,path+': mass missing',failures)
        require(all(v>0 and math.isfinite(v) for v in a.get('physics:diagonalInertia',[0])),path+': inertia missing',failures)
        if name.startswith('Wheel_'):
            require('PhysicsCollisionAPI' in apis,path+': collision API missing',failures)
            p=prim(doc,path,schemas=True,relationships=True,attrs=['axis','radius','height'])
            for endpoint,api in [('wheel','PhysxVehicleWheelAPI'),('suspension','PhysxVehicleSuspensionAPI'),('tire','PhysxVehicleTireAPI')]:
                target=p['relationships'].get('physxVehicleWheelAttachment:'+endpoint,[])
                direct=api in p['api_schemas']
                require((direct and not target) or (not direct and len(target)==1),path+': ambiguous '+endpoint,failures)
                if target:
                    require(api in prim(doc,target[0],schemas=True,attrs=[])['api_schemas'],path+': wrong '+endpoint+' endpoint',failures)
            material=p['relationships'].get('material:binding:physics',[])
            require(len(material)==1,path+': missing physics binding',failures)
            if material:
                m=prim(doc,material[0],schemas=True,attrs=['physics:staticFriction','physics:dynamicFriction','physics:restitution'])
                require(m['type_name']=='Material' and 'PhysicsMaterialAPI' in m['api_schemas'],path+': binding is not a physics Material',failures)
        bodies.append(dict(path=path,mass_kg=a.get('physics:mass'),inertia=a.get('physics:diagonalInertia')))
    for name,_,_ in CORNERS:
        for joint in ['Suspension_'+name+'_Slider','Wheel_'+name+'_Hinge']+(['Steering_'+name+'_Hinge'] if name[0]=='F' else []):
            path=root+'/'+joint
            p=prim(doc,path,relationships=True,attrs=['physics:localPos0','physics:localPos1','physics:localRot0','physics:localRot1','physics:axis'])
            for field in ['localPos0','localPos1','localRot0','localRot1']:
                require('physics:'+field in p['attrs'],path+': implicit '+field,failures)
            for endpoint in ['body0','body1']:
                targets=p['relationships'].get('physics:'+endpoint,[])
                require(len(targets)==1,path+': invalid '+endpoint,failures)
            joints.append(dict(path=path,frames=p['attrs']))
    return dict(failures=failures,bodies=bodies,joints=joints)

def main():
    q('OpenFile',path=str(ROOT/'vehicles/roadster.usda'))
    doc=await_doc(lambda d:'vehicles/roadster.usda' in str(d))
    report=audit_vehicle(doc)
    q('CloseDocument',doc_id=doc)
    scenes=[]
    for file in sorted((ROOT/'scenes').glob('roadster_*.usda')):
        q('OpenFile',path=str(file));doc=await_doc(lambda d:str(file) in str(d))
        if not q('InspectUsdDocument',doc_id=doc,path='/World/Roadster')['prim']['exists']:
            q('CloseDocument',doc_id=doc);continue
        root=prim(doc,'/World/Roadster',attrs=['xformOp:translate','xformOp:rotateXYZ','xformOpOrder'])['attrs']
        angles=root.get('xformOp:rotateXYZ',[0,0,0]) if 'xformOp:rotateXYZ' in root['xformOpOrder'] else [0,0,0]
        maximum_error=0
        for name,local in BODIES.items():
            expected=[a+b for a,b in zip(root['xformOp:translate'],rotate_xyz(local,angles))]
            actual=prim(doc,'/World/Roadster/'+name,attrs=[])['world_position']
            maximum_error=max(maximum_error,max(abs(a-b) for a,b in zip(expected,actual)))
        require(maximum_error<1e-4,file.name+': initial body frame drift',report['failures'])
        scene=prim(doc,'/World/PhysicsScene',schemas=True,attrs=['physics:gravityMagnitude','physics:gravityDirection','physxScene:enableCCD'])
        gravity=scene['attrs']
        require('PhysxSceneAPI' in scene['api_schemas'] and gravity.get('physxScene:enableCCD') is True,file.name+': scene CCD disabled',report['failures'])
        require(abs(gravity['physics:gravityMagnitude']-9.80665)<1e-5,file.name+': wrong Earth gravity',report['failures'])
        scenes.append(dict(scene=file.name,maximum_pose_error_m=maximum_error))
        q('CloseDocument',doc_id=doc)
    report.update(ok=not report['failures'],scenes=scenes,sources=SOURCES,
                  scope='Composed USD authoring audit; Omniverse execution not tested')
    (ROOT/'results/usd-standard.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(dict(ok=report['ok'],bodies=len(report['bodies']),joints=len(report['joints']),scenes=len(scenes),failures=report['failures']),indent=2))
    return 0 if report['ok'] else 1

if __name__=='__main__':raise SystemExit(main())
