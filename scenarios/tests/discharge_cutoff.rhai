// Production live-input contract. Inputs only; no temperature, mass or pose writes.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts"],required_inputs:[]}
}
fn values(car) {
 let v=#{};
 for p in query("ReadPorts",#{api_id:car,port_names:["tank_temperature_k","tank_temperature_c","thermal_guard_temperature_c","air_discharge_enabled","gas_mass_kg"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 v
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.n=0;this.done=false;this.fail=[];this.samples=[];
 cmd("SetPorts",#{target:this.car,writes:[["discharge_cutoff_c",-130.0]]});
}
fn check(car,expected,enabled) {
 let v=values(car);let failures=[];
 if abs(v.thermal_guard_temperature_c-expected)>1e-9 {failures.push("Live cutoff not consumed: "+expected.to_string());}
 if abs(v.tank_temperature_c-(v.tank_temperature_k-273.15))>1e-9 {failures.push("Celsius output does not match physical kelvin state");}
 if v.air_discharge_enabled!=enabled {failures.push("Discharge gate does not follow the live cutoff");}
 #{sample:v,failures:failures}
}

fn on_tick(me,ctx) {
 if this.done {return;}this.n+=1;
 if this.n==4 {
  let result=check(this.car,-130.0,1.0);
  this.fail+=result.failures;this.samples.push(result.sample);
  cmd("SetPorts",#{target:this.car,writes:[["discharge_cutoff_c",20.0]]});
 }
 if this.n==10 {
  let result=check(this.car,20.0,0.0);
  this.fail+=result.failures;this.samples.push(result.sample);
  cmd("SetPorts",#{target:this.car,writes:[["discharge_cutoff_c",-100.0]]});
 }
 if this.n==16 {
  let result=check(this.car,-100.0,1.0);
  this.fail+=result.failures;this.samples.push(result.sample);
  emit("runtime.ui.action",#{action:"roadster.cutoff.up"});
 }
 if this.n==22 {
  let result=check(this.car,-95.0,1.0);
  this.fail+=result.failures;this.samples.push(result.sample);
  cmd("SetPorts",#{target:this.car,writes:[["discharge_cutoff_c",-130.0]]});
 }
 if this.n==28 {
  let result=check(this.car,-130.0,1.0);
  this.fail+=result.failures;this.samples.push(result.sample);
  let first=this.samples[0];let last=this.samples[this.samples.len()-1];
  if abs(last.gas_mass_kg-first.gas_mass_kg)>0.001 {this.fail.push("Changing cutoff must not refill or reset the inventory");}
  this.done=true;
  emit("ROADSTER_LIVE_CUTOFF_EVIDENCE",#{samples:this.samples,failures:this.fail});
  report_verdict(this.fail,"ROADSTER LIVE CELSIUS CUTOFF","ROADSTER_LIVE_CUTOFF");
 }
}
