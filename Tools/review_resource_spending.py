"""Inspect a frozen combat source; observational diagnostic, never training data."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source', type=Path)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
raw = args.source.read_bytes()
episode = json.loads(raw)['episode']
costs = episode['resourceCosts']
steps = {str(step['id']): step for step in episode['steps']}
rows = {}
for step_id, charge in costs['byStep'].items():
    step = steps[step_id]
    action = step['action']
    key = action['actor'] + ':' + action['weapon']
    row = rows.setdefault(key, dict(chargedActions=0, consumption=0, units=0,
        effectiveHealth=0, effectiveArmor=0, noObservedContribution=0,
        noObservedContributionCost=0, incompleteActions=0))
    row['chargedActions'] += 1
    row['consumption'] += charge['cost']
    row['units'] += charge['count']
    hits = [hit for hit in step.get('hits', []) if hit.get('relation') != 'friendly']
    hp = sum(hit.get('credit', {}).get('health', 0) for hit in hits)
    ap = sum(hit.get('credit', {}).get('armor', 0) for hit in hits)
    row['effectiveHealth'] += hp
    row['effectiveArmor'] += ap
    incomplete = step.get('truncated', False) or not step.get('sealed', False)
    row['incompleteActions'] += int(incomplete)
    if hp + ap == 0:
        row['noObservedContribution'] += 1
        row['noObservedContributionCost'] += charge['cost']
assert sum(row['consumption'] for row in rows.values()) + costs['deployment'] + costs['unattributed'] == costs['total']
report = dict(schemaVersion=1, trainable=False, source=str(args.source),
    sourceSha256=hashlib.sha256(raw).hexdigest(), total=costs['total'],
    deployment=costs['deployment'], unattributed=costs['unattributed'], actors=rows,
    caveat='No observed credited HP/AP is not proof of a miss or avoidable waste; interrupted actions, contribution caps, and other effects require review. This does not reconstruct decision transitions.')
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(report, ensure_ascii=False))
