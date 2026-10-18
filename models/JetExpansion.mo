model JetExpansion
  "Fixed-area isentropic nozzle and an explicit qualitative mixing envelope"
  parameter Real gamma = 1.4;
  parameter Real gas_constant = CompressedAir.R;
  parameter Real exit_mach = 3.8 "Assumed fixed supersonic nozzle geometry";
  parameter Real throat_area(unit="m2") = 0.002;
  parameter Real nozzle_count = 4;
  parameter Real nozzle_efficiency = 0.85;
  parameter Real spreading_rate = 0.08 "Assumed radial growth per axial metre, not CFD";
  parameter Real area_ratio = (1.0/exit_mach)*((2.0/(gamma+1.0))*(1.0+(gamma-1.0)*exit_mach^2/2.0))^((gamma+1.0)/(2.0*(gamma-1.0)));
  parameter Real exit_area(unit="m2") = throat_area*area_ratio;
  parameter Real exit_radius(unit="m") = sqrt(exit_area/(nozzle_count*3.141592653589793));
  input Real tank_pressure(unit="Pa");
  input Real tank_temperature(unit="K");
  input Real ambient_pressure(unit="Pa");
  Real matched_velocity;
  Real continuity_area_ratio;
  output Real exit_pressure(unit="Pa");
  output Real exit_temperature(unit="K");
  output Real exit_velocity(unit="m/s");
  output Real radius_start(unit="m");
  output Real radius_expanded(unit="m");
  output Real expansion_length(unit="m");
  output Real mixing_length(unit="m");
  output Real radius_end(unit="m");
equation
  exit_temperature = tank_temperature/(1.0+(gamma-1.0)*exit_mach^2/2.0);
  exit_pressure = tank_pressure*(exit_temperature/tank_temperature)^(gamma/(gamma-1.0));
  exit_velocity = exit_mach*sqrt(nozzle_efficiency*gamma*gas_constant*exit_temperature);
  matched_velocity = sqrt(max(1.0,nozzle_efficiency*2.0*gamma/(gamma-1.0)*gas_constant*tank_temperature
    *(1.0-min(1.0,ambient_pressure/tank_pressure)^((gamma-1.0)/gamma))));
  continuity_area_ratio = max(1.0,(exit_pressure/ambient_pressure)^(1.0/gamma)*exit_velocity/matched_velocity);
  radius_start = exit_radius;
  radius_expanded = exit_radius*sqrt(continuity_area_ratio);
  expansion_length = 8.0*exit_radius;
  mixing_length = min(2.4,8.0*exit_radius+exit_velocity*0.002);
  radius_end = radius_expanded+spreading_rate*max(0.0,mixing_length-expansion_length);
end JetExpansion;
