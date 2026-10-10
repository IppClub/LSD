#!/usr/bin/env python3
"""Author cover gestures on Wuyun's own rig; preserve all original artwork."""
import copy
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'Docs/artwork/interrogation/wuyun'
data = json.loads((BASE / 'source-export/wuyun.json').read_text())
# The editor reads packed-resolution PNGs and replaces region dimensions.
# Restore physical size through attachment scale before the next import/export.
# Mesh vertices already carry their authored coordinates and must not be scaled.
for region in json.loads((BASE / 'original-regions.json').read_text()):
    skin = next(s for s in data['skins'] if s['name'] == region['skin'])
    attachment = skin['attachments'][region['slot']][region['attachment']]
    attachment['scaleX'] = region['scaleX'] * region['width'] / attachment['width']
    attachment['scaleY'] = region['scaleY'] * region['height'] / attachment['height']
source = copy.deepcopy(data)
idle = data['animations']['idle']
fit = json.loads((BASE / 'hand-fit.json').read_text())['rotations']

def at_zero(node):
    if isinstance(node, list):
        # Timelines starting later must retain their setup pose at t=0.
        if not node or node[0].get('time', 0) > 0:
            return []
        key = copy.deepcopy(node[0])
        key.pop('curve', None)
        key.pop('time', None)
        return [key]
    return {k: v for k, child in node.items() if (v := at_zero(child))}

base = at_zero(idle)

def rotate(times, values):
    keys = []
    for i, (t, v) in enumerate(zip(times, values)):
        key = {'time': t, 'value': v}
        if i + 1 < len(times):
            dt = times[i + 1] - t
            key['curve'] = [t + dt / 3, v, times[i + 1] - dt / 3, values[i + 1]]
        keys.append(key)
    return keys

for name, duration, start_weight, end_weight in (
    ('coverReach', .55, 0, 1), ('coverHold', 2, 1, 1), ('coverRelease', .4, 1, 0)):
    anim = copy.deepcopy(base)
    for bone, target in fit.items():
        tracks = anim['bones'].setdefault(bone, {})
        initial = tracks.get('rotate', [{}])[0].get('value', 0)
        tracks['rotate'] = rotate([0, duration], [initial + (target-initial)*start_weight, initial + (target-initial)*end_weight])
    if name == 'coverHold':
        # Preserve authored blinking without moving the calibrated palm.
        anim['slots'] = copy.deepcopy(idle['slots'])
        anim['attachments'] = copy.deepcopy(idle['attachments'])
    data['animations'][name] = anim
assert all(data[k] == source[k] for k in source if k != 'animations')
assert all(data['animations'][k] == v for k, v in source['animations'].items())
(BASE / 'actions.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')))
print('Created coverReach 0.55s, coverHold 2s, coverRelease 0.4s; original rig and animations preserved.')
