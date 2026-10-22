// The drop is a physical overload, not a survivable roof-settling fixture.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[],
 query_reads:["QueryPhysicsState","ReadPorts","GetReadiness","ReadExposures"],required_inputs:[]}
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.elapsed=0.0;this.held_at=();this.done=false;
 this.events=0;this.explained=false;this.impact_event=false;
 subscribe("simulation-object-paused");subscribe("roadster.roof-overload");
}
fn on_event(me,evt,ctx) {
 if evt.name=="roadster.roof-overload" {
  this.impact_event=evt.source==this.car && evt.value>=0.5 && evt.sim_tick<=sim_tick();
  emit("ROADSTER_ROOF_EVENT_EVIDENCE",#{event:evt,car:this.car});
 }
 if evt.name=="simulation-object-paused" && evt.source==this.car {
  this.events+=1;this.explained=evt.value.contains("impact energy exceeded") && evt.value.contains("absorption envelope=");
 }
}
fn on_tick(me,ctx) {
 if this.done {return;}this.elapsed+=dt();
 let state=query("QueryPhysicsState",#{id:this.car});
 if state.simulation_object_paused && this.held_at==() {
  this.held_at=this.elapsed;this.pose=world_pos(this.car);
  this.model_time=get(this.car,"ModelicaModel.current_time");
 }
 if this.held_at==() && this.elapsed<4.0 {return;}
 if this.held_at!=() && this.elapsed-this.held_at<0.5 {return;}
 let hud=query("ReadExposures",#{surface:"vessel-hud"}).surfaces["vessel-hud"];
 let presented=hud!=() && hud.state=="ready" && hud.properties.runtime_status=="CABIN IMPACT / VEHICLE PAUSED";
 if this.held_at!=() && !presented && this.elapsed<4.0 {return;}
 let checks=[t_true(this.impact_event,"the retained failure event identifies the impacted vehicle and producer tick"),
  t_true(this.held_at!=(),"an overloaded cabin impact pauses the vehicle"),
  t_true(this.events==1 && this.explained,"one Recent Events message explains the exceeded energy envelope and authored capacity")];
 if this.held_at!=() {
  checks.push(t_true(state.rigid_body_disabled && get(this.car,"ModelicaModel.paused")==true,
   "native motion and continuous equations pause together"));
  checks.push(t_true(world_pos(this.car)==this.pose && get(this.car,"ModelicaModel.current_time")==this.model_time,
   "the coupled pose and model clock remain fixed"));
  checks.push(t_true(state.simulation_object_pause_reason.condition=="roadster:roof-impact-overload",
   "the retained condition identifies physical overload"));
 }
 checks.push(t_true(presented && hud.properties.program_label=="FAILED",
  "the retained pause condition reaches the authored failure HUD"));
 checks.push(t_true(presented && hud.properties.rr_course_hint.contains("absorption envelope="),
  "the HUD retains the explanation after the transient model output clears"));
 let ready=query("GetReadiness",#{});
 checks.push(t_true(ready.ready && !ready.world_hold && !ready.faulted,"the rest of the simulation remains usable"));
 emit("ROADSTER_ROOF_OVERLOAD_EVIDENCE",#{state:state});
 this.done=true;report_verdict(checks,"ROADSTER ROOF OVERLOAD","ROADSTER_ROOF_OVERLOAD");
}
