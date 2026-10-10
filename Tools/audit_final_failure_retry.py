"""Read-only audit of the original final mission's actual failure and paid retry."""
import argparse, hashlib, json, sqlite3
from pathlib import Path

def rows(db, table):
    return db.execute('SELECT * FROM "' + table.replace('"', '""') + '" ORDER BY rowid').fetchall()

def audit(evidence):
    r=json.loads((evidence/'result.json').read_text());run=json.loads((evidence/'run.json').read_text())
    assert r['status']=='PASS' and not r['osInput'] and run['runtimeErrorCount']==0
    for key in ['actualDefeat','paidRetry','cancelRetryNoCharge','noVictoryUnlock','modelsUnchanged','returnedToFinalGate']:assert r[key]
    a=sqlite3.connect(Path(r['source']).resolve().as_uri()+'?mode=ro',uri=True);b=sqlite3.connect(Path(r['database']).resolve().as_uri()+'?mode=ro',uri=True)
    assert b.execute('PRAGMA integrity_check').fetchall()==[('ok',)]
    changes={'Game0StoryPerformances','Game0StoryNodes','Game0StoryUnlocks','Game0MissionMeta','Game0MissionAttempts','Game0SupplyWallet','Game0SupplyAttempts','Game0SupplyLoadout','Game0AuxiliarySelection','sqlite_sequence'}
    unchanged=[]
    for (name,) in a.execute("SELECT name FROM sqlite_master WHERE type='table'"):
        if name not in changes:assert rows(a,name)==rows(b,name),name;unchanged.append(name)
    for name in ['Game0MissionAttempts','Game0SupplyAttempts','Game0StoryNodes','Game0StoryPerformances','Game0StoryUnlocks']:
        old=rows(a,name);assert rows(b,name)[:len(old)]==old,name
    assert [x[0] for x in rows(b,'Game0StoryNodes')[len(rows(a,'Game0StoryNodes')):]]==['jade-distance']
    assert rows(b,'Game0StoryUnlocks')[len(rows(a,'Game0StoryUnlocks')):]==[('evacuation-window','jade-distance')]
    assert b.execute("SELECT count(*) FROM Game0StoryNodes WHERE id IN ('final-betrayal','final-story-complete')").fetchone()[0]==0
    assert b.execute("SELECT count(*) FROM Game0MissionUnlocks WHERE id='last-promise-complete'").fetchone()[0]==0
    attempts=rows(b,'Game0MissionAttempts')[len(rows(a,'Game0MissionAttempts')):];bills=rows(b,'Game0SupplyAttempts')[len(rows(a,'Game0SupplyAttempts')):]
    assert len(attempts)==len(bills)==2
    summaries=[]
    for mission,bill,report,status in zip(attempts,bills,[r['failure'],r['retry']],['failed','aborted']):
        mid,_,mstatus,_,payload=mission;assert mission[1]=='c0-m09' and mstatus==status and json.loads(payload)==report
        aid,bstatus,ledger=bill;data=json.loads(ledger);e=data['result'];assert aid==f'mission:{mid}' and bstatus==data['status']==e['status']==status
        assert e==report['economy'] and e['income']==0 and e['cost']==data['spent']==sum(l['cost'] for l in e['lines'])
        assert e['reserved']==data['quote']['total'] and e['refund']==e['reserved']-e['cost'] and e['net']==-e['cost']
        assert data['balanceBefore']+e['net']==e['balanceAfter']
        events=list(data['events'].values()) if isinstance(data['events'],dict) else data['events']
        assert isinstance(events,list)
        for line in e['lines']:
            owned=[v for v in events if v['owner']==line['actor'] and v['item']==line['item']];stock=data['stock'][line['actor']+':'+line['item']]
            used=sum(v['count'] for v in owned);cost=sum(v['cost'] for v in owned)
            assert used==line['used']==stock['used'] and cost==line['consumption']==used*line['unit']
            assert line['remaining']==line['quantity']-used==stock['remaining'] and line['refund']==line['remaining']*line['unit']
            assert line['usedByOthers']==sum(v['count'] for v in owned if v['performer']!=v['owner']) and line['cost']==line['deployment']+cost
        assert sum(v['cost'] for v in events)+data['quote']['deployment']==e['cost']
        summaries.append(dict(attempt=aid,status=status,cost=e['cost'],refund=e['refund'],events=len(events)))
    for table in ['Game0MissionAttempts','Game0SupplyAttempts']:assert b.execute(f"SELECT count(*) FROM {table} WHERE status='active'").fetchone()[0]==0
    assert b.execute("SELECT count(*) FROM sqlite_master WHERE type='trigger'").fetchone()[0]==0
    before=a.execute('SELECT available FROM Game0SupplyWallet').fetchone()[0];after=b.execute('SELECT available FROM Game0SupplyWallet').fetchone()[0]
    assert before==r['balanceBefore'] and after==r['balanceAfter']==before-sum(x['cost'] for x in summaries)
    strike=r['retryStrike'];assert strike['completedAt']-strike['startedAt']>=strike['duration']-.05
    formal=Path('/Users/Jin/Workspace/Dora/lsd.db');sha=hashlib.sha256(formal.read_bytes()).hexdigest();assert sha=='760372bda8ae788c451e95bc169ccddd6b5837cee36fe9101b330efd4f7e3d39'
    if run.get('package'):assert run['packageIsolation']['verified'] and run['packageIsolation']['filesVerifiedAfter']==2780
    return dict(status='PASS_FINAL_FAILURE_RETRY_SQL',bills=summaries,balanceBefore=before,balanceAfter=after,unchangedTables=unchanged,originalRowsRetained=True,originalFinalReturn=True,noVictoryUnlock=True,osInput=False,naturalFinalVictoryProven=False,formalDatabaseSha256=sha,retryAttackMeasuredSeconds=strike['completedAt']-strike['startedAt'],retryAttackDeclaredSeconds=strike['duration'],attackTimingToleranceSeconds=.05)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--evidence',type=Path,required=True);p.add_argument('--output',type=Path,required=True);args=p.parse_args();r=audit(args.evidence);args.output.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n');print(json.dumps(r,ensure_ascii=False))
