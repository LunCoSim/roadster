// Twin presentation policy. Reads immutable engine facts, never simulation state.
fn text_number(value, scale) { ((value*scale).round()/scale).to_string() }
fn camera_ui(facts) {
        let items=[];
        for camera in facts.cameras {
            items.push(#{key:camera.name,label:camera.label,action:"camera.select.path."+camera.name});
        }
        if facts.avatar_available {
            items.push(#{key:"__avatar__",label:"Free / follow camera",action:"camera.observe.avatar"});
        }
        return #{active_label:facts.active_label,camera_items:items,
            dropdown_width:"280px",dropdown_max_height:"240px"};
}
fn roadster_ui(facts) {
    if facts.surface_id == "camera-status" { return camera_ui(facts); }
    if facts.surface_id != "vessel-hud" { return #{}; }
    let summary="PHYSICS LOADING";
    for participant in facts.participants {
        let v=participant.public_outputs;
        if v.speed_kmh == () { continue; }
        summary=text_number(v.speed_kmh,10.0)+" km/h · "+text_number(v.speed_mph,10.0)+" mph";
        summary += "\nAIR "+text_number(v.gas_mass_kg,10.0)+" kg · "+text_number(v.pressure_bar,10.0)+" bar";
        summary += "\nBATTERY "+text_number(v.charge_percent,10.0)+"% · SUCTION "+text_number(v.suction_force_kn,10.0)+" kN";
        summary += "\nI BOOST "+text_number(v.boost_force_kn,10.0)+" kN · J/L YAW "+text_number(v.yaw_force_kn,10.0)+" kN";
        summary += "\nU LIFT "+text_number(v.lift_force_kn,10.0)+" kN · K/O INHIBIT";
        if v.air_discharge_enabled == 0.0 { summary += "\nAIR DISCHARGE INHIBITED"; }
    }
    // The host publishes native attitude/speed below this policy. Put the
    // engineering readouts in its retained status field so they remain visible.
    #{program_label:"MANUAL",program_color:"var(--accent-color)",runtime_status:summary}
}
