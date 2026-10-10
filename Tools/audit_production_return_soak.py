"""Read-only audit of the one-save original-result-return loop.

Running prefixes are explicitly partial. A finished loop is not all-mission,
actual OS, all-ending, or whole-game performance acceptance.
"""
import argparse
import hashlib
import json
import sqlite3
from pathlib import Path


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rows(conn, table):
    return conn.execute('SELECT * FROM "' + table + '" ORDER BY rowid').fetchall()


def lifecycle_observations(cycles, frames):
    """Describe measured retention without treating observer data as a leak test."""
    ranges = {}
    for key in ('objects', 'luaRefs', 'callRefs', 'retainedSceneWorlds', 'luaKB'):
        values = [cycle[key] for cycle in cycles]
        ranges[key] = dict(first=values[0], last=values[-1], minimum=min(values), maximum=max(values), delta=values[-1] - values[0])
    slow_by_stage = {}
    for frame in (frames or {}).get('slowFrames', []):
        stage = frame.get('stage', 'initial-load')
        item = slow_by_stage.setdefault(stage, dict(count=0, maximumSeconds=0))
        item['count'] += 1
        item['maximumSeconds'] = max(item['maximumSeconds'], frame['dt'])
    return dict(
        measuredRanges=ranges,
        retainedObserverReports=len(cycles),
        serializedObserverReportBytes=sum(len(json.dumps(cycle['report'], ensure_ascii=False).encode('utf-8')) for cycle in cycles),
        reportBytesAreLuaAllocationEstimate=False,
        slowFramesByStage=slow_by_stage,
        slowFrameListCappedAt=100,
        interpretation='The fixture retains every complete report and rewrites accumulated JSON. Lua growth cannot establish game leakage or memory stability; frame samples include observer work. Native counts and weak worlds describe only this mission loop.',
        productionMemoryAccepted=False,
    )


