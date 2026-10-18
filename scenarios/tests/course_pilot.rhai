// Acceptance driver: commands the same finite actuators as a human. No pose or
// velocity writes. Course policy separately judges real crossings and landing.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.time=0.0;this.last_stage= -1;this.jump_at= -1.0;
 this.crest_boost_at= -1.0;this.rotated=false;this.stage_times=[];this.samples=[];this.done=false;
 cmd("SetPorts",#{target:this.car,writes:[["fan",1.0],["brake",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;}this.time+=dt();let v=#{};
 for p in query("ReadPorts",#{api_id:this.car,port_names:["course_stage","course_blocks","position_z","position_y","speed_mps","up_alignment","flight_control_weight","gas_mass_kg","tank_temperature_k","fan_seal","downforce","course_air_rotation_degrees","instant_services","instant_air_added_kg","vehicle_mass_kg","vehicle_inertia_xx","vehicle_inertia_yy","vehicle_inertia_zz"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 let stage=v.course_stage.round().to_int();
 if stage!=this.last_stage {this.stage_times.push(#{stage:stage,time_s:this.time,position:world_pos(this.car)});this.last_stage=stage;}
 let throttle=0.0;let brake=0.0;let boost=0.0;let lift=0.0;let fan=1.0;
 let target=0.0;
 if stage==0 {throttle=1.0;if this.time<2.6 && this.time>2.0 {boost=1.0;}if this.time<2.0 {throttle=0.0;brake=1.0;}}
 if stage==1 || stage==3 {target=22.0;}
 if stage==2 {
  fan=0.0;target=22.0;
  if v.position_z< -86.0 && this.jump_at<0.0 {this.jump_at=this.time;}
  if this.jump_at>0.0 {target=0.0;if this.time-this.jump_at<0.45 {lift=1.0;}}
 }
 if stage==4 || stage==5 {target=11.0;}
 if stage==5 && v.position_y>63.5 && v.position_z> -304.0 {fan=0.0;target=0.0;}
 if stage==6 {
  fan=0.0;
  if !this.rotated {
   throttle= -1.0;
   if v.up_alignment>0.45 {this.rotated=true;throttle=0.0;}
  }
  if this.rotated && v.up_alignment>0.95 && v.position_y<7.0 && v.position_y>1.5 {lift=0.3;}
  if v.flight_control_weight<0.2 {throttle=0.0;brake=1.0;}
 }
 if target>0.0 {
  throttle=max(0.021,min(1.0,0.16*(target-v.speed_mps)));
  if v.speed_mps>target+0.3 {throttle=0.0;brake=min(1.0,0.3*(v.speed_mps-target));}
 }

 if stage==7 || stage==8 {brake=1.0;}
 drive(this.car,throttle,0.0);
 cmd("SetPorts",#{target:this.car,writes:[["brake",brake],["fan",fan],["boost",boost],["thrust_y",lift]]});
 if this.samples.len==0 || this.time-this.samples[this.samples.len-1].time_s>0.2 {
  let row=#{time_s:this.time,stage:stage,position:world_pos(this.car),speed:v.speed_mps,up_y:v.up_alignment,
   gas_kg:v.gas_mass_kg,temperature:v.tank_temperature_k,seal:v.fan_seal,suction:v.downforce,air_rotation:v.course_air_rotation_degrees};
  this.samples=[row];emit("ROADSTER_COURSE_SAMPLE",row);
 }
 if stage!=7 && stage!=8 && this.time<150.0 {return;}
 let native=query("QueryPhysicsState",#{id:this.car});
 let failures=[];
 if abs(native.mass_kg-v.vehicle_mass_kg)>0.01 {failures.push("Native mass did not follow Modelica inventory");}
 if v.instant_services!=2.0 {failures.push("Both green waypoints did not service the tank");}
 if v.instant_air_added_kg<50.0 {failures.push("Waypoint mass bookkeeping did not replenish consumed air");}
 if stage!=7 {failures.push("Course not completed by finite-actuator acceptance driver");}
 emit("ROADSTER_COURSE_EVIDENCE",#{stage:stage,stage_times:this.stage_times,final:v,native_mass_kg:native.mass_kg,native_inertia:native.inertia_principal_kgm2,failures:failures});
 this.done=true;report_verdict(failures,"ROADSTER SKILL COURSE","ROADSTER_COURSE");
}
