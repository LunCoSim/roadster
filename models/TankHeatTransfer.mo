model TankHeatTransfer
  "Finite tank-wall thermal storage and passive heat exchange; study coefficients"
  parameter Real wall_heat_capacity(unit="J/K") = 60000;
  parameter Real gas_wall_conductance(unit="W/K") = 200;
  parameter Real ambient_conductance(unit="W/K") = 20;
  parameter Real ambient_temperature(unit="K") = 293.15;
  parameter Real initial_wall_temperature(unit="K") = 293.15;
  input Real gas_temperature(unit="K");
  input Real temperature_offset(unit="K");
  Real wall_temperature_ledger(start=initial_wall_temperature,fixed=true);
  Real wall_temperature;
  output Real heat_to_gas(unit="W");
  output Real heat_from_ambient(unit="W");
equation
  heat_to_gas = gas_wall_conductance*(wall_temperature-gas_temperature);
  heat_from_ambient = ambient_conductance*(ambient_temperature-wall_temperature);
  wall_temperature = wall_temperature_ledger+temperature_offset;
  der(wall_temperature_ledger) = (heat_from_ambient-heat_to_gas)/wall_heat_capacity;
end TankHeatTransfer;
