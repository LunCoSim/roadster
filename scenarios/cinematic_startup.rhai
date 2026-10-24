// Interactive showcase: the regular driver owns controls, the native camera
// follower supplies the presentation view. No recorder or frozen transport.
fn on_start(me,ctx) {
    import "./driver_setup" as driver;
    driver::on_start(me,ctx);
    cmd("SetCameraFollow",#{camera:find_path("/World/Avatar"),distance_m:14.0,
        height_m:1.0,pitch_rad:-0.2,yaw_rad:0.35,mode:"stabilized",damping:0.85});
}
fn on_event(me,evt,ctx) {
    import "./driver_setup" as driver;
    driver::on_event(me,evt,ctx);
}
