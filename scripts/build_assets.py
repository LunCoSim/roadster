#!/usr/bin/env python3
"""Offline authoring of the original Roadster study geometry and USD wiring.

Only Python's standard library is needed. Run from any directory. Numerical
values below are the explicit study assumptions in references/assumptions.md.
The generated assets are ordinary editable USD; this script is not a runtime.
"""
from pathlib import Path
from math import sqrt

ROOT = Path(__file__).resolve().parents[1]
HEADER = '#usda 1.0\n(\n    defaultPrim = "%s"\n    upAxis = "Y"\n    metersPerUnit = 1\n)\n\n'


def cube(name, pos, scale, color, material=None, collision=False):
    schema = ' (prepend apiSchemas = ["PhysicsCollisionAPI"])' if collision else ''
    binding = f'    rel material:binding = </Body/Looks/{material}>\n' if material else ''
    return f'''def Cube "{name}"{schema}
{{
    double size = 1
    double3 xformOp:translate = {pos}
    double3 xformOp:scale = {scale}
    uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:scale"]
    color3f[] primvars:displayColor = [{color}]
    bool physics:collisionEnabled = {str(collision).lower()}
{binding}}}
'''


def mesh(name, points, faces, color, material):
    return f'''def Mesh "{name}" (prepend apiSchemas = ["MaterialBindingAPI"])
{{
    point3f[] points = [{', '.join(str(tuple(round(a, 6) for a in p)) for p in points)}]
    int[] faceVertexCounts = {[len(f) for f in faces]}
    int[] faceVertexIndices = {[i for f in faces for i in f]}
    uniform token subdivisionScheme = "none"
    uniform bool doubleSided = true
    color3f[] primvars:displayColor = [{color}]
    bool physics:collisionEnabled = false
    rel material:binding = </Body/Looks/{material}>
}}
'''


def material(name, color, metallic, roughness, emission=(0, 0, 0)):
    return f'''def Material "{name}"
{{
    token outputs:surface.connect = </Body/Looks/{name}/Shader.outputs:surface>
    def Shader "Shader"
    {{
        uniform token info:id = "UsdPreviewSurface"
        color3f inputs:diffuseColor = {color}
        float inputs:metallic = {metallic}
        float inputs:roughness = {roughness}
        color3f inputs:emissiveColor = {emission}
        token outputs:surface
    }}
}}
'''


