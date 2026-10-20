model CoursePilot
  "Digital control suggestions for the shared course behavior tree; no force or state writes"
  input Real phase;
  input Real action;
  input Real elapsed;
  input Real position_x;
  input Real velocity_x;
  input Real turn_direction;
  input Real jump_timing_offset_s;
  input Real position_y;
  input Real position_z;
  input Real speed;
  input Real velocity_y;
  input Real velocity_z;
  input Real attitude[4] "w, x, y, z";
  input Real rates[3] "Body pitch, yaw, roll in degrees per second";
  input Real yaw;
  input Real up_y;
  input Real airborne;
  input Real wheel_heading;
  input Real wheel_heading_rate "Small-angle rate prediction from the modeled rack";
  parameter Real steering_preview_s = 0.17 "Controller tuning derived from command smoothing + rack lag";
  input Real full_lift_force;
  input Real mass;
  input Real angular_acceleration[3] "Full-bank pitch/yaw/roll authority, rad/s2";
  parameter Real wheelbase = 2.75;
  parameter Real pulse_period = 0.1;
  parameter Real pulse_on = 0.05;
  parameter Real attitude_gain[3] = {4.0,3.5,3.0};
  parameter Real flip_roll_direction = 1.0 "Positive body +Z: counterclockwise viewed from behind toward the nose";
  output Real recommended_yaw_direction;
  output Real jump_impulse_ready;
  output Real takeoff_gate;
  output Real forward;
  output Real reverse;
  output Real left;
  output Real right;
  output Real boost;
  output Real brake;
  output Real lift;
  output Real fan;
  output Real pitch_up;
  output Real pitch_down;
  output Real yaw_left;
  output Real yaw_right;
  output Real roll_left;
  output Real roll_right;
  output Real command_throttle;
  output Real command_steer;
  output Real command_brake;
  output Real command_thrust_z;
  output Real command_thrust_y;
  output Real command_thrust_x;
  output Real command_fan;
  output Real command_lift_fl;
  output Real command_lift_fr;
  output Real command_lift_rl;
  output Real command_lift_rr;
protected
  Real forward_axis[3];
  Real right_axis[3];
  Real desired[3];
  Real lookahead;
  Real heading_error;
  Real rack_error;
  Real error_quaternion[4];
  Real target_bank;
  Real landing_time;
  Real predicted_lateral_position;
  Real target_rate[3];
  Real rotation_length;
  Real rotation_scale;
  Real rotation_sign;
  Real attitude_error[3];
  Real rate_error[3];
  Real cruise_speed;
  Real lift_acceleration;
  Real available_lift_acceleration;
  Real stopping_height;
  Real jump_target_velocity;
  Real pulse[3];
  Real correcting;
  Real on_ground;
  Real flight;
