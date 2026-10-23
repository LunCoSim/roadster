model RoadsterFanSealBench
  "Controlled skirt-gap test of the canonical fan plant; not a vehicle-motion trial"
  parameter Real skirt_reach(unit="m") = 0.40 "Same study reach used by the course vehicle";
  parameter Real closed_gap(unit="m") = 0.12;
  parameter Real lifted_gap(unit="m") = 0.55;
  parameter Real fan_on_s(unit="s") = 1.0;
  parameter Real skirt_lift_s(unit="s") = 5.0;
  output Real fan_command;
  output Real skirt_gap_m(unit="m");
  output Real suction_kn(unit="kN");
  output Real vacuum_kpa(unit="kPa");
  output Real electrical_power_kw(unit="kW");
  output Real volume_flow_m3_s(unit="m3/s");
  output Real seal_fraction;
  FanAdhesion floor(
    command=fan_command, enabled=1.0, skirt_reach=skirt_reach,
    body_up={0,1,0}, gap={skirt_gap_m,skirt_gap_m,skirt_gap_m,skirt_gap_m},
    valid={1,1,1,1}, normal_x={0,0,0,0}, normal_y={1,1,1,1}, normal_z={0,0,0,0})
    annotation(Placement(transformation(extent={{-135,-80},{135,80}})));
equation
  fan_command = if time<fan_on_s then 0.0 else 1.0;
  skirt_gap_m = if time<skirt_lift_s then closed_gap else lifted_gap;
  suction_kn = -floor.force_body[2]/1000.0;
  vacuum_kpa = floor.pressure_drop/1000.0;
  electrical_power_kw = floor.electrical_power/1000.0;
  volume_flow_m3_s = floor.plenum.airflow;
  seal_fraction = floor.seal;
  annotation(
    Diagram(coordinateSystem(extent={{-180,-140},{180,140}}),graphics={
      Text(extent={{-170,132},{170,105}},textString="SKIRT LEAK TEST",textColor={230,238,244}),
      Text(extent={{-170,-97},{170,-121}},
        textString=DynamicSelect("Skirt gap [m]",String(skirt_gap_m)+" m skirt gap"),
        textColor={121,224,233})
    }),
    experiment(StartTime=0,StopTime=9,Interval=0.01,Tolerance=1e-6));
end RoadsterFanSealBench;
