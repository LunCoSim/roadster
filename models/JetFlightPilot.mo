model JetFlightPilot
  "Optional jet-flight feedback: requests existing valves, never forces or body state"
  input Real position[3];
  input Real velocity[3];
  input Real attitude[4] "Body-to-world quaternion w,x,y,z";
  input Real omega[3] "Body angular velocity rad/s";
  input Real target[3];
  input Real target_yaw "Heading about world Y; zero faces -Z";
  input Real mass;
  input Real inertia[3];
  input Real full_lift_force;
  input Real full_side_force;
  input Real rear_trim;
  input Real front_z;
  input Real rear_z;
  input Real lift_x;
  input Real side_y;
  input Real side_z;
  input Real center_y;
  input Real center_z;
  output Real collective;
  output Real side;
  output Real corner[4] "Offsets FL,RL,FR,RR on the existing trimmed valves";
  output Real altitude_error;
protected
  Real acceleration[3];
  Real body_acceleration_x;
  Real body_acceleration_z;
  Real pitch;
  Real roll;
  Real cp; Real sp; Real cr; Real sr; Real cy; Real sy;
  Real target_q[4];
  Real error_q[4];
  Real error_length;
  Real error_scale;
  Real moment[3];
  Real front_force;
  Real pitch_trim;
  Real roll_trim;
  Real up_y;
equation
  // Position and velocity feedback are control requests, not trajectory constraints.
  // Limits keep the vehicle's lift vector within a 20-degree study envelope.
  acceleration[1] = max(-3.5,min(3.5,0.18*(target[1]-position[1])-0.95*velocity[1]));
  acceleration[2] = max(-6.0,min(8.0,1.8*(target[2]-position[2])-2.8*velocity[2]));
  acceleration[3] = max(-3.5,min(3.5,0.18*(target[3]-position[3])-0.95*velocity[3]));
  altitude_error = target[2]-position[2];
  body_acceleration_x = cos(target_yaw)*acceleration[1]-sin(target_yaw)*acceleration[3];
  body_acceleration_z = sin(target_yaw)*acceleration[1]+cos(target_yaw)*acceleration[3];
  pitch = max(-0.35,min(0.35,atan2(body_acceleration_z,9.80665+acceleration[2])));
  roll = max(-0.35,min(0.35,-atan2(body_acceleration_x,9.80665+acceleration[2])));
  cp=cos(pitch/2); sp=sin(pitch/2); cr=cos(roll/2); sr=sin(roll/2);
  cy=cos(target_yaw/2); sy=sin(target_yaw/2);
  // q_target = yaw(Y) * pitch(X) * roll(Z).
  target_q = {cy*cp*cr+sy*sp*sr, cy*sp*cr+sy*cp*sr,
    sy*cp*cr-cy*sp*sr, cy*cp*sr-sy*sp*cr};
  // conjugate(q_body) * q_target: shortest attitude error in body axes.
  error_q = {sum(attitude.*target_q),
    attitude[1]*target_q[2]-attitude[2]*target_q[1]-attitude[3]*target_q[4]+attitude[4]*target_q[3],
    attitude[1]*target_q[3]+attitude[2]*target_q[4]-attitude[3]*target_q[1]-attitude[4]*target_q[2],
    attitude[1]*target_q[4]-attitude[2]*target_q[3]+attitude[3]*target_q[2]-attitude[4]*target_q[1]};
  error_length=sqrt(error_q[2]^2+error_q[3]^2+error_q[4]^2);
  error_scale=noEvent((if error_q[1]>=0 then 1.0 else -1.0)
    *2*atan2(error_length,abs(error_q[1]))/max(1e-9,error_length));
  for i in 1:3 loop
    moment[i]=inertia[i]*(8.0*error_scale*error_q[i+1]-4.0*omega[i]);
  end for;
  up_y=1-2*(attitude[2]^2+attitude[4]^2);
  collective=max(0.0,min(0.8,mass*(9.80665+acceleration[2])
    /max(1.0,full_lift_force*max(0.4,up_y))));
  side=max(-1.0,min(1.0,moment[2]/min(-1.0,(side_z-center_z)*full_side_force)));
  front_force=full_lift_force/max(0.01,2*(1+rear_trim));
  pitch_trim=max(-0.18,min(0.18,moment[1]/max(1.0,2*front_force*(rear_z-front_z))));
  // Counter the actual side nozzle's vertical arm; retain all valve limits.
  roll_trim=max(-0.18,min(0.18,(moment[3]+(side_y-center_y)*full_side_force*side)
    /max(1.0,4*lift_x*front_force)));
  corner={pitch_trim-roll_trim,(-pitch_trim-roll_trim)/max(0.05,rear_trim),
    pitch_trim+roll_trim,(-pitch_trim+roll_trim)/max(0.05,rear_trim)};
end JetFlightPilot;
