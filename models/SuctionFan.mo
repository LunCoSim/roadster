model SuctionFan
  "Four rear electric extractor fans sharing a skirted underbody plenum"
  parameter Real plenum_area(unit="m2") = 2.0;
  parameter Real maximum_pressure_drop(unit="Pa") = 20000;
  parameter Real maximum_electrical_power(unit="W") = 80000;
  parameter Real efficiency = 0.65;
  parameter Real idle_power(unit="W") = 4000;
  parameter Real maximum_omega(unit="rad/s") = 1570.7963267949;
  parameter Real initial_speed_fraction = 0.0;
  parameter Real rotor_inertia(unit="kg.m2") = 0.04;
  parameter Real rotor_efficiency = 0.9;
  parameter Real rotor_tau(unit="s") = 0.15;
  parameter Real skirt_reach(unit="m") = 0.25;
  parameter Real leak_transition(unit="m") = 0.04;
  parameter Real sealed_leak_area(unit="m2") = 0.003;
  parameter Real skirt_perimeter(unit="m") = 6.0;
  input Real command;
  input Real enabled;
  input Real ambient_pressure(unit="Pa");
  input Real air_density(unit="kg/m3");
  input Real gap[4](each unit="m");
  input Real valid[4];
  input Real alignment[4];
  Real omega(start=maximum_omega*initial_speed_fraction,fixed=true);
  Real angle(start=0,fixed=true);
  Real corner_seal[4];
  Real speed_fraction;
  Real excess_gap;
  Real requested_acceleration;
  Real rotor_acceleration_power;
  Real leak_area;
  Real available_air_power;
  Real power_limited_pressure;
  output Real seal;
  output Real pressure_drop(unit="Pa");
  output Real airflow(unit="m3/s");
  output Real electrical_power(unit="W");
  output Real suction_force(unit="N");
  output Real rotor_angle(unit="rad");
  output Real rotor_rpm(unit="1/min");
equation
  requested_acceleration = (maximum_omega*max(0.0,min(1.0,command))*enabled-omega)/rotor_tau;
  der(omega) = min(requested_acceleration,0.4*maximum_electrical_power*rotor_efficiency/(rotor_inertia*max(1.0,omega)));
  rotor_acceleration_power = max(0.0,rotor_inertia*omega*der(omega))/rotor_efficiency;
  der(angle) = omega;
  rotor_angle = angle;
  rotor_rpm = omega*30.0/3.141592653589793;
  speed_fraction = max(0.0,min(1.0,omega/maximum_omega));
  for i in 1:4 loop
    corner_seal[i] = max(0.0,min(1.0,valid[i]))*max(0.0,min(1.0,alignment[i]))^4
      *exp(-(max(0.0,gap[i]-skirt_reach)/leak_transition)^2);
  end for;
  seal = min(corner_seal);
  excess_gap = max(0.0,max(gap)-skirt_reach);
  leak_area = sealed_leak_area+skirt_perimeter*excess_gap+0.05*(1.0-seal);
  available_air_power = max(0.0,maximum_electrical_power-idle_power*speed_fraction^3-rotor_acceleration_power)*efficiency*speed_fraction^3;
  power_limited_pressure = (available_air_power/(leak_area*sqrt(2.0/max(0.01,air_density))))^(2.0/3.0);
  pressure_drop = min(0.6*ambient_pressure,min(maximum_pressure_drop*speed_fraction^2,power_limited_pressure));
  airflow = leak_area*sqrt(2.0*pressure_drop/max(0.01,air_density));
  electrical_power = idle_power*speed_fraction^3+rotor_acceleration_power+pressure_drop*airflow/efficiency;
  suction_force = pressure_drop*plenum_area*seal;
  annotation(Icon(coordinateSystem(extent={{-150,-100},{150,100}}),graphics={
    Rectangle(extent={{-150,100},{150,-100}},radius=8,
      lineColor={84,103,117},fillColor={9,15,21},fillPattern=FillPattern.Solid),
    Text(extent={{-138,91},{138,65}},textString="UNDERBODY PLENUM",textColor={230,238,244}),
    Text(extent={{-138,57},{138,30}},
      textString=DynamicSelect("Pressure drop [kPa]",String(pressure_drop/1000)+" kPa"),
      textColor={121,224,233}),
    Text(extent={{-138,24},{138,-3}},
      textString=DynamicSelect("Suction [kN]",String(suction_force/1000)+" kN suction"),
      textColor={230,238,244}),
    Text(extent={{-138,-9},{138,-36}},
      textString=DynamicSelect("Electrical power [kW]",String(electrical_power/1000)+" kW"),
      textColor={230,238,244}),
    Text(extent={{-138,-42},{138,-65}},
      textString=DynamicSelect("Airflow [m3/s]",String(airflow)+" m3/s"),
      textColor={158,179,191}),
    Rectangle(extent={{-130,-77},{130,-87}},lineColor={84,103,117}),
    Rectangle(extent=DynamicSelect({{-130,-77},{-130,-87}},{{-130,-77},{-130+260*seal,-87}}),
      lineColor={121,224,233},fillColor={121,224,233},fillPattern=FillPattern.Solid)
  }));
end SuctionFan;
