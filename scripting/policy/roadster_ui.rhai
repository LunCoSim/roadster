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
        if course!=() && course.course_failure_reason==8.0 {
            out.runtime_status="ADHESION LOST / VEHICLE PAUSED";
            out.program_label="PAUSED";
        }
        if facts.pause!=() && facts.pause.condition=="roadster:roof-impact-overload" {
            out.runtime_status="CABIN IMPACT / VEHICLE PAUSED";
            out.program_label="FAILED";
            out.rr_course_hint=facts.pause.detail;
        }
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

        // A speedometer measures forward travel, not the 3-D velocity norm.
        // Use the same whole-unit instrument precision in both unit systems.
        // Raw 3-D and longitudinal velocities remain available to telemetry.
        out.rr_speed = text_number(3.6*v.longitudinal_speed_mps,1.0);
        out.rr_steering = "FL "+text_number(v.steer_left_degrees,10.0)+" / FR "+text_number(v.steer_right_degrees,10.0)+" deg";
        out.rr_mph = text_number(v.longitudinal_speed_mps/0.44704,1.0)+" mph";
        out.rr_air_mass = text_number(v.gas_mass_kg,10.0)+" kg";
        out.rr_air_pressure = text_number(v.pressure_bar,10.0)+" bar";
        out.rr_air_fill = text_number(v.air_fill_percent,10.0)+"%";
        out.rr_air_width = v.air_fill_percent.to_string()+"%";
        out.rr_air_status = status;
        out.rr_air_color = if ready {"#68e0b2"}else{"#ffc66d"};
        out.rr_fill_temperature = text_number(v.refill_target_k-273.15,10.0)+" °C";
        out.rr_cutoff_temperature = text_number(v.thermal_guard_temperature_c,10.0)+" °C";
        out.rr_temperature = text_number(v.tank_temperature_c,10.0)+" °C";
        out.rr_unlimited_label = if v.unlimited_air_active>0.5 {"UNLIMITED AIR · ON"}else{"UNLIMITED AIR · OFF"};
        out.rr_refill_label = "Tab · REFILL AIR";
        out.rr_autopilot_label = if v.course_autopilot_active>0.5 {"STOP AUTOPILOT"}else{"RUN AUTOPILOT"};
        out.rr_course_controls = if v.course_autopilot_active>0.5 {"AUTOPILOT · driving or jet keys take over · Ctrl+P pauses"}
            else {suggested_controls(v)};
        out.rr_fan_state = fan_state;
        out.rr_fan_label = if v.fan_requested>0.5 {"F · FANS OFF"}else{"F · FANS ON"};
        out.rr_suction = text_number(v.suction_force_kn,10.0)+" kN suction";
        out.rr_fan_detail = text_number(v.fan_vacuum_kpa,10.0)+" kPa / "+text_number(v.fan_power_kw,10.0)+" kW";
        out.rr_aero = "Drag "+text_number(v.aerodynamic_drag_kn,100.0)+" kN / Aero load "+text_number(v.aerodynamic_downforce_kn,10.0)+" kN";
        out.rr_battery = text_number(v.charge_percent,10.0)+"% battery";
        out.rr_mode = if v.flight_control_weight>0.5 {"FLIGHT / DIRECT JETS"}else{"DRIVE"};
        out.rr_rates = "Pitch "+text_number(v.pitch_rate_deg_s,10.0)+" / Roll "+text_number(v.roll_rate_deg_s,10.0)+" deg/s";
        out.rr_force = "Lift "+text_number(v.lift_force_kn,10.0)+" kN / Boost "+text_number(v.boost_force_kn,10.0)+" kN";
        out.rr_service = if servicing {"Test supply: "+text_number(v.refill_flow_kg_s,10.0)+" kg/s"}else{"Earth g = 9.80665 m/s2"};
        out
}

