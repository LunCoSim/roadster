// Run with an explicit, inspected `doc` in the native command context.
// Roadster dimensions are study assumptions; contact is raycast, tread is visual.
import "crowned_tire" as tire;
import "assembly_edit" as assembly_edit;
let before=query("InspectUsdDocument",#{doc_id:doc,path:"/Roadster"});
let ops=[];
for corner in ["FL","FR","RL","RR"] {
    let name="Wheel_"+corner;
    let path="/Roadster/"+name;
    let current=query("QueryUsdPrim",#{doc_id:doc,path:path,attrs:[]});
    if current.type_name==() {throw("Missing exact wheel: "+path);}
    let profile=tire::plan("@root@","/Roadster",name,0.34,
        if corner.starts_with("F") {0.25} else {0.30},0.04,17,256,"X");
    if !profile.ok {throw(profile.error);}
    print(#{path:path,profile:profile.facts});
    for op in profile.ops {ops.push(op);}
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:[
        "PhysxVehicleWheelAttachmentAPI","PhysxVehicleWheelAPI"]}});
}
print(assembly_edit::batch(doc,"Raycast Roadster wheel mounts and crowned visuals",ops,before.generation));
// Read back the new generation in the next command turn before saving.
