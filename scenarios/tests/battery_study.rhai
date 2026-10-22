// Observe the actual Modelica energy ledger and native mass/inertia. No Python
// physics and no pose/velocity/inventory writes. Assumptions: BatteryStudy.mo.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let reads=[car];
 #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],query_reads:["ReadPorts","QueryPhysicsState","QueryUsdPrim"],required_inputs:[]}
}
fn values(car) {
 let v=#{};
 for p in query("ReadPorts",#{api_id:car,port_names:["battery_nominal_energy_kwh","battery_range_energy_kwh",
  "battery_range_proxy_km","battery_inferred_capacity_kwh","battery_pack_mass_estimate_kg",
  "battery_pack_volume_estimate_l","battery_non_pack_reference_mass_kg","battery_peak_dc_power_kw",
  "battery_peak_equivalent_c","battery_charge_10_80_energy_kwh","battery_charge_10min_average_kw",
  "battery_charge_12min_average_kw","battery_energy_remaining_kwh","battery_power","soc",
  "gas_mass_kg","gas_capacity_mass_kg","tank_volume_m3","cabin_tank_air_kg","vehicle_mass_kg","chassis_mass_kg",
  "chassis_inertia_xx","chassis_inertia_yy","chassis_inertia_zz"]}).ports {
  if p.direction=="out" {v[p.name]=p.value;}
 }
 v
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.measuring=false;this.power_integral_j=0.0;
 cmd("SetPorts",#{target:this.car,writes:[["brake",1.0],["fan",0.0],["boost",0.0],["lift",0.0]]});
}
fn begin(me) {this.initial=values(this.car);this.measuring=true;}
fn task(me,ctx) {seq([wait(2.0),once(Fn("begin")),wait(1.0),once(Fn("finish"))])}
fn on_tick(me,ctx) {
 if this.measuring {this.power_integral_j+=values(this.car).battery_power*dt();}
}
fn finish(me) {
 this.measuring=false;let v=values(this.car);let failures=[];
 let attrs=query("QueryUsdPrim",#{path:"/World/Roadster",attrs:["inputs:battery_capacity_kwh","inputs:boost_available","inputs:rear_tank_volume","inputs:cabin_tank_volume"]}).attrs;
 let requested=attrs["inputs:battery_capacity_kwh"];
 let native=query("QueryPhysicsState",#{id:this.car});let total=native.mass_kg;
 let energy_debit_j=(this.initial.battery_energy_remaining_kwh-v.battery_energy_remaining_kwh)*3600000.0;
 let balance_error=abs(energy_debit_j-this.power_integral_j);
 if abs(v.battery_nominal_energy_kwh-requested)>0.0001 {failures.push("USD battery parameter was not admitted");}
 if requested<=100.0 {failures.push("Study energy must exceed the published qualitative floor");}
 if v.battery_pack_mass_estimate_kg<=0.0 || v.battery_non_pack_reference_mass_kg<=0.0 {failures.push("Invalid battery mass budget");}
 if abs(total-v.vehicle_mass_kg)>0.05 || abs(native.mass_kg-v.chassis_mass_kg)>0.05 {failures.push("Native mass did not follow battery sizing");}
 let expected=v.battery_non_pack_reference_mass_kg+v.battery_pack_mass_estimate_kg+attrs["inputs:boost_available"]*v.gas_mass_kg;
 if abs(expected-v.vehicle_mass_kg)>0.05 {failures.push("Reference pack was double counted or mass delta lost");}
 if energy_debit_j<=0.0 || balance_error>100.0 {failures.push("Battery energy ledger does not match observed DC power");}
 if v.soc>=this.initial.soc {failures.push("SOC did not consume energy");}
 let inertia=[v.chassis_inertia_xx,v.chassis_inertia_yy,v.chassis_inertia_zz];
 // The API returns principal eigenvalues without promising axis order.
 let native_spectrum=native.inertia_principal_kgm2;inertia.sort();native_spectrum.sort();
 for i in 0..3 {if inertia[i]<=0.0 || abs(native_spectrum[i]-inertia[i])>0.02 {failures.push("Battery inertia spectrum did not reach native chassis");}}
 if attrs["inputs:cabin_tank_volume"]==0.0 && v.cabin_tank_air_kg>0.00001 {failures.push("Thrust trim retained a cabin tank inventory");}
 emit("ROADSTER_BATTERY_EVIDENCE",#{requested_kwh:requested,initial:this.initial,final:v,
  native_mass_kg:native.mass_kg,total_native_mass_kg:total,native_inertia:native.inertia_principal_kgm2,
  observed_power_integral_j:this.power_integral_j,energy_debit_j:energy_debit_j,energy_balance_error_j:balance_error,failures:failures});
 report_verdict(failures,"ROADSTER BATTERY STUDY","ROADSTER_BATTERY");
}
