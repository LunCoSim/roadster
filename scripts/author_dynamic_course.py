#!/usr/bin/env python3
"""Revise the cube timing corridor using the native USD document journal."""
from author_surface_probes import q, ROOT, await_doc
import json
from math import sin,cos,pi

def main():
    report=dict(block_height_m=3.0,block_length_m=2.4,block_centers_z_m=[-100,-112,-124],
                takeoff_z_m=-72.0,nominal_speed_mps=35.0,
                authoring='OpenFile / ApplyUsdOps / SaveDocument',
                provenance='Skill-game study geometry; not measured Tesla course dimensions')
    # C2 tangent transitions, no collider wedge at entry. An 18 m lower arc,
    # 0.9 m wall, 11.7 m return arc and 5.4 m lip form an 18.9 m study ramp.
    profile=[(0.0,-300.0,0.0)];y=0.0;z=-300.0
    for i in range(1,251):
        t=(i-.5)/250;theta=.5*pi*(3*t*t-2*t*t*t)
        y+=18/250*sin(theta);z-=18/250*cos(theta)
        t=i/250;profile.append((y,z,.5*pi*(3*t*t-2*t*t*t)))
    for j in range(1,11):profile.append((y+j*.9/10,z,.5*pi))
    y=profile[-1][0]
    for i in range(1,201):
        t=(i-.5)/200;theta=.5*pi+.5*pi*(3*t*t-2*t*t*t)
        y+=11.7/200*sin(theta);z-=11.7/200*cos(theta)
        t=i/200;profile.append((y,z,.5*pi+.5*pi*(3*t*t-2*t*t*t)))
    for j in range(1,41):profile.append((y,z+j*5.4/40,pi))
    report.update(ramp_height_m=y,ramp_end_z_m=profile[-1][1],lower_arc_m=18,vertical_m=.9,upper_arc_m=11.7,lip_m=5.4,transverse_segments=14)
    for scene in ['roadster_skill_course','roadster_course_check']:
        q('OpenFile',path=str(ROOT/'scenes'/f'{scene}.usda'))
        doc=await_doc(lambda d: f'/{scene}.usda' in str(d))
        ops=[]
        def attr(path,name,kind,value):
            ops.append({'SetAttribute':dict(edit_target='@root@',path=path,name=name,type_name=kind,value=value)})
        for i,z in enumerate(report['block_centers_z_m']):
            attr(f'/World/JumpBlock{i}','xformOp:translate','double3',str((0,1.5,z)))
            attr(f'/World/JumpBlock{i}','xformOp:scale','double3',str((12,3,2.4)))
            attr(f'/World/BlockTop{i}','xformOp:translate','double3',str((0,3.015,z)))
        attr('/World/TakeoffLine','xformOp:translate','double3','(0, 0.06, -72)')
        for name,x0,x1,solid in [('StuntRamp',-7,7,True),('RampEdgeL',-6.95,-6.76,False),('RampEdgeR',6.76,6.95,False),('RampCenter',-.045,.045,False)]:
            # Keep the physical surface and closed thickness, and subdivide
            # across width so contact triangles have reasonable aspect ratios.
            columns=14 if solid else 1;stride=columns+1
            points=[];faces=[]
            for h,z,theta in profile:
                points.extend([(x0+(x1-x0)*j/columns,h,z) for j in range(stride)])
            for i in range(len(profile)-1):
                for j in range(columns):
                    a=i*stride+j;faces.append((a,a+1,a+stride+1,a+stride))
            if solid:
                size=len(points)
                for h,z,theta in profile:
                    points.extend([(x0+(x1-x0)*j/columns,h-.6*cos(theta),z-.6*sin(theta)) for j in range(stride)])
                faces.extend(tuple(size+j for j in reversed(f)) for f in list(faces))
                for i in range(len(profile)-1):
                    for j in [0,columns]:
                        a=i*stride+j;b=a+stride
                        faces.append((a,b,b+size,a+size) if j==0 else (a,a+size,b+size,b))
                for j in range(columns):
                    a=j;faces.append((a,a+size,a+1+size,a+1))
                    a=(len(profile)-1)*stride+j;faces.append((a,a+1,a+1+size,a+size))
            attr('/World/'+name,'points','point3f[]','['+', '.join(str(tuple(round(a,7) for a in p)) for p in points)+']')
            attr('/World/'+name,'faceVertexCounts','int[]',str([4]*len(faces)))
            attr('/World/'+name,'faceVertexIndices','int[]',str([j for f in faces for j in f]))
        for side,x in [('L',-7.5),('R',7.5)]:
            attr('/World/CrestMarker'+side,'xformOp:translate','double3',str((x,y-1,profile[-1][1]-4)))
        q('ApplyUsdOps',doc_id=doc,ops=ops);q('SaveDocument',doc_id=doc)
        for i in range(3):
            assert q('InspectUsdDocument',doc_id=doc,path=f'/World/JumpBlock{i}')['prim']['exists']
        if scene=='roadster_course_check':
            for label,offset in [('early',0.3),('late',-0.2)]:
                q('SaveAsDocument',doc_id=doc,path=str(ROOT/'scenes'/f'roadster_course_{label}.usda'))
                q('ApplyUsdOps',doc_id=doc,ops=[{'SetAttribute':dict(edit_target='@root@',path='/World/DriverSetup',name='study:jumpTimingOffset',type_name='double',value=str(offset))}])
                q('SaveDocument',doc_id=doc)
        q('CloseDocument',doc_id=doc)
    (ROOT/'results/dynamic-geometry.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
if __name__=='__main__':main()
