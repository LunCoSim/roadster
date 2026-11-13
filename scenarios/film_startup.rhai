// @timing presentation
// Recording-scene startup: observation and authored controls, no possession.

fn on_start(me, ctx) {
    cmd("StepSimulation", #{hold:true});
    let gate=invoke_hook("control.authority.claim",[#{claimant:0,
        target:find_path("/World/Roadster"),current_owner:()}]);
    if !gate.ok || gate.value!=false {
        throw "Film startup requires the isolated recording control-claim policy";
    }
    // Release through the control owner, including its session claim. Merely
    // detaching a camera's ControlLink does not retire input authority.
    cmd("ReleaseControlSource", #{source:find_path("/World/Avatar")});
    print("ROADSTER_FILM_STARTUP held / observer only / no local driving claim");
}

fn task(me, ctx) {
    seq([
        once(|m| {
            cmd("FollowTarget", #{target:find_path("/World/Roadster")});
            cmd("ObserveAvatar", #{});
        }),
        once(|m| {
            cmd("SetCameraFollow", #{camera:find_path("/World/Avatar"),
                distance_m:14.0,height_m:1.0,pitch_rad:-0.2,yaw_rad:0.35,
                mode:"stabilized",damping:0.85});
            emit("roadster.film.ready", #{held:true,control:"scenario"});
        })
    ])
}

// Deliberately no interactive driver startup or input handlers. This replaces
// DriverSetup in the episode layer, rather than undoing its AcquireControl
// after the interactive startup has already run. Course service actions remain
// owned by the normal course program; the director supplies test inputs.
fn on_event(me,evt,ctx) {
    if evt.name=="runtime.ui.action" && evt.value.action=="roadster.refill" {
        // Reuse only the Twin's explicit service action. Calling its event
        // function does not execute the interactive on_start or acquire control.
        import "./driver_setup" as service;
        service::on_event(me,evt,ctx);
    }
}
