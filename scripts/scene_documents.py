"""Save Roadster fixture documents with portable Twin asset identities."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def save_scene_as(query, doc_id, destination):
    """Keep authored dependencies anchored before changing a scene's directory."""
    document = query('InspectUsdDocument', doc_id=doc_id)
    source = Path(document['origin']['File']['path'])
    namespace = 'twin://tesla-roadster-runner/'
    rewritten = set()
    operations = []

    def identity(asset):
        if not asset or '://' in asset or asset.startswith('/'):
            return asset
        rewritten.add(asset)
        return namespace + (source.parent / asset).resolve().relative_to(ROOT).as_posix()

    for path in ['/World', '/World/Roadster', '/World/EarthSky/Look/Shader',
                 '/World/DriverSetup', '/World/Scenario/Launch', '/World/CourseRuntime/Program']:
        prim = query('InspectUsdDocument', doc_id=doc_id, path=path)['prim']
        for attribute in prim['attributes']:
            if attribute['type'] != 'asset' or not attribute['authored']['root']:
                continue
            old = attribute['value'].strip('@')
            new = identity(old)
            if new != old:
                operations.append({'SetAttribute': dict(edit_target='@root@', path=path,
                    name=attribute['name'], type_name='asset', value='@' + new + '@')})
        references = prim['references']['authored']['root']
        for key, kind in [('explicit_items', 'Explicit'), ('prepended_items', 'Prepend'),
                          ('appended_items', 'Append'), ('added_items', 'Add'),
                          ('deleted_items', 'Delete')]:
            items = references.get(key, [])
            updated = [dict(item, asset_path=identity(item['asset_path'])) for item in items]
            if updated != items:
                operations.append({'SetReferenceArcs': dict(edit_target='@root@', path=path,
                    references=updated, list_op=kind)})
    relative = {asset for asset in document['composition']['dependencies']
                if asset and '://' not in asset and not asset.startswith('/')}
    if rewritten != relative:
        raise RuntimeError(f'Unmapped authored Roadster dependencies: {relative - rewritten}')
    if operations:
        query('ApplyUsdOps', doc_id=doc_id, parent_gen=document['generation'],
              label='Anchor Roadster scene dependencies to the Twin', ops=operations)
    query('SaveAsDocument', doc_id=doc_id, path=str(destination))
