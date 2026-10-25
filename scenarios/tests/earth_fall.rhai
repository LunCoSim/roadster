fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],query_reads:["ReadPorts"],required_inputs:[]}
}
fn value(car,name) {
 for p in query("ReadPorts",#{api_id:car,port_names:[name]}).ports {if p.name==name && p.direction=="out" {return p.value;}}
 throw("Missing port "+name);
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.elapsed=0.0;this.done=false;this.first=();
 this.initial_y=world_pos(this.car)[1];this.initial_vy=value(this.car,"velocity_y");
 cmd("SetPorts",#{target:this.car,writes:[["fan",0.0],["brake",0.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;}this.elapsed+=dt();
 if this.first==() {this.first=#{time:this.elapsed,vy:value(this.car,"velocity_y"),y:world_pos(this.car)[1],soc:value(this.car,"soc")};return;}
 if this.elapsed<0.5 {return;}
 let vy=value(this.car,"velocity_y");let measured_g=-(vy-this.first.vy)/(this.elapsed-this.first.time);
 let failures=[];
 if measured_g<9.5 || measured_g>10.1 {failures.push("Native free-fall acceleration is not Earth gravity");}
 if value(this.car,"jet_force_y")>0.01 || value(this.car,"downforce")>0.01 {failures.push("Fall test has active lift or suction");}
 let total_speed=value(this.car,"speed_mps");let road_speed=value(this.car,"longitudinal_speed_mps");
 if total_speed<4.0 || road_speed>0.05 {failures.push("Speedometer must distinguish a vertical fall from longitudinal travel");}
 let soc=value(this.car,"soc");
 if this.first.soc<0.9999 || soc>=this.first.soc || soc<0.999 {failures.push("Battery must initialize full and expend stored energy on the active auxiliary loads");}
 emit("ROADSTER_EARTH_EVIDENCE",#{elapsed_s:this.elapsed-this.first.time,initial_y:this.first.y,final_y:world_pos(this.car)[1],
  initial_vy:this.first.vy,final_vy:vy,measured_acceleration_m_s2:measured_g,total_speed_mps:total_speed,longitudinal_speed_mps:road_speed,
  initial_soc:this.first.soc,final_soc:soc,failures:failures});
 this.done=true;report_verdict(failures,"ROADSTER EARTH GRAVITY","ROADSTER_EARTH");
}
