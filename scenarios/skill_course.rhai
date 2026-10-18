// High-level checkpoint policy. Never writes pose, velocity, forces or mass.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let metrics=car;
 #{modelica_entities:[car,metrics],entity_reads:[car,metrics],entity_writes:[car,metrics],query_reads:["ReadPorts","QueryPhysicsState"],required_inputs:[]}
}
fn readings(id,names) {
 let out=#{};
 for p in query("ReadPorts",#{api_id:id,port_names:names}).ports {if p.direction=="out" {out[p.name]=p.value;}}
 out
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.metrics=this.car;
 this.stage=0;this.blocks=0;this.previous_z=200.0;this.published_blocks=0;this.auto_supply=false;this.landing_dwell=0.0;
 notify("Skill course: W + Space to reach 60 mph at the blue gate. Shift brakes. Green pads refill while rolling. Ctrl+P pauses for inspection.");
}
fn on_tick(me,ctx) {
 let v=readings(this.car,["position_z","position_y","flight_control_weight"]);
 let m=readings(this.metrics,["launch_gate","refill_zone","refill_ready","jump_clearance","climb_gate","landing_gate"]);
 cmd("SetPorts",#{target:this.car,writes:[["course_position_y",v.position_y]]});
 let z=v.position_z;let previous=this.stage;
 if this.stage==0 {
  if m.launch_gate>0.5 {this.stage=1;notify("Launch cleared. Drive through the GREEN waypoint for an immediate tank refill.");}
  else if z<125.0 {this.stage=8;notify("Missed launch: reach 60 mph with air boost at the BLUE gate. Retry course.");}
 }
 if this.stage==1 || this.stage==3 {
  if m.refill_zone>0.5 {
   if !this.auto_supply {
    let boundary=readings(this.car,["next_mass_offset","next_temperature_offset","next_wall_temperature_offset","next_refill_count","next_mechanical_energy_j","next_stored_energy_j"]);
    let writes=[];
    for name in ["mass_offset","temperature_offset","wall_temperature_offset","refill_count","mechanical_energy_j","stored_energy_j"] {
     writes.push(["instant_"+name,boundary["next_"+name]]);
    }
    cmd("SetPorts",#{target:this.car,writes:writes});this.auto_supply=true;
   }
   if m.refill_ready>0.5 {
    this.stage+=1;
    if this.stage==2 {notify("Refilled. Build 65–85 km/h, turn fans OFF, then tap K at the yellow line to clear all three blocks.");}
    else {notify("Refilled. Fans ON. Approach ramp at 35–45 km/h and use W to climb to the green crest marker.");}
   }
  } else if this.auto_supply {this.auto_supply=false;}
  if (this.stage==1 && z<32.0) || (this.stage==3 && z< -208.0) {
   this.stage=8;notify("Green waypoint missed. Drive between its posts; refill is immediate, with no stop. Retry course.");
  }
 }
 if this.stage!=1 && this.stage!=3 && this.auto_supply {
  this.auto_supply=false;
 }
 if this.stage==2 && this.blocks<3 {
  let barrier_z= -100.0-8.0*this.blocks;
  if this.previous_z>barrier_z && z<=barrier_z {
   if m.jump_clearance>0.5 {this.blocks+=1;}
   else {this.stage=8;notify("Block missed. Build speed and time a short K pulse at the yellow takeoff line. Retry course.");}
   if this.blocks==3 {this.stage=3;notify("Three blocks cleared. Continue through the next GREEN waypoint for an immediate refill.");}
  }
 }
 if this.stage==4 && m.climb_gate>0.5 {this.stage=5;notify("Fan climb cleared. Follow the return lip to the green crest, then fans OFF. Use Q/E to pitch.");}
 if this.stage==5 && v.flight_control_weight>0.8 && v.position_y>20.0 {
  this.stage=6;notify("Manual flip: Q nose up; E nose down. Pulse opposing jets to stop rotation. J/L yaw, U/O roll, K body-up thrust. WASD stays drivetrain. Land wheels DOWN, Shift to stop.");
 }
 if this.stage==6 {
  if m.landing_gate>0.5 {
   let contacts=0;
   for w in query("QueryPhysicsState",#{id:this.car}).wheel_contacts {if w.contact_valid {contacts+=1;}}
   if contacts==4 {this.landing_dwell+=dt();}else{this.landing_dwell=0.0;}
  } else {this.landing_dwell=0.0;}
  if this.landing_dwell>0.5 {this.stage=7;notify("COURSE COMPLETE: launch, timed jump, fan climb and manual flip landed on four wheels.");}
 }
 if this.stage!=previous {cmd("SetPorts",#{target:this.metrics,writes:[["course_phase",this.stage*1.0]]});}
 if this.blocks!=this.published_blocks {cmd("SetPorts",#{target:this.metrics,writes:[["course_blocks_passed",this.blocks*1.0]]});this.published_blocks=this.blocks;}
 this.previous_z=z;
}
