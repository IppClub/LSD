-- Public controls driven by UI events in an isolated QA save, not OS input.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-arena-ui-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-arena-ui-'..os.time()..'.db';r.database=db;assert(not D.DB:existDB('lsd'));assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  local function wait(fn)local deadline=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<deadline,'Arena UI timeout');D.sleep(.02)end end
  require('Training.Level')(nil,'ninilite')
  wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local controls=D.Director.ui3D:getChildByTag('training-controls');assert(controls)
  controls:getChildByTag('training-menu'):getChildByTag('大英招示范'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout')end)
  D.Director.ui3D:getChildByTag('big-yingzhao-supply-loadout').saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.battle.yingzhaoDemonstration end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  assert(b.minX==200 and b.maxX==3640 and c.targetButtons.head and c.hud and c.gather)
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local guard=b.enemies[1].guard;local update=guard.update
  guard.update=function(g,now)g.nextAttack=math.huge;update(g,now);g.nextAttack=math.huge end
  guard.nextAttack=math.huge;b.wuyun.mode='review';D.sleep(.5)
  c.targetButtons.head:emit('Tapped');assert(b.demonstrationTarget=='head')
  D.emit('Skill.Began')
  wait(function()for _,s in ipairs(b.bossTrace.steps)do if s.origin=='demo'and s.emitted==1 then assert(s.aim.intent=='head');return true end end end)
  wait(function()return not b.arena:isAttacking()end)
  D.App:saveScreenshot(root..'/Test/yingzhao-arena-ui-aim.tga');D.sleep(.2)
  c.hud.move:emit('Left',true)
  wait(function()r.movement={x=b.arena.student.x,hp=b.arena.studentHP,phase=b.phase,mode=b.arena.mode};return b.arena.student.x<=b.minX+2 end);c.hud.move:emit('Left',false);D.sleep(.3)
  assert(b.arena.student.x>=b.minX-.1 and b.controlledUnit==b.arena.student)
  D.App:saveScreenshot(root..'/Test/yingzhao-arena-ui-edge.tga');D.sleep(.2)
  r.stepCount=#b.bossTrace.steps;assert(r.stepCount<80 and not b.bossTrace.truncated,'Held HUD input flooded the trace')
  r.edgeX=b.arena.student.x;r.cameraX=b.world.camera.position.x;r.shots=b.supplies.emissions
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'end)
  assert(c.result.resultLayout=='MissionFail'and b.demonstrationSourceId and E.wallet().available==balance)
  r.record=assert(require('Training.YingzhaoStore').loadAsync(b.demonstrationSourceId));r.walletUnchanged=true
  c.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  r.returned=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
