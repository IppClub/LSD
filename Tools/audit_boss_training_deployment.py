"""Trace an actual public lesson, comparison, reversible adoption and formal outcome."""
from pathlib import Path
import argparse,json,hashlib,sqlite3,shutil
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_text())
def db(p):return sqlite3.connect('file:'+str(p)+'?mode=ro',uri=True)
def rows(c,n):return c.execute('select * from "'+n.replace('"','""')+'" order by rowid').fetchall()
def protected(a,b):
 names=[n for n, in a.execute("select name from sqlite_master where type='table'")if n.startswith(('Game0Training','Game0Target','Game0Flower')) or n=='Game0StorySupplies']
 for n in names:assert rows(a,n)==rows(b,n),n
 return names
def main():
 p=argparse.ArgumentParser();p.add_argument('--lesson',type=Path,required=True);p.add_argument('--comparison',type=Path,required=True);p.add_argument('--adoption',type=Path,required=True);p.add_argument('--deployment',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--blocked',type=Path);a=p.parse_args()
 stages=[('lesson',a.lesson),('comparison',a.comparison),('adoption',a.adoption),('deployment',a.deployment)];data=[]
 for label,raw in stages:
  r=load(raw/'result.json');u=load(raw/'run.json');assert r['status'] in ['PASS','FAIL'] and u['runtimeErrorCount']==0 and u['gameSourcesUnchanged'] and u['uiSourcesUnchanged'];assert u['packageIsolation']['verified']
  if label!='deployment':assert r['status']==u['status']=='PASS'
  package=Path(u['package']['root']);m=load(package/'package-manifest.json');assert len(m['files'])==u['packageIsolation']['filesVerifiedAfter']==2779
  for v in m['files']:
   f=package/v['path'];assert f.stat().st_size==v['bytes']and sha(f)==v['sha256']
  assert len(u['luaSources'])==410 and len(u['uiLuaSources'])==81
  assert sha(ROOT/'Test'/(u['test']+'.lua'))==u['testSha256']
  data.append((r,u))
 assert len({u['package']['root']for r,u in data})==1
 lesson,compare,adopt,formal=[r for r,u in data]
 assert lesson['protectedStateUnchanged'] and lesson['noKnownExposedEMP'] and lesson['knownArmsSwitchSamples']>=2
 assert compare['protectedStateUnchanged'] and compare['report']['candidate']==lesson['model'] and len(compare['report']['rounds'])==2
 assert compare['parentEvidence']==str(a.lesson/'result.json') and adopt['parentEvidence']==str(a.comparison/'result.json')
 assert adopt['model']==lesson['model'] and adopt['publicRollbackVerified'] and adopt['protectedStateUnchanged'] and not adopt['stableBenefitProven']
 assert formal['source']==adopt['adoptedCheckpoint'] and formal['deploymentVerified'] and formal['episodeSaved'] and formal['returnedToTrain']
 assert formal['outcome'] in ['won','failed'] and formal['naturalVictory']==(formal['outcome']=='won')
 source=db(lesson['parentDatabase']);taught=db(lesson['database']);compared=db(compare['database']);rolled=db(adopt['database']);active=db(adopt['adoptedCheckpoint']);child=db(formal['database'])
 protectedTables=protected(source,taught);protected(taught,compared);protected(compared,rolled);protected(active,child)
 for c in [source,taught,compared,rolled,active,child]:assert c.execute('pragma integrity_check').fetchall()==[('ok',)]
 for c in [taught,compared,rolled,active]:assert rows(source,'Game0MissionAttempts')==rows(c,'Game0MissionAttempts') and rows(source,'Game0SupplyAttempts')==rows(c,'Game0SupplyAttempts') and rows(source,'Game0SupplyWallet')==rows(c,'Game0SupplyWallet')
 for n in ['Game0YingzhaoAdoptions','Game0YingzhaoAdoptionState','Game0YingzhaoCandidates','Game0YingzhaoComparisons','Game0YingzhaoObservations']:assert rows(active,n)==rows(child,n)
 assert rows(source,'Game0YingzhaoAdoptionState')==rows(compared,'Game0YingzhaoAdoptionState')
 assert active.execute("select current from Game0YingzhaoAdoptionState where actor='ninilite'").fetchone()[0]==adopt['active']
 for n in ['Game0MissionAttempts','Game0SupplyAttempts']:
  old=rows(active,n);new=rows(child,n);assert new[:len(old)]==old and len(new)==len(old)+1
  assert child.execute('select count(*) from '+n+" where status='active'").fetchone()[0]==0
 mission=rows(child,'Game0MissionAttempts')[-1];assert mission[1]=='c0-yingzhao' and mission[2]==formal['outcome'] and json.loads(mission[4])==formal['battle']
 s=json.loads(child.execute('select payload from Game0SupplyAttempts where id=?',('mission:'+str(mission[0]),)).fetchone()[0]);e=formal['battle']['economy'];assert s['result']==e
 assert e['cost']==s['quote']['deployment']+sum(v['cost']for v in s['events'].values()) and e['income']==(100 if formal['outcome']=='won'else 0) and e['net']==e['income']-e['cost'] and e['reserved']==e['cost']+e['refund']
 for q,l in zip(s['quote']['lines'],e['lines'],strict=True):
  uses=[v for v in s['events'].values()if v['owner']==q['actor'] and v['item']==q['item']];used=sum(v['count']for v in uses);st=s['stock'][q['key']]
  assert used==st['used']==l['used'] and q['quantity']-used==st['remaining']==l['remaining'] and st['remaining']>=0
  assert all(v['cost']==v['count']*q['unit'] for v in uses);assert l['cost']==q['deploy']+used*q['unit'] and l['refund']==st['remaining']*q['unit']
 assert formal['balanceAfter']==child.execute('select available from Game0SupplyWallet').fetchone()[0]==formal['balanceBefore']+formal.get('recoveryIncome',0)+e['net']
 assert formal['policyDecisions'] and all(v['origin']=='adopted'for v in formal['policyDecisions'])
 episode=json.loads(child.execute('select payload from Game0CombatEpisodes where attempt=?',(mission[0],)).fetchone()[0]);assert episode['boss']['status']==formal['outcome']
 formalDB=ROOT.parent/'lsd.db';assert sha(formalDB)=='760372bda8ae788c451e95bc169ccddd6b5837cee36fe9101b330efd4f7e3d39'
 audit={'status':'PASS_PUBLIC_TRAINING_DEPLOYMENT_INTEGRATION_ONLY','package':data[0][1]['package']['root'],'candidateSamples':lesson['model']['sampleCount'],'knownExposedEMPComparison':compare['effects'][1]['actors']['ninilite']['empKnownExposedHits'],'comparisonRounds':[{k:v.get(k)for k in ['mode','status','cost','bossHP','armorDamage','healthDamage']}for v in compare['report']['rounds']],'formalOutcome':formal['outcome'],'cost':e['cost'],'income':e['income'],'refund':e['refund'],'balanceBefore':formal['balanceBefore'],'recoveryIncome':formal.get('recoveryIncome',0),'balanceAfter':formal['balanceAfter'],'adoptedDecisions':len(formal['policyDecisions']),'acceptedDecisions':sum(bool(d.get('accepted'))for d in formal['policyDecisions']),'protectedTables':protectedTables,'rollbackVerified':True,'stableBenefitProven':False,'continuousOS':False,'fullGameAccepted':False,'formalDBUnchanged':True}
 a.output.mkdir(parents=True,exist_ok=False)
 for label,raw in stages:shutil.copytree(raw,a.output/label);u=load(raw/'run.json');shutil.copy2(ROOT/'Test'/(u['test']+'.lua'),a.output/(u['test']+'.lua'))
 if a.blocked:
  blocked=load(a.blocked/'result.json');u=load(a.blocked/'run.json');assert blocked['status']==u['status']=='FAIL' and 'Recovery ceiling cannot fund loadout' in blocked['error'] and u['packageIsolation']['verified']
  denied=db(blocked['database']);assert rows(active,'Game0MissionAttempts')==rows(denied,'Game0MissionAttempts')and rows(active,'Game0SupplyAttempts')==rows(denied,'Game0SupplyAttempts')and rows(active,'Game0SupplyWallet')==rows(denied,'Game0SupplyWallet')
  audit['unaffordable405BlockedWithoutTaskOrWalletChange']=True;shutil.copytree(a.blocked,a.output/'unaffordable-405');shutil.copy2(blocked['database'],a.output/'unaffordable-405.db')
 for label,path in [('source',lesson['parentDatabase']),('taught',lesson['database']),('compared',compare['database']),('rollback',adopt['database']),('adopted',adopt['adoptedCheckpoint']),('formal',formal['database'])]:shutil.copy2(path,a.output/(label+'.db'))
 shutil.copy2(__file__,a.output/Path(__file__).name)
 (a.output/'independent-audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n')
 (a.output/'README.md').write_text('# 公开训练到正式Boss接入\n\n保留合法失败存档→原示范/学习→双场对照→原采用/回滚→正式出战全过程；原始结果和独立SQL审计见附件。候选并未证明稳定收益，任何失败均保留。所有操作为原公共UI脚本回放，不代表OS通关或全内容验收。正式lsd.db未改。\n')
 files=[{'path':str(f.relative_to(a.output)),'bytes':f.stat().st_size,'sha256':sha(f)}for f in sorted(a.output.rglob('*'))if f.is_file()]
 (a.output/'manifest.json').write_text(json.dumps({'files':files},ensure_ascii=False,indent=2)+'\n');print(json.dumps(audit,ensure_ascii=False))
if __name__=='__main__':main()
