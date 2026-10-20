model ConstantShaftTorque
  "Isolated diagnostic shaft input; equal requests, no traction or tire law"
  input Real torque(unit="N.m") = 0;
  output Real shaft_torque(unit="N.m");
equation
  shaft_torque = torque;
end ConstantShaftTorque;
