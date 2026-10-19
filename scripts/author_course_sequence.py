#!/usr/bin/env python3
"""Author course observations and discrete controller edges through USD tools."""
from author_surface_probes import q, ROOT, await_doc
import argparse

FIELDS = ['forward','reverse','left','right','boost','brake','lift','fan',
          'pitch_up','pitch_down','yaw_left','yaw_right','roll_left','roll_right']

OBSERVATIONS = ['course_takeoff_gate','course_jump_impulse_ready','course_air_pitch_degrees','course_landing_impact_speed','course_step','course_roll_gate','course_yaw_gate',
                'course_air_yaw_degrees','course_air_roll_degrees',
                'course_backward_distance_m','course_forward_speed','course_forward_z',
                'pilot_yaw_direction','course_mid_yaw_gate']

def main(observations_only=False):
    q('OpenFile', path=str(ROOT/'vehicles/roadster.usda'))
    doc = await_doc(lambda d: '/vehicles/roadster.usda' in str(d))
    inspected = q('InspectUsdDocument', doc_id=doc, path='/Roadster')
    assert inspected['prim']['exists']
    ops = []
    def attr(path, name, kind, value):
        ops.append({'SetAttribute': dict(edit_target='@root@', path=path,
                    name=name, type_name=kind, value=value)})
    def connect(path, name, source, kind='float'):
        ops.append({'SetConnection': dict(edit_target='@root@', path=path,
                    name=name, type_name=kind, sources=[source])})
    attr('/Roadster','inputs:course_jump_timing_offset_s','double','0')
    attr('/Roadster','inputs:course_turn_direction','double','1')
    for name in OBSERVATIONS:
        attr('/Roadster','outputs:'+name,'double','0')
    if observations_only:
        q('ApplyUsdOps',doc_id=doc,ops=ops)
        q('SaveDocument',doc_id=doc)
        saved=q('InspectUsdDocument',doc_id=doc,path='/Roadster')
        names={a['name'] for a in saved['prim']['attributes']}
        assert all('outputs:'+name in names for name in OBSERVATIONS)
        q('CloseDocument',doc_id=doc)
        print('Saved course observations through the USD journal.')
        return
    for name in ['course_action','course_autopilot_enable']:
        attr('/Roadster','inputs:'+name,'float','0')
    ops.append({'RemoveAttribute':dict(edit_target='@root@',path='/Roadster',name='outputs:position_y')})
    ops.append({'RemoveAttribute':dict(edit_target='@root@',path='/Roadster',name='inputs:course_position_y')})
    attr('/Roadster','inputs:course_position_y','double','0.66')
    for corner in ['fl','fr','rl','rr']:
        ops.append({'RemoveAttribute':dict(edit_target='@root@',path='/Roadster',name='inputs:course_contact_'+corner)})
    for name in ['course_autopilot_active','course_block_crossed','course_crest_gate',
                 'course_airborne_gate','course_healthy','landing_gate']:
        attr('/Roadster','outputs:'+name,'float','0')
    path = '/Roadster/CourseEvents'
    if not q('InspectUsdDocument',doc_id=doc,path=path)['prim']['exists']:
        ops.append({'AddPrim':dict(edit_target='@root@',parent_path='/Roadster',
                    name='CourseEvents',type_name='Scope',reference=None,reference_prim_path=None)})
    def event(name, port, event_name, duration=0.0):
        ops.append({'AddPrim':dict(edit_target='@root@',parent_path=path,name=name,
                    type_name='LunCoEvent',reference=None,reference_prim_path=None)})
        attr(path+'/'+name,'lunco:event:name','token','"'+event_name+'"')
        attr(path+'/'+name,'lunco:event:qualificationTime','double',str(duration))
        connect(path+'/'+name,'inputs:trigger','/Roadster.outputs:'+port)
    for name in FIELDS:
        for suffix in ['', '_on', '_off']:
            attr('/Roadster','outputs:pilot_'+name+suffix,'float','0')
        for edge in ['on','off']:
            event('Pilot_'+name+'_'+edge,'pilot_'+name+'_'+edge,'roadster.pilot.controls')
    if q('InspectUsdDocument',doc_id=doc,path=path+'/LandingQualified')['prim']['exists']:
        ops.append({'RemovePrim':dict(edit_target='@root@',path=path+'/LandingQualified')})
    q('ApplyUsdOps',doc_id=doc,ops=ops)
    q('SaveDocument',doc_id=doc)
    composed = q('InspectUsdDocument',doc_id=doc,path=path+'/Pilot_fan_off')
    assert composed['prim']['exists']
    q('CloseDocument',doc_id=doc)
    print('Saved shared Modelica control event edges. Author the native Y connection in the mounted course document.')

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--observations-only',action='store_true')
    main(parser.parse_args().observations_only)
