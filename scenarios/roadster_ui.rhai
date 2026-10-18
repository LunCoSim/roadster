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
    let speed=0.0;
    if facts.velocity.len == 3 {
        for v in facts.velocity { speed += v*v; }
        speed=sqrt(speed);
    }
    let gas=0.0;
    let pressure=0.0;
    let soc=0.0;
    for participant in facts.participants {
        let values=participant.public_outputs;
        if values.gas_mass_kg != () { gas=values.gas_mass_kg; }
        if values.tank_pressure_pa != () { pressure=values.tank_pressure_pa; }
        if values.soc != () { soc=values.soc; }
    }
    let tilt=0.0;
    if facts.rotation.len == 4 {
        let q=facts.rotation;
        let up=1.0-2.0*(q[0]*q[0]+q[2]*q[2]);
        let clamped=max(-1.0,min(1.0,up));
        tilt=acos(clamped)*57.295779513;
    }
    let position="—";
    let altitude="—";
    if facts.position.len == 3 {
        position="X "+text_number(facts.position[0],1.0)+" · Z "+text_number(facts.position[2],1.0);
        altitude=text_number(facts.position[1],10.0);
    }
    let summary=text_number(speed*3.6,1.0)+" km/h · "+text_number(speed/0.44704,1.0)+" mph";
    summary += "\nAIR "+text_number(gas,10.0)+" kg · "+text_number(pressure/100000.0,1.0)+" bar";
    summary += "\nBATTERY "+text_number(soc*100.0,10.0)+"%";
    #{label:facts.label,program_label:"MANUAL",program_color:"var(--accent-color)",
      runtime_status:if facts.available { "RUNNING" } else { "LOADING" },
      speed:text_number(speed,10.0),altitude:altitude,
      tilt:text_number(tilt,1.0)+"°",tilt_status:if tilt>35.0 { "TILTED" } else { "STABLE" },
      tilt_limits:"",tilt_color:"var(--ok-color)",tilt_marker:"0%",
      caution_width:"44%",danger_start:"78%",danger_width:"22%",
      roll:"—",pitch:"—",heading:"—",local_position:position,
      geo_display:"none",local_display:"flex",comms_display:"none",
      telemetry_display:"flex",
      telemetry_summary:summary}
}
