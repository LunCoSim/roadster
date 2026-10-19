# Shared course tree checkpoint

The course sequence lives in `scenarios/skill_course.rhai` as a `seq` behavior
 tree. `models/CoursePilot.mo` supplies digital control suggestions to both the
native keyboard client and the event-driven autopilot. Guidance does not write
forces, poses or velocities. The HUD exposes autopilot start/stop and suggestions.

Production validation at this checkpoint:

- Modelica compiles and the production runtime admits physics.
- The keyboard run reached phase 6 (flight/landing) at 33.9167 simulated seconds.
- That run was invalidated at 39.05 seconds by an unexpected native Shift release.
  It is not a passing course acceptance result.
- The new autopilot path has not yet completed production acceptance.
- The older standalone `course_pilot.rhai` acceptance controller remains to be
  replaced by an observer of this shared tree.

The course height connection uses the native `position_y` output. It requires
the LunCoSim live-port lookup correction currently being committed separately.

Next maneuver review: represent the demonstrated backward yaw maneuver explicitly
and keep the avatar camera stable while the vehicle attitude changes. The current
landing guidance targets identity attitude; its accumulated pitch qualification
is not yet a specification of that backward yaw maneuver.
