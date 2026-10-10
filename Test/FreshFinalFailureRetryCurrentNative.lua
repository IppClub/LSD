-- Earned historical rescue checkpoint -> original final entrance -> actual
-- under-equipped defeat and paid retry. No HP/story/model/wallet injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/fresh-final-failure-retry-current-result.json'
local r={status='RUNNING',osInput=false,stages={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-rescue-reactions-current-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourneyBranch and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-rescue%-reactions%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-final-failure-retry-current-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  r.database=db;r.source=prior.database
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==prior.balanceAfter)
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local original=models()
  local function stage(name)r.stage=name;r.stages[#r.stages+1]={name=name,at=D.App.runningTime,balance=E.wallet().available};save()end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Final failure/retry stalled at '..tostring(r.stage));D.sleep(.02)end end
  local function world()return D.Platformer.Data.store.world end
  local function player()return assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end))end
  local function hud()local h;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then h=n end end);return assert(h)end
  local function move(x)local p=player();local h=hud();if math.abs(p.unit.x-x)>25 then local side=p.unit.x<x and 'Right'or'Left';h.move:emit(side,true);wait(function()return math.abs(p.unit.x-x)<25 end,45);h.move:emit(side,false)end;D.sleep(.3)end
  local function door(side,target)
   local old=world();move(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
   local p=player();local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
   assert(index and p.interaction.menu.enabled,'Missing original door '..target);p.interaction:emit('Tapped',index)
   wait(function()return world()~=old and world().tag==target end);D.sleep(.3);stage(target)
  end
  local function flow(w,id,count)
   wait(function()return w.storyFlow and w.storyFlow.id==id and w.storyFlow.view.visible end)
   local f=w.storyFlow;local deadline=D.App.runningTime+100
   while f.phase~='complete'do assert(D.App.runningTime<deadline,'Dialogue '..id..' '..f.phase);if f.view.visible and not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.07)end
   assert(#f.view._reviews==count);stage(id)
  end
  require('Start');wait(function()return world()and world().tag=='RDRoom'and world().jadeArrival end,45);stage('earned-rescue-resumed')
  local w=world();wait(function()return w.jadeArrival.phase=='ready'and w.jadeArrival.marker end);move(w.jadeArrival.marker.x);w.jadeArrival.menu:emit('Tapped',1);flow(w,'jade-distance',8)
  wait(function()return w.finalGate end);local gate=w.finalGate;move(gate.marker.x)
  local preparation,why=gate:request();assert(preparation,why);assert(preparation.phase=='briefing')
  preparation.view.startButton:emit('Tapped');wait(function()return gate.supplyPanel end)
  local panel=gate.supplyPanel
  while panel.values['mentor:kinetic']>1 do panel.buttons[1][-1]:emit('Tapped')end
  while panel.values['ninilite:emp']>0 do panel.buttons[2][-1]:emit('Tapped')end
  assert(panel.quote.total==4);panel.saveButton:emit('Tapped');wait(function()return gate.level end,45)
  local level=gate.level;local b=level.battle;assert(b.supplies and not b.supplies.isVirtual);stage('under-equipped-final-ready')
  wait(function()return b.mentor.onSurface and b.arena.student.onSurface end);level.start:emit('Tapped')
  wait(function()return b.phase=='failed'or b.phase=='won'end,180)
  assert(b.phase=='failed','Under-equipped final unexpectedly won');wait(function()return level.phase=='result'end,45)
  assert(level.result.resultLayout=='MissionFail'and not E.active())
  r.failure=b.report;r.failureAttempt=level.attempt.id;r.balanceAfterFailure=E.wallet().available
  assert(b.report.economy.income==0 and r.balanceAfterFailure==r.balanceBefore-b.report.economy.cost)
  local function noVictory()
   local facts=assert(require('Story.Service').open()):summary()
   assert(not facts.mission.unlocks['last-promise-complete']and not facts.completed['final-betrayal']and not facts.completed['final-story-complete'],'Failed final advanced victory story')
  end
  noVictory();stage('natural-failure-settled')
  level.result.againButton:emit('Tapped');wait(function()return level.supplyPanel end)
  assert(not E.active());level.supplyPanel.closeButton:emit('Tapped');wait(function()return not level.supplyPanel and not level.leaving end)
  assert(E.wallet().available==r.balanceAfterFailure);r.cancelRetryNoCharge=true
  level.result.againButton:emit('Tapped');wait(function()return level.supplyPanel end)
  panel=level.supplyPanel;panel.defaultsButton:emit('Tapped');assert(panel.quote.total<=E.wallet().available);panel.saveButton:emit('Tapped')
  wait(function()return world()~=b.world and world().patrolLevel and world().patrolLevel.phase=='ready'end,45)
  local retry=world().patrolLevel;local rb=retry.battle
  assert(rb.stage==0 and #rb.completedStages==0 and rb.mentorHP==100 and rb.arena.studentHP==100)
  assert(rb.support.gold==45 and rb.support.machineHP==100 and rb.emergencyGranted==b.emergencyGranted and rb.emergencyUsed==0,'Retry accumulated emergency supplies or retained damage')
  assert(retry.medicine.parent and retry.fire.parent and retry.hud.parent and rb.supplies and not rb.supplies.isVirtual)
  stage('paid-retry-ready');wait(function()return rb.mentor.onSurface and rb.arena.student.onSurface end);retry.start:emit('Tapped')
  wait(function()return rb.phase=='playing'and rb.enemies[1]and rb.enemies[1].enemyPhase=='attack'end,15);local strike=rb.enemies[1].enemyStrike
  retry.withdraw:emit('Tapped');wait(function()return retry.phase=='result'end,45)
  assert(rb.phase=='aborted'and strike.completedAt and strike.completedAt-strike.startedAt>=strike.duration-.05,'Retry withdrawal cut enemy attack')
  r.retryStrike={startedAt=strike.startedAt,completedAt=strike.completedAt,duration=strike.duration,kind=strike.kind}
  assert(retry.result.resultLayout=='MissionFail'and not E.active());r.retry=rb.report;r.retryAttempt=retry.attempt.id
  r.balanceAfter=E.wallet().available;assert(r.balanceAfter==r.balanceAfterFailure-rb.report.economy.cost and rb.report.economy.income==0)
  noVictory();retry.result.baseButton:emit('Tapped');wait(function()return world()~=rb.world and world().tag=='RDRoom'and world().finalGate end,45)
  assert(world().finalGate.phase=='ready');assert(models()==original,'Failure/retry changed adopted models')
  r.actualDefeat=true;r.paidRetry=true;r.fullEnemyAttack=true;r.noVictoryUnlock=true;r.modelsUnchanged=true;r.returnedToFinalGate=true;stage('returned-to-original-final-gate')
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
