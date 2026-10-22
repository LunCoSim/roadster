// Three steady turns: rigid-body yaw response against geometric curvature.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 let reads=[car];
 for corner in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+corner));}
 #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {this.car=find_path("/World/Roadster");this.time=0.0;this.rows=[];this.done=false;}
fn on_tick(me,ctx) {
 if this.done {return;}this.time+=dt();let v=#{};
 for p in query("ReadPorts",#{api_id:this.car,port_names:["speed_mps","heading_fl","heading_fr","angvel_y","position_y"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 let target=if this.time<14.0 {5.0}else if this.time<26.0 {15.0}else{30.0};
 let steer=if this.time>=8.0 && this.time<14.0 {0.15}else if this.time>=20.0 && this.time<26.0 {0.1}else if this.time>=32.0 {0.05}else{0.0};
 let throttle=max(0.021,min(1.0,0.3*(target-v.speed_mps)));let brake=0.0;
 if v.speed_mps>target+0.2 {throttle=0.0;brake=min(1.0,0.2*(v.speed_mps-target));}
 if this.time<2.0 {throttle=0.0;brake=1.0;}
 drive(this.car,throttle,steer);cmd("SetPorts",#{target:this.car,writes:[["brake",brake],["fan",1.0]]});
 if (this.time>=13.9 && this.rows.len==0) || (this.time>=25.9 && this.rows.len==1) || (this.time>=37.9 && this.rows.len==2) {
  let tangent=2.0/(1.0/tan(v.heading_fl)+1.0/tan(v.heading_fr));
  let wheel_samples=#{};
  for corner in ["FL","FR","RL","RR"] {
   let wheel=find_path("/World/Roadster/Wheel_"+corner);
   wheel_samples[corner]=#{position:world_pos(wheel),rotation:world_rotation(wheel)};
  }
  this.rows.push(#{speed_mps:v.speed_mps,steer:steer,heading_fl:v.heading_fl,heading_fr:v.heading_fr,
   yaw_rate:v.angvel_y,kinematic_yaw_rate:v.speed_mps*tangent/2.75,position:world_pos(this.car),wheel_samples:wheel_samples});
 }
 if this.time<38.0 {return;}
 let failures=[];
 for row in this.rows {
  if row.yaw_rate>=0.0 {failures.push("Right steering did not produce right yaw");}
  if abs(row.yaw_rate/row.kinematic_yaw_rate-1.0)>0.25 {failures.push("Steady yaw response differs substantially from geometric turn");}
 }
 emit("ROADSTER_STEERING_EVIDENCE",#{turns:this.rows,failures:failures});
 drive(this.car,0.0,0.0);cmd("SetPorts",#{target:this.car,writes:[["brake",1.0]]});
 this.done=true;report_verdict(failures,"ROADSTER STEERING","ROADSTER_STEERING");
}
