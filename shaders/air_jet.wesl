import bevy_pbr::render::{mesh_functions, forward_io::VertexOutput, mesh_view_bindings::{globals,view}};
import lunco::shaders::lunco_noise::{vnoise};

//! Shared Roadster jet visibility: 2.2x length, 1.6x far-field width and enhanced opacity.
//! Not a calibrated plume or CFD prediction. The live force still gates emission.
//! Cold-air mixing envelope. Modelica supplies nozzle radius, pressure expansion,
//! length and velocity. This shader integrates translucent mist inside a fixed
//! bounding frustum; it never paints the bounding surface as a solid cone.
//!@default force 0.0
//!@default direction 1.0
//!@default reference_force 30000.0
//!@default radius_start 0.04
//!@default radius_expanded 0.06
//!@default expansion_length 0.3
//!@default mixing_length 1.5
//!@default radius_end 0.16
//!@default exit_velocity 600.0
struct Material {
    force: f32,
    direction: f32,
    reference_force: f32,
    radius_start: f32,
    radius_expanded: f32,
    expansion_length: f32,
    mixing_length: f32,
    radius_end: f32,
    exit_velocity: f32,
}
@group(constants::MATERIAL_BIND_GROUP) @binding(0)
var<uniform> mat: Material;
@fragment
fn fragment(input: VertexOutput,@builtin(front_facing) front: bool) -> @location(0) vec4<f32> {
    let delivered=max(0.0,mat.force*mat.direction);
    if delivered<1.0 || !front { return vec4<f32>(0.0); }
    let inverse=mesh_functions::get_local_from_world(input.instance_index);
    let start=(inverse*vec4<f32>(input.world_position.xyz,1.0)).xyz;
    let eye=(inverse*vec4<f32>(view.world_position,1.0)).xyz;
    let ray=normalize(start-eye);
    let activity=clamp(delivered/mat.reference_force,0.0,1.0);
    var optical_depth=0.0;
    for(var i=0;i<32;i=i+1) {
        let p=start+ray*(0.08*(f32(i)+0.5));
        if p.y<0.0 || p.y>mat.mixing_length { continue; }
        let near=clamp(p.y/max(0.001,mat.expansion_length),0.0,1.0);
        let far=clamp((p.y-mat.expansion_length)/max(0.001,mat.mixing_length-mat.expansion_length),0.0,1.0);
        let radius=mix(mat.radius_start/1.6,mat.radius_expanded,near)+(mat.radius_end-mat.radius_expanded)*far;
        let normalized_radius=length(p.xz)/max(0.001,radius);
        if normalized_radius>1.8 { continue; }
        let distance=p.y/max(0.01,mat.mixing_length);
        let noise=vnoise(vec3<f32>(p.x*24.0,p.z*24.0,p.y*16.0-globals.time*mat.exit_velocity*0.04));
        let radial=exp(-2.0*normalized_radius*normalized_radius);
        let dilution=mat.radius_start/max(mat.radius_start,radius);
        let fade=1.0-smoothstep(0.65,1.0,distance);
        optical_depth+=0.08*radial*dilution*fade*(0.4+0.6*noise);
    }
    let alpha=(1.0-exp(-14.0*optical_depth))*sqrt(activity);
    return vec4<f32>(vec3<f32>(0.82,0.87,0.92),alpha);
}
