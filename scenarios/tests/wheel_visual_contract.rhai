// Headful production gate: analytic wheel contact, one crowned render surface.
fn simulation_dependencies(me,ctx) {
    let car=find_path("/World/Roadster");let reads=[car];
    for corner in ["FL","FR","RL","RR"] {
        reads.push(find_path("/World/Roadster/Wheel_"+corner));
        reads.push(find_path("/World/Roadster/Wheel_"+corner+"/CrownedVisual"));
    }
    #{modelica_entities:[car],entity_reads:reads,entity_writes:[],
      query_reads:["QueryUsdPrim","QueryPhysicsState"],required_inputs:[]}
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
        let authored=query("QueryUsdPrim",#{path:path,schemas:true,attrs:["axis","radius","height","purpose","proxyVisibility"]});
        let physics=query("QueryPhysicsState",#{id:wheel});
        checks.push(t_true(authored.type_name=="Cylinder" && authored.attrs.axis=="X"
            && near(authored.attrs.radius,0.34,1.0e-12)
            && !authored.api_schemas.contains("PhysicsMeshCollisionAPI") && physics.collider_present,
            corner+": native analytic cylinder remains the collision owner"));
        checks.push(t_true(get(wheel,"PhysicalWheel")!=()
            && get(wheel,"PhysicalWheel.visual_entity").to_string()!="None"
            && get(wheel,"Visibility").to_string().contains("Hidden"),
            corner+": collision proxy contributes no rendered wheel surface"));
        let material=query("QueryUsdPrim",#{path:path+"/CrownedVisual",attrs:[],topology:true}).topology.parts[0].materials;
        checks.push(t_true(visual>=0 && get(visual,"Mesh3d")!=()
            && material.shader==path+"/TireLook/Shader"
            && get(visual,"Visibility").to_string().contains("Visible"),
            corner+": crowned tire is the visible shaded wheel mesh"));
    }
    let cabin=query("QueryUsdPrim",#{path:"/World/Roadster/Body/CabinCollider",schemas:true});
    checks.push(t_true(cabin.type_name=="Mesh" && cabin.api_schemas.contains("PhysicsMeshCollisionAPI"),
        "cabin retains its authored mesh collision hull"));
    this.done=true;report_verdict(checks,"ROADSTER WHEEL VISUAL CONTRACT","ROADSTER_WHEEL_VISUAL_CONTRACT");
}
