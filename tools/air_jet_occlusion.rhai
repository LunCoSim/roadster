// Mounted Avian clearance observations drive the shared mist shader.
// Sensor and material own separate entities; this adds no actuator or force.
fn attr(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn plan(root,count,phase) {
    if count<1 || count>12 {throw "Expected an explicit set of jet meshes";}
    if phase!="sensors" && phase!="wires" {throw "Author and admit sensors before their connections";}
    let ops=[];
    if phase=="sensors" {
        let materials=if count==4 {["Rear"]}else{["Lift","Left","Right"]};
        for material in materials {
            let shader=root+"/Looks/"+material+"/Surface";
            ops.push(attr(shader,"inputs:surface_distance","float","12.0"));
            ops.push(attr(shader,"inputs:surface_hit_valid","float","0.0"));
        }
    }
    for i in 0..count {
        let path=root+"/Jet"+i;let probe=path+"/OcclusionProbe";
        if phase=="sensors" {
            ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
            ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:path,name:"OcclusionProbe",
                type_name:"Xform",reference:"./SurfaceProbe.usda",reference_prim_path:()}});
            ops.push(attr(probe,"lunco:raycast:axis","token","\"Y\""));
            ops.push(attr(probe,"lunco:raycast:maxDistance","float","12.0"));
        } else {
            for wire in [["surface_distance","ray_distance"],["surface_hit_valid","ray_hit_valid"]] {
                ops.push(attr(path,"inputs:"+wire[0],"float","0.0"));
                ops.push(#{SetConnection:#{edit_target:"@root@",path:path,name:"inputs:"+wire[0],
                    type_name:"float",sources:[probe+".outputs:"+wire[1]]}});
            }
        }
    }
    #{ok:true,ops:ops}
}
