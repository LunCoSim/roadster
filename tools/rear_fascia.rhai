//! Shared cosmetic rear closure; no collider, nozzle or force changes.
fn attr(path,name,kind,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:kind,value:value}}
}
fn plan() {
    let path="/Body/RearFasciaSurround";
    let ops=[#{AddPrim:#{edit_target:"@root@",parent_path:"/Body",name:"RearFasciaSurround",
        type_name:"Mesh",reference:(),reference_prim_path:""}}];
    // Body-colored closure makes the rear visibly solid around the four
    // dark nozzle housings, rather than resembling an open black cavity.
    ops.push(#{SetRelationship:#{edit_target:"@root@",path:"/Body/RearMask",name:"material:binding",targets:["/Body/Looks/White"]}});
    ops.push(attr(path,"points","point3f[]",
        "[(-0.90,0.235,2.264),(-0.73,0.12,2.275),(-0.71,-0.265,2.275),(-0.81,-0.265,2.264), (0.90,0.235,2.264),(0.81,-0.265,2.264),(0.71,-0.265,2.275),(0.73,0.12,2.275), (-0.90,0.235,2.264),(0.90,0.235,2.264),(0.73,0.12,2.275),(-0.73,0.12,2.275)]"));
    ops.push(attr(path,"faceVertexCounts","int[]","[4,4,4]"));
    ops.push(attr(path,"faceVertexIndices","int[]","[0,1,2,3,4,5,6,7,8,9,10,11]"));
    ops.push(attr(path,"subdivisionScheme","token","\"none\""));
    ops.push(attr(path,"doubleSided","bool","true"));
    ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["MaterialBindingAPI"]}});
    ops.push(#{SetRelationship:#{edit_target:"@root@",path:path,name:"material:binding",targets:["/Body/Looks/White"]}});
    ops
}
