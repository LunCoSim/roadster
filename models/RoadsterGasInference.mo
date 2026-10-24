model RoadsterGasInference
  "Initial-fill calculation using the vehicle's real-gas library"
  parameter Real mass_kg = 250 "Study assumption";
  parameter Real volume_m3 = 0.6 "Reported total volume";
  parameter Real temperature_K = 293.15 "Study assumption";
  Real density_kg_m3;
  Real ideal_pressure_bar;
  Real real_pressure_bar;
equation
  density_kg_m3 = mass_kg / volume_m3;
  ideal_pressure_bar = density_kg_m3 * CompressedAir.R
    * temperature_K / 1e5;
  real_pressure_bar = CompressedAir.pressureFromDensity(
    density_kg_m3, temperature_K) / 1e5;
  annotation(Diagram(coordinateSystem(extent={{-200,-120},{200,120}}),graphics={
    Text(extent={{-190,115},{190,85}},textString="INITIAL TANK PRESSURE",textColor={235,242,248},fontSize=22),
    Text(extent={{-190,75},{190,50}},textString="600 L / 250 kg / 20 °C",textColor={165,185,200},fontSize=18),
    Text(extent={{-190,30},{-10,-5}},textString="REAL GAS",textColor={165,215,250},fontSize=20),
    Text(extent={{10,30},{190,-5}},textString="IDEAL GAS",textColor={240,180,190},fontSize=20),
    Text(extent={{-190,-10},{-10,-60}},textString=DynamicSelect("Run model",String(real_pressure_bar)+" bar"),textColor={235,242,248},fontSize=30),
    Text(extent={{10,-10},{190,-60}},textString=DynamicSelect("Run model",String(ideal_pressure_bar)+" bar"),textColor={235,242,248},fontSize=30),
    Text(extent={{-190,-85},{190,-110}},textString="Assumed fill / calculated absolute pressures",textColor={165,185,200},fontSize=16)
  }),experiment(StartTime=0,StopTime=0.1,Interval=0.1));
end RoadsterGasInference;