def body():
    # Original low-poly silhouette. Wheel arches are cut into the side skin.
    sections = [(-2.25, .70, .04), (-1.90, .94, .24), (-.75, .97, .28),
                (-.20, .97, .27), (.90, .97, .33), (1.80, .94, .25), (2.25, .75, .15)]

    def at(z):
        for a, b in zip(sections, sections[1:]):
            if a[0] <= z <= b[0]:
                t = (z-a[0])/(b[0]-a[0])
                return a[1]+t*(b[1]-a[1]), a[2]+t*(b[2]-a[2])
        raise ValueError(z)

    zs = sorted(set([s[0] for s in sections] + [round(-2.2+i*.05, 3) for i in range(89)]))
    points, faces = [], []
    for z in zs:
        w, top = at(z)
        lower = -.30
        for axle in (-1.375, 1.375):
            delta = abs(z-axle)
            if delta < .385:
                lower = max(lower, -.21+sqrt(.385**2-delta**2))
        points += [(-w, lower, z), (-w, top-.04, z), (-.72*w, top, z),
                   (.72*w, top, z), (w, top-.04, z), (w, lower, z)]
    for i in range(len(zs)-1):
        for j in range(5):
            k = i*6+j
            faces.append((k, k+1, k+7, k+6))
    faces += [tuple(range(5, -1, -1)), tuple(range(len(points)-6, len(points)))]
    text = HEADER % 'Body' + 'def Xform "Body" (kind = "component")\n{\n'
    text += 'def Scope "Looks" {\n'
    text += material('White', (.83, .86, .88), .35, .24)
    text += material('Glass', (.28, .17, .055), .72, .15)
    text += material('Carbon', (.022, .028, .035), .28, .38)
    text += material('Lamp', (.85, .9, 1), .1, .18, (2, 2.2, 2.5))
    text += material('RearLamp', (.45, .005, .008), .1, .2, (1.8, .008, .015))
    text += '}\n' + mesh('Skin', points, faces, (.83, .86, .88), 'White')
    rings = [(-.72, .76, .29), (-.20, .65, .70), (.65, .65, .66), (1.30, .77, .32)]
    canopy_points = [(x, y, z) for z, w, y in rings for x in (-w, w)]
    text += mesh('GoldCanopy', canopy_points,
                 [(0, 1, 3, 2), (2, 3, 5, 4), (4, 5, 7, 6),
                  (0, 2, 4, 6), (1, 7, 5, 3)], (.28, .17, .055), 'Glass')
    text += cube('BatteryFloorCollider', (0, -.18, 0), (1.48, .18, 3.8), (.022,.028,.035), 'Carbon', True)
    text += cube('FrontSplitter', (0,-.25,-2.18), (1.65,.055,.25), (.025,.03,.04), 'Carbon')
    text += cube('RearDiffuser', (0,-.23,2.12), (1.62,.12,.35), (.025,.03,.04), 'Carbon')
    text += cube('RearWing', (0,.31,2.02), (1.72,.045,.20), (.03,.035,.04), 'Carbon')
    text += cube('RearLightBar', (0,.11,2.255), (1.44,.025,.016), (.8,.005,.01), 'RearLamp')
    for side, x in [('L', -.57), ('R', .57)]:
        text += cube('Headlight'+side, (x,.065,-2.23), (.44,.022,.018), (.8,.9,1), 'Lamp')
        text += cube('Rocker'+side, ((-.94 if side=='L' else .94),-.27,0), (.10,.06,1.70), (.03,.035,.04), 'Carbon')
    for name, x in [('DriverSeat', -.37), ('PassengerSeat', .37)]:
        text += cube(name, (x,.17,.32), (.43,.42,.66), (.85,.85,.82))
    for x in (-.36,.36):
        text += f'''def Cylinder "Fan{'L' if x<0 else 'R'}" {{
            uniform token axis = "Y"
            double radius = 0.26
            double height = 0.06
            double3 xformOp:translate = ({x}, -0.29, 0.62)
            uniform token[] xformOpOrder = ["xformOp:translate"]
            color3f[] primvars:displayColor = [(0.04,0.05,0.06)]
            bool physics:collisionEnabled = false
        }}\n'''
    (ROOT/'components/body.usda').write_text(text+'}\n')


def tires():
    text = HEADER % 'RoadTire' + '''over "RoadTire" (
    prepend references = @lunco://components/mobility/tires/hard.usda@</Tire>
) {
    float physics:dynamicFriction = 1.4
    float physics:staticFriction = 1.4
    float physxVehicleTire:longitudinalStiffness = 30000
    float2 physxVehicleTire:lateralStiffnessGraph = (1, 90000)
    float physxVehicleTire:restLoad = 9000
    # Steady-state slip-angle denominator floor: avoids the discontinuous
    # zero-speed lateral saturation of an uncalibrated tire curve.
    float lunco:tire:minValidatedSpeed = 8.0
    over "TireLook" { over "Shader" {
        uniform asset info:wgsl:sourceAsset = @../shaders/road_tire.wgsl@
        color3f inputs:rim_color = (0.75,0.78,0.82)
        float inputs:spoke_count = 5
        float inputs:spoke_width = 0.22
        float inputs:tread_lugs = 32
        float inputs:lug_depth = 0.04
    } }
}
'''
    (ROOT/'components/road_tire.usda').write_text(text)


