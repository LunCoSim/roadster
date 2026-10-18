model RoadsterPowertrain
  "Assumed EV force/energy envelope for the October 2026 Roadster study; not a Tesla calibration"
  parameter Real wheel_radius(unit="m") = 0.34;
  parameter Real motor_peak_torque(unit="N.m") = 1400 "Combined two-motor lower-bound study value";
  parameter Real motor_peak_power(unit="W") = 1000000 "Combined two-motor lower-bound study value";
  parameter Real reduction_ratio = 8.4 "Reported planetary ratio, provisional";
  parameter Real reduction_efficiency = 0.97;
  parameter Real efficiency = 0.93;
  parameter Real capacity_kwh = 100;
  parameter Real initial_soc = 0.90;
  parameter Real dry_mass_kg = 1700 "Study mass excluding gas; published target has unspecified trim/fill state";
  parameter Real rho = 1.225;
  parameter Real cd_area(unit="m2") = 0.62;
  parameter Real rolling_coefficient = 0.012;
  parameter Real regen_deceleration(unit="m/s2") = 1.8;
  parameter Real regen_peak_power(unit="W") = 120000;
  parameter Real regen_efficiency = 0.8;
  parameter Real fan_initial_fraction = 0.0;
  parameter Real gas_capacity_kg = 250 "Available starting air mass supplied by user; no volume scaling";
  parameter Real initial_fill = 1.0;
  parameter Real initial_gas_temperature(unit="K") = 293.15;
  parameter Real gas_constant = CompressedAir.R;
  parameter Real initial_gas_mass = gas_capacity_kg*initial_fill;
  parameter Real rear_tank_volume(unit="m3") = 0.2 "S05 rear COPV internal volume";
  parameter Real cabin_tank_volume(unit="m3") = 0.4 "S05 Rocket COPV replacing passenger seat";
  parameter Real tank_volume(unit="m3") = rear_tank_volume+cabin_tank_volume
    "Common-pressure, common-temperature manifold approximation";
  parameter Real initial_pressure = CompressedAir.pressureFromDensity(initial_gas_mass/tank_volume,initial_gas_temperature);
  parameter Real gamma = 1.4;
  parameter Real minimum_discharge_temperature(unit="K") = 200 "Model guard, not a Tesla hardware threshold";
  parameter Real ambient_pressure(unit="Pa") = 101325;
  parameter Real throat_area(unit="m2") = 0.002 "Aggregate open throat area, study assumption";
  parameter Real nozzle_efficiency = 0.85;
  parameter Real refill_max_flow(unit="kg/s") = 20;
  parameter Real refill_heat_limit(unit="W") = 2000000 "External track test facility, not onboard hardware";
  parameter Real valve_tau(unit="s") = 0.025;
  parameter Real boost_available = 0;
  parameter Real lift_available = 0;
  parameter Real lift_trim[4] = {1,1,1,1} "Fixed per-valve geometry gains, independent of flight/keys";
  parameter Real ambient_k = 298.15;
  parameter Real heat_capacity(unit="J/K") = 100000;
  parameter Real cooling_w_k = 300;
  input Real demand;
  input Real steer;
  input Real attitude[4];
  input Real brake;
  input Real boost;
  input Real lift;
  input Real thrust_x;
  input Real thrust_y;
  input Real thrust_z;
  input Real fan;
  input Real headlight_switch;
  input Real refill;
  input Real instant_mass_offset;
  input Real instant_temperature_offset;
  input Real instant_wall_temperature_offset;
  input Real instant_refill_count;
  input Real instant_mechanical_energy_j;
  input Real instant_stored_energy_j;
  input Real refill_target_temperature_k(unit="K");
  input Real lift_individual[4];
  input Real omega_left(unit="rad/s");
  input Real omega_right(unit="rad/s");
  input Real velocity_x(unit="m/s");
  input Real velocity_z(unit="m/s");
  input Real velocity_y(unit="m/s");
  input Real velocity_forward(unit="m/s");
  input Real omega_body[3](each unit="rad/s");
  input Real surface_gap[4];
  input Real surface_valid[4];
  input Real surface_alignment[4];
  input Real body_up_y;
  input Real ground_gap(unit="m");
  input Real ground_valid;
  SuctionFan suction(command=fan,enabled=enabled,ambient_pressure=ambient_pressure,initial_speed_fraction=fan_initial_fraction,
    air_density=rho,gap=surface_gap,valid=surface_valid,alignment=surface_alignment);
  JetExpansion rear_nozzle(gamma=gamma,gas_constant=gas_constant,throat_area=throat_area,
    nozzle_count=4,nozzle_efficiency=nozzle_efficiency,tank_pressure=tank_pressure_pa,
    tank_temperature=gas_temperature,ambient_pressure=ambient_pressure);
  JetExpansion side_nozzle(gamma=gamma,gas_constant=gas_constant,throat_area=0.04*throat_area,
    nozzle_count=1,nozzle_efficiency=nozzle_efficiency,tank_pressure=tank_pressure_pa,
    tank_temperature=gas_temperature,ambient_pressure=ambient_pressure);
  VehicleAerodynamics aero(density=rho,drag_area_forward=cd_area,
    velocity={velocity_x,velocity_y,velocity_z},quaternion=attitude,throttle=demand,brake=brake,steer=steer);
  TankHeatTransfer tank_heat(gas_temperature=gas_temperature,initial_wall_temperature=initial_gas_temperature,
    temperature_offset=instant_wall_temperature_offset);
  HeadlightOptics headlights(enabled=enabled*max(0.0,min(1.0,headlight_switch)));
  CompressedAir.State target_air(density=gas_capacity_kg/tank_volume,temperature=refill_target_temperature_k);
  CompressedAir.State air(density=gas_density,temperature=gas_temperature);
  Real energy_j(start=initial_soc*capacity_kwh*3600000, fixed=true);
  Real net_air_ledger(start=initial_gas_mass, fixed=true);
  Real gas_mass;
  Real valve_x(start=0,fixed=true);
  Real valve_y;
  Real valve_lift[4](each start=0,each fixed=true);
  Real valve_z(start=0,fixed=true);
  Real motor_temperature(start=ambient_k, fixed=true);
  Real enabled;
  Real service_gate;
  Real actuator_enabled;
  Real mass_inflow;
  Real service_heat;
  Real fill_compression_heat;
  Real inlet_kinetic_heat;
  output Real inlet_force[3](each unit="N");
  Real external_air_used(start=0,fixed=true);
  Real external_service_energy(start=0,fixed=true);
  output Real next_mass_offset;
  output Real next_temperature_offset;
  output Real next_wall_temperature_offset;
  output Real next_refill_count;
  output Real next_mechanical_energy_j;
  output Real next_stored_energy_j;
  output Real air_fill_percent;
  output Real refill_allowed;
  output Real refill_active;
  output Real refill_complete;
  output Real refill_flow_kg_s;
  output Real service_power_w;
  output Real service_air_used_kg;
  output Real service_energy_j;
  Real command;
  Real mean_omega;
  Real torque_limit;
  Real slip_left;
  Real slip_right;
  Real traction_left;
  Real traction_right;
  Real mechanical_power;
  Real regeneration_gate;
  Real regen_torque_left;
  Real regen_torque_right;
  Real drive_power;
  Real recovered_power;
  Real fan_command;
  Real forward_force;
  Real vertical_force;
  Real side_force;
  Real temperature_ledger(start=initial_gas_temperature,fixed=true);
  Real gas_temperature;
  Real gas_density;
  Real raw_pressure;
  Real pressure_temperature_derivative;
  Real gas_cv;
  Real discharge_enabled;
  Real residual_mass;
  Real pressure_ratio;
  Real critical_ratio;
  Real mass_flux;
  Real mass_flow;
  Real exhaust_speed;
  Real vector_norm;
  Real valve_fraction;
  Real force_magnitude;
  Real free_stream_speed;
  Real seal_fraction;
  output Real full_area_force;
  output Real torque_left(unit="N.m");
  output Real torque_right(unit="N.m");
  output Real freewheel_torque(unit="N.m");
  output Real force_local_z(unit="N");
  output Real force_local_y(unit="N");
  output Real force_local_x(unit="N");
  output Real force_x(unit="N");
  output Real force_y(unit="N");
  output Real force_z(unit="N");
  output Real gas_mass_kg(unit="kg");
  output Real tank_pressure_pa(unit="Pa");
  output Real jet_force_x(unit="N");
  output Real jet_force_y(unit="N");
  output Real jet_force_z(unit="N");
  output Real forward_speed(unit="m/s");
  output Real battery_power(unit="W");
  output Real soc;
  output Real temperature_k(unit="K");
  output Real impulse_remaining(unit="N.s");
  output Real thruster_force(unit="N");
  output Real corner_lift[4](each unit="N");
  output Real recovered_power_w(unit="W");
  output Real downforce(unit="N");
  output Real vehicle_mass_kg(unit="kg");
  output Real tank_temperature_k(unit="K");
  output Real rear_tank_air_kg(unit="kg");
  output Real cabin_tank_air_kg(unit="kg");
  output Real tank_volume_m3(unit="m3");
