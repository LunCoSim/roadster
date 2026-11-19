#!/usr/bin/env python3
"""Author the stunt ramp through LunCoSim's USD document journal (no USD text writes).

Run with a local production API, e.g. --port 4198. Curve sampling is offline
geometry construction, not a replacement dynamics solver. The mesh uses a
50 m transition whose pitch smoothly increases from level to vertical, with
zero end curvature, followed by a 10 m vertical wall. All dimensions SI.
"""
from scene_documents import save_scene_as
import argparse
import json
from math import sin,cos,pi
from pathlib import Path
import time
import urllib.request
import urllib.error
ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--port',type=int,default=4198);ap.add_argument('--course',action='store_true');args=ap.parse_args()
    def q(command,**params):
        req=urllib.request.Request(f'http://127.0.0.1:{args.port}/api/commands',
            data=json.dumps(dict(type='ExecuteCommand',command=command,params=params)).encode(),headers={'Content-Type':'application/json'})
        r=json.load(urllib.request.urlopen(req,timeout=60))
        if 'error' in r:raise RuntimeError(r)
        return r['data']
    source=ROOT/'scenes/roadster_rocket.usda'
    existing=q('ListOpenDocuments')['open_documents']
    for entry in existing:
        if entry.get('kind')=='usd' and any(name in str(entry.get('origin',{})) for name in ['roadster_ramp','roadster_rocket','roadster_skill_course','roadster_course_check']):
            q('CloseDocument',doc_id=entry['doc_id'])
    q('OpenFile',path=str(source))
    for _ in range(100):
        docs=q('ListOpenDocuments')['open_documents']
        matches=[d for d in docs if d.get('kind')=='usd' and 'roadster_rocket' in str(d)]
        if matches:
            try:
                q('InspectUsdDocument',doc_id=matches[-1]['doc_id'],path='/World')
                break
            except urllib.error.HTTPError:
                pass
        time.sleep(.1)
    else:raise RuntimeError(docs)
    doc=matches[-1]['doc_id'];q('InspectUsdDocument',doc_id=doc,path='/World')
    q('SaveAsDocument',doc_id=doc,path=str(ROOT/('scenes/roadster_skill_course.usda' if args.course else 'scenes/roadster_ramp.usda')))
    ops=[]
    def add(path,kind):
        parent,name=path.rsplit('/',1)
        ops.append({'AddPrim':dict(edit_target='@root@',parent_path=parent,name=name,type_name=kind,reference=None,reference_prim_path=None)})
    def attr(path,name,kind,value):
        ops.append({'SetAttribute':dict(edit_target='@root@',path=path,name=name,type_name=kind,value=value)})
    def literal(v):
        if isinstance(v,(list,tuple)):return ('[' if isinstance(v,list) else '(')+', '.join(literal(x) for x in v)+(']' if isinstance(v,list) else ')')
        return str(round(v,7))
    attr('/World/Roadster','xformOp:translate','double3','(0, 0.66, 200)' if args.course else '(0, 0.66, -60)')
    # Integrate the authored tangent to obtain a C2 level-to-wall profile.
    ramp_start=-300.0 if args.course else -70.0
    profile=[(0.0,ramp_start,0.0)]; y=0.0;z=ramp_start;n=250;ds=50.0/n
    for i in range(1,n+1):
        t=(i-.5)/n;theta=.5*pi*(3*t*t-2*t*t*t)
        y+=ds*sin(theta);z-=ds*cos(theta)
        t=i/n;profile.append((y,z,.5*pi*(3*t*t-2*t*t*t)))
    for j in range(1,51):profile.append((y+j*.2,z,.5*pi))
    y=profile[-1][0]
    for i in range(1,201):
        t=(i-.5)/200;theta=.5*pi+.5*pi*(3*t*t-2*t*t*t)
        y+=.2*sin(theta);z-=.2*cos(theta)
        t=i/200;profile.append((y,z,.5*pi+.5*pi*(3*t*t-2*t*t*t)))
    for j in range(1,41):profile.append((y,z+j*.2,pi))
    def strip(name,x0,x1,color,solid=False):
        path='/World/'+name;add(path,'Mesh');points=[];faces=[]
        for h,z,theta in profile:
            points.extend([(x0,h,z),(x1,h,z)])
        for i in range(len(profile)-1):faces.append((2*i,2*i+1,2*i+3,2*i+2))
        if solid:
            size=len(points)
            for h,z,theta in profile:points.extend([(x0,h-.6*cos(theta),z-.6*sin(theta)),(x1,h-.6*cos(theta),z-.6*sin(theta))])
            faces.extend(tuple(size+j for j in reversed(f)) for f in list(faces))
            for i in range(len(profile)-1):
                a=2*i;b=a+2;faces.extend([(a,b,b+size,a+size),(a+1,a+1+size,b+1+size,b+1)])
            faces.extend([(0,size,size+1,1),(size-2,size-1,2*size-1,2*size-2)])
            ops.append({'SetApiSchemas':dict(edit_target='@root@',path=path,schemas=['PhysicsCollisionAPI','PhysicsMeshCollisionAPI','LunCoTerrainAPI','MaterialBindingAPI'])})
            attr(path,'physics:collisionEnabled','bool','true')
            attr(path,'physics:approximation','token','"none"')
            ops.append({'SetRelationship':dict(edit_target='@root@',path=path,name='material:binding:physics',targets=['/World/AsphaltContact'])})
        else:
            attr(path,'xformOp:translate','double3','(0, 0.012, 0.012)')
            attr(path,'xformOpOrder','token[]','["xformOp:translate"]')
        attr(path,'points','point3f[]',literal(points))
        attr(path,'faceVertexCounts','int[]',literal([len(f) for f in faces]))
        attr(path,'faceVertexIndices','int[]',literal([v for f in faces for v in f]))
        attr(path,'subdivisionScheme','token','"none"');attr(path,'doubleSided','bool','true')
        attr(path,'primvars:displayColor','color3f[]',literal([color]))
    strip('StuntRamp',-7,7,(.20,.23,.27),True)
    strip('RampEdgeL',-6.95,-6.76,(.95,.055,.025));strip('RampEdgeR',6.76,6.95,(.95,.055,.025))
    strip('RampCenter',-.045,.045,(.8,.82,.85))
    # Overview camera coexists with the vehicle's authored chase/driver cameras.
    add('/World/RampOverview','Camera')
    ops.append({'SetApiSchemas':dict(edit_target='@root@',path='/World/RampOverview',schemas=['LunCoCameraAPI'])})
    attr('/World/RampOverview','xformOp:translate','double3','(230, 220, 50)' if args.course else '(75, 55, -20)')
    attr('/World/RampOverview','xformOpOrder','token[]','["xformOp:translate"]')
    attr('/World/RampOverview','lunco:cameraLookAt','double3','(0, 15, -70)' if args.course else '(0, 30, -75)')
    attr('/World/RampOverview','focalLength','float','12' if args.course else '16')
    attr('/World/RampOverview','clippingRange','float2','(0.05, 10000)')
    if args.course: author_course(add,attr,ops,profile)
    q('ApplyUsdOps',doc_id=doc,ops=ops)
    q("SaveDocument",doc_id=doc)
    checked=q('InspectUsdDocument',doc_id=doc,path='/World/StuntRamp')
    if not checked['prim']['exists']:raise RuntimeError('Ramp did not read back')
    report=dict(width_m=14,transition_arc_length_m=50,vertical_extension_m=10,
        height_m=profile[-1][0],wall_z_m=profile[-1][1],mesh_samples=len(profile),thickness_m=.6,
        authoring='ApplyUsdOps + SaveDocument',reference='User supplied stunt-ramp image; study dimensions, not measured replica')
    (ROOT/('results/course-geometry.json' if args.course else 'results/ramp-geometry.json')).write_text(json.dumps(report,indent=2)+'\n')
    if args.course:
        save_scene_as(q, doc, str(ROOT/'scenes/tests/roadster_course_check.usda'))
        q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path='/World/DriverSetup',
            name='info:sourceAsset',type_name='asset',value='@../../scenarios/tests/course_pilot.rhai@')},
            {'SetAttribute':dict(edit_target='@root@',path='/World/DriverSetup',name='study:expectCollision',type_name='bool',value='false')}])
        q('SaveDocument',doc_id=doc)
        print(json.dumps(report,indent=2));return
    save_scene_as(q, doc, str(ROOT/'scenes/tests/roadster_ramp_check.usda'))
    q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path='/World/DriverSetup',
        name='info:sourceAsset',type_name='asset',value='@../../scenarios/tests/ramp_drive.rhai@')}])
    q('SaveDocument',doc_id=doc)
    print(json.dumps(report,indent=2))