def nozzles(name, stations):
    text = HEADER % name + f'def Xform "{name}" (kind = "component") {{\n'
    for i, station in enumerate(stations):
        x, y, z = station[:3]
        axis = station[3] if len(station) > 3 else 'Z'
        text += f'''def Cylinder "Nozzle{i}" {{
    uniform token axis = "{axis}"
    double radius = 0.072
    double height = 0.14
    double3 xformOp:translate = ({x},{y},{z})
    uniform token[] xformOpOrder = ["xformOp:translate"]
    color3f[] primvars:displayColor = [(0.15,0.16,0.17)]
    bool physics:collisionEnabled = false
}}\n'''
    text += 'def Scope "Looks" {\n'
    axes = [('Rear', 'z', -1, 30000)] if name == 'RearThrusters' else [('Lift', 'y', 1, 30000),('Left', 'x', 1, 5000),('Right', 'x', -1, 5000)]
    for label, axis, sign, reference in axes:
        text += f'''def Material "{label}" {{
    token outputs:surface.connect = </{name}/Looks/{label}/Surface.outputs:surface>
    def Shader "Surface" {{
        uniform token info:implementationSource = "sourceAsset"
        asset info:wgsl:sourceAsset = @../shaders/air_jet.wgsl@
        float inputs:force = 0
        float inputs:direction = {sign}
        float inputs:reference_force = {reference}
        token outputs:surface
    }}
}}\n'''
    text += '}\n'
    for i, station in enumerate(stations):
        x,y,z = station[:3]
        if name == 'RearThrusters':
            label,axis,offset,rotation = 'Rear','z',(0,0,.77),(90,0,0)
        elif i < 4:
            label,axis,offset,rotation = 'Lift','y',(0,-.72,0),(180,0,0)
        elif x < 0:
            label,axis,offset,rotation = 'Left','x',(-.77,0,0),(0,0,90)
        else:
            label,axis,offset,rotation = 'Right','x',(.77,0,0),(0,0,-90)
        center = tuple(a+b for a,b in zip((x,y,z),offset))
        text += f'''def Cone "Jet{i}" (prepend apiSchemas = ["MaterialBindingAPI"]) {{
    uniform token axis = "Y"
    double height = 1
    double radius = 1
    double3 xformOp:translate = {center}
    double3 xformOp:rotateXYZ = {rotation}
    double3 xformOp:scale = (0.16,1.4,0.16)
    uniform token[] xformOpOrder = ["xformOp:translate","xformOp:rotateXYZ","xformOp:scale"]
    bool physics:collisionEnabled = false
    bool primvars:doNotCastShadows = true
    uniform bool doubleSided = true
    float[] primvars:displayOpacity = [0.5]
    rel material:binding = </{name}/Looks/{label}>
    float inputs:force = 0
}}\n'''
    (ROOT/f'components/{name}.usda').write_text(text+'}\n')


