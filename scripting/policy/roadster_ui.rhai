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
    let course=();
    for participant in facts.participants {
        if participant.public_outputs.skill_course_active!=() && participant.public_outputs.skill_course_active>0.5 {course=participant.public_outputs;}
    }
    for participant in facts.participants {
        let v=participant.public_outputs;
        if v.speed_kmh == () { continue; }
        let out=vehicle_ui(v);
        let game=course_ui(course);
        out.rr_course_title=game.rr_course_title;out.rr_course_hint=game.rr_course_hint;out.rr_course_metrics=game.rr_course_metrics;
        return out;
    }
    #{runtime_status:"PHYSICS LOADING",rr_speed:"--",rr_mode:"PREPARING"}
}

fn vehicle_ui(v) {
        let servicing=v.refill_active>0.5;
        let ready=v.air_discharge_enabled>0.5;
        let fan_state=if v.fan_requested<0.5 {"FANS OFF"}else if v.fan_seal>0.8 {"FANS ON / SEALED"}else{"FANS ON / NO SEAL"};
        let status=if servicing {"REFILLING / moving allowed"}else if ready {"AIR READY"}else if v.thermal_guard_active>0.5 {"MODEL TEMP GUARD / REFILL"}else{"AIR UNAVAILABLE"};
        let out=#{program_label:"MANUAL",runtime_status:status};

        out.rr_speed = text_number(v.speed_kmh,1.0);
        out.rr_steering = "FL "+text_number(v.steer_left_degrees,10.0)+" / FR "+text_number(v.steer_right_degrees,10.0)+" deg";
        out.rr_mph = text_number(v.speed_mph,10.0)+" mph";
        out.rr_air_mass = text_number(v.gas_mass_kg,10.0)+" kg";
        out.rr_air_pressure = text_number(v.pressure_bar,10.0)+" bar";
        out.rr_air_fill = text_number(v.air_fill_percent,10.0)+"%";
        out.rr_air_width = v.air_fill_percent.to_string()+"%";
        out.rr_air_status = status;
        out.rr_air_color = if ready {"#68e0b2"}else{"#ffc66d"};
        out.rr_fill_temperature = text_number(v.refill_target_k,10.0)+" K";
        out.rr_temperature = text_number(v.tank_temperature_k,10.0)+" K";
        out.rr_refill_label = if servicing {"STOP REFILL"}else{"REFILL AIR"};
        out.rr_fan_state = fan_state;
        out.rr_fan_label = if v.fan_requested>0.5 {"TURN FANS OFF"}else{"TURN FANS ON"};
        out.rr_suction = text_number(v.suction_force_kn,10.0)+" kN suction";
        out.rr_fan_detail = text_number(v.fan_vacuum_kpa,10.0)+" kPa / "+text_number(v.fan_power_kw,10.0)+" kW";
        out.rr_aero = "Drag "+text_number(v.aerodynamic_drag_kn,100.0)+" kN / Aero load "+text_number(v.aerodynamic_downforce_kn,10.0)+" kN";
        out.rr_battery = text_number(v.charge_percent,10.0)+"% battery";
        out.rr_mode = if v.flight_control_weight>0.5 {"FLIGHT / MANUAL RATE"}else{"DRIVE"};
        out.rr_rates = "Pitch "+text_number(v.pitch_rate_deg_s,10.0)+" / Roll "+text_number(v.roll_rate_deg_s,10.0)+" deg/s";
        out.rr_force = "Lift "+text_number(v.lift_force_kn,10.0)+" kN / Boost "+text_number(v.boost_force_kn,10.0)+" kN";
        out.rr_service = if servicing {"Test supply: "+text_number(v.refill_flow_kg_s,10.0)+" kg/s"}else{"Earth g = 9.80665 m/s2"};
        out
}

fn course_ui(c) {
 let out=#{rr_course_title:"FREE DRIVE",rr_course_hint:"Ctrl+P pauses physics. Modelica parameters remain available in the inspector.",rr_course_metrics:""};
 if c==() {return out;}
 let titles=["01 / LAUNCH","02 / INSTANT REFILL WAYPOINT","03 / TIMED JUMP","04 / INSTANT REFILL WAYPOINT","05 / FAN CLIMB","06 / CREST RELEASE","07 / MANUAL FLIP + LAND","COURSE COMPLETE","RETRY COURSE"];
 let hints=["W + Space: reach 60 mph at the blue gate. Shift brakes before green zone.",
  "Drive between green posts: tank mass and temperature refill immediately. No stop.",
  "Fans OFF. Build 65–85 km/h. Tap K (~0.4 s) at YELLOW line. Clear all three blocks.",
  "Drive through green posts for immediate refill. Fans ON, then slow to 35–45 km/h for ramp.",
  "Fans ON. Aim for 35–45 km/h at ramp entry. W climbs; keep wheels sealed to ramp.",
  "Follow the long return lip. At the green crest: fans OFF. Pulse Q/E to flip.",
  "Q nose up · E nose down · J/L yaw · U/O roll. Counterpulse to stop rotation. Land wheels down, Shift brake.",
  "Launch, three blocks, fan climb and manual flip landed on FOUR wheels. Retry for a faster run.",
  "Checkpoint missed. Retry resets course, car, air and the simulation clock."];
 let index=max(0,min(8,c.course_stage.round().to_int()));
 out.rr_course_title=titles[index];out.rr_course_hint=hints[index];
 out.rr_course_metrics=text_number(c.course_time_s,10.0)+" s  /  Target "+text_number(c.target_distance_m,1.0)+" m  /  Blocks "+c.course_blocks.to_int().to_string()+" of 3  /  Air pitch "+text_number(c.course_air_rotation_degrees,1.0)+" deg";
 out
}
