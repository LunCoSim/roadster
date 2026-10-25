// Continuous 1.4 m LED bar, represented by nine overlapping native optical
// segments. Visual study, not measured Tesla photometry. Total power: 120 W.
fn attribute(path,name,type_name,value) {
    #{SetAttribute:#{edit_target:"@root@",path:path,name:name,type_name:type_name,value:value}}
}
fn plan(existing_paths) {
    let ops=[];
    for name in ["HeadlampL","HeadlampR","FrontLightbar"] {
        let path="/Roadster/"+name;
        if existing_paths.contains(path) {ops.push(#{RemovePrim:#{edit_target:"@root@",path:path}});}
    }
    let root="/Roadster/FrontLightbar";
    ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:"/Roadster",name:"FrontLightbar",type_name:"Xform",reference:(),reference_prim_path:()}});
    for i in 0..9 {
        let path=root+"/Segment"+i;
        ops.push(#{AddPrim:#{edit_target:"@root@",parent_path:root,name:"Segment"+i,type_name:"SphereLight",reference:(),reference_prim_path:()}});
        ops.push(#{SetApiSchemas:#{edit_target:"@root@",path:path,schemas:["ShapingAPI","ShadowAPI","LunCoLightAPI"]}});
        ops.push(attribute(path,"xformOp:translate","double3","("+(-0.7+0.175*i)+",0.048,-2.275)"));
        ops.push(attribute(path,"xformOp:rotateXYZ","double3","(-2.0,0.0,0.0)"));
        ops.push(attribute(path,"xformOpOrder","token[]","[\"xformOp:translate\",\"xformOp:rotateXYZ\"]"));
        ops.push(attribute(path,"inputs:normalize","bool","true"));
        ops.push(attribute(path,"inputs:intensity","float","29555.56"));
        ops.push(attribute(path,"inputs:radius","float","0.075"));
        ops.push(attribute(path,"inputs:color","color3f","(0.9,0.95,1.0)"));
        ops.push(attribute(path,"inputs:shaping:cone:angle","float","22.0"));
        ops.push(attribute(path,"inputs:shaping:cone:softness","float","0.35"));
        ops.push(attribute(path,"inputs:shadow:enable","bool","true"));
        ops.push(attribute(path,"lunco:light:range","float","120.0"));
        ops.push(#{SetConnection:#{edit_target:"@root@",path:path,name:"inputs:light_intensity",type_name:"float",sources:["/Roadster.outputs:headlight_intensity_lm"]}});
    }
    #{ok:true,ops:ops}
}