equation
  // Explicit GAME service boundary jumps, prescribed through ordinary inputs.
  // Between services the ledgers integrate the physical mass/energy equations.
  // The replacement is co-moving/co-rotating, so native velocity is preserved;
  // the external facility supplies its momentum and kinetic energy.
  gas_mass = net_air_ledger+instant_mass_offset;
  gas_temperature = temperature_ledger+instant_temperature_offset;
  next_mass_offset = instant_mass_offset+gas_capacity_kg-gas_mass;
  next_temperature_offset = instant_temperature_offset+refill_target_temperature_k-gas_temperature;
  next_wall_temperature_offset = instant_wall_temperature_offset+refill_target_temperature_k-tank_heat.wall_temperature;
  next_refill_count = instant_refill_count+1.0;
  next_mechanical_energy_j = instant_mechanical_energy_j+0.5*(gas_capacity_kg-gas_mass)
    *(free_stream_speed^2+(0.5^2+1.0^2)/12.0*omega_body[1]^2
      +(1.2^2+1.0^2)/12.0*omega_body[2]^2+(1.2^2+0.5^2)/12.0*omega_body[3]^2);
  next_stored_energy_j = instant_stored_energy_j+gas_capacity_kg*target_air.specific_internal_energy
    -gas_mass*air.specific_internal_energy
    +tank_heat.wall_heat_capacity*(refill_target_temperature_k-tank_heat.wall_temperature)
    +next_mechanical_energy_j-instant_mechanical_energy_j;
  soc = max(0.0, min(1.0, energy_j/(capacity_kwh*3600000)));
  enabled = noEvent(if soc > 0.02 then 1.0 else 0.0);
  // External TEST facility: 20 kg/s conditioned air, finite 2 MW thermal
  // jacket, compressor eta=0.7. This is not an onboard Tesla compressor.
  refill_allowed = noEvent(if refill_target_temperature_k>=253.15 and refill_target_temperature_k<=333.15 then 1.0 else 0.0);
  refill_complete = noEvent(if gas_mass>=gas_capacity_kg-0.005 and abs(gas_temperature-refill_target_temperature_k)<0.01 then 1.0 else 0.0);
  service_gate = max(0.0,min(1.0,refill))*refill_allowed;
  refill_active = service_gate*(1.0-refill_complete);
  actuator_enabled = enabled;
  mass_inflow = service_gate*min(refill_max_flow,max(0.0,(gas_capacity_kg-gas_mass)/0.2));
  // Same-state incoming enthalpy. External aftercooling removes the inflow
  // compression term; a bounded jacket restores the reference temperature.
  fill_compression_heat = mass_inflow*gas_temperature*pressure_temperature_derivative/gas_density;
  // Drive-through TEST supply: incoming air starts at rest in world coordinates
  // and enters at the centered tank COM. Momentum loading is a real force,
  // with relative kinetic energy converted to heat and removed by aftercooling.
  inlet_force = -mass_inflow*{velocity_x,velocity_y,velocity_z};
  inlet_kinetic_heat = 0.5*mass_inflow*(free_stream_speed^2
    +(0.5^2+1.0^2)/12.0*omega_body[1]^2
    +(1.2^2+1.0^2)/12.0*omega_body[2]^2
    +(1.2^2+0.5^2)/12.0*omega_body[3]^2);
  // Feed forward measured wall exchange so the finite jacket has no steady
  // temperature offset. All compensation remains an accounted external heat flow.
  service_heat = service_gate*max(-refill_heat_limit,min(refill_heat_limit,100000.0*(refill_target_temperature_k-gas_temperature)-tank_heat.heat_to_gas));
  refill_flow_kg_s = mass_inflow;
  air_fill_percent = 100.0*gas_mass_kg/gas_capacity_kg;
  service_power_w = mass_inflow*gas_constant*refill_target_temperature_k*log(max(1.0,tank_pressure_pa/ambient_pressure))/0.7
    +abs(fill_compression_heat)+abs(service_heat)+inlet_kinetic_heat;
  der(external_air_used) = mass_inflow;
  der(external_service_energy) = service_power_w;
  service_air_used_kg = external_air_used;
  service_energy_j = external_service_energy;
  command = max(-1.0, min(1.0, demand)) * (1.0-max(0.0,min(1.0,brake))) * actuator_enabled;
  mean_omega = 0.5*(abs(omega_left)+abs(omega_right));
  torque_limit = motor_peak_torque*reduction_ratio*reduction_efficiency;
  // Slip feedback limits runaway axle spin; wheel rotation remains the native
  // contact/shaft solution. 0.12 is an uncalibrated road-tire slip target.
  slip_left = (omega_left*wheel_radius-forward_speed)/max(2.0,abs(forward_speed));
  slip_right = (omega_right*wheel_radius-forward_speed)/max(2.0,abs(forward_speed));
  traction_left = 1.0/(1.0+30.0*max(0.0,command*slip_left-0.12));
  traction_right = 1.0/(1.0+30.0*max(0.0,command*slip_right-0.12));
  torque_left = regen_torque_left+0.5*command*traction_left*min(torque_limit,motor_peak_power*reduction_efficiency/max(1.0,abs(omega_left)));
  torque_right = regen_torque_right+0.5*command*traction_right*min(torque_limit,motor_peak_power*reduction_efficiency/max(1.0,abs(omega_right)));
  freewheel_torque = 0.0;
  // One-pedal regenerative braking is separate from aerodynamic and rolling
  // losses. It acts through the native wheel shafts and recovers electrical
  // energy; no scripted velocity clamp or hidden wheel brake is used.
  regeneration_gate = noEvent(if abs(command)<0.02 and boost+thrust_z<0.01 then 1.0 else 0.0)
    *max(0.0,min(1.0,ground_valid))*enabled*max(0.0,min(1.0,(0.98-soc)/0.01))*(1.0-max(0.0,min(1.0,brake)));
  regen_torque_left = -regeneration_gate*tanh(omega_left*wheel_radius/0.5)
    *min(0.5*vehicle_mass_kg*regen_deceleration*wheel_radius,0.5*regen_peak_power/max(1.0,abs(omega_left)));
  regen_torque_right = -regeneration_gate*tanh(omega_right*wheel_radius/0.5)
    *min(0.5*vehicle_mass_kg*regen_deceleration*wheel_radius,0.5*regen_peak_power/max(1.0,abs(omega_right)));
  mechanical_power = torque_left*omega_left+torque_right*omega_right;
  drive_power = max(0.0,mechanical_power);
  recovered_power = max(0.0,-mechanical_power)*regen_efficiency;
  recovered_power_w = recovered_power;
  seal_fraction = max(0.0,min(1.0,ground_valid))*exp(-(max(0.0,ground_gap)/0.35)^4);
  fan_command = max(0.0,min(1.0,fan))*enabled;
  downforce = suction.suction_force;
  // Rear forward jets, four downward lift jets, two front side/yaw jets.
  // Side jets have 4% of aggregate throat area (study assumption).
  // K opens all lift jets; I/P/comma/period select corners. Space opens rear jets.
  der(valve_x) = (0.04*lift_available*max(-1.0,min(1.0,thrust_x))*actuator_enabled-valve_x)/valve_tau;
  for i in 1:4 loop
    der(valve_lift[i]) = (0.25*lift_available*lift_trim[i]*max(0.0,min(1.0,lift+thrust_y+lift_individual[i]))*actuator_enabled-valve_lift[i])/valve_tau;
    corner_lift[i] = force_magnitude*valve_lift[i]/max(1e-8,vector_norm);
  end for;
  valve_y = sum(valve_lift);
  der(valve_z) = (boost_available*max(0.0,min(1.0,boost+thrust_z))*actuator_enabled-valve_z)/valve_tau;
  vector_norm = abs(valve_x)+valve_y+valve_z;
  valve_fraction = min(1.0,vector_norm);
  gas_mass_kg = max(0.000001,gas_mass);
  vehicle_mass_kg = dry_mass_kg+boost_available*gas_mass_kg;
  tank_temperature_k = gas_temperature;
  tank_volume_m3 = tank_volume;
  // At the assumed shared rho/T, masses partition by internal volume.
  rear_tank_air_kg = gas_mass_kg*rear_tank_volume/tank_volume;
  cabin_tank_air_kg = gas_mass_kg*cabin_tank_volume/tank_volume;
  gas_density = gas_mass_kg/tank_volume;
  raw_pressure = air.pressure;
  pressure_temperature_derivative = air.dpdT;
  gas_cv = air.cv;
  tank_pressure_pa = max(ambient_pressure,raw_pressure);
  // Fixed-volume adiabatic open-system energy balance with real-gas cv and
  // (dp/dT)_rho. The nozzle remains an ideal-expansion engineering closure.
  discharge_enabled = noEvent(if gas_temperature > minimum_discharge_temperature and raw_pressure > ambient_pressure then 1.0 else 0.0);
  der(temperature_ledger) = ((mass_inflow-mass_flow)*gas_temperature*pressure_temperature_derivative/gas_density
    -fill_compression_heat+service_heat+tank_heat.heat_to_gas)/(gas_mass_kg*max(1.0,gas_cv));
  residual_mass = tank_volume*ambient_pressure/(gas_constant*gas_temperature);
  pressure_ratio = min(1.0,ambient_pressure/tank_pressure_pa);
  critical_ratio = (2.0/(gamma+1.0))^(gamma/(gamma-1.0));
  mass_flux = noEvent(if pressure_ratio <= critical_ratio then
      tank_pressure_pa*sqrt(gamma/(gas_constant*gas_temperature))*(2.0/(gamma+1.0))^((gamma+1.0)/(2.0*(gamma-1.0)))
    else tank_pressure_pa*sqrt(max(0.0,2.0*gamma/(gas_constant*gas_temperature*(gamma-1.0))*(pressure_ratio^(2.0/gamma)-pressure_ratio^((gamma+1.0)/gamma)))));
  mass_flow = throat_area*mass_flux*valve_fraction*discharge_enabled;
  der(net_air_ledger) = mass_inflow-mass_flow;
  exhaust_speed = rear_nozzle.exit_velocity;
  full_area_force = max(0.0,throat_area*mass_flux*rear_nozzle.exit_velocity
    +(rear_nozzle.exit_pressure-ambient_pressure)*rear_nozzle.exit_area)*discharge_enabled;
  force_magnitude = max(0.0,mass_flow*exhaust_speed
    +(rear_nozzle.exit_pressure-ambient_pressure)*rear_nozzle.exit_area*valve_fraction*discharge_enabled);
  side_force = force_magnitude*valve_x/max(1e-8,vector_norm);
  vertical_force = force_magnitude*valve_y/max(1e-8,vector_norm);
  forward_force = force_magnitude*valve_z/max(1e-8,vector_norm);
  jet_force_x = side_force;
  jet_force_y = vertical_force;
  jet_force_z = -forward_force;
  impulse_remaining = max(0.0,gas_mass-residual_mass)*exhaust_speed;
  thruster_force = forward_force;
  forward_speed = velocity_forward;
  // Inertial drag opposes the complete measured velocity, including flight.
  // Isotropic CdA is a study approximation; no CFD attitude map is available.
  free_stream_speed = sqrt(velocity_x*velocity_x+velocity_y*velocity_y+velocity_z*velocity_z+1e-16);
  force_x = aero.force_world[1]+inlet_force[1];
  force_y = aero.force_world[2]+inlet_force[2];
  force_z = aero.force_world[3]+inlet_force[3];
  force_local_z = rolling_coefficient*(vehicle_mass_kg*9.80665*abs(body_up_y)+downforce+aero.downforce)*tanh(forward_speed/0.5)*seal_fraction-forward_force;
  force_local_y = vertical_force-downforce-aero.downforce;
  force_local_x = side_force;
  battery_power = drive_power/efficiency-recovered_power+800.0*enabled+headlights.electrical_power+suction.electrical_power;
  der(energy_j) = -battery_power;
  der(motor_temperature) = (drive_power*(1.0/efficiency-1.0)+max(0.0,-mechanical_power)*(1.0-regen_efficiency)
    -cooling_w_k*(motor_temperature-ambient_k))/heat_capacity;
  temperature_k = motor_temperature;
  annotation(experiment(StartTime=0,StopTime=10,Interval=0.01,Tolerance=1e-6));
end RoadsterPowertrain;
