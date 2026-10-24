// Canonical course ramp presentation. Preserve the authored Y/Z driving curve.
// Visual steelwork has no collider; the existing deck remains the contact owner.
fn attribute(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn tuple(value) {assembly_edit::tuple3_literal(value)}
fn beam(name,a,b,thickness) {
    let delta=vec3_from(b)-vec3_from(a);
    let length=vlen(delta);
    if length<0.001 {throw "Ramp beam requires distinct endpoints";}
    // All side members lie in Y/Z; transverse members lie on X.
    let transverse=abs(delta.x)>0.001;
    let rotation=if transverse {[0.0,90.0,0.0]}
        else {[-atan(delta.y,delta.z)*57.29577951308232,0.0,0.0]};
    let center=vec3_array((vec3_from(a)+vec3_from(b))*0.5);
    let scale=[thickness,thickness,length];
    let plan=assembly_builder::cube_plan("@root@","/World/RampSteel",name,
        1.0,center,rotation,scale,false);
    if !plan.ok {throw plan.error;}
    plan.ops.push(attribute(plan.shape,"primvars:displayColor","color3f[]","[(0.19, 0.23, 0.28)]"));
    plan.ops
}
fn width_plan() {
    let ops=[];
    ops.push(attribute("/World/StuntRamp","xformOp:scale","double3",tuple([5.0/14.0,1.0,1.0])));
    ops.push(attribute("/World/StuntRamp","xformOpOrder","token[]","[\"xformOp:scale\"]"));
    // Edge strip thickness is 0.15 m; the white centre stripe is unchanged.
    let factor=0.15/0.19;
    for side in [-1.0,1.0] {
        let path=if side<0.0 {"/World/RampEdgeL"}else{"/World/RampEdgeR"};
        ops.push(attribute(path,"xformOp:scale","double3",tuple([factor,1.0,1.0])));
        ops.push(attribute(path,"xformOp:translate","double3",tuple([side*(2.375-6.855*factor),0.012,0.012])));
        ops.push(attribute(path,"xformOpOrder","token[]","[\"xformOp:translate\",\"xformOp:scale\"]"));
    }
    #{ok:true,ops:ops}
}
fn steel_plan(profile,index) {
    if profile.len()<100 || profile.len()%2!=0 {throw "Expected paired native ramp centre vertices";}
    if index<0 {
        let ops=[#{AddPrim:#{edit_target:"@root@",parent_path:"/World",name:"RampSteel",
            type_name:"Xform",reference:(),reference_prim_path:""}}];
        ops.push(attribute("/World/RampSteel","primvars:displayColor","color3f[]","[(0.19, 0.23, 0.28)]"));
        return #{ok:true,ops:ops};
    }
    // Leave the return deck's upper landing surface unobstructed.
    if index>14 {throw "Ramp frame bay index must be 0..14";}
    let ops=[];
    let inner=[];let outer=[];let n=profile.len()/2;
    for i in 0..21 {
        let index=min(n-1,(i*(n-1)/20).to_int());
        let p=profile[index*2];
        let prev=profile[max(0,index-1)*2];let next=profile[min(n-1,index+1)*2];
        let dy=next[1]-prev[1];let dz=next[2]-prev[2];let length=sqrt(dy*dy+dz*dz);
        if length<0.001 {throw "Ramp curve tangent is singular";}
        // Outward from the driving face, behind the 0.6 m concrete slab.
        inner.push([p[1]+dz/length*0.72,p[2]-dy/length*0.72]);
        outer.push([p[1]+dz/length*1.65,p[2]-dy/length*1.65]);
    }
    if index<20 {for side in [-1.0,1.0] {
        let x=side*2.1;let prefix=if side<0.0 {"L"}else{"R"};
        for i in index..index+1 {
            let a=inner[i];let b=inner[i+1];let c=outer[i];let d=outer[i+1];
            for op in beam(prefix+"Inner"+i,[x,a[0],a[1]],[x,b[0],b[1]],0.1) {ops.push(op);}
            for op in beam(prefix+"Outer"+i,[x,c[0],c[1]],[x,d[0],d[1]],0.12) {ops.push(op);}
            for op in beam(prefix+"Brace"+i,[x,a[0],a[1]],[x,d[0],d[1]],0.075) {ops.push(op);}
            for op in beam(prefix+"Web"+i,[x,a[0],a[1]],[x,c[0],c[1]],0.075) {ops.push(op);}
        }
    }}
    for i in index..index+1 {
        let p=outer[i];
        for op in beam("Cross"+i,[-2.1,p[0],p[1]],[2.1,p[0],p[1]],0.09) {ops.push(op);}
    }
    #{ok:true,ops:ops}
}
fn appearance_plan(existing) {
    let ops=[];
    for i in 0..21 {
        let names=["Cross"+i];
        if i<20 {for side in ["L","R"] {for member in ["Inner","Outer","Brace","Web"] {
            names.push(side+member+i);
        }}}
        for name in names {
            let path="/World/RampSteel/"+name;
            if !existing.contains(path) {throw "Missing authored ramp frame member: "+path;}
            if i>14 {
                ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});
            } else {
                ops.push(attribute(path+"/Shape","primvars:displayColor","color3f[]","[(0.19, 0.23, 0.28)]"));
            }
        }
    }
    #{ok:true,ops:ops}
}
