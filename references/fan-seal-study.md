# Controlled fan-skirt study

`RoadsterFanSealBench` composes the existing `FanAdhesion` / `SuctionFan`
plant with controlled geometric observations. It does not prescribe motion
of the car, change a wheel or alter the fan equations.

The fan command turns on at 1 s. At 5 s the observed skirt gap changes from
0.12 m to 0.55 m. Surface validity and alignment remain one. The chosen
0.40 m skirt reach matches `RoadsterVehicle.fan_skirt_reach`.

The native 9 s experiment with 0.01 s output intervals produced 903 samples,
including event samples. The read-only Rhai report
`roadster_report::fan_seal_report(experiment_id, 4.0, 8.0)` selects actual
recorded samples without interpolation:

| Quantity | Sealed, 4 s | Open, 8 s |
|---|---:|---:|
| Gap | 0.12 m | 0.55 m |
| Suction | 40.0 kN | approximately zero |
| Pressure difference | 20.0 kPa | 1.18 kPa |
| Electrical power | 20.68 kW | 80.0 kW |
| Volume flow | 0.542 m³/s | 41.84 m³/s |

The open case reaches the **assumed 80 kW power ceiling**. It is not a
prediction of Tesla's actual fan rating. Floor area, skirt geometry, leakage,
efficiency and seal law are reduced-model study inputs. The comparison shows
their consequence: almost four times the electrical power can accompany
almost no suction when the seal is lost. It does not imply that the tires
lose their ordinary gravity-loaded grip.

Native run `08d00b17-b17f-41c4-bba8-e3e0b891386c` used source CID
`bafkreif2lasp7avjuvstyovzecdi2dsoyt7qan5ueoiv2orlvqlktbj6wi`.
The report also rejects reversed observation times and a gas-bench result
that lacks the required fan variables. The campaign retains the numerical
receipts and separately labelled native graph captures.

To repeat the study, open the model in the active Twin, run
`RoadsterFanSealBench` from 0 to 9 s with `dt=0.01` and tolerance `1e-6`, then
pass the new experiment ID to the report. Experiment IDs belong to their
own document/runtime scope; an archived ID is not a replacement for a new run.
