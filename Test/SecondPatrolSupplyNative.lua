-- Native command-driven public route, earned interrogation fixture; no HP edits.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local id=tostring(os.time());local run=id;local report={status='RUNNING',osInput=false};local out=D.Path(root,'Test/second-patrol-supply-result.json');local function save()D.Content:save(out,D.json.encode(report,false,true))end;save()
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
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local wind,why=b:command('wind');assert(not wind and why=='ROLE_ABSENT')
  local deadline=D.App.runningTime+95;local nextShot=0
  while b.phase=='playing' or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Battle stalled')
   local e=b:target(b.mentor)
   if e then
    if math.abs(e.enemy.x-b.mentor.x)>280 then b:command(e.enemy.x>b.mentor.x and 'right' or 'left')
    else b:command('stop');if D.App.runningTime>=nextShot then b:command('shoot');nextShot=D.App.runningTime+.3 end end
    b:command('fire')
   end
   D.sleep(.03)
  end
  report.battle=b.report;save();assert(b.phase=='won',b.reason)
  assert(b.report.learners.ninilite.modelActions>0 and not b.report.learners.wuyun and b.report.windHits==0)
  wait(function()return level.phase=='save-error'end);assert(not assert(store:load()).completed)
  assert(Economy.active()and not level.result.baseButton.visible);assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='active');report.atomicRollback=true
  assert(D.DB:exec('DROP TRIGGER lsd.fail_second_patrol')>=0)
  local bad=D.json.decode(D.json.encode(b.report));bad.learners.wuyun={samples=1};local accepted,why=store:writeAsync(bad);assert(not accepted and why=='WUYUN_MUST_STAY')
  bad=D.json.decode(D.json.encode(b.report));bad.guards[1].loseEnded=bad.guards[1].loseStarted+.1;accepted,why=store:writeAsync(bad);assert(not accepted and why=='FULL_DEFEAT_REQUIRED')
  level.result.againButton:emit('Tapped');wait(function()return level.phase=='result'end);assert(level.checkpointSaved)
  local ledger=assert(Economy.load(b.supplies.attempt));assert(ledger.status=='won'and not Economy.active())
  assert(b.report.economy and Economy.wallet().available==initial-b.report.economy.cost+b.report.economy.income)
  report.cost=b.report.economy.cost;report.income=b.report.economy.income;report.atomicSettlement=true
  assert(assert(store:load()).completed);local first=D.json.encode(assert(store:load()).report,false,true);assert(store:writeAsync({}));assert(first==D.json.encode(assert(store:load()).report,false,true))
  level.result.againButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w~=b.world and w.infiltration and w.infiltration.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local restored=world.infiltration
  assert(restored.second.completed and not restored.battleLevel)
  local wu=D.Group({'name','unit'}):find(function(e)return e.name=='wuyun' and e.unit.world==world end);assert(wu and math.abs(wu.unit.x-4680)<5)
  assert(require('Story.ControlPodStore').open(),'Control pod unavailable after victory')

  report.status='PASS';report.publicRoute=true;report.wuyunAbsent=true;report.saveFailureRetry=true;report.idempotent=true;report.guardRestored=true;report.sameProcessResume=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;save();print(D.json.encode(report))
end)
