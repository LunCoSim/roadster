// Cosmetic nose repair. All dimensions are metres in /Body's existing frame.
// Canonical station() remains the plan-view envelope; no physical owner edits.
fn width(z) {
    let station=reveal_body::station(-z*4.34/4.5);
    station[4][0]*(1.99/2.02)
}
fn plane_y(z) {
    let back=-2.25+32.0*4.5/220.0;
    let p=reveal_body::station(-back*4.34/4.5);
    0.054+(p[8][1]-0.054)*(z+2.25)/(back+2.25)
}
fn add_mesh(name,polys,material) {
    let points=[];let counts=[];let indices=[];let normals=[];
    for polygon in polys {
      for triangle in 1..polygon.len()-1 {
        let poly=[polygon[0],polygon[triangle],polygon[triangle+1]];
        let ab=reveal_body::difference(poly[1],poly[0]);let ac=reveal_body::difference(poly[2],poly[0]);
        let cross=[ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]];
        if cross[0]**2+cross[1]**2+cross[2]**2<1.0e-16 {continue;}
        let length=sqrt(cross[0]*cross[0]+cross[1]*cross[1]+cross[2]*cross[2]);
        if length<1.0e-8 {continue;}
        let normal=[cross[0]/length,cross[1]/length,cross[2]/length];
        counts.push(poly.len());
        for point in poly {indices.push(points.len());points.push(point);normals.push(normal);}
      }
    }
    let m=assembly_builder::mesh_shape_plan("@root@","/Body",name,points,counts,indices,[0.85,0.86,0.88],false);
    if !m.ok {throw m.error;}
    let attrs=assembly_builder::mesh_surface_attributes_plan("@root@",m.path,normals,());
    if !attrs.ok {throw attrs.error;}
    for op in attrs.ops {m.ops.push(op);}
    m.ops.push(#{SetAttribute:#{edit_target:"@root@",path:m.path,name:"doubleSided",type_name:"bool",value:"true"}});
    m.ops.push(#{SetAttribute:#{edit_target:"@root@",path:m.path,name:"physics:collisionEnabled",type_name:"bool",value:"false"}});
    m.ops.push(#{SetRelationship:#{edit_target:"@root@",path:m.path,name:"material:binding",targets:["/Body/Looks/"+material]}});
    m.ops
}
fn mirror(p,side) {[side*p[0],p[1],p[2]]}
fn mix(a,b,t) {[a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1]),a[2]+t*(b[2]-a[2])]}
fn ribbon(path,height) {
    let polys=[];
    for i in 0..path.len()-1 {
        let a=path[i];let b=path[i+1];
        polys.push([[a[0],a[1]-height/2.0,a[2]], [b[0],b[1]-height/2.0,b[2]],
                    [b[0],b[1]+height/2.0,b[2]], [a[0],a[1]+height/2.0,a[2]]]);
    }
    polys
}
fn geometry(existing_paths) {
    let ops=[];let parts=[];
    let names=["FrontMask","FrontSplitter","FrontDRL","NoseFascia","NoseHood","NoseFacets","NoseRecesses","NoseSeams","NoseSideReturns0","NoseSideReturns1","NoseSideReturns2","NoseSideReturns3","NoseRearJoin","NoseRearJoinL","NoseRearJoinR"];
    for name in names {
        let path="/Body/"+name;
        if existing_paths.contains(path) {ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
    }
    // Replace only the cosmetic nose sheets. Wheel arches behind station 32,
    // the complete cabin, physical collider meshes and mount frames are retained.
    for i in 0..32 {
        for material in ["White","Carbon"] {
            if material=="Carbon" && i>=20 {continue;}
            let path="/Body/RevealShell/Panel"+(if i<10 {"0"}else{""})+i+material;
            if existing_paths.contains(path) {ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
        }
    }
    for name in ["FrontCapWhite","FrontCapCarbon"] {
        let path="/Body/RevealShell/"+name;
        if existing_paths.contains(path) {ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
    }
    // Inset contour follows exactly the same station width as the body shell.
    let half=[];
    for z in [-2.22,-2.17,-2.08,-1.98,-1.88,-1.84] {
        let p=reveal_body::station(-z*4.34/4.5);
        half.push([width(z)-0.024,max(0.035,p[4][1]-0.02),z]);
    }
    let outline=[];
    for i in 0..half.len() {outline.push(mirror(half[half.len()-1-i],-1.0));}
    outline.push([0.0,0.035,-2.222]);
    for p in half {outline.push(p);}
    let fascia=[];let lower=[];
    for p in outline {
        lower.push([p[0]*(1.0-0.045/max(0.1,abs(p[0]))),-0.215,p[2]+0.075]);
    }
    for i in 0..outline.len()-1 {fascia.push([outline[i],outline[i+1],lower[i+1],lower[i]]);}
    parts.push(#{name:"NoseFascia",polys:fascia,material:"Carbon"});
    // A thin wrapped blade, entirely within the shell silhouette. Its chord
    // tapers to 15 mm at each side, unlike the retired full-width Cube.
    let outer=[];let inner=[];
    for i in 0..outline.len() {
        let p=outline[i];let side_fraction=abs(i-(outline.len()-1)/2.0)/((outline.len()-1)/2.0);
        let chord=0.14*(1.0-side_fraction)+0.015*side_fraction;
        let oz=p[2]-0.006;
        let ox=if abs(p[0])<0.001 {0.0}else{(if p[0]<0.0 {-1.0}else{1.0})*(width(oz)-0.024)};
        outer.push([ox,-0.238,oz]);
        inner.push([p[0]*0.985,-0.238,p[2]+chord]);
    }
    let blade=[];
    for i in 0..outer.len()-1 {
        let a=outer[i];let b=outer[i+1];let c=inner[i+1];let d=inner[i];
        blade.push([a,b,c,d]);
        blade.push([a,[a[0],a[1]-0.018,a[2]],[b[0],b[1]-0.018,b[2]],b]);
        blade.push([[d[0],d[1]-0.018,d[2]],[c[0],c[1]-0.018,c[2]],
                    [b[0],b[1]-0.018,b[2]],[a[0],a[1]-0.018,a[2]]]);
    }
    parts.push(#{name:"FrontSplitter",polys:blade,material:"Carbon"});
    let back=-2.25+32.0*4.5/220.0;
    let station=reveal_body::station(-back*4.34/4.5);
    let rear_x=station[7][0]*(1.99/2.02);
    let front_x=width(-2.235)-0.024;
    let front=[front_x,plane_y(-2.235),-2.235];
    let rear=[rear_x,plane_y(back),back];
    let hood=[mirror(rear,-1.0),mirror(front,-1.0),[0.0,plane_y(-2.25),-2.25],front,rear];
    parts.push(#{name:"NoseHood",polys:[hood],material:"White"});
    let facets=[];let recesses=[];let seam=[];let lights=[];
    for side in [-1.0,1.0] {
        let a=mirror(front,side);let c=mirror(rear,side);
        let b=[side*(width(-1.88)-0.004),0.205,-1.88];
        let d=[side*station[4][0]*(1.99/2.02),station[4][1],back];
        // Triangular opening is actual geometry: three surrounding panels and
        // an inset floor, not an emissive decal drawn over an unbroken surface.
        let center=[(a[0]+b[0]+c[0])/3.0,(a[1]+b[1]+c[1])/3.0,(a[2]+b[2]+c[2])/3.0];
        let ia=mix(center,a,0.68);let ib=mix(center,b,0.68);let ic=mix(center,c,0.68);
        facets.push([a,b,ib,ia]);facets.push([b,c,ic,ib]);facets.push([c,a,ia,ic]);
        facets.push([b,d,c]);
        let ra=[ia[0],ia[1]-0.012,ia[2]];let rb=[ib[0],ib[1]-0.012,ib[2]];let rc=[ic[0],ic[1]-0.012,ic[2]];
        recesses.push([ra,rb,rc]);recesses.push([ia,ib,rb,ra]);recesses.push([ib,ic,rc,rb]);recesses.push([ic,ia,ra,rc]);
        // Crisp dark panel seam runs from the lip up to the rear hood edge.
        let inset=[side*0.004,0.001,0.0];
        seam.push([a,c,[c[0]+inset[0],c[1]+inset[1],c[2]], [a[0]+inset[0],a[1]+inset[1],a[2]]]);
        // The visible signature turns upward and outboard into each recess.
        let lead=[a[0],a[1]+0.002,a[2]-0.003];
        let join=[ib[0],ib[1]+0.004,ib[2]-0.002];
        for poly in ribbon([lead,join,[ic[0],ic[1]+0.004,ic[2]-0.002]],0.010) {lights.push(poly);}
    }
    for poly in ribbon([[ -front_x,front[1]-0.004,front[2]-0.003],
        [0.0,0.050,-2.253],[front_x,front[1]-0.004,front[2]-0.003]],0.012) {lights.push(poly);}
    parts.push(#{name:"NoseFacets",polys:facets,material:"White"});
    parts.push(#{name:"NoseRecesses",polys:recesses,material:"Carbon"});
    parts.push(#{name:"NoseSeams",polys:seam,material:"Carbon"});
    parts.push(#{name:"FrontDRL",polys:lights,material:"Lamp"});
    #{ok:true,ops:ops,parts:parts,contract:#{fascia_inset_m:0.024,fascia_bottom_setback_m:0.075,splitter_thickness_m:0.018,collision_enabled:false}}
}

fn side_part(chunk) {
    let back=-2.25+32.0*4.5/220.0;
    let station=reveal_body::station(-back*4.34/4.5);
    let rear_x=station[7][0]*(1.99/2.02);
    let front=[width(-2.235)-0.024,plane_y(-2.235),-2.235];
    let rear=[rear_x,plane_y(back),back];
    let returns=[];let rear_join=[];
    for side in [-1.0,1.0] {
        let a=mirror(front,side);let c=mirror(rear,side);
        let b=[side*(width(-1.88)-0.004),0.205,-1.88];
        let d=[side*station[4][0]*(1.99/2.02),station[4][1],back];
        if chunk<4 {
        // Close the lower side to the retained shell trim. The upper edge
        // follows the two crisp corner planes instead of rounding over them.
        let strip=[];
        for i in chunk*8..chunk*8+9 {
            let z=-2.25+i*4.5/220.0;let st=reveal_body::station(-z*4.34/4.5);
            let low=[side*st[3][0]*(1.99/2.02),st[3][1],z];
            let shoulder=[side*st[4][0]*(1.99/2.02),st[4][1],z];
            let edge=if z<a[2] {[a[0],a[1],z]}else if z<b[2] {mix(a,b,(z-a[2])/(b[2]-a[2]))}else{mix(b,d,(z-b[2])/(d[2]-b[2]))};
            strip.push([low,shoulder,edge]);
        }
        for i in 0..strip.len()-1 {
            returns.push([strip[i][0],strip[i+1][0],strip[i+1][1],strip[i][1]]);
            returns.push([strip[i][1],strip[i+1][1],strip[i+1][2],strip[i][2]]);
        }
        }else{
        // The old shell ends in a rounded cross-section. Bridge that exact
        // boundary to the new flat hood so the seam has no see-through slit.
        let ring=reveal_body::half_section(-back*4.34/4.5);
        for i in 0..ring.len()-1 {
            let p=ring[i];let q=ring[i+1];if p[2]<4.0 {continue;}
            let px=side*p[0]*(1.99/2.02);let qx=side*q[0]*(1.99/2.02);
            let py=if abs(px)<=rear_x {rear[1]}else{rear[1]+(d[1]-rear[1])*(abs(px)-rear_x)/(abs(d[0])-rear_x)};
            let qy=if abs(qx)<=rear_x {rear[1]}else{rear[1]+(d[1]-rear[1])*(abs(qx)-rear_x)/(abs(d[0])-rear_x)};
            rear_join.push([[px,p[1],back],[qx,q[1],back],[qx,qy,back],[px,py,back]]);
        }
        }
    }
    if chunk==4 {return #{name:"NoseRearJoin",polys:rear_join,material:"White"};}
    let clipped=[];
    for poly in returns {
        let vertices=[];for point in poly {vertices.push([point,[0.0,1.0,0.0],[4.0,0.0]]);}
        let cut=reveal_body::clip_arch(vertices,-1.375);
        if cut.len()>=3 {let points=[];for v in cut {points.push(v[0]);}clipped.push(points);}
    }
    #{name:"NoseSideReturns"+chunk,polys:clipped,material:"White"}
}

// Bounded authoring steps: compute geometry separately from serialization so
// every native tool call stays within the standard Rhai execution budget.
fn part(index) {
    if index<7 {return geometry([]).parts[index];}
    if index<11 {return side_part(index-7);}
    if index>12 {throw "Nose part index must be 0..12";}
    let join=side_part(4);let half=join.polys.len()/2;let faces=[];
    let begin=if index==11 {0}else{half};
    for i in begin..begin+half {faces.push(join.polys[i]);}
    #{name:if index==11 {"NoseRearJoinL"}else{"NoseRearJoinR"},polys:faces,material:"White"}
}
