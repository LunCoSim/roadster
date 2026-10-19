// Acceptance driver only. Native contacts/joints and Modelica own all physics.
fn simulation_dependencies(me,ctx) {
 let car=find_path("/World/Roadster");let reads=[car];
 for n in ["FL","FR","RL","RR"] {reads.push(find_path("/World/Roadster/Wheel_"+n));reads.push(find_path("/World/Roadster/Suspension_"+n));}
 for n in ["FL","FR"] {reads.push(find_path("/World/Roadster/SteeringKnuckle_"+n));}
 #{modelica_entities:[car],entity_reads:reads,entity_writes:[car],query_reads:["QueryUsdPrim","QueryPhysicsState","ReadPorts"],required_inputs:[]}
}
fn values(car) {
 let v=#{};
 for p in query("ReadPorts",#{api_id:car,port_names:["flight_control_weight","gas_mass_kg","tank_pressure_pa","tank_temperature_k","unlimited_air_active","ideal_supply_air_kg","actual_mass_flow_kg_s","jet_force_z","thruster_pitch_moment_nm","pitch_rate_deg_s","roll_rate_deg_s","up_alignment","vehicle_mass_kg","speed_mps","next_mass_offset","next_temperature_offset","next_wall_temperature_offset","next_refill_count","next_mechanical_energy_j","next_stored_energy_j"]}).ports {if p.direction=="out" {v[p.name]=p.value;}}
 v
}
fn on_start(me,ctx) {
 this.car=find_path("/World/Roadster");this.t=0.0;this.done=false;this.fail=[];this.samples=[];
 this.kind=query("QueryUsdPrim",#{path:"/World/DriverSetup",attrs:["study:case"]}).attrs["study:case"];
 this.geometry_observed=false;this.initial_radial_error=0.0;this.radial_error=0.0;this.last_geometry_error_s=0.0;this.geometry_error_ticks=0;this.max_bump=0.0;this.min_bump=0.0;this.max_penetration=0.0;this.max_ground_penetration=0.0;this.max_pitch=0.0;this.landed=false;this.upright=false;
 this.m0=0.0;this.t0=0.0;this.finite=();this.worst=#{};this.airborne_observation_error=0.0;
 cmd("SetPorts",#{target:this.car,writes:[["fan",0.0],["unlimited_air",1.0]]});
}
fn on_tick(me,ctx) {
 if this.done {return;}this.t+=dt();let v=values(this.car);let pos=world_pos(this.car);let rot=world_rotation(this.car);
 if this.t>0.05 && this.kind=="DROP" && pos[1]>3.0 && v.up_alignment>0.95 {this.airborne_observation_error=max(this.airborne_observation_error,1.0-v.flight_control_weight);}
 let inv=[-rot[0],-rot[1],-rot[2],rot[3]];let wheels=[];
 for n in ["FL","FR","RL","RR"] {
  let wheel=find_path("/World/Roadster/Wheel_"+n);let native=query("QueryPhysicsState",#{id:wheel});
  if !native.collider_present || native.body_mode!="dynamic" {this.fail.push("Wheel is not a collision-backed dynamic body: "+n);}
  let bounds=native.colliders[0].shape_local_bounds;
  for axis in [1,2] {
   let radial=max(abs(bounds.min[axis]+0.34),abs(bounds.max[axis]-0.34));
   if !this.geometry_observed {this.initial_radial_error=max(this.initial_radial_error,radial);continue;}
   if radial>0.00001 {this.last_geometry_error_s=this.t;this.geometry_error_ticks+=1;}
   if radial>this.radial_error {this.worst.geometry=#{time_s:this.t,wheel:n,bounds:bounds,scale:native.colliders[0].scale};}
   this.radial_error=max(this.radial_error,radial);
  }
  let wp=world_pos(wheel);
  let local=qrot(inv,vsub(wp,pos));let stroke=local[1]+0.21;
  let detail=#{time_s:this.t,car_position:pos,car_rotation:rot,wheel:n,wheel_position:wp,wheel_rotation:world_rotation(wheel),local:local,stroke_m:stroke,up_alignment:v.up_alignment};
  if this.kind=="DROP" && v.up_alignment>0.95 {
   let penetration=max(0.0,0.34-wp[1]);
   if penetration>this.max_ground_penetration {this.worst.ground=detail;}
   this.max_ground_penetration=max(this.max_ground_penetration,penetration);
  }
  if stroke>this.max_bump {this.worst.bump=detail;}
  if stroke<this.min_bump {this.worst.droop=detail;}
  this.max_bump=max(this.max_bump,stroke);this.min_bump=min(this.min_bump,stroke);
  let c=contact_debug(wheel);this.max_penetration=max(this.max_penetration,c.max_penetration);
  wheels.push(#{name:n,world:wp,native_center:native.colliders[0].physics_position_m,ccd:native.continuous_collision_enabled,collider_body:native.colliders[0].body_usd_prim_path,owner_present:native.colliders[0].body_relationship_present,owner_matches:native.colliders[0].body_is_query_body,local:local,stroke_m:stroke,contact:c.touching_pair_count,penetration:c.max_penetration});
 }
 this.geometry_observed=true;
 if this.t>0.15 && this.t<0.5 {this.max_pitch=max(this.max_pitch,abs(v.pitch_rate_deg_s));}
 if this.kind=="DROP" {
  let boost=if this.t>0.12 && this.t<0.45 {1.0}else{0.0};
  let supply=if this.t<0.65 || this.t>1.0 {1.0}else{0.0};
  if this.t<0.12 {this.m0=v.gas_mass_kg;this.t0=v.tank_temperature_k;}
  if this.t>0.5 && this.t<0.65 {
   if abs(v.gas_mass_kg-this.m0)>0.0001 || abs(v.tank_temperature_k-this.t0)>0.0001 {this.fail.push("Unlimited mass/temperature drift");}
  }
  if this.t>=0.65 && this.t<0.95 {boost=1.0;}
  if this.t>=0.95 && this.finite==() {this.finite=v;}
  cmd("SetPorts",#{target:this.car,writes:[["boost",boost],["unlimited_air",supply],["brake",if this.t>2.0 {1.0}else{0.0}]]});
  if this.t>2.0 && pos[1]<0.7 && v.up_alignment>0.95 {this.landed=true;}
 }else{
  // Same manual Q/E banks: pulse the low side, then counterpulse the high side.
  let left=if this.kind=="LEFT" {1.0}else{0.0};
  let primary=if this.t>0.6 && this.t<0.85 {1.0}else{0.0};
  let counter=if this.t>1.10 && this.t<1.35 {1.0}else{0.0};
  let q=left*primary+(1.0-left)*counter;let e=(1.0-left)*primary+left*counter;
  cmd("SetPorts",#{target:this.car,writes:[["lift_fl",q],["lift_rl",q],["lift_fr",e],["lift_rr",e],["brake",1.0]]});
  if this.t>0.65 && v.up_alignment>0.95 {this.upright=true;}
 }
 if this.samples.len==0 || this.t-this.samples[this.samples.len-1].time_s>0.2 {
  let sample=#{time_s:this.t,pos:pos,rotation:rot,values:v,wheels:wheels};
  this.samples.push(sample);emit("ROADSTER_CONTACT_RECOVERY_SAMPLE_EVIDENCE",sample);
 }
 if this.t<20.0 {return;}
 if v.ideal_supply_air_kg<50.0 && this.kind=="DROP" {this.fail.push("Ideal source mass ledger did not record delivered air");}
 if this.airborne_observation_error>0.01 {this.fail.push("Internal clearance query hit the airborne vehicle itself");}
 if this.radial_error>0.00001 {this.fail.push("Physical wheel collider lost its analytic radius");}
 if this.max_bump>0.068 || this.min_bump< -0.058 {this.fail.push("Suspension exceeded authored bump/droop limits");}
 if this.kind=="DROP" {
  if this.max_ground_penetration>0.003 {this.fail.push("Wheel penetrated the ground after physics writeback");}
  if !this.landed {this.fail.push("Drop did not land wheels down");}
  if this.max_pitch>2.0 {this.fail.push("Rear thrust pitched the free car");}
  if this.finite==() || this.finite.gas_mass_kg>249.0 || this.finite.tank_temperature_k>this.t0-1.0 {this.fail.push("Finite air did not resume blowdown/cooling");}
 }else{if !this.upright {this.fail.push("Side bank did not right the car");}}
 emit("ROADSTER_CONTACT_RECOVERY_EVIDENCE",#{kind:this.kind,duration_s:this.t,substeps:physics_substeps(),maximum_airborne_observation_error:this.airborne_observation_error,maximum_radial_extent_error_m:this.radial_error,initial_geometry_snapshot_error_m:this.initial_radial_error,last_geometry_error_s:this.last_geometry_error_s,geometry_error_count:this.geometry_error_ticks,maximum_bump_m:this.max_bump,minimum_bump_m:this.min_bump,maximum_penetration_m:this.max_penetration,maximum_ground_penetration_m:this.max_ground_penetration,
  maximum_boost_pitch_rate_deg_s:this.max_pitch,landed:this.landed,upright:this.upright,finite:this.finite,final:v,worst:this.worst,failures:this.fail});
 cmd("SetPorts",#{target:this.car,writes:[["boost",0.0],["lift_fl",0.0],["lift_rl",0.0],["lift_fr",0.0],["lift_rr",0.0]]});
 this.done=true;report_verdict(this.fail,"ROADSTER CONTACT RECOVERY","ROADSTER_CONTACT_RECOVERY");
}
