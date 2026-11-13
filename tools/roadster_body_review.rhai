// Procedural styling adapted from eduardmur/tesla-roadster-simulator,
// src/scene/car/body.ts at a0d187c08514cd15569d25f6afcace9e6da20c0c.
// Copyright (c) 2026 Tesla Roadster Simulator contributors, MIT.
// See references/licenses/tesla-roadster-simulator-MIT.txt.
// Geometry only: the canonical rigid body, wheels and propulsion stay owners.

fn linear(keys,z) {
    if z>=keys[0][0] {return keys[0][1];}
    for i in 0..keys.len()-1 {
        let a=keys[i];let b=keys[i+1];
        if z<=a[0] && z>=b[0] {return a[1]+(b[1]-a[1])*(z-a[0])/(b[0]-a[0]);}
    }
    keys[keys.len()-1][1]
}
fn slope(keys,i) {
    let a=keys[max(0,i-1)];let b=keys[min(keys.len()-1,i+1)];
    (b[1]-a[1])/(b[0]-a[0])
}
fn curve(keys,z) {
    if z>=keys[0][0] {return keys[0][1];}
    for i in 0..keys.len()-1 {
        let a=keys[i];let b=keys[i+1];
        if z<=a[0] && z>=b[0] {
            let h=b[0]-a[0];let t=(z-a[0])/h;let t2=t*t;let t3=t2*t;
            return (2*t3-3*t2+1)*a[1]+(t3-2*t2+t)*h*slope(keys,i)
                +(-2*t3+3*t2)*b[1]+(t3-t2)*h*slope(keys,i+1);
        }
    }
    keys[keys.len()-1][1]
}
fn smooth(a,b,x) {let t=min(1.0,max(0.0,(x-a)/(b-a)));t*t*(3.0-2.0*t)}
fn station(z) {
    let w=linear([[2.17,0.66],[1.78,0.95],[1.36,0.99],[0.4,0.97],[-1.4,1.01],[-1.85,1.0],[-2.17,0.9]],z);
    let yt=curve([[2.17,0.05],[1.9,0.21],[1.6,0.3],[1.36,0.35],[1.08,0.41],[0.5,0.57],[0.0,0.62],[-0.5,0.63],[-1.0,0.59],[-1.5,0.51],[-1.85,0.46],[-2.17,0.43]],z);
    let wt=min(linear([[2.17,0.5],[1.8,0.7],[1.08,0.8],[0.3,0.74],[-0.5,0.64],[-1.2,0.54],[-1.82,0.47],[-2.17,0.8]],z),w-0.12);
    let hg=if z<1.1 && z> -1.1 {max(0.0,curve([[1.1,0.0],[0.8,0.13],[0.3,0.2],[-0.3,0.19],[-0.75,0.11],[-1.1,0.0]],z))}else{0.0};
    let ys=curve([[2.17,-0.02],[1.9,0.19],[1.36,0.335],[0.9,0.3],[0.2,0.26],[-0.7,0.3],[-1.4,0.38],[-1.9,0.37],[-2.17,0.38]],z);
    let yrail=max(yt-0.035+0.05*smooth(1.0,1.45,z),ys+0.04);
    let ybelt=max(yrail-hg,ys+0.04);
    let wbelt=min(wt+0.65*(yrail-ybelt)+0.0001,w-0.08);
    let yb=curve([[2.17,-0.24],[2.0,-0.32],[1.7,-0.35],[-1.75,-0.35],[-2.0,-0.29],[-2.17,-0.24]],z);
    let wl=min(0.9,w-0.1);
    let yr=max(curve([[2.17,-0.14],[1.6,-0.12],[-1.6,-0.1],[-2.17,-0.08]],z),yb+0.08);
    [[0.0,yb],[wl-0.06,yb],[wl,yb+0.05],[w-0.05,yr],[w,ys],[wbelt,ybelt],[wt,yrail],[wt-0.04,yt-0.008],[0.0,yt]]
}
fn length2(a,b) {sqrt((b[0]-a[0])**2+(b[1]-a[1])**2)}
fn along(a,b,d) {
    let l=length2(a,b);if l<0.000001 {return a;}
    [a[0]+(b[0]-a[0])*d/l,a[1]+(b[1]-a[1])*d/l]
}
fn half_section(z) {
    let p=station(z);let fillet=[0.0,0.03,0.03,0.025,0.012,0.02,0.015,0.03,0.0];
    let samples=[5,1,4,4,3,3,1,7];let d=[];let result=[];
    for i in 0..p.len() {
        d.push(if i==0 || i==p.len()-1 {0.0}else{min(fillet[i],min(0.4*length2(p[i-1],p[i]),0.4*length2(p[i],p[i+1])))});
    }
    for i in 0..p.len() {
        if i==0 || i==p.len()-1 {result.push([p[i][0],p[i][1],i*1.0]);}
        else {
            let lin=length2(p[i-1],p[i]);let lout=length2(p[i],p[i+1]);
            let s=along(p[i],p[i-1],d[i]);let e=along(p[i],p[i+1],d[i]);
            let u0=i-d[i]/max(lin,0.000001);let u1=i+d[i]/max(lout,0.000001);
            for k in 0..3 {
                let t=k/2.0;let a=(1.0-t)**2;let b=2.0*(1.0-t)*t;let c=t*t;
                result.push([a*s[0]+b*p[i][0]+c*e[0],a*s[1]+b*p[i][1]+c*e[1],u0+(u1-u0)*t]);
            }
        }
        if i==p.len()-1 {break;}
        let l=length2(p[i],p[i+1]);let from=d[i];let to=l-d[i+1];
        for k in 1..samples[i]+1 {
            let distance=from+(to-from)*k/(samples[i]+1.0);
            let v=along(p[i],p[i+1],max(0.0,distance));
            result.push([v[0],v[1],i+distance/max(l,0.000001)]);
        }
    }
    result
}
fn ring(z) {
    let half=half_section(z);let result=half;
    for n in 1..half.len()-1 {let p=half[half.len()-1-n];result.push([-p[0],p[1],p[2]]);}
    result
}
fn local(p,z) {[-p[0]*(1.99/2.02),p[1],-z*(4.5/4.34)]}
fn normal(a,b) {
    let n=[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
    let l=sqrt(n[0]*n[0]+n[1]*n[1]+n[2]*n[2]);
    if l==0.0 {throw "Degenerate body normal";}
    [n[0]/l,n[1]/l,n[2]/l]
}
fn difference(a,b) {[a[0]-b[0],a[1]-b[1],a[2]-b[2]]}
fn mesh_plan(name,points,counts,indices,normals,material) {
    let plan=assembly_builder::mesh_shape_plan("@root@","/Body/RevealShell",name,points,counts,indices,[0.88,0.89,0.9],false);
    if !plan.ok {throw plan.error;}
    let surface=assembly_builder::mesh_surface_attributes_plan("@root@",plan.path,normals,());
    if !surface.ok {throw surface.error;}
    for op in surface.ops {plan.ops.push(op);}
    plan.ops.push(#{SetRelationship:#{edit_target:"@root@",path:plan.path,name:"material:binding",targets:["/Body/Looks/"+material]}});
    plan
}
fn mix_vertex(a,b,t) {
    let p=[];let n=[];let uv=[];
    for i in 0..3 {p.push(a[0][i]+(b[0][i]-a[0][i])*t);n.push(a[1][i]+(b[1][i]-a[1][i])*t);}
    for i in 0..2 {uv.push(a[2][i]+(b[2][i]-a[2][i])*t);}
    [p,n,uv]
}
fn in_arch(v,z) {
    abs(v[0][0])>0.64 && v[2][0]<4.4
        && (v[0][1]+0.145)**2+(v[0][2]-z)**2<0.43**2
}
fn arch_boundary(a,b,z) {
    let dy=b[0][1]-a[0][1];let dz=b[0][2]-a[0][2];
    let y=a[0][1]+0.145;let zz=a[0][2]-z;
    let aa=dy*dy+dz*dz;let bb=2.0*(y*dy+zz*dz);let cc=y*y+zz*zz-0.43*0.43;
    let candidates=[];
    if aa>0.0 {
        let discriminant=bb*bb-4.0*aa*cc;
        if discriminant>=0.0 {
            let root=sqrt(max(0.0,discriminant));
            candidates.push((-bb-root)/(2.0*aa));candidates.push((-bb+root)/(2.0*aa));
        }
    }
    let dx=abs(b[0][0])-abs(a[0][0]);let du=b[2][0]-a[2][0];
    if abs(dx)>0.0000001 {candidates.push((0.64-abs(a[0][0]))/dx);}
    if abs(du)>0.0000001 {candidates.push((4.4-a[2][0])/du);}
    for t in candidates {
        if t>= -0.000001 && t<=1.000001 {
            if in_arch(mix_vertex(a,b,t-0.000001),z)!=in_arch(mix_vertex(a,b,t+0.000001),z) {
                return mix_vertex(a,b,min(1.0,max(0.0,t)));
            }
        }
    }
    throw "Wheel arch edge has no geometric intersection";
}
fn clip_arch(poly,z) {
    let out=[];
    for i in 0..poly.len() {
        let a=poly[i];let b=poly[(i+1)%poly.len()];let ai=in_arch(a,z);let bi=in_arch(b,z);
        if !ai {out.push(a);}
        if ai!=bi {out.push(arch_boundary(a,b,z));}
    }
    out
}
fn boundary(v,kind) {
    let u=v[2][0];let z=v[2][1];let ax=abs(v[0][0])/(1.99/2.02);
    if kind=="trim" {return u-3.0-min(0.88,max(0.0,(-1.66-z)*3.2));}
    if kind=="side_low" {return u-5.03;}
    if kind=="side_high" {return 5.97-u;}
    if kind=="side_front" {return 1.1-z;}
    if kind=="side_rear" {return z+1.1;}
    if kind=="roof_low" {return u-7.05;}
    if kind=="roof_front" {return 1.5-max(0.0,ax-0.34)*0.95-z;}
    if kind=="roof_rear" {return z+1.82-max(0.0,ax-0.3)*0.8;}
    if kind=="tail_top" {return 0.33-v[0][1];}
    if kind=="tail_bottom" {return v[0][1]-0.055;}
    if kind=="tail_side" {return 0.8-ax;}
    throw "Unknown body surface boundary";
}
fn half_polygon(poly,kind,positive) {
    let out=[];
    for i in 0..poly.len() {
        let a=poly[i];let b=poly[(i+1)%poly.len()];
        let av=boundary(a,kind);let bv=boundary(b,kind);
        let ai=if positive {av>=0.0}else{av<0.0};let bi=if positive {bv>=0.0}else{bv<0.0};
        if ai {out.push(a);}
        if ai!=bi {out.push(mix_vertex(a,b,av/(av-bv)));}
    }
    out
}
fn carve(poly,planes) {
    let inside=poly;let outside=[];
    for plane in planes {
        if inside.len()<3 {break;}
        let rest=half_polygon(inside,plane,false);if rest.len()>=3 {outside.push(rest);}
        inside=half_polygon(inside,plane,true);
    }
    #{inside:inside,outside:outside}
}
fn material_polygons(poly) {
    let result=[];
    if poly[0][2][0]>8.5 {
        let tail=carve(poly,["tail_top","tail_bottom","tail_side"]);
        if tail.inside.len()>=3 {result.push(#{material:"White",poly:tail.inside});}
        for p in tail.outside {result.push(#{material:"Carbon",poly:p});}
        return result;
    }
    let black=half_polygon(poly,"trim",false);
    if black.len()>=3 {result.push(#{material:"Carbon",poly:black});}
    let paint=half_polygon(poly,"trim",true);if paint.len()<3 {return result;}
    let side=carve(paint,["side_low","side_high","side_front","side_rear"]);
    if side.inside.len()>=3 {result.push(#{material:"SideGlass",poly:side.inside});}
    for candidate in side.outside {
        let roof=carve(candidate,["roof_low","roof_front","roof_rear"]);
        if roof.inside.len()>=3 {result.push(#{material:"Glass",poly:roof.inside});}
        for p in roof.outside {result.push(#{material:"White",poly:p});}
    }
    result
}
// Most triangles are wholly inside one surface. Only boundary triangles need
// polygon clipping; prove containment/exclusion against the same half-planes.
fn region_status(poly,planes) {
    let contained=true;
    for plane in planes {
        let negative=0;
        for v in poly {if boundary(v,plane)<0.0 {negative+=1;}}
        if negative==poly.len() {return -1;}
        if negative>0 {contained=false;}
    }
    if contained {1}else{0}
}
fn quick_material(poly) {
    if poly[0][2][0]>8.5 {
        let status=region_status(poly,["tail_top","tail_bottom","tail_side"]);
        return if status==1 {"White"}else if status== -1 {"Carbon"}else{""};
    }
    let trim=region_status(poly,["trim"]);
    if trim== -1 {return "Carbon";}if trim==0 {return "";}
    let side=region_status(poly,["side_low","side_high","side_front","side_rear"]);
    if side==1 {return "SideGlass";}if side==0 {return "";}
    let roof=region_status(poly,["roof_low","roof_front","roof_rear"]);
    if roof==1 {return "Glass";}if roof==0 {return "";}
    "White"
}
fn surface_plans(name,vertices,triangles) {
    let groups=#{};
    for triangle in triangles {
        let poly=[vertices[triangle[0]],vertices[triangle[1]],vertices[triangle[2]]];
        poly=clip_arch(poly,-1.375);if poly.len()<3 {continue;}
        poly=clip_arch(poly,1.375);if poly.len()<3 {continue;}
        let material=quick_material(poly);
        let regions=if material!="" {[#{material:material,poly:poly}]}else{material_polygons(poly)};
        for region in regions {
        let material=region.material;poly=region.poly;
        if !groups.contains(material) {groups[material]=#{points:[],normals:[],indices:[],counts:[],lookup:#{}};}
        let group=groups[material];let face=[];
        for v in poly {
            let p=v[0];let key=p[0]+"/"+p[1]+"/"+p[2];
            if !group.lookup.contains(key) {
                group.lookup[key]=group.points.len();group.points.push(p);
                let n=v[1];let length=sqrt(n[0]*n[0]+n[1]*n[1]+n[2]*n[2]);
                group.normals.push([n[0]/length,n[1]/length,n[2]/length]);
            }
            face.push(group.lookup[key]);
        }
        for i in 1..face.len()-1 {
            let a=group.points[face[0]];let b=group.points[face[i]];let c=group.points[face[i+1]];
            let ab=difference(b,a);let ac=difference(c,a);
            let cross=[ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]];
            let area_squared=cross[0]*cross[0]+cross[1]*cross[1]+cross[2]*cross[2];
            if area_squared==0.0 {continue;}
            group.counts.push(3);for index in [face[0],face[i],face[i+1]] {group.indices.push(index);}
        }
        groups[material]=group;
        }
    }
    let ops=[];
    for material in ["White","Carbon","Glass","SideGlass"] {
        if !groups.contains(material) {continue;}
        let g=groups[material];if g.counts.is_empty() {continue;}
        let p=mesh_plan(name+material,g.points,g.counts,g.indices,g.normals,material);
        for op in p.ops {ops.push(op);}
    }
    #{ok:true,path:"/Body/RevealShell/"+name,ops:ops}
}
// Small native mesh sections keep typed authoring inside the shared sandbox.
// Adjacent sections use identical ring coordinates and differential normals.
fn chunk_plan(index) {
    let first=index;let last=min(220,first+1);
    if first>=220 {throw "Body chunk index is outside the authored station grid";}
    let points=[];let normals=[];let uv=[];let counts=[];let indices=[];let width=0;
    let sections=[];
    for i in first-1..last+2 {sections.push(ring(2.17-4.34*i/220.0));}
    for i in first..last+1 {
        let z=2.17-4.34*i/220.0;let section=sections[i-first+1];let before=sections[i-first];let after=sections[i-first+2];width=section.len();
        for j in 0..width {
            let left=local(section[(j+width-1)%width],z);let right=local(section[(j+1)%width],z);
            let longitudinal=difference(local(after[j],z-4.34/220.0),local(before[j],z+4.34/220.0));
            points.push(local(section[j],z));normals.push(normal(longitudinal,difference(right,left)));uv.push([section[j][2],z]);
        }
    }
    for i in 0..last-first {
        for j in 0..width {
            let a=i*width+j;let b=(i+1)*width+j;let j2=(j+1)%width;
            counts.push(3);counts.push(3);
            for v in [a,b,i*width+j2,i*width+j2,b,(i+1)*width+j2] {indices.push(v);}
        }
    }
    let vertices=[];for i in 0..points.len() {vertices.push([points[i],normals[i],uv[i]]);}
    let triangles=[];for i in 0..indices.len()/3 {triangles.push([indices[i*3],indices[i*3+1],indices[i*3+2]]);}
    surface_plans("Panel"+(if index<10 {"0"}else{""})+index,vertices,triangles)
}
fn cap_plan(rear,part) {
    if part<0 || part>1 || (!rear && part!=0) {throw "Invalid body end-cap section";}
    let z=if rear {-2.17}else{2.17};let section=ring(z);
    let points=[];let uv=[];let normals=[];let counts=[];let indices=[];let center=[0.0,0.0,0.0];
    let u=if rear {9.0}else{4.2};let n=if rear {[0.0,0.0,1.0]}else{[0.0,0.0,-1.0]};
    for p in section {
        let v=local(p,z);points.push(v);uv.push([u,z]);normals.push(n);
        for i in 0..3 {center[i]+=v[i]/section.len();}
    }
    // The nose section is concave. Its vertex mean lies outside the visibility
    // kernel and would invert eight cap triangles. Intersect all edge half-planes
    // on the symmetry axis and choose an interior point for this star-shaped cap.
    let lower=-1.0e6;let upper=1.0e6;
    for j in 0..points.len() {
        let a=points[j];let b=points[(j+1)%points.len()];let dx=b[0]-a[0];let dy=b[1]-a[1];
        if dx>0.0 {upper=min(upper,a[1]-dy*a[0]/dx);}
        else if dx<0.0 {lower=max(lower,a[1]-dy*a[0]/dx);}
        else if dy*a[0]>0.0 {throw "Body cap has no symmetry-axis visibility kernel";}
    }
    if lower>=upper {throw "Body cap is not star-shaped about the symmetry axis";}
    center[0]=0.0;center[1]=(lower+upper)*0.5;
    let size=points.len();points.push(center);uv.push([u,z]);normals.push(n);
    let first=if rear {part*size/2}else{0};let last=if rear {(part+1)*size/2}else{size};
    for j in first..last {
        counts.push(3);let next=(j+1)%size;
        for v in if rear {[size,next,j]}else{[size,j,next]} {indices.push(v);}
    }
    let vertices=[];for i in 0..points.len() {vertices.push([points[i],normals[i],uv[i]]);}
    let triangles=[];for i in 0..indices.len()/3 {triangles.push([indices[i*3],indices[i*3+1],indices[i*3+2]]);}
    surface_plans(if rear {"RearCap"+(if part==0 {"L"}else{"R"})}else{"FrontCap"},vertices,triangles)
}

fn attr(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn prim(parent,name,kind) {
    #{AddPrim:#{edit_target:"@root@",parent_path:parent,name:name,type_name:kind,reference:(),reference_prim_path:()}}
}
// One continuous front signature, thick enough to remain readable in a wide
// course shot. The two photometric road projectors keep their existing power.
fn front_light_plan() {
    #{ok:true,ops:[
        attr("/Body/FrontDRL","points","point3f[]",
            "[(-0.7,0.035,-2.267),(0.7,0.035,-2.267),(0.7,0.061,-2.267),(-0.7,0.061,-2.267)]"),
        attr("/Body/FrontDRL","visibility","token","\"inherited\""),
        attr("/Body/HeadlightL","visibility","token","\"invisible\""),
        attr("/Body/HeadlightR","visibility","token","\"invisible\"")
    ]}
}
fn setup_plan(existing_paths) {
    let ops=[];
    for path in ["/Body/RevealShell","/Body/Looks/RevealFinish"] {
        if existing_paths.contains(path) {ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
    }
    ops.push(prim("/Body","RevealShell","Xform"));
    // Retire the separate cosmetic panels; mechanical and propulsion children stay.
    for name in ["Skin","GoldCanopy","SideWindowL","SideWindowR","APillarL","APillarR",
        "RoofRailL","RoofRailR","RearButtressL","RearButtressR","RoofSpine",
        "HeadlampSeamL0","HeadlampSeamL1","HeadlampSeamL2","HeadlampSeamR0","HeadlampSeamR1","HeadlampSeamR2"] {
        let path="/Body/"+name;
        if existing_paths.contains(path) {ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
    }
    ops.push(attr("/Body/RearWing","xformOp:translate","double3","(0.0,0.438,2.205)"));
    ops.push(attr("/Body/RearLightBar","xformOp:translate","double3","(0.0,0.375,2.263)"));
    ops.push(attr("/Body/Looks/RearLamp/Shader","inputs:emissiveColor","color3f","(8.0,0.03,0.06)"));
    for op in front_light_plan().ops {ops.push(op);}
    ops.push(#{SetPrimDocumentation:#{edit_target:"@root@",path:"/Body",
        documentation:"Procedural visual study; not Tesla CAD. Cross-section profile adapted from eduardmur/tesla-roadster-simulator body.ts, MIT, Copyright (c) 2026 Tesla Roadster Simulator contributors. Native USD material regions and geometric wheel openings; see references/body-style.md and references/licenses/tesla-roadster-simulator-MIT.txt. Physical colliders, wheel mounts and propulsion remain separate."}});
    #{ok:true,ops:ops}
}

// Dark inner liners prevent distant scenery showing through the wheel wells.
// These are cosmetic back walls, inboard of the existing tire collision shape.
fn wheelhouse_plan() {
    let ops=[];
    for side in [-1,1] {
        for axle in [-1,1] {
            let name="Wheelhouse"+(if side<0 {"L"}else{"R"})+(if axle<0 {"F"}else{"R"});
            let path="/Body/"+name;
            ops.push(prim("/Body",name,"Cylinder"));
            ops.push(attr(path,"radius","double","0.426"));
            ops.push(attr(path,"height","double","0.02"));
            ops.push(attr(path,"axis","token","\"X\""));
            ops.push(attr(path,"purpose","token","\"render\""));
            ops.push(attr(path,"xformOp:translate","double3",
                "("+(side*0.68)+", -0.145, "+(axle*1.375)+")"));
            ops.push(attr(path,"xformOpOrder","token[]","[\"xformOp:translate\"]"));
            ops.push(#{SetRelationship:#{edit_target:"@root@",path:path,name:"material:binding",targets:["/Body/Looks/Carbon"]}});
        }
    }
    #{ok:true,ops:ops}
}
