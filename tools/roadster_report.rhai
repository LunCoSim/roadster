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
