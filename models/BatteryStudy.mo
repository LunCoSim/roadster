model BatteryStudy
  "Source-informed sizing assumptions; no claim of Roadster cell or pack calibration"
  // S10 (firsthand Tesla engineer interview, 2026-10-16): >100 kWh,
  // 4680 pack, >300-mile target, 1 MW combined drive. Exact energy withheld.
  // https://www.motortrend.com/news/first-look-2028-tesla-roadster-performance-thrust-rocket
  // A-B01: select 120 kWh by rounding the 118.019 kWh range inference below.
  // Sensitivity bracket 110-140 kWh is chosen for study, not a Tesla tolerance.
  // Full assumption register and derivation: references/battery-study.md.
  parameter Real capacity_kwh = 120 "Selected study baseline; exact Tesla value withheld";
  parameter Real reference_capacity_kwh = 120;
  // S10 reports a 1700 kg vehicle target without trim/fill definition.
  // A-B02 interprets this as dry study mass INCLUDING the 120 kWh pack.
  parameter Real reference_vehicle_dry_mass_kg = 1700 "Includes the reference battery: never add its mass twice";
  // S11: measured OLD 2022 Model Y 4680 cell, not the new Roadster chemistry.
  // Primary teardown: https://doi.org/10.1016/j.xcrp.2025.102453
  parameter Real cell_specific_energy_wh_kg = 241.01 "2025 teardown of an earlier Tesla 4680; conservative proxy";
  parameter Real cell_energy_density_wh_l = 643.3;
  // A-B03: pack overhead assumptions, not measurements. The S11 cell values
  // must be derated for enclosure, interconnect, cooling and control hardware.
  parameter Real cell_mass_fraction = 0.80 "Cells / complete pack mass, study assumption";
  parameter Real cell_volume_fraction = 0.75 "Cells / complete pack volume, study assumption";
  // A-B04: 90% energy allowance and 220 Wh/km are sizing choices. They are
  // not Tesla's BMS window or an observed drive-cycle consumption. S10's
  // 300-mile reported floor constrains the inference, not these two choices.
  parameter Real range_usable_fraction = 0.90 "Range-sizing allowance, not a claimed BMS setting";
  parameter Real cycle_consumption_wh_km = 220 "Mixed-driving sizing assumption";
  parameter Real target_range_miles = 300 "Reported target floor, not an EPA result";
  parameter Real motor_peak_power_w = 1000000;
  // A-B05: conversion efficiency, auxiliary and fan loads reuse the plant
  // study assumptions in references/assumptions.md; no manufacturer loss map.
  parameter Real drive_efficiency = 0.93;
  parameter Real fan_peak_power_w = 80000;
  parameter Real other_auxiliary_power_w = 920;
  // A-B06: equivalent incremental battery box AT the reference vehicle COM.
  // Used only for capacity/mass/inertia sensitivity; dimensions are assumed.
  parameter Real pack_width_m = 1.5 "Equivalent mass distribution; not a manufacturer drawing";
  parameter Real pack_height_m = 0.12;
  parameter Real pack_length_m = 2.5;
  parameter Real pack_specific_energy_wh_kg = cell_specific_energy_wh_kg*cell_mass_fraction;
  parameter Real pack_mass_kg = capacity_kwh*1000/pack_specific_energy_wh_kg;
  parameter Real reference_pack_mass_kg = reference_capacity_kwh*1000/pack_specific_energy_wh_kg;
  parameter Real pack_mass_delta_kg = pack_mass_kg-reference_pack_mass_kg;
  parameter Real vehicle_dry_mass_kg = reference_vehicle_dry_mass_kg+pack_mass_delta_kg;
  output Real nominal_energy_kwh;
  output Real range_energy_kwh;
  output Real range_proxy_km;
  output Real inferred_capacity_kwh;
  output Real pack_mass_estimate_kg;
  output Real pack_volume_estimate_l;
  output Real non_pack_reference_mass_kg;
  output Real peak_dc_power_kw;
  output Real peak_equivalent_c;
  output Real charge_10_80_energy_kwh;
  output Real charge_10min_average_kw;
  output Real charge_12min_average_kw;
equation
  nominal_energy_kwh = capacity_kwh;
  range_energy_kwh = capacity_kwh*range_usable_fraction;
  range_proxy_km = 1000*range_energy_kwh/cycle_consumption_wh_km;
  inferred_capacity_kwh = target_range_miles*1.609344*cycle_consumption_wh_km/(1000*range_usable_fraction);
  pack_mass_estimate_kg = pack_mass_kg;
  pack_volume_estimate_l = capacity_kwh*1000/(cell_energy_density_wh_l*cell_volume_fraction);
  non_pack_reference_mass_kg = reference_vehicle_dry_mass_kg-reference_pack_mass_kg;
  peak_dc_power_kw = (motor_peak_power_w/drive_efficiency+fan_peak_power_w+other_auxiliary_power_w)/1000;
  peak_equivalent_c = peak_dc_power_kw/capacity_kwh;
  // S10 reports a 10-80% charge target in 10-12 min. These are required
  // average powers, not a measured charger/taper/thermal response.
  charge_10_80_energy_kwh = 0.70*capacity_kwh;
  charge_10min_average_kw = charge_10_80_energy_kwh*60/10;
  charge_12min_average_kw = charge_10_80_energy_kwh*60/12;
end BatteryStudy;
