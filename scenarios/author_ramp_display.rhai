// @timing presentation
// Explicit Editor operation; never part of the driving scene's runtime.
fn on_start(me,ctx) {
    this.doc=ctx.ramp_document;this.index=ctx.first_bay;
    let source=query("QueryUsdPrim",#{doc_id:this.doc,path:"/World/RampCenter",attrs:["points"]});
    this.profile=source.attrs["points"];
    this.expected=query("InspectUsdDocument",#{doc_id:this.doc}).generation.to_int();
}
fn committed(me) {
    let doc=query("InspectUsdDocument",#{doc_id:this.doc});
    doc.generation.to_int()>=this.expected && query("GetReadiness",#{}).ready
}
fn bay(me) {
    let plan=ramp_display::steel_plan(this.profile,this.index);
    if !plan.ok || plan.ops.is_empty() {throw "Ramp bay plan must contain geometry";}
    let generation=query("InspectUsdDocument",#{doc_id:this.doc}).generation;
    this.expected=generation.to_int()+plan.ops.len();
    cmd("ApplyUsdOps",#{doc_id:this.doc,parent_gen:generation,
        label:"Author canonical ramp frame bay "+this.index,ops:plan.ops});
    this.index+=1;
}
fn finish(me) {
    print("ROADSTER_RAMP_FRAME_AUTHORED bays="+this.index);
}
fn task(me,ctx) {
    seq([wait_until(Fn("committed")),
        repeat(15-ctx.first_bay,seq([once(Fn("bay")),wait_until(Fn("committed"))])),
        once(Fn("finish"))])
}
