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
        if evt.value.action=="roadster.refill" {
            name="roadster_test_refill_request";
            for p in query("ReadPorts",#{api_id:car,port_names:["refill_active"]}).ports {
                if p.direction=="out" && p.value>0.5 {name="roadster_test_refill_cancel";}
            }
        }
    }
    if name == "roadster_fan_toggle" {
        let switch_on=false;
        for p in query("ReadPorts",#{api_id:car,port_names:["fan_requested"]}).ports {
            if p.direction=="out" && p.value>0.5 {switch_on=true;}
        }
        cmd("SetPorts",#{target:car,writes:[["fan",if switch_on {0.0}else{1.0}]]});
    }
    if name == "roadster_test_refill_request" {
        let allowed=false;
        for p in query("ReadPorts",#{api_id:car,port_names:["refill_allowed"]}).ports {
            if p.direction=="out" && p.value>0.5 {allowed=true;}
        }
        if !allowed {notify("Choose a refill target between 253.15 and 333.15 K.");return;}
        cmd("SetPorts",#{target:car,writes:[["refill",1.0]]});
        notify("External test air supply connected. Modelica accounts for air mass, temperature and service power.");
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
    set(avatar,"SpringArmCamera.distance",9.0);
    set(avatar,"SpringArmCamera.pitch",-0.10);
    set(avatar,"SpringArmCamera.vertical_offset",0.5);
}
fn task(me,ctx) { seq([wait(0.1),once(|m| configure_follow(m))]) }
