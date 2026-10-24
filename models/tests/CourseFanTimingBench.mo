model CourseFanTimingBench
  "Controller-only approach/release test; prescribed inputs do not move a physical car"
  CoursePilot pilot(
    phase=if time<1 then 3 else if time<4 then 4 else 5,
    action=if time<5 then 6 else 8, elapsed=time,
    position_x=0, velocity_x=0, turn_direction=1,
    jump_timing_offset_s=0, position_y=0.534,
    position_z=-270-12*time, speed=12, velocity_y=0, velocity_z=-12,
    attitude={1,0,0,0}, rates={0,0,0}, yaw=0, up_y=1, airborne=0,
    wheel_heading=0, wheel_heading_rate=0,
    full_lift_force=80000, mass=1950, angular_acceleration={1,1,1});
  output Real fan_command = pilot.command_fan;
  output Real position_z = pilot.position_z;
  output Real phase = pilot.phase;
  output Real action = pilot.action;
  annotation(experiment(StartTime=0,StopTime=6,Interval=0.01,Tolerance=1e-8));
end CourseFanTimingBench;
