// Automatically evaluated for the selected subject, including while paused.
// Native camera code owns interpolation, BigSpace conversion and obstruction.
fn follow_camera(ctx) {
    if ctx.subject_name==() || !ctx.subject_name.contains("Roadster") {return #{};}
    let p=ctx.settings;
    // Heading and body attitude remain explicit operator choices. The default
    // stabilized view follows position and lets the car turn independently.
    if p.attitude=="body" || p.track_heading {return #{};}
    let up=max(-1.0,min(1.0,ctx.subject_up[1]));
    let ramp=max(0.0,min(1.0,(0.95-up)/0.75));
    // Move to the open side as the ramp steepens. Under the return lip, view
    // from below; a world-up focus offset could otherwise lie inside the ramp.
    #{attitude:"world",yaw:p.yaw+1.25*ramp,pitch:p.pitch*up,
      height:p.height*max(0.0,up)}
}
