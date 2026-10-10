-- Scene gate, formal budget and settlement on a named QA save copy.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-mission-gate-result.json';local r={status='RUNNING',osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-mission-gate-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;require('Data.Config'):loadAsync()
  local S=assert(require('Mission.Service').open());assert(S:summary().unlocks['yingzhao-route-cleared'])
  local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local function wait(fn)local deadline=D.App.runningTime+25;while not fn()do assert(D.App.runningTime<deadline,'Mission gate timeout');D.sleep(.02)end end
  local support=require('Ground.LifeSupport').new(65,'defence');support.hp={100,100,100}
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true,support=support})
  local world=D.Platformer.Data.store.world;local gate=assert(world.disarmGate);wait(function()return gate.menu.visible end)
  -- Remove only the copied QA unlock to exercise the locked UI, then restore it.
  local unlock=D.DB:query("SELECT mission,attempt FROM lsd.Game0MissionUnlocks WHERE id='yingzhao-route-cleared'")[1]
  assert(D.DB:exec("DELETE FROM lsd.Game0MissionUnlocks WHERE id='yingzhao-route-cleared'")>=0)
  gate.menu:emit('Tapped',2);D.sleep(.2);assert(not gate.supplyPanel and gate.label.text:find('先完成',1,true));assert(E.wallet().available==initial and not E.active());r.lockedNoCharge=true
  assert(D.DB:exec('INSERT INTO lsd.Game0MissionUnlocks(id,mission,attempt) VALUES(?,?,?)',{'yingzhao-route-cleared',unlock[1],unlock[2]})>=0)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end);assert(world.data.storyBusy)
  gate.supplyPanel.closeButton:emit('Tapped');wait(function()return not gate.supplyPanel end);assert(not world.data.storyBusy and E.wallet().available==initial and not E.active());r.cancelNoCharge=true
  wait(function()return gate.menu.visible end);D.sleep(.25)
  r.screenshot=root..'/Test/yingzhao-mission-gate.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
  gate.menu:emit('Tapped',1);wait(function()return gate.supplyPanel end);gate.supplyPanel.closeButton:emit('Tapped');wait(function()return not gate.supplyPanel end)
  assert(E.wallet().available==initial and not E.active());r.disarmStillAvailable=true
  wait(function()return gate.menu.visible end);D.sleep(.05)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end);gate.supplyPanel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  assert(b.bossCombat and not b.supplies.isVirtual and not b.yingzhaoDemonstration,'Gate did not open formal Boss task')
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));assert(D.DB:query('SELECT mission FROM lsd.Game0MissionAttempts WHERE id=?',{attempt})[1][1]=='c0-yingzhao')
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='MissionFail'and b.report.economy.income==0)
  assert(E.wallet().available==initial-b.report.economy.cost and not E.active());r.withdrawCost=b.report.economy.cost
  local episode=assert(require('Training.CombatStore').load(attempt));assert(episode.boss.status=='aborted');r.formalEvidenceSaved=true
  c.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end);r.returned=true
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
