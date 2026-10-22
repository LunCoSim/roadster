model SkillCourse
  "Course measurements only. Native vehicle physics owns every maneuver."
  parameter Real launch_gate_z(unit="m") = 140.0;
  parameter Real first_refill_z(unit="m") = 40.0;
  input Real stage;
  input Real enabled;
  input Real blocks;
  input Real position_x;
  input Real position_y;
  input Real position_z;
  input Real speed;
  input Real pitch_rate_deg_s;
  input Real yaw_rate_deg_s;
  input Real roll_rate_deg_s;
  input Real velocity_y;
  input Real forward_z;
  input Real forward_speed;
  input Real up_y;
  input Real airborne;
  input Real gas_mass;
  input Real gas_temperature;
  input Real target_temperature;
  input Real fan_seal;
  input Real suction;
  Real elapsed(start=0,fixed=true);
  Real rotation(start=0,fixed=true);
  Real yaw_rotation(start=0,fixed=true);
  Real roll_rotation(start=0,fixed=true);
  Real pitch_rotation(start=0,fixed=true);
  Real impact_speed(start=0,fixed=true);
  Real backward_distance(start=0,fixed=true);
  output Real course_stage;
  output Real course_blocks;
  output Real course_time_s;
  output Real course_air_rotation_degrees;
  output Real course_air_yaw_degrees;
  output Real course_air_roll_degrees;
  output Real course_air_pitch_degrees;
  output Real landing_impact_speed;
  output Real course_backward_distance_m;
  output Real roll_gate;
  output Real yaw_gate;
  output Real mid_yaw_gate;
  output Real target_distance_m;
  output Real launch_gate;
  output Real refill_zone;
  output Real refill_ready;
  output Real jump_clearance;
  output Real climb_gate;
  output Real landing_gate;
  output Real block_crossed;
  output Real crest_gate;
  output Real airborne_gate;
  output Real healthy;
  output Real failure_reason "0 healthy, 1 timeout, 2 launch, 3 carry speed, 4 refill miss, 5 incomplete roll, 8 lost fan adhesion";
  Real target_y;
  Real target_z;
equation
  course_stage = stage;
  course_blocks = blocks;
  der(elapsed) = noEvent(if enabled>0.5 and stage<7 then 1.0 else 0.0);
  der(rotation) = noEvent(if abs(stage-6.0)<0.5 and airborne>0.8 then sqrt(pitch_rate_deg_s^2+yaw_rate_deg_s^2+roll_rate_deg_s^2) else 0.0);
  der(yaw_rotation) = noEvent(if abs(stage-6)<0.5 and airborne>0.8 then abs(yaw_rate_deg_s) else 0.0);
  der(pitch_rotation) = noEvent(if abs(stage-6)<0.5 and airborne>0.8 then abs(pitch_rate_deg_s) else 0.0);
  // Peak downward speed within the final metre above the resting wheel centre.
  // Retains the approach severity even after the native solver arrests descent.
  der(impact_speed) = noEvent(if abs(stage-6)<0.5 and position_y<1.66 and airborne>0.8 and -velocity_y>impact_speed then (-velocity_y-impact_speed)/0.0166666667 else 0.0);
  landing_impact_speed = impact_speed;
  course_air_pitch_degrees = pitch_rotation;
  der(roll_rotation) = noEvent(if abs(stage-6)<0.5 and airborne>0.8 then abs(roll_rate_deg_s) else 0.0);
  der(backward_distance) = noEvent(if abs(stage-6)<0.5 and airborne>0.8 and up_y>0.95 and forward_z< -0.9 then max(0.0,-forward_speed) else 0.0);
  course_air_yaw_degrees = yaw_rotation;
  course_air_roll_degrees = roll_rotation;
  course_backward_distance_m = backward_distance;
  roll_gate = noEvent(if up_y>0.97 and forward_z>0.94 and abs(roll_rate_deg_s)<35 and abs(pitch_rate_deg_s)<35 and abs(yaw_rate_deg_s)<30 then 1.0 else 0.0);
  mid_yaw_gate = noEvent(if up_y>0.94 and forward_z> -0.7 and yaw_rotation>35.0 then 1.0 else 0.0);
  yaw_gate = noEvent(if up_y>0.97 and forward_z>0.94 and abs(yaw_rate_deg_s)<30 and yaw_rotation>150 then 1.0 else 0.0);
  course_time_s = elapsed;
  course_air_rotation_degrees = rotation;
  target_z = noEvent(if abs(stage-0.0)<0.5 then launch_gate_z else if abs(stage-1.0)<0.5 then first_refill_z else if abs(stage-2.0)<0.5 then -100.0-12.0*blocks
    else if abs(stage-3.0)<0.5 then -200.0 else if abs(stage-4.0)<0.5 then -309.0 else if abs(stage-5.0)<0.5 then -300.0 else -260.0);
  target_y = noEvent(if abs(stage-4.0)<0.5 then 17.0 else if abs(stage-5.0)<0.5 then 18.873 else 0.66);
  target_distance_m = sqrt(position_x^2+(position_y-target_y)^2+(position_z-target_z)^2);
  launch_gate = noEvent(if abs(position_x)<6.0 and position_z<=launch_gate_z and speed>=26.8224 and gas_mass<249.0 then 1.0 else 0.0);
  refill_zone = noEvent(if abs(position_x)<6.0 and position_y<1.5 and ((abs(stage-1.0)<0.5 and abs(position_z-first_refill_z)<8.0)
    or (abs(stage-3.0)<0.5 and abs(position_z+200.0)<8.0)) then 1.0 else 0.0);
  refill_ready = noEvent(if gas_mass>=249.995 and abs(gas_temperature-target_temperature)<0.1 then 1.0 else 0.0);
  jump_clearance = noEvent(if abs(position_x)<6.0 and position_y>3.0 and airborne>0.8 then 1.0 else 0.0);
  climb_gate = noEvent(if position_y>17.0 and abs(position_x)<5.5 and fan_seal>0.4 and suction>20000.0 then 1.0 else 0.0);
  block_crossed = noEvent(if position_z<= -103.6-12.0*blocks then 1.0 else 0.0);
  crest_gate = noEvent(if position_y>17.8 and position_z> -301.0 then 1.0 else 0.0);
  airborne_gate = noEvent(if airborne>0.8 and position_y>10.0 then 1.0 else 0.0);
  failure_reason = noEvent(if elapsed>180.0 then 1.0
    else if abs(stage-4)<0.5 and position_y>12.0 and airborne>0.8 and (fan_seal<0.2 or suction<20000.0) then 8.0
    else if stage<0.5 and position_z<launch_gate_z-15.0 and launch_gate<0.5 then 2.0
    else if stage>0.5 and stage<3.5 and position_z<launch_gate_z-5.0 and speed<25.0 then 3.0
    else if (abs(stage-1)<0.5 and position_z<first_refill_z-8.0) or (abs(stage-3)<0.5 and position_z< -208.0) then 4.0
    else if abs(stage-6)<0.5 and position_y<1.0 and airborne<0.2 and roll_rotation<150.0 then 5.0 else 0.0);
  healthy = noEvent(if failure_reason>0.5 then 0.0 else 1.0);
  landing_gate = noEvent(if abs(position_x)<6.0 and position_z> -295.0 and position_z< -230.0
    and position_y<1.5 and up_y>0.95 and speed<0.2 and airborne<0.2 and roll_rotation>150.0 and forward_z>0.94 then 1.0 else 0.0);
end SkillCourse;
