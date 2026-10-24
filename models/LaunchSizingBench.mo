model LaunchSizingBench
  "Expose the vehicle's first-order sizing model for inspecting its force budget"
  parameter Real initial_mass_kg(unit="kg") = 1950 "1700 kg dry mass plus 250 kg initial gas: study assumption";
  extends LaunchSizing(initial_mass=initial_mass_kg);
  output Real target_speed_mph = target_speed/0.44704;
  output Real target_time_s(unit="s") = target_time;
  annotation(
    Diagram(coordinateSystem(extent={{-300,-140},{300,140}}),graphics={
      Rectangle(extent={{-300,140},{300,-140}},radius=8,
        lineColor={84,103,117},fillColor={9,15,21},fillPattern=FillPattern.Solid),
      Text(extent={{-280,130},{280,105}},textString="FROM ACCELERATION TO FORCE",textColor={230,238,244}),
      Rectangle(extent={{-280,85},{-110,-88}},radius=10,
        lineColor={121,224,233},fillColor={15,26,34},fillPattern=FillPattern.Solid),
      Text(extent={{-272,77},{-118,57}},textString="TARGET + MASS",textColor={158,179,191}),
      Text(extent={{-272,48},{-118,22}},
        textString=DynamicSelect("Speed and time target",String(target_speed_mph)+" mph in "+String(target_time_s)+" s"),textColor={230,238,244}),
      Text(extent={{-272,7},{-118,-19}},
        textString=DynamicSelect("Initial mass",String(initial_mass)+" kg"),textColor={230,238,244}),
      Text(extent={{-272,-49},{-118,-69}},textString="Initial mass assumed",textColor={158,179,191}),
      Line(points={{-110,0},{-88,0}},color={121,224,233},thickness=1.5,
        arrow={Arrow.None,Arrow.Filled}),
      Rectangle(extent={{-88,85},{88,-88}},radius=10,
        lineColor={121,224,233},fillColor={15,26,34},fillPattern=FillPattern.Solid),
      Text(extent={{-80,77},{80,57}},textString="MEAN NET FORCE",textColor={158,179,191}),
      Text(extent={{-80,45},{80,12}},
        textString=DynamicSelect("Required force",String(required_mean_net_force/1000)+" kN"),textColor={121,224,233}),
      Text(extent={{-80,-4},{80,-28}},textString="F = mass × acceleration",textColor={230,238,244}),
      Text(extent={{-80,-49},{80,-69}},textString="a = speed / time",textColor={158,179,191}),
      Line(points={{88,0},{110,0}},color={121,224,233},thickness=1.5,
        arrow={Arrow.None,Arrow.Filled}),
      Rectangle(extent={{110,85},{280,-88}},radius=10,
        lineColor={121,224,233},fillColor={15,26,34},fillPattern=FillPattern.Solid),
      Text(extent={{118,77},{272,57}},textString="WHEELS + JETS",textColor={158,179,191}),
      Text(extent={{118,42},{272,20}},textString="Wheel force",textColor={230,238,244}),
      Text(extent={{118,12},{272,-10}},textString="depends on grip",textColor={230,238,244}),
      Text(extent={{118,-35},{272,-57}},textString="Jets supply the balance",textColor={121,224,233}),
      Text(extent={{-280,-106},{280,-128}},textString="Initial-mass estimate / full simulation includes changing mass and tire contact",textColor={158,179,191})
    }),
    experiment(StartTime=0,StopTime=0.01,Interval=0.01,Tolerance=1e-6));
end LaunchSizingBench;
