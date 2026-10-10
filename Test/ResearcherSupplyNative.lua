-- Public route from an earned stealth checkpoint; no fabricated victory or user save writes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local id=tostring(os.time());local run=id;local report={status='RUNNING',osInput=false};local out=D.Path(root,'Test/researcher-supply-result.json');local function save()D.Content:save(out,D.json.encode(report,false,true))end;save()
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
  level.start:emit('Tapped')
  wait(function()return b.world.storyFlow and b.world.storyFlow.id=='researcher-contact' and b.world.storyFlow.view.visible end)
  local f=b.world.storyFlow;while f.phase~='complete'do if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end
  assert(#f.view._reviews==2,'Original contact rows missing')
  wait(function()return b.phase=='playing'end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_researcher BEFORE UPDATE OF caught ON Game0Researcher WHEN NEW.caught=1 BEGIN SELECT RAISE(ABORT,'QA researcher');END")>=0)
  local deadline=D.App.runningTime+60
  while b.phase=='playing' or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Capture stalled')
   local target=b:target(b.mentor)
   if target then
    if math.abs(target.enemy.x-b.mentor.x)>330 then b:command(target.enemy.x>b.mentor.x and 'right' or 'left')else b:command('stop');b:command('shoot')end
    b:command('fire');b:command('wind')
   end
   D.sleep(.03)
  end
  assert(b.phase=='won',b.reason);wait(function()return level.phase=='save-error'end)
  local store=assert(require('Story.ResearcherStore').open());assert(not store:load().caught,'Failed write advanced capture')
  assert(Economy.active()and not level.result.baseButton.visible);assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='active');report.atomicRollback=true
  D.DB:exec('DROP TRIGGER lsd.fail_researcher');level.result.againButton:emit('Tapped');wait(function()return level.phase=='result'end)
  local ledger=assert(Economy.load(b.supplies.attempt));assert(ledger.status=='won'and not Economy.active())
  assert(b.report.economy and Economy.wallet().available==initial-b.report.economy.cost+b.report.economy.income)
  report.cost=b.report.economy.cost;report.income=b.report.economy.income;report.atomicSettlement=true
  assert(store:load().caught and level.checkpointSaved)
  local saved=D.json.encode(store:load().report,false,true);assert(store:writeAsync(b.report));assert(saved==D.json.encode(store:load().report,false,true),'Replay replaced first report')
  level.result.againButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.capture and w.infiltration.capture.caught end,40)
  w=D.Platformer.Data.store.world;route=w.infiltration
  assert(route.researcher.current=='restrained' and not route.battleLevel and not route.path)
  local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end);assert(math.abs(p.unit.x-4100)<50)
  assert(assert(require('Story.Service').open()):summary().objective:find('已被控制'))
  assert(assert(require('Story.Service').open()):canRead('researcher-interrogation','Factory'));assert(not route.battleLevel,'Repeated capture battle')

  assert(D.DB:exec('UPDATE lsd.Game0Researcher SET schemaVersion=99 WHERE id=1')>=0)
  local bad,err=require('Story.ResearcherStore').open();assert(not bad and err=='INCOMPATIBLE_RESEARCHER_SAVE')
  local options,resumeError=require('Story.InfiltrationStore').resumeOptions(assert(require('Story.Service').open()):summary());assert(not options and resumeError=='INCOMPATIBLE_RESEARCHER_SAVE')
  D.DB:exec('UPDATE lsd.Game0Researcher SET schemaVersion=1 WHERE id=1')
  report.publicRoute=true;report.returned=true;report.battle=b.report;return true
 end,debug.traceback)
 report.status=ok and 'PASS'or'FAIL';report.error=not ok and tostring(result)or nil;save();print('LSD_RESEARCHER_SUPPLY_'..report.status)
end)
