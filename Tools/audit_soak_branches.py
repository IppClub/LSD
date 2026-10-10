"""Read-only SQL audit of completed FullGameSoakNative checkpoint branches.

This does not accept OS play, all endings, or production memory behavior.
Only completed child databases are opened; the running stage is untouched.
"""
import argparse
import hashlib
import json
import sqlite3
from collections import Counter
from pathlib import Path


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def connect(path):
    return sqlite3.connect(Path(path).resolve().as_uri() + '?mode=ro', uri=True)


def rows(conn, name):
    return conn.execute('SELECT * FROM "' + name.replace('"', '""') + '" ORDER BY rowid').fetchall()


def action_facts(reports):
    attacks = releases = cancellations = losses = 0
    for report in reports:
        guards = list(report.get('guards', []))
        if report.get('opponent'):
            guards.append(report['opponent'])
        for segment in report.get('stages', []):
            guards.extend(segment.get('guards', []))
        for guard in guards:
            for strike in guard.get('strikes', []):
                start = strike.get('startedAt', strike.get('started'))
                end = strike.get('completedAt', strike.get('completed'))
                assert end - start >= strike['duration'] - .05
                attack = strike.get('attackAt', strike.get('releaseAt'))
                if attack is not None:
                    assert start <= attack <= end
                    releases += 1
                else:
                    reason = strike.get('releaseCancelled')
                    assert reason in ['DEFEATED', 'BATTLE_ENDED'], strike
                    assert start <= strike['releaseEventAt'] <= end
                    assert strike.get('hits', 0) == 0
                    if reason == 'DEFEATED':
                        assert strike['releaseEventHP'] <= 0
                    else:
                        assert strike['releaseEventPhase'] != 'playing'
                    cancellations += 1
                attacks += 1
            if guard.get('loseDuration') is not None:
                assert guard['loseEnded'] - guard['loseStarted'] >= guard['loseDuration'] - .05
                losses += 1
    return dict(fullAttackDurations=attacks, actualReleasePoints=releases, actualCancelledReleases=cancellations, fullRecordedLoseDurations=losses, toleranceSeconds=.05)


def patrol_action_facts(reports):
    """Patrol sequences use per-clip records; interrupted clips lack end times."""
    complete = interrupted = impacts = 0
    for report in reports:
        for guard in report['guards']:
            for strike in guard['strikes']:
                assert strike.get('completed') is not None or strike.get('cancelled') in ('HIT', 'DEFEATED', 'BATTLE_ENDED')
                for clip in strike['clips']:
                    if 'ended' in clip:
                        assert clip['ended'] - clip['started'] >= clip['duration'] - .05
                        complete += 1
                    else:
                        assert strike.get('cancelled') in ('HIT', 'DEFEATED', 'BATTLE_ENDED')
                        interrupted += 1
                for impact in strike['impacts']:
                    assert impact['at'] >= strike['started']
                    if 'completed' in strike:
                        assert impact['at'] <= strike['completed']
                    impacts += 1
    return dict(fullRecordedClipDurations=complete, interruptedClips=interrupted, recordedImpacts=impacts,
                interruptedClipTimingAccepted=False, allAttackAnimationsAccepted=False, toleranceSeconds=.05)


