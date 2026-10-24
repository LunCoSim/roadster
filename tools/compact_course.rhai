//! Course-layout authoring only. Vehicle forces and the obstacle/ramp geometry
//! remain owned by their shared models. The document owner applies this plan.
fn attr(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn set_z(doc,path,z) {
    let prim=query("QueryUsdPrim",#{doc_id:doc,path:path});
    if prim.type_name=="" || !prim.attrs.contains("xformOp:translate") {
        throw "Course-layout prim has no authored translation: "+path;
    }
    let p=prim.attrs["xformOp:translate"];
    attr(path,"xformOp:translate","double3",
        "("+p[0].to_string()+", "+p[1].to_string()+", "+z.to_string()+")")
}
fn plan(params) {
    let doc=params.doc_id;
    let start=params.start_z_m;
    let launch=params.launch_z_m;
    let refill=params.first_refill_z_m;
    // Keep the finite-width service pad between the gate and the existing
    // -72 m takeoff. This is layout admission, not a physics success claim.
    if start<=launch || launch<=refill+16.0 || refill<= -64.0 {
        throw "Course order must be start, launch gate, service pad, takeoff";
    }
    let ops=[set_z(doc,"/World/Roadster",start),
        set_z(doc,"/World/CourseStart",start-3.0),
        attr("/World/Roadster","inputs:course_launch_gate_z","double",launch.to_string()),
        attr("/World/Roadster","inputs:course_first_refill_z","double",refill.to_string())];
    for name in ["LaunchGateL","LaunchGateR","LaunchGateTop"] {
        ops.push(set_z(doc,"/World/"+name,launch));
    }
    for name in ["RefillPad0","RefillRail00","RefillRail01"] {
        ops.push(set_z(doc,"/World/"+name,refill));
    }
    for side in ["0","1"] {
        ops.push(set_z(doc,"/World/RefillMarker0"+side+"0",refill-8.0));
        ops.push(set_z(doc,"/World/RefillMarker0"+side+"1",refill+8.0));
    }
    #{ok:true,ops:ops,start_z_m:start,launch_z_m:launch,
      first_refill_z_m:refill,takeoff_z_m:-72.0,
      launch_to_takeoff_m:launch+72.0}
}
