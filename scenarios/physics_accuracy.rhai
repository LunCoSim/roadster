// Scene-scoped numerical accuracy, not a force, pose, or vehicle controller.
fn simulation_dependencies(me,ctx) {
 #{modelica_entities:[],entity_reads:[me],entity_writes:[],query_reads:["QueryUsdPrim"],required_inputs:[]}
}
fn on_start(me,ctx) {
 this.previous_iterations=get_setting("ContinuousCollisionSettings.max_iterations");
 this.previous_position=get_setting("ContinuousCollisionSettings.position_tolerance_m");
 this.previous_angle=get_setting("ContinuousCollisionSettings.angular_tolerance_rad");
 let a=query("QueryUsdPrim",#{path:usd_path(me)+"/ContactAccuracy",attrs:["study:positionToleranceM","study:angularToleranceRad","study:maxIterations"]}).attrs;
 if this.previous_position==() || this.previous_angle==() {throw("Native contact accuracy settings are unavailable");}
 if !set_setting("ContinuousCollisionSettings.max_iterations",a["study:maxIterations"]) {throw("Native iteration budget could not be configured");}
 if !set_setting("ContinuousCollisionSettings.position_tolerance_m",a["study:positionToleranceM"]) || !set_setting("ContinuousCollisionSettings.angular_tolerance_rad",a["study:angularToleranceRad"]) {throw("Native contact accuracy could not be configured");}
}
fn on_stop(me,ctx) {
 if this.previous_iterations!=() {set_setting("ContinuousCollisionSettings.max_iterations",this.previous_iterations);}
 if this.previous_position!=() {set_setting("ContinuousCollisionSettings.position_tolerance_m",this.previous_position);}
 if this.previous_angle!=() {set_setting("ContinuousCollisionSettings.angular_tolerance_rad",this.previous_angle);}
}
