model LaunchSizing
  "First-order average launch-force budget; native contact simulation is the acceptance measurement"
  parameter Real target_speed(unit="m/s") = 26.8224;
  parameter Real target_time(unit="s") = 0.59;
  parameter Real wheel_only_time(unit="s") = 1.7856431056531614 "Measured 1950 kg fan-on baseline; update if the drivetrain/traction changes";
  input Real initial_mass(unit="kg");
  output Real required_mean_acceleration(unit="m/s2");
  output Real required_mean_net_force(unit="N");
  output Real measured_mean_wheel_acceleration(unit="m/s2");
  output Real estimated_mean_wheel_net_force(unit="N");
  output Real estimated_additional_mean_boost(unit="N");
equation
  required_mean_acceleration = target_speed/target_time;
  required_mean_net_force = initial_mass*required_mean_acceleration;
  measured_mean_wheel_acceleration = target_speed/wheel_only_time;
  estimated_mean_wheel_net_force = initial_mass*measured_mean_wheel_acceleration;
  // Conservative constant-initial-mass comparison, not a substitute for the
  // coupled changing-mass, traction/load-transfer and blowdown simulation.
  estimated_additional_mean_boost = max(0.0,required_mean_net_force-estimated_mean_wheel_net_force);
end LaunchSizing;
