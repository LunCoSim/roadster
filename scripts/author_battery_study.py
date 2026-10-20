#!/usr/bin/env python3
"""Publish Modelica battery assumptions and correct the Thrust storage variant."""
from author_surface_probes import q, ROOT, await_doc

OUTPUTS = ['battery_'+name for name in [
    'nominal_energy_kwh','range_energy_kwh','range_proxy_km','inferred_capacity_kwh',
    'pack_mass_estimate_kg','pack_volume_estimate_l','non_pack_reference_mass_kg',
    'peak_dc_power_kw','peak_equivalent_c','charge_10_80_energy_kwh',
    'charge_10min_average_kw','charge_12min_average_kw','energy_remaining_kwh']]+['gas_capacity_mass_kg']

def main():
    q('OpenFile',path=str(ROOT/'vehicles/roadster.usda'))
    doc=await_doc(lambda d:'/vehicles/roadster.usda' in str(d))
    ops=[]
    def attr(path,name,kind,value):
        ops.append({'SetAttribute':dict(edit_target='@root@',path=path,name=name,type_name=kind,value=value)})
    attr('/Roadster','inputs:battery_capacity_kwh','float','120')
    for name in OUTPUTS:attr('/Roadster','outputs:'+name,'double','0')
    ops.append({'SetAttributeDocumentation':dict(edit_target='@root@',path='/Roadster',
        name='inputs:battery_capacity_kwh',documentation='120 kWh study assumption from >100 kWh reporting and 300-mile sizing. Editable preparation parameter. BatteryStudy computes mass/inertia deltas from a 120 kWh / 1700 kg reference. See references/battery-study.md. Not a Tesla capacity specification.')})
    # Local opinions are stronger than variants (USD LIVRPS). Move the
    # defaults into each variant so Thrust's cabin=0 can actually compose.
    for name in ['rear_tank_volume','cabin_tank_volume']:
        ops.append({'RemoveAttribute':dict(edit_target='@root@',path='/Roadster',name='inputs:'+name)})
    for trim,cabin in [('Performance','0.4'),('Rocket','0.4'),('Thrust','0')]:
        attr('/Roadster{trim='+trim+'}','inputs:rear_tank_volume','float','0.2')
        attr('/Roadster{trim='+trim+'}','inputs:cabin_tank_volume','float',cabin)
    attr('/Roadster','inputs:reference_gas_mass_kg','float','250')
    attr('/Roadster','inputs:reference_storage_volume_m3','float','0.6')
    for trim in ['Performance','Thrust','Rocket']:
        ops.append({'RemoveAttribute':dict(edit_target='@root@',path='/Roadster{trim='+trim+'}',name='inputs:gas_capacity_kg')})
    q('ApplyUsdOps',doc_id=doc,ops=ops)
    q('SaveDocument',doc_id=doc)
    result=q('InspectUsdDocument',doc_id=doc,path='/Roadster')
    assert all('outputs:'+n in {a['name'] for a in result['prim']['attributes']} for n in OUTPUTS)
    q('CloseDocument',doc_id=doc)
    print('Saved battery parameters/observations and 200 L Thrust storage through USD journal.')
if __name__=='__main__':main()