def author_course(add,attr,ops,profile):
    def cube(name,pos,size,color,collider=False):
        path='/World/'+name;add(path,'Cube');attr(path,'size','double','1')
        attr(path,'xformOp:translate','double3',str(tuple(pos)));attr(path,'xformOp:scale','double3',str(tuple(size)))
        attr(path,'xformOpOrder','token[]','["xformOp:translate","xformOp:scale"]')
        attr(path,'primvars:displayColor','color3f[]','['+str(tuple(color))+']')
        if collider:
            ops.append({'SetApiSchemas':dict(edit_target='@root@',path=path,schemas=['PhysicsCollisionAPI','MaterialBindingAPI'])})
            attr(path,'physics:collisionEnabled','bool','true')
            ops.append({'SetRelationship':dict(edit_target='@root@',path=path,name='material:binding:physics',targets=['/World/AsphaltContact'])})
    green=(.04,.85,.32);blue=(.03,.48,1);yellow=(1,.65,.02)
    for name,value in [('exposure:iso','400'),('exposure:time','0.016666667'),('exposure:fStop','2.8')]:
        attr('/World/Avatar',name,'float',value)
        attr('/World/RampOverview',name,'float',value)
        attr('/World/Roadster/DriverCamera',name,'float',value)
    attr('/World/Sun','inputs:intensity','float','80');attr('/World/Fill','inputs:intensity','float','10')
    attr('/World/EarthSky/Look/Shader','inputs:brightness','float','0.08')
    cube('CourseStart',(0,.04,197),(14,.04,.3),blue)
    for x in [-6.4,6.4]:cube('LaunchGate'+('L' if x<0 else 'R'),(x,2.5,140),(.35,5,.35),blue)
    cube('LaunchGateTop',(0,5,140),(13.2,.3,.3),blue)
    for index,center in enumerate([40,-200]):
        cube('RefillPad'+str(index),(0,.035,center),(12,.035,16),(.035,.21,.10))
        for side,x in enumerate([-6,6]):
            cube('RefillRail'+str(index)+str(side),(x,.07,center),(.15,.1,16),green)
            for j in range(2):cube('RefillMarker'+str(index)+str(side)+str(j),(x,1.0,center-8+j*16),(.25,2,.25),green)
    cube('TakeoffLine',(0,.06,-86),(12,.05,.5),yellow)
    for i in range(3):
        z=-100-i*8
        cube('JumpBlock'+str(i),(0,.6,z),(12,1.2,2.4),(.8,.2,.035),True)
        cube('BlockTop'+str(i),(0,1.215,z),(12,.025,2.4),yellow)
    cube('LandingPad',(0,.04,-262.5),(12,.045,65),(.025,.28,.14))
    for x in [-6,6]:cube('LandingRail'+('L' if x<0 else 'R'),(x,.08,-262.5),(.15,.08,65),green)
    # Crest bars sit outside the tire path; checkpoint geometry never obstructs the car.
    for x in [-7.5,7.5]:cube('CrestMarker'+('L' if x<0 else 'R'),(x,61.0,profile[-1][1]-4),(.35,8,.35),green)
    attr('/World/Roadster','inputs:course_enabled','float','1')
    for name in ['course_phase','course_blocks_passed']:attr('/World/Roadster','inputs:'+name,'float','0')
    # Native body position is sampled by the course script and admitted as a
    # measured input; this does not author a competing native output port.
    attr('/World/Roadster','inputs:course_position_y','float','0.66')
    for name in ['course_stage','course_blocks','course_time_s','course_air_rotation_degrees','target_distance_m','launch_gate',
       'refill_zone','refill_ready','jump_clearance','climb_gate','landing_gate']:
        attr('/World/Roadster','outputs:'+name,'float','0')
    add('/World/CourseRuntime','Scope')
    add('/World/CourseRuntime/Program','Scope')
    ops.append({'SetApiSchemas':dict(edit_target='@root@',path='/World/CourseRuntime/Program',schemas=['LunCoProgramAPI'])})
    attr('/World/CourseRuntime/Program','info:implementationSource','token','"sourceAsset"')
    attr('/World/CourseRuntime/Program','info:sourceAsset','asset','@../scenarios/skill_course.rhai@')

if __name__=='__main__':main()
