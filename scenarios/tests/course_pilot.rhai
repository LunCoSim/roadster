// Observer of the production tree. The shared course pilot owns all guidance.
import "twin://tesla-roadster-runner/tools/wheel_state" as wheels;
fn simulation_dependencies(me,ctx) {
    let car=find_path("/World/Roadster");
    let reads=[car];for corner in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+corner));}
    for i in 0..3 {reads.push(find_path("/World/JumpBlock"+i.to_string()));}
    #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],
      query_reads:["ReadPorts","QueryPhysicsState","QueryUsdPrim","AnalyzeSysml","ReadActiveTwinContract"],
      required_inputs:[#{owner:"sysml.twin-analysis",identity:twin_name()}]}
}
fn on_start(me,ctx) {
    this.car=find_path("/World/Roadster");this.time=0.0;this.last_stage= -1;
    this.stage_times=[];this.next_sample=0.0;this.done=false;
    this.jump_impulse=0.0;this.touchdown_speed=();
    this.minimum_carry_speed=();this.minimum_service_speed=();
    this.last_services=0.0;this.maximum_unlimited=0.0;this.climb_height=();this.climb_seal=();this.climb_suction=();
    this.cubes=[];for i in 0..3 {this.cubes.push(find_path("/World/JumpBlock"+i.to_string()));}
    this.contact_bodies=[this.car];
    this.source=sysml_requirements::source();if this.source.ok!=true {throw(this.source.error);}
    let fields=query("QueryUsdPrim",#{path:"/World/DriverSetup",attrs:["study:jumpTimingOffset","study:timingSweep"]}).attrs;
    this.timing_sweep=fields["study:timingSweep"]==true;
    this.timing_offset=if fields["study:jumpTimingOffset"]==() {0.0}else{fields["study:jumpTimingOffset"]};
    cmd("SetPorts",#{target:this.car,writes:[["course_jump_timing_offset_s",this.timing_offset]]});
}
fn task(me,ctx) {
    seq([wait(0.2),once(|m|emit("runtime.ui.action",#{action:"roadster.autopilot"}))])
}
// Per-tick work is acceptance observation only; no actuator or state writes.
fn on_tick(me,ctx) {
    if this.done {return;}this.time+=dt();let v=#{};
    for p in query("ReadPorts",#{api_id:this.car,port_names:["course_failure_reason","fan_seal","downforce","course_stage","course_blocks",
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
        for cube in this.cubes {for body in this.contact_bodies {
            let c=contact_debug(body,cube);
            this.jump_impulse=max(this.jump_impulse,c.total_normal_impulse);
        }}
    }
    if stage>=1 && stage<=3 {this.minimum_carry_speed=if this.minimum_carry_speed==() {v.speed_mps}else{min(this.minimum_carry_speed,v.speed_mps)};}
    if v.instant_services>this.last_services {
        this.minimum_service_speed=if this.minimum_service_speed==() {v.speed_mps}else{min(this.minimum_service_speed,v.speed_mps)};this.last_services=v.instant_services;
    }
    this.maximum_unlimited=max(this.maximum_unlimited,v.unlimited_air_active);
    // Bind raw co-sampled climb facts; SysML evaluates seal/force/height limits.
    if stage==4 && (this.climb_height==() || v.position_y>this.climb_height) {
        this.climb_height=v.position_y;this.climb_seal=v.fan_seal;this.climb_suction=v.downforce;
    }
    if stage==6 && v.position_y<1.0 && v.flight_control_weight>0.8 {this.touchdown_speed=if this.touchdown_speed==() {max(0.0,-v.velocity_y)}else{max(this.touchdown_speed,-v.velocity_y)};}
    if stage!=this.last_stage {this.stage_times.push(#{stage:stage,time_s:this.time,
        position:world_pos(this.car)});this.last_stage=stage;}
    if this.time>=this.next_sample {
        emit("ROADSTER_COURSE_SAMPLE_EVIDENCE",#{time_s:this.time,stage:stage,position:world_pos(this.car),
            speed:v.speed_mps,up_y:v.up_alignment,gas_kg:v.gas_mass_kg,temperature:v.tank_temperature_k,telemetry:v});
        this.next_sample=this.time+(if stage==2 || stage==6 {0.05}else{0.2});
    }
    if this.timing_sweep && (stage>=3 || this.time>=20.0) {
        let failures=[];
        if this.time>=20.0 {failures.push("Jump observation did not reach a terminal checkpoint");}
        emit("ROADSTER_JUMP_WINDOW_EVIDENCE",#{timing_offset_s:this.timing_offset,
            cleared:stage>=3 && stage!=8 && v.course_blocks==3.0 && this.jump_impulse<=1.0,
            stage:stage,stage_times:this.stage_times,final:v,
            peak_cube_collision_impulse_ns:this.jump_impulse,failures:failures});
        this.done=true;
        // PASS means a valid measured trial, including a measured mission miss.
        // The separate cleared field classifies the tested timing sample.
        report_verdict(failures,"ROADSTER JUMP TIMING MEASUREMENT","ROADSTER_JUMP_WINDOW");return;
    }
    if stage!=7 && stage!=8 && this.time<100.0 {return;}
    let native=query("QueryPhysicsState",#{id:this.car});let failures=[];
    if this.timing_offset!=0.0 {
        if stage!=8 || v.course_failure_reason!=6.0 || this.jump_impulse<100.0 {failures.push("Timing perturbation did not produce a measured cube collision and mission miss");}
        emit("ROADSTER_COURSE_EVIDENCE",#{stage:stage,stage_times:this.stage_times,timing_offset_s:this.timing_offset,
            peak_cube_collision_impulse_ns:this.jump_impulse,final:v,failures:failures});
        this.done=true;report_verdict(failures,"ROADSTER TIMING CHALLENGE","ROADSTER_COURSE");return;
    }
    let contacts=wheels::contact_count("/World/Roadster");
    let checks=[
        criterion("continuous","courseFlow","ContinuousCourse",#{stage:v.course_stage,blocks:v.course_blocks,minimumCarrySpeedMps:this.minimum_carry_speed}),
        criterion("cube-contact","clearCubes","CleanCubeJump",#{peakImpulseNs:this.jump_impulse}),
        criterion("rolling-refill","courseRefills","RollingServices",#{serviceCount:v.instant_services,addedAirKg:v.instant_air_added_kg,minimumServiceSpeedMps:this.minimum_service_speed}),
        criterion("fan-climb","courseClimb","FanSupportedClimb",#{heightM:this.climb_height,fanSeal:this.climb_seal,suctionN:this.climb_suction}),
        criterion("return-landing","courseLanding","ReturnLanding",#{rollDegrees:v.course_air_roll_degrees,forwardZ:v.course_forward_z,upY:v.up_alignment,xM:v.position_x,zM:v.position_z,speedMps:v.speed_mps,wheelContacts:contacts}),
        criterion("landing-speed","landingSeverity","CushionedDescent",#{downwardSpeedMps:this.touchdown_speed}),
        criterion("finite-mass","courseInventory","FiniteCourseInventory",#{unlimitedAir:this.maximum_unlimited,nativeMassErrorKg:abs(native.mass_kg-v.chassis_mass_kg)})
    ];
    let report=sysml_requirements::evaluate(this.source,checks);
    this.done=true;
    // Emit the formal report first and detailed telemetry last. Existing scene
    // consumers retain the last evidence event; both share the same channel.
    report_structured_verdict(report,"ROADSTER SHARED COURSE TREE","ROADSTER_COURSE");
    emit("ROADSTER_COURSE_EVIDENCE",#{stage:stage,stage_times:this.stage_times,final:v,
        requirements:report,touchdown_speed_mps:this.touchdown_speed,
        minimum_carry_speed_mps:this.minimum_carry_speed,minimum_service_speed_mps:this.minimum_service_speed,
        qualified_fan_height_m:this.climb_height,fan_seal_at_height:this.climb_seal,suction_at_height_n:this.climb_suction,peak_cube_collision_impulse_ns:this.jump_impulse,
        native_mass_kg:native.mass_kg,native_inertia:native.inertia_principal_kgm2,failures:report.failures});
}
fn criterion(id,req,constraint,values) {
    sysml_requirements::constraint_check(id,"roadster.vehicle","Roadster::"+req,
        "Roadster::VerifySkillCourse","Roadster::"+constraint,values,"derived",0.0)
}
