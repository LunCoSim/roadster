// Regression for the real driving/jumping boundary: no pose/velocity writes.
// W remains held through takeoff, then S/A/D are exercised in free flight.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.time=0.0;this.jump_at= -1.0;
 this.done=false;this.air_ticks=0;this.max_collective_pitch_moment=0.0;this.max_uncommanded_jet=0.0;
 this.flight_motor_torque=0.0;this.max_rear_height_difference=0.0;this.rows=[];
 this.commands_seen=[false,false,false,false];
}
fn on_tick(me,ctx) {
 if this.done {return;}this.time+=dt();let v=#{};
 for p in query("ReadPorts",#{api_id:this.car,port_names:["thruster_pitch_moment_nm","speed_mps","flight_control_weight","torque_left","jet_lift_0","jet_lift_1","jet_lift_2","jet_lift_3","jet_force_x","jet_force_z","pitch_rate_deg_s","up_alignment","quat_w","quat_x","quat_y","quat_z"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 let throttle=if this.time<1.0 {0.0}else{1.0};let steer=0.0;let lift=0.0;
 if this.jump_at<0.0 && v.speed_mps>=20.0 {this.jump_at=this.time;}
 let elapsed=this.time-this.jump_at;
 if this.jump_at>0.0 {
  if elapsed<0.45 {lift=1.0;}
  if elapsed>0.65 && elapsed<0.95 {throttle= -1.0;}
  if elapsed>=0.95 && elapsed<1.25 {throttle=0.0;steer= -1.0;}
  if elapsed>=1.25 && elapsed<1.55 {throttle=0.0;steer=1.0;}
  if v.flight_control_weight>0.99 {
   this.air_ticks+=1;
   this.max_collective_pitch_moment=max(this.max_collective_pitch_moment,abs(v.thruster_pitch_moment_nm));
   // Rear/front axle body points span 2.75 m; report actual attitude.
   let rear_minus_front=5.5*(v.quat_y*v.quat_z-v.quat_w*v.quat_x);
   this.max_rear_height_difference=max(this.max_rear_height_difference,abs(rear_minus_front));
   if elapsed>0.1 && elapsed<0.4 {this.flight_motor_torque=max(this.flight_motor_torque,v.torque_left);this.commands_seen[0]=true;}
   if elapsed>0.75 && elapsed<0.9 {this.commands_seen[1]=true;}
   if elapsed>1.05 && elapsed<1.2 {this.commands_seen[2]=true;}
   if elapsed>1.35 && elapsed<1.5 {this.commands_seen[3]=true;}
   // Allow 0.35 s (14 valve time constants) after collective release.
   if elapsed>0.8 {
    for force in [v.jet_lift_0,v.jet_lift_1,v.jet_lift_2,v.jet_lift_3,abs(v.jet_force_x),abs(v.jet_force_z)] {this.max_uncommanded_jet=max(this.max_uncommanded_jet,force);}
   }
   if this.rows.len==0 || elapsed-this.rows[this.rows.len-1].jump_time_s>0.15 {
    this.rows.push(#{jump_time_s:elapsed,position:world_pos(this.car),speed:v.speed_mps,
     pitch_rate_deg_s:v.pitch_rate_deg_s,rear_minus_front_m:rear_minus_front,up_y:v.up_alignment,
     motor_torque:v.torque_left,front_force:v.jet_lift_0+v.jet_lift_2,rear_force:v.jet_lift_1+v.jet_lift_3});
   }
  }
 }
 drive(this.car,throttle,steer);
 cmd("SetPorts",#{target:this.car,writes:[["fan",0.0],["brake",if this.time<1.0 {1.0}else{0.0}],["thrust_y",lift]]});
 if (this.jump_at<0.0 || elapsed<1.6) && this.time<12.0 {return;}
 let failures=[];
 if this.air_ticks<30 {failures.push("Insufficient real airborne samples");}
 for seen in this.commands_seen {if !seen {failures.push("A driving command was not exercised in flight");}}
 if this.max_collective_pitch_moment>0.01 {failures.push("Collective lift created an uncommanded pitch moment");}
 if this.max_uncommanded_jet>1.0 {failures.push("WASD opened an uncommanded thruster");}
 if this.flight_motor_torque<1.0 {failures.push("W stopped controlling the motors in flight");}
 emit("ROADSTER_MOVING_JUMP_EVIDENCE",#{jump_at_s:this.jump_at,airborne_ticks:this.air_ticks,
  maximum_collective_pitch_moment_nm:this.max_collective_pitch_moment,maximum_uncommanded_jet_n:this.max_uncommanded_jet,
  flight_motor_torque_nm:this.flight_motor_torque,maximum_body_front_rear_height_difference_m:this.max_rear_height_difference,
  commands_exercised_in_flight:this.commands_seen,samples:this.rows,failures:failures});
 drive(this.car,0.0,0.0);cmd("SetPorts",#{target:this.car,writes:[["thrust_y",0.0]]});
 this.done=true;report_verdict(failures,"ROADSTER FIXED FLIGHT CONTROLS","ROADSTER_MOVING_JUMP");
}
