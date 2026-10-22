//! Read-only reports over native Roadster experiment trajectories.
//! This tool does not integrate a simulator or change a model/controller.
fn ui_label() { "Roadster experiment report" }
fn ui_hint() { "gas_bench_report(experiment_id, split_s) summarizes two native valve pulses" }
fn gas_bench_report(experiment_id,split_s) {
    let status=query("RunStatus",#{experiment_id:experiment_id});
    if status.state!="done" {return #{ok:false,error:"A completed native experiment is required"};}
    let names=["tank_temperature_c","tank_pressure_bar","air_mass_kg","rear_thrust_kn"];
    let r=query("GetExperimentResult",#{experiment_id:experiment_id,variables:names});
    if r.downsampled || r.missing_variables.len()>0 || r.times.len()<2 {
        return #{ok:false,error:"Full native samples for the four bench outputs are required"};
    }
    let times=r.times;let force=r.series["rear_thrust_kn"];
    let last=times.len()-1;
    if !(split_s>times[0]) || !(split_s<times[last]) {
        return #{ok:false,error:"split_s must lie between the pulses inside the recorded interval"};
    }
    let first=0.0;let second=0.0;let split=0;
    for i in 1..times.len() {
        let dt=times[i]-times[i-1];
        if dt<0.0 {return #{ok:false,error:"Native sample times must not run backwards"};}
        if times[i-1]<split_s && times[i]>split_s {
            let alpha=(split_s-times[i-1])/dt;
            let mid=force[i-1]+alpha*(force[i]-force[i-1]);
            first+=0.5*(force[i-1]+mid)*(split_s-times[i-1]);
            second+=0.5*(mid+force[i])*(times[i]-split_s);
        } else {
            let impulse=0.5*(force[i-1]+force[i])*dt;
            if times[i]<=split_s {first+=impulse;split=i;}else{second+=impulse;}
        }
    }
    if !(first>0.0) {return #{ok:false,error:"The first interval has no positive rear-jet impulse"};}
    let pressure=r.series["tank_pressure_bar"];let mass=r.series["air_mass_kg"];
    let temperature=r.series["tank_temperature_c"];
    #{ok:true,experiment_id:experiment_id,source_cid:r.source_cid,samples:times.len(),
      split_s:split_s,snapshot_time_s:times[split],first_impulse_kn_s:first,
      second_impulse_kn_s:second,second_impulse_fraction:second/first,
      initial_pressure_bar:pressure[0],between_pulses_pressure_bar:pressure[split],
      between_pulses_mass_kg:mass[split],between_pulses_temperature_c:temperature[split],
      remaining_mass_fraction:mass[split]/mass[0],remaining_pressure_fraction:pressure[split]/pressure[0],
      scope:"Same gas plant, chosen fill, fixed mechanical observations; not a driving trial or hardware measurement"}
}

// Prepare the native chart before revealing the report perspective.
// Requires a completed bench and that exact document selected; no simulation starts.
fn show_gas_temperature(experiment_id) {
    let status=query("RunStatus",#{experiment_id:experiment_id});
    if status.state!="done" {return #{ok:false,error:"Complete the native gas bench first"};}
    let facts=query("InspectWorkbench",#{});
    if facts.preparing || !facts.scene_mounted {return #{ok:false,error:"Wait for the current Twin and scene admission before preparing the report"};}
    if facts.document_id!=status.doc_id {return #{ok:false,error:"Focus the bench document before showing its data"};}
    let plot=();
    for panel in facts.instance_panels {
        if panel.id=="modelica_plot" {plot=panel.canonical_instance;}
    }
    if plot==() {return #{ok:false,error:"The native Modelica plot is unavailable"};}
    let report=gas_bench_report(experiment_id,2.5);
    if !report.ok {return report;}
    cmd("SetPlotSignals",#{plot:plot,signals:["tank_temperature_c"]});
    cmd("ConfigureLinePlot",#{plot:plot,caption:"Tank air temperature",x_label:"Time (s)",y_label:"°C",
        text_size:28.0,line_width:5.0,show_controls:false,show_legend:false,
        simplified_grid:true,compact_layout:true,follow_latest:false,y_reference_range:[-130.0,40.0]});
    cmd("SetTimeTransport",#{playing:false});
    cmd("ActivatePerspective",#{id:"twin/report-analysis"});
    #{ok:true,status:"queued",plot:plot,experiment_id:experiment_id,source_cid:report.source_cid,
      scope:"Historical gas bench; not the background car's live telemetry"}
}

// Native scalar selection only. No derivative, resampling or second history.
// Call show_live_grid after command admission to style and reveal the view.
fn prepare_live_grid(grid,columns,entries) {
    let facts=query("InspectWorkbench",#{});
    if facts.preparing || !facts.scene_mounted {return #{ok:false,error:"Wait for scene admission"};}
    let car=find_path("/World/Roadster");
    if car<=0 {return #{ok:false,error:"The Roadster is not mounted"};}
    let selected=[];
    for entry in entries {
        let name=entry.signal;let found=false;
        let catalog=query("ListTelemetryChannels",#{name:name});
        for channel in catalog.channels {
            if channel.source==car && channel.name==name && channel.active && channel.samples>0 {found=true;break;}
        }
        if !found {return #{ok:false,error:"No current measured channel: "+name};}
        selected.push(#{target_gid:car,signal:name,caption:entry.caption});
    }
    cmd("ConfigureSignalGrid",#{grid:grid,title:"Roadster measurements",columns:columns,signals:selected});
    #{ok:true,status:"queued",grid:grid,channels:entries.len(),source_gid:car}
}
fn show_live_grid(grid,perspective,text_size) {
    let inspection=query("InspectSignalGrid",#{});let plots=[];
    for view in inspection.grids {if view.grid==grid {plots=view.plots;}}
    if plots.len()==0 {return #{ok:false,error:"Prepare the native signal grid first"};}
    for plot in plots {
        cmd("ConfigureLinePlot",#{plot:plot,x_label:"Time (s)",text_size:text_size,line_width:3.5,
            show_controls:false,show_legend:false,simplified_grid:true,compact_layout:true,
            show_latest_value:false,follow_latest:true,time_window_s:5.0});
    }
    cmd("ActivatePerspective",#{id:perspective});
    #{ok:true,status:"queued",grid:grid,plots:plots,window_seconds:5.0}
}
