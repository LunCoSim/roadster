# Fan preload timing

CoursePilot now has named ramp_entry_z_m and fan_preload_distance_m parameters.
The current course enters the ramp at Z=−300 m and preloads 12 m beforehand,
Z=−288 m. With the authored 12 m/s approach request this gives one second to
build suction. Earlier phase-4 travel keeps the fans off; phase 5 retains them
until the existing release action. Manual prompts no longer request fans on
at the second refill pad.

CourseFanTimingBench drives the actual CoursePilot with prescribed controller
inputs. It is not a car trajectory or physics substitute. A native RunExperiment
completed 0–6 s, output interval 0.01 s, tolerance 1e-8 in 102 ms. Experiment:
866a79a0-87ab-49b2-8047-df34ed142c5a. Source CID:
bafkreih2vdbwrqynzp2kvkpz5mvnqx5bahxzuouv6t2ksr7vbi34mm44pm.

The authored fan_timing_bench.rhai check ran through production RunRhai:
604 complete samples, 150 early-off checks, 247 approach-on checks, 97 crest-on
checks and 99 release-off checks passed. This is controller verification;
full-course dynamics and fresh video after the planned ramp audit remain open.
