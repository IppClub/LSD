local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ground-disarm-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local generated,why=D.xml.tolua(D.Content:load(root..'/UI/Settlement.xml'));assert(generated,why);assert(D.Content:save(root..'/UI/Settlement.lua','-- [xml]: UI/Settlement.xml\n'..generated))
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-adoption-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-adoption%-%d+%.db$'))
  local db=D.Content.writablePath..'/ground-disarm-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local adoption=require('Training.DisarmAdoptionStore');local models=assert(require('Training.FlowerPractice').models());local current=assert(adoption.inspectAsync('wuyun'))
  local inactive,reason=adoption.loadAsync('wuyun',models,'mission');assert(not inactive and reason=='MISSION_NOT_CONFIRMED')
  assert(adoption.adoptAsync(current.bundle,{accepted=true,scope='practice-and-mission',comparisonId=current.bundle.comparison.id,review=current.proof.review},models,adoption.state('wuyun')))
  r.formalScopeExplicit=true
  local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available;local L=require('Economy.Loadout')
  local values=L.defaults();values['mentor:kinetic']=24;values['ninilite:emp']=24;values['wuyun:emp']=6;values['wuyun:blade']=24;assert(L.saveAsync(values))
  local function wait(fn)local deadline=D.App.runningTime+30;while not fn()do assert(D.App.runningTime<deadline,'Ground disarm timeout');D.sleep(.02)end end
  local function observationCount()return assert(D.DB:query('SELECT COUNT(*) FROM lsd.Game0DisarmObservations'))[1][1]end
  local count=observationCount()
  local function open()
   local support=require('Ground.LifeSupport').new(65,'defence');support.hp={100,100,100}
   require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true,support=support})
   local world=D.Platformer.Data.store.world;local gate=assert(world.disarmGate);wait(function()return gate.menu.visible end);gate.menu:emit('Tapped');wait(function()return gate.supplyPanel end);return world,gate
  end
  local world,gate=open();local gold=world.groundExpedition.support.gold;D.sleep(.3);assert(world.groundExpedition.support.gold==gold and world.data.storyBusy)
  gate.supplyPanel.closeButton:emit('Tapped');wait(function()return not gate.supplyPanel end);assert(not E.active()and E.wallet().available==initial);r.cancelNoCharge=true
  D.sleep(.3);wait(function()return gate.menu.visible end);gate.menu:emit('Tapped');wait(function()return gate.supplyPanel end);gate.supplyPanel.saveButton:emit('Tapped')
  wait(function()return D.Platformer.Data.store.world.patrolLevel end);local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  assert(not b.supplies.isVirtual and b.disarmTrace.adoptions.wuyun and b.disarmTrace.kind=='disarm-mission')
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='MissionFail'and b.report.economy.income==0 and b.report.economy.cost==9 and E.wallet().available==initial-9)
  local episode=assert(require('Training.CombatStore').load(tonumber(b.supplies.attempt:match('(%d+)$'))));assert(episode.disarm.status=='aborted')
  assert(observationCount()==count);r.withdrawCost=b.report.economy.cost
  c.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end)
  world,gate=open();gate.supplyPanel.saveButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world.patrolLevel end)
  c=D.Platformer.Data.store.world.patrolLevel;b=c.battle
  assert(D.DB:exec("CREATE TRIGGER lsd.reject_disarm_result BEFORE UPDATE OF status ON Game0MissionAttempts BEGIN SELECT RAISE(ABORT,'settlement test'); END")>=0)
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end);local deadline=D.App.runningTime+110
  while b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Disarm mission did not finish')
   if b.phase=='playing'then local enemy=b:target(b.mentor)
    if enemy then local dx=enemy.enemy.x-b.mentor.x
     if math.abs(dx)>420 then c.hud.move:emit(dx>0 and 'Right'or'Left',true)
     else c.hud.move:emit('Right',false);c.hud.move:emit('Left',false);c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')end
     c.fire:emit('TapBegan');c.wind:emit('TapBegan')
    end
   end;D.sleep(.1)
  end
  wait(function()return c.phase=='save-error'end);assert(b.phase=='won',b.reason)
  local reserved=E.wallet().available;c.result.baseButton:emit('Tapped');D.sleep(.2);assert(D.Platformer.Data.store.world==b.world and E.wallet().available==reserved)
  assert(D.DB:exec('DROP TRIGGER lsd.reject_disarm_result')>=0);c.result.againButton:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='Settlement'and b.report.economy.income==100)
  local attemptId=tonumber(b.supplies.attempt:match('(%d+)$'));local e=assert(require('Training.CombatStore').load(attemptId));assert(e.disarm.kind=='disarm-mission'and #e.disarm.adoptionDecisions>0)
  local yes,reason=require('Training.DisarmStore').saveAsync(e.disarm);assert(not yes and reason=='INVALID_SOURCE')
  local service=assert(require('Mission.Service').open());local balance=E.wallet().available
  assert(service:finishAsync({id=attemptId,mission='c0-disarm'},'won',b.report,e));assert(E.wallet().available==balance and balance==initial-9+b.report.economy.net)
  assert(observationCount()==count);r.won={cost=b.report.economy.cost,net=b.report.economy.net,balance=balance};r.atomicRetry=true;r.separateFromTraining=true
  r.screenshot=D.Content.writablePath..'/ground-disarm-success.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
