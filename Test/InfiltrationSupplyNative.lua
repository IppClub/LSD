-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=D.Path(root,'Test','infiltration-supply-result.json');local evidence={status='RUNNING',osInput=false};D.Content:save(out,D.json.encode(evidence,false,true))
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(source:match('^/Users/Jin/Workspace/Dora/lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'infiltration-supply-'..os.time()..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  evidence.database=db
  require('Data.Config'):loadAsync()
  local Economy=require('Economy.Store');assert(Economy.open());local initial=Economy.wallet().available
  local progress=require('Training.Progress');assert(progress.load());local wp=progress.forCharacter('wuyun');assert(wp.load());local models={ninilite=assert(progress.adopted),wuyun=assert(wp.adopted)}
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Public infiltration wait stalled');D.sleep(.03)end end
  local function advance(f,count)
   wait(function()return f.view.visible end)
   local deadline=D.App.runningTime+30;while f.phase~='complete'do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end
   assert(#f.view._reviews==count)
  end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.commandAssembly and w.commandAssembly.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local assembly=world.commandAssembly
  local player=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)
  local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  if math.abs(player.unit.x-assembly.center)>=100 then
   local side=player.unit.x<assembly.center and 'Right'or'Left';hud.move:emit(side,true)
   wait(function()return math.abs(player.unit.x-assembly.center)<100 end);hud.move:emit(side,false);D.sleep(.3)
  end
  assembly.menu:emit('Tapped',4)
  wait(function()local w=D.Platformer.Data.store.world;return w~=world and w.infiltration and w.infiltration.phase=='ready'end,30)
  world=D.Platformer.Data.store.world;local c=world.infiltration;assert(world.infiltrationRoute and not world.factoryExpedition and c.fox.companionForm=='nine-tail-chibi')
  local store=c.store;assert(store:load().active and not store:load().located)
  assert(not store:writeAsync('locate',{fromLens=true,x=3000,seconds=3}),'Out-of-range scan accepted')
  c.menu:emit('Tapped',1);wait(function()return world.storyFlow and world.storyFlow.id=='patrol-approach'end);advance(world.storyFlow,2)
  assert(c:request());local lens=world.nightLens;assert(lens.locations[2].id=='patrol')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_patrol_location BEFORE UPDATE OF located ON Game0Infiltration WHEN NEW.located=1 BEGIN SELECT RAISE(ABORT,'QA location'); END")>=0)
  lens.view.researchButton:emit('Tapped');wait(function()return c.error=='SAVE_FAILED' and not c.scanning end,6);assert(not store:load().located)
  D.DB:exec('DROP TRIGGER lsd.fail_patrol_location');lens.view.researchButton:emit('Tapped');wait(function()return store:load().located and not c.scanning end,6);lens.view.closeButton:emit('Tapped')
  assert(c:request());wait(function()return c.supplyPanel end)
  c.supplyPanel.closeButton:emit('Tapped');wait(function()return c.phase=='ready'and not c.supplyPanel end)
  assert(not world.data.storyBusy and Economy.wallet().available==initial and not Economy.active());evidence.cancelNoCharge=true
  assert(c:request());wait(function()return c.supplyPanel end);c.supplyPanel.saveButton:emit('Tapped')
  wait(function()return c.battleLevel and c.battleLevel.phase=='ready'end,30)
  local level=c.battleLevel;local b=level.battle
  assert(b.supplies and not b.supplies.isVirtual);for _,a in ipairs(b.learners)do assert(a.supplies==b.supplies)end
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));assert(D.DB:query('SELECT mission FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='c0-patrol')
  evidence.formalSupplies=true
  level.start:emit('Tapped');wait(function()return b.world.storyFlow and b.world.storyFlow.id=='patrol-contact'end);advance(b.world.storyFlow,1);wait(function()return b.phase=='playing'end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_patrol_checkpoint BEFORE UPDATE OF firstPatrol ON Game0Infiltration WHEN NEW.firstPatrol=1 BEGIN SELECT RAISE(ABORT,'QA victory'); END")>=0)
  local deadline=D.App.runningTime+70;local nextShot=0
  while b.phase=='playing' or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Patrol battle stalled')
   local e=b:target(b.mentor)
   if e then
    if math.abs(e.enemy.x-b.mentor.x)>330 then b:command(e.enemy.x>b.mentor.x and 'right' or 'left')else b:command('stop');if D.App.runningTime>=nextShot then b:command('shoot');nextShot=D.App.runningTime+.3 end end
    b:command('fire');b:command('wind')
   end;D.sleep(.03)
  end
  assert(b.phase=='won',b.reason);wait(function()return level.phase=='save-error'end);assert(not store:load().firstPatrol and not level.checkpointSaved)
  assert(not level.result.baseButton.visible and Economy.active());assert(D.DB:query('SELECT status FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='active')
  evidence.rollbackBeforeRetry=true
  D.DB:exec('DROP TRIGGER lsd.fail_patrol_checkpoint');level.result.againButton:emit('Tapped');wait(function()return level.phase=='result' and level.checkpointSaved end)
  local ledger=assert(Economy.load(b.supplies.attempt));assert(ledger.status=='won'and not Economy.active())
  local report=store:load().report;assert(report.economy and report.economy.cost>ledger.quote.deployment and Economy.wallet().available==initial-report.economy.cost+report.economy.income)
  evidence.cost=report.economy.cost;evidence.income=report.economy.income;evidence.atomicSettlement=true
  local owners={};for _,event in pairs(ledger.events)do owners[event.owner or event.actor]=true end;assert(owners.mentor and (owners.ninilite or owners.wuyun));evidence.resourceEvents=ledger.events
assert(store:load().firstPatrol and report.mentorHits>0 and report.fireHits>0 and report.windHits>0)
  level.result.againButton:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w~=b.world and w.infiltration and w.infiltration.phase=='ready'end,30)
  world=D.Platformer.Data.store.world;c=world.infiltration;assert(c.state.firstPatrol and math.abs(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end).unit.x-2200)<80)
  assert(c:request());advance(world.storyFlow,1);assert(require('Story.Service').open():summary().completed['patrol-cleared'])
  local saved=D.json.encode(store:load().report,false,true);D.sleep(.1);assert(c.phase=='ready'and not world.patrolBattle and saved==D.json.encode(store:load().report,false,true),'Repeated patrol completion changed report');assert(require('Story.Service').open():canRead('infiltration-fox-guide','Factory'))
  c.menu:emit('Tapped',2);wait(function()return D.Platformer.Data.store.world.tag=='OperationRoom'end,30);assert(not store:load().active and store:load().firstPatrol)
  local current=D.Platformer.Data.store.world;local journal=assert(require('Story.Journal').openAsync(current,13));journal.view.researchButton:emit('Tapped');wait(function()return current.storyFlow and current.storyFlow.id=='patrol-cleared'end);advance(current.storyFlow,1);wait(function()return current.storyJournal.phase=='journal'end);current.storyJournal.view.closeButton:emit('Tapped')
  assert(D.DB:exec('UPDATE lsd.Game0InfiltrationMeta SET schemaVersion=99 WHERE id=1')>=0)
  local can,reason=require('Story.Service').open():canRead('patrol-cleared','OperationRoom',true);assert(not can and reason=='INCOMPATIBLE_INFILTRATION_SAVE')
  local wrote,err=store:writeAsync('enter');assert(not wrote and err=='INCOMPATIBLE_INFILTRATION_SAVE');D.DB:exec('UPDATE lsd.Game0InfiltrationMeta SET schemaVersion=1 WHERE id=1')
  evidence.returned=true;evidence.report=report
  return true
 end,debug.traceback)
 evidence.status=ok and 'PASS'or'FAIL';evidence.error=not ok and tostring(result)or nil;D.Content:save(out,D.json.encode(evidence,false,true));print('LSD_INFILTRATION_SUPPLY_'..evidence.status)
end)
