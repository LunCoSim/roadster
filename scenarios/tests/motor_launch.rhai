// Motor-only standing start: native contact/shaft physics, no gas boost.
fn simulation_dependencies(me, ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car,find_path("/World/Roadster/Wheel_RL")],entity_writes:[car],query_reads:["ReadPorts"],required_inputs:[]}
}
fn sample(car,name) {
 for p in query("ReadPorts",#{api_id:car,port_names:[name]}).ports {
  if p.name==name && p.direction=="out" { return p.value; }
 }
 throw("Missing output "+name);
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster"); this.elapsed=0.0; this.started=false; this.done=false;
 this.samples=[]; this.peak_power=0.0; this.crossing=(); this.previous_speed=0.0; this.previous_time=0.0;
 cmd("SetPorts",#{target:this.car,writes:[["brake",1.0],["boost",0.0],["lift",0.0],["fan",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;} this.elapsed+=dt(); if this.elapsed<2.0 {return;}
 if !this.started {
  this.started=true; this.start=this.elapsed;
  drive(this.car,1.0,0.0); cmd("SetPorts",#{target:this.car,writes:[["brake",0.0]]}); return;
 }
 let t=this.elapsed-this.start; let v=-sample(this.car,"velocity_z");
 this.peak_power=max(this.peak_power,sample(this.car,"battery_power"));
 if this.crossing==() && v>=26.8224 {
  this.crossing=this.previous_time+(26.8224-this.previous_speed)/(v-this.previous_speed)*(t-this.previous_time);
 }
 if this.samples.len==0 || t-this.samples[this.samples.len-1].time_s>=0.1 {
  let wheel=find_path("/World/Roadster/Wheel_RL");
  this.samples.push(#{time_s:t,speed_m_s:v,wheel_rad_s:get(wheel,"WheelRaycast.spin_velocity"),
   torque_nm:sample(this.car,"torque_left"),battery_power_w:sample(this.car,"battery_power"),
   downforce_n:sample(this.car,"downforce"),gas_mass_kg:sample(this.car,"gas_mass_kg")});
 }
 this.previous_speed=v; this.previous_time=t;
 if t<7.0 {return;}
 emit("ROADSTER_MOTOR_EVIDENCE",#{standing_start_0_60_s:this.crossing,final_speed_m_s:v,samples:this.samples});
 brake(this.car); this.done=true;
 let failures=[];
 if this.crossing==() {failures.push("Motor-only car failed to reach 60 mph within seven simulated seconds");}
 if this.peak_power<500000.0 {failures.push("Full throttle never used half the rated power");}
 if abs(sample(this.car,"gas_mass_kg")-250.0)>0.000001 {failures.push("Motor-only launch consumed gas");}
 let wheel=find_path("/World/Roadster/Wheel_RL");
 if abs(get(wheel,"WheelRaycast.spin_velocity")*0.34-v)>0.2*v {failures.push("Wheel peripheral speed does not track road speed");}
 report_verdict(failures,"ROADSTER MOTOR LAUNCH","ROADSTER_MOTOR");
}
