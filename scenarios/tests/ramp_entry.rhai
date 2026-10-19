// Native ramp entry, with only ordinary throttle/brake/fan actuator commands.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let reads=[car];
 for n in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+n));}
 #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState","QueryUsdPrim"],required_inputs:[]}
}
fn contact_summary(car) {
 let c=contact_debug(car);
 #{normal_impulse_ns:c.total_normal_impulse,continuous_normal_impulse_ns:c.continuous_normal_impulse,
  normal_impulse_vector:c.normal_impulse_vector,max_penetration_m:c.max_penetration,
  max_normal_speed_mps:c.max_normal_speed,contact_normal:c.contact_normal,contact_point:c.contact_point}
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.time=0.0;this.done=false;
 let a=query("QueryUsdPrim",#{path:"/World/DriverSetup",attrs:["study:targetSpeed","study:fan"]}).attrs;
 this.target=a["study:targetSpeed"];this.fan=a["study:fan"];
 this.previous_speed=0.0;this.max_drop=0.0;this.min_speed=1000.0;this.entry_speed=0.0;
 this.max_body_impulse=0.0;this.max_height=0.0;this.worst=#{};this.next_sample=0.0;
}
fn on_tick(me,ctx) {
 if this.done {return;}this.time+=dt();let v=#{};
 for p in query("ReadPorts",#{api_id:this.car,port_names:["speed_mps","downforce","torque_left","up_alignment","pitch_rate_deg_s","quat_w","quat_x","quat_y","quat_z"]}).ports {if p.direction=="out" {v[p.name]=p.value;}}
 let pos=world_pos(this.car);let speed=v.speed_mps;
 let throttle=max(0.021,min(1.0,0.3*(this.target-speed)));let brake=0.0;
 if speed>this.target+0.3 {throttle=0.0;brake=min(1.0,0.3*(speed-this.target));}
 // Target speed defines the approach. On the ramp, hold the accelerator as
 // instructed by the course rather than commanding a cruise-speed ceiling.
 if pos[2]< -67.0 {throttle=1.0;brake=0.0;}
 if this.time<1.0 {throttle=0.0;brake=1.0;}
 drive(this.car,throttle,0.0);cmd("SetPorts",#{target:this.car,writes:[["brake",brake],["fan",this.fan]]});
 let native=query("QueryPhysicsState",#{id:this.car});
 let wheels=[];let rot=world_rotation(this.car);let inv=[-rot[0],-rot[1],-rot[2],rot[3]];
 for n in ["FL","FR","RL","RR"] {
  let path="/World/Roadster/Wheel_"+n;let w=find_path(path);let c=contact_debug(w);
  let hub=qrot(inv,vsub(world_pos(w),pos));let wn=query("QueryPhysicsState",#{id:w});
  wheels.push(#{wheel_usd_prim_path:path,contact_valid:c.touching_pair_count>0,
    suspension_compression_m:hub[1]+0.21,angular_velocity:wn.angular_velocity_radps,rotation:world_rotation(w),normal_impulse_ns:c.total_normal_impulse+c.continuous_normal_impulse});
 }
 let row=#{time_s:this.time,position:pos,speed_mps:speed,velocity:native.linear_velocity_mps,angular_velocity:native.angular_velocity_radps,
  quat:[v.quat_w,v.quat_x,v.quat_y,v.quat_z],body_contact:contact_summary(this.car),wheels:wheels,suction_n:v.downforce,torque_left_nm:v.torque_left,throttle:throttle,brake:brake,up_y:v.up_alignment};
 this.max_body_impulse=max(this.max_body_impulse,row.body_contact.normal_impulse_ns);
 if pos[2]< -67.0 && pos[2]> -103.0 && pos[1]<30.0 {
  if this.entry_speed==0.0 {this.entry_speed=speed;}
  this.min_speed=min(this.min_speed,speed);
  let drop=this.previous_speed-speed;
  if drop>this.max_drop {this.max_drop=drop;this.worst=row;}
 }
 this.previous_speed=speed;this.max_height=max(this.max_height,pos[1]);
 if this.time>=this.next_sample {emit("ROADSTER_RAMP_ENTRY_SAMPLE_EVIDENCE",row);this.next_sample=this.time+0.016;}
 if this.time<20.0 && pos[1]<30.0 {return;}
 let failures=[];
 if native.collider_source_paths.len!=7 {failures.push("All seven chassis collision parts must remain enabled");}
 if this.max_body_impulse>1000.0 {failures.push("Unexpected chassis impact during the wheel-supported climb");}
 if this.entry_speed<this.target*0.8 {failures.push("Target approach speed not reached");}
 if this.max_drop>0.75 {failures.push("Abrupt speed loss at ramp entry");}
 if this.min_speed<this.entry_speed*0.5 {failures.push("Ramp entry stopped the car");}
 if this.max_height<5.0 {failures.push("Car did not climb the transition");}
 emit("ROADSTER_RAMP_ENTRY_EVIDENCE",#{target_mps:this.target,fan:this.fan,entry_speed_mps:this.entry_speed,min_transition_speed_mps:this.min_speed,
  maximum_speed_drop_per_tick:this.max_drop,max_height_m:this.max_height,maximum_body_contact_impulse_ns:this.max_body_impulse,worst:this.worst,failures:failures});
 this.done=true;drive(this.car,0.0,0.0);report_verdict(failures,"ROADSTER RAMP ENTRY","ROADSTER_RAMP_ENTRY");
}
