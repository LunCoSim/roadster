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
    }
    part def Battery { port supply : ElectricalPort; }
    part def DriveUnit { port supply : ~ElectricalPort; port axle : TorquePort; }
    part def Wheel { port hub : ~TorquePort; }
    part def Body;
    part def FanSystem;
    part def ActiveAerodynamics;
    part def ColdGasSystem {
        doc /* Study dry-air tank using a reusable real-gas EOS, adiabatic energy balance, compressible nozzle closure and finite valve response. Rear boost, corner lift and front side/yaw commands share one 250 kg starting reservoir. Parameters and validity limits are recorded in references/dynamics.md. */
    }
    part def ThermalSystem;
    part def DriverStation;

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
        part perimeterThrusters : ColdGasSystem;
    }
    part runner : ThrustVehicle;

    constraint def HasTwoSeats {
        in count : Integer;
        count == 2;
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
        elapsedS > 0.0 and elapsedS < 1.0 and reachedSpeedMps >= 26.8224;
    }

    requirement def Seating {
        doc /* The Thrust vehicle shall provide two occupant seating stations. Verification: inspection of the composed vehicle. Source S01. */
        require HasTwoSeats;
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
        doc /* The Thrust variant shall accelerate from rest to 60 mph in less than one second. Source S01 manufacturer claim. The study records standing-start timing without rollout subtraction on its level dry track. Verification: sampled physical body velocity. */
        require SubsecondLaunch;
    }
    requirement <'RR-001'> seating : Seating { subject vehicle : ThrustVehicle; }
    requirement <'RR-002'> wheels : WheelAssembly { subject vehicle : RoadsterVehicle; }
    requirement <'RR-003'> driveResponse : DriveResponse { subject vehicle : RoadsterVehicle; }
    requirement <'RR-004'> batteryBounds : BatteryBounds { subject vehicle : RoadsterVehicle; }
    requirement <'RR-005'> driveEnergy : DriveEnergy { subject vehicle : RoadsterVehicle; }
    requirement <'RR-006'> gasBudget : GasBudget { subject vehicle : ThrustVehicle; }
    requirement <'RR-007'> thrustAcceleration : ThrustAcceleration { subject vehicle : ThrustVehicle; }
    satisfy seating by runner;
    satisfy wheels by runner;
    satisfy driveResponse by runner;
    satisfy batteryBounds by runner;
    satisfy driveEnergy by runner;
    satisfy gasBudget by runner;
    satisfy thrustAcceleration by runner;

    verification def VerifyRunner {
        subject vehicle : ThrustVehicle;
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
