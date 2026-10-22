//! Crowned visual mesh under an analytical raycast wheel mount.
//! Dimensions are explicit caller assumptions; the caller owns wheel dynamics.
fn ui_label() { "Crowned tire profile" }
fn ui_hint() { "plan(layer, parent, name, radius_m, width_m, shoulder_drop_m, rings, segments, axis) returns a wheel mount and crowned visual geometry" }
fn profile(radius_m,width_m,shoulder_drop_m,rings,segments,axis) {
    if !(radius_m>0.0) || !(width_m>0.0) || !(shoulder_drop_m>0.0)
        || !(shoulder_drop_m<radius_m) || rings<5 || rings>65 || rings%2!=1
        || segments<16 || segments>512 || !(axis in ["X","Y","Z"]) {
        return #{ok:false,error:"Positive radius/width, 0 < shoulder drop < radius, odd 5..65 rings, 16..512 segments and X/Y/Z axis required"};
    }
    let meridian=[[0.0,-width_m/2.0]];
    for i in 0..rings {
        let u=-1.0+2.0*f64_from(i)/f64_from(rings-1);
        let radius=radius_m-shoulder_drop_m+shoulder_drop_m*sqrt(max(0.0,1.0-u*u));
        meridian.push([radius,u*width_m/2.0]);
    }
    meridian.push([0.0,width_m/2.0]);
    let axis_direction=if axis=="X" {[1.0,0.0,0.0]} else if axis=="Z" {[0.0,0.0,1.0]} else {[0.0,1.0,0.0]};
    #{ok:true,profile:meridian,axis:axis_direction,
      facts:#{radius_m:radius_m,width_m:width_m,shoulder_drop_m:shoulder_drop_m,
        axis:axis,rings:rings,segments:segments,
        radial_chord_error_m:radius_m*(1.0-cos(3.141592653589793/f64_from(segments))),
        fidelity:"Analytical raycast contact and crowned visual profile; no rubber carcass or manufacturer calibration"}}
}
fn plan(layer,parent,name,radius_m,width_m,shoulder_drop_m,rings,segments,axis) {
    let shape=profile(radius_m,width_m,shoulder_drop_m,rings,segments,axis);
    if !shape.ok {return shape;}
    let path=parent+"/"+name;
    let visual=path+"/CrownedVisual";
    let ops=[
      #{AddPrim:#{edit_target:layer,parent_path:parent,name:name,
        type_name:"Xform",reference:(),reference_prim_path:()}},
      #{SetAttribute:#{edit_target:layer,path:path,name:"purpose",type_name:"token",value:"\"default\""}},
      #{AddPrim:#{edit_target:layer,parent_path:path,name:"CrownedVisual",
        type_name:"Mesh",reference:(),reference_prim_path:()}},
      #{RevolveProfileMesh:#{edit_target:layer,path:visual,profile:shape.profile,
        axis:shape.axis,angular_segments:segments,normal_crease_angle_deg:35.0,
        display_color:[0.025,0.025,0.028],collision_enabled:false}},
      #{SetApiSchemas:#{edit_target:layer,path:visual,schemas:["VisibilityAPI"]}},
      #{SetAttribute:#{edit_target:layer,path:visual,name:"purpose",type_name:"token",value:"\"render\""}},
      #{SetAttribute:#{edit_target:layer,path:visual,name:"renderVisibility",type_name:"token",value:"\"visible\""}}
    ];
    for name in ["points","normals","faceVertexCounts","faceVertexIndices",
        "subdivisionScheme","primvars:st","primvars:st:indices","physics:approximation"] {
        ops.push(#{RemoveAttribute:#{edit_target:layer,path:path,name:name}});
    }
    #{ok:true,ops:ops,facts:shape.facts}
}
