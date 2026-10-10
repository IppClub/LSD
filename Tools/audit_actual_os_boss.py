from pathlib import Path
import json,sqlite3,hashlib,shutil,sys
root=Path('/Users/Jin/Workspace/Dora/LSD');raw=Path(sys.argv[1]);dest=root/'Docs/evidence/2026-10-09'/sys.argv[2]
r=json.loads((raw/'result.json').read_text());u=json.loads((raw/'run.json').read_text());assert r['status']==u['status'] and r['status'] in ['PASS','FAIL'] and r['naturalVictory']==(r['outcome']=='won') and r['outcome'] in ['won','failed'] and r['episodeSaved']and r['returnedToTrain']and u['runtimeErrorCount']==0 and u['gameSourcesUnchanged']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def db(p):return sqlite3.connect('file:'+str(p)+'?mode=ro',uri=True)
def rows(c,n):return c.execute('select * from "'+n+'" order by rowid').fetchall()
a=db(r['source']);b=db(r['database']);assert b.execute('pragma integrity_check').fetchall()==[('ok',)]
models=[n for n, in a.execute("select name from sqlite_master where type='table'")if n.startswith(('Game0Training','Game0Target','Game0Flower'))]
for n in models:assert rows(a,n)==rows(b,n)
for n in ['Game0MissionAttempts','Game0SupplyAttempts']:
 old=rows(a,n);new=rows(b,n);assert new[:len(old)]==old and len(new)==len(old)+1 and b.execute('select count(*)from '+n+" where status='active'").fetchone()[0]==0
row=rows(b,'Game0MissionAttempts')[-1];assert row[1]=='c0-yingzhao'and row[2]==r['outcome']and json.loads(row[4])==r['battle']
e=r['battle']['economy'];s=json.loads(b.execute('select payload from Game0SupplyAttempts where id=?',('mission:'+str(row[0]),)).fetchone()[0]);assert s['result']==e and e['cost']==s['quote']['deployment']+sum(x['cost']for x in s['events'].values())and e['income']==(100 if r['outcome']=='won' else 0) and e['refund']==r['budget']-e['cost'] and e['reserved']==r['budget'] and e['net']==e['income']-e['cost']
stockAudit=[]
for q,line in zip(s['quote']['lines'],e['lines'],strict=True):
 key=q['key'];st=s['stock'][key];events=[v for v in s['events'].values() if v['owner']==q['actor'] and v['item']==q['item']]
 used=sum(v['count'] for v in events);assert used==st['used']==line['used'] and q['quantity']-used==st['remaining']==line['remaining'] and st['remaining']>=0
 assert q['actor']==line['actor'] and q['item']==line['item'] and q['unit']==st['unit']==line['unit']
 assert all(v['performer'] in ['mentor','ninilite','wuyun'] and v['count']>0 and v['cost']==v['count']*q['unit'] for v in events)
 assert line['consumption']==used*q['unit'] and line['cost']==q['deploy']+line['consumption'] and line['refund']==st['remaining']*q['unit']
 assert line['usedByOthers']==sum(v['count'] for v in events if v['performer']!=q['actor'])
 stockAudit.append({'ownerItem':key,'events':len(events),'used':used,'remaining':st['remaining'],'actualCost':line['cost'],'refund':line['refund']})
assert sum(v['used'] for v in stockAudit)==sum(v['count'] for v in s['events'].values())
assert sum(v['actualCost'] for v in stockAudit)==e['cost'] and sum(v['refund'] for v in stockAudit)==e['refund']
paidMentorUses=sum(v['count'] for v in s['events'].values() if v['performer']=='mentor' and v['item']==s['quote']['lines'][0]['item']);assert paidMentorUses<=r['mentorShots']
parentWallet=a.execute('select available from Game0SupplyWallet').fetchone()[0];assert r['balanceBefore']==parentWallet and r['balanceAfter']==parentWallet+r.get('recoveryIncome',0)+e['net']==b.execute('select available from Game0SupplyWallet').fetchone()[0]
episode=json.loads(b.execute('select payload from Game0CombatEpisodes where attempt=?',(row[0],)).fetchone()[0]);assert episode['boss']['status']==r['outcome']and episode['boss']['vitals']==r['vitals']and episode['boss']['encounter']['maxHP']==1000
strikes={};children=[]
def add(strike):
 key=(strike['source'],strike['started'])
 if key in strikes:assert strikes[key]==strike
 else:strikes[key]=strike
