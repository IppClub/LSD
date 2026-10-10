-- Scripted controls, saved adopted learners, untouched HP/AP and active enemy AI.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/big-yingzhao-full-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/ground-disarm-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/ground%-disarm%-%d+%.db$'))
  local db=D.Content.writablePath..'/big-yingzhao-full-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local service=assert(require('Mission.Service').open());local models=assert(require('Training.FlowerPractice').models());local formation=assert(service:formation())
  local L=require('Economy.Loadout');assert(L.saveAsync(L.defaults()));local supplies=assert(L.forMission('c0-yingzhao',formation))
  local attempt=assert(service:beginAsync('c0-yingzhao',models,formation,supplies));local c=require('Ground.BigYingzhaoLevel').openAsync(service,attempt);local b=c.battle
  local function wait(fn)local stop=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<stop,'Full battle timeout');D.sleep(.02)end end
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local deadline=D.App.runningTime+195;local nextGather=0
  while b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Battle exceeded deadline')
   if b.phase=='playing'then
    if D.App.runningTime>=nextGather and (b.arena.studentHP<80 or b.enemies[1].guard.busy)then c.gather:emit('TapBegan');c.gather:emit('TapEnded');nextGather=D.App.runningTime+3.2 end
    local target=b:target(b.mentor)
    if target then
     local dx=target.enemy.x-b.mentor.x
     if math.abs(dx)>500 then c.hud.move:emit(dx>0 and'Right'or'Left',true)
     elseif math.abs(dx)<300 then c.hud.move:emit(dx>0 and'Left'or'Right',true)
     else c.hud.move:emit('Right',false);c.hud.move:emit('Left',false);c.hud.weapon:emit('TapBegan');D.sleep(.03);c.hud.weapon:emit('TapEnded')end
     c.fire:emit('TapBegan');c.wind:emit('TapBegan')
    else c.hud.move:emit('Right',false);c.hud.move:emit('Left',false)end
   end
   D.sleep(.1)
  end
  wait(function()return c.phase=='result'or c.phase=='save-error'end)
  r.outcome=b.phase;r.uiPhase=c.phase;r.errorSaving=c.error;r.report=b.report;r.bossHP=b.enemies[1].enemyHP;r.resources=b.supplies:evidence();r.hits=#b.bossTrace.hits;r.steps=#b.bossTrace.steps
  assert(c.phase=='result',c.error);assert(c.result.resultLayout==(b.phase=='won'and'Settlement'or'MissionFail'))
  assert(require('Training.CombatStore').load(attempt.id));r.saved=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/big-yingzhao-full-result.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