def vehicle():
    text = HEADER % 'Roadster' + '''def Xform "Roadster" (
    kind = "assembly"
    doc = "October 2026 Roadster study. Geometry and performance parameters are assumptions, not Tesla CAD or calibration."
    prepend apiSchemas = ["PhysicsRigidBodyAPI", "PhysxRigidBodyAPI", "PhysicsMassAPI", "PhysxVehicleContextAPI", "LunCoCatalogAPI", "LunCoProgramAPI", "LunCoUiSchemaAPI"]
    prepend references = [
        @lunco://components/avionics/obc.usda@</OBC>
    ]
    prepend variantSets = ["trim"]
    variants = { string trim = "Performance" }
) {
    uniform bool lunco:spawnable = true
    string ui:displayName = "ROADSTER"
    string lunco:ui:surfaceId = "vessel-hud"
    string lunco:ui:visibilityMode = "possessed"
    uniform token info:implementationSource = "sourceAsset"
    uniform asset info:sourceAsset = @../models/RoadsterVehicle.mo@
    uniform bool lunco:program:realtimeSafe = true
    uniform token lunco:steeringGeometry = "ackermann"
    # Native raycast wheels contribute 4 x 24 kg to computed vehicle mass.
    # 1604 + 96 = 1700 kg dry vehicle. Modelica supplies gas mass in operation.
    float physics:mass = 1604
    float3 physics:centerOfMass = (0,-0.14,0)
    float3 physics:diagonalInertia = (3022,3494,708)
    float physxRigidBody:linearDamping = 0
    float physxRigidBody:angularDamping = 0.5
    bool physxRigidBody:enableCCD = true
    float inputs:boost = 0
    float inputs:lift = 0
    float inputs:thrust_x = 0
    float inputs:thrust_y = 0
    float inputs:thrust_z = 0
    float inputs:fan = 1
    float inputs:brake = 0
    float inputs:wheel_speed_left.connect = </Roadster/Wheel_RL.outputs:shaft_speed>
    float inputs:wheel_speed_right.connect = </Roadster/Wheel_RR.outputs:shaft_speed>
    float inputs:measured_vx.connect = </Roadster.outputs:velocity_x>
    float inputs:measured_vz.connect = </Roadster.outputs:velocity_z>
    float inputs:measured_vy.connect = </Roadster.outputs:velocity_y>
    float inputs:ground_gap.connect = </Roadster/GroundSeal.outputs:ray_distance>
    float inputs:ground_valid.connect = </Roadster/GroundSeal.outputs:ray_hit_valid>
    float inputs:attitude_w.connect = </Roadster.outputs:quat_w>
    float inputs:attitude_x.connect = </Roadster.outputs:quat_x>
    float inputs:attitude_y.connect = </Roadster.outputs:quat_y>
    float inputs:attitude_z.connect = </Roadster.outputs:quat_z>
    float inputs:throttle = 0
    float inputs:steer = 0
    float inputs:program_active = 0
    float inputs:autopilot_enable = 0
    float inputs:autopilot_target_x = 0
    float inputs:autopilot_target_z = 0
    float inputs:autopilot_speed = 0
    float inputs:autopilot_radius = 2
    float inputs:autopilot_turn_only = 0
    float inputs:autopilot_position_x.connect = </Roadster.outputs:position_x>
    float inputs:autopilot_position_z.connect = </Roadster.outputs:position_z>
    float inputs:autopilot_yaw.connect = </Roadster.outputs:yaw>
    float inputs:autopilot_yaw_rate.connect = </Roadster.outputs:angvel_y>
    float inputs:piloted.connect = </Roadster.outputs:piloted>
    float inputs:wheelbase = 2.75
    float inputs:track = 1.72
    float inputs:max_heading = 0.45
    float inputs:force_local_z.connect = </Roadster.outputs:force_local_z>
    float inputs:force_local_y.connect = </Roadster.outputs:force_local_y>
    float inputs:force_local_x.connect = </Roadster.outputs:force_local_x>
    float inputs:force_x.connect = </Roadster.outputs:force_x>
    float inputs:force_y.connect = </Roadster.outputs:force_y>
    float inputs:force_z.connect = </Roadster.outputs:force_z>
    float inputs:torque_x.connect = </Roadster.outputs:torque_x>
    float inputs:torque_y.connect = </Roadster.outputs:torque_y>
    float inputs:torque_z.connect = </Roadster.outputs:torque_z>
    float inputs:initial_fill = 1
    float inputs:mass.connect = </Roadster.outputs:vehicle_mass_kg>
    float inputs:inertia_xx.connect = </Roadster.outputs:vehicle_inertia_xx>
    float inputs:inertia_yy.connect = </Roadster.outputs:vehicle_inertia_yy>
    float inputs:inertia_zz.connect = </Roadster.outputs:vehicle_inertia_zz>
    float outputs:drive_left
    float outputs:drive_right
    float outputs:heading_fl
    float outputs:heading_fr
    float outputs:soc
    float outputs:temperature_k
    float outputs:impulse_remaining
    float outputs:thruster_force
    float outputs:battery_power
    float outputs:gas_mass_kg
    float outputs:tank_pressure_pa
    float outputs:jet_force_x
    float outputs:jet_force_y
    float outputs:jet_force_z
    float outputs:vehicle_mass_kg
    float outputs:vehicle_inertia_xx
    float outputs:vehicle_inertia_yy
    float outputs:vehicle_inertia_zz
    float outputs:tank_temperature_k
    float outputs:tank_volume_m3
    def "Controls" (prepend references = @lunco://vessels/control_profiles.usda@</RoverControls>) {
        def "thrust" { uniform string lunco:port = "thrust_z" uniform double lunco:factor = 1 }
        def "release" { uniform string lunco:port = "thrust_z" uniform double lunco:factor = -1 }
        def "yaw_left" { uniform string lunco:port = "thrust_x" uniform double lunco:factor = -1 }
        def "yaw_right" { uniform string lunco:port = "thrust_x" uniform double lunco:factor = 1 }
        def "speed_boost" { uniform string lunco:port = "thrust_y" uniform double lunco:factor = 1 }
        def "action" { uniform string lunco:port = "thrust_y" uniform double lunco:factor = -1 }
    }
    def Xform "GroundSeal" (prepend references = @lunco://vessels/sensors/altimeter.usda@</Altimeter>) {
        double3 xformOp:translate = (0,-0.3,0)
        uniform token[] xformOpOrder = ["xformOp:translate"]
        float lunco:raycast:maxDistance = 2
        over "Model" (active = false) {}
        over "Beam" (active = false) {}
    }
    def Camera "DriverCamera" (prepend references = @lunco://components/cameras/rover_front_camera.usda@</FrontCamera>) {
        double3 xformOp:translate = (-0.37,0.82,-0.80)
        double3 lunco:cameraLookAt = (-0.37,0.55,-20)
        float focalLength = 21
        float2 clippingRange = (0.05,10000)
    }
    def Camera "ChaseCamera" (prepend references = @lunco://components/cameras/rover_front_camera.usda@</FrontCamera>) {
        double3 xformOp:translate = (3.8,2.7,7.8)
        double3 lunco:cameraLookAt = (0,0.10,-0.8)
        float focalLength = 24
        float2 clippingRange = (0.05,10000)
    }
    def Xform "Body" (prepend references = @../components/body.usda@</Body>) {}
'''
    outputs = ['torque_left','torque_right','freewheel_torque','force_local_z','force_local_y','force_local_x','force_x','force_y','force_z','torque_x','torque_y','torque_z','forward_speed',
               'battery_power','soc','temperature_k','impulse_remaining','thruster_force','downforce',
               'speed_mps','speed_kmh','speed_mph','pressure_bar','charge_percent',
               'boost_force_kn','lift_force_kn','yaw_force_kn','suction_force_kn','air_discharge_enabled']
    text += ''.join(f'    float outputs:{name}\n' for name in outputs if name not in ['battery_power','soc','temperature_k','impulse_remaining','thruster_force','forward_speed'])
    for i, (name,x,z) in enumerate([('FL',-.86,-1.375),('FR',.86,-1.375),('RL',-.86,1.375),('RR',.86,1.375)]):
        width = .25 if i < 2 else .30
        drive = 'float inputs:drive.connect = </Roadster.outputs:freewheel_torque>' if i < 2 else f'float inputs:drive.connect = </Roadster.outputs:torque_{"left" if i==2 else "right"}>'
        heading = f'float inputs:heading.connect = </Roadster.outputs:heading_{name.lower()}>' if i < 2 else 'float inputs:heading = 0'
        text += f'''    def Cylinder "Wheel_{name}" (
        prepend apiSchemas = ["PhysxVehicleWheelAttachmentAPI", "PhysxVehicleWheelAPI"]
        prepend references = [@lunco://components/mobility/wheel.usda@</Wheel>, @lunco://components/mobility/suspensions/standard.usda@</Suspension>]
        prepend variantSets = ["tire"]
        variants = {{ string tire = "road" }}
    ) {{
        double3 xformOp:translate = ({x},-0.21,{z})
        uniform token[] xformOpOrder = ["xformOp:translate"]
        double radius = 0.34
        double height = {width}
        float physxVehicleWheel:radius = 0.34
        float physxVehicleWheel:width = {width}
        float physxVehicleWheel:mass = 24
        float physxVehicleWheel:moi = 1.4
        float physxVehicleWheel:dampingRate = 0.08
        float physxVehicleWheel:maxBrakeTorque = 4000
        int physxVehicleWheelAttachment:index = {i}
        float lunco:suspension:restLength = 0.43
        float physxVehicleSuspension:springStrength = 100000
        float physxVehicleSuspension:springDamperRate = 8000
        {drive}
        {heading}
        variantSet "tire" = {{ "road" (prepend references = @../components/road_tire.usda@</RoadTire>) {{}} }}
        over "SuspensionCasing" {{ token visibility = "invisible" }}
        over "SuspensionPiston" {{ token visibility = "invisible" }}
        over "SuspensionSpring" {{ token visibility = "invisible" }}
    }}\n'''
    text += '''    variantSet "trim" = {
        "Performance" {
            float inputs:boost_available = 0
            float inputs:lift_available = 0
            float inputs:gas_capacity_kg = 250
        }
        "Thrust" {
            float inputs:boost_available = 1
            float inputs:gas_capacity_kg = 250
            def Xform "RearThrusters" (prepend references = @../components/RearThrusters.usda@</RearThrusters>) {
                over "Jet0" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
                over "Jet1" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
                over "Jet2" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
                over "Jet3" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
            }
        }
        "Rocket" {
            float inputs:boost_available = 1
            float inputs:lift_available = 1
            float inputs:gas_capacity_kg = 250
            over "Body" { over "PassengerSeat" { token visibility = "invisible" } }
            def Xform "RearThrusters" (prepend references = @../components/RearThrusters.usda@</RearThrusters>) {
                over "Jet0" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
                over "Jet1" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
                over "Jet2" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
                over "Jet3" { float inputs:force.connect = </Roadster.outputs:jet_force_z> }
            }
            def Xform "PerimeterThrusters" (prepend references = @../components/PerimeterThrusters.usda@</PerimeterThrusters>) {
                over "Jet0" { float inputs:force.connect = </Roadster.outputs:jet_force_y> }
                over "Jet1" { float inputs:force.connect = </Roadster.outputs:jet_force_y> }
                over "Jet2" { float inputs:force.connect = </Roadster.outputs:jet_force_y> }
                over "Jet3" { float inputs:force.connect = </Roadster.outputs:jet_force_y> }
                over "Jet4" { float inputs:force.connect = </Roadster.outputs:jet_force_x> }
                over "Jet5" { float inputs:force.connect = </Roadster.outputs:jet_force_x> }
            }
        }
    }
}
'''
    (ROOT/'vehicles/roadster.usda').write_text(text)


