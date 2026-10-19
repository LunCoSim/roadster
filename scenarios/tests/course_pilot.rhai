// Observer of the production tree. The shared course pilot owns all guidance.
fn simulation_dependencies(me,ctx) {
    let car=find_path("/World/Roadster");
    let reads=[car];for corner in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+corner));}
    #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],
      query_reads:["ReadPorts","QueryPhysicsState","QueryUsdPrim"],required_inputs:[]}
}
fn on_start(me,ctx) {
    this.car=find_path("/World/Roadster");this.time=0.0;this.last_stage= -1;
    this.stage_times=[];this.next_sample=0.0;this.done=false;
    this.jump_impulse=0.0;this.touchdown_speed=0.0;
    let fields=query("QueryUsdPrim",#{path:"/World/DriverSetup",attrs:["study:jumpTimingOffset"]}).attrs;
    this.timing_offset=if fields["study:jumpTimingOffset"]==() {0.0}else{fields["study:jumpTimingOffset"]};
    cmd("SetPorts",#{target:this.car,writes:[["course_jump_timing_offset_s",this.timing_offset]]});
}
fn task(me,ctx) {
    seq([wait(0.2),once(|m|emit("runtime.ui.action",#{action:"roadster.autopilot"}))])
}
// Per-tick work is acceptance observation only; no actuator or state writes.
fn on_tick(me,ctx) {
    if this.done {return;}this.time+=dt();let v=#{};
    for p in query("ReadPorts",#{api_id:this.car,port_names:["course_stage","course_blocks",
        "course_time_s","position_x","position_y","position_z","speed_mps","up_alignment",
        "flight_control_weight","gas_mass_kg","tank_temperature_k","course_air_rotation_degrees",
        "quat_w","quat_x","quat_y","quat_z","pitch_rate_deg_s","yaw_rate_deg_s","roll_rate_deg_s",
        "heading_fl","pilot_left","pilot_right","velocity_x","velocity_z","pilot_lift","pilot_boost","pilot_pitch_up","pilot_pitch_down","pilot_yaw_left","pilot_yaw_right","pilot_roll_left","pilot_roll_right",
        "course_forward_speed","course_forward_z","jet_force_x","jet_force_y","thruster_yaw_moment_nm","thruster_roll_moment_nm",
        "course_step","velocity_y","course_landing_impact_speed","course_air_pitch_degrees","course_air_yaw_degrees","course_air_roll_degrees","course_backward_distance_m",
        "instant_services","instant_air_added_kg","chassis_mass_kg","course_autopilot_active","unlimited_air_active"]}).ports {
        if p.direction=="out" {v[p.name]=p.value;}
    }
    let stage=v.course_stage.round().to_int();
    if (stage==2 || stage==8) && v.position_z< -94.0 && v.position_z> -132.0 {
        this.jump_impulse=max(this.jump_impulse,(contact_debug(this.car).total_normal_impulse+contact_debug(this.car).continuous_normal_impulse));
        for corner in ["FL","FR","RL","RR"] {this.jump_impulse=max(this.jump_impulse,(contact_debug(find_path("/World/Roadster/Wheel_"+corner)).total_normal_impulse+contact_debug(find_path("/World/Roadster/Wheel_"+corner)).continuous_normal_impulse));}
    }
    if stage==6 && v.position_y<1.0 && v.flight_control_weight>0.8 {this.touchdown_speed=max(this.touchdown_speed,-v.velocity_y);}
    if stage!=this.last_stage {this.stage_times.push(#{stage:stage,time_s:this.time,
        position:world_pos(this.car)});this.last_stage=stage;}
    if this.time>=this.next_sample {
        emit("ROADSTER_COURSE_SAMPLE_EVIDENCE",#{time_s:this.time,stage:stage,position:world_pos(this.car),
            speed:v.speed_mps,up_y:v.up_alignment,gas_kg:v.gas_mass_kg,temperature:v.tank_temperature_k,telemetry:v});
        this.next_sample=this.time+(if stage==2 || stage==6 {0.05}else{0.2});
    }
    if stage!=7 && stage!=8 && this.time<100.0 {return;}
    let native=query("QueryPhysicsState",#{id:this.car});let failures=[];
    if this.timing_offset!=0.0 {
        if stage!=8 || this.jump_impulse<100.0 {failures.push("Timing perturbation did not produce a measured cube collision and mission miss");}
        emit("ROADSTER_COURSE_EVIDENCE",#{stage:stage,stage_times:this.stage_times,timing_offset_s:this.timing_offset,
            peak_cube_collision_impulse_ns:this.jump_impulse,final:v,failures:failures});
        this.done=true;report_verdict(failures,"ROADSTER TIMING CHALLENGE","ROADSTER_COURSE");return;
    }
    if this.touchdown_speed>5.0 {failures.push("Landing vertical speed exceeds 5 m/s");}
    if this.jump_impulse>1.0 {failures.push("Nominal course struck a cube with a physical collider");}
    if v.course_air_roll_degrees<150.0 || v.course_forward_z<0.94 {failures.push("Roll/away-heading maneuver not measured");}
    if stage!=7 {failures.push("Shared course tree did not complete");}
    if v.course_autopilot_active<0.5 {failures.push("Shared autopilot was not active");}
    if v.course_blocks!=3.0 {failures.push("Three blocks were not crossed");}
    if v.instant_services!=2.0 {failures.push("Both green waypoints did not refill");}
    if v.instant_air_added_kg<50.0 {failures.push("Waypoint mass bookkeeping did not replenish consumed air");}
    if v.unlimited_air_active>0.5 {failures.push("Finite-air acceptance used unlimited air");}
    if abs(native.mass_kg-v.chassis_mass_kg)>0.01 {failures.push("Native mass did not follow Modelica inventory");}
    emit("ROADSTER_COURSE_EVIDENCE",#{stage:stage,stage_times:this.stage_times,final:v,
        touchdown_speed_mps:this.touchdown_speed,peak_cube_collision_impulse_ns:this.jump_impulse,native_mass_kg:native.mass_kg,native_inertia:native.inertia_principal_kgm2,failures:failures});
    this.done=true;report_verdict(failures,"ROADSTER SHARED COURSE TREE","ROADSTER_COURSE");
}