def audit(result, run, allow_running):
    assert result['startExecutions'] == result['dbAttachments'] == 1
    assert not result['qaSceneReset'] and not result['qaRootCleanupReset']
    assert not result['osInput'] and not result['fullGameComplete']
    finished = result['status'] == run['status'] == 'PASS'
    if not finished:
        assert allow_running and result['status'] == run['status'] == 'RUNNING'
    cycles = result['cycles']
    assert cycles, 'No completed original-return cycle yet'
    with sqlite3.connect(Path(result['source']).as_uri() + '?mode=ro', uri=True) as parent, sqlite3.connect(Path(result['database']).as_uri() + '?mode=ro', uri=True) as child:
        child.execute('BEGIN')  # Consistent snapshot while the game may write.
        assert child.execute('PRAGMA integrity_check').fetchall() == [('ok',)]
        names = [n for n, in parent.execute("SELECT name FROM sqlite_master WHERE type='table'")]
        models = [n for n in names if n.startswith(('Game0Training', 'Game0Target', 'Game0Flower'))]
        for name in models:
            assert rows(parent, name) == rows(child, name), name
        old_missions = rows(parent, 'Game0MissionAttempts')
        missions = rows(child, 'Game0MissionAttempts')
        old_supplies = rows(parent, 'Game0SupplyAttempts')
        supplies = rows(child, 'Game0SupplyAttempts')
        assert missions[:len(old_missions)] == old_missions
        assert supplies[:len(old_supplies)] == old_supplies
        assert child.execute("SELECT count(*) FROM sqlite_master WHERE type='trigger'").fetchone()[0] == 0
        added = {row[0]: row for row in supplies[len(old_supplies):]}
        bills = []
        wallet = parent.execute('SELECT available FROM Game0SupplyWallet').fetchone()[0]
        assert wallet == result['balanceBefore']
        for index, cycle in enumerate(cycles, 1):
            assert cycle['index'] == index and cycle['originalReturn']
            attempt = cycle['attempt']
            _, status, payload = added[attempt]
            data = json.loads(payload)
            mission = child.execute('SELECT * FROM Game0MissionAttempts WHERE id=?', (int(attempt.split(':')[1]),)).fetchone()
            economy = cycle['report']['economy']
            assert mission[1:3] == ('c0-disarm', 'won') and status == 'won'
            assert json.loads(mission[4]) == cycle['report'] and data['result'] == economy
            assert economy['cost'] == data['spent'] == sum(line['cost'] for line in economy['lines'])
            assert economy['reserved'] == data['quote']['total'] and economy['refund'] == economy['reserved'] - economy['cost']
            assert economy['net'] == economy['income'] - economy['cost']
            events = list(data['events'].values())
            for line in economy['lines']:
                stock = data['stock'][line['actor'] + ':' + line['item']]
                owned = [e for e in events if e['owner'] == line['actor'] and e['item'] == line['item']]
                assert sum(e['count'] for e in owned) == line['used'] == stock['used']
                assert sum(e['cost'] for e in owned) == line['consumption'] == line['used'] * line['unit']
                assert line['remaining'] == line['quantity'] - line['used'] == stock['remaining']
                assert line['refund'] == line['remaining'] * line['unit']
                assert line['cost'] == line['deployment'] + line['consumption']
                assert line['usedByOthers'] == sum(e['count'] for e in owned if e['performer'] != e['owner'])
            assert economy['cost'] == data['quote']['deployment'] + sum(e['cost'] for e in events)
            assert data['balanceBefore'] == wallet
            wallet += economy['net']
            assert cycle['balance'] == economy['balanceAfter'] == wallet
            episode = child.execute('SELECT payload FROM Game0CombatEpisodes WHERE attempt=?', (mission[0],)).fetchone()
            assert episode and json.loads(episode[0])['disarm']['status'] == 'won'
            bills.append(dict(attempt=attempt, cost=economy['cost'], income=economy['income'], refund=economy['refund'], net=economy['net'], balance=wallet))
        # Account for a later committed outcome or the next reserved budget,
        # without presenting unreturned work as another accepted cycle.
        actual_wallet = result['balanceBefore']
        for row in supplies[len(old_supplies):]:
            data = json.loads(row[2])
            actual_wallet += -data['quote']['total'] if row[1] == 'active' else data['result']['net']
        assert child.execute('SELECT available FROM Game0SupplyWallet').fetchone()[0] == actual_wallet
        active = child.execute("SELECT count(*) FROM Game0MissionAttempts WHERE status='active'").fetchone()[0]
        if finished:
            assert active == 0 and len(added) == len(cycles) and len(missions) == len(old_missions) + len(cycles)
            assert wallet == result['balanceAfter'] == actual_wallet
    package = Path(run['package']['root'])
    manifest = json.loads((package / 'package-manifest.json').read_text())
    assert len(manifest['files']) == 2777
    for item in manifest['files']:
        assert sha(package / item['path']) == item['sha256']
    game = Path(run['package']['gameRoot'])
    assert len(run['luaSources']) == 409
    for path, digest in run['luaSources'].items():
        assert sha(game / path) == digest
    if finished:
        assert run['runtimeErrorCount'] == 0 and run['gameSourcesUnchanged']
        assert run['packageIsolation']['verified'] and run['packageIsolation']['filesVerifiedAfter'] == 2777
    metrics = [{key: cycle[key] for key in ('index', 'objects', 'luaRefs', 'callRefs', 'luaKB', 'retainedSceneWorlds')} for cycle in cycles]
    return dict(status='PASS_FINISHED_ORIGINAL_RETURN_SQL' if finished else 'PASS_COMPLETED_RETURN_PREFIX_ONLY', completedCycles=len(cycles), elapsed=result['elapsed'], finished=finished, longDurationObserved=finished and result['elapsed'] >= 1800 and result['targetSeconds'] >= 1800, startExecutions=1, dbAttachments=1, qaSceneReset=False, qaRootCleanupReset=False, bills=bills, walletAfterCompletedPrefix=wallet, observedCurrentWallet=actual_wallet, activeMissionCount=active, modelTablesPreserved=models, priorAttemptsPreserved=True, frozenFilesVerified=2777, scriptFilesVerified=409, memory=metrics, frames=result.get('frames'), productionMemoryAccepted=False, allMissionStabilityAccepted=False, osInput=False, allOriginalEndingsAccepted=False, fullGameComplete=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--result', type=Path, required=True)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--allow-running', action='store_true')
    args = parser.parse_args()
    result = json.loads(args.result.read_text())
    evidence = audit(result, json.loads(args.run.read_text()), args.allow_running)
    evidence['lifecycleObservations'] = lifecycle_observations(result['cycles'], evidence['frames'])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: v for k, v in evidence.items() if k not in ('bills', 'memory', 'frames', 'modelTablesPreserved', 'lifecycleObservations')}, ensure_ascii=False))


if __name__ == '__main__':
    main()
