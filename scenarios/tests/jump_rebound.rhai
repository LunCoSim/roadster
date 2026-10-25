// Production regression: the same lift valve as K, with controlled press/release
// timing. No pose, velocity, suspension, mass or physics-setting writes.
fn simulation_dependencies(me,ctx) {
    let car=find_path("/World/Roadster");let reads=[car,find_path("/World/Avatar")];
    for n in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+n));}
    #{modelica_entities:[car],entity_reads:reads,entity_writes:[car,find_path("/World/Avatar")],
      query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {
    this.car=find_path("/World/Roadster");this.t=0.0;this.done=false;
    this.held=ctx.contains("held") && ctx.held;
    this.first_apex=0.0;this.later_apex=0.0;this.airborne=false;this.landed=false;
    this.maximum_force=0.0;this.maximum_compression=0.0;this.samples=[];
    cmd("ReleaseControlSource",#{source:find_path("/World/Avatar")});
    cmd("AcquireControl",#{target:this.car,bind_camera:false});
    cmd("SetPorts",#{target:this.car,writes:[["fan",0.0],["course_autopilot_enable",0.0],["unlimited_air",0.0]]});
}
fn on_tick(me,ctx) {
    if this.done {return;}
    this.t+=dt();
    let active=if this.held {this.t>=1.5 && this.t<11.5}
        else {(this.t>=1.5 && this.t<1.8) || (this.t>=4.5 && this.t<4.8)};
    cmd("SetPorts",#{target:this.car,writes:[["thrust_y",if active {1.0}else{0.0}]]});
    let v=#{};
    for p in query("ReadPorts",#{api_id:this.car,port_names:["position_y","velocity_y","jet_force_y","gas_mass_kg","up_alignment"]}).ports {
        if p.direction=="out" {v[p.name]=p.value;}
    }
    let physics=query("QueryPhysicsState",#{id:this.car});let contacts=0;let compression=0.0;
    for wheel in physics.wheel_contacts {
        if wheel.contact_valid {contacts+=1;}
        this.maximum_compression=max(this.maximum_compression,wheel.suspension_compression_m);
        compression=max(compression,wheel.suspension_compression_m);
    }
    if v.position_y>1.0 {this.airborne=true;}
    // A hard stop can reverse velocity within one physics cycle; touchdown
    // detection must not require the completed sample to remain downward.
    if this.airborne && !this.landed && (contacts>0 || compression>0.0 || v.position_y<0.8) {this.landed=true;}
    if this.landed {this.later_apex=max(this.later_apex,v.position_y);}
    else {this.first_apex=max(this.first_apex,v.position_y);}
    this.maximum_force=max(this.maximum_force,v.jet_force_y);
    if this.samples.len==0 || this.t-this.samples[this.samples.len-1].time_s>=0.05 {
        this.samples.push(#{time_s:this.t,height_m:v.position_y,vertical_speed_mps:v.velocity_y,
            lift_n:v.jet_force_y,gas_mass_kg:v.gas_mass_kg,up_alignment:v.up_alignment,contacts:contacts});
    }
    if this.t<(if this.held {24.0}else{16.0}) {return;}
    let failures=[
        t_true(this.airborne && this.landed && this.maximum_force>30000.0,"Lift valve produces a real jump and touchdown"),
        t_true(this.later_apex<=this.first_apex+0.5,"Touchdown does not launch the car above the powered jump"),
        t_true(this.maximum_compression<=0.068,"Wheel compression stays within the 65 mm stop plus 3 mm contact tolerance")];
    this.failures=failures;
    emit("ROADSTER_JUMP_REBOUND_EVIDENCE",#{held:this.held,first_apex_m:this.first_apex,
        later_apex_m:this.later_apex,maximum_compression_m:this.maximum_compression,samples:this.samples,failures:failures});
    cmd("SetPorts",#{target:this.car,writes:[["thrust_y",0.0]]});
    this.done=true;report_verdict(failures,"ROADSTER JUMP REBOUND","ROADSTER_JUMP_REBOUND");
}