def audit_stage(stage):
    result = json.loads(Path(stage['result']).read_text())
    same_journey = result['sameJourneyBranch'] if stage['test'] == 'FreshDisarmCurrentNative' else result['sameJourney']
    assert result['status'] == 'PASS' and same_journey and not result['osInput']
    assert result['database'] == stage['database'] and result['source'] == stage['source']
    with connect(stage['source']) as parent, connect(stage['database']) as child:
        assert child.execute('PRAGMA integrity_check').fetchall() == [('ok',)]
        names = [n for n, in parent.execute("SELECT name FROM sqlite_master WHERE type='table'")]
        models = [n for n in names if n.startswith(('Game0Training', 'Game0Target', 'Game0Flower'))]
        for name in models:
            assert rows(parent, name) == rows(child, name), name
        for name in ['Game0MissionAttempts', 'Game0SupplyAttempts']:
            old = rows(parent, name)
            assert rows(child, name)[:len(old)] == old, name
            assert child.execute('SELECT count(*) FROM ' + name + " WHERE status='active'").fetchone()[0] == 0
        assert child.execute("SELECT count(*) FROM sqlite_master WHERE type='trigger'").fetchone()[0] == 0
        before = parent.execute('SELECT available FROM Game0SupplyWallet').fetchone()[0]
        after = child.execute('SELECT available FROM Game0SupplyWallet').fetchone()[0]
        assert after == stage['balance'] == result.get('balance', result.get('balanceAfter'))
        reports = {
            'FreshGroundCurrentNative': lambda: [result['battle']],
            'FreshDisarmCurrentNative': lambda: [result['battle']],
            'FreshEnergyCurrentNative': lambda: [result['battle']],
            'FreshEnergyEfficiencyNative': lambda: [result['battle']],
            'FreshMaterialsCurrentNative': lambda: [result['battle']],
            'FreshRuinsCurrentNative': lambda: [result['report']],
            'FreshFactoryCurrentNative': lambda: [x['report'] for x in result['battles']],
            'FreshChapterThreeCurrentNative': lambda: [result['battle']],
            'FreshEndingCurrentNative': lambda: [result['rescue'], result['final']],
        }[stage['test']]()
        prior = rows(parent, 'Game0SupplyAttempts')
        bills = []
        for aid, status, payload in rows(child, 'Game0SupplyAttempts')[len(prior):]:
            data = json.loads(payload)
            economy = data['result']
            mission = child.execute('SELECT * FROM Game0MissionAttempts WHERE id=?', (int(aid.split(':')[1]),)).fetchone()
            report = json.loads(mission[4])
            assert report in reports and report['economy'] == economy
            assert status == mission[2] == data['status'] == economy['status'] == 'won'
            assert economy['cost'] == data['spent'] == sum(line['cost'] for line in economy['lines'])
            assert economy['reserved'] == data['quote']['total']
            assert economy['refund'] == economy['reserved'] - economy['cost']
            assert economy['net'] == economy['income'] - economy['cost']
            assert data['balanceBefore'] + economy['net'] == economy['balanceAfter']
            events = list(data['events'].values())
            for line in economy['lines']:
                key = line['actor'] + ':' + line['item']
                owned = [e for e in events if e['owner'] == line['actor'] and e['item'] == line['item']]
                used = sum(e['count'] for e in owned)
                consumption = sum(e['cost'] for e in owned)
                others = sum(e['count'] for e in owned if e['performer'] != e['owner'])
                assert used == line['used'] == data['stock'][key]['used']
                assert consumption == line['consumption'] == used * line['unit']
                assert others == line['usedByOthers']
                assert line['remaining'] == line['quantity'] - used == data['stock'][key]['remaining']
                assert line['refund'] == line['remaining'] * line['unit']
                assert line['cost'] == line['deployment'] + consumption
            assert sum(e['cost'] for e in events) + data['quote']['deployment'] == economy['cost']
            bills.append(dict(attempt=aid, mission=mission[1], cost=economy['cost'], income=economy['income'], net=economy['net'], refund=economy['refund'], consumptionEvents=len(events)))
        assert len(bills) == len(reports)
        assert before + sum(b['net'] for b in bills) + result.get('recoveryIncome', 0) == after
        actions = patrol_action_facts(reports) if stage['test'] == 'FreshDisarmCurrentNative' else action_facts(reports)
        if stage['test'] == 'FreshDisarmCurrentNative':
            assert {bill['mission'] for bill in bills} == {'c0-disarm'}
            assert result['outcome'] == 'won' and result['returnedToTrain'] and result['episodeSaved']
            assert result['cancelNoCharge'] and result['bossLockedNoCharge']
            assert result['stage'] == 'clearance-returned'
            assert rows(parent, 'Game0StorySupplies') == rows(child, 'Game0StorySupplies')
            assert len(bills) == 1
            attempt = int(bills[0]['attempt'].split(':')[1])
            episode = child.execute('SELECT payload FROM Game0CombatEpisodes WHERE attempt=?', (attempt,)).fetchone()
            assert episode and json.loads(episode[0])['disarm']['status'] == 'won'
        medicine = None
        if stage['test'] == 'FreshRuinsCurrentNative':
            assert {bill['mission'] for bill in bills} == {'c0-m06'}
            assert result['outcome'] == 'won' and result['stage'] == 'valley-arrival'
            report = reports[0]
            assert report['escortsSafe'] == 4 and report['routeCheckpoints'] == [True, True, True]
            assert report['mentorHits'] > 0 and report['flareHits'] > 0
            assert report['toolAnimations']['smoke'] > 0 and report['toolAnimations']['flare'] > 0
            mentor = parent.execute("SELECT value_str FROM Config WHERE name='char'").fetchone()[0]
            assert mentor in ('charF', 'charM')
            assert rows(parent, 'Config') == rows(child, 'Config')
            stock_before = {tuple(row[:3]): row[3] for row in rows(parent, 'Game0StorySupplies')}
            stock_after = {tuple(row[:3]): row[3] for row in rows(child, 'Game0StorySupplies')}
            assert stock_before.keys() == stock_after.keys()
            used = 0
            for key, amount in stock_before.items():
                delta = amount - stock_after[key]
                if key[1:] == (mentor, 'first-aid-water'):
                    assert 0 <= delta <= amount
                    used += delta
                else:
                    assert delta == 0, key
            assert used == report['medicineUses']
            medicine = dict(recipient=mentor, consumedUnits=used, reportUses=report['medicineUses'], otherStockExactlyPreserved=True, originalValleyReturn=True)
        ending = None
        if stage['test'] == 'FreshEndingCurrentNative':
            assert {b['mission'] for b in bills} == {'c0-m08', 'c0-m09'}
            assert child.execute("SELECT count(*) FROM Game0StoryNodes WHERE id='final-betrayal'").fetchone()[0] == 1
            assert {x[0] for x in rows(child, 'Game0EndingViews')} == {'ending', 'credits'}
            assert result['endingViews']['ending'] and result['endingViews']['credits']
            terminal = result['terminal']
            assert terminal['version'] == 1 and terminal['rows'] == 15
            assert terminal['clockBefore'] > 0 and terminal['clockBefore'] == terminal['clockAfter']
            assert terminal['freezeObserved'] - terminal['freezeStarted'] >= .65
            motion = terminal['action']
            assert motion['mentor'] in ['charM', 'charF'] and motion['held']
            assert motion['attackStarted'] < motion['impactAt'] < motion['attackEnded']
            assert 100 <= motion['impactDistance'] <= 170
            assert abs(motion['hitStarted'] - motion['impactAt']) <= .03
            for prefix, minimum in [('attack', .99), ('hit', .59), ('fall', 1.1)]:
                assert motion[prefix + 'Duration'] >= minimum
                assert motion[prefix + 'Ended'] - motion[prefix + 'Started'] >= motion[prefix + 'Duration'] - .04
            assert motion['fallStarted'] >= max(motion['attackEnded'], motion['hitEnded'])
            assert motion['approach']['distance'] >= 300 and motion['approach']['seconds'] >= 2
            ending = dict(endingAndCreditsSaved=True, finalBetrayalRecordedOnce=True, dialogueRows=15, frozenCommunicationPreserved=True, completeAttackHitFall=True, allOriginalEndingsAccepted=False)
    return dict(cycle=stage['cycle'], test=stage['test'], status='PASS_COMPLETED_BRANCH_SQL', walletBefore=before, walletAfter=after, bills=bills, modelTablesExactlyPreserved=models, priorAttemptsExactlyPreserved=True, actionFacts=actions, medicineFacts=medicine, endingFacts=ending, sourceSha256=sha(Path(stage['source'])), databaseSha256=sha(Path(stage['database'])), resultSha256=sha(Path(stage['result'])))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--result', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    snapshot = json.loads(args.result.read_text())
    audits = [audit_stage(stage) for stage in snapshot['stages']]
    counts = Counter(a['test'] for a in audits)
    output = dict(status='PASS_COMPLETED_BRANCH_SQL_ONLY', observedRunStatus=snapshot['status'], observedElapsed=snapshot['elapsed'], completedStages=len(audits), stagesByTest=dict(counts), stages=audits, checkpointBranches=True, qaRootCleanupReset=snapshot['qaRootCleanupReset'], productionLeakAccepted=False, longStabilityAccepted=False, osInput=False, allOriginalEndingsAccepted=False, fullGameComplete=False)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: v for k, v in output.items() if k != 'stages'}, ensure_ascii=False))


if __name__ == '__main__':
    main()
