model RoadsterVehicle
  "Single solving boundary: shared Ackermann controller plus Roadster EV envelope"
  parameter Real wheelbase = 2.75;
  parameter Real track = 1.72;
  parameter Real max_heading = 0.45;
  input Real throttle;
  input Real steer;
  input Real program_active;
  input Real autopilot_enable;
  input Real autopilot_target_x;
  input Real autopilot_target_z;
  input Real autopilot_speed;
  input Real autopilot_radius;
  input Real autopilot_turn_only;
  input Real autopilot_position_x;
  input Real autopilot_position_z;
  input Real autopilot_yaw;
  input Real autopilot_yaw_rate;
  input Real piloted;
  parameter Real boost_available = 0;
  parameter Real lift_available = 0;
  parameter Real gas_capacity_kg = 250;
  parameter Real initial_fill = 1.0;
  input Real brake;
  input Real boost;
  input Real lift;
  input Real thrust_x;
  input Real thrust_y;
  input Real thrust_z;
  input Real fan;
  input Real wheel_speed_left;
  input Real wheel_speed_right;
  input Real measured_vx;
  input Real measured_vz;
  input Real measured_vy;
  input Real ground_gap;
  input Real ground_valid;
  input Real attitude_w;
  input Real attitude_x;
  input Real attitude_y;
  input Real attitude_z;
  Real steering_position(start=0,fixed=true);
  Real steering_limit;
  LunCo.Mobility.RoverAckermannDrivetrain steering(
    wheelbase=wheelbase,track=track,max_heading=max_heading,
    throttle=throttle,steer=steering_position,program_active=program_active,
    autopilot_enable=autopilot_enable,autopilot_target_x=autopilot_target_x,
    autopilot_target_z=autopilot_target_z,autopilot_speed=autopilot_speed,
    autopilot_radius=autopilot_radius,autopilot_turn_only=autopilot_turn_only,
    autopilot_position_x=autopilot_position_x,autopilot_position_z=autopilot_position_z,
    autopilot_yaw=autopilot_yaw,autopilot_yaw_rate=autopilot_yaw_rate,piloted=piloted);
  RoadsterPowertrain powertrain(
    boost_available=boost_available, lift_available=lift_available,
    gas_capacity_kg=gas_capacity_kg,initial_fill=initial_fill,
    demand=steering.drive_left, brake=brake, boost=boost, lift=lift, fan=fan,
    thrust_x=thrust_x,thrust_y=thrust_y,thrust_z=thrust_z,
    omega_left=wheel_speed_left, omega_right=wheel_speed_right,
    velocity_x=measured_vx, velocity_z=measured_vz, velocity_y=measured_vy,
    ground_gap=ground_gap,ground_valid=ground_valid,yaw=autopilot_yaw);
  output Real torque_left;
  output Real torque_right;
  output Real freewheel_torque;
  output Real force_local_z;
  output Real force_local_y;
  output Real force_local_x;
  output Real force_x;
  output Real force_y;
  output Real force_z;
  output Real torque_x;
  output Real torque_y;
  output Real torque_z;
  output Real vehicle_mass_kg;
  output Real vehicle_inertia_xx;
  output Real vehicle_inertia_yy;
  output Real vehicle_inertia_zz;
  output Real tank_temperature_k;
  output Real tank_volume_m3;
  output Real gas_mass_kg;
  output Real tank_pressure_pa;
  output Real jet_force_x;
  output Real jet_force_y;
  output Real jet_force_z;
  output Real battery_power;
  output Real soc;
  output Real temperature_k;
  output Real impulse_remaining;
  output Real thruster_force;
  output Real downforce;
  output Real drive_left;
  output Real drive_right;
  output Real heading_fl;
  output Real heading_fr;
equation
  // Limit rack slew and high-speed steering authority. No visual-only yaw.
  steering_limit = min(1.0,atan(0.8*9.80665*wheelbase/max(1.0,measured_vx*measured_vx+measured_vz*measured_vz))/max_heading);
  der(steering_position) = max(-2.0,min(2.0,(max(-steering_limit,min(steering_limit,steer))-steering_position)/0.12));
  drive_left = steering.drive_left;
  drive_right = steering.drive_right;
  heading_fl = steering.heading_fl;
  heading_fr = steering.heading_fr;
  torque_left = powertrain.torque_left;
  torque_right = powertrain.torque_right;
  freewheel_torque = powertrain.freewheel_torque;
  force_local_z = powertrain.force_local_z;
  force_local_y = powertrain.force_local_y;
  force_local_x = powertrain.force_local_x;
  force_x = powertrain.force_x;
  force_y = powertrain.force_y;
  force_z = powertrain.force_z;
  vehicle_mass_kg = powertrain.vehicle_mass_kg;
  // Homogenized gas distribution centered at COM, 1.2 x 0.5 x 1.0 m.
  // Dry-car inertia includes wheels. Actual tank placement remains unknown.
  vehicle_inertia_xx = 3022.0+boost_available*gas_mass_kg*(0.5^2+1.0^2)/12.0;
  vehicle_inertia_yy = 3494.0+boost_available*gas_mass_kg*(1.2^2+1.0^2)/12.0;
  vehicle_inertia_zz = 708.0+boost_available*gas_mass_kg*(1.2^2+0.5^2)/12.0;
  tank_temperature_k = powertrain.tank_temperature_k;
  tank_volume_m3 = powertrain.tank_volume_m3;
  // Two front side jets act 1.7 m ahead of COM. Rotate body-Y yaw moment
  // to world axes using the measured quaternion, including airborne attitude.
  torque_x = -1.7*jet_force_x*2.0*(attitude_x*attitude_y-attitude_w*attitude_z);
  torque_y = -1.7*jet_force_x*(1.0-2.0*(attitude_x*attitude_x+attitude_z*attitude_z));
  torque_z = -1.7*jet_force_x*2.0*(attitude_y*attitude_z+attitude_w*attitude_x);
  gas_mass_kg = powertrain.gas_mass_kg;
  tank_pressure_pa = powertrain.tank_pressure_pa;
  jet_force_x = powertrain.jet_force_x;
  jet_force_y = powertrain.jet_force_y;
  jet_force_z = powertrain.jet_force_z;
  battery_power = powertrain.battery_power;
  soc = powertrain.soc;
  temperature_k = powertrain.temperature_k;
  impulse_remaining = powertrain.impulse_remaining;
  thruster_force = powertrain.thruster_force;
  downforce = powertrain.downforce;
end RoadsterVehicle;
