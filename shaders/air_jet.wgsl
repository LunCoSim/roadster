//! Cold compressed-air jet indicator: a translucent white condensation cue.
//! Visibility follows delivered Modelica force, never a key or requested valve.
//! The time-advection is presentation only; it supplies no vehicle force.
#import bevy_pbr::{mesh_functions, forward_io::VertexOutput, mesh_view_bindings::globals}
#import lunco::noise::vnoise
//!@default force 0.0
//!@default direction 1.0
//!@default reference_force 30000.0
struct Material {
    force: f32,
    direction: f32,
    reference_force: f32,
}
@group(#{MATERIAL_BIND_GROUP}) @binding(0)
var<uniform> mat: Material;
@fragment
fn fragment(input: VertexOutput) -> @location(0) vec4<f32> {
    let delivered = max(0.0, mat.force * mat.direction);
    if delivered < 1.0 { return vec4<f32>(0.0); }
    let activity = clamp(delivered / mat.reference_force, 0.0, 1.0);
    let p = (mesh_functions::get_local_from_world(input.instance_index) * vec4<f32>(input.world_position.xyz,1.0)).xyz;
    let axial = clamp(p.y + 0.5, 0.0, 1.0);
    let flow = vnoise(vec3<f32>(p.x*13.0,p.z*13.0,axial*17.0-globals.time*28.0));
    let fade = 1.0-smoothstep(0.25+0.7*sqrt(activity),1.0,axial);
    let bands = 0.55+0.45*sin(axial*52.0-globals.time*55.0);
    let alpha = 0.48*sqrt(activity)*fade*(0.35+0.65*flow)*(0.8+0.2*bands);
    return vec4<f32>(vec3<f32>(1.0,1.08,1.15),alpha);
}
