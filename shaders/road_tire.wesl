import bevy_pbr::render::{
    forward_io::VertexOutput,
    pbr_types,
    pbr_functions,
    mesh_bindings::mesh,
    mesh_types,
    mesh_view_bindings::view,
    mesh_functions,
};

//! Crowned Roadster tire: mesh-local axle coordinates drive rim and tread.
//! The visual meridian is independent of the analytic collision cylinder.
//! Mesh-local positions keep the pattern attached while the wheel rolls and
//! avoid depending on a particular primitive generator's cap UV convention.

const TAU: f32 = 6.28318530718;

//!@ui      rim_color   color "Rim / spoke colour"
//!@default rim_color   0.12,0.13,0.14
//!@ui      tire_color  color "Tire colour"
//!@default tire_color  0.05,0.05,0.06
//!@ui      spoke_count 1 16   "Spoke count"
//!@default spoke_count 6
//!@ui      tread_lugs  4 48   "Tread lugs"
//!@default tread_lugs  24
//!@ui      spoke_width 0.05 0.9 "Spoke width (of sector)"
//!@default spoke_width 0.35
//!@ui      lug_depth   0 1 "Lug relief depth"
//!@default lug_depth   0.6
//!@ui      wear        0 1 "Tread wear"
//!@default wear        0.15
//!@ui      wheel_radius 0.01 2.0 "Visual tire radius (m)"
//!@default wheel_radius 0.34
//!@default axle_axis 1.0,0.0,0.0
struct Material {
    rim_color:   vec3<f32>,
    spoke_count: f32,
    tire_color:  vec3<f32>,
    tread_lugs:  f32,
    spoke_width: f32,
    lug_depth:   f32,
    wear:        f32,
    wheel_radius: f32,
    axle_axis: vec3<f32>,
}

@group(constants::MATERIAL_BIND_GROUP) @binding(0)
var<uniform> mat: Material;

@fragment
fn fragment(input: VertexOutput, @builtin(front_facing) is_front: bool) -> @location(0) vec4<f32> {
    let spoke_count = mat.spoke_count;
    let lug_count   = mat.tread_lugs;
    let spoke_w     = mat.spoke_width;

    let rubber = mat.tire_color;                          // dark tire
    let metal  = mat.rim_color;                           // bright spoke/rim
    let tread  = mix(mat.tire_color, mat.rim_color, 0.22); // subtle lug highlight (reads as rubber)

    let m = mesh_functions::get_world_from_local(input.instance_index);
    let local_position = (mesh_functions::get_local_from_world(input.instance_index)
        * input.world_position).xyz;
    let n_local = normalize(transpose(mat3x3<f32>(m[0].xyz,m[1].xyz,m[2].xyz))
        * normalize(input.world_normal));
    let axle = normalize(mat.axle_axis);
    let reference = select(vec3<f32>(0.0,1.0,0.0),vec3<f32>(0.0,0.0,1.0),abs(axle.y)>0.9);
    let radial_u = normalize(cross(axle,reference));
    let radial_v = cross(axle,radial_u);
    let radial = vec2<f32>(dot(local_position,radial_u),dot(local_position,radial_v));
    let angle = atan2(radial.y,radial.x)/TAU+0.5;

    var color: vec3<f32>;
    var is_metal: f32 = 0.0;
    if (abs(dot(n_local,axle)) > 0.5) {
        let r = length(radial)/mat.wheel_radius;
        let ang = angle;
        if (r > 0.74) {
            // Black tire ring — smooth sidewall (a tire's side has no tread).
            // The rolling tread lives on the barrel branch below.
            // A single orange index stripe breaks spoke-pattern aliasing.
            let index_mark = ang > 0.46 && ang < 0.50 && r < 0.94;
            color = select(rubber, vec3<f32>(1.0,0.32,0.025), index_mark);
            is_metal = 0.0;
        } else if (r > 0.60) {
            color = metal;                                // rim ring
            is_metal = 1.0;
        } else if (r > 0.22) {
            // Radial spokes — all bright metal. Rotation stays legible from
            // the tread lugs streaming past on the barrel.
            let s = fract(ang * spoke_count);
            let is_spoke = s < spoke_w;
            color = select(rubber, metal, is_spoke);
            is_metal = select(0.0, 1.0, is_spoke);
        } else {
            // Hubcap: bright metal centre.
            color = metal;
            is_metal = 1.0;
        }
    } else {
        // ---- Barrel: the rolling tread surface ----
        let ang = angle;
        // Lug PROFILE instead of a hard on/off stripe: `wear` rounds and
        // flattens it toward bald (a worn tire's lug↔groove contrast fades),
        // `lug_depth` fakes relief — groove valleys pick up contact AO.
        let s = abs(fract(ang * lug_count) - 0.5) * 2.0;      // 0 valley … 1 lug top
        let edge = mix(0.25, 0.6, mat.wear);                   // wear rounds the shoulder
        let lug_m = smoothstep(0.5 - edge * 0.5, 0.5 + edge * 0.5, s)
            * (1.0 - mat.wear * 0.85);                         // wear flattens contrast
        color = mix(rubber, tread, lug_m);
        color *= 1.0 - mat.lug_depth * 0.35 * (1.0 - lug_m);   // valley AO
        is_metal = 0.0;
    }

    // Delegate illumination and shadowing to Bevy's native PBR path. Custom
    // materials are still ordinary shadow receivers; enforce that bit because
    // this shader owns the PbrInput rather than Bevy's stock fragment entry.
    var pbr_input = pbr_types::pbr_input_new();
    pbr_input.flags = mesh[input.instance_index].flags | mesh_types::MESH_FLAGS_SHADOW_RECEIVER_BIT;
    pbr_input.frag_coord = input.position;
    pbr_input.world_position = input.world_position;
    pbr_input.world_normal = pbr_functions::prepare_world_normal(
        normalize(input.world_normal), false, is_front);
    pbr_input.is_orthographic = view.clip_from_view[3].w == 1.0;
    pbr_input.N = pbr_input.world_normal;
    pbr_input.V = pbr_functions::calculate_view(input.world_position, pbr_input.is_orthographic);
    pbr_input.material.base_color = vec4(color, 1.0);
    pbr_input.material.perceptual_roughness = mix(0.85, 0.35, is_metal);
    pbr_input.material.metallic = mix(0.0, 0.80, is_metal);
    pbr_input.material.reflectance = vec3(0.5);

    var out = pbr_functions::apply_pbr_lighting(pbr_input);
    out = pbr_functions::main_pass_post_lighting_processing(pbr_input, out);
    return out;
}
