model VehicleAerodynamics
  "Body-axis drag and a finite-response active aero/airbrake study envelope"
  parameter Real density(unit="kg/m3") = 1.225;
  parameter Real drag_area_forward(unit="m2") = 0.62;
  parameter Real drag_area_side(unit="m2") = 4.5;
  parameter Real drag_area_vertical(unit="m2") = 8.0;
  parameter Real airbrake_area(unit="m2") = 1.1;
  parameter Real maximum_lift_area(unit="m2") = 7.9;
  parameter Real actuator_tau(unit="s") = 0.2;
  input Real velocity[3];
  input Real quaternion[4] "w,x,y,z";
  input Real throttle;
  input Real brake;
  input Real steer;
  Real body_velocity[3];
  Real drag_body[3];
  Real speed;
  Real requested_deployment;
  Real deployment(start=0.2,fixed=true);
  Real rotation[3,3];
  output Real force_world[3];
  output Real downforce;
  output Real drag_force;
  output Real drag_power;
  output Real wing_deployment;
equation
  rotation[1,1] = 1.0-2.0*(quaternion[3]^2+quaternion[4]^2);
  rotation[1,2] = 2.0*(quaternion[2]*quaternion[3]-quaternion[1]*quaternion[4]);
  rotation[1,3] = 2.0*(quaternion[2]*quaternion[4]+quaternion[1]*quaternion[3]);
  rotation[2,1] = 2.0*(quaternion[2]*quaternion[3]+quaternion[1]*quaternion[4]);
  rotation[2,2] = 1.0-2.0*(quaternion[2]^2+quaternion[4]^2);
  rotation[2,3] = 2.0*(quaternion[3]*quaternion[4]-quaternion[1]*quaternion[2]);
  rotation[3,1] = 2.0*(quaternion[2]*quaternion[4]-quaternion[1]*quaternion[3]);
  rotation[3,2] = 2.0*(quaternion[3]*quaternion[4]+quaternion[1]*quaternion[2]);
  rotation[3,3] = 1.0-2.0*(quaternion[2]^2+quaternion[3]^2);
  for i in 1:3 loop
    body_velocity[i] = sum({rotation[j,i]*velocity[j] for j in 1:3});
    force_world[i] = sum({rotation[i,j]*drag_body[j] for j in 1:3});
  end for;
  speed = sqrt(sum(velocity.^2)+1e-16);
  requested_deployment = max(0.2,max(max(0.0,min(1.0,brake)),
    max(abs(steer),noEvent(if abs(throttle)<0.02 then 0.5 else 0.2))));
  der(deployment) = (requested_deployment-deployment)/actuator_tau;
  wing_deployment = deployment;
  drag_body[1] = -0.5*density*drag_area_side*speed*body_velocity[1];
  drag_body[2] = -0.5*density*drag_area_vertical*speed*body_velocity[2];
  drag_body[3] = -0.5*density*(drag_area_forward+airbrake_area*deployment)*speed*body_velocity[3];
  downforce = 0.5*density*maximum_lift_area*deployment*body_velocity[3]^2;
  drag_force = sqrt(sum(drag_body.^2));
  drag_power = -sum({drag_body[i]*body_velocity[i] for i in 1:3});
end VehicleAerodynamics;
