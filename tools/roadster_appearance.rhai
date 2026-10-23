//! Shared Roadster appearance. Author into canonical components, never a film layer.
//! Exhaust is enhanced for visibility, not calibrated CFD; force gates emission.
fn attr(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn plan(component) {
    let ops=[];
    if component=="Body" {
        for material in ["White","Glass"] {
            let path="/Body/Looks/"+material+"/Shader";
            ops.push(attr(path,"inputs:clearcoat","float","0.8"));
            ops.push(attr(path,"inputs:clearcoatRoughness","float","0.08"));
        }
    } else if component=="RearThrusters" || component=="PerimeterThrusters" {
        let count=if component=="RearThrusters" {4}else{6};
        for index in 0..count {
            let path="/"+component+"/Jet"+index;
            ops.push(attr(path,"xformOp:scale","double3","(1.6, 2.2, 1.6)"));
            ops.push(attr(path,"xformOpOrder","token[]",
                "[\"xformOp:translate\", \"xformOp:rotateXYZ\", \"xformOp:scale\"]"));
        }
    } else {throw "Unknown Roadster appearance component: "+component;}
    #{ok:true,ops:ops,scope:component,
      note:"Shared appearance only; no force, flow, nozzle area or suspension edits"}
}
