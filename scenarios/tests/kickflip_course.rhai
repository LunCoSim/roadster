// Observe the ordinary course and its native contact pairs; no body-state writes.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let reads=[car];
 for corner in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+corner));}
 for i in 0..3 {reads.push(find_path("/World/JumpBlock"+i.to_string()));}
 #{modelica_entities:[car],entity_reads:reads,entity_writes:[],query_reads:[],required_inputs:[]}
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.done=false;this.hit=false;this.peak_impulse=0.0;this.peak_roll=0.0;
 this.bodies=[this.car];this.blocks=[];
 for corner in ["FL","FR","RL","RR"] {this.bodies.push(find_path("/World/Roadster/Wheel_"+corner));}
 for i in 0..3 {this.blocks.push(find_path("/World/JumpBlock"+i.to_string()));}
}
fn on_tick(me,ctx) {
 let c=this.car;let row=#{tick:clock_snapshot().sim_tick};
 for name in ["course_stage","course_failure_reason","instant_services","course_blocks",
   "course_jump_roll_degrees","course_jump_roll_ready","position_x","position_y","position_z",
   "attitude_w","attitude_x","attitude_y","attitude_z","roll_rate_deg_s","up_alignment",
   "gas_mass_kg","tank_temperature_k","thermal_guard_active","speed_mps"] {row[name]=get(c,name);}
 if row.course_stage>=2 && row.course_stage<4 && row.position_z< -94 && row.position_z> -132 {
  for block in this.blocks {for body in this.bodies {
   let contact=contact_debug(body,block);
   let impulse=contact.total_normal_impulse+contact.continuous_normal_impulse;
   this.peak_impulse=max(this.peak_impulse,impulse);if impulse>1.0 {this.hit=true;}
  }}
 }
 row.barrier_contact=this.hit;row.peak_barrier_impulse=this.peak_impulse;
 this.peak_roll=max(this.peak_roll,abs(row.course_jump_roll_degrees));row.peak_roll_degrees=this.peak_roll;
 print("ROADSTER_KICKFLIP_ROW "+row.to_string());
 if !this.done && row.course_stage>=4 {
  this.done=true;
  report_verdict([
   t_true(row.course_stage<8,"course remains healthy after the obstacle jump"),
   t_true(row.course_blocks==3,"all three obstacles crossed"),
   t_true(this.peak_roll>=355 && this.peak_roll<405,"measured complete body revolution before recovery bank"),
   t_true(row.up_alignment>0.97 && abs(row.roll_rate_deg_s)<35,"upright attitude and roll-rate recovery"),
   t_true(!this.hit,"no native car/wheel collision with the obstacles"),
   t_true(row.instant_services==2,"ordinary green services, finite air")
  ],"KICKFLIP COURSE","ROADSTER_KICKFLIP");
 }
}
