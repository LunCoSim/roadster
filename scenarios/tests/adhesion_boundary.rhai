// A deliberately short skirt must fail visibly and hold the coupled vehicle.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[],
   query_reads:["ReadPorts","QueryPhysicsState","GetReadiness"],required_inputs:[]}
}
fn readings(car) {
 let v=#{};
 for p in query("ReadPorts",#{api_id:car,port_names:["course_stage","course_failure_reason","gas_mass_kg","soc","course_time_s"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 v
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.elapsed=0.0;this.held_at=();this.done=false;
 this.pause_events=0;this.explanation=false;subscribe("simulation-object-paused");
}
fn task(me,ctx) {seq([wait(0.2),once(|m|emit("runtime.ui.action",#{action:"roadster.autopilot"}))])}
fn on_event(me,evt,ctx) {
 if evt.name=="simulation-object-paused" && evt.source==this.car {
  this.pause_events+=1;this.explanation=evt.value.contains("roadster:adhesion-lost")
   && evt.value.contains("suction=") && evt.value.contains("weight=") && evt.value.contains("seal=");
 }
}
fn on_tick(me,ctx) {
 if this.done {return;}this.elapsed+=dt();
 let state=query("QueryPhysicsState",#{id:this.car});
 if state.simulation_object_paused && this.held_at==() {
  this.held_at=this.elapsed;this.pose=world_pos(this.car);
  this.model_time=get(this.car,"ModelicaModel.current_time");this.values=readings(this.car);
 }
 if this.held_at!=() && this.elapsed-this.held_at<0.5 {return;}
 if this.held_at==() && this.elapsed<35.0 {return;}
 let v=readings(this.car);let ready=query("GetReadiness",#{});let checks=[];
 checks.push(t_true(this.held_at!=(),"short skirt reaches an explicit coupled-object hold"));
 checks.push(t_true(this.pause_events==1 && this.explanation,"one Recent Events explanation carries measured adhesion facts"));
 if this.held_at!=() {
  checks.push(t_true(state.rigid_body_disabled && state.physics_object_paused && get(this.car,"ModelicaModel.paused")==true,
   "physics and continuous vehicle equations are both paused"));
  checks.push(t_true(world_pos(this.car)==this.pose && get(this.car,"ModelicaModel.current_time")==this.model_time
   && v.gas_mass_kg==this.values.gas_mass_kg && v.soc==this.values.soc && v.course_time_s==this.values.course_time_s,
   "pose, model clock, air, battery and mission clock remain fixed"));
  checks.push(t_true(state.simulation_object_pause_reason.condition=="roadster:adhesion-lost",
   "the retained pause reason identifies the authored envelope"));
  checks.push(t_true(v.course_failure_reason==8.0,"Modelica identifies loss of climb adhesion"));
 }
 checks.push(t_true(ready.ready && !ready.world_hold && !ready.faulted,"the world remains admitted after the object hold"));
 emit("ROADSTER_ADHESION_BOUNDARY_EVIDENCE",#{final:v,state:state,pause_events:this.pause_events});
 this.done=true;report_verdict(checks,"ROADSTER ADHESION BOUNDARY","ROADSTER_ADHESION_BOUNDARY");
}
