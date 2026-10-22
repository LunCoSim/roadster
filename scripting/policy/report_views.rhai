// Engineering report layouts over the current Twin's native views and signals.
// Generic workbench hosts own placement; this Twin chooses report composition.
fn has_panel(facts,id) {
    for panel in facts.panels {if panel.id==id {return true;}}
    false
}
fn has_kind(facts,id) {
    for kind in facts.instance_kinds {if kind==id {return true;}}
    false
}
fn assemble(facts) {
    let plots=[];
    for panel in facts.instance_panels {
        if panel.id=="modelica_plot" && panel.canonical_instance!=() {
            let kind=panel.id;let instance=panel.canonical_instance;
            let plot=#{kind:kind,instance:instance,slot:"center"};
            plots.push(plot);
        }
    }
    let views=[];
    if plots.len()>0 {
        let view=#{id:"report-graph",title:"Graph",interaction:"editor",restore:false,
            description:"Native measurements with quantity and unit axes. Return here to edit the plot.",
            instances:plots};
        views.push(view);
    }
    if !facts.scene_mounted || !has_panel(facts,"workbench::viewport") {return views;}
    if plots.len()>0 {
        let plot=plots[0];
        let kind=plot.kind;let instance=plot.instance;
        let host=#{kind:kind,instance:instance,corner:"top_right",width:880,height:400,inset:24};
        let view=#{id:"report-analysis",title:"Car + data",interaction:"editor",restore:false,
            description:"The native graph over the scene, without a tab header or title bar.",scene_visible:true,
            floating:[host]};
        views.push(view);
    }
    if has_panel(facts,"modelica_canvas_diagram") {
        let host=#{panel:"modelica_canvas_diagram",corner:"top_left",width:1100,height:640,inset:24};
        let view=#{id:"report-model",title:"Car + model",interaction:"editor",restore:false,
            description:"The selected native Modelica diagram over the physical vehicle.",scene_visible:true,
            floating:[host]};
        views.push(view);
    }
    if has_panel(facts,"usd_connection_canvas") {
        let host=#{panel:"usd_connection_canvas",corner:"top_left",width:1100,height:640,inset:24};
        let view=#{id:"report-connections",title:"Connections",interaction:"editor",restore:false,
            description:"Actual authored signal connections beside their physical result.",scene_visible:true,
            floating:[host]};
        views.push(view);
    }
    if has_kind(facts,"signal_grid") {
            let kind="signal_grid";
            let host=#{kind:kind,instance:1,corner:"top_right",width:1120,height:720,inset:24};
            let stunt=#{id:"report-stunt",title:"Stunt data",interaction:"editor",restore:false,
                description:"Four native physical measurements beside the complete stunt.",scene_visible:true,floating:[host]};
            views.push(stunt);
            let tile=#{kind:kind,instance:2,slot:"center"};
            let overview=#{id:"report-under-hood",title:"Under the hood",interaction:"editor",restore:false,
                description:"Real channel histories from the same experiment.",instances:[tile]};
            views.push(overview);
    }
    views
}