equation
  command_throttle = forward-reverse;
  command_steer = right-left;
  command_brake = brake;
  command_thrust_z = boost;
  command_thrust_y = lift;
  command_thrust_x = yaw_right-yaw_left;
  command_fan = fan;
  command_lift_fl = min(1.0,pitch_up+roll_left);
  command_lift_fr = min(1.0,pitch_up+roll_right);
  command_lift_rl = min(1.0,pitch_down+roll_left);
  command_lift_rr = min(1.0,pitch_down+roll_right);
  forward_axis = {-2*(attitude[2]*attitude[4]+attitude[1]*attitude[3]),
    -2*(attitude[3]*attitude[4]-attitude[1]*attitude[2]),
    -1+2*(attitude[2]^2+attitude[3]^2)};
  right_axis = {1-2*(attitude[3]^2+attitude[4]^2),
    2*(attitude[2]*attitude[3]+attitude[1]*attitude[4]),
    2*(attitude[2]*attitude[4]-attitude[1]*attitude[3])};
  lookahead = max(10.0,0.5*speed);
  desired = {-(position_x+0.5*velocity_x)/lookahead,forward_axis[2],forward_axis[3]};
  heading_error = atan2(-sum(right_axis.*desired),sum(forward_axis.*desired));
  // A-C01 study controller: anticipate the actual modeled steering lag.
  // Source: SteeringDriver.mo command_tau + rack_tau (not Tesla calibration).
  // This PD/preview term prevents digital pulses chasing an already-moving
  // rack at speed. It changes guidance keys only; manual plant control is direct.
  rack_error = wheel_heading+steering_preview_s*wheel_heading_rate-atan(2*wheelbase*sin(heading_error)/lookahead);
  on_ground = noEvent(if airborne<0.2 then 1.0 else 0.0);
  flight = noEvent(if abs(phase-6)<0.5 and airborne>0.2 then 1.0 else 0.0);
  left = noEvent(if phase<6 and on_ground>0.5 and rack_error< -0.0015 then 1.0 else 0.0);
  right = noEvent(if phase<6 and on_ground>0.5 and rack_error>0.0015 then 1.0 else 0.0);
  // Target speeds are pilot requests, never physical velocity constraints.
  // Carry the launch speed through both service pads and the cube corridor.
  cruise_speed = noEvent(if phase>0.5 and phase<3.5 then 35.0
    else if phase>3.5 and phase<5.5 and action<7.5 then
      (if position_y>10 then 6.5 else if position_z> -298 and position_y<0.8 then 28.0 else 0.0)
    else 0.0);
  // A narrow ballistic clearance corridor. Valve closing contributes a short
  // residual impulse; the target is measured velocity, not an assumed K hold.
  jump_target_velocity = 6.8;
  jump_impulse_ready = noEvent(if velocity_y>=jump_target_velocity then 1.0 else 0.0);
  takeoff_gate = noEvent(if position_z< -72.0+35.0*jump_timing_offset_s then 1.0 else 0.0);
  forward = noEvent(if phase<0.5 and action>0.5 then 1.0
    else if cruise_speed>0 and speed<cruise_speed-0.5 and on_ground>0.5 then 1.0
    else if phase>3.5 and phase<5.5 and action<7.5 and cruise_speed<0.5 then 1.0
    else 0.0);
  reverse = 0.0;
  brake = noEvent(if phase<0.5 and action<0.5 then 1.0
    else if cruise_speed>0 and speed>cruise_speed+2 then 1.0
    else if abs(phase-6)<0.5 and on_ground>0.5 and forward<0.5 and reverse<0.5 then 1.0
    else if phase>6.5 then 1.0 else 0.0);
  fan = noEvent(if (phase>0.5 and phase<3.5) or phase>5.5 or (abs(phase-5)<0.5 and action>7.5) then 0.0 else 1.0);
  // q_error = conjugate(q_body) * q_target, expressed in body axes.
  // Recover wheels-down while retaining the ramp exit heading (+Z).
  landing_time = (velocity_y+sqrt(velocity_y^2+2*9.80665*max(0.0,position_y)))/9.80665;
  predicted_lateral_position = position_x+velocity_x*max(0.5,landing_time);
  recommended_yaw_direction = noEvent(if predicted_lateral_position>0 then 1.0 else -1.0);
  // The inverted ramp already points along +Z. Recover with a roll, then
  // bank the physical lift vector to cancel lateral drift over the road.
  target_bank = noEvent(if flight>0.5 and up_y>0.8 then
    max(-0.24,min(0.24,atan2(-1.2*position_x-2.0*velocity_x,
      max(9.80665,0.6*full_lift_force/max(1.0,mass))))) else 0.0);
  error_quaternion = {attitude[2]*sin(target_bank/2)+attitude[3]*cos(target_bank/2),
      attitude[1]*sin(target_bank/2)+attitude[4]*cos(target_bank/2),
      attitude[1]*cos(target_bank/2)-attitude[4]*sin(target_bank/2),
      -attitude[2]*cos(target_bank/2)+attitude[3]*sin(target_bank/2)};
  rotation_length = sqrt(error_quaternion[2]^2+error_quaternion[3]^2+error_quaternion[4]^2);
  // At an inverted exit both half-turns reach the same upright attitude.
  // Select the requested roll branch near inversion instead of letting tiny
  // attitude errors choose clockwise. Once clear, use shortest-path recovery
  // for normal landing trims. Only digital valve suggestions change.
  rotation_sign = noEvent(if flight>0.5 and up_y< -0.8 then
    (if flip_roll_direction*error_quaternion[4]>=0 then 1.0 else -1.0)
    else if error_quaternion[1]>=0 then 1.0 else -1.0);
  rotation_scale = noEvent(rotation_sign
    *2*atan2(rotation_length,rotation_sign*error_quaternion[1])*180/3.141592653589793/max(1e-9,rotation_length));
  attitude_error = rotation_scale*{error_quaternion[2],error_quaternion[3],error_quaternion[4]};
  // Stopping-speed envelope from current finite-gas torque authority. The margin
  // covers valve lag and digital sampling; pitch/roll use half-duty pulses.
  for axis in 1:3 loop
    target_rate[axis] = noEvent((if attitude_error[axis]>=0 then 1.0 else -1.0)
      *min(attitude_gain[axis]*abs(attitude_error[axis]),
      sqrt(2*0.65*max(0.0,angular_acceleration[axis])
        *(if axis==2 then 1.0 else 0.5)*abs(attitude_error[axis])*3.141592653589793/180)
        *180/3.141592653589793));
  end for;
  rate_error = {max(-220,min(220,target_rate[1]))-rates[1],
    max(-150,min(150,target_rate[2]))-rates[2],
    max(-300,min(300,target_rate[3]))-rates[3]};
  for axis in 1:3 loop
    // Short correction pulses match the required angular impulse. A high-roll
    // authority bank must not fire a fixed 50 ms pulse for a tiny rate error.
    pulse[axis] = noEvent(if elapsed-floor(elapsed/pulse_period)*pulse_period
      <min(pulse_on,abs(rate_error[axis])*3.141592653589793/180/max(1e-9,angular_acceleration[axis]))
      then 1.0 else 0.0);
  end for;
  pitch_up = noEvent(if flight>0.5 and pulse[1]>0.5 and rate_error[1]>12 then 1.0 else 0.0);
  pitch_down = noEvent(if flight>0.5 and pulse[1]>0.5 and rate_error[1]< -12 then 1.0 else 0.0);
  yaw_left = noEvent(if flight>0.5 and rate_error[2]>8 then 1.0 else 0.0);
  yaw_right = noEvent(if flight>0.5 and rate_error[2]< -8 then 1.0 else 0.0);
  roll_right = noEvent(if flight>0.5 and pulse[3]>0.5 and rate_error[3]>10 then 1.0 else 0.0);
  roll_left = noEvent(if flight>0.5 and pulse[3]>0.5 and rate_error[3]< -10 then 1.0 else 0.0);
  correcting = noEvent(if pitch_up+pitch_down+yaw_left+yaw_right+roll_left+roll_right>0.5 then 1.0 else 0.0);
  boost = noEvent(if phase<0.5 and abs(action-1)<0.5 then 1.0
    else if flight>0.5 and up_y>0.94 and velocity_z>16 and abs(yaw)<0.25 and correcting<0.5 then 1.0 else 0.0);
  // Conservative terminal-force allowance for cooling and pressure drop.
  lift_acceleration = 0.65*full_lift_force*up_y/max(1.0,mass)-9.80665;
  available_lift_acceleration = full_lift_force*up_y/max(1.0,mass)-9.80665;
  stopping_height = velocity_y^2/(2*max(1.0,lift_acceleration));
  lift = noEvent(if abs(phase-2)<0.5 and abs(action-4)<0.5 then 1.0
    // A second timed collective pulse cushions the fast cube-jump landing.
    // Momentum carries the car onward; motor torque is released in the air.
    else if abs(phase-3)<0.5 and airborne>0.8 and up_y>0.94 and velocity_y< -1.5
      and position_y<stopping_height+1.0 and available_lift_acceleration>0.0 then 1.0
    else if flight>0.5 and up_y>0.94 and velocity_y< -2 and available_lift_acceleration>0.0
      and position_y<stopping_height+3.0 and pitch_up+pitch_down+roll_left+roll_right<0.5 then 1.0 else 0.0);
end CoursePilot;
