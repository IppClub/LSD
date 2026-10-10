#!/usr/bin/env python3
"""Non-production reaction candidates on the original researcher rig.
Keep source images, mesh weights, constraints and authored locomotion unchanged.
"""
from pathlib import Path
import copy
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Docs/artwork/researcher/source-export/shujuyuan.json'
OUT = ROOT / 'Docs/artwork/researcher/actions.json'
data = json.loads(SOURCE.read_text())
original = copy.deepcopy(data)

def rotation(times, values):
    frames = []
    for i, (time, value) in enumerate(zip(times, values)):
        frame = {'time': time, 'value': value}
        if i + 1 < len(times):
            dt = times[i + 1] - time
            frame['curve'] = [time + dt / 3, value, times[i + 1] - dt / 3, values[i + 1]]
        frames.append(frame)
    return frames

# Body reaction is above the hips; ground contacts retain the source IK.
# The tablet stays in the same hand and retains its authored mesh and slot order.
times = [0, .07, .16, .29, .46, .64]
recoil = {
    'bone3': [0, -3, -12, -8, 2, 0],
    'bone4': [0, -2, -7, -5, 1, 0],
    'bone6': [0, 0, 8, 5, -2, 0],
    'bone8': [0, 2, 9, 6, -2, 0],
    'bone9': [0, 0, -12, -8, 2, 0],
    'bone12': [0, 2, 7, 5, -1, 0],
    'bone13': [0, 0, -8, -5, 1, 0],
    'bone31': [0, 0, 5, 9, -3, 0],
    'bone36': [0, 0, -4, -8, 2, 0],
}
# Source faces right: positive torso rotation recoils away from an attacker on the right.
for bone in ('bone3', 'bone4', 'bone6'):
    recoil[bone] = [-value for value in recoil[bone]]
data['animations']['hit'] = {'bones': {bone: {'rotate': rotation(times, values)} for bone, values in recoil.items()}}
# A subdued, breathing pose for the interrogation. This is not a knock-out pose.
held = {'bone3': [5, 6, 5], 'bone4': [3, 4, 3], 'bone6': [-10, -11, -10],
        'bone8': [-4, -5, -4], 'bone9': [7, 8, 7], 'bone12': [3, 4, 3],
        'bone13': [-5, -6, -5], 'bone31': [2, 3, 2], 'bone36': [-2, -3, -2]}
for bone in ('bone3', 'bone4', 'bone6'):
    held[bone] = [-value for value in held[bone]]
data['animations']['restrained'] = {'bones': {bone: {'rotate': rotation([0, 1, 2], values)} for bone, values in held.items()}}
# Knock-out candidate: delayed torso/head response, folding legs and hands,
# then a side-lying hold. Existing eye-only bones compress the eye meshes;
# no replacement pixels or edits to the original images are involved.
fall_times = [0, .12, .3, .55, .8, 1.02, 1.35]
fall = {
    'root': [0, -5, 12, 45, 83, 89, 88],
    'bone3': [-5, 12, -8, -18, -12, -9, -10],
    'bone4': [-3, 6, 8, 14, 10, 8, 8],
    'bone6': [10, -12, 6, 0, -14, -19, -18],
    'bone15': [0, 0, 8, 20, 28, 28, 28],
    'bone16': [0, 0, -8, -32, -46, -44, -44],
    'bone17': [0, 0, 3, 8, 12, 12, 12],
    'bone18': [0, 0, -4, 5, 12, 12, 12],
    'bone19': [0, 0, -6, -26, -36, -35, -35],
    'bone20': [0, 0, 2, 7, 10, 10, 10],
    'bone8': [-4, 5, 16, 28, 34, 31, 31],
    'bone9': [7, -8, -20, -38, -48, -45, -45],
    'bone12': [3, -5, -10, -20, -25, -24, -24],
    'bone13': [-5, 8, 24, 45, 58, 55, 55],
    'bone31': [2, 1, -8, -15, 12, 4, 6],
    'bone36': [-2, -1, 5, 12, -8, -2, -3],
}
# Native mesh contact fit is a pose proposal, reviewed in the offscreen render.
# It changes joint rotations only; the mesh and bone lengths stay untouched.
landing_fit = json.loads((ROOT / 'Docs/artwork/researcher/landing-fit.json').read_text())
for bone, target in landing_fit.items():
    values = fall.setdefault(bone, [0] * len(fall_times))
    correction = target - values[-1]
    fall[bone] = [value + correction * weight for value, weight in zip(values, [0, 0, 0, .35, .8, 1, 1])]
fall_bones = {bone: {'rotate': rotation(fall_times, values)} for bone, values in fall.items()}
for bone in ('bone34', 'bone35'):
    fall_bones[bone] = {'scale': [{'x': 1, 'y': 1}, {'time': .18, 'x': 1, 'y': .08}, {'time': 1.35, 'x': 1, 'y': .08}]}
fall_ik = {c['name']: [{'mix': 1}, {'time': .3, 'mix': 0}, {'time': 1.35, 'mix': 0}] for c in data['constraints']}
data['animations']['knockout'] = {'bones': fall_bones, 'ik': fall_ik}
rest_bones = {bone: {'rotate': rotation([0, 1.2, 2.4], [values[-1], values[-1] + (.35 if bone in ('bone3', 'bone4') else 0), values[-1]])} for bone, values in fall.items()}
for bone in ('bone34', 'bone35'):
    rest_bones[bone] = {'scale': [{'x': 1, 'y': .08}, {'time': 2.4, 'x': 1, 'y': .08}]}
data['animations']['unconscious'] = {'bones': rest_bones, 'ik': {c['name']: [{'mix': 0}, {'time': 2.4, 'mix': 0}] for c in data['constraints']}}
# Optional native bounds pass bakes root-height correction at 120 Hz. This
# prevents geometric floor penetration; it does not prove natural contact.
import csv, hashlib, sys
raw_export = '--raw' in sys.argv
ground_hashes = json.loads((ROOT / 'Docs/artwork/researcher/ground-correction-source.json').read_text())
for name in ('knockout', 'unconscious'):
    bounds_path = ROOT / ('Docs/artwork/researcher/' + name + '-uncorrected-bounds.csv')
    if not raw_export and bounds_path.exists():
        digest = hashlib.sha256(json.dumps(data['animations'][name], sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        assert ground_hashes.get(name) == digest, 'Ground correction is stale; regenerate raw bounds for ' + name
        rows = list(csv.DictReader(bounds_path.open()))
        data['animations'][name]['bones']['root']['translate'] = [
            {'time': float(row['time']), 'x': 0, 'y': -float(row['y'])} for row in rows]
for key in ('bones', 'slots', 'constraints', 'skins'):
    assert data[key] == original[key], key
for name, animation in original['animations'].items():
    assert data['animations'][name] == animation, name
# Mouth attachment is derived from the original head mesh UV, parented to head.
mouth = json.loads((ROOT / 'Docs/artwork/researcher/mouth-point.json').read_text())
data['slots'].append({'name': 'contact:mouth', 'bone': 'bone6'})
data['skins'][0]['attachments']['contact:mouth'] = {'mouth': {'type': 'point', 'x': mouth['x'], 'y': mouth['y']}}
OUT.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n')
print('Built hit (0.64s), restrained (2s), knockout (1.35s), unconscious (2.4s); original rig and animations preserved.')
