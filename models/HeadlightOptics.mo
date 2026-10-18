model HeadlightOptics
  "Two focused LED study lamps; finite electrical/optical budget"
  parameter Real electrical_power_each(unit="W") = 60;
  parameter Real delivered_efficacy(unit="lm/W") = 50;
  parameter Real outer_angle_degrees = 22;
  parameter Real cone_softness = 0.35;
  input Real enabled;
  Real outer_cosine;
  Real inner_cosine;
  output Real electrical_power(unit="W");
  output Real flux_each_lm(unit="lm");
  output Real effective_solid_angle(unit="sr");
  output Real peak_candela(unit="cd");
  output Real renderer_isotropic_lumens(unit="lm");
equation
  outer_cosine = cos(outer_angle_degrees*3.141592653589793/180.0);
  inner_cosine = cos((1.0-cone_softness)*outer_angle_degrees*3.141592653589793/180.0);
  // The native spotlight uses a squared linear-in-cosine penumbra. Integrate
  // it over the sphere; focus the finite lamp flux into that actual envelope.
  effective_solid_angle = 2.0*3.141592653589793*(1.0-inner_cosine+(inner_cosine-outer_cosine)/3.0);
  electrical_power = 2.0*electrical_power_each*enabled;
  flux_each_lm = electrical_power_each*delivered_efficacy*enabled;
  peak_candela = flux_each_lm/effective_solid_angle;
  // Native SpotLight is an absorbent housing around an isotropic source:
  // its API lumens divide by 4*pi before cone attenuation, not by beam angle.
  renderer_isotropic_lumens = 4.0*3.141592653589793*peak_candela;
end HeadlightOptics;
