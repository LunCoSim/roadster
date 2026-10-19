// Presentation and possession only. No per-tick camera or physics writer.
fn simulation_dependencies(me, ctx) {
    let car = find_path("/World/Roadster");
    #{modelica_entities:[car],entity_reads:[car,find_path("/World/Avatar")],entity_writes:[car,find_path("/World/Avatar")],
      query_reads:[],required_inputs:[]}
}
fn on_start(me, ctx) {
    let car = find_path("/World/Roadster");
    cmd("AcquireControl", #{target:car,bind_camera:true});
    cmd("ObserveAvatar",#{});

}
fn on_event(me,evt,ctx) {
    let car=find_path("/World/Roadster");
    let name=evt.name;
    // Fixed semantic action: one toggle on the press edge, never while held.
    if name=="intent.edge" && evt.source==car && evt.value.intent=="action" && evt.value.edge=="pressed" {
        name="roadster_fan_toggle";
    }
    if name=="intent.edge" && evt.source==car && evt.value.intent=="secondary_action" && evt.value.edge=="pressed" {
        name="roadster_instant_refill";
    }
    if name=="runtime.ui.action" {
        if evt.value.action=="roadster.restart" {cmd("OpenTwin",#{path:twin_root()});return;}
        if evt.value.action=="roadster.temperature.up" || evt.value.action=="roadster.temperature.down" {
            let change=if evt.value.action=="roadster.temperature.up" {5.0}else{-5.0};
            for p in query("ReadPorts",#{api_id:car,port_names:["refill_target_k"]}).ports {
                if p.direction=="out" {
                    cmd("SetPorts",#{target:car,writes:[["refill_target_temperature_k",max(253.15,min(333.15,p.value+change))]]});
                }
            }
        }
        if evt.value.action=="roadster.fans" {name="roadster_fan_toggle";}
        if evt.value.action=="roadster.refill" {name="roadster_instant_refill";}
        if evt.value.action=="roadster.unlimited" {
            let active=0.0;
            for p in query("ReadPorts",#{api_id:car,port_names:["unlimited_air_active"]}).ports {
                if p.direction=="out" {active=p.value;}
            }
            cmd("SetPorts",#{target:car,writes:[["unlimited_air",if active>0.5 {0.0}else{1.0}]]});
            if active<0.5 {name="roadster_instant_refill";}
        }
    }
    if name == "roadster_fan_toggle" {
        let switch_on=false;
        for p in query("ReadPorts",#{api_id:car,port_names:["fan_requested"]}).ports {
            if p.direction=="out" && p.value>0.5 {switch_on=true;}
        }
        cmd("SetPorts",#{target:car,writes:[["fan",if switch_on {0.0}else{1.0}]]});
    }
    if name == "roadster_instant_refill" {
        // The same Modelica-computed co-moving service boundary as green pads.
        // It restores gas/wall temperature, mass, inertia and energy ledgers.
        let boundary=#{};
        for p in query("ReadPorts",#{api_id:car,port_names:["refill_allowed","next_mass_offset","next_temperature_offset","next_wall_temperature_offset","next_refill_count","next_mechanical_energy_j","next_stored_energy_j"]}).ports {
            if p.direction=="out" {boundary[p.name]=p.value;}
        }
        if boundary.refill_allowed<0.5 {notify("Choose a refill temperature between 253.15 and 333.15 K.");return;}
        let writes=[["refill",0.0]];
        for field in ["mass_offset","temperature_offset","wall_temperature_offset","refill_count","mechanical_energy_j","stored_energy_j"] {
            writes.push(["instant_"+field,boundary["next_"+field]]);
        }
        cmd("SetPorts",#{target:car,writes:writes});
        notify("Air refilled to 250 kg at the selected temperature.");
    }
    if name == "roadster_air_refilled" || name == "roadster_test_refill_cancel" {
        cmd("SetPorts",#{target:car,writes:[["refill",0.0]]});
        notify("Test air supply disconnected.");
    }
}

// Configure the existing avatar spring arm once after possession commits.
// Camera realization and collision avoidance remain in the native camera owner.
fn configure_follow(me) {
    let avatar=find_path("/World/Avatar");
    cmd("SetCameraFollow",#{camera:avatar,distance_m:14.0,height_m:0.8,
        pitch_rad:-0.24,yaw_rad:0.0,mode:"stabilized",damping:0.92});
}
fn task(me,ctx) { seq([wait(0.1),once(|m| configure_follow(m))]) }
