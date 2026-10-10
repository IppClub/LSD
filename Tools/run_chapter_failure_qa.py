#!/usr/bin/env python3
"""Run earned third-chapter failure branches after a specific frozen journey ends.
Never launches a second Dora or treats these scripted branches as OS acceptance.
"""
import argparse, hashlib, json, os, shutil, sqlite3, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CASES=[('fresh-defense-failure-retry-current','fresh-factory-current','c0-m07',['failed','aborted']),('fresh-rescue-reaction-failure-current','fresh-chapter-three-current','c0-m08',['failed'])]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text())
def rows(c,t):return c.execute('select * from "'+t+'" order by rowid').fetchall()
def db(p):return sqlite3.connect('file:'+str(p)+'?mode=ro',uri=True)
def audit(dest,parent,key,mission,statuses,package):
 r=read(dest/'result.json');u=read(dest/'run.json');p=read(parent/'result.json')
 assert r['status']==u['status']=='PASS' and r['osInput'] is False and u['runtimeErrorCount']==0
 assert r['source']==p['database'] and u['gameSourcesUnchanged']
 assert u['package']['root']==str(package) and u['packageIsolation']['verified']
 m=read(package/'package-manifest.json');assert u['packageIsolation']['filesVerifiedAfter']==len(m['files'])
 for f in m['files']:assert sha(package/f['path'])==f['sha256']
 for f,h in u['luaSources'].items():assert sha(ROOT/f)==sha(package/'LingShuQiYuan.app/Contents/Resources/LSD'/f)==h
 assert sha(ROOT/'Test'/(u['test']+'.lua'))==u['testSha256']
 assert all(Path(v).is_relative_to(package/'LingShuQiYuan.app/Contents/Resources') for v in u['packageIsolation']['moduleFiles'].values())
 with db(r['source']) as a,db(r['database']) as b:
  assert b.execute('pragma integrity_check').fetchall()==[('ok',)]
  protected=[n for n, in a.execute("select name from sqlite_master where type='table'") if n.startswith(('Game0Training','Game0Target','Game0Flower')) or n=='Game0StorySupplies']
  for t in protected:assert rows(a,t)==rows(b,t),(key,t)
  old=rows(a,'Game0MissionAttempts');new=rows(b,'Game0MissionAttempts');assert new[:len(old)]==old
  added=new[len(old):];assert [x[2] for x in added]==statuses
  old_supply=rows(a,'Game0SupplyAttempts');assert rows(b,'Game0SupplyAttempts')[:len(old_supply)]==old_supply
  bills=[];balance=a.execute('select available from Game0SupplyWallet').fetchone()[0]
  assert balance==r['balanceBefore']
  for aid,mid,status,model,payload in added:
   assert mid==mission;report=json.loads(payload)
   st,pay=b.execute('select status,payload from Game0SupplyAttempts where id=?',('mission:'+str(aid),)).fetchone()
   ledger=json.loads(pay);e=ledger['result'];assert st==status==report['status'] and report['economy']==e
   events=ledger['events']
   if events==[]:events={}
   assert isinstance(events,dict),'Nonempty consumption list requires schema review'
   assert ledger['balanceBefore']==balance and e['income']==0
   assert e['reserved']==ledger['quote']['total'] and e['cost']==ledger['spent']==ledger['quote']['deployment']+sum(x['cost'] for x in events.values())
   for x in e['lines']:
    ev=[v for v in events.values() if v['owner']==x['actor'] and v['item']==x['item']]
    stock=ledger['stock'][x['actor']+':'+x['item']]
    assert x['used']==stock['used']==sum(v['count'] for v in ev)
    assert x['consumption']==x['used']*x['unit']==sum(v['cost'] for v in ev)
    assert x['remaining']==stock['remaining']==x['quantity']-x['used']>=0
    assert x['cost']==x['deployment']+x['consumption'] and x['refund']==x['remaining']*x['unit']
    assert x['usedByOthers']==sum(v['count'] for v in ev if v['performer']!=v['owner'])
   assert e['cost']==sum(x['cost'] for x in e['lines']) and e['refund']==sum(x['refund'] for x in e['lines'])==e['reserved']-e['cost']
   balance-=e['cost'];assert balance==e['balanceAfter']
   bills.append(dict(attempt=aid,status=status,cost=e['cost'],income=0,refund=e['refund'],balanceAfter=balance))
  assert balance==r['balanceAfter']==b.execute('select available from Game0SupplyWallet').fetchone()[0]
  for t in ['Game0MissionRewards','Game0MissionUnlocks']:assert rows(a,t)==rows(b,t)
  for t in ['Game0MissionAttempts','Game0SupplyAttempts']:assert b.execute('select count(*) from '+t+" where status='active'").fetchone()[0]==0
  assert b.execute("select count(*) from sqlite_master where type='trigger' and name like 'fail_%'").fetchone()[0]==0
  if mission=='c0-m07':
   assert b.execute("select count(*) from Game0StoryNodes where id='academy-loss'").fetchone()[0]==0
   s=r['retryStrike'];assert s['completedAt']-s['startedAt']>=s['duration']-.05
   assert r['failure']['mentorHP']==0 and r['cancelRetryNoCharge'] and r['returnedToDefenseGate']
  else:
   assert r['naturalFatal'] and r['retryAvailable'];fatal=[]
   for twin in r['battle']['twins']:
    dead=False;falls=0
    for e in twin['reactions']:
     if e['kind']=='complete':assert e['elapsed']>=e['duration']-.0001
     if e['kind']=='damage' and e['hp']==0:dead=True
     if dead and e['kind']=='start':
      assert e['clip']!='standUp'
      if e['clip']=='fall':falls+=1
    if twin['hp']==0:assert dead and falls<=1;fatal.append(twin['role'])
   assert fatal
 return dict(status='PASS_ACTUAL_SQL_PACKAGE_FAILURE_BRANCH',test=key,parent=r['source'],database=r['database'],bills=bills,protectedTables=protected,packageFiles=len(m['files']),scripted=True,osInput=False,fullGameComplete=False)
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--journey',type=Path,required=True);p.add_argument('--runtime-manifest',type=Path,required=True);p.add_argument('--evidence',type=Path,required=True);p.add_argument('--wait-pid',type=int);p.add_argument('--resume',action='store_true',help='Reuse completed native cases after an audit error; no gameplay replay');a=p.parse_args()
 if a.resume:assert read(a.evidence/'state.json')['status']=='FAIL','Resume only a recorded failed audit'
 a.evidence.mkdir(parents=True,exist_ok=a.resume);state={'status':'WAITING_JOURNEY','cases':[],'fullGameComplete':False}
 def save():
  tmp=a.evidence/'state.tmp';tmp.write_text(json.dumps(state,ensure_ascii=False,indent=2));tmp.replace(a.evidence/'state.json')
 save();formal=ROOT.parent/'lsd.db';formal_sha=sha(formal)
 assert formal_sha=='760372bda8ae788c451e95bc169ccddd6b5837cee36fe9101b330efd4f7e3d39','Formal save differs from protected baseline'
 try:
  if a.wait_pid:
   expected=str(a.journey.resolve())
   while True:
    proc=subprocess.run(['ps','-p',str(a.wait_pid),'-o','command='],capture_output=True,text=True)
    if proc.returncode:break
    assert 'Tools/run_full_journey_qa.py' in proc.stdout and expected in proc.stdout,'PID identity changed'
    time.sleep(15)
  chain=read(a.journey/'chain.json');assert chain['status']=='PASS_SCRIPTED_JOURNEY' and len(chain['completed'])==chain['totalStages']==25
  package=Path(chain['package']).resolve();state.update(status='RUNNING',package=str(package));save()
  for key,parent_key,mission,statuses in CASES:
   parent=a.journey/parent_key;earned=read(parent/'result.json')
   # Existing external fixtures read these result files; require exact current-journey identity.
   assert read(ROOT/'Test'/(parent_key+'-result.json'))==earned
   assert read(parent/'run.json')['package']['root']==str(package)
   assert subprocess.run(['pgrep','-f','[.]app/Contents/MacOS/Dora'],capture_output=True).returncode!=0,'Another native Dora active'
   dest=a.evidence/key;state['current']=key;save()
   env=os.environ.copy();env['LSD_QA_PARENT_RESULT']=str(parent/'result.json')
   if dest.exists():
    assert a.resume and read(dest/'run.json')['status']==read(dest/'result.json')['status']=='PASS','Cannot replay or reuse an unfinished native case'
    code=0
   else:code=subprocess.run([sys.executable,str(ROOT/'Tools/run_combat_qa.py'),'--runtime-manifest',str(a.runtime_manifest),'--package-root',str(package),'--test',key,'--evidence',str(dest),'--timeout','900'],cwd=ROOT,env=env).returncode
   assert code==0,'Native failure branch failed; preserve actual result'
   result=audit(dest,parent,key,mission,statuses,package);(dest/'independent-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));state['cases'].append(result);save()
   shutil.copy2(earned['database'],dest/'parent-save.db');shutil.copy2(result['database'],dest/'actual-save.db')
   shutil.copy2(parent/'result.json',dest/'parent-result.json');shutil.copy2(parent/'run.json',dest/'parent-run.json')
   u=read(dest/'run.json');shutil.copy2(ROOT/'Test'/(u['test']+'.lua'),dest/(u['test']+'.lua'))
  assert sha(formal)==formal_sha;state.update(status='PASS_SCRIPTED_FAILURE_BRANCHES',formalSaveUnchanged=True)
 except Exception as e:state.update(status='FAIL',error=str(e));save();raise
 save()
 archive=ROOT/'Docs/evidence/2026-10-09'/a.evidence.name
 shutil.copytree(a.evidence,archive)
 for rel,h in read(a.evidence/CASES[0][0]/'run.json')['luaSources'].items():
  assert sha(ROOT/rel)==h;target=archive/'game-source'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,target)
 shutil.copy2(__file__,archive/'runner-audit.py');shutil.copy2(package/'package-manifest.json',archive/'package-manifest.json')
 shutil.copy2(a.runtime_manifest,archive/'runtime-manifest.json')
 (archive/'README.md').write_text('同一输入恢复候选完成25段旅程后，从本包实际获得的工厂/第三章父档复制隔离分支，沿原入口验证学院失败、付费重试和撤退，以及双子救援实际致命失败、返回和取消配装。公开UI脚本驱动，非OS操作；逐消费、库存、退款、旧账模型和剧情奖励独立SQL核验。各分支不并入主账，不证明全部结局或双子动画视觉质量。\n')
 files=[dict(path=str(f.relative_to(archive)),bytes=f.stat().st_size,sha256=sha(f)) for f in sorted(archive.rglob('*')) if f.is_file() and f.name!='manifest.json']
 (archive/'manifest.json').write_text(json.dumps({'files':files},indent=2))
 print(json.dumps(state,ensure_ascii=False),flush=True)
if __name__=='__main__':main()
