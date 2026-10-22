// Modelica owns the impact-energy envelope; this policy owns its reaction.
fn simulation_dependencies(me,ctx) {
 let car=me;
 #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],
   query_reads:["ReadPorts"],required_inputs:[]}
}
fn readings(car,names) {
 let values=#{};
 for port in query("ReadPorts",#{api_id:car,port_names:names}).ports {
  if port.direction=="out" {values[port.name]=port.value;}
 }
 for name in names {if !values.contains(name) {throw("Missing impact observation: "+name);}}
 values
}
fn on_start(me,ctx) {
 this.car=me;subscribe("roadster.roof-overload");
}
fn on_event(me,evt,ctx) {
 if evt.name=="roadster.roof-overload" && evt.source==this.car {
  let impact=readings(this.car,["roof_impact_capacity_j"]);
  let result=cmd("PauseSimulationObject",#{target:this.car,condition:"roadster:roof-impact-overload",
   detail:"Cabin impact energy exceeded the authored study absorption envelope="
    +impact.roof_impact_capacity_j.to_string()+" J. Mission failed; the complete coupled vehicle is paused. Review impact conditions before restarting."});
  if result.ok!=true {throw("Roof impact could not pause its coupled vehicle: "+result);}
 }
}
