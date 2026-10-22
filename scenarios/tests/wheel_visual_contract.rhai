// Headful production gate: raycast wheel contact, one crowned render surface.
fn simulation_dependencies(me,ctx) {
    let car=find_path("/World/Roadster");let reads=[car];
    for corner in ["FL","FR","RL","RR"] {
        reads.push(find_path("/World/Roadster/Wheel_"+corner));
        reads.push(find_path("/World/Roadster/Wheel_"+corner+"/CrownedVisual"));
    }
    #{modelica_entities:[car],entity_reads:reads,entity_writes:[],
      query_reads:["QueryUsdPrim","QueryPhysicsState","ReadPorts"],required_inputs:[]}
}
fn on_start(me,ctx) {this.elapsed=0.0;this.done=false;}
fn on_tick(me,ctx) {
    if this.done {return;}this.elapsed+=dt();
    let ready=true;
    for corner in ["FL","FR","RL","RR"] {
        let visual=find_path("/World/Roadster/Wheel_"+corner+"/CrownedVisual");
        ready=ready && visual>=0 && get(visual,"Mesh3d")!=();
    }
    if !ready && this.elapsed<10.0 {return;}
    let checks=[];
    for corner in ["FL","FR","RL","RR"] {
        let path="/World/Roadster/Wheel_"+corner;
        let wheel=find_path(path);let visual=find_path(path+"/CrownedVisual");
        let authored=query("QueryUsdPrim",#{path:path,schemas:true,attrs:["physxVehicleWheel:radius"]});
        let physics=query("QueryPhysicsState",#{id:wheel});
        checks.push(t_true(authored.type_name=="Xform"
            && near(authored.attrs["physxVehicleWheel:radius"],0.34,1.0e-6)
            && !authored.api_schemas.contains("PhysicsRigidBodyAPI")
            && !authored.api_schemas.contains("PhysicsCollisionAPI") && !physics.collider_present,
            corner+": raycast wheel owns analytical road contact without a rigid wheel collider"));
        checks.push(t_true(get(wheel,"WheelRaycast")!=()
            && get(wheel,"WheelRaycast.visual_entity").to_string()!="None"
            && get(wheel,"Mesh3d")==(),
            corner+": wheel mount binds the crowned visual and contributes no duplicate surface"));
        let material=();
        for part in query("QueryUsdPrim",#{path:path+"/CrownedVisual",attrs:[],topology:true}).topology.parts {
            if part.path==path+"/CrownedVisual" {material=part.materials;}
        }
        checks.push(t_true(visual>=0 && get(visual,"Mesh3d")!=()
            && material!=() && material.shader==path+"/TireLook/Shader"
            && get(visual,"Visibility").to_string().contains("Visible"),
            corner+": crowned tire is the visible shaded wheel mesh"));
    }
    let cabin=query("QueryUsdPrim",#{path:"/World/Roadster/Body/CabinCollider",schemas:true});
    checks.push(t_true(cabin.type_name=="Mesh" && cabin.api_schemas.contains("PhysicsMeshCollisionAPI"),
        "cabin retains its authored mesh collision hull"));
    let mass=();
    for port in query("ReadPorts",#{api_id:find_path("/World/Roadster"),port_names:["vehicle_mass_kg"]}).ports {
        if port.direction=="out" {mass=port.value;}
    }
    checks.push(t_true(mass!=() && near(query("QueryPhysicsState",#{id:find_path("/World/Roadster")}).mass_kg,mass,0.01),
        "the single rigid body carries the complete Modelica vehicle mass"));
    this.done=true;report_verdict(checks,"ROADSTER WHEEL VISUAL CONTRACT","ROADSTER_WHEEL_VISUAL_CONTRACT");
}
