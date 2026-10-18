package Roadster {
    private import ScalarValues::*;
    private import ISQ::MassValue;
    private import ISQ::LengthValue;
    private import SI::kg;
    private import SI::m;

    attribute def SourceLocator :> String;
    enum def EvidenceSourceRole { Reference; StudyAssumption; }
    part def EvidenceSource {
        attribute role : EvidenceSourceRole;
        attribute locator : SourceLocator;
    }
    part def RequirementEvidence {
        ref targetRequirement : SysML::RequirementUsage;
        ref part sources : EvidenceSource[0..*];
    }

    port def ElectricalPort { out attribute powerW : Real; }
    port def TorquePort { out attribute torqueNm : Real; }
    port def CommandPort {
        in attribute throttle : Real;
        in attribute steer : Real;
        in attribute brake : Real;
        in attribute fan : Real;
        in attribute boost : Real;
        in attribute lift : Real;
        in attribute thrustX : Real;
        in attribute thrustY : Real;
        in attribute thrustZ : Real;
        in attribute liftFrontLeft : Real;
        in attribute liftFrontRight : Real;
        in attribute liftRearLeft : Real;
        in attribute liftRearRight : Real;
        in attribute refill : Real;
        in attribute refillTemperatureK : Real;
    }
    part def Battery { port supply : ElectricalPort; }
    part def DriveUnit { port supply : ~ElectricalPort; port axle : TorquePort; }
    part def Wheel { port hub : ~TorquePort; }
    part def Body;
    part def FanSystem {
        doc /* Four rear extractors evacuate a skirted plenum. Count and position follow S10; pressure, area, power and performance maps are study assumptions. */
        attribute extractorCount : Integer = 4;
        attribute studyPlenumAreaM2 : Real = 2.0;
        attribute studyPressureDropPa : Real = 20000;
        attribute studyElectricalLimitW : Real = 80000;
    }
    part def ActiveAerodynamics;
    part def ColdGasSystem {
        doc /* Study dry-air tank using a reusable real-gas EOS, adiabatic energy balance, compressible nozzle closure and finite valve response. Rear boost, corner lift and front side/yaw commands share one 250 kg starting reservoir. Parameters and validity limits are recorded in references/dynamics.md. */
    }
    part def GasStorage {
        doc /* Rocket: 200 L rear vessel plus 400 L in place of the passenger seat. The study uses 250 kg TOTAL with a common-pressure/temperature manifold, not 250 kg in each vessel. */
        attribute rearInternalVolumeM3 : Real = 0.2;
        attribute cabinInternalVolumeM3 : Real = 0.4;
        attribute totalStudyAirMass : MassValue = 250[kg];
    }
    part def ThermalSystem {
        doc /* Finite Modelica tank-wall heat storage and passive exchange; editable initial/refill temperature. No assertion of Tesla's undisclosed cold-gas heating design. */
    }
    part def DriverStation {
        doc /* Fixed key meanings at every altitude: WASD drivetrain, Q/E left/right lift pairs for roll, R/C front/rear pairs for pitch, J/L yaw, F toggles fans, K collective lift, Space forward boost and Shift brake. No airborne remapping or automatic attitude correction. */
    }
    part def GameRefillWaypoint {
        doc /* Explicit game service boundary. Modelica computes immediate inventory/thermal ledger adjustments, native mass/inertia and EOS pressure. Co-moving supply preserves velocity and accounts external mechanical/stored energy exchange. Not a real instantaneous refill mechanism. */
        attribute targetAirMass : MassValue = 250[kg];
    }
    part def SkillTrack {
        doc /* Native Earth contact geometry; measured launch speed, three airborne block crossings, fan-sealed upper ramp and a manual aerial turn ending upright on four wheel contacts. Pause freezes course simulation time. */
        part firstRefill : GameRefillWaypoint;
        part secondRefill : GameRefillWaypoint;
        attribute jumpBlockCount : Integer = 3;
        attribute rampWidth : LengthValue = 14[m];
        attribute studyRampHeight : LengthValue = 64.46[m];
    }
    part skillTrack : SkillTrack;

    part def RoadsterVehicle {
        doc /* October 2026 study architecture. Runtime geometry and physics are owned by USD; equations by Modelica. Assumed geometry and drivetrain topology are documented in references/assumptions.md. */
        attribute studyDryMass : MassValue = 1700[kg];
        attribute studyAirMass : MassValue = 250[kg];
        attribute studyChargedMass : MassValue = 1950[kg];
        attribute combinedMotorPowerW : Real = 1000000;
        attribute combinedMotorTorqueNm : Real = 1400;
        attribute studyWheelbase : LengthValue = 2.75[m];
        attribute studyTrack : LengthValue = 1.72[m];
        attribute studyTireRadius : LengthValue = 0.34[m];
        part body : Body;
        part battery : Battery;
        part leftDriveUnit : DriveUnit;
        part rightDriveUnit : DriveUnit;
        part frontLeft : Wheel;
        part frontRight : Wheel;
        part rearLeft : Wheel;
        part rearRight : Wheel;
        part fanSystem : FanSystem;
        part aero : ActiveAerodynamics;
        part thermal : ThermalSystem;
        part driver : DriverStation;
        port commands : CommandPort;
        connect battery.supply to leftDriveUnit.supply;
        connect battery.supply to rightDriveUnit.supply;
        connect leftDriveUnit.axle to rearLeft.hub;
        connect rightDriveUnit.axle to rearRight.hub;
    }
    part def PerformanceVehicle :> RoadsterVehicle {
        part passenger : DriverStation;
    }
    part def ThrustVehicle :> PerformanceVehicle {
        part rearThrusters : ColdGasSystem;
    }
    part def RocketVehicle :> RoadsterVehicle {
        part rearThrusters : ColdGasSystem;
        part perimeterThrusters : ColdGasSystem;
        part storage : GasStorage;
    }
    part runner : RocketVehicle;

    constraint def HasOneSeat {
        in count : Integer;
        count == 1;
    }
    constraint def HasFourWheels {
        in count : Integer;
        count == 4;
    }
    constraint def PositiveMotion {
        in travelM : Real;
        travelM > 0.0;
    }
    constraint def StateOfChargeBounds {
        in soc : Real;
        soc >= 0.0 and soc <= 1.0;
    }
    constraint def EnergyConsumed {
        in initialSoc : Real;
        in finalSoc : Real;
        finalSoc < initialSoc;
    }
    constraint def FiniteImpulse {
        in initialImpulseNs : Real;
        in remainingImpulseNs : Real;
        remainingImpulseNs >= 0.0 and remainingImpulseNs < initialImpulseNs;
    }
    constraint def SubsecondLaunch {
        in elapsedS : Real;
        in reachedSpeedMps : Real;
        elapsedS > 0.0 and elapsedS <= 0.59 and reachedSpeedMps >= 26.8224;
    }

    requirement def Seating {
        doc /* The Rocket runner shall provide one occupant seating station; its passenger space is allocated to the additional pressure vessel. Verification: inspection of the composed vehicle. Source S01. */
        require HasOneSeat;
    }
    requirement def WheelAssembly {
        doc /* The runner shall compose four tire-contact wheel stations. Verification: inspection of the composed wheel topology. Source: study runner architecture. */
        require HasFourWheels;
    }
    requirement def DriveResponse {
        doc /* On the level dry Earth test track, a positive drive command shall produce positive forward displacement. Verification: physics position observation after actuation. */
        require PositiveMotion;
    }
    requirement def BatteryBounds {
        doc /* The battery energy model shall expose a state of charge in the closed interval zero to one throughout a run. Verification: sampled Modelica output. */
        require StateOfChargeBounds;
    }
    requirement def DriveEnergy {
        doc /* During the powered launch, the runner shall consume stored electrical energy. Verification: initial and final state of charge. */
        require EnergyConsumed;
    }
    requirement def GasBudget {
        doc /* A boosted launch shall consume the finite stored impulse budget while reporting a nonnegative remaining budget. Verification: sampled Modelica output. */
        require FiniteImpulse;
    }
    requirement def ThrustAcceleration {
        doc /* The gas-assisted study runner shall accelerate from rest to 60 mph in no more than 0.59 seconds. Source: user-selected Rocket study acceptance target; no manufacturer standing-start test is inferred. The study records standing-start timing without rollout subtraction on its level dry track. Verification: sampled physical body velocity. */
        require SubsecondLaunch;
    }
    requirement <'RR-001'> seating : Seating { subject vehicle : RocketVehicle; }
    requirement <'RR-002'> wheels : WheelAssembly { subject vehicle : RoadsterVehicle; }
    requirement <'RR-003'> driveResponse : DriveResponse { subject vehicle : RoadsterVehicle; }
    requirement <'RR-004'> batteryBounds : BatteryBounds { subject vehicle : RoadsterVehicle; }
    requirement <'RR-005'> driveEnergy : DriveEnergy { subject vehicle : RoadsterVehicle; }
    requirement <'RR-006'> gasBudget : GasBudget { subject vehicle : RocketVehicle; }
    requirement <'RR-007'> thrustAcceleration : ThrustAcceleration { subject vehicle : RocketVehicle; }
    satisfy seating by runner;
    satisfy wheels by runner;
    satisfy driveResponse by runner;
    satisfy batteryBounds by runner;
    satisfy driveEnergy by runner;
    satisfy gasBudget by runner;
    satisfy thrustAcceleration by runner;

    verification def VerifyRunner {
        subject vehicle : RocketVehicle;
        objective {
            verify seating;
            verify wheels;
            verify driveResponse;
            verify batteryBounds;
            verify driveEnergy;
            verify gasBudget;
            verify thrustAcceleration;
        }
    }
    part teslaCurrent : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.tesla.com/en_GB/roadster";
    }
    part study : EvidenceSource {
        attribute role : EvidenceSourceRole = "StudyAssumption";
        attribute locator : SourceLocator = "../references/assumptions.md";
    }
    part gasDynamics : EvidenceSource {
        attribute role : EvidenceSourceRole = "Reference";
        attribute locator : SourceLocator = "https://www.grc.nasa.gov/www/k-12/BGP/mflchk.html";
    }
    part evidenceSeating : RequirementEvidence {
        ref targetRequirement = seating;
        ref sources = (teslaCurrent);
    }
    part evidenceAcceleration : RequirementEvidence {
        ref targetRequirement = thrustAcceleration;
        ref sources = (teslaCurrent, study);
    }
    part evidenceWheels : RequirementEvidence { ref targetRequirement = wheels; ref sources = (study); }
    part evidenceDrive : RequirementEvidence { ref targetRequirement = driveResponse; ref sources = (study); }
    part evidenceBattery : RequirementEvidence { ref targetRequirement = batteryBounds; ref sources = (study); }
    part evidenceEnergy : RequirementEvidence { ref targetRequirement = driveEnergy; ref sources = (study); }
    part evidenceGas : RequirementEvidence { ref targetRequirement = gasBudget; ref sources = (study, gasDynamics); }
}
