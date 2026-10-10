"""Audit default-bootstrap opening and cold continue without accepting all chapters."""
import argparse, hashlib, json, shutil, sqlite3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p): return json.loads(p.read_text())
def connect(p): return sqlite3.connect('file:'+str(p)+'?mode=ro',uri=True)
def snapshot(c):
    names=[r[0] for r in c.execute("select name from sqlite_master where type='table' order by name")]
    return {n:c.execute('select * from "'+n.replace('"','""')+'" order by rowid').fetchall() for n in names}
def main():
    p=argparse.ArgumentParser();p.add_argument('--opening',type=Path,required=True);p.add_argument('--continue-run',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    opening=load(a.opening/'result.json');resume=load(a.continue_run/'result.json')
    checks=[]
    for raw,r in [(a.opening,opening),(a.continue_run,resume)]:
        run=load(raw/'run.json');assert run['status']==r['status']=='PASS'
        assert run['runtimeErrorCount']==0 and run['gameSourcesUnchanged'] and run['uiSourcesUnchanged']
        assert run['packageIsolation']['verified']
        package=Path(run['package']['root']);manifest=load(package/'package-manifest.json')
        assert len(manifest['files'])==run['packageIsolation']['filesVerifiedAfter']==2779
        for row in manifest['files']:
            f=package/row['path'];assert f.stat().st_size==row['bytes'] and sha(f)==row['sha256'],f
        assert len(run['luaSources'])==410 and len(run['uiLuaSources'])==81
        for name,value in {**run['luaSources'],**run['uiLuaSources']}.items(): assert sha(Path(run['package']['gameRoot'])/name)==value
        assert sha(ROOT/'Test'/ (run['test']+'.lua'))==run['testSha256']
        bootstrap=Path(r['defaultBootstrap']);assert sha(bootstrap)==manifest['bootstrapSha256']
        event=load(raw/'actual-title-input.json');assert event['actualOS'] and event['action']=='click' and event['surface']=='CUA native macOS'
        assert r['titleClickRequiresOS'] and r['titleSelectedTime']>0
        checks.append({'fixture':run['test'],'package':str(package),'bootstrapSha256':sha(bootstrap),'actualOSScope':'title click only','packageFilesVerified':2779})
    assert checks[0]['package']==checks[1]['package'] and checks[0]['bootstrapSha256']==checks[1]['bootstrapSha256']
    assert opening['originalTitle'] and opening['actualTitleSelected']==Path(opening['database']).name
    assert resume['source']==opening['database'] and resume['titleName']==Path(opening['database']).name
    assert resume['noRepeatedTutorial'] and resume['noDuplicateRewards']
    db=connect(opening['database']);cold=connect(resume['database'])
    assert db.execute('pragma integrity_check').fetchall()==cold.execute('pragma integrity_check').fetchall()==[('ok',)]
    first=snapshot(db);second=snapshot(cold);assert first==second,'Cold resume altered earned SQL rows'
    config={v[0]:v[1:] for v in first['Config']};assert config['charName'][1]=='旅程QA' and config['char'][1]=='charF' and db.execute("select coalesce(value_bool,value_num) from Config where name='tutorialCompleted'").fetchone()[0]==1
    attempts=db.execute('select id,status,report from Game0MissionAttempts').fetchall();assert len(attempts)==1 and attempts[0][1]=='won'
    battle=json.loads(attempts[0][2]);assert battle==opening['battle'];e=battle['economy']
    supply=json.loads(db.execute('select payload from Game0SupplyAttempts where id=?',('mission:'+str(attempts[0][0]),)).fetchone()[0]);assert supply['result']==e
    events=supply['events'].values();assert e['cost']==supply['quote']['deployment']+sum(v['cost']for v in events)
    assert e['income']==100 and e['net']==100-e['cost'] and e['reserved']==e['cost']+e['refund']
    for q,line in zip(supply['quote']['lines'],e['lines'],strict=True):
        stock=supply['stock'][q['key']];uses=[v for v in events if v['owner']==q['actor'] and v['item']==q['item']]
        used=sum(v['count'] for v in uses);assert used==stock['used']==line['used'] and q['quantity']-used==stock['remaining']==line['remaining']
        assert all(v['cost']==v['count']*q['unit'] for v in uses)
        assert line['cost']==q['deploy']+used*q['unit'] and line['refund']==stock['remaining']*q['unit']
    balance=db.execute('select available from Game0SupplyWallet').fetchone()[0];assert balance==opening['balance']==resume['balance']==300+e['net']
    training=json.loads(db.execute("select payload from Game0Training where slot='main'").fetchone()[0]);assert training['adopted']['sampleCount']==opening['model']['count']==resume['model']['count']>=6
    formal=ROOT.parent/'lsd.db';assert sha(formal)=='760372bda8ae788c451e95bc169ccddd6b5837cee36fe9101b330efd4f7e3d39'
    audit={'status':'PASS_DEFAULT_ENTRY_AND_COLD_CONTINUE_ONLY','runs':checks,'openingUnseeded':True,'actualTitleClicks':2,'tutorialCombatScripted':True,'coldTablesUnchanged':len(first),'trainingSamples':opening['model']['count'],'firstMissionCost':e['cost'],'income':e['income'],'refund':e['refund'],'balance':balance,'consumptionEvents':len(supply['events']),'allChapters':False,'allEndings':False,'continuousOSJourney':False,'formalDatabaseUnchanged':True}
    a.output.mkdir(parents=True,exist_ok=False)
    for label,raw in [('opening',a.opening),('continue',a.continue_run)]:shutil.copytree(raw,a.output/label)
    for label,path in [('opening.db',opening['database']),('cold-continue.db',resume['database'])]:shutil.copy2(path,a.output/label)
    for n in ['DefaultOpeningEntryNative.lua','DefaultContinueEntryNative.lua']:shutil.copy2(ROOT/'Test'/n,a.output/n)
    shutil.copy2(Path(__file__),a.output/Path(__file__).name)
    for label,raw in [('opening',a.opening),('continue',a.continue_run)]:
        run=load(raw/'run.json');save=Path(run['workDirectory'])/'save'
        for f in save.glob('default-*.tga'):shutil.copy2(f,a.output/(label+'-'+f.name))
    (a.output/'independent-audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n')
    (a.output/'README.md').write_text('# 默认入口与冷启动继续\n\n执行未改包内bootstrap，隔离目录中实际OS点击新旅程与继续；后续原教程、学院漫游、训练采用和首场任务为脚本公共UI回放。原始运行和SQL逐行核对范围见独立审计，不能替代全程OS、三章、所有结局或稳定Boss胜利。正式存档未改。\n')
    files=[{'path':str(f.relative_to(a.output)),'bytes':f.stat().st_size,'sha256':sha(f)}for f in sorted(a.output.rglob('*'))if f.is_file()]
    (a.output/'manifest.json').write_text(json.dumps({'files':files},ensure_ascii=False,indent=2)+'\n');print(json.dumps(audit,ensure_ascii=False))
if __name__=='__main__':main()
