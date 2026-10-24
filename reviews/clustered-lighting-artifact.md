# Roadster background lighting artifact

At output 00:15:21 (60 fps), the v14 report contains rectangular black steps in
lit ground outside the runway. They are present in raw source
report_course_flight_setup_v94, frame 561 (9.35 seconds); export is not the cause.

Reproduction used the normal cinematic scene in an owned production session
on port 4499, with a 1600×1000 offscreen target and simulation held. Camera eye
was derived from the recorded car position (−0.0284855, 0.5071319, −226.5373599)
and the existing native course camera at 9.35 seconds, angle 0.7823339 rad.

Findings:

- Current normal clustered rendering reproduces the stepped missing lighting.
- Isolating Pool13L retains the steps: this is not only a crowded-light budget.
- Explicit CPU assignment also retains them: switching off GPU clustering alone
  does not fix this artifact.
- A CPU single-cluster diagnostic removes the rectangular steps, leaving the
  ordinary horizontal boundary. This isolates spatial cluster assignment / lookup
  as the failing path rather than missing ground topology or video encoding.
- The precise faulty bound/index computation has not been established. Do not
  claim an upstream patch or a qualified production repair from these tests.

Temporary application-owned CPU/single-cluster switches were removed after the
comparison. Neither workaround is shipped as the solution. No dependency source
was edited. Relevant owners are Bevy light cluster assignment and PBR fragment
cluster lookup; LunCoSim camera policy is scene_camera.rs. The normal scene's
local lights have a 20 m influence range.

Directed native captures are retained locally under
.scratch/rear-and-lighting-review/ (GPU/default, isolated light, CPU/default,
CPU/single cluster). Logs are in the local cache, roadster-cluster-*.log.
The vehicle being absent at the fixed diagnostic camera is intentional: the
camera is at the recorded course location while the held car stays at spawn.
