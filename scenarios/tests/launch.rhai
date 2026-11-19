// Rocket standing-start launch. Uses actual Avian motion and Modelica samples.
// Requirement limits live in SysML, not in this scenario.
fn simulation_dependencies(me, ctx) {
    let car = find_path("/World/Roadster");
    #{modelica_entities: [car], entity_reads: [car], entity_writes: [car],
      query_reads: ["ReadPorts", "QueryUsdPrim", "AnalyzeSysml", "ReadActiveTwinContract"],
      required_inputs: [#{owner: "sysml.twin-analysis", identity: twin_source_identity()}]}
}

fn sample(car, name) {
    let record = query("ReadPorts", #{api_id: car, port_names: [name]});
    for p in record.ports { if p.name == name && p.direction == "out" { return p.value; } }
    throw("Missing Roadster output: " + name);
}

fn criterion(id, req, constraint, values) {
    sysml_requirements::constraint_check(id, "roadster.vehicle", "Roadster::"+req,
        "Roadster::VerifyRunner", "Roadster::"+constraint, values, "derived", 0.0)
}

fn on_start(me, ctx) {
    this.car = find_path("/World/Roadster");
    this.elapsed = 0.0;
    this.launched = false;
    this.done = false;
    this.crossing = ();
    this.crossing_speed = 0.0;
    this.previous_speed = 0.0;
    this.previous_time = 0.0;
    this.min_soc = 1.0;
    this.max_soc = 0.0;
    this.max_speed = 0.0;
    this.samples = [];
    this.source = sysml_requirements::source();
    if this.source.ok != true { throw(this.source.error); }
    cmd("SetPorts", #{target: this.car, writes: [["brake",1.0]]});
}

fn on_tick(me, ctx) {
    if this.done { return; }
    this.elapsed += dt();
    if this.elapsed < 2.0 { return; }
    if !this.launched {
        this.launched = true;
        this.start = world_pos(this.car);
        this.initial_soc = sample(this.car,"soc");
        this.initial_impulse = sample(this.car,"impulse_remaining");
        this.launch_at = this.elapsed;
        drive(this.car, 1.0, 0.0);
        cmd("SetPorts", #{target: this.car, writes: [["launch_measurement_active",1.0],["brake",0.0],["fan",1.0],["boost",1.0]]});
        return;
    }
    let t = this.elapsed-this.launch_at;
    let velocity = -sample(this.car,"velocity_z");
    let soc = sample(this.car,"soc");
    this.min_soc = min(this.min_soc,soc);
    this.max_soc = max(this.max_soc,soc);
    this.max_speed = max(this.max_speed,velocity);
    // The 60 mph measurement conversion is exact (NIST S06). SysML evaluates
    // the acceptance bound against this observed threshold crossing.
    if this.crossing == () && velocity >= 26.8224 {
        let fraction = (26.8224-this.previous_speed)/max(0.0000001,velocity-this.previous_speed);
        this.crossing = this.previous_time+fraction*(t-this.previous_time);
        this.crossing_speed = velocity;
        cmd("SetPorts",#{target:this.car,writes:[["launch_measurement_active",0.0]]});
    }
    if this.samples.len() == 0 || t-this.samples[this.samples.len()-1].time_s >= 0.05 {
        this.samples.push(#{time_s:t, speed_m_s:velocity, soc:soc,
            impulse_ns:sample(this.car,"impulse_remaining"),
            battery_power_w:sample(this.car,"battery_power"),
            thruster_force_n:sample(this.car,"thruster_force"),
            vehicle_mass_kg:sample(this.car,"vehicle_mass_kg"),
            gas_mass_kg:sample(this.car,"gas_mass_kg"),
            tank_pressure_pa:sample(this.car,"tank_pressure_pa"),
            tank_temperature_k:sample(this.car,"tank_temperature_k"),
            temperature_k:sample(this.car,"temperature_k"), position:world_pos(this.car)});
    }
    this.previous_speed = velocity;
    this.previous_time = t;
    if t < 3.0 { return; }
    cmd("SetPorts", #{target: this.car, writes: [["boost",0.0],["fan",0.0]]});
    brake(this.car);
    let travel = vsub(this.start,world_pos(this.car))[2];
    let checks = [];
    let wheel_count = 0;
    for name in ["Wheel_FL","Wheel_FR","Wheel_RL","Wheel_RR"] {
        if find_path("/World/Roadster/"+name) >= 0 { wheel_count += 1; }
    }
    let seat_count = 0;
    for name in ["DriverSeat","PassengerSeat"] {
        let path="/World/Roadster/Body/"+name;
        if find_path(path)>=0 {
            let seat=query("QueryUsdPrim",#{path:path,attrs:["visibility"]});
            if seat.active && seat.attrs.visibility!="invisible" {seat_count+=1;}
        }
    }
    checks.push(criterion("RR-001", "seating", "HasOneSeat", #{count:seat_count}));
    checks.push(criterion("RR-002", "wheels", "HasFourWheels", #{count:wheel_count}));
    checks.push(criterion("RR-003", "driveResponse", "PositiveMotion", #{travelM:travel}));
    checks.push(criterion("RR-004-min", "batteryBounds", "StateOfChargeBounds", #{soc:this.min_soc}));
    checks.push(criterion("RR-004-max", "batteryBounds", "StateOfChargeBounds", #{soc:this.max_soc}));
    checks.push(criterion("RR-005", "driveEnergy", "EnergyConsumed", #{initialSoc:this.initial_soc,finalSoc:soc}));
    checks.push(criterion("RR-006", "gasBudget", "FiniteImpulse",
        #{initialImpulseNs:this.initial_impulse,remainingImpulseNs:sample(this.car,"impulse_remaining")}));
    // Missing threshold crossing stays an unavailable observation; it cannot pass.
    let timing = #{reachedSpeedMps:this.crossing_speed};
    if this.crossing != () { timing.elapsedS = this.crossing; }
    checks.push(criterion("RR-007", "thrustAcceleration", "SubsecondLaunch", timing));
    let result = sysml_requirements::evaluate(this.source,checks);
    emit("ROADSTER_LAUNCH_EVIDENCE", #{standing_start_0_60_s:this.crossing,
        travel_m:travel, peak_speed_m_s:this.max_speed, initial_soc:this.initial_soc,
        recorded_boost_window_s:sample(this.car,"launch_recorded_time_s"),
        boost_impulse_to_60_ns:sample(this.car,"launch_rear_impulse_ns"),
        mean_boost_to_60_n:sample(this.car,"launch_rear_mean_force_n"),
        final_soc:soc, samples:this.samples});
    print("ROADSTER: 0-60 standing-start="+this.crossing+" s; travel="+travel+" m; SOC="+soc);
    this.done = true;
    report_structured_verdict(result,"ROADSTER RUNNER","ROADSTER_RUNNER");
}

fn on_stop(me, ctx) {
    if this.car >= 0 {
        brake(this.car);
        cmd("SetPorts", #{target:this.car,writes:[["boost",0.0],["lift",0.0],["fan",0.0]]});
    }
}