for guard in r['battle']['guards']:
 for strike in guard['strikes']:add(strike)
 for child in guard.get('summons',[]):
  children.append(child);assert child['ended'] and child['reason']
  for strike in child['strikes']:assert strike['source']=='yingzhao-summon-'+str(child['id']);add(strike)
assert len(children)>0 and len({c['id']for c in children})==len(children)
contacts=[x for x in r['supportAfter']['physicalShield']['events']if x['kind']=='impact'];matches=[]
for x in contacts:
 ss=[s for (source,started),s in strikes.items()if source==x['attackerId']and abs(started-x['strikeStarted'])<1e-5];assert len(ss)==1
 actor='charF'if x['actor']=='mentor'else 'auxiliary-machine'if x['actor']=='machine'else x['actor'];strike=ss[0]
 if x['attackKind']=='enemy-wave':
  assert x['hitIndex']==1;hit=[h for h in strike['wave']['hits']if h['actor']==actor and abs(h['at']-x['at'])<.01];assert len(hit)==1 and hit[0]['damage']==x['incoming']
 else:
  hit=strike['impacts'][x['hitIndex']-1];assert abs(hit['at']-x['at'])<.01 and any(t['actor']==actor and t['damage']==x['incoming']for t in hit['targets'])
 matches.append({'shieldIndex':x['index'],'actor':x['actor'],'attackerId':x['attackerId'],'strikeStarted':x['strikeStarted'],'hitIndex':x['hitIndex'],'actualLoss':x['hpBefore']-x['hpAfter']})
packageRecord=u.get('package')
if packageRecord:
 assert u['packageIsolation']['verified']
 packageRoot=Path(packageRecord['root']);packageManifest=json.loads((packageRoot/'package-manifest.json').read_text())
 assert packageRecord['filesVerified']==u['packageIsolation']['filesVerifiedAfter']==len(packageManifest['files'])
 packageRoot=Path(packageRecord['root']);packageManifest=json.loads((packageRoot/'package-manifest.json').read_text())
 for item in packageManifest['files']:assert sha(packageRoot/item['path'])==item['sha256']
 loadedRoot=Path(packageRecord['gameRoot'])
else:
 loadedRoot=root
assert u['luaSources'] and len(u['luaSources'])==len(list((loadedRoot/'Script').rglob('*.lua')))
if 'uiLuaSources' in u:
 assert u['uiSourcesUnchanged'] and len(u['uiLuaSources'])==len(list((loadedRoot/'UI').rglob('*.lua')))
 assert all(sha(loadedRoot/path)==digest for path,digest in u['uiLuaSources'].items())
assert all(sha(loadedRoot/path)==digest for path,digest in u['luaSources'].items())
assert u['runtime']['binarySha256']==json.loads(Path('/private/tmp/lsd-font-atlas-runtime-20261008/manifest.json').read_text())['binarySha256']
assert all(step['origin']=='player' for step in r['trace']['steps'] if step['actor']=='mentor' and step['action']=='shoot');assert r['osInput'] and r['actualCombatKeys'] and r['setupScripted'] and not r['combatScripted'] and not r['fullGameComplete'];assert paidMentorUses==r['actualKineticUses']==r['mentorShots'];assert any(x['key']=='J' and x['kind']=='KeyDown' and x['phase']=='playing' for x in r['events']) and any(x['key']=='J' and x['kind']=='KeyUp' and x['phase']=='playing' for x in r['events']);shutil.copytree(raw,dest,dirs_exist_ok=True);shutil.copy2(r['source'],dest/'actual-earned-parent.db');shutil.copy2(r['database'],dest/'actual-outcome-save.db');test=root/'Test/OSBossResourceLoadoutNative.lua';assert sha(test)==u['testSha256'];shutil.copy2(test,dest/test.name)
for path,digest in {**u['luaSources'],**u.get('uiLuaSources',{})}.items():
 frozen=loadedRoot/path;assert sha(frozen)==digest;target=dest/'game-source'/path;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(frozen,target)
