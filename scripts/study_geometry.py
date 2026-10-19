"""Dimensioned Roadster study mounts, not manufacturer CAD."""
MOUNTS = dict(lift_front_z=-.90,lift_rear_z=1.85,lift_x=.8,lift_y=-.32,
              rear_jet_y=-.14,rear_jet_z=2.30,side_jet_y=-.1,side_jet_z=-1.90,
              mass_center_y=-.14,mass_center_z=0.0)

def thruster_stations():
    return ([(x,MOUNTS['rear_jet_y'],MOUNTS['rear_jet_z']) for x in (-.55,-.2,.2,.55)],
            [(x,MOUNTS['lift_y'],z,'Y') for x in (-MOUNTS['lift_x'],MOUNTS['lift_x'])
             for z in (MOUNTS['lift_front_z'],MOUNTS['lift_rear_z'])]+
            [(x,MOUNTS['side_jet_y'],MOUNTS['side_jet_z'],'X') for x in (-.96,.96)])
