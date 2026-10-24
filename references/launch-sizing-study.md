# Launch force budget

`models/LaunchSizingBench.mo` inherits the vehicle's `LaunchSizing` model and
adds a native Modelica Diagram. It changes no vehicle or sizing equations.
The diagram reads completed native experiment outputs; it is also usable as
an interactive model view.

The reported 0–60 mph target supplies the speed and time. A 1,950 kg initial
mass is this study's assumption: 1,700 kg dry mass plus 250 kg of gas.
The completed native run gives:

| Input or result | Value |
|---|---:|
| Target speed | 60 mph / 26.8224 m/s |
| Target time | 0.59 s |
| Assumed initial mass | 1,950 kg |
| Mean acceleration, speed / time | 45.4617 m/s² |
| Initial-mass estimate of mean net force | 88.6503 kN |

Native run `f4a6a02f-d4eb-4eaf-91e4-eb926b57d104` completed over 0–0.01 s,
with two retained samples and source CID
`bafkreifnkjnh2pdmrwotcvtfdbe4j5znnjakd6rzs2ws2qkwsflejbxdru`.
Its report returned all four displayed inputs/results without downsampling.

This is a mean-force estimate at the initial mass. The full vehicle simulation
also solves changing gas mass, thrust, drag and wheel contact. Speed, time and
mass alone do not identify a unique nozzle area, tank pressure or jet force
history. A comparable wheel-only run is needed before subtracting a wheel
contribution. The diagram therefore does not show the older wheel-only
calibration as a current result or display a new numerical jet-force inference.

The ten-second native diagram capture retains its first/final picture review,
input hashes, result receipt and recording clock checks in the Roadster film
package's `delivery/force_budget_capture_review.json`. That review qualifies
this diagram; it does not validate Tesla hardware or the complete film.
