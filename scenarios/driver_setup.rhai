// Presentation and possession only. No per-tick camera or physics writer.
fn simulation_dependencies(me, ctx) {
    let car = find_path("/World/Roadster");
    #{modelica_entities:[car],entity_reads:[car],entity_writes:[car],
      query_reads:[],required_inputs:[]}
}
fn on_start(me, ctx) {
    let car = find_path("/World/Roadster");
    cmd("AcquireControl", #{target:car,bind_camera:true});
    set_camera("ChaseCamera");
}
