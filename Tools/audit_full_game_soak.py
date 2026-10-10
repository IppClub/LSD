"""Audit terminal diagnostic soak evidence without accepting the whole game.

The QA checkpoint reload may clear root Cleanup slots. Its memory counters do
not establish production leak freedom; OS play and all endings remain separate.
"""
import argparse
import hashlib
import json
from pathlib import Path
from audit_soak_branches import audit_stage


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--raw', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--fixtures-root', type=Path, default=Path(__file__).resolve().parents[1] / 'Test')
    args = parser.parse_args()
    run = json.loads((args.raw / 'run.json').read_text())
    assert run['status'] == 'PASS', 'Terminal PASS evidence required; do not audit a live run as accepted'
    result = json.loads((args.raw / 'result.json').read_text())
    assert run['status'] == result['status'] == 'PASS', 'Terminal PASS evidence required'
    assert run['runtimeErrorCount'] == 0 and run['gameSourcesUnchanged']
    assert result['sameNativeProcess'] and result['targetSeconds'] >= 1800
    assert result['elapsed'] >= result['targetSeconds'] and result['mode'] == 'long-soak'
    assert not result['osInput'] and not result['injectsCombatState']
    assert result['checkpointBranches'] and not result['fullGameComplete']
    package = Path(run['package']['root'])
    game = Path(run['package']['gameRoot'])
    manifest = json.loads((package / 'package-manifest.json').read_text())
    assert len(manifest['files']) == run['packageIsolation']['filesVerifiedAfter'] == 2777
    assert run['packageIsolation']['verified']
    for item in manifest['files']:
        path = package / item['path']
        assert path.stat().st_size == item['bytes'] and sha(path) == item['sha256'], path
    assert len(run['luaSources']) == 409
    for name, checksum in run['luaSources'].items():
        assert sha(game / name) == checksum, name
    fixture = args.fixtures_root / 'FullGameSoakNative.lua'
    assert sha(fixture) == run['testSha256'], 'Active soak fixture changed'
    formal = Path('/Users/Jin/Workspace/Dora/lsd.db')
    assert formal.stat().st_size == 12288
    assert sha(formal) == '760372bda8ae788c451e95bc169ccddd6b5837cee36fe9101b330efd4f7e3d39'
    sequence = ['FreshGroundCurrentNative', 'FreshFactoryCurrentNative', 'FreshChapterThreeCurrentNative', 'FreshEndingCurrentNative']
    cycles = result['cycles']
    assert len(cycles) == result['completedCycles'] and len(result['stages']) == len(cycles) * 4
    parents = [json.loads(Path(p).read_text()) for p in result['parentResults']]
    assert all(p['status'] == 'PASS' and p['sameJourney'] for p in parents)
    audits = []
    for cycle in cycles:
        branches = [s for s in result['stages'] if s['cycle'] == cycle['index']]
        assert [s['test'] for s in branches] == sequence
        assert branches[0]['source'] == parents[0]['database']
        assert branches[1]['source'] == parents[1]['database']
        assert branches[2]['source'] == branches[1]['database']
        assert branches[3]['source'] == branches[2]['database']
        for branch in branches:
            child_fixture = Path(run['workDirectory']) / 'save' / f"child-{cycle['index']}-{branch['test']}.lua"
            current = fixture.parent / (branch['test'] + '.lua')
            assert sha(child_fixture) == sha(current), child_fixture
            audits.append(audit_stage(branch))
    frames = result['frames']
    assert frames['count'] > 0 and abs(frames['count'] * frames['mean'] - result['elapsed']) < 1
    assert frames['p95'] <= frames['p99'] <= frames['max'] + .0001
    assert len(frames['slowFrames']) == min(100, frames['over33ms'])
    assert all(f['dt'] > 1 / 30 and 0 <= f['at'] <= result['elapsed'] for f in frames['slowFrames'])
    rss = json.loads((args.raw / 'rss.json').read_text())
    assert rss['pid'] == run['pid'] and len(rss['samples']) > result['elapsed'] * .8
    samples = rss['samples']
    assert samples[-1]['elapsed'] >= result['elapsed'] - 3
    assert all(a['elapsed'] < b['elapsed'] for a, b in zip(samples, samples[1:]))
    trend = []
    for cycle in cycles:
        near = min(samples, key=lambda s: abs(s['elapsed'] - cycle['elapsed']))
        trend.append(dict(cycle, nearestExternalRSS=near))
    flat = {name: len({c[name] for c in cycles}) == 1 for name in ['objects', 'luaRefs', 'callRefs']}
    output = dict(status='PASS_DIAGNOSTIC_LONG_SOAK_EVIDENCE', package=str(package), seconds=result['elapsed'], cycles=len(cycles), stages=len(audits), paidBills=sum(len(a['bills']) for a in audits), branchAudits=audits, frames=frames, resourceTrend=trend, countersFlat=flat, retainedSceneWorldsAllReleased=all(c['retainedSceneWorlds'] == 0 for c in cycles), externalRSSSamples=len(samples), externalRSSPeakKB=max(s['rssKB'] for s in samples), frozenFiles=2777, frozenScriptLua=409, formalSaveUnchanged=True, qaRootCleanupReset=result['qaRootCleanupReset'], productionLeakAccepted=False, osPlayAccepted=False, allOriginalEndingsAccepted=False, fullGameComplete=False)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: v for k, v in output.items() if k not in ['branchAudits', 'frames', 'resourceTrend']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
