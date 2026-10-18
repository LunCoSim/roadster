// An inverted body must settle on its roof envelope, not pass through Earth.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.time=0.0;this.done=false;
 cmd("SetPorts",#{target:this.car,writes:[["fan",0.0],["brake",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;}this.time+=dt();if this.time<4.0 {return;}
 let v=#{};
 for p in query("ReadPorts",#{api_id:this.car,port_names:["position_y","up_alignment","speed_mps"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 let native=query("QueryPhysicsState",#{id:this.car});let failures=[];
 if v.position_y<0.55 || v.position_y>1.0 {failures.push("Roof collision envelope did not support the inverted body");}
 if v.up_alignment> -0.95 || v.speed_mps>0.1 {failures.push("Inverted roof contact did not settle");}
 if !native.collider_present {failures.push("No native body collider");}
 emit("ROADSTER_ROOF_EVIDENCE",#{position:world_pos(this.car),up_y:v.up_alignment,speed:v.speed_mps,
  collider_sources:native.collider_source_paths,failures:failures});
 this.done=true;report_verdict(failures,"ROADSTER ROOF COLLISION","ROADSTER_ROOF");
}
