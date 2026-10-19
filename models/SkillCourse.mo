model SkillCourse
  "Course measurements only. Native vehicle physics owns every maneuver."
  input Real stage;
  input Real enabled;
  input Real blocks;
  input Real position_x;
  input Real position_y;
  input Real position_z;
  input Real speed;
  input Real pitch_rate_deg_s;
  input Real up_y;
  input Real airborne;
  input Real gas_mass;
  input Real gas_temperature;
  input Real target_temperature;
  input Real fan_seal;
  input Real suction;
  Real elapsed(start=0,fixed=true);
  Real rotation(start=0,fixed=true);
  output Real course_stage;
  output Real course_blocks;
  output Real course_time_s;
  output Real course_air_rotation_degrees;
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
  Real target_y;
  Real target_z;
equation
  course_stage = stage;
  course_blocks = blocks;
  der(elapsed) = noEvent(if enabled>0.5 and stage<7 then 1.0 else 0.0);
  der(rotation) = noEvent(if abs(stage-6.0)<0.5 and airborne>0.8 then abs(pitch_rate_deg_s) else 0.0);
  course_time_s = elapsed;
  course_air_rotation_degrees = rotation;
  target_z = noEvent(if abs(stage-0.0)<0.5 then 140.0 else if abs(stage-1.0)<0.5 then 40.0 else if abs(stage-2.0)<0.5 then -100.0-8.0*blocks
    else if abs(stage-3.0)<0.5 then -200.0 else if abs(stage-4.0)<0.5 then -322.2 else if abs(stage-5.0)<0.5 then -300.0 else -260.0);
  target_y = noEvent(if abs(stage-4.0)<0.5 then 60.0 else if abs(stage-5.0)<0.5 then 64.46 else 0.66);
  target_distance_m = sqrt(position_x^2+(position_y-target_y)^2+(position_z-target_z)^2);
  launch_gate = noEvent(if abs(position_x)<6.0 and position_z<=140.0 and speed>=26.8224 and gas_mass<249.0 then 1.0 else 0.0);
  refill_zone = noEvent(if abs(position_x)<6.0 and position_y<1.5 and ((abs(stage-1.0)<0.5 and abs(position_z-40.0)<8.0)
    or (abs(stage-3.0)<0.5 and abs(position_z+200.0)<8.0)) then 1.0 else 0.0);
  refill_ready = noEvent(if gas_mass>=249.995 and abs(gas_temperature-target_temperature)<0.1 then 1.0 else 0.0);
  jump_clearance = noEvent(if abs(position_x)<6.0 and position_y>2.0 and airborne>0.8 then 1.0 else 0.0);
  climb_gate = noEvent(if position_y>60.0 and abs(position_x)<5.5 and fan_seal>0.4 and suction>20000.0 then 1.0 else 0.0);
  block_crossed = noEvent(if position_z<= -100.0-8.0*blocks then 1.0 else 0.0);
  crest_gate = noEvent(if position_y>63.5 and position_z> -304.0 then 1.0 else 0.0);
  airborne_gate = noEvent(if airborne>0.8 and position_y>20.0 then 1.0 else 0.0);
  healthy = noEvent(if elapsed>180.0 or (stage<0.5 and position_z<125.0 and launch_gate<0.5)
    or (abs(stage-1)<0.5 and position_z<32.0) or (abs(stage-3)<0.5 and position_z< -208.0) then 0.0 else 1.0);
  landing_gate = noEvent(if abs(position_x)<6.0 and position_z> -295.0 and position_z< -230.0
    and position_y<1.5 and up_y>0.95 and speed<2.0 and airborne<0.2 and rotation>170.0 then 1.0 else 0.0);
end SkillCourse;
