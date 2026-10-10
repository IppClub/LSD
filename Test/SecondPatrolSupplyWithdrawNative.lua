-- Native command-driven public route, earned interrogation fixture; no HP edits.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local id=tostring(os.time());local run=id;local report={status='RUNNING',osInput=false};local out=D.Path(root,'Test/second-patrol-supply-withdraw-result.json');local function save()D.Content:save(out,D.json.encode(report,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/interrogation-resume-fixture.txt')))
  assert(source:match('^/Users/Jin/Workspace/Dora/lsd%-interrogation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-second-patrol-route-qa-'..run..'.db');report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  report.database=db;require('Data.Config'):loadAsync();local Economy=require('Economy.Store');assert(Economy.open());local initial=Economy.wallet().available
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Second patrol route stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local route=D.Platformer.Data.store.world.infiltration;local store=assert(require('Story.SecondPatrolStore').open())
  assert(not assert(store:load()).completed);assert(not store:writeAsync({}))
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_second_patrol BEFORE UPDATE ON Game0SecondPatrol BEGIN SELECT RAISE(ABORT,'QA second patrol');END")>=0)
  route.menu:emit('Tapped',1);wait(function()return route.supplyPanel end)
  route.supplyPanel.closeButton:emit('Tapped');wait(function()return route.phase=='ready'and not route.supplyPanel end)
  assert(not Economy.active()and Economy.wallet().available==initial);report.cancelNoCharge=true
  assert(route:request());wait(function()return route.supplyPanel end);route.supplyPanel.saveButton:emit('Tapped');wait(function()return route.battleLevel end,40)
  local level=route.battleLevel;local b=level.battle
  assert(b.supplies and not b.supplies.isVirtual);for _,a in ipairs(b.learners)do assert(a.supplies==b.supplies)end
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));assert(D.DB:query('SELECT mission FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='c0-patrol-second');report.formalSupplies=true
  assert(#b.learners==1 and not b.wuyun and not b.supplies.ledger.stock['wuyun:emp'] and not b.supplies.ledger.stock['wuyun:blade'] and #b:targets()==2 and #b.enemies==3)
  assert(not level.wind.visible and level.fire.visible)
  local ghosts=0;D.Group({'name','unit'}):each(function(e)if e.name=='wuyun' and e.unit.world==b.world then ghosts=ghosts+1 end end);assert(ghosts==0,'Wuyun followed into the battle')
  D.sleep(1);assert(b.mentorHP==100 and b.arena.studentHP==100)
  local checkpoint=assert(require('Story.SecondPatrolStore').open());assert(not checkpoint:load().completed)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_supply_withdraw BEFORE UPDATE OF status ON Game0MissionAttempts WHEN NEW.mission='c0-patrol-second' BEGIN SELECT RAISE(ABORT,'QA withdraw'); END")>=0)
  level.withdraw:emit('Tapped');wait(function()return level.phase=='save-error'end)
  assert(Economy.active()and not level.result.baseButton.visible and level.result.resultLayout=='MissionFail')
  assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='active')
  D.DB:exec('DROP TRIGGER lsd.fail_supply_withdraw');level.result.againButton:emit('Tapped');wait(function()return level.phase=='result'and level.checkpointSaved end)
  local ledger=assert(Economy.load(b.supplies.attempt));assert(ledger.status=='aborted'and not Economy.active())
  assert(b.report.economy.income==0 and b.report.economy.cost==ledger.quote.deployment and Economy.wallet().available==initial-ledger.quote.deployment)
  assert(not checkpoint:load().completed);report.rollbackRetry=true;report.cost=b.report.economy.cost;report.failurePage=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_second_patrol')>=0)
  level.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world.tag=='OperationRoom'end)
  report.returned=true;report.status='PASS';return true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;save();print(D.json.encode(report))
end)
