// Drive against the authored collision mesh. Native physics owns the trajectory.
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
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.elapsed=0.0;this.done=false;this.started=false;this.samples=[];
 this.entry_speed_drop=0.0;this.previous_speed=0.0;this.max_height=0.0;this.slope_contacts=0;this.max_slope=0.0;
 cmd("SetPorts",#{target:this.car,writes:[["brake",1.0],["fan",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;}this.elapsed+=dt();
 if !this.started && this.elapsed>=2.0 {
  cmd("SetPorts",#{target:this.car,writes:[["brake",0.0]]});drive(this.car,1.0,0.0);this.started=true;
 }
 let speed=sample(this.car,"speed_mps");
 let pos=world_pos(this.car);
 if pos[2]< -70.0 && pos[2]> -85.0 && pos[1]<3.0 {
  this.entry_speed_drop=max(this.entry_speed_drop,this.previous_speed-speed);
 }
 this.previous_speed=speed;this.max_height=max(this.max_height,pos[1]);
 let contacts=wheels::contact_count("/World/Roadster");
 // Alignment is measured by the four body-relative surface probes, not
 // assumed from the authored curve or time since launch.
 if contacts>=2 && pos[1]>3.0 && pos[2] < -70.0 {this.slope_contacts+=1;}
 if this.samples.len==0 || this.elapsed-this.samples[this.samples.len-1].time_s>0.1 {
  this.samples.push(#{time_s:this.elapsed,position:pos,contacts:contacts,
   speed_mps:sample(this.car,"speed_mps"),suction_n:sample(this.car,"downforce")});
 }
 if this.elapsed<10.0 && this.max_height<20.0 {return;}
 let failures=[];
 if this.entry_speed_drop>3.0 {failures.push("Abrupt collision-like speed loss at ramp entry");}
 if this.max_height<5.0 {failures.push("Vehicle did not climb the ramp");}
 if this.slope_contacts<10 {failures.push("No sustained native wheel contact on the curved ramp");}
 emit("ROADSTER_RAMP_EVIDENCE",#{max_height_m:this.max_height,maximum_entry_speed_drop_per_tick:this.entry_speed_drop,slope_contact_ticks:this.slope_contacts,
  final_position:pos,samples:this.samples,failures:failures});
 drive(this.car,0.0,0.0);this.done=true;report_verdict(failures,"ROADSTER RAMP","ROADSTER_RAMP");
}
