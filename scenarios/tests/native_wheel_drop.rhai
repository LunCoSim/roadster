// Isolate native collision integration from Modelica and vehicle joints.
fn simulation_dependencies(me,ctx) {
 #{modelica_entities:[],entity_reads:[find_path("/World/Tire")],entity_writes:[],query_reads:["QueryPhysicsState"],required_inputs:[]}
}
fn on_start(me,ctx) {this.t=0.0;this.minimum_y=6.0;this.done=false;}
fn on_tick(me,ctx) {
 if this.done {return;}this.t+=dt();let tire=find_path("/World/Tire");let p=world_pos(tire);
 this.minimum_y=min(this.minimum_y,p[1]);
 if this.t<3.0 {return;}
 let failures=[];if this.minimum_y<0.337 {failures.push("Native isolated tire penetrated the ground");}
 emit("ROADSTER_NATIVE_WHEEL_EVIDENCE",#{minimum_y:this.minimum_y,position:p,native:query("QueryPhysicsState",#{id:tire}),failures:failures});
 this.done=true;report_verdict(failures,"NATIVE WHEEL DROP","ROADSTER_NATIVE_WHEEL");
}
