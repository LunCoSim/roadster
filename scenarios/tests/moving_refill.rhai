// Finite-flow external refill acceptance; no state reset or pressure writes.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn sample(car,name) {
 for p in query("ReadPorts",#{api_id:car,port_names:[name]}).ports {
  if p.name==name && p.direction=="out" {return p.value;}
 }
 throw("Missing output "+name);
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.elapsed=0.0;this.stage=0;this.done=false;this.samples=[];
 this.refill_speed_min=1000.0;this.refill_speed_max=0.0;this.loading_force_max=0.0;this.min_mass=250.0;this.peak_flow=0.0;this.peak_service_power=0.0;
 cmd("SetPorts",#{target:this.car,writes:[["brake",1.0],["fan",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;} this.elapsed+=dt();
 this.min_mass=min(this.min_mass,sample(this.car,"gas_mass_kg"));
 this.peak_flow=max(this.peak_flow,sample(this.car,"refill_flow_kg_s"));
 this.peak_service_power=max(this.peak_service_power,sample(this.car,"service_power_w"));
 if this.stage==0 && this.elapsed>=2.0 {cmd("SetPorts",#{target:this.car,writes:[["thrust_z",1.0]]});this.stage=1;}
 if this.stage==1 && this.elapsed>=2.2 {cmd("SetPorts",#{target:this.car,writes:[["thrust_z",0.0]]});this.stage=2;}
 if this.stage==2 && this.elapsed>=3.0 {cmd("SetPorts",#{target:this.car,writes:[["brake",0.0]]});drive(this.car,0.2,0.0);}
 if this.stage==2 && this.elapsed>=4.0 && sample(this.car,"speed_mps")>3.0 && sample(this.car,"refill_allowed")>0.5 {
  this.before=#{mass:sample(this.car,"gas_mass_kg"),temperature:sample(this.car,"tank_temperature_k"),pressure:sample(this.car,"tank_pressure_pa")};
  cmd("SetPorts",#{target:this.car,writes:[["refill_target_temperature_k",303.15],["refill",1.0]]});this.stage=3;
 }
 if this.stage==3 {
  let speed=sample(this.car,"speed_mps");
  drive(this.car,max(0.021,min(0.3,0.1*(6.0-speed))),0.0);
  this.refill_speed_min=min(this.refill_speed_min,speed);this.refill_speed_max=max(this.refill_speed_max,speed);
  this.loading_force_max=max(this.loading_force_max,sample(this.car,"refill_momentum_force_n"));
 }
 if this.stage==3 && sample(this.car,"refill_complete")>0.5 {
  drive(this.car,0.0,0.0);cmd("SetPorts",#{target:this.car,writes:[["refill",0.0],["brake",1.0]]});this.stage=4;this.completed_at=this.elapsed;
 }
 if this.stage==3 && (this.samples.len==0 || this.elapsed-this.samples[this.samples.len-1].time_s>0.2) {
  this.samples.push(#{time_s:this.elapsed,mass:sample(this.car,"gas_mass_kg"),temperature:sample(this.car,"tank_temperature_k"),pressure:sample(this.car,"tank_pressure_pa"),flow:sample(this.car,"refill_flow_kg_s")});
 }
 if this.stage!=4 && this.elapsed<30.0 {return;}
 if this.stage==4 && this.elapsed<this.completed_at+0.5 {return;}
 let mass=sample(this.car,"gas_mass_kg");let air_used=sample(this.car,"service_air_used_kg");
 let failures=[];
 if this.refill_speed_min<1.0 {failures.push("Moving refill required a stop");}
 if this.loading_force_max<10.0 {failures.push("No variable-mass inlet momentum loading");}
 let native_mass=query("QueryPhysicsState",#{id:this.car}).mass_kg;
 if abs(native_mass-1950.0)>0.01 {failures.push("Native mass not updated after refill");}
 if this.stage!=4 {failures.push("Refill did not complete");}
 if this.min_mass>245.0 {failures.push("Test did not deplete air first");}
 if abs(mass-250.0)>0.01 {failures.push("Refill mass did not reach target");}
 if abs(sample(this.car,"tank_temperature_k")-303.15)>0.11 {failures.push("Refill temperature outside reference tolerance");}
 if abs(sample(this.car,"tank_pressure_pa")-sample(this.car,"refill_target_pressure_pa"))>10000.0 {failures.push("EOS pressure did not recover");}
 if this.peak_flow>20.0001 || this.peak_flow<1.0 {failures.push("Inflow not finite and bounded");}
 if abs(air_used-(mass-this.min_mass))>0.05 {failures.push("External and tank air mass do not balance");}
 if sample(this.car,"service_energy_j")<=0.0 {failures.push("No external service energy accounted");}
 if abs(sample(this.car,"vehicle_mass_kg")-1950.0)>0.01 {failures.push("Vehicle mass did not recover");}
 emit("ROADSTER_MOVING_REFILL_EVIDENCE",#{before:this.before,native_mass_kg:native_mass,refill_speed_min_mps:this.refill_speed_min,refill_speed_max_mps:this.refill_speed_max,peak_inlet_momentum_force_n:this.loading_force_max,refill_target_k:sample(this.car,"refill_target_k"),target_pressure_pa:sample(this.car,"refill_target_pressure_pa"),final_mass_kg:mass,final_temperature_k:sample(this.car,"tank_temperature_k"),
  final_pressure_pa:sample(this.car,"tank_pressure_pa"),external_air_used_kg:air_used,external_energy_j:sample(this.car,"service_energy_j"),
  peak_flow_kg_s:this.peak_flow,peak_service_power_w:this.peak_service_power,samples:this.samples,failures:failures});
 this.done=true;report_verdict(failures,"ROADSTER REFILL","ROADSTER_MOVING_REFILL");
}
