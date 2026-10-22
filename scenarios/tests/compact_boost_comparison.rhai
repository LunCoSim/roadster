// Isolated launch/jump comparison. Only ordinary controls and the authored
// demonstration service act on the car. No pose, velocity or force writes.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let reads=[car];
 for c in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+c));}
 for i in 0..3 {reads.push(find_path("/World/JumpBlock"+i.to_string()));}
 #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],query_reads:["ReadPorts"],required_inputs:[]}
}
fn values(car,names) {
 let out=#{};for p in query("ReadPorts",#{api_id:car,port_names:names}).ports {if p.direction=="out" {out[p.name]=p.value;}}out
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.n=0;this.serviced=false;this.lifted=false;this.lift_closed=false;
 this.hit_barrier=false;this.blocks=0;this.takeoff_speed=0.0;this.done=false;
 this.bodies=[this.car];
 this.cubes=[];for i in 0..3 {this.cubes.push(find_path("/World/JumpBlock"+i.to_string()));}
 cmd("SetPorts",#{target:this.car,writes:[["course_autopilot_enable",0.0],["program_active",1.0],["autopilot_enable",0.0],
  ["course_phase",1.0],["course_blocks_passed",0.0],["steer",0.0],["throttle",0.0],["brake",1.0],["fan",0.0],
  ["thrust_x",0.0],["thrust_y",0.0],["thrust_z",0.0],["lift_fl",0.0],["lift_fr",0.0],["lift_rl",0.0],["lift_rr",0.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;}
 let v=values(this.car,["position_x","position_y","position_z","speed_mps","refill_zone","course_takeoff_gate","course_jump_impulse_ready","jump_clearance","course_block_crossed","gas_mass_kg","tank_temperature_k"]);
 if this.n==60 {cmd("SetPorts",#{target:this.car,writes:[["throttle",1.0],["brake",0.0],["thrust_z",ctx.boost]]});}
 if this.n==99 {cmd("SetPorts",#{target:this.car,writes:[["thrust_z",0.0]]});}
 if !this.serviced && v.refill_zone>0.5 {
  let fields=["mass_offset","temperature_offset","wall_temperature_offset","refill_count","mechanical_energy_j","stored_energy_j"];
  let names=[];for f in fields {names.push("next_"+f);}let next=values(this.car,names);let writes=[];
  for f in fields {writes.push(["instant_"+f,next["next_"+f]]);}cmd("SetPorts",#{target:this.car,writes:writes});this.serviced=true;
 }
 if !this.lifted && v.course_takeoff_gate>0.5 {
  this.lifted=true;this.takeoff_speed=v.speed_mps;
  cmd("SetPorts",#{target:this.car,writes:[["thrust_y",1.0],["throttle",0.0]]});
 }
 if this.lifted && !this.lift_closed && v.course_jump_impulse_ready>0.5 {
  cmd("SetPorts",#{target:this.car,writes:[["thrust_y",0.0]]});this.lift_closed=true;
 }
 if this.lifted && v.position_z< -94.0 && v.position_z> -132.0 {
  for cube in this.cubes {for body in this.bodies {
   let c=contact_debug(body,cube);if c.total_normal_impulse>1.0 {this.hit_barrier=true;}
  }}
 }
 if this.blocks<3 && v.course_block_crossed>0.5 && v.jump_clearance>0.5 && !this.hit_barrier {
  this.blocks+=1;cmd("SetPorts",#{target:this.car,writes:[["course_blocks_passed",this.blocks*1.0]]});
 }
 if this.hit_barrier || (this.blocks==3 && v.position_y<1.0) {
  cmd("SetPorts",#{target:this.car,writes:[["throttle",0.0],["thrust_y",0.0],["thrust_z",0.0],["brake",1.0]]});
 }
 print("ROADSTER_COMPACT_BOOST "+#{case_name:ctx.case_name,image:this.n,time_s:this.n/60.0,values:v,boost:ctx.boost,
  serviced:this.serviced,takeoff_speed:this.takeoff_speed,blocks:this.blocks,hit_barrier:this.hit_barrier}.to_string());
 this.n+=1;if this.n>=600 {this.done=true;}
}
