import bevy_pbr::render::{mesh_functions,forward_io::VertexOutput};
import lunco::shaders::pbr_lit::{lit};

//! Counter-rotating blower rotor, driven by integrated Modelica shaft angle.
//!@default angle 0.0
//!@default rpm 0.0
struct Material { angle: f32, rpm: f32, }
@group(constants::MATERIAL_BIND_GROUP) @binding(0)
var<uniform> mat: Material;
@fragment
fn fragment(input: VertexOutput,@builtin(front_facing) front: bool) -> @location(0) vec4<f32> {
    let p=(mesh_functions::get_local_from_world(input.instance_index)*vec4<f32>(input.world_position.xyz,1.0)).xyz;
    let r=length(p.xy);
    let theta=atan2(p.y,p.x)-mat.angle;
    let blade=fract((theta+r*3.0)*8.0/6.28318530718)<0.42;
    var color=select(vec3<f32>(0.015,0.02,0.025),vec3<f32>(0.055,0.065,0.075),blade);
    if r<0.055 {color=vec3<f32>(0.022,0.026,0.030);}
    color=mix(vec3<f32>(0.012,0.016,0.020),color,clamp(abs(mat.rpm)/3000.0,0.0,1.0));
    return lit(input,front,color,0.35,0.7,vec3<f32>(0.0));
}
