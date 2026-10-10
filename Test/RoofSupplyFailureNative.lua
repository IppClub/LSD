-- Native combat integration fixture; uses the earned dialogue save and adopted learner.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/roof-supply-failure-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-dialogue-resume-fixture.txt')));assert(source:match('^/Users/Jin/Workspace/Dora/lsd%-roof%-dialogue%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-battle-failure-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();local Economy=require('Economy.Store');assert(Economy.open());local initial=Economy.wallet().available
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Roof combat stalled');D.sleep(.02)end end
  require('Start');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.roof and D.Platformer.Data.store.world.roof.phase=='ready'end,40)
  local c=D.Platformer.Data.store.world.roof;local p=require('Training.Progress');assert(p.load()and p.adopted)
  assert(c:act());wait(function()return c.supplyPanel end);assert(c.phase=='supply'and not c.ui.visible and not c.hud.visible)
  c.supplyPanel.closeButton:emit('Tapped');wait(function()return c.phase=='ready'and not c.supplyPanel end)
  assert(c.ui.visible and c.hud.visible and Economy.wallet().available==initial and not Economy.active());report.cancelNoCharge=true
  assert(c:act());wait(function()return c.supplyPanel end);c.supplyPanel.saveButton:emit('Tapped');wait(function()return c.world.patrolLevel end);local level=c.world.patrolLevel;local b=level.battle;assert(b.supplies and not b.supplies.isVirtual and b.arena.supplies==b.supplies and not b.supplies.ledger.stock['wuyun:emp']);local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));assert(D.DB:query('SELECT mission FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='c0-roof');report.formalSupplies=true;wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.enemy.enemy.onSurface end)
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  level.hud.move:emit('Right',true);wait(function()return b.mentor.x>=b.enemy.enemy.x-100 end,8);level.hud.move:emit('Right',false)
  wait(function()return b.phase=='failed'or b.phase=='won'end,60)
  report.defeat=b.report;assert(b.phase=='failed'and b.mentorHP==0,'Expected an actual combat defeat')
  wait(function()return level.phase=='result'end)
  local store=assert(require('Story.RoofDuelStore').open());assert(not store:load().completed)
  assert(level.result.resultLayout=='MissionFail'and b.report.economy.income==0 and not Economy.active())
  assert(Economy.wallet().available==initial-b.report.economy.cost);report.failureCost=b.report.economy.cost
  level.result.againButton:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w~=b.world and w.roof and w.roof.supplyPanel end)
  local panel=D.Platformer.Data.store.world.roof.supplyPanel
  while panel.quote.total>Economy.wallet().available do panel.buttons[1][-1]:emit('Tapped')end
  panel.saveButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world.patrolLevel end)
  local retry=D.Platformer.Data.store.world.patrolLevel;assert(retry.battle.phase=='ready'and retry.battle.mentorHP==100 and retry.battle.arena.studentHP==100 and retry.battle.enemy.enemyHP==360)
  wait(function()return retry.battle.mentor.onSurface and retry.battle.arena.student.onSurface end)
  retry.start:emit('Tapped');wait(function()return retry.battle.phase=='playing'end)
  D.emit('Skill.Began');D.emit('Skill.Ended');wait(function()return retry.battle.mentor:isDoing('groundMentorShot')end)
  local started=D.App.runningTime;retry.withdraw:emit('Tapped');assert(retry.battle.phase=='settling')
  wait(function()return retry.phase=='result'end)
  assert(retry.battle.phase=='aborted'and retry.battle.mentor.data.combatCompletedName=='pistol'and D.App.runningTime-started>.6,'Withdraw cut the pending shot')
  assert(not store:load().completed and retry.result.resultLayout=='MissionFail'and retry.battle.report.economy.income==0 and not Economy.active());report.withdrawCost=retry.battle.report.economy.cost;report.withdrawDuringAttack=true
  retry.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=retry.battle.world and D.Platformer.Data.store.world.roof end)
  local returned=D.Platformer.Data.store.world.roof;assert(returned.confrontationComplete and not returned.duelComplete and returned.stage==2)
  report.failureRetry=true;report.noVictoryOnFailure=true;report.returnToRoof=true
  report.status='PASS';report.atomicSettlement=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
