-- Actual production HUD/order lifecycle, controlled HP/idle models, virtual
-- supplies and disabled Boss attacks. Not formal combat, OS input or victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/recovery-hold-continuity-result.json'
local r={status='RUNNING',controlledFixture=true,osInput=false,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local c=require('Factory.PatrolLevel').openAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},function()return true end,{battleFactory=function(m)
   local supply=assert(require('Economy.CombatSession').virtual('recovery-hold',{{actor='mentor',item='kinetic',quantity=4}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(m,supply,{virtual=true,physicalSupport=true});b.bossCombat.boss.guard.update=function()end;return b
  end})
  local b=c.battle
  local function wait(fn,t)local stop=D.App.runningTime+(t or 8);while not fn()do assert(D.App.runningTime<stop,'Recovery hold fixture stalled');D.sleep(.01)end end
  wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.wuyun.student.onSurface end)
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  b.mentorHP=10;assert(b:command('recover-gather'))
  local record=b.bossTrace.gathers[#b.bossTrace.gathers];local deadline=record.deadline;local plan=b.gatherPlan
  local function same(name)
   r.cases[#r.cases+1]={name=name,ended=record.ended,reason=record.reason,deadline=b.gatherUntil,records=#b.bossTrace.gathers};save()
   assert(not record.ended and b.gatherPlan==plan and b.gatherUntil==deadline and #b.bossTrace.gathers==1,name..' cancelled or renewed active recovery')
  end
  c.controls:emit('KeyDown','G');D.sleep(.1);same('keyboard-press')
  D.sleep(.6);same('keyboard-long-hold');c.controls:emit('KeyUp','G');same('keyboard-long-release')
  c.gather:emit('TapBegan');D.sleep(.7);same('touch-long-hold');c.gather:emit('TapEnded');same('touch-long-release')
  c.controls:emit('KeyDown','G');D.sleep(.1);same('pending-short-press')
  D.emit('AppEvent','WindowFocusLost');c.controls:emit('KeyUp','G');D.sleep(.1);same('focus-loss-clears-deferred-cancel')
  D.emit('AppEvent','WindowFocusGained')
  c.gather:emit('TapBegan');D.sleep(.1);same('fresh-short-press');c.gather:emit('TapEnded');D.sleep(.05)
  assert(record.reason=='PLAYER_CANCELLED'and record.deadline==deadline and not b:gatherActive())
  r.shortReleaseCancelled=true
  c.gather:emit('TapBegan');assert(b.gatherMode=='normal'and b:gatherActive());c.gather:emit('TapEnded')
  r.freshNormalPressImmediate=true
  b:finish('aborted','Controlled recovery hold continuity complete')
  r.scope='Actual native HUD and finite recovery record continuity; controlled HP/idle models/virtual supplies/disabled Boss attacks, simulated UI/focus events; not formal battle, real OS focus, victory or recovery balance'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
