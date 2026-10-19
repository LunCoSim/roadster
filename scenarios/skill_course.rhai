// One mission tree for manual play, keyboard acceptance, and autopilot.
// Modelica owns measurements and control suggestions; this program owns phases
// and discrete command edges. It never writes forces, poses, velocities or mass.
fn simulation_dependencies(me, ctx) {
    let car = find_path("/World/Roadster");
    let reads=[car];for corner in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+corner));}
    #{modelica_entities:[car], entity_reads:reads, entity_writes:[car],
      query_reads:["ReadPorts"], required_inputs:[]}
}
fn readings(car, names) {
    let values = #{};
    for p in query("ReadPorts", #{api_id:car, port_names:names}).ports {
        if p.direction == "out" { values[p.name] = p.value; }
    }
    values
}
fn phase_node(phase, action, message) {
    once(|me| {
        this.phase = phase;
        cmd("SetPorts", #{target:this.car, writes:[
            ["course_phase", phase*1.0], ["course_action", action*1.0]]});
        notify(message);
    })
}
fn action_node(action) {
    once(|me| { cmd("SetPorts", #{target:this.car, writes:[["course_action",action*1.0]]}); })
}
fn healthy(me) { readings(this.car,["course_healthy"]).course_healthy > 0.5 }
fn launched(me) { readings(this.car,["launch_gate"]).launch_gate > 0.5 }
fn launch_started(me) { readings(this.car,["course_launch_started"]).course_launch_started > 0.5 }
fn in_refill_zone(me) { readings(this.car,["refill_zone"]).refill_zone > 0.5 }
fn tank_ready(me) { readings(this.car,["refill_ready"]).refill_ready > 0.5 }
fn at_takeoff(me) { readings(this.car,["position_z"]).position_z < -86.0 }
fn barrier_reached(me) { readings(this.car,["course_block_crossed"]).course_block_crossed > 0.5 }
fn barrier_cleared(me) { readings(this.car,["jump_clearance"]).jump_clearance > 0.5 }
fn block_count_published(me) { readings(this.car,["course_blocks"]).course_blocks >= this.blocks*1.0 }
fn climbed(me) { readings(this.car,["climb_gate"]).climb_gate > 0.5 }
fn at_crest(me) { readings(this.car,["course_crest_gate"]).course_crest_gate > 0.5 }
fn in_flight(me) { readings(this.car,["course_airborne_gate"]).course_airborne_gate > 0.5 }
fn roll_ready(me) {readings(this.car,["course_roll_gate"]).course_roll_gate>0.5}
fn select_yaw_direction(me) {
    let direction=readings(this.car,["pilot_yaw_direction"]).pilot_yaw_direction;
    cmd("SetPorts",#{target:this.car,writes:[["course_turn_direction",direction]]});
}
fn mid_yaw(me) {readings(this.car,["course_mid_yaw_gate"]).course_mid_yaw_gate>0.5}
fn yaw_ready(me) {readings(this.car,["course_yaw_gate"]).course_yaw_gate>0.5}
fn landing_ready(me) {
    if readings(this.car,["landing_gate"]).landing_gate<0.5 {return false;}
    for corner in ["FL","FR","RL","RR"] {
        if contact_debug(find_path("/World/Roadster/Wheel_"+corner)).touching_pair_count<1 {return false;}
    }
    true
}
fn refill(me) {
    let fields = ["mass_offset","temperature_offset","wall_temperature_offset",
        "refill_count","mechanical_energy_j","stored_energy_j"];
    let names = []; for field in fields { names.push("next_"+field); }
    let boundary = readings(this.car,names);
    let writes = [];
    for field in fields { writes.push(["instant_"+field,boundary["next_"+field]]); }
    cmd("SetPorts",#{target:this.car,writes:writes});
}
fn count_block(me) {
    this.blocks += 1;
    cmd("SetPorts",#{target:this.car,writes:[["course_blocks_passed",this.blocks*1.0]]});
}
fn refill_node(phase, message) {
    seq([phase_node(phase,2,message), wait_until(Fn("in_refill_zone")),
         once(Fn("refill")), wait_until(Fn("tank_ready"))])
}
fn barrier_node() {
    seq([wait_until(Fn("barrier_reached")), check(Fn("barrier_cleared")),
         once(Fn("count_block")),wait_until(Fn("block_count_published"))])
}
fn on_start(me, ctx) {
    this.car = find_path("/World/Roadster");
    this.phase = 0; this.blocks = 0; this.autopilot = false;
    this.last_controls = [];
    for name in ["TASK_FAILED","runtime.ui.action","roadster.pilot.controls","intent.edge"] {subscribe(name);}
    cmd("SetPorts",#{target:this.car,writes:[["course_phase",0.0],
        ["course_action",0.0],["course_blocks_passed",0.0],["course_autopilot_enable",0.0]]});
}
fn task(me, ctx) {
    reactive_seq([
        check(Fn("healthy")),
        seq([
            phase_node(0,0,"LAUNCH: settle, then W + Space to reach 60 mph at the blue gate. Ctrl+P pauses."),
            wait(2.0), action_node(1), wait_until(Fn("launch_started")), wait(0.65), action_node(2),
            wait_until(Fn("launched")),
            refill_node(1,"REFILL 1: drive through the green waypoint; refill is immediate while rolling."),
            phase_node(2,3,"JUMP: fans OFF, build 65–85 km/h, tap K at the yellow takeoff line."),
            wait_until(Fn("at_takeoff")), action_node(4), wait(0.45), action_node(5),
            repeat(3,barrier_node()),
            refill_node(3,"REFILL 2: drive through green posts, then fans ON and slow for the ramp."),
            phase_node(4,6,"CLIMB: fans ON, approach at 35–45 km/h, then hold W up the ramp."),
            wait_until(Fn("climbed")),
            phase_node(5,7,"CREST: follow the return lip; slow down and switch fans OFF at the crest."),
            wait_until(Fn("at_crest")), action_node(8), wait_until(Fn("in_flight")),
            phase_node(6,9,"ROLL: Q/E rolls upright. R/C trims pitch. Fans remain OFF."),
            wait_until(Fn("roll_ready")),
            once(Fn("select_yaw_direction")),
            phase_node(6,11,"YAW: J/L turns the nose back along the track; K can cushion descent."),
            wait_until(Fn("mid_yaw")),
            phase_node(6,13,"YAW: continue the same turn until the nose points back along the track."),
            wait_until(Fn("yaw_ready")),
            phase_node(6,12,"BACKWARD FLIGHT + LAND: Space brakes backward motion; K cushions descent. Shift on touchdown."),
            // Losing any landing condition resets the native task dwell.
            // This is checkpoint qualification, not a physical contact law.
            retry(60,seq([wait_until(Fn("landing_ready")),
                reactive_seq([check(Fn("landing_ready")),wait(0.5)])])),
            phase_node(7,10,"COURSE COMPLETE: launch, three blocks, fan climb, flip and four-wheel landing."),
            once(|m| { if this.autopilot { this.apply_pilot(m); } }),
        ]),
    ])
}
fn pilot_setpoint(car) {
    let names = ["throttle","steer","brake","thrust_z","thrust_y","thrust_x",
        "fan","lift_fl","lift_fr","lift_rl","lift_rr"];
    let ports = []; for name in names { ports.push("pilot_command_"+name); }
    let p = readings(car,ports);
    let writes = [["program_active",1.0],["autopilot_enable",0.0]];
    for name in names { writes.push([name,p["pilot_command_"+name]]); }
    writes
}

fn apply_pilot(me) {
    let writes = pilot_setpoint(this.car);
    if writes != this.last_controls {
        cmd("SetPorts",#{target:this.car,writes:writes});
        this.last_controls = writes;
    }
}
fn stop_setpoint() {
    [["program_active",0.0],["course_autopilot_enable",0.0],
     ["throttle",0.0],["steer",0.0],["brake",1.0],["thrust_z",0.0],["thrust_y",0.0],
     ["thrust_x",0.0],["lift_fl",0.0],["lift_fr",0.0],["lift_rl",0.0],["lift_rr",0.0]]
}
fn on_event(me, evt, ctx) {
    if evt.name == "TASK_FAILED" && evt.source == me {
        this.phase = 8; this.autopilot = false;
        let writes = stop_setpoint(); writes.push(["course_phase",8.0]);
        cmd("SetPorts",#{target:this.car,writes:writes});
        notify("Course missed or timed out. Retry to reset the car, air and mission tree.");
    }
    if evt.name == "runtime.ui.action" && evt.value.action == "roadster.autopilot" {
        if this.phase >= 7 { notify("Retry the course before starting the autopilot."); return; }
        this.autopilot = !this.autopilot; this.last_controls = [];
        if this.autopilot {
            cmd("SetPorts",#{target:this.car,writes:[["course_autopilot_enable",1.0]]});
            this.apply_pilot(me);
            notify("Course autopilot ON. Press any driving or jet key to take over. Ctrl+P still pauses.");
        } else {
            cmd("SetPorts",#{target:this.car,writes:stop_setpoint()});
            notify("Autopilot OFF. Manual controls active.");
        }
    }
    if this.autopilot && evt.name == "roadster.pilot.controls" && evt.source == this.car {
        this.apply_pilot(me);
    }
    if this.autopilot && evt.name == "intent.edge" && evt.source == this.car && evt.value.edge == "pressed" {
        let movement = ["forward","backward","left","right","brake","thrust","speed_boost",
            "yaw_left","yaw_right","auxiliary_1","auxiliary_2","auxiliary_3","auxiliary_4"];
        if movement.contains(evt.value.intent) {
            this.autopilot = false;
            // Native input has already written the player's complete frame.
            cmd("SetPorts",#{target:this.car,writes:[["course_autopilot_enable",0.0],["program_active",0.0]]});
            notify("Manual takeover: autopilot OFF.");
        }
    }
}
fn on_stop(me,ctx) {
    if this.autopilot { cmd("SetPorts",#{target:this.car,writes:stop_setpoint()}); }
}
