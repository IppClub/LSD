local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-practice-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-medical-visit-qa-1791007987.db';local dest=D.Content.writablePath..'/lsd-yingzhao-practice-qa-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=saved();local function wait(fn,seconds)local untilAt=D.App.runningTime+(seconds or 12);while not fn()do assert(D.App.runningTime<untilAt,'Yingzhao practice timeout');D.sleep(.02)end end
  require('Training.Level')(nil,'ninilite');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local basic=D.Director.ui3D:getChildByTag('training-controls');basic:getChildByTag('training-menu'):getChildByTag('英招演练'):emit('Tapped')
  wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  assert(b.world.tag=='VRTraining' and #b.enemies==3 and b.phase=='ready');D.sleep(.7)
  for _,e in ipairs(b.enemies)do assert(#e.guard.strikes==0 and e.enemy.playable.current=='idle')end
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local endAt=D.App.runningTime+100;local photographed=false
  while b.phase=='playing' or b.phase=='settling' do
   assert(D.App.runningTime<endAt,'Encounter did not settle')
   if b.phase=='playing' then
    local target=b:target(b.mentor)
    if target then
     local delta=target.enemy.x-b.mentor.x
     if math.abs(delta)>420 then c.hud.move:emit(delta>0 and 'Right' or 'Left',true)
     else
      c.hud.move:emit('Right',false);c.hud.move:emit('Left',false)
      if b.mentor.faceRight~=(delta>=0)then c.hud.move:emit(delta>=0 and 'Right' or 'Left',true);D.sleep(.02);c.hud.move:emit('Right',false);c.hud.move:emit('Left',false)end
      c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')
     end
     c.fire:emit('TapBegan');c.wind:emit('TapBegan')
    end
    if not photographed and D.App.runningTime-b.started>4 then photographed=true;D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/yingzhao-practice-active.tga')end
   end
   D.sleep(.1)
  end
  r.report=b.report;assert(b.phase=='won',b.reason);assert(b.mentorHits>0 and b.arena.metrics.modelActions>0 and b.wuyun.metrics.modelActions>0)
  local attacks=0;for _,e in ipairs(b.enemies)do assert(e.guard.dead);attacks=attacks+#e.guard.strikes end;assert(attacks>0);r.attacks=attacks
  wait(function()return c.phase=='result'end);assert(saved()==before,'Practice changed saved progress')
  c.result.againButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel and D.Platformer.Data.store.world.patrolLevel~=c end)
  local again=D.Platformer.Data.store.world.patrolLevel;assert(again.battle.phase=='ready');again.withdraw:emit('Tapped');wait(function()return again.phase=='result'end)
  again.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  assert(saved()==before);r.publicEntry=true;r.virtualScene=true;r.restart=true;r.returned=true;r.progressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
