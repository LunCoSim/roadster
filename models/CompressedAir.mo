package CompressedAir
  "Reusable dry-air storage calculations using Lemmon et al. (2000) Helmholtz EOS"
  // Coefficients: CoolProp 8.0.0 Air.json, Lemmon-JPCRD-2000.
  // DOI 10.1063/1.1285884. See references/gas-storage.md and LICENSES/CoolProp.txt.
  // Single-phase study domain: 200..350 K, 0.1..70 MPa. SI absolute pressure.
  constant Real R = 8.31451/0.02896546;
  constant Real reducingDensity = 10447.7*0.02896546;
  constant Real reducingTemperature = 132.6312;

  constant Real n[19] = {0.118160747229,0.713116392079,-1.61824192067,0.0714140178971,-0.0865421396646,0.134211176704,0.0112626704218,-0.0420533228842,0.0349008431982,0.000164957183186,-0.101365037912,-0.17381369097,-0.0472103183731,-0.0122523554253,-0.146629609713,-0.0316055879821,0.000233594806142,0.0148287891978,-0.00938782884667};
  constant Real d[19] = {1,1,1,2,3,3,4,4,4,6,1,3,5,6,1,3,11,1,3};
  constant Real t[19] = {0,0.33,1.01,0,0,0.15,0,0.2,0.35,1.35,1.6,0.8,0.95,1.25,3.6,6,3.25,3.5,15};
  constant Integer l[19] = {0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,3};
  constant Real n0[6] = {6.057194e-8,-2.10274769e-5,-0.000158860716,-13.841928076,17.275266575,-0.00019536342};
  constant Real t0[6] = {-3,-2,-1,0,1,1.5};

  function properties
    input Real density(unit="kg/m3");
    input Real temperature(unit="K");
    output Real pressure(unit="Pa");
    output Real dpdT(unit="Pa/K");
    output Real cv(unit="J/(kg.K)");
  protected
    Real delta;
    Real tau;
    Real term;
    Real derivative;
    Real arD;
    Real arDT;
    Real arTT;
    Real cv0;
    Real x;
  algorithm
    delta := density/reducingDensity;
    tau := reducingTemperature/temperature;
    arD := 0;
    arDT := 0;
    arTT := 0;
    term := 0;
    derivative := 0;
    cv0 := 0;
    x := 0;
    for i in 1:19 loop
      term := n[i]*delta^d[i]*tau^t[i];
      if l[i] > 0 then
        term := term*exp(-delta^l[i]);
        derivative := term*(d[i]/delta-l[i]*delta^(l[i]-1));
      else
        derivative := term*d[i]/delta;
      end if;
      arD := arD+derivative;
      arDT := arDT+derivative*t[i]/tau;
      arTT := arTT+term*t[i]*(t[i]-1)/(tau*tau);
    end for;
    cv0 := 2.490888032;
    for i in 1:6 loop
      cv0 := cv0-n0[i]*t0[i]*(t0[i]-1)*tau^t0[i];
    end for;
    x := 25.36365*tau;
    cv0 := cv0+0.791309509*x*x*exp(-x)/(1-exp(-x))^2;
    x := 16.90741*tau;
    cv0 := cv0+0.212236768*x*x*exp(-x)/(1-exp(-x))^2;
    x := 87.31279*tau;
    cv0 := cv0+0.197938904*x*x*(2.0/3.0)*exp(-x)/(1+(2.0/3.0)*exp(-x))^2;
    pressure := density*R*temperature*(1+delta*arD);
    dpdT := density*R*(1+delta*arD-delta*tau*arDT);
    cv := R*(cv0-tau*tau*arTT);
  end properties;

  function pressureFromDensity
    input Real density(unit="kg/m3");
    input Real temperature(unit="K");
    output Real pressure(unit="Pa");
  protected
    Real dpdT;
    Real cv;
  algorithm
    (pressure,dpdT,cv) := properties(density,temperature);
  end pressureFromDensity;

  function densityFromPressure
    "Monotone single-phase gas inversion in the declared domain"
    input Real pressure(unit="Pa");
    input Real temperature(unit="K");
    output Real density(unit="kg/m3");
  protected
    Real low;
    Real high;
    Real middle;
  algorithm
    low := 0.000001;
    high := 1000;
    middle := 0;
    for i in 1:50 loop
      middle := 0.5*(low+high);
      if pressureFromDensity(middle,temperature) > pressure then
        high := middle;
      else
        low := middle;
      end if;
    end for;
    density := 0.5*(low+high);
  end densityFromPressure;

  model State
    "Equation-form EOS for realtime solvers; same coefficients as properties"
    input Real density(unit="kg/m3");
    input Real temperature(unit="K");
    output Real pressure(unit="Pa");
    output Real dpdT(unit="Pa/K");
    output Real cv(unit="J/(kg.K)");
    Real delta;
    Real tau;
    Real term[19];
    Real derivative[19];
    Real temperatureDerivative[19];
    Real curvature[19];
    Real idealTerms[6];
    Real arD;
    Real arDT;
    Real arTT;
    Real cv0;
    Real x1;
    Real x2;
    Real x3;
  equation
    delta = density/reducingDensity;
    tau = reducingTemperature/temperature;
    for i in 1:19 loop
      term[i] = n[i]*delta^d[i]*tau^t[i]*(if l[i] > 0 then exp(-delta^l[i]) else 1);
      derivative[i] = term[i]*(d[i]/delta-(if l[i] > 0 then l[i]*delta^(l[i]-1) else 0));
      temperatureDerivative[i] = derivative[i]*t[i]/tau;
      curvature[i] = term[i]*t[i]*(t[i]-1)/(tau*tau);
    end for;
    for i in 1:6 loop
      idealTerms[i] = -n0[i]*t0[i]*(t0[i]-1)*tau^t0[i];
    end for;
    arD = sum(derivative);
    arDT = sum(temperatureDerivative);
    arTT = sum(curvature);
    x1 = 25.36365*tau;
    x2 = 16.90741*tau;
    x3 = 87.31279*tau;
    cv0 = 2.490888032+sum(idealTerms)
      +0.791309509*x1*x1*exp(-x1)/(1-exp(-x1))^2
      +0.212236768*x2*x2*exp(-x2)/(1-exp(-x2))^2
      +0.197938904*x3*x3*(2.0/3.0)*exp(-x3)/(1+(2.0/3.0)*exp(-x3))^2;
    pressure = density*R*temperature*(1+delta*arD);
    dpdT = density*R*(1+delta*arD-delta*tau*arDT);
    cv = R*(cv0-tau*tau*arTT);
  end State;

  model StorageSizing
    "Use prescribed volume to solve pressure, or prescribed pressure to size volume"
    parameter Real availableMass(unit="kg") = 250;
    parameter Real temperature(unit="K") = 293.15;
    parameter Real volume(unit="m3") = 0.6;
    parameter Real designPressure(unit="Pa") = 43702345.09974838;
    output Real density(unit="kg/m3");
    output Real pressure(unit="Pa");
    output Real requiredVolume(unit="m3");
    output Real idealPressure(unit="Pa");
    output Real compressibility;
    output Real dpdT(unit="Pa/K");
    output Real cv(unit="J/(kg.K)");
  equation
    density = availableMass/volume;
    (pressure,dpdT,cv) = properties(density,temperature);
    requiredVolume = availableMass/densityFromPressure(designPressure,temperature);
    idealPressure = density*R*temperature;
    compressibility = pressure/idealPressure;
  end StorageSizing;
end CompressedAir;
