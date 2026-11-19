// A pre-spun vehicle on a real vertical collider. No kinematic attachment.
import "../../tools/wheel_state" as wheels;
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let reads=[car];
 for n in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+n));}
 #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn sample(car,name) {
 for p in query("ReadPorts",#{api_id:car,port_names:[name]}).ports {
  if p.name==name && p.direction=="out" {return p.value;}
 }
 throw("Missing output "+name);
}
fn contacts(car) {
 wheels::contact_count("/World/Roadster")
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.elapsed=0.0;this.done=false;this.on=();this.samples=[];
 this.start=world_pos(this.car);
 cmd("SetPorts",#{target:this.car,writes:[["brake",1.0],["fan",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;} this.elapsed+=dt();
 if this.samples.len==0 || this.elapsed-this.samples[this.samples.len-1].time_s>0.2 {
  this.samples.push(#{time_s:this.elapsed,position:world_pos(this.car),contacts:contacts(this.car),
   force_n:sample(this.car,"downforce"),seal:sample(this.car,"fan_seal")});
  emit("WALL_TRACE",this.samples[this.samples.len-1]);
 }
 if this.elapsed>=5.0 && this.on==() {
  this.on=#{position:world_pos(this.car),contacts:contacts(this.car),
   suction_n:sample(this.car,"downforce"),seal:sample(this.car,"fan_seal"),
   power_w:sample(this.car,"fan_power_w"),rpm:sample(this.car,"fan_rpm"),
   friction_margin_n:sample(this.car,"wall_friction_margin_n")};
  cmd("SetPorts",#{target:this.car,writes:[["fan",0.0]]});
 }
 if this.elapsed<7.0 {return;}
 let off=#{position:world_pos(this.car),contacts:contacts(this.car),
   suction_n:sample(this.car,"downforce"),power_w:sample(this.car,"fan_power_w")};
 let failures=[];
 if this.on.contacts!=4 {failures.push("Fan-on vehicle lost wheel contact with wall");}
 if this.on.position[1]<this.start[1]-2.0 {failures.push("Fan-on vehicle fell down wall");}
 if abs(this.on.position[2]-0.5)>0.3 {failures.push("Fan-on normal position left the wall");}
 if this.on.suction_n<30000.0 || this.on.friction_margin_n<=0.0 {failures.push("Insufficient wall adhesion force");}
 if this.on.power_w>80000.01 {failures.push("Fan exceeded its electrical budget");}
 if off.suction_n>100.0 || off.position[1]>this.on.position[1]-5.0 {failures.push("Fan-off control case stayed attached");}
 emit("ROADSTER_WALL_EVIDENCE",#{fan_on:this.on,fan_off:off,initial_position:this.start,samples:this.samples,failures:failures});
 this.done=true;report_verdict(failures,"ROADSTER WALL ADHESION","ROADSTER_WALL");
}
