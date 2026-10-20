model RoadsterVehicle
  "Single solving boundary: shared Ackermann controller plus Roadster EV envelope"
  parameter Real course_enabled = 0;
  parameter Real course_launch_gate_z(unit="m") = 140.0;
  parameter Real course_first_refill_z(unit="m") = 40.0;
  output Real skill_course_active;
  input Real course_phase;
  input Real course_failure_code = 0.0 "Latched native task failure: 6 cube impact, 7 checkpoint; 1-5 from SkillCourse";
  output Real course_failure_reason;
  input Real course_blocks_passed;
  input Real course_position_y;
  input Real course_action;
  input Real course_turn_direction = 1.0 "Positive yaw until the course latches its measured drift decision";
  input Real course_jump_timing_offset_s = 0.0 "Guidance-only timing perturbation for acceptance; positive fires earlier";
  input Real course_jump_roll_target_deg = 360.0 "Signed obstacle-jump kickflip request; zero selects an upright jump";
  input Real course_autopilot_enable;
  output Real course_autopilot_active;
  output Real course_block_crossed;
  output Real course_crest_gate;
  output Real course_airborne_gate;
  output Real course_healthy;
  output Real course_launch_started;
  output Real course_step;
  output Real course_takeoff_gate;
  output Real course_jump_impulse_ready;
  output Real course_jump_roll_degrees;
  output Real course_jump_roll_ready;
  output Real course_air_pitch_degrees;
  output Real course_landing_impact_speed;
  output Real pilot_yaw_direction;
  output Real course_mid_yaw_gate;
  output Real course_forward_speed;
  output Real course_forward_z;
  output Real course_roll_gate;
  output Real course_yaw_gate;
  output Real course_air_yaw_degrees;
  output Real course_air_roll_degrees;
  output Real course_backward_distance_m;
  output Real pilot_command_throttle;
  output Real pilot_command_steer;
  output Real pilot_command_brake;
  output Real pilot_command_thrust_z;
  output Real pilot_command_thrust_y;
  output Real pilot_command_thrust_x;
  output Real pilot_command_fan;
  output Real pilot_command_lift_fl;
  output Real pilot_command_lift_fr;
  output Real pilot_command_lift_rl;
  output Real pilot_command_lift_rr;
  output Real pilot_forward;
  output Real pilot_forward_on;
  output Real pilot_forward_off;
  output Real pilot_reverse;
  output Real pilot_reverse_on;
  output Real pilot_reverse_off;
  output Real pilot_left;
  output Real pilot_left_on;
  output Real pilot_left_off;
  output Real pilot_right;
  output Real pilot_right_on;
  output Real pilot_right_off;
  output Real pilot_boost;
  output Real pilot_boost_on;
  output Real pilot_boost_off;
  output Real pilot_brake;
  output Real pilot_brake_on;
  output Real pilot_brake_off;
  output Real pilot_lift;
  output Real pilot_lift_on;
  output Real pilot_lift_off;
  output Real pilot_fan;
  output Real pilot_fan_on;
  output Real pilot_fan_off;
  output Real pilot_pitch_up;
  output Real pilot_pitch_up_on;
  output Real pilot_pitch_up_off;
  output Real pilot_pitch_down;
  output Real pilot_pitch_down_on;
  output Real pilot_pitch_down_off;
  output Real pilot_yaw_left;
  output Real pilot_yaw_left_on;
  output Real pilot_yaw_left_off;
  output Real pilot_yaw_right;
  output Real pilot_yaw_right_on;
  output Real pilot_yaw_right_off;
  output Real pilot_roll_left;
  output Real pilot_roll_left_on;
  output Real pilot_roll_left_off;
  output Real pilot_roll_right;
  output Real pilot_roll_right_on;
  output Real pilot_roll_right_off;
  CoursePilot pilot(phase=course_phase,action=course_action,elapsed=course_time_s,
    jump_roll_degrees=course_jump_roll_target_deg,
    position_x=autopilot_position_x,velocity_x=measured_vx,turn_direction=course_turn_direction,jump_timing_offset_s=course_jump_timing_offset_s,
    position_y=course_position_y,position_z=autopilot_position_z,
    speed=speed_mps,velocity_y=measured_vy,velocity_z=measured_vz,
    attitude={attitude_w,attitude_x,attitude_y,attitude_z},
    rates={pitch_rate_deg_s,yaw_rate_deg_s,roll_rate_deg_s},
    yaw=autopilot_yaw,up_y=up_alignment,airborne=flight_control_weight,
    wheel_heading=heading_fl,wheel_heading_rate=-max_heading*steering_driver.rack_velocity,
    steering_preview_s=steering_driver.command_tau+steering_driver.rack_tau,full_lift_force=full_lift_force_n,mass=vehicle_mass_kg,
    wheelbase=wheelbase,angular_acceleration={
      full_lift_force_n*abs(lift_front_z-mass_center_z)/(1.0+rear_lift_trim)/vehicle_inertia_xx,
      side_yaw_acceleration,full_lift_force_n*0.4/vehicle_inertia_zz});
  SkillCourse course(enabled=course_enabled,stage=course_phase,blocks=course_blocks_passed,
    launch_gate_z=course_launch_gate_z,first_refill_z=course_first_refill_z,
    position_x=autopilot_position_x,position_y=course_position_y,position_z=autopilot_position_z,
    speed=speed_mps,velocity_y=measured_vy,pitch_rate_deg_s=pitch_rate_deg_s,yaw_rate_deg_s=yaw_rate_deg_s,
    roll_rate_deg_s=roll_rate_deg_s,forward_z=-1.0+2.0*(attitude_x^2+attitude_y^2),
    forward_speed=velocity_forward,up_y=up_alignment,
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
  // Positions are authored in USD body coordinates (forward -Z, up +Y).
  parameter Real lift_front_z = -0.90;
  parameter Real lift_rear_z = 1.85;
  parameter Real lift_x = 0.8;
  parameter Real lift_y = -0.32;
  parameter Real rear_jet_y = -0.14 "Study mount: thrust line through COM, no artificial attitude correction";
  parameter Real rear_jet_z = 2.30;
  parameter Real side_jet_y = -0.1;
  parameter Real side_jet_z = -1.90;
  parameter Real mass_center_y = -0.14;
  parameter Real mass_center_z = 0.0;
  parameter Real rear_lift_trim = min(1.0,max(0.0,(mass_center_z-lift_front_z)/(lift_rear_z-mass_center_z)))
    "Fixed geometry trim for collective and bank commands, not attitude feedback";
  LaunchSizing launch_sizing(initial_mass=powertrain.dry_mass_kg+boost_available*gas_capacity_kg);
  ThrusterMount rear_mount(point={0,rear_jet_y,rear_jet_z},center_of_mass={0,mass_center_y,mass_center_z},force={0,0,jet_force_z});
  ThrusterMount fl_mount(point={-lift_x,lift_y,lift_front_z},center_of_mass={0,mass_center_y,mass_center_z},force={0,jet_lift_0,0});
  ThrusterMount rl_mount(point={-lift_x,lift_y,lift_rear_z},center_of_mass={0,mass_center_y,mass_center_z},force={0,jet_lift_1,0});
  ThrusterMount fr_mount(point={lift_x,lift_y,lift_front_z},center_of_mass={0,mass_center_y,mass_center_z},force={0,jet_lift_2,0});
  ThrusterMount rr_mount(point={lift_x,lift_y,lift_rear_z},center_of_mass={0,mass_center_y,mass_center_z},force={0,jet_lift_3,0});
  // Opposing nose-side jets share Y/Z. Their X-coordinate is along the force
  // line and therefore does not alter their moment about the centered X COM.
  ThrusterMount side_mount(point={0,side_jet_y,side_jet_z},center_of_mass={0,mass_center_y,mass_center_z},force={jet_force_x,0,0});
  output Real full_rear_force_n;
  output Real full_lift_force_n;
  output Real full_side_force_n;
  output Real full_mass_flow_kg_s;
  output Real actual_mass_flow_kg_s;
  output Real hover_fraction;
  output Real lift_net_acceleration;
  output Real side_yaw_acceleration;
  output Real thruster_pitch_moment_nm;
  output Real thruster_yaw_moment_nm;
  output Real thruster_roll_moment_nm;
  output Real launch_mean_force_n;
  output Real launch_wheel_mean_force_n;
  output Real launch_boost_mean_force_n;
  parameter Real wheelbase = 2.75;
  parameter Real track = 1.72;
  parameter Real max_heading = 0.45;
  input Real throttle;
  input Real launch_measurement_active "Acceptance instrumentation only; no physical effect";
  Real launch_elapsed(start=0,fixed=true);
  Real launch_rear_impulse(start=0,fixed=true);
  output Real launch_recorded_time_s;
  output Real launch_rear_impulse_ns;
  output Real launch_rear_mean_force_n;
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
  // A-B01/S10: 120 kWh source-informed assumption, not a released Tesla spec.
  // https://www.motortrend.com/news/first-look-2028-tesla-roadster-performance-thrust-rocket
  // BatteryStudy.mo and references/battery-study.md record every inference.
  parameter Real battery_capacity_kwh = 120 "Study energy, not a published Tesla specification";
  parameter Real reference_vehicle_dry_mass_kg = 1700;
  BatteryStudy battery(capacity_kwh=battery_capacity_kwh,
    reference_vehicle_dry_mass_kg=reference_vehicle_dry_mass_kg);
  output Real battery_nominal_energy_kwh;
  output Real battery_range_energy_kwh;
  output Real battery_range_proxy_km;
  output Real battery_inferred_capacity_kwh;
  output Real battery_pack_mass_estimate_kg;
  output Real battery_pack_volume_estimate_l;
  output Real battery_non_pack_reference_mass_kg;
  output Real battery_peak_dc_power_kw;
  output Real battery_peak_equivalent_c;
  output Real battery_charge_10_80_energy_kwh;
  output Real battery_charge_10min_average_kw;
  output Real battery_charge_12min_average_kw;
  output Real battery_energy_remaining_kwh;
  // U01/S05: user-selected 250 kg Rocket inventory in 200+400 L. Thrust's
  // equal-density mass is derived, not a reported Tesla mass specification.
  // Sources: references/spec-audit.md and https://www.youtube.com/watch?v=22rvpUecLts
  parameter Real reference_gas_mass_kg = 250;
  parameter Real reference_storage_volume_m3 = 0.6;
  parameter Real gas_capacity_kg = reference_gas_mass_kg*(rear_tank_volume+cabin_tank_volume)/reference_storage_volume_m3;
  parameter Real rear_tank_volume(unit="m3") = 0.2;
  parameter Real cabin_tank_volume(unit="m3") = 0.4;
  parameter Real fan_initial_fraction = 0.0;
  parameter Real initial_fill = 1.0;
  parameter Real initial_gas_temperature(unit="K") = 293.15;
  input Real jet_flight_enable = 0.0 "Optional valve-request flight controller; off for normal course/manual play";
  input Real jet_flight_target_x = 0.0;
  input Real jet_flight_target_y = 30.0;
  input Real jet_flight_target_z = -310.0;
  input Real jet_flight_target_yaw = 0.0;
  JetFlightPilot jet_flight(position={autopilot_position_x,course_position_y,autopilot_position_z},
    velocity={measured_vx,measured_vy,measured_vz},attitude={attitude_w,attitude_x,attitude_y,attitude_z},
    omega=omega_body,target={jet_flight_target_x,jet_flight_target_y,jet_flight_target_z},
    target_yaw=jet_flight_target_yaw,mass=vehicle_mass_kg,
    inertia={vehicle_inertia_xx,vehicle_inertia_yy,vehicle_inertia_zz},
    full_lift_force=full_lift_force_n,full_side_force=full_side_force_n,rear_trim=rear_lift_trim,
    front_z=lift_front_z,rear_z=lift_rear_z,lift_x=lift_x,side_y=side_jet_y,
    side_z=side_jet_z,center_y=mass_center_y,center_z=mass_center_z);
  input Real brake;
  input Real boost;
  input Real lift;
  input Real thrust_x;
  input Real thrust_y;
  input Real thrust_z;
  input Real fan;
  input Real headlights;
  input Real refill;
  input Real unlimited_air;
  output Real unlimited_air_active;
  output Real ideal_supply_flow_kg_s;
  output Real ideal_supply_heat_w;
  output Real ideal_supply_air_kg;
  output Real ideal_supply_power_w;
  output Real ideal_supply_energy_j;
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
  SteeringDriver steering_driver(command=steer,
    speed=speed_mps,assistance=keyboard_steering_assistance);
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
  RoadsterPowertrain powertrain(capacity_kwh=battery_capacity_kwh,dry_mass_kg=battery.vehicle_dry_mass_kg,
    boost_available=boost_available, lift_available=lift_available,lift_trim={1,rear_lift_trim,1,rear_lift_trim},
    rear_tank_volume=rear_tank_volume,cabin_tank_volume=cabin_tank_volume,
    gas_capacity_kg=gas_capacity_kg,initial_fill=initial_fill,initial_gas_temperature=initial_gas_temperature,
    steer=steer,attitude={attitude_w,attitude_x,attitude_y,attitude_z},omega_body=omega_body,headlight_switch=headlights,
    demand=steering.drive_left, brake=brake, boost=if noEvent(jet_flight_enable>0.5) then 0.0 else boost, lift=if noEvent(jet_flight_enable>0.5) then 0.0 else lift, adhesion_force_body=adhesion.force_body,adhesion_power_w=adhesion.electrical_power,refill=refill,unlimited_air=unlimited_air,instant_mass_offset=instant_mass_offset,instant_temperature_offset=instant_temperature_offset,
    instant_wall_temperature_offset=instant_wall_temperature_offset,instant_refill_count=instant_refill_count,
    instant_mechanical_energy_j=instant_mechanical_energy_j,instant_stored_energy_j=instant_stored_energy_j,refill_target_temperature_k=refill_target_temperature_k,
    lift_individual=if noEvent(jet_flight_enable>0.5) then jet_flight.corner else {lift_fl,lift_rl,lift_fr,lift_rr},
    thrust_x=if noEvent(jet_flight_enable>0.5) then jet_flight.side else thrust_x,
    thrust_y=if noEvent(jet_flight_enable>0.5) then jet_flight.collective else thrust_y,
    thrust_z=if noEvent(jet_flight_enable>0.5) then 0.0 else thrust_z,
    omega_left=wheel_speed_left, omega_right=wheel_speed_right,
    velocity_x=measured_vx, velocity_z=measured_vz, velocity_y=measured_vy,
    ground_gap=ground_gap,ground_valid=ground_valid,velocity_forward=velocity_forward,
    body_up_y=body_up_y);
  // Assembly adapter only: native geometry binds to the internal adhesion law.
  // Both components are flattened into ONE Modelica solve; no extra participant,
  // communication lag, duplicate rotor integration or script physics is added.
  FanAdhesion adhesion(command=if noEvent(jet_flight_enable>0.5) then 0.0 else fan,enabled=powertrain.enabled,initial_speed_fraction=fan_initial_fraction,
    center_of_mass={0,mass_center_y,mass_center_z},body_up={body_up_x,body_up_y,body_up_z},
    gap={surface_gap_0,surface_gap_1,surface_gap_2,surface_gap_3},
    valid={surface_valid_0,surface_valid_1,surface_valid_2,surface_valid_3},
    normal_x={surface_nx_0,surface_nx_1,surface_nx_2,surface_nx_3},
    normal_y={surface_ny_0,surface_ny_1,surface_ny_2,surface_ny_3},
    normal_z={surface_nz_0,surface_nz_1,surface_nz_2,surface_nz_3});
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
  output Real thermal_guard_temperature_k(unit="K")
    "The study's assumed discharge guard, exposed for native telemetry plots";
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
  output Real chassis_mass_kg;
  output Real chassis_com_y;
  output Real chassis_com_z;
  output Real chassis_inertia_xx;
  output Real chassis_inertia_yy;
  output Real chassis_inertia_zz;
  output Real vehicle_inertia_xx;
  output Real vehicle_inertia_yy;
  output Real vehicle_inertia_zz;
  output Real tank_temperature_k;
  output Real rear_tank_air_kg(unit="kg");
  output Real cabin_tank_air_kg(unit="kg");
  output Real tank_volume_m3;
  output Real gas_mass_kg;
  output Real gas_capacity_mass_kg;
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
  der(launch_elapsed) = max(0.0,min(1.0,launch_measurement_active));
  der(launch_rear_impulse) = max(0.0,min(1.0,launch_measurement_active))*abs(jet_force_z);
  launch_recorded_time_s = launch_elapsed;
  launch_rear_impulse_ns = launch_rear_impulse;
  launch_rear_mean_force_n = launch_rear_impulse/max(1e-9,launch_elapsed);
  full_rear_force_n = boost_available*powertrain.full_area_force;
  full_lift_force_n = lift_available*0.5*(1.0+rear_lift_trim)*powertrain.full_area_force;
  full_side_force_n = lift_available*0.04*powertrain.full_area_force;
  full_mass_flow_kg_s = max(boost_available,lift_available)*powertrain.throat_area*powertrain.mass_flux*powertrain.discharge_enabled;
  actual_mass_flow_kg_s = powertrain.mass_flow;
  hover_fraction = vehicle_mass_kg*9.80665/max(1.0,full_lift_force_n);
  lift_net_acceleration = full_lift_force_n/vehicle_mass_kg-9.80665;
  side_yaw_acceleration = abs(side_jet_z-mass_center_z)*full_side_force_n/vehicle_inertia_yy;
  thruster_pitch_moment_nm = rear_mount.moment[1]+fl_mount.moment[1]+rl_mount.moment[1]+fr_mount.moment[1]+rr_mount.moment[1]+side_mount.moment[1];
  thruster_yaw_moment_nm = rear_mount.moment[2]+fl_mount.moment[2]+rl_mount.moment[2]+fr_mount.moment[2]+rr_mount.moment[2]+side_mount.moment[2];
  thruster_roll_moment_nm = rear_mount.moment[3]+fl_mount.moment[3]+rl_mount.moment[3]+fr_mount.moment[3]+rr_mount.moment[3]+side_mount.moment[3];
  launch_mean_force_n = launch_sizing.required_mean_net_force;
  launch_wheel_mean_force_n = launch_sizing.estimated_mean_wheel_net_force;
  launch_boost_mean_force_n = launch_sizing.estimated_additional_mean_boost;
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
  course_autopilot_active = noEvent(if course_enabled>0.5 and course_autopilot_enable>0.5 then 1.0 else 0.0);
  course_block_crossed = course.block_crossed;
  course_crest_gate = course.crest_gate;
  course_airborne_gate = course.airborne_gate;
  course_healthy = course.healthy;
  course_failure_reason = noEvent(if course_failure_code>0.5 then course_failure_code else course.failure_reason);
  pilot_command_throttle = pilot.command_throttle;
  pilot_command_steer = pilot.command_steer;
  pilot_command_brake = pilot.command_brake;
  pilot_command_thrust_z = pilot.command_thrust_z;
  pilot_command_thrust_y = pilot.command_thrust_y;
  pilot_command_thrust_x = pilot.command_thrust_x;
  pilot_command_fan = pilot.command_fan;
  pilot_command_lift_fl = pilot.command_lift_fl;
  pilot_command_lift_fr = pilot.command_lift_fr;
  pilot_command_lift_rl = pilot.command_lift_rl;
  pilot_command_lift_rr = pilot.command_lift_rr;
  course_launch_started = noEvent(if abs(throttle)>0.5 or thrust_z>0.5 then 1.0 else 0.0);
  pilot_forward = pilot.forward;
  pilot_forward_on = course_autopilot_active*pilot_forward;
  pilot_forward_off = course_autopilot_active*(1.0-pilot_forward);
  pilot_reverse = pilot.reverse;
  pilot_reverse_on = course_autopilot_active*pilot_reverse;
  pilot_reverse_off = course_autopilot_active*(1.0-pilot_reverse);
  pilot_left = pilot.left;
  pilot_left_on = course_autopilot_active*pilot_left;
  pilot_left_off = course_autopilot_active*(1.0-pilot_left);
  pilot_right = pilot.right;
  pilot_right_on = course_autopilot_active*pilot_right;
  pilot_right_off = course_autopilot_active*(1.0-pilot_right);
  pilot_boost = pilot.boost;
  pilot_boost_on = course_autopilot_active*pilot_boost;
  pilot_boost_off = course_autopilot_active*(1.0-pilot_boost);
  pilot_brake = pilot.brake;
  pilot_brake_on = course_autopilot_active*pilot_brake;
  pilot_brake_off = course_autopilot_active*(1.0-pilot_brake);
  pilot_lift = pilot.lift;
  pilot_lift_on = course_autopilot_active*pilot_lift;
  pilot_lift_off = course_autopilot_active*(1.0-pilot_lift);
  pilot_fan = pilot.fan;
  pilot_fan_on = course_autopilot_active*pilot_fan;
  pilot_fan_off = course_autopilot_active*(1.0-pilot_fan);
  pilot_pitch_up = pilot.pitch_up;
  pilot_pitch_up_on = course_autopilot_active*pilot_pitch_up;
  pilot_pitch_up_off = course_autopilot_active*(1.0-pilot_pitch_up);
  pilot_pitch_down = pilot.pitch_down;
  pilot_pitch_down_on = course_autopilot_active*pilot_pitch_down;
  pilot_pitch_down_off = course_autopilot_active*(1.0-pilot_pitch_down);
  pilot_yaw_left = pilot.yaw_left;
  pilot_yaw_left_on = course_autopilot_active*pilot_yaw_left;
  pilot_yaw_left_off = course_autopilot_active*(1.0-pilot_yaw_left);
  pilot_yaw_right = pilot.yaw_right;
  pilot_yaw_right_on = course_autopilot_active*pilot_yaw_right;
  pilot_yaw_right_off = course_autopilot_active*(1.0-pilot_yaw_right);
  pilot_roll_left = pilot.roll_left;
  pilot_roll_left_on = course_autopilot_active*pilot_roll_left;
  pilot_roll_left_off = course_autopilot_active*(1.0-pilot_roll_left);
  pilot_roll_right = pilot.roll_right;
  pilot_roll_right_on = course_autopilot_active*pilot_roll_right;
  pilot_roll_right_off = course_autopilot_active*(1.0-pilot_roll_right);
  course_stage = course.course_stage;
  course_blocks = course.course_blocks;
  course_time_s = course.course_time_s;
  course_air_rotation_degrees = course.course_air_rotation_degrees;
  course_air_yaw_degrees = course.course_air_yaw_degrees;
  course_air_roll_degrees = course.course_air_roll_degrees;
  course_backward_distance_m = course.course_backward_distance_m;
  course_roll_gate = course.roll_gate;
  course_yaw_gate = course.yaw_gate;
  course_step = course_action;
  course_takeoff_gate = pilot.takeoff_gate;
  course_jump_impulse_ready = pilot.jump_impulse_ready;
  course_jump_roll_degrees = pilot.jump_roll_progress_deg;
  course_jump_roll_ready = pilot.jump_roll_ready;
  course_air_pitch_degrees = course.course_air_pitch_degrees;
  course_landing_impact_speed = course.landing_impact_speed;
  pilot_yaw_direction = pilot.recommended_yaw_direction;
  course_mid_yaw_gate = course.mid_yaw_gate;
  course_forward_speed = velocity_forward;
  course_forward_z = -1.0+2.0*(attitude_x^2+attitude_y^2);
  target_distance_m = course.target_distance_m;
  launch_gate = course.launch_gate;
  refill_zone = course.refill_zone;
  refill_ready = course.refill_ready;
  jump_clearance = course.jump_clearance;
  climb_gate = course.climb_gate;
  landing_gate = course.landing_gate;
  // This observation only labels course/HUD state. It never changes controls.
  flight_control_weight = 1.0-adhesion.surface_proximity;
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
  fan_angle_left = adhesion.rotor_angle;
  fan_angle_right = -adhesion.rotor_angle;
  fan_rpm = adhesion.rotor_rpm;
  fan_requested = max(0.0,min(1.0,fan));
  fan_vacuum_kpa = fan_pressure_pa/1000.0;
  fan_power_kw = fan_power_w/1000.0;
  fan_pressure_pa = adhesion.pressure_drop;
  fan_power_w = adhesion.electrical_power;
  fan_seal = adhesion.seal;
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
  thermal_guard_temperature_k = powertrain.minimum_discharge_temperature;
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
  unlimited_air_active = powertrain.unlimited_air_active;
  ideal_supply_flow_kg_s = powertrain.ideal_supply_flow_kg_s;
  ideal_supply_heat_w = powertrain.ideal_supply_heat_w;
  ideal_supply_air_kg = powertrain.ideal_supply_air_kg;
  ideal_supply_power_w = powertrain.ideal_supply_power_w;
  ideal_supply_energy_j = powertrain.ideal_supply_energy_j;
  battery_nominal_energy_kwh = battery.nominal_energy_kwh;
  battery_range_energy_kwh = battery.range_energy_kwh;
  battery_range_proxy_km = battery.range_proxy_km;
  battery_inferred_capacity_kwh = battery.inferred_capacity_kwh;
  battery_pack_mass_estimate_kg = battery.pack_mass_estimate_kg;
  battery_pack_volume_estimate_l = battery.pack_volume_estimate_l;
  battery_non_pack_reference_mass_kg = battery.non_pack_reference_mass_kg;
  battery_peak_dc_power_kw = battery.peak_dc_power_kw;
  battery_peak_equivalent_c = battery.peak_equivalent_c;
  battery_charge_10_80_energy_kwh = battery.charge_10_80_energy_kwh;
  battery_charge_10min_average_kw = battery.charge_10min_average_kw;
  battery_charge_12min_average_kw = battery.charge_12min_average_kw;
  battery_energy_remaining_kwh = powertrain.soc*battery_capacity_kwh;
  vehicle_mass_kg = powertrain.vehicle_mass_kg;
  // Six mechanism bodies (4 x 5 kg carriers, 2 x 6 kg knuckles) and
  // four 24 kg wheels remain separate native bodies. Never count them twice.
  chassis_mass_kg = vehicle_mass_kg-128.0;
  chassis_com_y = (vehicle_mass_kg*mass_center_y+128.0*0.21)/chassis_mass_kg;
  chassis_com_z = (vehicle_mass_kg*mass_center_z+12.0*1.375)/chassis_mass_kg;
  chassis_inertia_xx = vehicle_inertia_xx-128.0*(0.07^2+1.375^2)-5.6-0.3
    -chassis_mass_kg*((chassis_com_y-mass_center_y)^2+(chassis_com_z-mass_center_z)^2);
  chassis_inertia_yy = vehicle_inertia_yy-128.0*(0.86^2+1.375^2)-3.3844-0.3
    -chassis_mass_kg*(chassis_com_z-mass_center_z)^2;
  chassis_inertia_zz = vehicle_inertia_zz-128.0*(0.86^2+0.07^2)-3.3844-0.3
    -chassis_mass_kg*(chassis_com_y-mass_center_y)^2;
  // A-B06: battery capacity edits add the equivalent box inertia at the
  // reference vehicle COM. The 120 kWh reference is already in dry inertia;
  // add only its mass delta. Source/assumptions: references/battery-study.md.
  // Homogenized gas distribution centered at COM, 1.2 x 0.5 x 1.0 m.
  // Dry-car inertia includes wheels. Actual tank placement remains unknown.
  vehicle_inertia_xx = 3022.0+battery.pack_mass_delta_kg*(battery.pack_height_m^2+battery.pack_length_m^2)/12.0+boost_available*gas_mass_kg*(0.5^2+1.0^2)/12.0;
  vehicle_inertia_yy = 3494.0+battery.pack_mass_delta_kg*(battery.pack_width_m^2+battery.pack_length_m^2)/12.0+boost_available*gas_mass_kg*(1.2^2+1.0^2)/12.0;
  vehicle_inertia_zz = 708.0+battery.pack_mass_delta_kg*(battery.pack_width_m^2+battery.pack_height_m^2)/12.0+boost_available*gas_mass_kg*(1.2^2+0.5^2)/12.0;
  tank_temperature_k = powertrain.tank_temperature_k;
  tank_volume_m3 = powertrain.tank_volume_m3;
  rear_tank_air_kg = powertrain.rear_tank_air_kg;
  cabin_tank_air_kg = powertrain.cabin_tank_air_kg;
  // Each corner has its authored lever arm. Fixed rear-valve trim balances
  // the unequal fore/aft arms; individual commands create real moments.
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
  moment_body_x = thruster_pitch_moment_nm+adhesion.moment_body[1]
    +(mass_center_y-chassis_com_y)*powertrain.force_local_z-(mass_center_z-chassis_com_z)*powertrain.force_local_y
    -powertrain.mass_inflow*boost_available*(0.5^2+1.0^2)/12.0*omega_body[1];
  moment_body_y = thruster_yaw_moment_nm+adhesion.moment_body[2]
    +(mass_center_z-chassis_com_z)*powertrain.force_local_x
    -powertrain.mass_inflow*boost_available*(1.2^2+1.0^2)/12.0*omega_body[2];
  moment_body_z = thruster_roll_moment_nm+adhesion.moment_body[3]
    -(mass_center_y-chassis_com_y)*powertrain.force_local_x
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
  gas_capacity_mass_kg = gas_capacity_kg;
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