def scene(filename, trim, launch=False):
    text = HEADER % 'World' + '''def Xform "World" (kind = "assembly") {
    def PhysicsScene "PhysicsScene" {
        vector3f physics:gravityDirection = (0,-1,0)
        float physics:gravityMagnitude = 9.80665
    }
    def DistantLight "Sun" (prepend references = @lunco://lighting/sun.usda@</Sun>) {
        float inputs:intensity = 128000
        color3f inputs:color = (1,0.95,0.87)
        double3 xformOp:rotateXYZ = (-42,135,0)
        uniform token[] xformOpOrder = ["xformOp:rotateXYZ"]
    }
    def DomeLight "Fill" {
        float inputs:intensity = 700
        color3f inputs:color = (0.55,0.68,0.85)
    }
    def Material "AsphaltContact" (prepend apiSchemas = ["PhysicsMaterialAPI"]) {
        float physics:staticFriction = 1.4
        float physics:dynamicFriction = 1.4
        float physics:restitution = 0
    }
    def Cube "Ground" (prepend apiSchemas = ["PhysicsCollisionAPI", "LunCoTerrainAPI", "MaterialBindingAPI"]) {
        double size = 1
        double3 xformOp:translate = (0,-0.5,0)
        double3 xformOp:scale = (100000,1,100000)
        uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:scale"]
        color3f[] primvars:displayColor = [(0.15,0.18,0.17)]
        bool physics:collisionEnabled = true
        rel material:binding:physics = </World/AsphaltContact>
    }
'''
    text += cube('Runway', (0,.006,-500), (16,.012,2600), (.065,.075,.09))
    for x in (-7.6,7.6):
        text += cube('Edge'+('L' if x<0 else 'R'), (x,.017,-500), (.12,.008,2600), (.9,.92,.94))
    text += cube('StartLine', (0,.025,-3), (15,.008,.22), (.95,.95,.94))
    for i in range(42):
        text += cube(f'Marker{i}', (0,.025,-10-i*20), (.10,.008,8), (.7,.73,.75))
    text += f'''    def Xform "Roadster" (
        prepend references = @../vehicles/roadster.usda@</Roadster>
        variants = {{ string trim = "{trim}" }}
    ) {{
        double3 xformOp:translate = (0,0.66,0)
        uniform token[] xformOpOrder = ["xformOp:translate"]
    }}
    def Camera "Avatar" (prepend apiSchemas = ["LunCoCameraAPI", "LunCoAvatarAPI"]) {{
        uniform bool lunco:avatar = true
        double3 xformOp:translate = (4.8,2.4,6.5)
        double3 lunco:cameraLookAt = (0,0.65,0)
        uniform token[] xformOpOrder = ["xformOp:translate"]
        float focalLength = 40
        float2 clippingRange = (0.05,10000)
        def "Controls" (prepend references = @lunco://vessels/control_profiles.usda@</AvatarControls>) {{}}
    }}
'''
    if launch:
        text += '''    def Scope "Scenario" {
        def Scope "Launch" (prepend apiSchemas = ["LunCoProgramAPI"]) {
            uniform token info:implementationSource = "sourceAsset"
            uniform asset info:sourceAsset = @../scenarios/tests/launch.rhai@
        }
    }
'''
    else:
        text += '''    def Scope "DriverSetup" (prepend apiSchemas = ["LunCoProgramAPI"]) {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:sourceAsset = @../scenarios/driver_setup.rhai@
    }
'''
    (ROOT/f'scenes/{filename}.usda').write_text(text+'}\n')


if __name__ == '__main__':
    body()
    tires()
    nozzles('RearThrusters', [(x,-.12,2.20) for x in (-.55,-.2,.2,.55)])
    nozzles('PerimeterThrusters', [(x,-.32,z,'Y') for x in (-.8,.8) for z in (-1.5,1.5)] +
        [(-.96,-.1,-1.7,'X'),(.96,-.1,-1.7,'X')])
    vehicle()
    scene('roadster_track','Performance')
    scene('roadster_thrust','Thrust')
    scene('roadster_rocket','Rocket')
    scene('roadster_launch','Thrust',launch=True)
    scene('roadster_motor_launch','Rocket',launch=True)
    p=ROOT/'scenes/roadster_motor_launch.usda'
    p.write_text(p.read_text().replace('../scenarios/tests/launch.rhai','../scenarios/tests/motor_launch.rhai'))
    print('Authored body, tire, thrusters, vehicle and five scenes.')
