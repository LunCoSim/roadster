model SteeringDriver
  "Progressive keyboard driver plus finite steering rack, without a speed angle cap"
  parameter Real assistance = 1.0;
  parameter Real low_speed_command_rate(unit="1/s") = 1.8;
  parameter Real sensitivity_speed(unit="m/s") = 20.0;
  parameter Real return_command_rate(unit="1/s") = 2.8;
  parameter Real rack_tau(unit="s") = 0.12;
  parameter Real command_tau(unit="s") = 0.05 "Existing driver-command smoothing, exposed for guidance prediction";
  parameter Real rack_rate_limit(unit="1/s") = 2.0;
  input Real command;
  input Real speed;
  Real driver_command(start=0,fixed=true);
  Real demand;
  Real buildup_rate;
  Real selected_rate;
  output Real rack_position(start=0,fixed=true);
  output Real rack_velocity;
equation
  demand = max(-1.0,min(1.0,command));
  buildup_rate = low_speed_command_rate/(1.0+(speed/sensitivity_speed)^2);
  selected_rate = noEvent(if abs(demand)<0.01 or driver_command*demand<0.0
    then return_command_rate else buildup_rate);
  der(driver_command) = max(-selected_rate,min(selected_rate,(demand-driver_command)/command_tau));
  rack_velocity = max(-rack_rate_limit,min(rack_rate_limit,
    ((1.0-assistance)*demand+assistance*driver_command-rack_position)/rack_tau));
  der(rack_position) = rack_velocity;
end SteeringDriver;
