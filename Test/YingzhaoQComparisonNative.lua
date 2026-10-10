local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-comparison-result.json';local r={status='RUNNING',completed={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/yingzhao-q-entry-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-q%-entry%-%d+%.db$'))
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-q-compare-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local models=assert(require('Training.FlowerPractice').models())
  local candidate=assert(require('Training.YingzhaoQStore').loadLatestAsync('ninilite'))
  local original=D.json.encode(candidate.model)
  local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true});assert(loadout)
  local function wait(fn,seconds)local stop=D.App.runningTime+(seconds or 420);while not fn()do local failed=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');if failed and failed.error then r.comparisonError=failed.error;error(failed.error)end;assert(D.App.runningTime<stop,'Comparison UI timeout');D.sleep(.05)end end
  local Entry=require('Training.YingzhaoComparisonEntry')
  local panel=Entry.openAsync(nil,'ninilite',models,candidate);panel.saveButton:emit('Tapped')
  wait(function()local progress=D.Director.ui3D:getChildByTag('yingzhao-comparison-progress');local holder=progress and progress:getChildByTag('comparison-stop-holder');return holder and holder:getChildByTag('comparison-stop') end,30)
  D.Director.ui3D:getChildByTag('yingzhao-comparison-progress'):getChildByTag('comparison-stop-holder'):getChildByTag('comparison-stop'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-result')end)
  local result=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');assert(result.report and result.report.cancelled and #result.report.rounds==1);r.cancelled=true
  assert(D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0YingzhaoComparisons(id INTEGER PRIMARY KEY AUTOINCREMENT,identity TEXT UNIQUE NOT NULL,payload TEXT NOT NULL)')>=0)
  assert(D.DB:exec("CREATE TRIGGER lsd.reject_comparison BEFORE INSERT ON Game0YingzhaoComparisons BEGIN SELECT RAISE(ABORT,'QA write failure'); END")>=0)
  require('Training.Level')(nil,'ninilite')
  wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  D.Director.ui3D:getChildByTag('training-controls'):getChildByTag('training-menu'):getChildByTag('自主对照'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-budget')end)
  panel=D.Director.ui3D:getChildByTag('yingzhao-comparison-budget');panel.saveButton:emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('yingzhao-comparison-result')end)
  result=D.Director.ui3D:getChildByTag('yingzhao-comparison-result');assert(result.report,result.error);r.report=result.report
  assert(not result.saved and result.saveError=='WRITE_FAILED',result.saveError)
  assert(D.DB:exec('DROP TRIGGER lsd.reject_comparison')>=0);result.retryButton:emit('Tapped');wait(function()return result.saved end)
  local store=require('Training.YingzhaoComparisonStore');assert(store.load(result.saved));assert(store.saveAsync(result.report)==result.saved)
  local fake=D.json.decode(D.json.encode(result.report),32);fake.rounds[1].cost=fake.rounds[1].cost+1;assert(not store.saveAsync(fake))
  fake=D.json.decode(D.json.encode(result.report),32);fake.rounds[1].shieldEnergy=fake.rounds[1].shieldEnergy+1;assert(not store.saveAsync(fake),'Forged shield energy summary accepted')
  r.saved=result.saved;r.retry=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/yingzhao-q-comparison-ui.tga');D.sleep(.2)
  assert(#r.report.rounds==2)
  assert(require('Training.YingzhaoRules').current(r.report.setup))
  for _,round in ipairs(r.report.rounds)do assert(round.trace.physicalShieldVersion==1 and round.trace.physicalShield.initial.gold==45 and round.trace.physicalShield.initial.capacity==80);assert(math.abs(round.shieldEnergy-require('Training.YingzhaoRewards').shieldCost(round.trace))<1e-6)end
  r.equalShieldEnvironment=true;r.shieldEnergySummaryValidated=true
  for _,round in ipairs(r.report.rounds)do assert(round.status=='won'or round.status=='failed');assert(require('Training.ResourceEvidence').validate(round.trace.resources))end
  assert(#r.report.rounds[2].decisions>0)
  assert(D.json.encode(assert(require('Training.YingzhaoQStore').loadLatestAsync('ninilite')).model)==original)
  r.frozen=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
