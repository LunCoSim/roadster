// One shot director for the offline Roadster track capture.
fn simulation_dependencies(me, ctx) {
    let car = find_path("/World/Roadster");
    #{modelica_entities: [car], entity_reads: [car], entity_writes: [],
      query_reads: [], required_inputs: []}
}

fn on_start(me, ctx) {
    this.car = find_path("/World/Roadster");
}

fn task(me, ctx) {
    seq([
        once(|m| {
            cmd("FollowTarget", #{target: this.car});
            cmd("ObserveAvatar", #{});
            // Tune the active avatar follow rig (the optional camera field
            // identifies a local embodiment, not the authored camera prim).
            cmd("SetCameraFollow", #{distance_m: 15.0, height_m: 2.0,
                pitch_rad: -0.25, yaw_rad: 0.0,
                mode: "stabilized", damping: 0.65});
        }),
        wait(0.25),
        once(|m| emit("runtime.ui.action", #{action: "roadster.autopilot", parameters: #{}})),
        wait(12.5),
        once(|m| cmd("SetCameraFollow", #{distance_m: 22.0, height_m: 8.0,
            pitch_rad: -0.18, yaw_rad: -1.2, mode: "stabilized", damping: 0.75})),
        wait(13.5),
        once(|m| cmd("SetCameraFollow", #{distance_m: 15.0, height_m: 2.0,
            pitch_rad: -0.25, yaw_rad: 0.0, mode: "stabilized", damping: 0.75}))
    ])
}
