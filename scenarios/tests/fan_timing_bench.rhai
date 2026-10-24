// Read the production Modelica controller bench, not a second fan controller.
fn verify(experiment_id) {
    let result=query("GetExperimentResult",#{experiment_id:experiment_id,
        variables:["fan_command","position_z","phase","action"],max_points:1000});
    if result.state!="done" || result.downsampled || !result.missing_variables.is_empty() {
        throw "Complete native fan-timing samples are required";
    }
    let off_before=0;let on_approach=0;let on_crest=0;let off_release=0;
    for i in 0..result.times.len() {
        let t=result.times[i];let fan=result.series.fan_command[i];
        if t<1.49 {if fan!=0.0 {throw "Fans started before the preload boundary";}off_before+=1;}
        if t>1.51 && t<3.99 {if fan!=1.0 {throw "Fans must preload before climbing";}on_approach+=1;}
        if t>4.01 && t<4.99 {if fan!=1.0 {throw "Fans must stay on through the crest";}on_crest+=1;}
        if t>5.01 {if fan!=0.0 {throw "Release action must turn fans off";}off_release+=1;}
    }
    if min(min(off_before,on_approach),min(on_crest,off_release))<20 {
        throw "Fan timing test lacks observations in a required interval";
    }
    #{ok:true,samples:result.times.len(),preload_z_m:-288.0,
      early_off:off_before,approach_on:on_approach,crest_on:on_crest,release_off:off_release}
}
