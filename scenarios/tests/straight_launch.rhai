// Zero-steer symmetry diagnostic. Only ordinary controls stimulate the plant.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let reads=[car];
 for corner in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+corner));}
 for corner in ["FL","FR"] {reads.push(find_path("/World/Roadster/Steering_"+corner+"_Hinge"));}
 let models=[car];let source=find_path("/World/EqualDrive");if source>0 {models.push(source);reads.push(source);}
 #{modelica_entities:models,entity_reads:reads,entity_writes:reads,query_reads:["ReadPorts","ReadModelicaStepSamples"],required_inputs:[]}
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.n=0;this.done=false;this.source=find_path("/World/EqualDrive");if this.source>0 {cmd("SetPorts",#{target:this.source,writes:[["torque",0.0]]});}this.rear=[find_path("/World/Roadster/Wheel_RL"),find_path("/World/Roadster/Wheel_RR")];
 cmd("SetPorts",#{target:this.car,writes:[["course_enabled",0.0],["course_autopilot_enable",0.0],["program_active",1.0],["autopilot_enable",0.0],
  ["throttle",0.0],["steer",0.0],["brake",1.0],["fan",ctx.fan],["thrust_z",0.0],["thrust_y",0.0],["thrust_x",0.0],
  ["lift_fl",0.0],["lift_fr",0.0],["lift_rl",0.0],["lift_rr",0.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;}
 if this.n==60 {cmd("SetPorts",#{target:this.car,writes:[["throttle",ctx.motor],["steer",0.0],["brake",0.0],["thrust_z",ctx.jet]]});}
 if this.n==60 && this.source>0 {
  cmd("SetPorts",#{target:this.source,writes:[["torque",ctx.equal_torque]]});
 }
 if this.n==99 {cmd("SetPorts",#{target:this.car,writes:[["thrust_z",0.0]]});}
 let r=#{case_name:ctx.case_name,image:this.n,time_s:this.n/60.0};
 for p in query("ReadPorts",#{api_id:this.car,port_names:["position_x","position_y","position_z","velocity_x","velocity_z","yaw","angvel_y","heading_fl","heading_fr","thruster_yaw_moment_nm","adhesion.moment_body[2]","jet_force_z","downforce","torque_left","torque_right","wheel_speed_left","wheel_speed_right","fan_requested","powertrain.slip_left","powertrain.slip_right","powertrain.traction_left","powertrain.traction_right"]}).ports {if p.direction=="out" {r[p.name]=p.value;}}
 for corner in ["FL","FR"] {
  let joint=find_path("/World/Roadster/Steering_"+corner+"_Hinge");
  for p in query("ReadPorts",#{api_id:joint,port_names:["angle","angular_velocity"]}).ports {
   r[corner+"_"+p.direction+"_"+p.name]=p.value;
  }
 }
 for corner in ["RL","RR"] {
  for p in query("ReadPorts",#{api_id:find_path("/World/Roadster/Wheel_"+corner),port_names:["drive","shaft_speed","position_x","position_z","angvel_x"]}).ports {
   r[corner+"_"+p.name]=p.value;
  }
 }
 print("ROADSTER_STRAIGHT_LAUNCH " + r.to_string());
 this.n+=1;
 if this.n>=240 {this.done=true;emit("ROADSTER_STRAIGHT_LAUNCH_DONE",#{case_name:ctx.case_name,cycles:this.n});}
}
