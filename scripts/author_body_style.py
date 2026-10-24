#!/usr/bin/env python3
"""Author the reveal-inspired visual shell through the native USD journal.

Photo references and limits: references/body-style.md. Dimensions are original
study geometry, not Tesla CAD. Wheel openings affect side panels only: the hood
is an independent longitudinal surface, without tire-envelope humps.
"""
from math import sqrt
from author_surface_probes import q, ROOT, await_doc

# z, half width, deck height. A continuous wedge, not a curve at each axle.
PROFILE = [(-2.25, .82, .045), (-1.80, .955, .235), (-.75, .965, .345),
           (.30, .95, .36), (1.35, .995, .375), (2.25, .91, .30)]
AXLES = [-1.375, 1.375]
WELL_RADIUS = .395
WELL_CENTER_Y = -.145  # Existing 65 mm bump envelope and cosmetic clearance.


def profile(z):
    # Shape-preserving Hermite interpolation removes hard loft creases without
    # introducing overshoot/local wheel-shaped humps into the hood profile.
    def tangent(index, field):
        slopes=[(b[field]-a[field])/(b[0]-a[0]) for a,b in zip(PROFILE,PROFILE[1:])]
        if index==0:return slopes[0]
        if index==len(PROFILE)-1:return slopes[-1]
        left,right=slopes[index-1],slopes[index]
        return 2*left*right/(left+right) if left*right>0 else 0.0
    for index,(a, b) in enumerate(zip(PROFILE, PROFILE[1:])):
        if a[0] <= z <= b[0]:
            span=b[0]-a[0];t=(z-a[0])/span
            return tuple((2*t**3-3*t**2+1)*a[i]+(t**3-2*t**2+t)*span*tangent(index,i)
                         +(-2*t**3+3*t**2)*b[i]+(t**3-t**2)*span*tangent(index+1,i) for i in [1,2])
    raise ValueError(z)


def deck(x_fraction, z):
    w, y = profile(z)
    # Shallow transverse crown/chamfer; independent of wheel position.
    edge = .014*(1-abs(x_fraction))
    return (w*x_fraction, y+edge, z)


def opening(z, axle):
    return WELL_CENTER_Y+sqrt(max(0, WELL_RADIUS**2-(z-axle)**2))


def shell():
    points, faces = [], []
    def quad(vertices):
        start = len(points); points.extend(vertices)
        faces.append(tuple(range(start, start+len(vertices))))
    stations = sorted(set([round(-2.25+i*.025, 6) for i in range(181)]+
                          [p[0] for p in PROFILE]+
                          [a+d for a in AXLES for d in [-WELL_RADIUS, 0, WELL_RADIUS]]))
    fractions = [-1, -.96, -.80, 0, .80, .96, 1]
    for a, b in zip(stations, stations[1:]):
        for x0, x1 in zip(fractions, fractions[1:]):
            quad([deck(x0,a), deck(x0,b), deck(x1,b), deck(x1,a)])
        axle = next((c for c in AXLES if abs((a+b)/2-c)<WELL_RADIUS), None)
        la, lb = (-.265, -.265) if axle is None else (opening(a,axle), opening(b,axle))
        for sign in [-1, 1]:
            wa, ya = profile(a); wb, yb = profile(b)
            v = [(sign*wa,ya,a),(sign*wa,la,a),(sign*wb,lb,b),(sign*wb,yb,b)]
            quad(v if sign<0 else v[::-1])
    # End caps, with outward normals. No full-width sheet through wheel wells.
    for z in [-2.25, 2.25]:
        for fa, fb in zip(fractions, fractions[1:]):
            left, right = deck(fa, z), deck(fb, z)
            v = [(left[0], -.265, z), (right[0], -.265, z), right, left]
            quad(v if z>0 else v[::-1])
    return points, faces


