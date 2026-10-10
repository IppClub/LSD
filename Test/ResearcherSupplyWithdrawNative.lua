-- Public route from an earned stealth checkpoint; no fabricated victory or user save writes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local id=tostring(os.time());local run=id;local report={status='RUNNING',osInput=false};local out=D.Path(root,'Test/researcher-supply-withdraw-result.json');local function save()D.Content:save(out,D.json.encode(report,false,true))end;save()
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/infiltration-path-resume-fixture.txt')))
  assert(source:match('^/Users/Jin/Workspace/Dora/lsd%-infiltration%-path%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-researcher-route-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  report.database=db;require('Data.Config'):loadAsync();local Economy=require('Economy.Store');assert(Economy.open());local initial=Economy.wallet().available
  local function wait(fn,t)local untilTime=D.App.runningTime+(t or 25);while not fn()do assert(D.App.runningTime<untilTime,'Researcher route stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local route=w.infiltration
  assert(route.pathCompleted and route.researcher and not route.capture.caught)
  assert(not route.captureStore:writeAsync({status='won'}),'Accepted empty victory')
  route.menu:emit('Tapped',1);wait(function()return route.supplyPanel end)
  route.supplyPanel.closeButton:emit('Tapped');wait(function()return route.phase=='ready'and not route.supplyPanel end)
  assert(not Economy.active()and Economy.wallet().available==initial);report.cancelNoCharge=true
  assert(route:request());wait(function()return route.supplyPanel end);route.supplyPanel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.phase=='ready'end,40)
  local level=D.Platformer.Data.store.world.patrolLevel;local b=level.battle
  assert(b.supplies and not b.supplies.isVirtual);for _,a in ipairs(b.learners)do assert(a.supplies==b.supplies)end
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));assert(D.DB:query('SELECT mission FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='c0-researcher');report.formalSupplies=true
  local checkpoint=assert(require('Story.ResearcherStore').open());assert(not checkpoint:load().caught)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_supply_withdraw BEFORE UPDATE OF status ON Game0MissionAttempts WHEN NEW.mission='c0-researcher' BEGIN SELECT RAISE(ABORT,'QA withdraw'); END")>=0)
  level.withdraw:emit('Tapped');wait(function()return level.phase=='save-error'end)
  assert(Economy.active()and not level.result.baseButton.visible and level.result.resultLayout=='MissionFail')
  assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='active')
  D.DB:exec('DROP TRIGGER lsd.fail_supply_withdraw');level.result.againButton:emit('Tapped');wait(function()return level.phase=='result'and level.checkpointSaved end)
  local ledger=assert(Economy.load(b.supplies.attempt));assert(ledger.status=='aborted'and not Economy.active())
  assert(b.report.economy.income==0 and b.report.economy.cost==ledger.quote.deployment and Economy.wallet().available==initial-ledger.quote.deployment)
  assert(not checkpoint:load().caught);report.rollbackRetry=true;report.cost=b.report.economy.cost;report.failurePage=true
  level.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world.tag=='OperationRoom'end)
  report.returned=true;report.status='PASS';return true
 end,debug.traceback)
 report.status=ok and 'PASS'or'FAIL';report.error=not ok and tostring(result)or nil;save();print('LSD_RESEARCHER_SUPPLY_'..report.status)
end)
