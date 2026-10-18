model ThrusterMount
  "Rigid-body wrench from an authored application point: moment = (point - COM) cross force"
  parameter Real point[3](each unit="m") = {0,0,0};
  parameter Real center_of_mass[3](each unit="m") = {0,0,0};
  input Real force[3](each unit="N");
  output Real moment[3](each unit="N.m");
equation
  moment[1] = (point[2]-center_of_mass[2])*force[3]-(point[3]-center_of_mass[3])*force[2];
  moment[2] = (point[3]-center_of_mass[3])*force[1]-(point[1]-center_of_mass[1])*force[3];
  moment[3] = (point[1]-center_of_mass[1])*force[2]-(point[2]-center_of_mass[2])*force[1];
end ThrusterMount;