audit={'status':'PASS_FORMAL_BOSS_SQL_COLD_READ_AND_ALL_CONTACT_PROVENANCE','outcome':r['outcome'],'naturalVictory':r['naturalVictory'],'stableVictory':False,'sourceNotPackaged':not bool(packageRecord),'sourceLua':len(u['luaSources']),'uiLua':len(u.get('uiLuaSources',{})),'schema':13,'seconds':r['battle']['seconds'],'cost':e['cost'],'income':e['income'],'refund':e['refund'],'walletBefore':parentWallet,'legalRecoveryIncome':r.get('recoveryIncome',0),'walletAfter':r['balanceAfter'],'net':e['net'],'machineHP':r['supportAfter']['machineHP'],'mentorEmittedShots':r['mentorShots'],'paidKineticUses':e['lines'][0]['used'],'retiredSummons':len(children),'allPartyAndMachineContactsMatched':len(matches),'machineContactsMatched':sum(x['actor']=='machine'for x in matches),'sameFrozenLatestPackage':bool(packageRecord),'previousPackageComparison':False,'oldModelsAndBillsPreserved':True,'episodeSavedAndReturned':True,'runtimeErrors':0,'osInput':True,'setupScripted':True,'combatScripted':False,'fullGameComplete':False,'slowFrameObservations':r.get('slowFrameObservations',[]),'actualMentorOrigins':[step['origin'] for step in r['trace']['steps'] if step['actor']=='mentor' and step['action']=='shoot'],'failureReason':r['battle']['reason'],'finalVitals':r['vitals']['final'],'scope':r['scope']}
(dest/'independent-audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2));(dest/'all-contact-matches.json').write_text(json.dumps(matches,ensure_ascii=False,indent=2));(dest/'consumption-stock-audit.json').write_text(json.dumps(stockAudit,ensure_ascii=False,indent=2));shutil.copy2(__file__,dest/'audit.py');(dest/'README.md').write_text('# 实际键盘Boss尝试（版本来源见独立审计）\n\n公开路线和配装为夹具准备；开始、战斗与原结算返回为CUA实际操作。实际结果 '+r['outcome']+'，原因 '+r['battle']['reason']+'；耗时 '+str(r['battle']['seconds'])+'，成本 '+str(e['cost'])+'，收入 '+str(e['income'])+'，退款 '+str(e['refund'])+'，钱包 '+str(parentWallet)+'＋补给'+str(r.get('recoveryIncome',0))+'→'+str(r['balanceAfter'])+'。机体 '+str(r['supportAfter']['machineHP'])+'，导师/队友实际终值见独立audit。全部实际导师射击来源player，原记录保留；不表示稳定获胜或完整默认App旅程。观察器PASS仅表示真实输入、账目、旧模型保持、保存及返回通过。工具往返和分析空档保留，不当作难度单变量对照；无慢帧观察不能覆盖旧长稳慢帧门槛。\n')
m={'files':[{'path':str(p.relative_to(dest)),'bytes':p.stat().st_size,'sha256':sha(p)}for p in sorted(dest.rglob('*'))if p.is_file()and p.name!='manifest.json']};(dest/'manifest.json').write_text(json.dumps(m,indent=2));assert all(sha(dest/x['path'])==x['sha256']for x in m['files']);print(json.dumps(audit,ensure_ascii=False));print('manifest',len(m['files']))
