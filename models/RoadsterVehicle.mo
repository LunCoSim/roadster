model RoadsterVehicle
  "Single solving boundary: shared Ackermann controller plus Roadster EV envelope"
  parameter Real course_enabled = 0;
  output Real skill_course_active;
  input Real course_phase;
  input Real course_blocks_passed;
  input Real course_position_y;
  SkillCourse course(enabled=course_enabled,stage=course_phase,blocks=course_blocks_passed,
    position_x=autopilot_position_x,position_y=course_position_y,position_z=autopilot_position_z,
    speed=speed_mps,pitch_rate_deg_s=pitch_rate_deg_s,up_y=up_alignment,
    airborne=flight_control_weight,gas_mass=gas_mass_kg,gas_temperature=tank_temperature_k,
    target_temperature=refill_target_k,fan_seal=fan_seal,suction=downforce);
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
  parameter Real rear_tank_volume(unit="m3") = 0.2;
  parameter Real cabin_tank_volume(unit="m3") = 0.4;
  parameter Real fan_initial_fraction = 0.0;
  parameter Real initial_fill = 1.0;
  parameter Real initial_gas_temperature(unit="K") = 293.15;
  input Real brake;
  input Real boost;
  input Real lift;
  input Real thrust_x;
  input Real thrust_y;
  input Real thrust_z;
  input Real fan;
  input Real headlights;
  input Real refill;
  input Real instant_mass_offset;
  input Real instant_temperature_offset;
  input Real instant_wall_temperature_offset;
  input Real instant_refill_count;
  input Real instant_mechanical_energy_j;
  input Real instant_stored_energy_j;
  output Real instant_air_added_kg;
  output Real instant_services;
  output Real next_mass_offset;
  output Real next_temperature_offset;
  output Real next_wall_temperature_offset;
  output Real next_refill_count;
  output Real next_mechanical_energy_j;
  output Real next_stored_energy_j;
  input Real refill_target_temperature_k;
  input Real lift_fl;
  input Real lift_fr;
  input Real lift_rl;
  input Real lift_rr;
  Real moment_body_x;
  Real moment_body_y;
  Real moment_body_z;
  input Real wheel_speed_left;
  input Real wheel_speed_right;
  input Real measured_wx;
  input Real measured_wy;
  input Real measured_wz;
  Real omega_body[3];
  output Real flight_control_weight;
  output Real pitch_rate_deg_s;
  output Real roll_rate_deg_s;
  output Real yaw_rate_deg_s;
  input Real measured_vx;
  input Real measured_vz;
  input Real measured_vy;
  input Real ground_gap;
  input Real ground_valid;
  input Real attitude_w;
  input Real attitude_x;
  input Real attitude_y;
  input Real attitude_z;
  Real body_up_x;
  Real body_up_y;
  Real body_up_z;
  Real velocity_forward;
  input Real surface_gap_0;
  input Real surface_valid_0;
  input Real surface_nx_0;
  input Real surface_ny_0;
  input Real surface_nz_0;
  input Real surface_gap_1;
  input Real surface_valid_1;
  input Real surface_nx_1;
  input Real surface_ny_1;
  input Real surface_nz_1;
  input Real surface_gap_2;
  input Real surface_valid_2;
  input Real surface_nx_2;
  input Real surface_ny_2;
  input Real surface_nz_2;
  input Real surface_gap_3;
  input Real surface_valid_3;
  input Real surface_nx_3;
  input Real surface_ny_3;
  input Real surface_nz_3;
  parameter Real keyboard_steering_assistance = 1.0 "0 selects direct analog rack commands";
  SteeringDriver steering_driver(command=steer,speed=speed_mps,assistance=keyboard_steering_assistance);
  Real steering_position;
  Real steering_limit;
  output Real aerodynamic_drag_kn;
  output Real aerodynamic_downforce_kn;
  output Real aerodynamic_power_kw;
  output Real wing_deployment_percent;
  output Real steering_limit_degrees;
  output Real steer_left_degrees;
  output Real steer_right_degrees;
  output Real headlight_intensity_lm;
  output Real headlight_power_w;
  output Real headlight_peak_candela;
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
    rear_tank_volume=rear_tank_volume,cabin_tank_volume=cabin_tank_volume,
    gas_capacity_kg=gas_capacity_kg,initial_fill=initial_fill,fan_initial_fraction=fan_initial_fraction,initial_gas_temperature=initial_gas_temperature,
    steer=steer,attitude={attitude_w,attitude_x,attitude_y,attitude_z},omega_body=omega_body,headlight_switch=headlights,
    demand=steering.drive_left, brake=brake, boost=boost, lift=lift, fan=fan,refill=refill,instant_mass_offset=instant_mass_offset,instant_temperature_offset=instant_temperature_offset,
    instant_wall_temperature_offset=instant_wall_temperature_offset,instant_refill_count=instant_refill_count,
    instant_mechanical_energy_j=instant_mechanical_energy_j,instant_stored_energy_j=instant_stored_energy_j,refill_target_temperature_k=refill_target_temperature_k,
    lift_individual={lift_fl,lift_rl,lift_fr,lift_rr},
    thrust_x=thrust_x,thrust_y=thrust_y,thrust_z=thrust_z,
    omega_left=wheel_speed_left, omega_right=wheel_speed_right,
    velocity_x=measured_vx, velocity_z=measured_vz, velocity_y=measured_vy,
    ground_gap=ground_gap,ground_valid=ground_valid,velocity_forward=velocity_forward,
    body_up_y=body_up_y,
    surface_gap={surface_gap_0,surface_gap_1,surface_gap_2,surface_gap_3},
    surface_valid={surface_valid_0,surface_valid_1,surface_valid_2,surface_valid_3},
    surface_alignment={surface_nx_0*body_up_x+surface_ny_0*body_up_y+surface_nz_0*body_up_z,
      surface_nx_1*body_up_x+surface_ny_1*body_up_y+surface_nz_1*body_up_z,
      surface_nx_2*body_up_x+surface_ny_2*body_up_y+surface_nz_2*body_up_z,
      surface_nx_3*body_up_x+surface_ny_3*body_up_y+surface_nz_3*body_up_z});
  // Reusable engineering readouts; presentation code only formats these.
  output Real air_fill_percent;
  output Real refill_allowed;
  output Real refill_active;
  output Real refill_complete;
  output Real refill_finished;
  output Real refill_flow_kg_s;
  output Real service_power_w;
  output Real service_power_mw;
  output Real service_air_used_kg;
  output Real service_energy_j;
  output Real speed_mps(unit="m/s");
  output Real speed_kmh(unit="km/h");
  output Real speed_mph(unit="mi/h");
  output Real pressure_bar(unit="bar");
  output Real charge_percent(unit="%");
  output Real boost_force_kn(unit="kN");
  output Real lift_force_kn(unit="kN");
  output Real yaw_force_kn(unit="kN");
  output Real suction_force_kn(unit="kN");
  output Real air_discharge_enabled;
  output Real thermal_guard_active;
  output Real up_alignment;
  output Real refill_momentum_force_n;
  output Real refill_loading_power_w;
  output Real refill_target_k;
  output Real refill_target_pressure_pa;
  output Real tank_wall_temperature_k;
  output Real tank_heat_flow_w;
  output Real jet_lift_0;
  output Real jet_lift_1;
  output Real jet_lift_2;
  output Real jet_lift_3;
  output Real jet_rear_each_n;
  output Real lift_fl_kn;
  output Real lift_fr_kn;
  output Real lift_rl_kn;
  output Real lift_rr_kn;
  output Real recovered_power_w;
  output Real fan_angle_left;
  output Real fan_angle_right;
  output Real fan_rpm;
  output Real fan_requested;
  output Real fan_vacuum_kpa;
  output Real fan_power_kw;
  output Real fan_pressure_pa;
  output Real fan_power_w;
  output Real fan_seal;
  output Real wall_friction_margin_n;
  output Real plume_rear_radius_start;
  output Real plume_rear_radius_expanded;
  output Real plume_rear_expansion_length;
  output Real plume_rear_mixing_length;
  output Real plume_rear_radius_end;
  output Real plume_rear_exit_velocity;
  output Real plume_side_radius_start;
  output Real plume_side_radius_expanded;
  output Real plume_side_expansion_length;
  output Real plume_side_mixing_length;
  output Real plume_side_radius_end;
  output Real plume_side_exit_velocity;
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
  output Real rear_tank_air_kg(unit="kg");
  output Real cabin_tank_air_kg(unit="kg");
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
  headlight_intensity_lm = powertrain.headlights.renderer_isotropic_lumens;
  headlight_power_w = powertrain.headlights.electrical_power;
  headlight_peak_candela = powertrain.headlights.peak_candela;
  instant_services = instant_refill_count;
  instant_air_added_kg = instant_mass_offset;
  next_mass_offset = powertrain.next_mass_offset;
  next_temperature_offset = powertrain.next_temperature_offset;
  next_wall_temperature_offset = powertrain.next_wall_temperature_offset;
  next_refill_count = powertrain.next_refill_count;
  next_mechanical_energy_j = powertrain.next_mechanical_energy_j;
  next_stored_energy_j = powertrain.next_stored_energy_j;
  skill_course_active = course_enabled;
  course_stage = course.course_stage;
  course_blocks = course.course_blocks;
  course_time_s = course.course_time_s;
  course_air_rotation_degrees = course.course_air_rotation_degrees;
  target_distance_m = course.target_distance_m;
  launch_gate = course.launch_gate;
  refill_zone = course.refill_zone;
  refill_ready = course.refill_ready;
  jump_clearance = course.jump_clearance;
  climb_gate = course.climb_gate;
  landing_gate = course.landing_gate;
  // Contact proximity is measured in body coordinates, so wall driving remains
  // ground mode. All four probes must leave the suspension envelope for flight.
  flight_control_weight = 1.0-max({surface_valid_0*max(0.0,min(1.0,(0.50-surface_gap_0)/0.15)),
    surface_valid_1*max(0.0,min(1.0,(0.50-surface_gap_1)/0.15)),
    surface_valid_2*max(0.0,min(1.0,(0.50-surface_gap_2)/0.15)),
    surface_valid_3*max(0.0,min(1.0,(0.50-surface_gap_3)/0.15))});
  omega_body[1] = (1.0-2.0*(attitude_y^2+attitude_z^2))*measured_wx
    +2.0*(attitude_x*attitude_y+attitude_w*attitude_z)*measured_wy
    +2.0*(attitude_x*attitude_z-attitude_w*attitude_y)*measured_wz;
  omega_body[2] = body_up_x*measured_wx+body_up_y*measured_wy+body_up_z*measured_wz;
  omega_body[3] = 2.0*(attitude_x*attitude_z+attitude_w*attitude_y)*measured_wx
    +2.0*(attitude_y*attitude_z-attitude_w*attitude_x)*measured_wy
    +(1.0-2.0*(attitude_x^2+attitude_y^2))*measured_wz;
  // Measurement only: WASD never commands jets or changes meaning in flight.
  pitch_rate_deg_s = omega_body[1]*180.0/3.141592653589793;
  roll_rate_deg_s = omega_body[3]*180.0/3.141592653589793;
  yaw_rate_deg_s = omega_body[2]*180.0/3.141592653589793;
  air_fill_percent = powertrain.air_fill_percent;
  refill_allowed = powertrain.refill_allowed;
  refill_active = powertrain.refill_active;
  refill_complete = powertrain.refill_complete;
  refill_finished = max(0.0,min(1.0,refill))*refill_complete;
  refill_flow_kg_s = powertrain.refill_flow_kg_s;
  service_power_w = powertrain.service_power_w;
  service_power_mw = service_power_w/1000000.0;
  service_air_used_kg = powertrain.service_air_used_kg;
  service_energy_j = powertrain.service_energy_j;
  body_up_x = 2.0*(attitude_x*attitude_y-attitude_w*attitude_z);
  body_up_y = 1.0-2.0*(attitude_x^2+attitude_z^2);
  body_up_z = 2.0*(attitude_y*attitude_z+attitude_w*attitude_x);
  velocity_forward = -(2.0*(attitude_x*attitude_z+attitude_w*attitude_y)*measured_vx
    +2.0*(attitude_y*attitude_z-attitude_w*attitude_x)*measured_vy
    +(1.0-2.0*(attitude_x^2+attitude_y^2))*measured_vz);
  fan_angle_left = powertrain.suction.rotor_angle;
  fan_angle_right = -powertrain.suction.rotor_angle;
  fan_rpm = powertrain.suction.rotor_rpm;
  fan_requested = max(0.0,min(1.0,fan));
  fan_vacuum_kpa = fan_pressure_pa/1000.0;
  fan_power_kw = fan_power_w/1000.0;
  fan_pressure_pa = powertrain.suction.pressure_drop;
  fan_power_w = powertrain.suction.electrical_power;
  fan_seal = powertrain.suction.seal;
  wall_friction_margin_n = 1.4*downforce-vehicle_mass_kg*9.80665*sqrt(max(0.0,1.0-body_up_y^2));
  plume_rear_radius_start = powertrain.rear_nozzle.radius_start;
  plume_rear_radius_expanded = powertrain.rear_nozzle.radius_expanded;
  plume_rear_expansion_length = powertrain.rear_nozzle.expansion_length;
  plume_rear_mixing_length = powertrain.rear_nozzle.mixing_length;
  plume_rear_radius_end = powertrain.rear_nozzle.radius_end;
  plume_rear_exit_velocity = powertrain.rear_nozzle.exit_velocity;
  plume_side_radius_start = powertrain.side_nozzle.radius_start;
  plume_side_radius_expanded = powertrain.side_nozzle.radius_expanded;
  plume_side_expansion_length = powertrain.side_nozzle.expansion_length;
  plume_side_mixing_length = powertrain.side_nozzle.mixing_length;
  plume_side_radius_end = powertrain.side_nozzle.radius_end;
  plume_side_exit_velocity = powertrain.side_nozzle.exit_velocity;
  speed_mps = sqrt(measured_vx*measured_vx+measured_vy*measured_vy+measured_vz*measured_vz);
  speed_kmh = 3.6*speed_mps;
  speed_mph = speed_mps/0.44704;
  pressure_bar = tank_pressure_pa/100000.0;
  charge_percent = 100.0*soc;
  boost_force_kn = -jet_force_z/1000.0;
  lift_force_kn = jet_force_y/1000.0;
  yaw_force_kn = jet_force_x/1000.0;
  suction_force_kn = downforce/1000.0;
  air_discharge_enabled = powertrain.discharge_enabled;
  up_alignment = body_up_y;
  refill_momentum_force_n = sqrt(powertrain.inlet_force[1]^2+powertrain.inlet_force[2]^2+powertrain.inlet_force[3]^2);
  refill_loading_power_w = powertrain.mass_inflow*speed_mps^2;
  refill_target_k = refill_target_temperature_k;
  refill_target_pressure_pa = powertrain.target_air.pressure;
  thermal_guard_active = noEvent(if tank_temperature_k<=powertrain.minimum_discharge_temperature then 1.0 else 0.0);
  tank_wall_temperature_k = powertrain.tank_heat.wall_temperature;
  tank_heat_flow_w = powertrain.tank_heat.heat_to_gas;
  // Engineering readouts; all vehicle motion is integrated by native physics.
  aerodynamic_drag_kn = powertrain.aero.drag_force/1000.0;
  aerodynamic_downforce_kn = powertrain.aero.downforce/1000.0;
  aerodynamic_power_kw = powertrain.aero.drag_power/1000.0;
  wing_deployment_percent = 100.0*powertrain.aero.wing_deployment;
  // Rack travel and actuator rate are physical limits. Tire slip and the
  // native Coulomb cone determine high-speed understeer, not an input cap.
  steering_limit = 1.0;
  steering_limit_degrees = max_heading*180.0/3.141592653589793;
  steering_position = steering_driver.rack_position;
  steer_left_degrees = heading_fl*180.0/3.141592653589793;
  steer_right_degrees = heading_fr*180.0/3.141592653589793;
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
  rear_tank_air_kg = powertrain.rear_tank_air_kg;
  cabin_tank_air_kg = powertrain.cabin_tank_air_kg;
  // Each corner lift force has its own lever arm. Symmetric commands cancel
  // moments; individual commands pitch and roll the vehicle physically.
  jet_lift_0 = powertrain.corner_lift[1];
  jet_lift_1 = powertrain.corner_lift[2];
  jet_lift_2 = powertrain.corner_lift[3];
  jet_lift_3 = powertrain.corner_lift[4];
  jet_rear_each_n = jet_force_z/4.0;
  lift_fl_kn = jet_lift_0/1000.0;
  lift_rl_kn = jet_lift_1/1000.0;
  lift_fr_kn = jet_lift_2/1000.0;
  lift_rr_kn = jet_lift_3/1000.0;
  recovered_power_w = powertrain.recovered_power_w;
  // Stationary incoming air also acquires angular momentum in the centered
  // tank distribution. The native solver receives the corresponding loading
  // torque while its inertia is updated; co-rotating outgoing gas cancels its
  // own inertia-change term. No angular-velocity rescaling is scripted.
  moment_body_x = 1.5*(jet_lift_0+jet_lift_2-jet_lift_1-jet_lift_3)
    -powertrain.mass_inflow*boost_available*(0.5^2+1.0^2)/12.0*omega_body[1];
  moment_body_y = -1.7*jet_force_x
    -powertrain.mass_inflow*boost_available*(1.2^2+1.0^2)/12.0*omega_body[2];
  moment_body_z = 0.8*(-jet_lift_0-jet_lift_1+jet_lift_2+jet_lift_3)
    -powertrain.mass_inflow*boost_available*(1.2^2+0.5^2)/12.0*omega_body[3];
  torque_x = (1.0-2.0*(attitude_y^2+attitude_z^2))*moment_body_x
    +2.0*(attitude_x*attitude_y-attitude_w*attitude_z)*moment_body_y
    +2.0*(attitude_x*attitude_z+attitude_w*attitude_y)*moment_body_z;
  torque_y = 2.0*(attitude_x*attitude_y+attitude_w*attitude_z)*moment_body_x
    +(1.0-2.0*(attitude_x^2+attitude_z^2))*moment_body_y
    +2.0*(attitude_y*attitude_z-attitude_w*attitude_x)*moment_body_z;
  torque_z = 2.0*(attitude_x*attitude_z-attitude_w*attitude_y)*moment_body_x
    +2.0*(attitude_y*attitude_z+attitude_w*attitude_x)*moment_body_y
    +(1.0-2.0*(attitude_x^2+attitude_y^2))*moment_body_z;
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