def main():
    q('OpenFile',path=str(ROOT/'components/body.usda'))
    doc = await_doc(lambda d:'/components/body.usda' in str(d))
    ops = []
    def op(kind, **fields):
        ops.append({kind:dict(edit_target='@root@',**fields)})
    def attr(path,name,kind,value):
        op('SetAttribute',path=path,name=name,type_name=kind,value=str(value))
    def add(path,kind):
        if not q('InspectUsdDocument',doc_id=doc,path=path)['prim']['exists']:
            parent,name=path.rsplit('/',1)
            op('AddPrim',parent_path=parent or '/',name=name,type_name=kind,reference=None,reference_prim_path=None)
    def mesh(name,points,faces,material='White'):
        path='/Body/'+name;add(path,'Mesh')
        op('SetApiSchemas',path=path,schemas=['MaterialBindingAPI'])
        attr(path,'points','point3f[]',points)
        attr(path,'faceVertexCounts','int[]',[len(f) for f in faces])
        attr(path,'faceVertexIndices','int[]',[i for f in faces for i in f])
        attr(path,'subdivisionScheme','token','"none"')
        attr(path,'doubleSided','bool','true')
        attr(path,'physics:collisionEnabled','bool','false')
        op('SetRelationship',path=path,name='material:binding',targets=['/Body/Looks/'+material])
    def material(name,color,metallic,roughness):
        path='/Body/Looks/'+name;add(path,'Material');add(path+'/Shader','Shader')
        attr(path+'/Shader','info:id','token','"UsdPreviewSurface"')
        attr(path+'/Shader','inputs:diffuseColor','color3f',color)
        attr(path+'/Shader','inputs:metallic','float',metallic)
        attr(path+'/Shader','inputs:roughness','float',roughness)
        attr(path+'/Shader','outputs:surface','token','""')
        op('SetConnection',path=path,name='outputs:surface',type_name='token',sources=[path+'/Shader.outputs:surface'])
    def ribbon(name,a,b,width,material_name='White'):
        # A narrow surface ribbon for structural pillars and visible panel seams.
        v=[(a[0]-width/2,a[1],a[2]),(a[0]+width/2,a[1],a[2]),
           (b[0]+width/2,b[1],b[2]),(b[0]-width/2,b[1],b[2])]
        mesh(name,v,[(0,3,2,1)],material_name)

    material('White',(.88,.895,.90),.18,.26)
    material('Glass',(.15,.115,.075),.58,.13)
    material('SideGlass',(.045,.055,.064),.38,.18)
    mesh('Skin',*shell())

    # Wraparound windscreen, separate roof glazing and swept rear glass.
    rings=[(-.75,.745,.353),(-.15,.645,.70),(.62,.635,.68),(1.30,.74,.38)]
    glass=[(s*w,y,z) for z,w,y in rings for s in [-1,1]]
    mesh('GoldCanopy',glass,[(0,2,3,1),(2,4,5,3),(4,6,7,5)],'Glass')
    for sign,label in [(-1,'L'),(1,'R')]:
        side=[(sign*.745,.353,-.75),(sign*.645,.70,-.15),
              (sign*.635,.68,.62),(sign*.74,.38,1.30)]
        mesh('SideWindow'+label,side,[(3,2,1,0) if sign<0 else (0,1,2,3)],'SideGlass')
        ribbon('APillar'+label,(sign*.745,.357,-.752),(sign*.645,.705,-.15),.032)
        ribbon('RoofRail'+label,(sign*.645,.705,-.15),(sign*.635,.685,.62),.028)
        mesh('RearButtress'+label,[(sign*.635,.686,.62),(sign*.755,.384,1.31),
             (sign*.92,.37,1.10),(sign*.77,.397,.66)],[(3,2,1,0) if sign<0 else (0,1,2,3)])
        # Dark aperture depth is local to each side; it never lifts the hood.
        well_points,well_faces=[],[]
        for axle in AXLES:
            zs=[axle-WELL_RADIUS+2*WELL_RADIUS*i/40 for i in range(41)]
            for a,b in zip(zs,zs[1:]):
                wa,_=profile(a);wb,_=profile(b)
                i=len(well_points)
                well_points += [(sign*wa,opening(a,axle),a),(sign*.71,opening(a,axle),a),
                                (sign*.71,opening(b,axle),b),(sign*wb,opening(b,axle),b)]
                well_faces.append((i,i+1,i+2,i+3) if sign<0 else (i+3,i+2,i+1,i))
        mesh('WheelWellReveals'+label,well_points,well_faces,'Carbon')
    mesh('RoofSpine',[(-.024,.708,-.15),(.024,.708,-.15),(.024,.688,.62),(-.024,.688,.62)],[(0,3,2,1)])

    # Broad trapezoidal face and thin continuous DRL, as in the reveal photos.
    mesh('FrontMask',[(-.70,.038,-2.258),(.70,.038,-2.258),(.76,-.26,-2.258),(-.76,-.26,-2.258)],[(0,1,2,3)],'Carbon')
    mesh('FrontDRL',[(-.70,.043,-2.262),(.70,.043,-2.262),(.70,.054,-2.262),(-.70,.054,-2.262)],[(0,3,2,1)],'Lamp')
    for label in ['L','R']:
        attr('/Body/Headlight'+label,'visibility','token','"invisible"')
    # Closed triangular headlamp doors. Existing actual light sources still
    # illuminate the road; these are cosmetic door outlines, not a new emitter.
    for sign,label in [(-1,'L'),(1,'R')]:
        corners=[(sign*.80,-2.16),(sign*.97,-1.86),(sign*.80,-1.96)]
        for i,(a,b) in enumerate(zip(corners,corners[1:]+corners[:1])):
            # Follow the curved hood rather than letting a straight seam sink
            # through its surface. Keep the legacy three prim paths stable.
            points,faces=[],[]
            for j in range(16):
                ends=[]
                for t in [j/16,(j+1)/16]:
                    p=deck(a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1]))
                    ends.append((p[0],p[1]+.004,p[2]))
                u,v=ends;start=len(points)
                points += [(u[0]-.003,u[1],u[2]),(u[0]+.003,u[1],u[2]),
                           (v[0]+.003,v[1],v[2]),(v[0]-.003,v[1],v[2])]
                faces.append((start,start+3,start+2,start+1))
            mesh('HeadlampSeam'+label+str(i),points,faces,'Carbon')
    mesh('RearMask',[(-.86,.235,2.258),(.86,.235,2.258),(.81,-.265,2.258),(-.81,-.265,2.258)],[(0,3,2,1)],'Carbon')
    attr('/Body/RearLightBar','xformOp:translate','double3',(0,.245,2.263))
    attr('/Body/RearLightBar','xformOp:scale','double3',(1.73,.022,.014))
    attr('/Body/RearWing','xformOp:translate','double3',(0,.325,2.205))
    attr('/Body/RearWing','xformOp:scale','double3',(1.80,.025,.12))
    attr('/Body/FrontSplitter','xformOp:scale','double3',(1.78,.035,.25))
    attr('/Body','study:visualReference','string','"MotorTrend reveal photo gallery; references/body-style.md. Original study mesh, not Tesla CAD."')
    q('ApplyUsdOps',doc_id=doc,ops=ops)
    q('SaveDocument',doc_id=doc)
    q('CloseDocument',doc_id=doc)
    print('Saved reveal-inspired shell, side-only wheel openings, glazing, DRL and fascia via USD document journal.')


if __name__=='__main__':main()
