#!/usr/bin/env python3
"""Serial, source-audited fresh journey on one immutable candidate package."""
import argparse, importlib.util, json, os, subprocess, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STAGES=[
 ('fresh-opening-scripted',False,None),
 ('fresh-opening-scripted-resume',True,None),
 ('fresh-investigation-scripted',False,None),
 ('fresh-train-current',False,None),('fresh-ground-current',False,None),
 ('fresh-cooperation-current',False,None),('fresh-wuyun-current',False,None),
 ('fresh-energy-current',True,None),
 ('fresh-energy-efficiency',False,'fresh-energy-current'),
 ('fresh-ayan-current',False,None),('fresh-liyena-current',False,None),
 ('fresh-aftertrial-current',False,None),('fresh-medical-current',False,None),
 ('fresh-materials-current',False,None),('fresh-recovery-current',False,None),
 ('fresh-ruins-current',False,None),('fresh-valley-current',False,None),
 ('fresh-valley-activities-current',False,None),('fresh-valley-days-current',False,None),
 ('fresh-fox-trail-current',False,None),('fresh-command-current',False,None),
 ('fresh-factory-current',False,None),('fresh-chapter-three-current',False,None),
 ('fresh-ending-current',False,None),('fresh-ending-resume-current',False,None)]

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--runtime-manifest',type=Path,required=True)
 p.add_argument('--package-root',type=Path,required=True)
 p.add_argument('--evidence',type=Path,required=True)
 p.add_argument('--stage-timeout',type=int,default=900)
 a=p.parse_args();base=a.evidence.resolve();base.mkdir()
 package=a.package_root.resolve();game=package/'LingShuQiYuan.app/Contents/Resources/LSD';lib=package/'LingShuQiYuan.app/Contents/Resources/Script/Lib'
 state={'status':'RUNNING','package':str(package),'osInput':False,'defaultAppBootstrap':False,'completed':[],'totalStages':len(STAGES),'sameFrozenVersion':True,'fullGameComplete':False}
 def save():
  tmp=base/'chain.tmp';tmp.write_text(json.dumps(state,ensure_ascii=False,indent=2));tmp.replace(base/'chain.json')
 previous=None;results={};snapshot=None
 try:
  for key,branch,reference in STAGES:
   parent=results[reference] if reference else previous
   expected_source=None
   if parent:
    pr=json.loads((parent/'result.json').read_text());expected_source=pr['source'] if reference else pr['database']
   dest=base/key;state['current']=key;state['parentEvidence']=str(parent)if parent else None;save()
   env=os.environ.copy();env.pop('LSD_QA_PARENT_RESULT',None)
   if parent:env['LSD_QA_PARENT_RESULT']=str(parent/'result.json')
   process=subprocess.run([sys.executable,str(ROOT/'Tools/run_combat_qa.py'),'--runtime-manifest',str(a.runtime_manifest),'--package-root',str(package),'--test',key,'--evidence',str(dest),'--timeout',str(a.stage_timeout)],cwd=ROOT,env=env)
   row={'stage':key,'evidence':str(dest),'parentEvidence':str(parent)if parent else None,'branch':branch,'exit':process.returncode};state['completed'].append(row)
   if process.returncode:raise RuntimeError('Stage failed; retain its actual result and save: '+key)
   r=json.loads((dest/'result.json').read_text());run=json.loads((dest/'run.json').read_text())
   assert r['status']=='PASS' and r.get('osInput')is False,(key,'Result/input scope')
   if expected_source:assert r['source']==expected_source,(key,'Unexpected save parent')
   assert r['database'].startswith('/private/tmp/lsd-combat-qa-')and Path(r['database']).is_file(),(key,'Save isolation')
   assert run['package']['root']==str(package)and run['package']['gameRoot']==str(game),(key,'Package changed')
   guard=run['packageIsolation'];assert run['gameSourcesUnchanged']and guard['verified']and guard['filesVerifiedAfter']==run['package']['filesVerified']
   assert all(Path(f).is_relative_to(game)or Path(f).is_relative_to(lib)for f in guard['moduleFiles'].values()),(key,'Module escape')
   if snapshot is None:snapshot=run['luaSources']
   assert snapshot==run['luaSources'],(key,'Source snapshot changed')
   row.update(verified=True,database=r['database'],source=r.get('source'),balance=r.get('balanceAfter',r.get('balance')),packageFiles=guard['filesVerifiedAfter'])
   results[key]=dest
   if not branch:previous=dest;state['lastMainDatabase']=r['database'];state['lastMainBalance']=row['balance']
   save()
  state['status']='PASS_SCRIPTED_JOURNEY'
 except Exception as error:
  state['status']='FAIL';state['error']=str(error);save();print(json.dumps({'status':'FAIL','stage':state['current'],'error':str(error)},ensure_ascii=False),flush=True);return 1
 save();print(json.dumps({'status':state['status'],'stages':len(state['completed']),'balance':state['lastMainBalance'],'osInput':False},ensure_ascii=False),flush=True);return 0
if __name__=='__main__':raise SystemExit(main())
