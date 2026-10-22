// Isolate native collision integration from Modelica and vehicle joints.
fn simulation_dependencies(me,ctx) {
 #{modelica_entities:[],entity_reads:[find_path("/World/Tire")],entity_writes:[],query_reads:["QueryPhysicsState","QueryUsdPrim"],required_inputs:[]}
}
fn on_start(me,ctx) {this.t=0.0;this.minimum_y=6.0;this.maximum_penetration=0.0;this.contact_ticks=0;this.done=false;}
fn on_tick(me,ctx) {
 if this.done {return;}this.t+=dt();let tire=find_path("/World/Tire");let p=world_pos(tire);
 this.minimum_y=min(this.minimum_y,p[1]);
 let contact=contact_debug(tire);
 this.maximum_penetration=max(this.maximum_penetration,contact.max_penetration);
 if contact.touching_pair_count>0 {this.contact_ticks+=1;}
 if this.t<3.0 {return;}
 let native=query("QueryPhysicsState",#{id:tire});
 let authored=query("QueryUsdPrim",#{path:"/World/Tire",attrs:["radius","height"]}).attrs;
 let bounds=native.collider_local_bounds;
 let failures=[];
 failures.push(t_true(abs(bounds.max[0]-authored.height/2.0)<0.000001
  && abs(bounds.max[1]-authored.radius)<0.000001
  && abs(bounds.max[2]-authored.radius)<0.000001,"Authored X-axis cylinder has the same native body-local bounds"));
 // A free tire can tip onto its side; native contact penetration is independent
 // of that physically valid change in its center height.
 failures.push(t_true(this.maximum_penetration<=0.003,"Native isolated tire stays within 3 mm contact penetration"));
 failures.push(t_true(this.contact_ticks>10 && contact.touching_pair_count>0,"Native tire reaches sustained ground contact"));
 failures.push(t_true(this.minimum_y>0.0,"Native tire remains above the solid ground"));
 emit("ROADSTER_NATIVE_WHEEL_EVIDENCE",#{minimum_y:this.minimum_y,maximum_penetration_m:this.maximum_penetration,
  contact_ticks:this.contact_ticks,position:p,native:native,failures:failures});
 this.done=true;report_verdict(failures,"NATIVE WHEEL DROP","ROADSTER_NATIVE_WHEEL");
}
