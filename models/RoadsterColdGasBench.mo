model RoadsterColdGasBench
  "Two rear-jet pulses on the existing gas plant; stationary bench, not a driving trial"
  parameter Real initial_air_mass_kg(unit="kg") = 250 "Chosen study fill, not a published Tesla inventory";
  parameter Real initial_temperature_k(unit="K") = 293.15;
  parameter Real first_pulse_start_s(unit="s") = 0.5;
  parameter Real pulse_duration_s(unit="s") = 1.0;
  parameter Real second_pulse_start_s(unit="s") = 3.0;
  input Real discharge_cutoff_c(unit="degC",min=-130,max=20) = -130;
  output Real rear_request "Normalized rear-valve request";
  output Real valve_opening "Actual modeled rear-valve response";
  output Real air_mass_kg(unit="kg");
  output Real tank_temperature_k(unit="K");
  output Real tank_temperature_c(unit="degC");
  output Real thermal_guard_temperature_c(unit="degC");
  output Real tank_pressure_bar(unit="bar");
  output Real mass_flow_kg_s(unit="kg/s");
  output Real rear_thrust_kn(unit="kN");
  output Real guard_active "The adjustable study guard; not a hardware specification";

  // This is the same plant used by RoadsterVehicle. The bench holds mechanical
  // observations at rest; it does not integrate or prescribe vehicle motion.
  RoadsterPowertrain gas_system(
    gas_capacity_kg=initial_air_mass_kg, initial_gas_temperature=initial_temperature_k,
    boost_available=1, lift_available=1,
    minimum_discharge_temperature=discharge_cutoff_c+273.15,
    demand=0, steer=0, attitude={1,0,0,0}, brake=0, boost=0, lift=0,
    thrust_x=0, thrust_y=0, thrust_z=rear_request,
    adhesion_force_body={0,0,0}, adhesion_power_w=0, headlight_switch=0,
    refill=0, unlimited_air=0,
    instant_mass_offset=0, instant_temperature_offset=0, instant_wall_temperature_offset=0,
    instant_refill_count=0, instant_mechanical_energy_j=0, instant_stored_energy_j=0,
    refill_target_temperature_k=initial_temperature_k, lift_individual={0,0,0,0},
    omega_left=0, omega_right=0, velocity_x=0, velocity_y=0, velocity_z=0,
    velocity_forward=0, omega_body={0,0,0}, body_up_y=1, ground_gap=0.34, ground_valid=1)
    annotation(Placement(transformation(extent={{-440,-130},{-80,130}})));

  record PlotNode
    Real extent[2,2];
    String signal;
    String title;
  end PlotNode;
equation
  rear_request = if (time>=first_pulse_start_s and time<first_pulse_start_s+pulse_duration_s)
    or (time>=second_pulse_start_s and time<second_pulse_start_s+pulse_duration_s) then 1 else 0;
  valve_opening = gas_system.valve_z;
  air_mass_kg = gas_system.gas_mass_kg;
  tank_temperature_k = gas_system.tank_temperature_k;
  tank_temperature_c = gas_system.tank_temperature_c;
  thermal_guard_temperature_c = gas_system.minimum_discharge_temperature-273.15;
  tank_pressure_bar = gas_system.tank_pressure_pa/100000;
  mass_flow_kg_s = gas_system.mass_flow;
  rear_thrust_kn = -gas_system.jet_force_z/1000;
  guard_active = if gas_system.discharge_enabled<0.5 then 1 else 0;
  annotation(
    Diagram(coordinateSystem(extent={{-470,-220},{470,220}}),graphics={
      Text(extent={{-440,205},{440,170}},textString="TWO-PULSE GAS BENCH",textColor={230,238,244}),
      Text(extent={{-440,158},{440,135}},textString="Same Roadster gas plant / fixed mechanical observations / no refill",textColor={158,179,191})
    }),
    __LunCo(plotNodes={
      PlotNode(extent={{-40,120},{200,10}},signal="tank_temperature_c",title="Tank temperature [°C]"),
      PlotNode(extent={{220,120},{460,10}},signal="air_mass_kg",title="Air remaining [kg]"),
      PlotNode(extent={{-40,-20},{200,-130}},signal="rear_thrust_kn",title="Rear thrust [kN]"),
      PlotNode(extent={{220,-20},{460,-130}},signal="valve_opening",title="Rear valve opening [0–1]")
    }),
    experiment(StartTime=0,StopTime=5,Interval=0.01,Tolerance=1e-6));
end RoadsterColdGasBench;