fn suggested_controls(v) {
    if v.skill_course_active<0.5 {return "Manual controls · Ctrl+P pauses";}
    let names=["forward","reverse","left","right","boost","brake","lift",
        "pitch_up","pitch_down","yaw_left","yaw_right","roll_left","roll_right"];
    let keys=["W","S","A","D","Space","Shift","K","R","C","J","L","Q","E"];
    let hint="";
    for i in 0..names.len() {
        if v["pilot_"+names[i]]>0.5 {if hint!="" {hint+=" + ";} hint+=keys[i];}
    }
    if hint=="" {hint="coast";}
    "Suggested: "+hint+" · fans "+(if v.pilot_fan>0.5 {"ON"}else{"OFF"})
}

fn course_ui(c) {
 let out=#{rr_course_title:"FREE DRIVE",rr_course_hint:"Ctrl+P pauses physics. Modelica parameters remain available in the inspector.",rr_course_metrics:""};
 if c==() {return out;}
 let titles=["01 / LAUNCH","02 / INSTANT REFILL WAYPOINT","03 / TIMED JUMP","04 / INSTANT REFILL WAYPOINT","05 / FAN CLIMB","06 / CREST RELEASE","07 / FLIP + RETURN LANDING","COURSE COMPLETE","RETRY COURSE"];
 let hints=["W + Space: reach 60 mph at blue gate, carry speed through green. No stops.",
  "Drive between green posts: tank mass and temperature refill immediately. No stop.",
  "Fans OFF. Carry 126 km/h. Pulse K at YELLOW line (~0.3 s). 3 m cubes: timing is tight.",
  "K cushions jump landing. Refill while rolling; F fans ON before ramp. Keep at least 90 km/h.",
  "Fans ON. Carry speed onto ramp, W climbs. Ease to 23 km/h on upper return curve.",
  "Follow the return lip. At the green crest: fans OFF, then Q/E rolls wheels down.",
  "R nose up · C nose down · J/L yaw · Q/E left/right lift. Counterpulse to stop rotation. Land wheels down, Shift brake.",
  "Launch, three blocks, fan climb and manual flip landed on FOUR wheels. Retry for a faster run.",
  "Checkpoint missed. Retry resets course, car, air and the simulation clock."];
 let index=max(0,min(8,c.course_stage.round().to_int()));
 if c.course_failure_reason!=() && c.course_failure_reason>0.5 {index=8;}
 out.rr_course_title=titles[index];out.rr_course_hint=hints[index];
 if index==8 && c.course_failure_reason!=() {
  let reasons=["Checkpoint missed.","Course time exceeded 180 s.","Launch gate missed: reach 60 mph before passing blue.",
    "Lost carry speed: keep at least 90 km/h before the ramp.","Green refill waypoint missed.",
    "Landed before completing the aerial roll.","Cube impact: adjust K takeoff timing at the yellow line.",
    "Checkpoint clearance or landing qualification missed.",
    "Fan adhesion lost during climb. Vehicle and Modelica paused; review skirt reach and retry."];
  let reason=c.course_failure_reason.round().to_int();
  out.rr_course_hint=if reason>=0 && reason<reasons.len {reasons[reason]+" Retry resets the course, car and air."}
    else {"Unknown mission failure code "+reason.to_string()+". Review model diagnostics."};
 }
 if index==6 {
  out.rr_course_hint=if c.course_step<10 {"Q/E: roll wheels-down, nose AWAY from ramp. Counterpulse, J/L yaw trim; K cushions descent."}
    else {"Nose AWAY from ramp. K cushions descent. Bank Q/E toward road center, Shift on touchdown."};
 }
 out.rr_course_metrics=text_number(c.course_time_s,10.0)+" s  /  Target "+text_number(c.target_distance_m,1.0)+" m  /  Blocks "+c.course_blocks.to_int().to_string()+" of 3  /  Roll "+text_number(c.course_air_roll_degrees,1.0)+" deg / Landing "+text_number(c.course_landing_impact_speed,10.0)+" m/s";
 out
}
