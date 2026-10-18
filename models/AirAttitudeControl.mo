model AirAttitudeControl
  "Manual body-rate commands realized by finite cold-gas jets; no attitude/landing target"
  parameter Real rate_limit(unit="rad/s") = 2.5 "Manual aerobatic command, study setting; torque and gas remain finite";
  parameter Real response_time(unit="s") = 0.4;
  parameter Real maximum_corner_correction = 0.25;
  parameter Real pitch_arm(unit="m") = 1.5;
  parameter Real roll_arm(unit="m") = 0.8;
  parameter Real yaw_arm(unit="m") = 1.7;
  input Real flight_weight;
  input Real pitch_command;
  input Real roll_command;
  input Real yaw_command;
  input Real collective;
  input Real individual[4];
  input Real omega_body[3];
  input Real inertia[3];
  input Real full_area_force;
  Real assistance;
  Real pitch_correction;
  Real roll_correction;
  Real yaw_correction;
  Real collective_fraction;
  output Real corner_command[4];
  output Real side_command;
  output Real pitch_rate_deg_s;
  output Real roll_rate_deg_s;
  output Real yaw_rate_deg_s;
equation
  // Holding a raw corner key bypasses rate assistance for that maneuver.
  assistance = max(0.0,min(1.0,flight_weight))*(1.0-max(0.0,min(1.0,max(individual))));
  pitch_correction = assistance*max(-maximum_corner_correction,min(maximum_corner_correction,
    inertia[1]*(rate_limit*pitch_command-omega_body[1])/(response_time*max(100.0,full_area_force*pitch_arm))));
  roll_correction = assistance*max(-maximum_corner_correction,min(maximum_corner_correction,
    inertia[3]*(rate_limit*roll_command-omega_body[3])/(response_time*max(100.0,full_area_force*roll_arm))));
  yaw_correction = max(-1.0,min(1.0,-inertia[2]*(-rate_limit*yaw_command-omega_body[2])
    /(response_time*max(100.0,0.04*full_area_force*yaw_arm))));
  side_command = (1.0-assistance)*yaw_command+assistance*yaw_correction;
  // Reserve 45% valve authority in flight for differential attitude control.
  collective_fraction = max(0.0,min(1.0,collective))*(1.0-0.45*flight_weight);
  corner_command[1] = max(0.0,min(1.0,collective_fraction+pitch_correction-roll_correction+individual[1]));
  corner_command[2] = max(0.0,min(1.0,collective_fraction-pitch_correction-roll_correction+individual[2]));
  corner_command[3] = max(0.0,min(1.0,collective_fraction+pitch_correction+roll_correction+individual[3]));
  corner_command[4] = max(0.0,min(1.0,collective_fraction-pitch_correction+roll_correction+individual[4]));
  pitch_rate_deg_s = omega_body[1]*180.0/3.141592653589793;
  yaw_rate_deg_s = omega_body[2]*180.0/3.141592653589793;
  roll_rate_deg_s = omega_body[3]*180.0/3.141592653589793;
end AirAttitudeControl;
