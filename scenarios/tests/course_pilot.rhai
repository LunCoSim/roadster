// Observer of the production tree. The shared course pilot owns all guidance.
fn simulation_dependencies(me,ctx) {
    let car=find_path("/World/Roadster");
    #{modelica_entities:[car],entity_reads:[car],entity_writes:[],
      query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {
    this.car=find_path("/World/Roadster");this.time=0.0;this.last_stage= -1;
    this.stage_times=[];this.next_sample=0.0;this.done=false;
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
        "instant_services","instant_air_added_kg","chassis_mass_kg","course_autopilot_active","unlimited_air_active"]}).ports {
        if p.direction=="out" {v[p.name]=p.value;}
    }
    let stage=v.course_stage.round().to_int();
    if stage!=this.last_stage {this.stage_times.push(#{stage:stage,time_s:this.time,
        position:world_pos(this.car)});this.last_stage=stage;}
    if this.time>=this.next_sample {
        emit("ROADSTER_COURSE_SAMPLE_EVIDENCE",#{time_s:this.time,stage:stage,position:world_pos(this.car),
            speed:v.speed_mps,up_y:v.up_alignment,gas_kg:v.gas_mass_kg,temperature:v.tank_temperature_k});
        this.next_sample=this.time+0.2;
    }
    if stage!=7 && stage!=8 && this.time<100.0 {return;}
    let native=query("QueryPhysicsState",#{id:this.car});let failures=[];
    if stage!=7 {failures.push("Shared course tree did not complete");}
    if v.course_autopilot_active<0.5 {failures.push("Shared autopilot was not active");}
    if v.course_blocks!=3.0 {failures.push("Three blocks were not crossed");}
    if v.instant_services!=2.0 {failures.push("Both green waypoints did not refill");}
    if v.instant_air_added_kg<50.0 {failures.push("Waypoint mass bookkeeping did not replenish consumed air");}
    if v.unlimited_air_active>0.5 {failures.push("Finite-air acceptance used unlimited air");}
    if abs(native.mass_kg-v.chassis_mass_kg)>0.01 {failures.push("Native mass did not follow Modelica inventory");}
    emit("ROADSTER_COURSE_EVIDENCE",#{stage:stage,stage_times:this.stage_times,final:v,
        native_mass_kg:native.mass_kg,native_inertia:native.inertia_principal_kgm2,failures:failures});
    this.done=true;report_verdict(failures,"ROADSTER SHARED COURSE TREE","ROADSTER_COURSE");
}
