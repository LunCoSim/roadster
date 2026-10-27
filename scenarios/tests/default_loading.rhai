// @timing presentation
// Direct Twin loading must publish the complete interactive control contract.
fn verify_loading() {
    let expected = #{forward:"W", backward:"S", left:"A", right:"D", thrust:"Space",
        brake:"ShiftLeft / ShiftRight", speed_boost:"K", action:"F", secondary_action:"Tab",
        yaw_left:"J", yaw_right:"L", auxiliary_1:"I / Q / R", auxiliary_2:"P / E / R",
        auxiliary_3:"Comma / Q / C", auxiliary_4:"Period / E / C", switch_mode:"V",
        pause:"ControlLeft + P / ControlRight + P"};
    let checks = [];
    for intent in expected.keys() {
        let label = expected[intent];
        checks.push(t_true(input_binding(intent) == label, "Twin binding: " + intent));
    }
    checks.push(t_true(is_controlled(find_path("/World/Roadster")), "default scene acquires manual control"));
    let surface = query("ReadExposures", #{}).surfaces["vessel-hud"];
    checks.push(t_true(surface.visible && surface.state == "ready"
        && surface.properties.contains("rr_air_mass"), "Roadster HUD has live Twin telemetry"));
    report_verdict(checks, "ROADSTER DEFAULT LOADING", "ROADSTER_DEFAULT_LOADING");
}

fn on_start(me, ctx) { this.elapsed = 0.0; this.done = false; }
fn on_tick(me, ctx) {
    if this.done { return; }
    this.elapsed += execution_context().delta_seconds;
    let surfaces = query("ReadExposures", #{}).surfaces;
    if (is_controlled(find_path("/World/Roadster")) && surfaces.contains("vessel-hud")
        && surfaces["vessel-hud"].state == "ready") || this.elapsed > 30.0 {
        this.done = true;
        verify_loading();
    }
}
