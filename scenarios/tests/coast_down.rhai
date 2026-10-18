// EV lift-off deceleration with native wheel contact and no friction brake.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts"],required_inputs:[]}
}
fn sample(car,name) {
 for p in query("ReadPorts",#{api_id:car,port_names:[name]}).ports {
  if p.name==name && p.direction=="out" {return p.value;}
 }
 throw("Missing output "+name);
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.elapsed=0.0;this.started=false;this.released=false;this.done=false;
 this.peak_regen=0.0;this.peak_speed=0.0;
 cmd("SetPorts",#{target:this.car,writes:[["brake",1.0],["boost",0.0],["fan",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;} this.elapsed+=dt();
 if this.elapsed<2.0 {return;}
 if !this.started {
  this.started=true;drive(this.car,1.0,0.0);
  cmd("SetPorts",#{target:this.car,writes:[["brake",0.0]]});return;
 }
 let speed=sample(this.car,"speed_mps");this.peak_speed=max(this.peak_speed,speed);
 if this.elapsed>=2.8 && !this.released {this.released=true;drive(this.car,0.0,0.0);}
 if this.released {this.peak_regen=max(this.peak_regen,sample(this.car,"recovered_power_w"));}
 if this.elapsed<12.8 {return;}
 let failures=[];
 if this.peak_speed<2.0 {failures.push("Vehicle failed to accelerate before release");}
 if speed>0.05 {failures.push("Released controls failed to stop vehicle");}
 if this.peak_regen<1000.0 {failures.push("No regenerative power was recovered");}
 emit("ROADSTER_COAST_EVIDENCE",#{peak_speed_mps:this.peak_speed,final_speed_mps:speed,peak_regen_w:this.peak_regen,release_duration_s:10.0,failures:failures});
 this.done=true;report_verdict(failures,"ROADSTER RELEASE TO STOP","ROADSTER_COAST");
}
