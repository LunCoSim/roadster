// @timing presentation
// Explicit cosmetic document authoring; never attached to the running car.
// params.body_document is the discovered canonical Body document ID.
// Leaves the preview unsaved for visual review unless params.save is true.
fn commit(doc,ops,label) {
    if ops.is_empty() {return;}
    let generation=query("InspectUsdDocument",#{doc_id:doc}).generation;
    let result=cmd("ApplyUsdOps",#{doc_id:doc,parent_gen:generation,label:label,ops:ops});
    if !result.ok || result.status!="applied" {throw "Nose document edit failed: "+result;}
}
fn on_start(me,ctx) {
    this.doc=ctx.body_document;this.save=ctx.contains("save") && ctx.save;this.index=0;
    let body=query("InspectUsdDocument",#{doc_id:this.doc,path:"/Body"});
    if body.prim==() || !body.prim.exists || body.prim.type!="Xform" {throw "Expected canonical Body document";}
    let paths=body.prim.children;
    for path in query("InspectUsdDocument",#{doc_id:this.doc,path:"/Body/RevealShell"}).prim.children {paths.push(path);}
    this.removals=front_nose::geometry(paths).ops;this.ready=true;
}
fn ready(me) {this.contains("ready") && this.ready}
fn remove(me) {commit(this.doc,this.removals,"Retire superseded cosmetic nose sheets");}
fn prepare(me) {this.part=front_nose::part(this.index);}
fn apply(me) {
    commit(this.doc,front_nose::add_mesh(this.part.name,this.part.polys,this.part.material),"Author "+this.part.name);
    this.index+=1;
}
fn finish(me) {
    if this.save {let result=cmd("SaveDocument",#{doc_id:this.doc});if !result.ok {throw "Nose save failed";}}
    print("ROADSTER_NOSE_COMPLETE parts="+this.index+" collision=false saved="+this.save);
}
fn task(me,ctx) {
    seq([check(Fn("ready")),once(Fn("remove")),
         repeat(13,seq([once(Fn("prepare")),wait(0.02),once(Fn("apply")),wait(0.02)])),once(Fn("finish"))])
}
