// Measured blowdown/force evidence using native free flight, not a Python solver.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts","QueryUsdPrim","QueryPhysicsState"],required_inputs:[]}
}
fn readings(car) {
 let v=#{};
 for p in query("ReadPorts",#{api_id:car,port_names:["full_rear_force_n","full_lift_force_n","full_side_force_n","full_mass_flow_kg_s","actual_mass_flow_kg_s","hover_fraction","lift_net_acceleration","side_yaw_acceleration","launch_mean_force_n","launch_wheel_mean_force_n","launch_boost_mean_force_n","jet_force_x","jet_force_y","jet_force_z","jet_lift_0","jet_lift_1","jet_lift_2","jet_lift_3","thruster_pitch_moment_nm","thruster_yaw_moment_nm","thruster_roll_moment_nm","gas_mass_kg","tank_pressure_pa","tank_temperature_k","vehicle_mass_kg","air_discharge_enabled","pitch_rate_deg_s","yaw_rate_deg_s","roll_rate_deg_s"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 v
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.time=0.0;this.started=false;this.done=false;
 this.bank=query("QueryUsdPrim",#{path:"/World/DriverSetup",attrs:["study:bank"]}).attrs["study:bank"];
 this.channel="ROADSTER_FORCE_"+this.bank;this.last_sample= -1.0;
 this.peak_force=0.0;this.peak_flow=0.0;this.max_lift_moment=0.0;this.guard_time= -1.0;
}
fn on_tick(me,ctx) {
 if this.done {return;}this.time+=dt();let v=readings(this.car);
 if !this.started {
  if this.time<0.1 {return;}
  this.started=true;this.start=this.time;this.initial=v;
 }
 let t=this.time-this.start;
 let force=if this.bank=="REAR" {abs(v.jet_force_z)}else if this.bank=="LIFT" {v.jet_force_y}else{abs(v.jet_force_x)};
 this.peak_force=max(this.peak_force,force);this.peak_flow=max(this.peak_flow,v.actual_mass_flow_kg_s);
 if this.bank=="LIFT" {this.max_lift_moment=max(this.max_lift_moment,abs(v.thruster_pitch_moment_nm)+abs(v.thruster_roll_moment_nm));}
 if v.air_discharge_enabled<0.5 && this.guard_time<0.0 {this.guard_time=t;}
 if t-this.last_sample>=0.05 {
  let row=#{time_s:t,force_n:force,mass_flow_kg_s:v.actual_mass_flow_kg_s,gas_kg:v.gas_mass_kg,
   temperature_k:v.tank_temperature_k,pressure_pa:v.tank_pressure_pa,mass_kg:v.vehicle_mass_kg,
   pitch_moment_nm:v.thruster_pitch_moment_nm,yaw_moment_nm:v.thruster_yaw_moment_nm,roll_moment_nm:v.thruster_roll_moment_nm,
   pitch_rate_deg_s:v.pitch_rate_deg_s,yaw_rate_deg_s:v.yaw_rate_deg_s,roll_rate_deg_s:v.roll_rate_deg_s,
   corner_forces:[v.jet_lift_0,v.jet_lift_1,v.jet_lift_2,v.jet_lift_3]};
  emit(this.channel+"_SAMPLE_EVIDENCE",row);this.last_sample=t;
 }
 cmd("SetPorts",#{target:this.car,writes:[["fan",0.0],["boost",if this.bank=="REAR" {1.0}else{0.0}],
  ["thrust_y",if this.bank=="LIFT" {1.0}else{0.0}],["thrust_x",if this.bank=="SIDE" {1.0}else{0.0}]]});
 if t<2.5 {return;}
 let failures=[];let minimum=if this.bank=="SIDE" {1000.0}else{20000.0};
 if this.peak_force<minimum {failures.push("Insufficient measurable bank thrust");}
 if this.max_lift_moment>0.01 {failures.push("Collective lift did not pass through the assumed COM");}
 if v.gas_mass_kg>=249.9 {failures.push("Thrust did not consume gas");}
 let native=query("QueryPhysicsState",#{id:this.car});
 if abs(native.mass_kg-v.vehicle_mass_kg)>0.1 {failures.push("Native mass did not track blowdown");}
 emit(this.channel+"_EVIDENCE",#{bank:this.bank,initial:this.initial,final:v,peak_force_n:this.peak_force,
  peak_mass_flow_kg_s:this.peak_flow,maximum_collective_moment_nm:this.max_lift_moment,thermal_guard_at_s:this.guard_time,
  native_angular_velocity:native.angular_velocity_radps,failures:failures});
 cmd("SetPorts",#{target:this.car,writes:[["boost",0.0],["thrust_y",0.0],["thrust_x",0.0]]});
 this.done=true;report_verdict(failures,"ROADSTER FORCE "+this.bank,this.channel);
}
