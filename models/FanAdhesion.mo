model FanAdhesion
  "Reduced underbody plenum: geometry stays internal; mechanics consumes its wrench"
  parameter Real initial_speed_fraction = 0.0;
  parameter Real skirt_reach(unit="m") = 0.25;
  parameter Real ambient_pressure(unit="Pa") = 101325;
  parameter Real air_density(unit="kg/m3") = 1.225;
  parameter Real center_of_pressure[3](each unit="m") = {0,-0.30,0};
  parameter Real center_of_mass[3](each unit="m") = {0,-0.14,0};
  input Real command;
  input Real enabled;
  input Real body_up[3];
  input Real gap[4](each unit="m");
  input Real valid[4];
  input Real normal_x[4];
  input Real normal_y[4];
  input Real normal_z[4];
  // Only the assembly adapter supplies native geometry observations. The
  // physical powertrain receives force and electrical power, never these rays.
  SuctionFan plenum(command=command,enabled=enabled,ambient_pressure=ambient_pressure,
    air_density=air_density,initial_speed_fraction=initial_speed_fraction,
    gap=gap,valid=valid,alignment=alignment,skirt_reach=skirt_reach)
    annotation(Placement(transformation(extent={{-130,-80},{130,80}})));
  Real alignment[4];
  Real lever[3];
  output Real force_body[3](each unit="N");
  output Real moment_body[3](each unit="N.m");
  output Real electrical_power(unit="W");
  output Real pressure_drop(unit="Pa");
  output Real seal;
  output Real rotor_angle(unit="rad");
  output Real rotor_rpm(unit="1/min");
  output Real surface_proximity "Observation for course/HUD, not a motion controller";
equation
  for i in 1:4 loop
    alignment[i] = normal_x[i]*body_up[1]+normal_y[i]*body_up[2]+normal_z[i]*body_up[3];
  end for;
  force_body = {0,-plenum.suction_force,0};
  lever = center_of_pressure-center_of_mass;
  moment_body = {lever[2]*force_body[3]-lever[3]*force_body[2],
    lever[3]*force_body[1]-lever[1]*force_body[3],
    lever[1]*force_body[2]-lever[2]*force_body[1]};
  electrical_power = plenum.electrical_power;
  pressure_drop = plenum.pressure_drop;
  seal = plenum.seal;
  rotor_angle = plenum.rotor_angle;
  rotor_rpm = plenum.rotor_rpm;
  surface_proximity = max({valid[i]*max(0.0,min(1.0,(0.50-gap[i])/0.15)) for i in 1:4});
  annotation(Icon(coordinateSystem(extent={{-150,-100},{150,100}}),graphics={
    Rectangle(extent={{-150,100},{150,-100}},radius=8,
      lineColor={84,103,117},fillColor={9,15,21},fillPattern=FillPattern.Solid),
    Text(extent={{-138,91},{138,65}},textString="FAN ADHESION",textColor={230,238,244}),
    Text(extent={{-138,51},{138,19}},
      textString=DynamicSelect("Suction [kN]",String(-force_body[2]/1000)+" kN suction"),
      textColor={121,224,233}),
    Text(extent={{-138,7},{138,-25}},
      textString=DynamicSelect("Electrical power [kW]",String(electrical_power/1000)+" kW"),
      textColor={230,238,244}),
    Text(extent={{-138,-37},{138,-69}},
      textString=DynamicSelect("Seal [%]",String(100*seal)+" % seal"),
      textColor={158,179,191})
  }),Diagram(coordinateSystem(extent={{-150,-100},{150,100}})));
end FanAdhesion;
