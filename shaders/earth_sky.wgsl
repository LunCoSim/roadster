//! Qualitative Earth daylight background; physics atmosphere is Modelica density.
#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput
#import bevy_pbr::utils::coords_to_viewport_uv
#import bevy_render::view::View
@group(0) @binding(0) var<uniform> view: View;
//!@default brightness 1.0
struct Material { brightness: f32, }
@group(#{MATERIAL_BIND_GROUP}) @binding(0) var<uniform> mat: Material;
@fragment
fn fragment(input: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let uv=coords_to_viewport_uv(input.position.xy,view.viewport);
    let h=view.view_from_clip*vec4<f32>(uv*vec2<f32>(2.0,-2.0)+vec2<f32>(-1.0,1.0),1.0,1.0);
    let direction=normalize((view.world_from_view*vec4<f32>(h.xyz/h.w,0.0)).xyz);
    let horizon=vec3<f32>(0.65,0.78,0.88);
    let zenith=vec3<f32>(0.045,0.22,0.55);
    let color=mix(horizon,zenith,pow(max(0.0,direction.y),0.35));
    return vec4<f32>(color*mat.brightness,1.0);
}
