// @timing presentation
// Explicit authoring program, never attached to the vehicle or a normal scene.
// RunScenarioAsset on a stable application host, with params.body_document identifying
// the open canonical body document. Keep a different scene rendered while it
// builds; SaveDocument is issued only after every native material section exists.
fn apply_plan(doc,plan,label) {
    if !plan.ok || plan.ops.is_empty() {throw "Empty or invalid body authoring plan";}
    let generation=query("InspectUsdDocument",#{doc_id:doc}).generation;
    let result=cmd("ApplyUsdOps",#{doc_id:doc,parent_gen:generation,label:label,ops:plan.ops});
    if !result.ok || result.status!="applied" || result.data.paths.is_empty() {
        throw "Body authoring did not commit: "+result;
    }
}
fn on_start(me,ctx) {
    this.ready=false;this.doc=ctx.body_document;this.index=0;
    let state=query("InspectUsdDocument",#{doc_id:this.doc,path:"/Body"});
    if state.prim==() || !state.prim.exists || state.prim.type!="Xform" {throw "Expected the open Body component document";}
    let existing=state.prim.children;
    for path in query("InspectUsdDocument",#{doc_id:this.doc,path:"/Body/Looks"}).prim.children {existing.push(path);}
    apply_plan(this.doc,reveal_body::setup_plan(existing),"Replace cosmetic shell with native materials");
    this.ready=true;
}
fn ready(me) {this.contains("ready") && this.ready}
fn panel(me) {
    apply_plan(this.doc,reveal_body::chunk_plan(this.index),"Author native body section "+this.index);
    this.index+=1;
}
fn front(me) {apply_plan(this.doc,reveal_body::cap_plan(false,0),"Close body nose");}
fn rear_left(me) {apply_plan(this.doc,reveal_body::cap_plan(true,0),"Close left body tail");}
fn rear_right(me) {apply_plan(this.doc,reveal_body::cap_plan(true,1),"Close right body tail");}
fn finish(me) {
    apply_plan(this.doc,reveal_body::wheelhouse_plan(),"Close cosmetic wheelhouse back walls");
    let result=cmd("SaveDocument",#{doc_id:this.doc});
    if !result.ok {throw "Completed body could not be saved";}
    print("ROADSTER_NATIVE_BODY_COMPLETE sections="+this.index);
}
fn task(me,ctx) {
    seq([check(Fn("ready")),repeat(220,seq([once(Fn("panel")),wait(0.02)])),
        once(Fn("front")),wait(0.02),once(Fn("rear_left")),wait(0.02),
        once(Fn("rear_right")),wait(0.02),once(Fn("finish"))])
}
